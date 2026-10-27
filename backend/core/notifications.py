from datetime import timedelta
from django.utils import timezone
import logging
from .models import Notification

logger = logging.getLogger(__name__)

STATUS_NOTIFICATION_TEMPLATES = {
    'pending': (
        'Order Placed',
        'Your order #{order_id} has been placed successfully and is awaiting confirmation.'
    ),
    'confirmed': (
        'Order Confirmed',
        'Your order #{order_id} from {restaurant_name} has been confirmed.'
    ),
    'preparing': (
        'Preparing Your Food',
        'The kitchen at {restaurant_name} has started preparing order #{order_id}.'
    ),
    'ready': (
        'Order Ready',
        'Order #{order_id} is packed and ready for courier pickup.'
    ),
    'ready_for_pickup': (
        'Order Ready',
        'Order #{order_id} is packed and ready for courier pickup.'
    ),
    'picked_up': (
        'Courier On the Way',
        'Your courier has picked up order #{order_id} and is en route.'
    ),
    'on_the_way': (
        'Order On the Way',
        'Your courier is on the way with order #{order_id}.'
    ),
    'driver_arrived': (
        'Courier Arrived',
        'Your courier has arrived at your delivery address for order #{order_id}.'
    ),
    'arrived': (
        'Courier Arrived',
        'Your courier has arrived at your delivery address for order #{order_id}.'
    ),
    'delivered': (
        'Order Delivered',
        'Your order #{order_id} has been safely delivered. Enjoy your meal!'
    ),
    'cancelled': (
        'Order Cancelled',
        'Order #{order_id} has been cancelled.'
    ),
}

def dispatch_order_notification(order, status_key=None, custom_title=None, custom_message=None, target_user=None):
    """
    Safely creates an in-app Notification for the order's customer (or target_user) with rich metadata.
    Includes rapid deduplication to prevent duplicate notifications across automated model signals
    and manual controller calls.
    """
    recipient = target_user or getattr(order, 'customer', None)
    if not recipient:
        return None
    try:
        st = (status_key or getattr(order, 'status', 'pending') or 'pending').lower()
        rest_name = order.restaurant.name if getattr(order, 'restaurant', None) else 'FoodGo Restaurant'

        default_title, default_msg_tpl = STATUS_NOTIFICATION_TEMPLATES.get(
            st,
            ('Order Update', f'Your order #{order.id} status is now {st}.')
        )
        title = custom_title or default_title
        message = custom_message or default_msg_tpl.format(order_id=order.id, restaurant_name=rest_name)

        # 5-second rapid deduplication for identical recipient, order, and status
        if getattr(order, 'id', None):
            cutoff = timezone.now() - timedelta(seconds=5)
            existing = Notification.objects.filter(
                user=recipient,
                notification_type='order',
                data__order_id=order.id,
                data__status=st,
                created_at__gte=cutoff
            ).first()

            if existing:
                # Upgrade title or message in-place if custom content is supplied
                changed = False
                if custom_title and existing.title != custom_title:
                    existing.title = custom_title
                    changed = True
                if custom_message and existing.message != custom_message:
                    existing.message = custom_message
                    changed = True
                if changed:
                    existing.save(update_fields=['title', 'message'])
                order._notification_dispatched_for_status = st
                return existing

        notif = Notification.objects.create(
            user=recipient,
            title=title,
            message=message,
            notification_type='order',
            data={
                'order_id': order.id,
                'order_reference': getattr(order, 'order_reference', ''),
                'status': st,
                'restaurant_name': rest_name,
                'total_amount': str(getattr(order, 'total_amount', '0.00')),
            }
        )
        order._notification_dispatched_for_status = st
        return notif
    except Exception as e:
        logger.warning(f"Failed to dispatch order notification for order {getattr(order, 'id', None)}: {e}")
        return None
