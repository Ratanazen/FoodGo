import json
from channels.generic.websocket import AsyncWebsocketConsumer

class OrderTrackingConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.order_id = self.scope['url_route']['kwargs']['order_id']
        self.room_group_name = f'order_{self.order_id}'

        # Join room group
        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name
        )
        await self.accept()

    async def disconnect(self, close_code):
        # Leave room group
        await self.channel_layer.group_discard(
            self.room_group_name,
            self.channel_name
        )

    # Receive message from WebSocket (if client sends data, not strictly needed for tracking view-only clients, but good to have)
    async def receive(self, text_data):
        text_data_json = json.loads(text_data)
        if 'lat' in text_data_json and 'lng' in text_data_json:
            # Broadcast the location to all listeners
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    'type': 'driver_location_update',
                    'lat': text_data_json['lat'],
                    'lng': text_data_json['lng'],
                }
            )

    # Receive message from room group
    async def driver_location_update(self, event):
        lat = event['lat']
        lng = event['lng']

        # Send message to WebSocket
        await self.send(text_data=json.dumps({
            'type': 'driver_location',
            'lat': lat,
            'lng': lng
        }))
