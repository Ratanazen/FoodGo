import json
import time
from urllib.parse import parse_qs
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from rest_framework_simplejwt.tokens import AccessToken
from django.contrib.auth import get_user_model
from core.models import Order


@database_sync_to_async
def get_user_from_token(token):
    try:
        access_token = AccessToken(token)
        user_id = access_token.get('user_id')
        if not user_id:
            return None
        User = get_user_model()
        return User.objects.filter(id=user_id, is_active=True).first()
    except Exception:
        return None


@database_sync_to_async
def check_order_access(order_id, user):
    """
    Checks if user is allowed to connect to the order tracking WebSocket.
    Returns (can_connect: bool, is_assigned_driver: bool)
    Allowed users:
    - Customer of the order
    - Assigned driver for the order
    - Staff / Admin
    """
    try:
        order = Order.objects.select_related('customer', 'delivery__driver__user').get(id=order_id)

        is_assigned_driver = False
        if hasattr(order, 'delivery') and order.delivery and order.delivery.driver:
            if order.delivery.driver.user_id == user.id:
                is_assigned_driver = True

        is_customer = (order.customer_id == user.id)
        is_staff = bool(user.is_staff or user.is_superuser)

        can_connect = is_customer or is_assigned_driver or is_staff
        return can_connect, is_assigned_driver
    except Exception:
        return False, False


class OrderTrackingConsumer(AsyncWebsocketConsumer):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.last_broadcast_ts = 0.0

    async def connect(self):
        self.order_id = self.scope['url_route']['kwargs']['order_id']
        self.room_group_name = f'order_{self.order_id}'

        # Extract token from query string (e.g., ?token=xxx)
        query_string = self.scope.get('query_string', b'').decode('utf-8')
        query_params = parse_qs(query_string)
        token = query_params.get('token', [None])[0]

        if not token:
            await self.close(code=4001)
            return

        # Development / Simulation bypass for testing and simulator script
        if token.startswith('mock-') or token in ('simulator-token', 'dev-token'):
            self.user = None
            self.is_assigned_driver = True
            await self.channel_layer.group_add(
                self.room_group_name,
                self.channel_name
            )
            await self.accept()
            return

        # Verify JWT token
        user = await get_user_from_token(token)
        if not user:
            await self.close(code=4001)
            return

        self.user = user

        # Verify authorization: order customer, assigned driver, or staff
        can_connect, is_assigned_driver = await check_order_access(self.order_id, user)
        if not can_connect:
            await self.close(code=4001)
            return

        self.is_assigned_driver = is_assigned_driver

        # Join room group
        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name
        )
        await self.accept()

    async def disconnect(self, close_code):
        # Leave room group
        if hasattr(self, 'room_group_name'):
            await self.channel_layer.group_discard(
                self.room_group_name,
                self.channel_name
            )

    # Receive message from WebSocket (only assigned driver can broadcast location updates)
    async def receive(self, text_data):
        if not getattr(self, 'is_assigned_driver', False):
            return

        try:
            text_data_json = json.loads(text_data)
        except Exception:
            return

        if 'lat' in text_data_json and 'lng' in text_data_json:
            try:
                lat = float(text_data_json['lat'])
                lng = float(text_data_json['lng'])
                if not (-90.0 <= lat <= 90.0 and -180.0 <= lng <= 180.0):
                    return
            except (ValueError, TypeError):
                return

            # Rate-limiting / Throttling: at most 1 update per 200ms per client
            now = time.time()
            if now - self.last_broadcast_ts < 0.2:
                return
            self.last_broadcast_ts = now

            bearing = float(text_data_json.get('bearing', 0.0))
            speed = float(text_data_json.get('speed', 30.0))

            # Broadcast the location to all listeners
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    'type': 'driver_location_update',
                    'lat': lat,
                    'lng': lng,
                    'bearing': bearing,
                    'speed': speed,
                }
            )

    # Receive message from room group
    async def driver_location_update(self, event):
        lat = event['lat']
        lng = event['lng']
        bearing = event.get('bearing', 0.0)
        speed = event.get('speed', 30.0)

        # Send message to WebSocket
        await self.send(text_data=json.dumps({
            'type': 'driver_location',
            'lat': lat,
            'lng': lng,
            'bearing': bearing,
            'speed': speed,
        }))
