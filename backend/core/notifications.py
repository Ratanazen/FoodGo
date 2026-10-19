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

def dispatch_order_notification(order, status_key=None, custom_title=None, custom_message=None):
    """
    Safely creates an in-app Notification for the order's customer with rich metadata.
    """
    if not order or not getattr(order, 'customer', None):
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

        return Notification.objects.create(
            user=order.customer,
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
    except Exception as e:
        logger.warning(f"Failed to dispatch order notification for order {getattr(order, 'id', None)}: {e}")
        return None
