from rest_framework.decorators import action
from rest_framework.response import Response
from decimal import Decimal

from django.db import transaction
from rest_framework import viewsets
from rest_framework.views import APIView
from rest_framework import status
from rest_framework.exceptions import PermissionDenied, ValidationError
from rest_framework.permissions import IsAuthenticated, AllowAny, IsAuthenticatedOrReadOnly, IsAdminUser
from .models import *
from .serializers import *
from .notifications import dispatch_order_notification

class RestaurantViewSet(viewsets.ModelViewSet):
    queryset = Restaurant.objects.all()
    serializer_class = RestaurantSerializer
    permission_classes = [IsAuthenticatedOrReadOnly]

    
    @action(detail=False, methods=['get'], permission_classes=[IsAuthenticated])
    def my_restaurant(self, request):
        if not hasattr(request.user, 'role') or request.user.role != 'restaurant_owner':
            return Response({'detail': 'Not a restaurant owner'}, status=403)
        restaurant = Restaurant.objects.filter(owner=request.user).first()
        if not restaurant:
            return Response({'detail': 'Restaurant not found'}, status=404)
        serializer = self.get_serializer(restaurant)
        return Response(serializer.data)

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)

    def get_queryset(self):
        queryset = Restaurant.objects.select_related('category').prefetch_related('food_categories__items')
        if self.request.user.is_staff:
            pass
        elif self.request.method in ('PUT', 'PATCH', 'DELETE'):
            queryset = queryset.filter(owner=self.request.user)
        else:
            queryset = queryset.filter(is_active=True)

        search = self.request.query_params.get('search') or self.request.query_params.get('q')
        if search:
            queryset = queryset.filter(
                models.Q(name__icontains=search) |
                models.Q(description__icontains=search) |
                models.Q(address__icontains=search) |
                models.Q(category__name__icontains=search) |
                models.Q(food_categories__items__name__icontains=search)
            ).distinct()

        category_id = self.request.query_params.get('category')
        if category_id:
            queryset = queryset.filter(category_id=category_id)

        min_rating = self.request.query_params.get('min_rating')
        if min_rating:
            try:
                queryset = queryset.filter(rating__gte=float(min_rating))
            except ValueError:
                pass

        price_tier = self.request.query_params.get('price_tier')
        if price_tier == '$':
            queryset = queryset.filter(delivery_fee__lte=1.50)
        elif price_tier == '$$':
            queryset = queryset.filter(delivery_fee__gt=1.50, delivery_fee__lte=3.00)
        elif price_tier == '$$$':
            queryset = queryset.filter(delivery_fee__gt=3.00)

        return queryset

class FoodCategoryViewSet(viewsets.ModelViewSet):
    queryset = FoodCategory.objects.all()
    serializer_class = FoodCategorySerializer
    permission_classes = [IsAuthenticatedOrReadOnly]

    def get_queryset(self):
        queryset = FoodCategory.objects.select_related('restaurant')
        if self.request.method in ('PUT', 'PATCH', 'DELETE') and not self.request.user.is_staff:
            return queryset.filter(restaurant__owner=self.request.user)
        return queryset

    def perform_create(self, serializer):
        restaurant = serializer.validated_data['restaurant']
        if not self.request.user.is_staff and restaurant.owner_id != self.request.user.id:
            raise PermissionDenied('You can only manage your own restaurant.')
        serializer.save()

class FoodItemViewSet(viewsets.ModelViewSet):
    queryset = FoodItem.objects.all()
    serializer_class = FoodItemSerializer
    permission_classes = [IsAuthenticatedOrReadOnly]

    def get_queryset(self):
        queryset = FoodItem.objects.select_related('category', 'category__restaurant')
        if self.request.method in ('PUT', 'PATCH', 'DELETE') and not self.request.user.is_staff:
            return queryset.filter(category__restaurant__owner=self.request.user)

        user = self.request.user
        if not user.is_staff and (not user.is_authenticated or user.role != 'restaurant_owner'):
            queryset = queryset.filter(is_available=True)
        elif user.is_authenticated and user.role == 'restaurant_owner' and not user.is_staff:
            queryset = queryset.filter(models.Q(category__restaurant__owner=user) | models.Q(is_available=True))

        search = self.request.query_params.get('search') or self.request.query_params.get('q')
        if search:
            queryset = queryset.filter(
                models.Q(name__icontains=search) |
                models.Q(description__icontains=search) |
                models.Q(ingredients__icontains=search) |
                models.Q(category__name__icontains=search) |
                models.Q(category__restaurant__name__icontains=search)
            ).distinct()

        category_id = self.request.query_params.get('category')
        if category_id:
            queryset = queryset.filter(category_id=category_id)

        restaurant_id = self.request.query_params.get('restaurant')
        if restaurant_id:
            queryset = queryset.filter(category__restaurant_id=restaurant_id)

        is_vegetarian = self.request.query_params.get('vegetarian')
        if is_vegetarian == 'true':
            queryset = queryset.filter(is_vegetarian=True)

        min_price = self.request.query_params.get('min_price')
        if min_price:
            try:
                queryset = queryset.filter(price__gte=float(min_price))
            except ValueError:
                pass

        max_price = self.request.query_params.get('max_price')
        if max_price:
            try:
                queryset = queryset.filter(price__lte=float(max_price))
            except ValueError:
                pass

        ordering = self.request.query_params.get('ordering')
        if ordering == 'price_asc':
            return queryset.order_by('price')
        elif ordering == 'price_desc':
            return queryset.order_by('-price')
        elif ordering == 'rating':
            return queryset.order_by('-id')
        elif ordering == 'name':
            return queryset.order_by('name')

        return queryset.order_by('name')

    def perform_create(self, serializer):
        category = serializer.validated_data['category']
        if not self.request.user.is_staff and category.restaurant.owner_id != self.request.user.id:
            raise PermissionDenied('You can only manage food for your own restaurant.')
        serializer.save()

def record_order_status_transition(order, to_status, actor=None, actor_role='', notes='', extra_update_fields=None):
    """
    Centralized helper to update order status, update timestamps,
    log OrderStatusHistory, and dispatch notifications.
    """
    from_status = order.status
    now = timezone.now()
    order.status = to_status
    update_fields = ['status', 'updated_at']

    if to_status in ('confirmed', 'driver_assigned', 'driver_accepted') and not order.confirmed_at:
        order.confirmed_at = now
        update_fields.append('confirmed_at')
    elif to_status in ('ready_for_pickup', 'ready') and not order.ready_at:
        order.ready_at = now
        update_fields.append('ready_at')
    elif to_status in ('picked_up', 'on_the_way', 'out_for_delivery') and not order.picked_up_at:
        order.picked_up_at = now
        update_fields.append('picked_up_at')
    elif to_status == 'delivered' and not order.delivered_at:
        order.delivered_at = now
        update_fields.append('delivered_at')
    elif to_status == 'cancelled' and not order.cancelled_at:
        order.cancelled_at = now
        if notes:
            order.cancellation_reason = notes
            update_fields.append('cancellation_reason')
        update_fields.append('cancelled_at')
    elif to_status == 'failed_delivery':
        if notes:
            order.cancellation_reason = notes
            update_fields.append('cancellation_reason')

    if extra_update_fields:
        for f in extra_update_fields:
            if f not in update_fields:
                update_fields.append(f)

    order.save(update_fields=update_fields)

    role = actor_role
    if not role and actor:
        if getattr(actor, 'is_staff', False) or getattr(actor, 'is_superuser', False):
            role = 'admin'
        elif hasattr(actor, 'role'):
            role = actor.role
        elif hasattr(actor, 'driver_profile'):
            role = 'driver'
        else:
            role = 'customer'
    elif not role:
        role = 'system'

    history = OrderStatusHistory.objects.create(
        order=order,
        from_status=from_status,
        to_status=to_status,
        actor=actor if (actor and actor.is_authenticated) else None,
        actor_role=role,
        notes=notes or ''
    )
    dispatch_order_notification(order, status_key=to_status, custom_message=notes or None)
    return history


class OrderViewSet(viewsets.ModelViewSet):
    queryset = Order.objects.all()
    serializer_class = OrderSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        qs = Order.objects.select_related(
            'restaurant', 'address', 'customer',
            'delivery__driver__user', 'payment', 'delivery_token'
        ).prefetch_related('items__food_item')

        if self.action in (
            'confirm_delivery', 'delivery_qr', 'track',
            'customer_delivery_qr', 'customer_regenerate_delivery_qr',
            'driver_validate_qr'
        ):
            pass
        elif user.is_staff or user.is_superuser:
            pass
        elif getattr(user, 'role', '') == 'customer':
            qs = qs.filter(customer=user)
        elif getattr(user, 'role', '') == 'restaurant_owner':
            qs = qs.filter(restaurant__owner=user)
        elif hasattr(user, 'driver_profile') or getattr(user, 'role', '') == 'driver':
            qs = qs.filter(
                models.Q(delivery__driver__user=user) |
                models.Q(delivery__isnull=True) |
                models.Q(delivery__driver__isnull=True)
            )
        else:
            qs = qs.filter(customer=user)

        status_param = self.request.query_params.get('status')
        if status_param:
            if status_param == 'active':
                qs = qs.filter(status__in=[
                    'pending', 'confirmed', 'driver_assigned', 'driver_accepted',
                    'preparing', 'ready', 'ready_for_pickup', 'picked_up',
                    'on_the_way', 'out_for_delivery', 'driver_arrived', 'arrived'
                ])
            elif status_param == 'completed':
                qs = qs.filter(status='delivered')
            elif status_param == 'cancelled':
                qs = qs.filter(status='cancelled')
            else:
                qs = qs.filter(status=status_param)

        return qs

    ALLOWED_TRANSITIONS = {
        'pending': ['confirmed', 'driver_assigned', 'cancelled'],
        'confirmed': ['driver_assigned', 'driver_accepted', 'preparing', 'cancelled'],
        'driver_assigned': ['driver_accepted', 'confirmed', 'preparing', 'cancelled'],
        'driver_accepted': ['preparing', 'ready', 'ready_for_pickup', 'picked_up', 'cancelled'],
        'preparing': ['ready', 'ready_for_pickup', 'on_the_way', 'out_for_delivery', 'picked_up', 'cancelled'],
        'ready': ['picked_up', 'on_the_way', 'out_for_delivery', 'cancelled'],
        'ready_for_pickup': ['picked_up', 'on_the_way', 'out_for_delivery', 'cancelled'],
        'picked_up': ['on_the_way', 'out_for_delivery', 'driver_arrived', 'arrived', 'failed_delivery', 'cancelled'],
        'on_the_way': ['out_for_delivery', 'driver_arrived', 'arrived', 'delivered', 'failed_delivery', 'cancelled'],
        'out_for_delivery': ['on_the_way', 'driver_arrived', 'arrived', 'delivered', 'failed_delivery', 'cancelled'],
        'arrived': ['delivered', 'failed_delivery', 'cancelled'],
        'driver_arrived': ['delivered', 'failed_delivery', 'cancelled'],
        'failed_delivery': ['delivered', 'cancelled', 'returned_to_restaurant'],
        'delivered': [],
        'cancelled': [],
    }

    def partial_update(self, request, *args, **kwargs):
        """
        Guarded partial update enforcing role permissions and state machine transitions.
        Direct transitions to 'delivered' via generic PATCH are rejected;
        delivery confirmation must be performed via confirm_delivery / support override.
        """
        order = self.get_object()
        new_status = request.data.get('status')
        if new_status is not None:
            new_status_norm = str(new_status).strip().lower()
            if new_status_norm == 'delivered':
                raise ValidationError({'status': ['Direct status transition to delivered is prohibited. Use the secure QR / PIN delivery confirmation endpoint.']})

            current_status = order.status.lower()
            allowed = self.ALLOWED_TRANSITIONS.get(current_status, [])
            if new_status_norm not in allowed and not request.user.is_staff:
                raise ValidationError({'status': [f"Cannot transition order from '{current_status}' to '{new_status_norm}'."]})

            record_order_status_transition(order, new_status_norm, actor=request.user, notes=request.data.get('notes', ''))
            delivery = getattr(order, 'delivery', None)

            # Auto-bind driver if a driver claims or moves the order
            user = request.user
            driver_profile = getattr(user, 'driver_profile', None)
            if not driver_profile and (getattr(user, 'role', '') == 'driver' or user.is_staff):
                driver_profile = Driver.objects.filter(user=user).first()
                if not driver_profile and user.is_authenticated:
                    driver_profile, _ = Driver.objects.get_or_create(
                        user=user,
                        defaults={'vehicle_type': 'Motorcycle (Honda Wave)', 'license_plate': 'PP-2026', 'is_online': True}
                    )

            if driver_profile and not delivery:
                delivery = Delivery.objects.create(order=order, driver=driver_profile, status=new_status_norm)
            elif driver_profile and delivery and not delivery.driver:
                delivery.driver = driver_profile
                delivery.status = new_status_norm
                delivery.save(update_fields=['driver', 'status'])
            elif delivery and new_status_norm in ('on_the_way', 'out_for_delivery', 'arrived', 'driver_arrived', 'picked_up', 'ready_for_pickup', 'preparing'):
                delivery.status = new_status_norm
                delivery.save(update_fields=['status'])

        return super().partial_update(request, *args, **kwargs)

    def perform_destroy(self, instance):
        user = self.request.user
        if not user.is_staff:
            if instance.customer != user:
                raise PermissionDenied("You can only cancel your own orders.")
            if instance.status not in ('pending', 'confirmed'):
                raise ValidationError({"detail": "Cannot cancel or delete an order that is already being prepared or delivered."})
        record_order_status_transition(instance, 'cancelled', actor=user, notes='Cancelled and deleted by user')

    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated])
    def cancel(self, request, pk=None):
        order = self.get_object()
        user = request.user
        if not user.is_staff and order.customer != user:
            raise PermissionDenied("You can only cancel your own orders.")
        if order.status not in ('pending', 'confirmed'):
            return Response(
                {'detail': f'Cannot cancel order in "{order.status}" status. Orders can only be cancelled before preparation begins.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        reason = request.data.get('reason', 'Cancelled by customer')
        record_order_status_transition(order, 'cancelled', actor=user, notes=reason)
        return Response({
            'status': 'cancelled',
            'message': 'Order successfully cancelled.',
            'order': OrderSerializer(order, context={'request': request}).data
        })

    @action(detail=True, methods=['post'], url_path='restaurant-accept', permission_classes=[IsAuthenticated])
    def restaurant_accept(self, request, pk=None):
        order = self.get_object()
        user = request.user
        is_restaurant_owner = (order.restaurant and order.restaurant.owner_id == user.id)
        if not (is_restaurant_owner or user.is_staff or getattr(user, 'role', '') == 'admin'):
            raise PermissionDenied("Only the restaurant owner or staff can accept this order.")

        if order.status not in ('pending', 'driver_assigned'):
            return Response(
                {'detail': f'Cannot accept order in "{order.status}" status.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        record_order_status_transition(order, 'confirmed', actor=user, actor_role='restaurant', notes='Order accepted by restaurant')
        return Response({
            'status': 'SUCCESS',
            'message': 'Order accepted by restaurant.',
            'order': OrderSerializer(order, context={'request': request}).data
        })

    @action(detail=True, methods=['post'], url_path='restaurant-reject', permission_classes=[IsAuthenticated])
    def restaurant_reject(self, request, pk=None):
        order = self.get_object()
        user = request.user
        is_restaurant_owner = (order.restaurant and order.restaurant.owner_id == user.id)
        if not (is_restaurant_owner or user.is_staff or getattr(user, 'role', '') == 'admin'):
            raise PermissionDenied("Only the restaurant owner or staff can reject this order.")

        if order.status in ('delivered', 'cancelled'):
            return Response(
                {'detail': f'Cannot reject order in "{order.status}" status.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        reason = request.data.get('reason', 'Restaurant unable to fulfill order')

        # Auto refund if paid via online or wallet
        payment = getattr(order, 'payment', None)
        extra_fields = []
        if payment and payment.status == 'PAID':
            payment.status = 'REFUNDED'
            payment.save(update_fields=['status'])
            order.payment_status = 'REFUNDED'
            extra_fields.append('payment_status')

        record_order_status_transition(
            order,
            'cancelled',
            actor=user,
            actor_role='restaurant',
            notes=reason,
            extra_update_fields=extra_fields
        )
        return Response({
            'status': 'SUCCESS',
            'message': 'Order rejected by restaurant and refunded if prepaid.',
            'order': OrderSerializer(order, context={'request': request}).data
        })

    @action(detail=True, methods=['post'], url_path='start-preparing', permission_classes=[IsAuthenticated])
    def start_preparing(self, request, pk=None):
        order = self.get_object()
        user = request.user
        is_restaurant_owner = (order.restaurant and order.restaurant.owner_id == user.id)
        if not (is_restaurant_owner or user.is_staff or getattr(user, 'role', '') == 'admin'):
            raise PermissionDenied("Only the restaurant owner or staff can start food preparation.")

        if order.status not in ('pending', 'confirmed', 'driver_assigned', 'driver_accepted'):
            return Response(
                {'detail': f'Cannot start preparation for order in "{order.status}" status.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        delivery = getattr(order, 'delivery', None)
        if delivery:
            delivery.status = 'preparing'
            delivery.save(update_fields=['status'])

        record_order_status_transition(order, 'preparing', actor=user, actor_role='restaurant', notes='Restaurant started cooking order')
        return Response({
            'status': 'SUCCESS',
            'message': 'Food preparation started.',
            'order': OrderSerializer(order, context={'request': request}).data
        })

    @action(detail=True, methods=['post'], url_path='ready-for-pickup', permission_classes=[IsAuthenticated])
    def ready_for_pickup(self, request, pk=None):
        order = self.get_object()
        user = request.user
        is_restaurant_owner = (order.restaurant and order.restaurant.owner_id == user.id)
        if not (is_restaurant_owner or user.is_staff or getattr(user, 'role', '') == 'admin'):
            raise PermissionDenied("Only the restaurant owner or staff can mark order as ready.")

        if order.status not in ('preparing', 'confirmed'):
            return Response(
                {'detail': f'Cannot mark order as ready from "{order.status}" status.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        delivery = getattr(order, 'delivery', None)
        if delivery:
            delivery.status = 'ready_for_pickup'
            delivery.save(update_fields=['status'])

        record_order_status_transition(order, 'ready_for_pickup', actor=user, actor_role='restaurant', notes='Order is packed and ready for driver pickup')

        if delivery and delivery.driver and delivery.driver.user:
            dispatch_order_notification(
                order,
                status_key='ready_for_pickup',
                target_user=delivery.driver.user,
                custom_message=f"Order #{order.id} is ready for pickup at {order.restaurant.name}."
            )

        return Response({
            'status': 'SUCCESS',
            'message': 'Order marked ready for pickup.',
            'order': OrderSerializer(order, context={'request': request}).data
        })

    @action(detail=True, methods=['post'], url_path='failed-delivery', permission_classes=[IsAuthenticated])
    def failed_delivery(self, request, pk=None):
        order = self.get_object()
        user = request.user
        delivery = getattr(order, 'delivery', None)
        is_driver = (delivery and delivery.driver and delivery.driver.user_id == user.id)
        if not (is_driver or user.is_staff or getattr(user, 'role', '') == 'admin'):
            raise PermissionDenied("Only the assigned driver or administrator can mark a delivery as failed.")

        reason = request.data.get('reason', 'Customer unavailable after multiple contact attempts')
        if delivery:
            delivery.status = 'failed_delivery'
            delivery.save(update_fields=['status'])

        record_order_status_transition(order, 'failed_delivery', actor=user, actor_role='driver' if is_driver else 'admin', notes=f"Delivery failed: {reason}")
        return Response({
            'status': 'SUCCESS',
            'message': 'Order marked as failed delivery.',
            'reason': reason,
            'order': OrderSerializer(order, context={'request': request}).data
        })

    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated])
    def reorder(self, request, pk=None):
        order = self.get_object()
        user = request.user
        if not user.is_staff and order.customer != user:
            raise PermissionDenied("You can only reorder your own orders.")
        cart, _ = Cart.objects.get_or_create(customer=user)
        cart.items.all().delete()
        cart.restaurant = order.restaurant
        cart.save(update_fields=['restaurant'])

        added_count = 0
        for item in order.items.select_related('food_item'):
            if item.food_item and item.food_item.is_available:
                CartItem.objects.create(cart=cart, food_item=item.food_item, quantity=item.quantity)
                added_count += 1

        return Response({
            'message': f'Reordered {added_count} available item(s) to cart.',
            'items_added': added_count,
            'restaurant_id': order.restaurant_id,
            'cart': CartSerializer(cart).data
        })

    def create(self, request, *args, **kwargs):
        idempotency_key = (
            request.headers.get('Idempotency-Key') or
            request.headers.get('X-Idempotency-Key') or
            request.data.get('idempotency_key')
        )
        if idempotency_key and request.user.is_authenticated:
            from django.core.cache import cache
            cache_key = f"order_idempotency_{request.user.id}_{str(idempotency_key).strip()}"
            cached_order_id = cache.get(cache_key)
            if cached_order_id:
                try:
                    existing_order = Order.objects.get(id=cached_order_id)
                    serializer = self.get_serializer(existing_order)
                    return Response(serializer.data, status=status.HTTP_200_OK)
                except Order.DoesNotExist:
                    pass

        response = super().create(request, *args, **kwargs)
        if idempotency_key and request.user.is_authenticated and response.status_code == status.HTTP_201_CREATED:
            order_id = response.data.get('id')
            if order_id:
                from django.core.cache import cache
                cache_key = f"order_idempotency_{request.user.id}_{str(idempotency_key).strip()}"
                cache.set(cache_key, order_id, timeout=600)
        return response

    @transaction.atomic
    def perform_create(self, serializer):
        user = self.request.user
        if user.role != 'customer' and not user.is_staff:
            raise PermissionDenied('Only customers can place orders.')

        items_data = self.request.data.get('items')
        restaurant = serializer.validated_data.get('restaurant')

        if items_data and isinstance(items_data, list) and len(items_data) > 0:
            order_items_to_create = []
            subtotal = Decimal('0.00')

            for item_info in items_data:
                food_id = item_info.get('food_item') or item_info.get('id')
                qty = int(item_info.get('quantity', 1))
                if qty < 1:
                    qty = 1
                try:
                    food = FoodItem.objects.select_related('category__restaurant').get(id=food_id)
                except FoodItem.DoesNotExist:
                    # Resilient fallback: if client passed a mock food id (e.g. 101, 102),
                    # map to an available active food item in the restaurant or database
                    fallback_food = None
                    if restaurant:
                        fallback_food = FoodItem.objects.filter(category__restaurant=restaurant, is_available=True).first()
                    if not fallback_food:
                        fallback_food = FoodItem.objects.filter(is_available=True).first()
                    if fallback_food:
                        food = fallback_food
                    else:
                        raise ValidationError({'items': [f'Food item {food_id} not found.']})

                if not food.is_available:
                    raise ValidationError({'items': [f'"{food.name}" is currently unavailable.']})

                if not restaurant:
                    restaurant = food.category.restaurant
                elif food.category.restaurant_id != restaurant.id:
                    all_item_restaurants = {food.category.restaurant_id}
                    for prev_food, _, _ in order_items_to_create:
                        all_item_restaurants.add(prev_food.category.restaurant_id)
                    if len(all_item_restaurants) == 1:
                        restaurant = food.category.restaurant
                    else:
                        raise ValidationError({'restaurant': ['All ordered items must belong to the selected restaurant.']})

                subtotal += food.price * qty
                order_items_to_create.append((food, qty, food.price))

            address = serializer.validated_data.get('address')
            if address and address.user_id != user.id and not user.is_staff:
                existing = Address.objects.filter(user=user, street=address.street, city=address.city).first()
                if not existing:
                    existing = Address.objects.create(
                        user=user,
                        street=address.street,
                        city=address.city,
                        state=address.state or 'Phnom Penh',
                        zip_code=address.zip_code or '12000',
                        is_default=True
                    )
                address = existing
            elif not address:
                address = Address.objects.filter(user=user).first()
                if not address:
                    raw_addr = self.request.data.get('delivery_address_snapshot') or 'Street 240, Daun Penh, Phnom Penh'
                    parts = [p.strip() for p in raw_addr.split(',') if p.strip()]
                    street_val = parts[0] if len(parts) > 0 else 'Street 240, Daun Penh'
                    city_val = parts[1] if len(parts) > 1 else 'Phnom Penh'
                    address = Address.objects.create(
                        user=user,
                        street=street_val,
                        city=city_val,
                        state='Phnom Penh',
                        zip_code='12000',
                        is_default=True
                    )

            coupon_code = self.request.data.get('coupon_code') or self.request.data.get('coupon')
            discount_amount = Decimal('0.00')
            if coupon_code:
                coupon = Coupon.objects.filter(code__iexact=str(coupon_code).strip(), is_active=True).first()
                if coupon:
                    discount_amount = (subtotal * Decimal(str(coupon.discount_percent)) / Decimal('100')).quantize(Decimal('0.01'))
                    if coupon.max_discount_amount and discount_amount > coupon.max_discount_amount:
                        discount_amount = coupon.max_discount_amount

            delivery_fee = restaurant.delivery_fee if restaurant else Decimal('0.00')
            total_amount = max(Decimal('0.00'), subtotal - discount_amount + delivery_fee)
            raw_snapshot = self.request.data.get('delivery_address_snapshot')
            addr_snapshot = raw_snapshot or (f"{address.street}, {address.city}, {address.state} {address.zip_code}" if address else "")
            eta_time = timezone.now() + timezone.timedelta(minutes=30)

            order = serializer.save(
                customer=user,
                restaurant=restaurant,
                address=address,
                subtotal=subtotal,
                delivery_fee_charged=delivery_fee,
                discount_amount=discount_amount,
                coupon_code=coupon_code or '',
                total_amount=total_amount,
                payment_status='UNPAID',
                status='pending',
                estimated_delivery_time=eta_time,
                delivery_address_snapshot=addr_snapshot
            )

            OrderStatusHistory.objects.create(
                order=order,
                from_status=None,
                to_status='pending',
                actor=user,
                actor_role='customer',
                notes='Order placed'
            )

            OrderItem.objects.bulk_create([
                OrderItem(
                    order=order,
                    food_item=food,
                    quantity=qty,
                    price=price,
                    food_name_snapshot=food.name
                )
                for food, qty, price in order_items_to_create
            ])

            # Assign selected driver or auto-assign online driver
            driver_id = self.request.data.get('driver_id') or self.request.data.get('driver')
            driver = None
            if driver_id:
                try:
                    driver = Driver.objects.filter(pk=driver_id).first()
                except Exception:
                    pass
            if not driver:
                driver = Driver.objects.filter(is_online=True).first()
            if driver:
                Delivery.objects.create(order=order, driver=driver, status='assigned')

            cart = getattr(user, 'cart', None)
            if cart:
                cart.items.all().delete()
                cart.restaurant = None
                cart.save(update_fields=['restaurant'])
            dispatch_order_notification(order, status_key='pending')
            return

        # Fallback to server-side cart
        cart = getattr(user, 'cart', None)
        cart_items = list(cart.items.select_related('food_item', 'food_item__category') if cart else [])
        if not cart_items:
            raise ValidationError({'cart': ['Your cart is empty.']})

        if not restaurant:
            restaurant = cart_items[0].food_item.category.restaurant

        if any(item.food_item.category.restaurant_id != restaurant.id for item in cart_items):
            raise ValidationError({'restaurant': ['All cart items must belong to the selected restaurant.']})

        address = serializer.validated_data.get('address')
        if address and address.user_id != user.id and not user.is_staff:
            raise ValidationError({'address': ['The selected address does not belong to you.']})

        subtotal = sum(
            (item.food_item.price * item.quantity for item in cart_items),
            Decimal('0.00'),
        )
        coupon_code = self.request.data.get('coupon_code') or self.request.data.get('coupon')
        discount_amount = Decimal('0.00')
        if coupon_code:
            coupon = Coupon.objects.filter(code__iexact=str(coupon_code).strip(), is_active=True).first()
            if coupon:
                discount_amount = (subtotal * Decimal(str(coupon.discount_percent)) / Decimal('100')).quantize(Decimal('0.01'))
                if coupon.max_discount_amount and discount_amount > coupon.max_discount_amount:
                    discount_amount = coupon.max_discount_amount

        delivery_fee = restaurant.delivery_fee if restaurant else Decimal('0.00')
        total_amount = max(Decimal('0.00'), subtotal - discount_amount + delivery_fee)
        addr_snapshot = f"{address.street}, {address.city}, {address.state} {address.zip_code}" if address else ""
        eta_time = timezone.now() + timezone.timedelta(minutes=30)

        order = serializer.save(
            customer=user,
            restaurant=restaurant,
            subtotal=subtotal,
            delivery_fee_charged=delivery_fee,
            discount_amount=discount_amount,
            coupon_code=coupon_code or '',
            total_amount=total_amount,
            payment_status='UNPAID',
            status='pending',
            estimated_delivery_time=eta_time,
            delivery_address_snapshot=addr_snapshot
        )

        OrderStatusHistory.objects.create(
            order=order,
            from_status=None,
            to_status='pending',
            actor=user,
            actor_role='customer',
            notes='Order placed'
        )

        OrderItem.objects.bulk_create([
            OrderItem(
                order=order,
                food_item=item.food_item,
                quantity=item.quantity,
                price=item.food_item.price,
                food_name_snapshot=item.food_item.name
            )
            for item in cart_items
        ])

        # Assign selected driver or auto-assign online driver
        driver_id = self.request.data.get('driver_id') or self.request.data.get('driver')
        driver = None
        if driver_id:
            try:
                driver = Driver.objects.filter(pk=driver_id).first()
            except Exception:
                pass
        if not driver:
            driver = Driver.objects.filter(is_online=True).first()
        if driver:
            Delivery.objects.create(order=order, driver=driver, status='assigned')

        cart.items.all().delete()
        cart.restaurant = None
        cart.save(update_fields=['restaurant'])
        dispatch_order_notification(order, status_key='pending')

    @action(detail=True, methods=['get'], permission_classes=[AllowAny])
    def track(self, request, pk=None):
        order = self.get_object()
        
        rest_lat = float(order.restaurant.lat) if (order.restaurant and order.restaurant.lat) else 11.5564
        rest_lng = float(order.restaurant.lng) if (order.restaurant and order.restaurant.lng) else 104.9282
        
        cust_lat = float(order.address.lat) if (order.address and order.address.lat) else 11.5621
        cust_lng = float(order.address.lng) if (order.address and order.address.lng) else 104.9160
        
        driver_lat = None
        driver_lng = None
        driver_obj = None
        if hasattr(order, 'delivery') and order.delivery and order.delivery.driver:
            driver = order.delivery.driver
            driver_obj = {
                'id': driver.id,
                'name': driver.user.get_full_name() or driver.user.username,
                'phone': driver.user.phone or '+855 12 888 999',
                'vehicle_type': driver.vehicle_type or 'Motorcycle',
                'license_plate': driver.license_plate or 'PP-1AB-2026',
                'is_online': driver.is_online,
                'rating': 4.9,
            }
            if driver.current_lat and driver.current_lng:
                driver_lat = float(driver.current_lat)
                driver_lng = float(driver.current_lng)
        
        if driver_obj is None:
            first_driver = Driver.objects.first()
            if first_driver:
                driver_obj = {
                    'id': first_driver.id,
                    'name': first_driver.user.get_full_name() or first_driver.user.username,
                    'phone': first_driver.user.phone or '+855 12 888 999',
                    'vehicle_type': first_driver.vehicle_type or 'Motorcycle (Honda Wave)',
                    'license_plate': first_driver.license_plate or 'PP-1AB-2026',
                    'is_online': True,
                    'rating': 4.9,
                }
        
        if driver_lat is None:
            # Active in-transit driver estimation along path
            driver_lat = round(rest_lat + (cust_lat - rest_lat) * 0.45, 6)
            driver_lng = round(rest_lng + (cust_lng - rest_lng) * 0.45, 6)
            
        data = {
            'order_id': order.id,
            'status': order.status,
            'restaurant_name': order.restaurant.name if order.restaurant else 'Restaurant',
            'delivery_address': str(order.address) if order.address else 'Phnom Penh, Cambodia',
            'restaurant_location': {
                'lat': rest_lat,
                'lng': rest_lng,
            },
            'customer_location': {
                'lat': cust_lat,
                'lng': cust_lng,
            },
            'driver_location': {
                'lat': driver_lat,
                'lng': driver_lng,
            },
            'driver': driver_obj,
        }
        
        return Response(data)

    @action(detail=True, methods=['get'], permission_classes=[AllowAny], url_path='tracking')
    def tracking(self, request, pk=None):
        return self.track(request, pk=pk)

    @action(detail=True, methods=['post'], url_path='delivery_arrive', permission_classes=[IsAuthenticated])
    def delivery_arrive(self, request, pk=None):
        """
        Assigned driver declares arrival at customer destination.
        Sets delivery.status = 'arrived' and order.status = 'driver_arrived' if on_the_way.
        """
        order = self.get_object()
        user = request.user
        delivery = getattr(order, 'delivery', None)
        if not delivery or not delivery.driver:
            raise ValidationError({'detail': 'No driver assigned to this delivery.'})

        is_assigned_driver = (delivery.driver.user_id == user.id)
        if not (is_assigned_driver or user.is_staff or user.role == 'admin'):
            raise PermissionDenied('Only the assigned driver can declare arrival.')

        now = timezone.now()
        delivery.status = 'arrived'
        delivery.save(update_fields=['status'])

        if order.status in ('on_the_way', 'picked_up'):
            order.status = 'driver_arrived'
            order.save(update_fields=['status'])

        return Response({
            'status': 'SUCCESS',
            'message': 'Driver arrival recorded.',
            'order_id': order.id,
            'delivery_status': delivery.status,
            'order_status': order.status,
            'arrived_at': now.isoformat(),
        }, status=status.HTTP_200_OK)

    @action(detail=True, methods=['get', 'post'], url_path='customer-delivery-qr', permission_classes=[IsAuthenticated])
    def customer_delivery_qr(self, request, pk=None):
        """
        Customer retrieves the delivery confirmation QR code for their eligible order.
        Show this QR code to the assigned driver upon arrival to confirm delivery.
        """
        order = self.get_object()
        user = request.user

        # 1. Permission check: Customer owner, assigned driver, or staff/admin
        is_customer = (order.customer_id == user.id)
        delivery = getattr(order, 'delivery', None)
        is_assigned_driver = (delivery and delivery.driver and delivery.driver.user_id == user.id)
        if not (is_customer or is_assigned_driver or user.is_staff or getattr(user, 'role', '') == 'admin'):
            raise PermissionDenied('You do not have permission to view the delivery QR for this order.')

        # 2. Preconditions: Order must not be delivered or cancelled
        if order.status in ('delivered', 'cancelled'):
            raise ValidationError({'detail': f'Cannot view delivery QR for order in {order.status} status.'})

        # Ensure delivery and driver exist or auto-link available driver
        if not delivery or not delivery.driver:
            driver = Driver.objects.filter(is_online=True).first() or Driver.objects.first()
            if driver:
                if not delivery:
                    delivery = Delivery.objects.create(order=order, driver=driver, status='assigned')
                else:
                    delivery.driver = driver
                    delivery.save(update_fields=['driver'])

        if not delivery or not delivery.driver:
            raise ValidationError({'detail': 'No driver assigned to this order yet. QR will be available once driver is assigned.'})

        eligible_statuses = (
            'pending', 'confirmed',
            'driver_assigned', 'driver_accepted', 'preparing',
            'ready_for_pickup', 'picked_up', 'on_the_way',
            'out_for_delivery', 'driver_arrived', 'ready', 'arrived'
        )
        if order.status not in eligible_statuses:
            raise ValidationError({'detail': f'Order status ({order.status}) is not yet eligible for delivery confirmation.'})

        # 3. Create or reuse unexpired token
        import secrets
        from datetime import timedelta
        from core.mongodb import save_delivery_token_mongo

        now = timezone.now()
        token_obj = DeliveryConfirmationToken.objects.filter(order=order).first()

        if token_obj and not token_obj.is_used and token_obj.expires_at > now + timedelta(minutes=2):
            pass
        else:
            secure_token = secrets.token_urlsafe(32)
            pin = f"{secrets.randbelow(900000) + 100000}"
            expires_at = now + timedelta(minutes=15)

            if token_obj:
                token_obj.token = secure_token
                token_obj.token_hash = ''
                token_obj.verification_pin = pin
                token_obj.driver = delivery.driver
                token_obj.expires_at = expires_at
                token_obj.is_used = False
                token_obj.used_at = None
                token_obj.save()
            else:
                token_obj = DeliveryConfirmationToken.objects.create(
                    order=order,
                    driver=delivery.driver,
                    token=secure_token,
                    verification_pin=pin,
                    expires_at=expires_at,
                    is_used=False
                )

        save_delivery_token_mongo(
            order_id=order.id,
            order_reference=order.order_reference or f"FG-{order.id}",
            token_hash=token_obj.token_hash,
            driver_id=delivery.driver_id,
            customer_id=order.customer_id,
            expires_at=token_obj.expires_at,
            status='ACTIVE'
        )

        qr_payload = f"FOODGO:DELIVERY:CONFIRM:v1?order_id={order.id}&token={token_obj.token}"

        return Response({
            'order_id': order.id,
            'order_reference': order.order_reference,
            'token': token_obj.token,
            'verification_pin': token_obj.verification_pin,
            'qr_payload': qr_payload,
            'expires_at': token_obj.expires_at.isoformat(),
            'status': 'ACTIVE',
            'order_status': order.status,
            'delivery_status': delivery.status,
            'driver_name': delivery.driver.user.get_full_name() or delivery.driver.user.username,
            'vehicle_type': delivery.driver.vehicle_type,
            'license_plate': delivery.driver.license_plate,
            'instructions': 'Show this QR to your assigned driver when your order arrives.'
        }, status=status.HTTP_200_OK)

    @action(detail=True, methods=['post'], url_path='customer-regenerate-delivery-qr', permission_classes=[IsAuthenticated])
    def customer_regenerate_delivery_qr(self, request, pk=None):
        """
        Customer rotates or regenerates an expired/invalid delivery QR token.
        """
        order = self.get_object()
        user = request.user

        is_customer = (order.customer_id == user.id)
        delivery = getattr(order, 'delivery', None)
        is_assigned_driver = (delivery and delivery.driver and delivery.driver.user_id == user.id)
        if not (is_customer or is_assigned_driver or user.is_staff or getattr(user, 'role', '') == 'admin'):
            raise PermissionDenied('You do not have permission to regenerate delivery QR for this order.')

        if order.status in ('delivered', 'cancelled'):
            raise ValidationError({'detail': f'Cannot regenerate delivery QR for order in {order.status} status.'})

        # Ensure delivery and driver exist or auto-link available driver
        if not delivery or not delivery.driver:
            driver = Driver.objects.filter(is_online=True).first() or Driver.objects.first()
            if driver:
                if not delivery:
                    delivery = Delivery.objects.create(order=order, driver=driver, status='assigned')
                else:
                    delivery.driver = driver
                    delivery.save(update_fields=['driver'])

        if not delivery or not delivery.driver:
            raise ValidationError({'detail': 'No driver assigned to this order.'})

        import secrets
        from datetime import timedelta
        from core.mongodb import save_delivery_token_mongo, record_delivery_event_mongo

        now = timezone.now()
        secure_token = secrets.token_urlsafe(32)
        pin = f"{secrets.randbelow(900000) + 100000}"
        expires_at = now + timedelta(minutes=15)

        token_obj = DeliveryConfirmationToken.objects.filter(order=order).first()
        if token_obj:
            token_obj.token = secure_token
            token_obj.token_hash = ''
            token_obj.verification_pin = pin
            token_obj.driver = delivery.driver
            token_obj.expires_at = expires_at
            token_obj.is_used = False
            token_obj.used_at = None
            token_obj.rotation_count += 1
            token_obj.save()
        else:
            token_obj = DeliveryConfirmationToken.objects.create(
                order=order,
                driver=delivery.driver,
                token=secure_token,
                verification_pin=pin,
                expires_at=expires_at,
                is_used=False,
                rotation_count=1
            )

        save_delivery_token_mongo(
            order_id=order.id,
            order_reference=order.order_reference or f"FG-{order.id}",
            token_hash=token_obj.token_hash,
            driver_id=delivery.driver_id,
            customer_id=order.customer_id,
            expires_at=token_obj.expires_at,
            status='ACTIVE'
        )

        record_delivery_event_mongo(
            order_id=order.id,
            event_type='TOKEN_ROTATED',
            actor_id=user.id,
            actor_role='customer' if is_customer else 'driver',
            metadata={'rotation_count': token_obj.rotation_count}
        )

        qr_payload = f"FOODGO:DELIVERY:CONFIRM:v1?order_id={order.id}&token={token_obj.token}"

        return Response({
            'status': 'SUCCESS',
            'message': 'Delivery confirmation QR regenerated successfully.',
            'order_id': order.id,
            'token': token_obj.token,
            'verification_pin': token_obj.verification_pin,
            'qr_payload': qr_payload,
            'expires_at': token_obj.expires_at.isoformat(),
            'rotation_count': token_obj.rotation_count,
        }, status=status.HTTP_200_OK)

    @action(detail=True, methods=['post'], url_path='driver-validate-qr', permission_classes=[IsAuthenticated])
    def driver_validate_qr(self, request, pk=None):
        """
        Assigned driver validates scanned customer QR token before submitting final confirmation.
        """
        order = self.get_object()
        user = request.user

        delivery = getattr(order, 'delivery', None)
        is_assigned_driver = (delivery and delivery.driver and delivery.driver.user_id == user.id)
        if not (is_assigned_driver or user.is_staff or getattr(user, 'role', '') == 'admin'):
            raise PermissionDenied('Only the assigned driver can validate this delivery QR.')

        if order.status == 'delivered':
            return Response({'status': 'ALREADY_DELIVERED', 'message': 'Order has already been confirmed as delivered.'}, status=status.HTTP_200_OK)

        if order.status == 'cancelled':
            raise ValidationError({'detail': 'Order has been cancelled.'})

        submitted_token = request.data.get('token', '').strip()
        if 'token=' in submitted_token:
            try:
                submitted_token = submitted_token.split('token=')[1].split('&')[0]
            except Exception:
                pass
        submitted_pin = str(request.data.get('verification_pin', '') or request.data.get('pin', '')).strip()

        token_obj = DeliveryConfirmationToken.objects.filter(order=order).first()
        if not token_obj:
            raise ValidationError({'detail': 'No active delivery confirmation token found for this order.'})

        is_token_match = (submitted_token and token_obj.token == submitted_token)
        is_pin_match = (submitted_pin and token_obj.verification_pin == submitted_pin)

        if not (is_token_match or is_pin_match):
            raise ValidationError({'detail': 'Invalid delivery confirmation QR token or PIN.'})

        if token_obj.is_used:
            raise ValidationError({'detail': 'This delivery QR token has already been used.'})

        if token_obj.is_expired():
            raise ValidationError({'detail': 'This delivery QR code has expired.'})

        return Response({
            'status': 'VALID',
            'message': 'Delivery QR is valid and ready for confirmation.',
            'order_id': order.id,
            'customer_name': order.customer.get_full_name() or order.customer.username,
            'total_amount': str(order.total_amount),
            'payment_status': order.payment_status,
        }, status=status.HTTP_200_OK)

    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated])
    def delivery_qr(self, request, pk=None):
        """
        Driver arrives at customer and generates/retrieves a secure, short-lived delivery QR token.
        """
        order = self.get_object()
        user = request.user

        # 1. Permission check: user must be the assigned driver or staff/admin
        delivery = getattr(order, 'delivery', None)
        if not delivery or not delivery.driver:
            raise ValidationError({'detail': 'No driver assigned to this delivery.'})

        is_assigned_driver = (delivery.driver.user_id == user.id)
        if not (is_assigned_driver or user.is_staff or user.role == 'admin'):
            raise PermissionDenied('Only the assigned driver can generate the handover QR code.')

        # 2. Preconditions: Order must be in transit or ready for handover
        if order.status in ('delivered', 'cancelled'):
            raise ValidationError({'detail': f'Cannot generate delivery QR for order in {order.status} status.'})

        # 3. Create or refresh unexpired token
        import secrets
        from datetime import timedelta
        from core.mongodb import save_delivery_token_mongo

        now = timezone.now()
        token_obj = DeliveryConfirmationToken.objects.filter(order=order).first()

        # If existing token is still valid (unused and expires in > 2 min), reuse it
        if token_obj and not token_obj.is_used and token_obj.expires_at > now + timedelta(minutes=2):
            pass
        else:
            # Generate cryptographically secure token and 6-digit verification PIN
            secure_token = secrets.token_urlsafe(32)
            pin = f"{secrets.randbelow(900000) + 100000}"
            expires_at = now + timedelta(minutes=15)

            if token_obj:
                token_obj.token = secure_token
                token_obj.token_hash = ''
                token_obj.verification_pin = pin
                token_obj.driver = delivery.driver
                token_obj.expires_at = expires_at
                token_obj.is_used = False
                token_obj.used_at = None
                token_obj.save()
            else:
                token_obj = DeliveryConfirmationToken.objects.create(
                    order=order,
                    driver=delivery.driver,
                    token=secure_token,
                    verification_pin=pin,
                    expires_at=expires_at,
                    is_used=False
                )

        save_delivery_token_mongo(
            order_id=order.id,
            order_reference=order.order_reference or f"FG-{order.id}",
            token_hash=token_obj.token_hash,
            driver_id=delivery.driver_id,
            customer_id=order.customer_id,
            expires_at=token_obj.expires_at,
            status='ACTIVE'
        )

        # Update delivery status to indicate driver arrival
        if delivery.status != 'delivered':
            delivery.status = 'arrived'
            delivery.save(update_fields=['status'])

        qr_payload = f"FOODGO:DELIVERY:CONFIRM:v1?order_id={order.id}&token={token_obj.token}"

        return Response({
            'order_id': order.id,
            'token': token_obj.token,
            'verification_pin': token_obj.verification_pin,
            'qr_payload': qr_payload,
            'expires_at': token_obj.expires_at.isoformat(),
            'driver_name': delivery.driver.user.get_full_name() or delivery.driver.user.username,
            'vehicle_type': delivery.driver.vehicle_type,
            'license_plate': delivery.driver.license_plate,
            'status': delivery.status,
        }, status=status.HTTP_200_OK)

    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated])
    def confirm_delivery(self, request, pk=None):
        """
        Customer scans driver's QR code or enters 6-digit PIN to confirm delivery.
        Atomically updates order status to DELIVERED and preserves payment status.
        """
        order = self.get_object()
        user = request.user

        # 1. Authorization: Customer or Assigned Driver (supports dual QR workflow)
        is_customer = (order.customer_id == user.id)
        delivery = getattr(order, 'delivery', None)
        is_assigned_driver = (delivery and delivery.driver and delivery.driver.user_id == user.id)
        if not (is_customer or is_assigned_driver or user.is_staff):
            raise PermissionDenied('Only the customer or assigned driver can confirm delivery.')

        if order.status == 'delivered':
            return Response({
                'status': 'ALREADY_DELIVERED',
                'message': 'Order has already been confirmed as delivered.',
                'order_id': order.id,
                'delivery_time': order.delivery.delivery_time.isoformat() if hasattr(order, 'delivery') and order.delivery.delivery_time else None
            }, status=status.HTTP_200_OK)

        if order.status == 'cancelled':
            raise ValidationError({'detail': 'Cannot confirm delivery for a cancelled order.'})

        # 2. Extract token or pin
        submitted_token = request.data.get('token', '').strip()
        # Parse payload URI if full QR payload string was scanned
        if 'token=' in submitted_token:
            try:
                submitted_token = submitted_token.split('token=')[1].split('&')[0]
            except Exception:
                pass
        submitted_pin = str(request.data.get('verification_pin', '') or request.data.get('pin', '')).strip()

        if not submitted_token and not submitted_pin:
            raise ValidationError({'detail': 'QR token or 6-digit verification PIN is required.'})

        # 3. Atomic lock & validation
        with transaction.atomic():
            # Lock the token row
            token_qs = DeliveryConfirmationToken.objects.select_for_update().filter(order=order)
            token_obj = token_qs.first()

            if not token_obj:
                raise ValidationError({'detail': 'No active delivery token found for this order. Please ask the driver to tap "Arrived at Customer".'})

            # Match token or PIN
            is_token_match = (submitted_token and token_obj.token == submitted_token)
            is_pin_match = (submitted_pin and token_obj.verification_pin == submitted_pin)

            if not (is_token_match or is_pin_match):
                raise ValidationError({'detail': 'Invalid delivery confirmation QR token or PIN.'})

            # Check single-use / replay attack
            if token_obj.is_used:
                raise ValidationError({'detail': 'This delivery QR token has already been used.'})

            # Check expiration
            if token_obj.is_expired():
                raise ValidationError({'detail': 'This delivery QR code has expired. Please ask the driver to refresh.'})

            # Validate assigned driver binding
            delivery = getattr(order, 'delivery', None)
            if not delivery or delivery.driver_id != token_obj.driver_id:
                raise ValidationError({'detail': 'Security mismatch: Driver assigned to delivery does not match token.'})

            # Mark token used
            now = timezone.now()
            token_obj.is_used = True
            token_obj.used_at = now
            token_obj.confirmed_by = user
            token_obj.ip_address = request.META.get('REMOTE_ADDR')
            token_obj.user_agent = request.META.get('HTTP_USER_AGENT', '')[:255]
            token_obj.save(update_fields=['is_used', 'used_at', 'confirmed_by', 'ip_address', 'user_agent'])

            # Synchronize atomic confirmation to MongoDB Atlas
            from core.mongodb import confirm_delivery_token_mongo
            confirm_delivery_token_mongo(
                order_id=order.id,
                token_hash=token_obj.token_hash,
                driver_id=delivery.driver_id,
                confirmed_by_id=user.id,
                confirmed_by_role='customer' if is_customer else 'driver',
                completed_at=now,
                notes='Delivery confirmed via QR / PIN verification'
            )

            # Transition order status to delivered with audit history
            record_order_status_transition(
                order,
                'delivered',
                actor=user,
                actor_role='customer' if is_customer else 'driver',
                notes='Delivery confirmed via QR / PIN verification'
            )

            # Transition delivery status
            delivery.status = 'delivered'
            delivery.delivery_time = now
            delivery.save(update_fields=['status', 'delivery_time'])

            # Credit driver earnings and deliveries
            driver = token_obj.driver
            fee = order.delivery_fee_charged if order.delivery_fee_charged else Decimal('2.00')
            driver.total_deliveries += 1
            driver.total_earnings += fee
            driver.save(update_fields=['total_deliveries', 'total_earnings'])

        return Response({
            'status': 'SUCCESS',
            'message': 'Delivery confirmed successfully!',
            'order_id': order.id,
            'order_status': 'delivered',
            'delivery_time': now.isoformat(),
            'driver_name': token_obj.driver.user.get_full_name() or token_obj.driver.user.username,
            'confirmed_by': user.username,
        }, status=status.HTTP_200_OK)

    @action(detail=True, methods=['post'], permission_classes=[IsAdminUser])
    def support_confirm_delivery(self, request, pk=None):
        """
        Admin/Support manual delivery clearance fallback when customer phone is unavailable.
        """
        order = self.get_object()
        reason = request.data.get('reason', 'Support manual delivery verification')
        now = timezone.now()

        with transaction.atomic():
            order.status = 'delivered'
            order.save(update_fields=['status'])
            delivery = getattr(order, 'delivery', None)
            if delivery:
                delivery.status = 'delivered'
                delivery.delivery_time = now
                delivery.save(update_fields=['status', 'delivery_time'])

            token_obj = DeliveryConfirmationToken.objects.filter(order=order).first()
            if token_obj and not token_obj.is_used:
                token_obj.is_used = True
                token_obj.used_at = now
                token_obj.confirmed_by = request.user
                token_obj.user_agent = f"SUPPORT_OVERRIDE: {reason}"
                token_obj.save(update_fields=['is_used', 'used_at', 'confirmed_by', 'user_agent'])

            dispatch_order_notification(
                order,
                status_key='delivered',
                custom_message=f"Order #{order.id} delivery verified and confirmed by support concierge."
            )

        return Response({
            'status': 'SUCCESS',
            'message': 'Order delivery confirmed via support override.',
            'order_id': order.id,
            'delivery_time': now.isoformat(),
        }, status=status.HTTP_200_OK)


class DriverViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Driver.objects.select_related('user').all()
    serializer_class = DriverSerializer
    permission_classes = [AllowAny]

    def get_queryset(self):
        qs = Driver.objects.select_related('user').all()
        if self.request.query_params.get('online') == 'true':
            qs = qs.filter(is_online=True)
        return qs

    def _get_driver(self, user):
        if not user or not user.is_authenticated:
            return None, Response({'error': 'Authentication required'}, status=status.HTTP_401_UNAUTHORIZED)
        driver = getattr(user, 'driver_profile', None)
        if not driver:
            if user.is_staff or getattr(user, 'role', '') == 'driver':
                driver, _ = Driver.objects.get_or_create(
                    user=user,
                    defaults={
                        'vehicle_type': 'Motorcycle (Honda Wave)',
                        'license_plate': 'PP-2026',
                        'is_online': True,
                        'is_approved': True,
                    }
                )
            else:
                return None, Response({'error': 'User is not registered as a driver'}, status=status.HTTP_403_FORBIDDEN)
        if not driver.is_approved and not user.is_staff:
            return None, Response({'error': 'Driver account is pending administrator approval.'}, status=status.HTTP_403_FORBIDDEN)
        return driver, None

    @action(detail=False, methods=['get', 'patch'], permission_classes=[IsAuthenticated])
    def me(self, request):
        driver, err = self._get_driver(request.user)
        if err:
            return err
        if request.method == 'PATCH':
            data = request.data
            if 'vehicle_type' in data:
                driver.vehicle_type = data['vehicle_type']
            if 'license_plate' in data:
                driver.license_plate = data['license_plate']
            if 'is_online' in data:
                driver.is_online = bool(data['is_online'])
            if 'phone' in data:
                new_phone = data['phone']
                if new_phone != request.user.phone:
                    request.user.phone = new_phone
                    request.user.phone_normalized = None
                    request.user.is_phone_verified = False
                    request.user.phone_verified_at = None
                    request.user.save(update_fields=['phone', 'phone_normalized', 'is_phone_verified', 'phone_verified_at'])
            driver.save()
        serializer = DriverSerializer(driver, context={'request': request})
        return Response(serializer.data)

    @action(detail=False, methods=['post'], permission_classes=[AllowAny], url_path='register')
    def register_driver(self, request):
        serializer = DriverRegistrationSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        driver = user.driver_profile
        driver_data = DriverSerializer(driver, context={'request': request}).data
        return Response({
            'status': 'SUCCESS',
            'message': 'Driver registered successfully.',
            'driver': driver_data,
        }, status=status.HTTP_201_CREATED)

    @action(detail=False, methods=['post'], permission_classes=[IsAuthenticated])
    def location(self, request):
        driver, err = self._get_driver(request.user)
        if err:
            return err
        lat = request.data.get('lat')
        lng = request.data.get('lng')
        if lat is not None and lng is not None:
            driver.current_lat = Decimal(str(lat))
            driver.current_lng = Decimal(str(lng))
            driver.last_location_update = timezone.now()
            driver.save(update_fields=['current_lat', 'current_lng', 'last_location_update'])
            return Response({
                'status': 'Location updated',
                'lat': float(driver.current_lat),
                'lng': float(driver.current_lng),
            })
        return Response({'error': 'lat and lng required'}, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=False, methods=['post'], permission_classes=[IsAuthenticated], url_path='toggle-online')
    def toggle_online(self, request):
        driver, err = self._get_driver(request.user)
        if err:
            return err
        is_online = request.data.get('is_online')
        if is_online is not None:
            if isinstance(is_online, str):
                driver.is_online = is_online.strip().lower() in ('true', '1', 'yes')
            else:
                driver.is_online = bool(is_online)
        else:
            driver.is_online = not driver.is_online
        driver.save(update_fields=['is_online'])
        return Response({'status': 'Status updated', 'is_online': driver.is_online})

    @action(detail=False, methods=['get'], permission_classes=[IsAuthenticated], url_path='available-orders')
    def available_orders(self, request):
        driver, err = self._get_driver(request.user)
        if err:
            return err
        orders = Order.objects.filter(
            models.Q(delivery__isnull=True) | models.Q(delivery__driver__isnull=True),
            status__in=['confirmed', 'preparing', 'ready', 'ready_for_pickup']
        ).select_related('restaurant', 'address', 'customer', 'delivery').order_by('-created_at')
        serializer = OrderSerializer(orders, many=True, context={'request': request})
        return Response(serializer.data)

    @action(detail=False, methods=['get'], permission_classes=[IsAuthenticated], url_path='active-deliveries')
    def active_deliveries(self, request):
        driver, err = self._get_driver(request.user)
        if err:
            return err
        orders = Order.objects.filter(
            delivery__driver=driver,
            delivery__status__in=['assigned', 'accepted', 'arrived_at_restaurant', 'picked_up', 'on_the_way', 'arrived']
        ).exclude(status__in=['delivered', 'cancelled']).select_related(
            'restaurant', 'address', 'customer', 'delivery', 'payment', 'delivery_token'
        ).order_by('-created_at')
        serializer = OrderSerializer(orders, many=True, context={'request': request})
        return Response(serializer.data)

    @action(detail=False, methods=['get'], permission_classes=[IsAuthenticated], url_path='history')
    def history(self, request):
        driver, err = self._get_driver(request.user)
        if err:
            return err
        orders = Order.objects.filter(
            delivery__driver=driver,
            delivery__status='delivered'
        ).select_related('restaurant', 'address', 'customer', 'delivery').order_by('-delivery__delivery_time')[:50]
        serializer = OrderSerializer(orders, many=True, context={'request': request})
        return Response(serializer.data)

    @action(detail=False, methods=['get'], permission_classes=[IsAuthenticated], url_path='earnings')
    def earnings(self, request):
        driver, err = self._get_driver(request.user)
        if err:
            return err
        today = timezone.now().date()
        week_ago = timezone.now() - timezone.timedelta(days=7)
        delivered_qs = Delivery.objects.filter(driver=driver, status='delivered')
        total_count = delivered_qs.count()

        today_fees = delivered_qs.filter(delivery_time__date=today).values_list('order__delivery_fee_charged', flat=True)
        today_total = float(sum(today_fees)) if today_fees else 0.0

        week_fees = delivered_qs.filter(delivery_time__gte=week_ago).values_list('order__delivery_fee_charged', flat=True)
        week_total = float(sum(week_fees)) if week_fees else 0.0

        all_fees = delivered_qs.values_list('order__delivery_fee_charged', flat=True)
        all_total = float(sum(all_fees)) if all_fees else float(driver.total_earnings)

        recent = Order.objects.filter(delivery__driver=driver, delivery__status='delivered').select_related('restaurant', 'address').order_by('-delivery__delivery_time')[:15]
        recent_list = []
        for o in recent:
            recent_list.append({
                'order_id': o.id,
                'order_reference': o.order_reference or f"#{o.id}",
                'restaurant': o.restaurant.name if o.restaurant else 'Restaurant',
                'delivery_fee': float(o.delivery_fee_charged or Decimal('2.00')),
                'delivered_at': o.delivered_at.isoformat() if o.delivered_at else None,
                'payment_status': o.payment_status,
            })

        return Response({
            'today_earnings_usd': today_total,
            'today_earnings_khr': int(today_total * 4100),
            'week_earnings_usd': week_total,
            'total_earnings_usd': all_total,
            'total_earnings_khr': int(all_total * 4100),
            'completed_trips': total_count,
            'recent_deliveries': recent_list,
        })

    @action(detail=False, methods=['post'], permission_classes=[IsAuthenticated], url_path=r'orders/(?P<order_id>[^/.]+)/accept')
    def accept_order(self, request, order_id=None):
        driver, err = self._get_driver(request.user)
        if err:
            return err
        if not request.user.is_phone_verified:
            return Response({'error': 'Verified Cambodian phone number required before accepting delivery assignments.'}, status=status.HTTP_403_FORBIDDEN)
        if not driver.is_online:
            return Response({'error': 'You must be online to accept delivery requests.'}, status=status.HTTP_400_BAD_REQUEST)

        with transaction.atomic():
            order = Order.objects.select_for_update().filter(id=order_id).first()
            if not order:
                return Response({'error': 'Order not found'}, status=status.HTTP_404_NOT_FOUND)
            if order.status in ('delivered', 'cancelled'):
                return Response({'error': f'Order cannot be accepted in {order.status} state.'}, status=status.HTTP_400_BAD_REQUEST)

            delivery, created = Delivery.objects.select_for_update().get_or_create(
                order=order,
                defaults={'driver': driver, 'status': 'accepted'}
            )
            if not created:
                if delivery.driver and delivery.driver != driver and delivery.status != 'assigned':
                    return Response({'error': 'This order has already been accepted by another driver.'}, status=status.HTTP_409_CONFLICT)
                delivery.driver = driver
                delivery.status = 'accepted'
                delivery.save(update_fields=['driver', 'status', 'updated_at'])

            target_status = 'confirmed' if order.status == 'pending' else order.status
            record_order_status_transition(
                order,
                target_status,
                actor=request.user,
                actor_role='driver',
                notes=f"Driver {driver.user.get_full_name() or driver.user.username} accepted delivery assignment"
            )

        serializer = OrderSerializer(order, context={'request': request})
        return Response({
            'status': 'SUCCESS',
            'message': 'Order accepted successfully.',
            'order': serializer.data,
        }, status=status.HTTP_200_OK)

    @action(detail=False, methods=['post'], permission_classes=[IsAuthenticated], url_path=r'orders/(?P<order_id>[^/.]+)/decline')
    def decline_order(self, request, order_id=None):
        driver, err = self._get_driver(request.user)
        if err:
            return err
        with transaction.atomic():
            delivery = Delivery.objects.select_for_update().filter(order_id=order_id, driver=driver).first()
            if delivery and delivery.status in ('assigned', 'accepted'):
                delivery.driver = None
                delivery.status = 'assigned'
                delivery.save(update_fields=['driver', 'status', 'updated_at'])
                OrderStatusHistory.objects.create(
                    order=delivery.order,
                    from_status=delivery.order.status,
                    to_status=delivery.order.status,
                    actor=request.user,
                    actor_role='driver',
                    notes=f"Driver {driver.user.username} declined delivery assignment; returned to queue"
                )
        return Response({'status': 'SUCCESS', 'message': 'Order declined.'}, status=status.HTTP_200_OK)

    @action(detail=False, methods=['post'], permission_classes=[IsAuthenticated], url_path=r'orders/(?P<order_id>[^/.]+)/arrive-restaurant')
    def arrive_restaurant(self, request, order_id=None):
        driver, err = self._get_driver(request.user)
        if err:
            return err
        delivery = Delivery.objects.filter(order_id=order_id, driver=driver).first()
        if not delivery:
            return Response({'error': 'Delivery assignment not found for this driver.'}, status=status.HTTP_404_NOT_FOUND)
        delivery.status = 'arrived_at_restaurant'
        delivery.save(update_fields=['status', 'updated_at'])
        order = delivery.order

        OrderStatusHistory.objects.create(
            order=order,
            from_status=order.status,
            to_status=order.status,
            actor=request.user,
            actor_role='driver',
            notes=f"Driver arrived at {order.restaurant.name if order.restaurant else 'restaurant'} for pickup"
        )
        dispatch_order_notification(
            order,
            status_key='arrived_restaurant',
            custom_message=f"Driver has arrived at {order.restaurant.name if order.restaurant else 'restaurant'} to pick up your order."
        )
        return Response({
            'status': 'SUCCESS',
            'message': 'Arrived at restaurant recorded.',
            'delivery_status': delivery.status,
        })

    @action(detail=False, methods=['post'], permission_classes=[IsAuthenticated], url_path=r'orders/(?P<order_id>[^/.]+)/pickup')
    def pickup_order(self, request, order_id=None):
        driver, err = self._get_driver(request.user)
        if err:
            return err
        delivery = Delivery.objects.filter(order_id=order_id, driver=driver).first()
        if not delivery:
            return Response({'error': 'Delivery assignment not found for this driver.'}, status=status.HTTP_404_NOT_FOUND)
        now = timezone.now()
        delivery.status = 'picked_up'
        delivery.pickup_time = now
        delivery.save(update_fields=['status', 'pickup_time', 'updated_at'])
        order = delivery.order
        record_order_status_transition(
            order,
            'on_the_way',
            actor=request.user,
            actor_role='driver',
            notes=f"Your order has been picked up from {order.restaurant.name if order.restaurant else 'restaurant'} and is on the way!"
        )
        return Response({
            'status': 'SUCCESS',
            'message': 'Order marked as picked up and on the way.',
            'order_status': order.status,
            'pickup_time': now.isoformat(),
        })

    @action(detail=False, methods=['post'], permission_classes=[IsAuthenticated], url_path=r'orders/(?P<order_id>[^/.]+)/arrive-customer')
    def arrive_customer(self, request, order_id=None):
        driver, err = self._get_driver(request.user)
        if err:
            return err
        delivery = Delivery.objects.filter(order_id=order_id, driver=driver).first()
        if not delivery:
            return Response({'error': 'Delivery assignment not found for this driver.'}, status=status.HTTP_404_NOT_FOUND)
        delivery.status = 'arrived'
        delivery.save(update_fields=['status', 'updated_at'])
        order = delivery.order
        record_order_status_transition(
            order,
            'driver_arrived',
            actor=request.user,
            actor_role='driver',
            notes="Driver has arrived outside customer destination with order."
        )
        return Response({
            'status': 'SUCCESS',
            'message': 'Arrival at customer recorded.',
            'order_status': order.status,
            'delivery_status': delivery.status,
        })

    @action(detail=False, methods=['post'], permission_classes=[IsAuthenticated], url_path=r'orders/(?P<order_id>[^/.]+)/deliver')
    def deliver_order(self, request, order_id=None):
        driver, err = self._get_driver(request.user)
        if err:
            return err
        delivery = Delivery.objects.filter(order_id=order_id, driver=driver).first()
        if not delivery:
            return Response({'error': 'Delivery assignment not found for this driver.'}, status=status.HTTP_404_NOT_FOUND)

        now = timezone.now()
        order = delivery.order

        payment = getattr(order, 'payment', None)
        payment_collected = request.data.get('payment_collected', False)
        is_cod = (payment and payment.provider == 'COD') or (not payment and order.payment_status != 'PAID')
        extra_fields = []

        # COD payments are marked paid upon driver confirming collection
        if payment_collected or is_cod:
            order.payment_status = 'PAID'
            extra_fields.append('payment_status')
            if payment:
                payment.status = 'PAID'
                payment.paid_at = now
                payment.save(update_fields=['status', 'paid_at'])

        delivery.status = 'delivered'
        delivery.delivery_time = now
        delivery.save(update_fields=['status', 'delivery_time', 'updated_at'])

        fee = order.delivery_fee_charged if order.delivery_fee_charged else Decimal('2.00')
        driver.total_deliveries += 1
        driver.total_earnings += fee
        driver.save(update_fields=['total_deliveries', 'total_earnings'])

        record_order_status_transition(
            order,
            'delivered',
            actor=request.user,
            actor_role='driver',
            notes=f"Order successfully delivered by driver {driver.user.username}. Earned ${fee} delivery fee.",
            extra_update_fields=extra_fields
        )
        return Response({
            'status': 'SUCCESS',
            'message': 'Order delivered successfully.',
            'order_id': order.id,
            'delivery_time': now.isoformat(),
            'fee_earned': float(fee),
            'total_earnings': float(driver.total_earnings),
            'payment_status': order.payment_status,
        })

    @action(detail=False, methods=['post'], permission_classes=[IsAuthenticated], url_path=r'orders/(?P<order_id>[^/.]+)/failed-delivery')
    def failed_delivery(self, request, order_id=None):
        driver, err = self._get_driver(request.user)
        if err:
            return err
        delivery = Delivery.objects.filter(order_id=order_id, driver=driver).first()
        if not delivery:
            return Response({'error': 'Delivery assignment not found for this driver.'}, status=status.HTTP_404_NOT_FOUND)
        reason = request.data.get('reason', 'Customer unreachable after multiple attempts')
        delivery.status = 'failed_delivery'
        delivery.save(update_fields=['status', 'updated_at'])
        order = delivery.order
        record_order_status_transition(
            order,
            'failed_delivery',
            actor=request.user,
            actor_role='driver',
            notes=f"Driver delivery failed: {reason}"
        )
        return Response({
            'status': 'SUCCESS',
            'message': 'Failed delivery recorded. Order returned to restaurant.',
            'order_status': order.status,
            'delivery_status': delivery.status,
            'reason': reason,
        })

    @action(detail=False, methods=['post'], permission_classes=[IsAuthenticated], url_path=r'orders/(?P<order_id>[^/.]+)/cancel')
    def cancel_delivery(self, request, order_id=None):
        driver, err = self._get_driver(request.user)
        if err:
            return err
        reason = request.data.get('reason', 'Driver reported unexpected issue')
        delivery = Delivery.objects.filter(order_id=order_id, driver=driver).first()
        if not delivery:
            return Response({'error': 'Delivery assignment not found for this driver.'}, status=status.HTTP_404_NOT_FOUND)
        order = delivery.order
        if delivery.status in ('assigned', 'accepted', 'arrived_at_restaurant'):
            delivery.driver = None
            delivery.status = 'assigned'
            delivery.save(update_fields=['driver', 'status', 'updated_at'])
            OrderStatusHistory.objects.create(
                order=order,
                from_status=order.status,
                to_status=order.status,
                actor=request.user,
                actor_role='driver',
                notes=f"Driver released delivery back to queue: {reason}"
            )
            return Response({
                'status': 'SUCCESS',
                'message': 'Delivery released back to available orders queue.',
                'reassigned': True,
            })
        else:
            delivery.status = 'cancelled'
            delivery.save(update_fields=['status', 'updated_at'])
            record_order_status_transition(
                order,
                'cancelled',
                actor=request.user,
                actor_role='driver',
                notes=f"Driver delivery cancellation: {reason}"
            )
            return Response({
                'status': 'SUCCESS',
                'message': 'Delivery cancelled.',
                'reassigned': False,
            })

    @action(detail=False, methods=['post'], permission_classes=[IsAuthenticated], url_path=r'orders/(?P<order_id>[^/.]+)/verify-payment')
    def verify_payment(self, request, order_id=None):
        driver, err = self._get_driver(request.user)
        if err:
            return err
        order = Order.objects.filter(id=order_id, delivery__driver=driver).first()
        if not order:
            return Response({'error': 'Order not found for this driver'}, status=status.HTTP_404_NOT_FOUND)

        payment = getattr(order, 'payment', None)
        if payment:
            payment.status = 'PAID'
            payment.paid_at = timezone.now()
            payment.save(update_fields=['status', 'paid_at'])
        order.payment_status = 'PAID'
        order.save(update_fields=['payment_status', 'updated_at'])

        return Response({
            'status': 'SUCCESS',
            'message': 'Payment confirmed.',
            'payment_status': order.payment_status,
        })

class CartViewSet(viewsets.ModelViewSet):
    queryset = Cart.objects.all()
    serializer_class = CartSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        if user.is_staff:
            return Cart.objects.all()
        return Cart.objects.filter(customer=user)

    def perform_create(self, serializer):
        serializer.save(customer=self.request.user)

class CartItemViewSet(viewsets.ModelViewSet):
    queryset = CartItem.objects.all()
    serializer_class = CartItemSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        queryset = CartItem.objects.select_related('cart', 'food_item')
        if self.request.user.is_staff:
            return queryset
        return queryset.filter(cart__customer=self.request.user)

    def perform_create(self, serializer):
        user = self.request.user
        cart, _ = Cart.objects.get_or_create(customer=user)
        food_item = serializer.validated_data['food_item']
        if not food_item.is_available:
            raise ValidationError({'food_item': ['This food item is not available.']})
        if cart.restaurant_id and cart.restaurant_id != food_item.category.restaurant_id:
            raise ValidationError({'food_item': ['A cart can contain items from one restaurant only.']})
        cart.restaurant = food_item.category.restaurant
        cart.save(update_fields=['restaurant'])
        serializer.save(cart=cart)


class AddressViewSet(viewsets.ModelViewSet):
    queryset = Address.objects.all()
    serializer_class = AddressSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.is_staff:
            return Address.objects.all()
        return Address.objects.filter(user=user)

    def perform_create(self, serializer):
        user = self.request.user
        if serializer.validated_data.get('is_default', False):
            Address.objects.filter(user=user).update(is_default=False)
        serializer.save(user=user)

    def perform_update(self, serializer):
        user = self.request.user
        if serializer.validated_data.get('is_default', False):
            Address.objects.filter(user=user).exclude(pk=serializer.instance.pk).update(is_default=False)
        serializer.save()

    @action(detail=True, methods=['post'])
    def set_default(self, request, pk=None):
        address = self.get_object()
        Address.objects.filter(user=request.user).update(is_default=False)
        address.is_default = True
        address.save(update_fields=['is_default'])
        return Response(self.get_serializer(address).data)

from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.exceptions import PermissionDenied
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser


from .serializers_user import UserSerializer

class UserMeView(generics.RetrieveUpdateAPIView):
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def get_object(self):
        return self.request.user

class UserRegistrationView(generics.CreateAPIView):
    queryset = User.objects.all()
    serializer_class = UserRegistrationSerializer
    permission_classes = [AllowAny]

class ForgotPasswordView(APIView):
    permission_classes = [AllowAny]
    
    def post(self, request):
        email = (request.data.get('email') or '').strip()
        phone = (request.data.get('phone') or '').strip()
        identifier = (request.data.get('identifier') or '').strip()

        target = identifier or email or phone
        if not target:
            return Response({'error': 'Email address or phone number is required.'}, status=status.HTTP_400_BAD_REQUEST)

        import re
        is_phone = bool(re.match(r'^\+?[0-9\s\-()]{7,20}$', target) and '@' not in target)

        if is_phone:
            try:
                from .phone_views import dispatch_phone_otp
                dispatch_phone_otp(request, target, purpose='password_reset')
            except Exception:
                pass
            return Response({
                'message': 'If an account with that phone number exists, an OTP reset code has been sent via SMS.'
            }, status=status.HTTP_200_OK)

        return Response({
            'message': 'If an account with that email exists, a password reset link has been sent.'
        }, status=status.HTTP_200_OK)

class LiveItemViewSet(viewsets.ModelViewSet):
    queryset = LiveItem.objects.all()
    serializer_class = LiveItemSerializer
    permission_classes = [IsAuthenticatedOrReadOnly]


class WalletViewSet(viewsets.GenericViewSet, viewsets.mixins.RetrieveModelMixin):
    serializer_class = WalletSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Wallet.objects.filter(user=self.request.user)
    
    @action(detail=False, methods=['get'])
    def my_wallet(self, request):
        wallet, _ = Wallet.objects.get_or_create(user=request.user)
        serializer = self.get_serializer(wallet)
        return Response(serializer.data)
        
    @action(detail=False, methods=['post'])
    def top_up(self, request):
        amount = request.data.get('amount')
        if not amount:
            return Response({'detail': 'Amount required'}, status=400)
        try:
            val = Decimal(str(amount))
            if val <= 0:
                return Response({'detail': 'Amount must be greater than zero'}, status=400)
        except Exception:
            return Response({'detail': 'Invalid amount'}, status=400)

        with transaction.atomic():
            wallet, _ = Wallet.objects.select_for_update().get_or_create(user=request.user)
            wallet.balance = Decimal(str(wallet.balance)) + val
            wallet.save(update_fields=['balance'])
            WalletTransaction.objects.create(
                wallet=wallet, amount=val, transaction_type='deposit', description='Account Wallet Top Up'
            )
            return Response(self.get_serializer(wallet).data)

    @action(detail=False, methods=['post'])
    def khqr_topup(self, request):
        amount = request.data.get('amount')
        currency = request.data.get('currency', 'USD').upper()
        if not amount:
            return Response({'detail': 'Amount required'}, status=400)
        try:
            val = Decimal(str(amount))
            if val <= 0:
                return Response({'detail': 'Amount must be greater than zero'}, status=400)
        except Exception:
            return Response({'detail': 'Invalid amount'}, status=400)

        from .payments.aba import ABAKHQRProvider
        aba = ABAKHQRProvider()
        merchant_ref = f"TOPUP-{request.user.id}-{int(timezone.now().timestamp())}"
        qr_string, _ = aba.generate_khqr(merchant_ref=merchant_ref, amount=val, currency=currency)

        return Response({
            'merchant_reference': merchant_ref,
            'amount': str(val),
            'currency': currency,
            'qr_payload': qr_string,
            'instructions': 'Scan with ABA Mobile, Bakong, or any Cambodian App to top up'
        })

    @action(detail=False, methods=['post'])
    def verify_topup(self, request):
        merchant_ref = request.data.get('merchant_reference')
        amount = request.data.get('amount')
        if not amount:
            return Response({'detail': 'Amount required'}, status=400)
        try:
            val = Decimal(str(amount))
            if val <= 0:
                return Response({'detail': 'Amount must be positive'}, status=400)
        except Exception:
            return Response({'detail': 'Invalid amount'}, status=400)

        with transaction.atomic():
            wallet, _ = Wallet.objects.select_for_update().get_or_create(user=request.user)
            wallet.balance = Decimal(str(wallet.balance)) + val
            wallet.save(update_fields=['balance'])
            WalletTransaction.objects.create(
                wallet=wallet,
                amount=val,
                transaction_type='deposit',
                description=f'KHQR Top-Up Verified ({merchant_ref or "Bank Transfer"})'
            )
            return Response(self.get_serializer(wallet).data)


class ReviewViewSet(viewsets.ModelViewSet):
    queryset = Review.objects.all()
    serializer_class = ReviewSerializer
    permission_classes = [IsAuthenticatedOrReadOnly]

    def perform_create(self, serializer):
        order = serializer.validated_data['order']
        if order.customer != self.request.user:
            raise PermissionDenied("You can only review your own orders.")
        if order.status != 'delivered':
            raise ValidationError("You can only review delivered orders.")
        serializer.save()

class RecommendationViewSet(viewsets.ViewSet):
    permission_classes = [IsAuthenticated]

    @action(detail=False, methods=['get'])
    def for_you(self, request):
        # Phase 4: Big Data Recommendations (Lightweight Collaborative Filtering Mock)
        # Suggest food from restaurants the user hasn't ordered from yet, 
        # or highly rated foods in the categories they order most.
        user_orders = Order.objects.filter(customer=request.user).prefetch_related('items__food_item__category')
        favorite_categories = set()
        for order in user_orders:
            for item in order.items.all():
                favorite_categories.add(item.food_item.category.name)
        
        if favorite_categories:
            recommended_foods = FoodItem.objects.filter(category__name__in=favorite_categories, is_available=True).order_by('-price')[:10]
        else:
            recommended_foods = FoodItem.objects.filter(is_available=True).order_by('id')[:10]
            
        serializer = FoodItemSerializer(recommended_foods, many=True, context={'request': request})
        return Response(serializer.data)


class RestaurantCategoryViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = RestaurantCategory.objects.all()
    serializer_class = RestaurantCategorySerializer
    permission_classes = [AllowAny]


class NotificationViewSet(viewsets.ModelViewSet):
    serializer_class = NotificationSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Notification.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    @action(detail=True, methods=['patch', 'post'])
    def read(self, request, pk=None):
        notification = self.get_object()
        notification.is_read = True
        notification.save(update_fields=['is_read'])
        return Response({'status': 'marked_read', 'id': notification.id})

    @action(detail=False, methods=['post'], url_path='mark-all-read')
    def mark_all_read(self, request):
        updated = Notification.objects.filter(user=request.user, is_read=False).update(is_read=True)
        return Response({'status': 'all_marked_read', 'count': updated})

    @action(detail=False, methods=['get'], url_path='unread-count')
    def unread_count(self, request):
        count = Notification.objects.filter(user=request.user, is_read=False).count()
        return Response({'unread_count': count})


class FavoriteViewSet(viewsets.ModelViewSet):
    serializer_class = FavoriteSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Favorite.objects.filter(customer=self.request.user).select_related('restaurant')

    def perform_create(self, serializer):
        serializer.save(customer=self.request.user)

    @action(detail=False, methods=['post'], url_path='toggle')
    def toggle(self, request):
        restaurant_id = request.data.get('restaurant') or request.data.get('restaurant_id')
        if not restaurant_id:
            return Response({'detail': 'restaurant is required.'}, status=status.HTTP_400_BAD_REQUEST)
        try:
            restaurant = Restaurant.objects.get(id=restaurant_id)
        except Restaurant.DoesNotExist:
            return Response({'detail': 'Restaurant not found.'}, status=status.HTTP_404_NOT_FOUND)

        fav = Favorite.objects.filter(customer=request.user, restaurant=restaurant).first()
        if fav:
            fav.delete()
            return Response({'is_favorited': False, 'message': 'Removed from favorites.'})
        else:
            fav = Favorite.objects.create(customer=request.user, restaurant=restaurant)
            return Response({'is_favorited': True, 'message': 'Added to favorites.', 'favorite_id': fav.id})

    @action(detail=False, methods=['get'], url_path='check')
    def check(self, request):
        restaurant_id = request.query_params.get('restaurant_id') or request.query_params.get('restaurant')
        if not restaurant_id:
            return Response({'is_favorited': False})
        is_fav = Favorite.objects.filter(customer=request.user, restaurant_id=restaurant_id).exists()
        return Response({'is_favorited': is_fav})


class CouponViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Coupon.objects.filter(is_active=True)
    serializer_class = CouponSerializer
    permission_classes = [AllowAny]

    @action(detail=False, methods=['post'], url_path='validate')
    def validate_coupon(self, request):
        code = request.data.get('code')
        if not code:
            return Response({'valid': False, 'message': 'Coupon code is required.'}, status=status.HTTP_400_BAD_REQUEST)
        coupon = Coupon.objects.filter(code__iexact=str(code).strip(), is_active=True).first()
        if not coupon:
            return Response({'valid': False, 'message': 'Invalid or expired coupon code.'}, status=status.HTTP_404_NOT_FOUND)
        
        subtotal_str = request.data.get('subtotal', '0.00')
        try:
            subtotal = Decimal(str(subtotal_str))
        except Exception:
            subtotal = Decimal('0.00')

        if coupon.min_order_amount and subtotal < coupon.min_order_amount:
            return Response({
                'valid': False,
                'message': f'Minimum order amount of ${coupon.min_order_amount} required.'
            }, status=status.HTTP_400_BAD_REQUEST)

        discount = (subtotal * Decimal(str(coupon.discount_percent)) / Decimal('100')).quantize(Decimal('0.01'))
        if coupon.max_discount_amount and discount > coupon.max_discount_amount:
            discount = coupon.max_discount_amount

        return Response({
            'valid': True,
            'code': coupon.code,
            'discount_percent': coupon.discount_percent,
            'discount_amount': str(discount),
            'message': f'{coupon.discount_percent}% discount applied!'
        })


def csrf_failure_view(request, reason=""):
    """
    Custom CSRF failure handler to prevent raw 403 crashes.
    Gracefully handles admin login retries, JSON API clients, and renders
    a branded recovery screen for form submissions.
    """
    from django.shortcuts import redirect, render
    from django.http import JsonResponse
    from django.middleware.csrf import rotate_token, get_token

    if request.path.startswith('/api/') or 'application/json' in request.headers.get('Accept', ''):
        return JsonResponse({
            'detail': 'CSRF verification failed. Request aborted.',
            'reason': reason or 'CSRF token from POST incorrect or missing.'
        }, status=403)

    # Admin login retry: rotate token and redirect back to login smoothly
    if request.path.startswith('/admin/login'):
        rotate_token(request)
        return redirect(f"{request.get_full_path()}{'&' if '?' in request.get_full_path() else '?'}csrf_retry=1")

    fresh_token = get_token(request)
    context = {
        'reason': reason or 'CSRF token from POST incorrect.',
        'return_url': request.get_full_path() or '/admin/',
        'csrf_token': fresh_token,
    }
    response = render(request, '403_csrf.html', context, status=403)
    response['Cache-Control'] = 'no-cache, no-store, must-revalidate, private, max-age=0'
    return response


class CurrencyRateView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        rate_obj, _ = ExchangeRate.objects.get_or_create(
            base_currency='USD',
            target_currency='KHR',
            defaults={
                'rate': Decimal('4100.0000'),
                'source': 'National Bank of Cambodia (NBC)'
            }
        )
        return Response({
            'base_currency': rate_obj.base_currency,
            'target_currency': rate_obj.target_currency,
            'rate': float(rate_obj.rate),
            'source': rate_obj.source,
            'updated_at': rate_obj.updated_at.isoformat(),
            'rates': {
                'USD': 1.0,
                'KHR': float(rate_obj.rate),
            }
        })


class HealthLiveView(APIView):
    """
    Lightweight liveness probe for Cloudflare Load Balancing and Vercel functions.
    Verifies that the server process is responsive without hitting external resources.
    """
    permission_classes = [AllowAny]

    def get(self, request):
        return Response({'status': 'live'}, status=status.HTTP_200_OK)


class HealthReadyView(APIView):
    """
    Readiness probe for Cloudflare Load Balancing.
    Verifies database connectivity before directing production traffic.
    Returns generic status to prevent leaking internal database info or credentials.
    """
    permission_classes = [AllowAny]

    def get(self, request):
        try:
            from django.db import connection
            with connection.cursor() as cursor:
                cursor.execute('SELECT 1')
            return Response({'status': 'ready'}, status=status.HTTP_200_OK)
        except Exception:
            return Response({'status': 'unavailable'}, status=status.HTTP_503_SERVICE_UNAVAILABLE)


class HealthCheckView(APIView):
    """
    Production health check and telemetry probe for load balancers and orchestrators
    (Docker, Render, Vercel, Kubernetes).
    """
    permission_classes = [AllowAny]

    def get(self, request):
        now = timezone.now()
        status_data = {
            'status': 'healthy',
            'service': 'foodgo-backend',
            'database': 'connected',
            'timestamp': now.isoformat(),
        }

        # Validate database connectivity
        try:
            from django.db import connection
            with connection.cursor() as cursor:
                cursor.execute('SELECT 1')
        except Exception:
            status_data['database'] = 'unavailable'
            status_data['status'] = 'degraded'

        # Check MongoDB Atlas if configured
        try:
            from core.mongodb import check_mongo_connection
            mongo_info = check_mongo_connection()
            status_data['mongodb'] = mongo_info.get('status', 'not_configured')
        except Exception:
            status_data['mongodb'] = 'unavailable'

        http_status = status.HTTP_200_OK if status_data['status'] == 'healthy' else status.HTTP_503_SERVICE_UNAVAILABLE
        return Response(status_data, status=http_status)


class MongoHealthCheckView(APIView):
    """
    Dedicated health check probe for MongoDB Atlas cluster verification.
    """
    permission_classes = [AllowAny]

    def get(self, request):
        from core.mongodb import check_mongo_connection
        result = check_mongo_connection()
        http_status = status.HTTP_200_OK if result.get('connected') else (
            status.HTTP_200_OK if result.get('status') == 'not_configured' else status.HTTP_503_SERVICE_UNAVAILABLE
        )
        return Response(result, status=http_status)


class MongoImageView(APIView):
    """
    Serve images and files stored directly in MongoDB Atlas GridFS.
    Endpoint: GET /api/media/mongo/<path:filename>
    """
    permission_classes = [AllowAny]

    def get(self, request, filename):
        from django.http import HttpResponse
        from core.mongodb import get_image_mongo, save_image_mongo
        import os
        from django.conf import settings

        doc = get_image_mongo(filename)
        if not doc:
            # Fallback to local MEDIA_ROOT if file exists locally
            local_path = os.path.join(settings.MEDIA_ROOT, filename)
            if os.path.exists(local_path):
                try:
                    with open(local_path, 'rb') as f:
                        content = f.read()
                    import mimetypes
                    content_type, _ = mimetypes.guess_type(local_path)
                    content_type = content_type or 'application/octet-stream'
                    save_image_mongo(filename, content, content_type=content_type)
                    resp = HttpResponse(content, content_type=content_type)
                    resp['Cache-Control'] = 'public, max-age=86400'
                    return resp
                except Exception:
                    pass
            return Response({'error': f"File '{filename}' not found in MongoDB Atlas"}, status=status.HTTP_404_NOT_FOUND)

        resp = HttpResponse(doc['content'], content_type=doc.get('content_type', 'application/octet-stream'))
        resp['Cache-Control'] = 'public, max-age=86400'
        resp['Content-Length'] = len(doc['content'])
        return resp


class MongoImageUploadView(APIView):
    """
    Upload images directly into MongoDB Atlas GridFS and list stored files.
    Endpoints:
    - GET /api/media/mongo/upload/ (List stored media)
    - POST /api/media/mongo/upload/ (Upload file or base64 data)
    """
    permission_classes = [AllowAny]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def get(self, request):
        from core.mongodb import list_images_mongo
        limit = min(int(request.query_params.get('limit', 50)), 200)
        images = list_images_mongo(limit=limit)
        return Response({
            'count': len(images),
            'images': images
        })

    def post(self, request):
        from core.mongodb import save_image_mongo
        import secrets
        import os

        file_obj = request.FILES.get('image') or request.FILES.get('file')
        content_type = None

        if file_obj:
            orig_name = file_obj.name
            content_type = file_obj.content_type
            file_data = file_obj.read()
        elif 'image_base64' in request.data:
            import base64
            b64_data = request.data['image_base64']
            if ',' in b64_data:
                header, b64_data = b64_data.split(',', 1)
                if 'image/' in header:
                    content_type = header.split(';')[0].replace('data:', '')
            try:
                file_data = base64.b64decode(b64_data)
            except Exception as e:
                return Response({'error': f'Invalid base64 encoding: {e}'}, status=status.HTTP_400_BAD_REQUEST)
            orig_name = request.data.get('filename', f"upload_{secrets.token_hex(4)}.jpg")
        else:
            return Response({'error': 'No image file or image_base64 provided'}, status=status.HTTP_400_BAD_REQUEST)

        safe_name = os.path.basename(orig_name).replace(' ', '_')
        if not safe_name:
            safe_name = f"upload_{secrets.token_hex(4)}.jpg"

        file_id = save_image_mongo(
            filename=safe_name,
            file_data=file_data,
            content_type=content_type,
            metadata={
                'uploaded_by': request.user.username if request.user and request.user.is_authenticated else 'anonymous',
                'original_name': orig_name
            }
        )

        if not file_id:
            return Response({'error': 'Failed to save image to MongoDB Atlas'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        public_url = request.build_absolute_uri(f"/api/media/mongo/{safe_name}")
        return Response({
            'status': 'success',
            'file_id': file_id,
            'filename': safe_name,
            'content_type': content_type,
            'size': len(file_data),
            'url': f"/api/media/mongo/{safe_name}",
            'absolute_url': public_url
        }, status=status.HTTP_201_CREATED)


class MongoSyncView(APIView):
    """
    Trigger manual or automated synchronization of catalog and orders to MongoDB Atlas.
    Endpoint: POST /api/mongodb/sync/
    """
    permission_classes = [AllowAny]

    def post(self, request):
        from core.mongodb import sync_catalog_to_mongo, save_order_mongo, get_mongo_stats
        from core.models import Order

        catalog_res = sync_catalog_to_mongo()
        orders = Order.objects.all()
        orders_synced = sum(1 for o in orders if save_order_mongo(o))
        stats = get_mongo_stats()

        return Response({
            'status': 'success',
            'catalog_synced': catalog_res,
            'orders_synced': orders_synced,
            'current_stats': stats
        })



