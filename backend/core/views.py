from rest_framework.decorators import action
from rest_framework.response import Response
from decimal import Decimal

from django.db import transaction
from rest_framework import viewsets
from rest_framework import status
from rest_framework.exceptions import PermissionDenied, ValidationError
from rest_framework.permissions import IsAuthenticated, AllowAny, IsAuthenticatedOrReadOnly, IsAdminUser
from .models import *
from .serializers import *

class RestaurantViewSet(viewsets.ModelViewSet):
    queryset = Restaurant.objects.all()
    serializer_class = RestaurantSerializer
    permission_classes = [IsAuthenticatedOrReadOnly]

    
    @action(detail=False, methods=['get'])
    def my_restaurant(self, request):
        if request.user.role != 'restaurant_owner':
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
            queryset = queryset.filter(models.Q(name__icontains=search) | models.Q(description__icontains=search) | models.Q(address__icontains=search))

        category_id = self.request.query_params.get('category')
        if category_id:
            queryset = queryset.filter(category_id=category_id)

        min_rating = self.request.query_params.get('min_rating')
        if min_rating:
            try:
                queryset = queryset.filter(rating__gte=float(min_rating))
            except ValueError:
                pass

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
                models.Q(ingredients__icontains=search)
            )

        category_id = self.request.query_params.get('category')
        if category_id:
            queryset = queryset.filter(category_id=category_id)

        restaurant_id = self.request.query_params.get('restaurant')
        if restaurant_id:
            queryset = queryset.filter(category__restaurant_id=restaurant_id)

        is_vegetarian = self.request.query_params.get('vegetarian')
        if is_vegetarian == 'true':
            queryset = queryset.filter(is_vegetarian=True)

        return queryset.order_by('name')

    def perform_create(self, serializer):
        category = serializer.validated_data['category']
        if not self.request.user.is_staff and category.restaurant.owner_id != self.request.user.id:
            raise PermissionDenied('You can only manage food for your own restaurant.')
        serializer.save()

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

        if self.action in ('confirm_delivery', 'delivery_qr', 'track'):
            pass
        elif user.is_staff or user.is_superuser:
            pass
        elif user.role == 'customer':
            qs = qs.filter(customer=user)
        elif user.role == 'restaurant_owner':
            qs = qs.filter(restaurant__owner=user)
        elif hasattr(user, 'driver_profile') or user.role == 'driver':
            qs = qs.filter(delivery__driver__user=user)
        else:
            qs = qs.filter(customer=user)

        status_param = self.request.query_params.get('status')
        if status_param:
            if status_param == 'active':
                qs = qs.filter(status__in=[
                    'pending', 'confirmed', 'preparing', 'ready',
                    'ready_for_pickup', 'picked_up', 'on_the_way',
                    'driver_arrived', 'arrived'
                ])
            elif status_param == 'completed':
                qs = qs.filter(status='delivered')
            elif status_param == 'cancelled':
                qs = qs.filter(status='cancelled')
            else:
                qs = qs.filter(status=status_param)

        return qs

    ALLOWED_TRANSITIONS = {
        'pending': ['confirmed', 'cancelled'],
        'confirmed': ['preparing', 'cancelled'],
        'preparing': ['ready', 'ready_for_pickup', 'on_the_way', 'cancelled'],
        'ready': ['picked_up', 'on_the_way', 'cancelled'],
        'ready_for_pickup': ['picked_up', 'on_the_way', 'cancelled'],
        'picked_up': ['on_the_way', 'driver_arrived', 'arrived'],
        'on_the_way': ['driver_arrived', 'arrived', 'delivered'],
        'arrived': ['delivered'],
        'driver_arrived': ['delivered'],
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

            order.status = new_status_norm
            order.save(update_fields=['status'])
            delivery = getattr(order, 'delivery', None)
            if delivery and new_status_norm in ('on_the_way', 'arrived', 'driver_arrived', 'picked_up'):
                delivery.status = new_status_norm
                delivery.save(update_fields=['status'])

        return super().partial_update(request, *args, **kwargs)

    def perform_destroy(self, instance):
        user = self.request.user
        if not user.is_staff:
            if instance.customer != user:
                raise PermissionDenied("You can only cancel your own orders.")
            if instance.status not in ('pending', 'cancelled'):
                raise ValidationError({"detail": "Cannot cancel or delete an order that is already being prepared or delivered."})
        instance.status = 'cancelled'
        instance.cancelled_at = timezone.now()
        instance.cancellation_reason = 'Cancelled by user'
        instance.save(update_fields=['status', 'cancelled_at', 'cancellation_reason'])

    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated])
    def cancel(self, request, pk=None):
        order = self.get_object()
        user = request.user
        if not user.is_staff and order.customer != user:
            raise PermissionDenied("You can only cancel your own orders.")
        if order.status not in ('pending', 'confirmed'):
            return Response(
                {'detail': f'Cannot cancel order in "{order.status}" status.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        reason = request.data.get('reason', 'Cancelled by customer')
        order.status = 'cancelled'
        order.cancelled_at = timezone.now()
        order.cancellation_reason = reason
        order.save(update_fields=['status', 'cancelled_at', 'cancellation_reason'])
        return Response({
            'status': 'cancelled',
            'message': 'Order successfully cancelled.',
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
                    raise ValidationError({'items': [f'Food item {food_id} not found.']})

                if not food.is_available:
                    raise ValidationError({'items': [f'"{food.name}" is currently unavailable.']})

                if not restaurant:
                    restaurant = food.category.restaurant
                elif food.category.restaurant_id != restaurant.id:
                    raise ValidationError({'restaurant': ['All ordered items must belong to the selected restaurant.']})

                subtotal += food.price * qty
                order_items_to_create.append((food, qty, food.price))

            address = serializer.validated_data.get('address')
            if address and address.user_id != user.id and not user.is_staff:
                raise ValidationError({'address': ['The selected address does not belong to you.']})

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
                delivery_address_snapshot=addr_snapshot
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
            delivery_address_snapshot=addr_snapshot
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

    @action(detail=True, methods=['get'])
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

            # Transition order status to delivered
            order.status = 'delivered'
            # CRITICAL: Preserve order.payment_status as required by specification!
            order.save(update_fields=['status'])

            # Transition delivery status
            delivery.status = 'delivered'
            delivery.delivery_time = now
            delivery.save(update_fields=['status', 'delivery_time'])

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

    @action(detail=False, methods=['post'], permission_classes=[IsAuthenticated])
    def location(self, request):
        user = request.user
        driver = getattr(user, 'driver_profile', None)
        if not driver:
            if user.is_staff or user.role == 'driver':
                driver, _ = Driver.objects.get_or_create(
                    user=user,
                    defaults={'vehicle_type': 'Motorcycle (Honda Wave)', 'license_plate': 'PP-2026', 'is_online': True}
                )
            else:
                return Response({'error': 'User is not registered as a driver'}, status=403)

        lat = request.data.get('lat')
        lng = request.data.get('lng')
        if lat is not None and lng is not None:
            driver.current_lat = Decimal(str(lat))
            driver.current_lng = Decimal(str(lng))
            driver.save(update_fields=['current_lat', 'current_lng'])
            return Response({'status': 'Location updated', 'lat': float(driver.current_lat), 'lng': float(driver.current_lng)})
        return Response({'error': 'lat and lng required'}, status=400)

    @action(detail=False, methods=['post'], permission_classes=[IsAuthenticated], url_path='toggle-online')
    def toggle_online(self, request):
        user = request.user
        driver = getattr(user, 'driver_profile', None)
        if not driver:
            if user.is_staff or user.role == 'driver':
                driver, _ = Driver.objects.get_or_create(
                    user=user,
                    defaults={'vehicle_type': 'Motorcycle (Honda Wave)', 'license_plate': 'PP-2026', 'is_online': True}
                )
            else:
                return Response({'error': 'User is not registered as a driver'}, status=403)

        is_online = request.data.get('is_online')
        if is_online is not None:
            driver.is_online = bool(is_online)
        else:
            driver.is_online = not driver.is_online
        driver.save(update_fields=['is_online'])
        return Response({'status': 'Status updated', 'is_online': driver.is_online})

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


from .serializers_user import UserSerializer

class UserMeView(generics.RetrieveUpdateAPIView):
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]

    def get_object(self):
        return self.request.user

class UserRegistrationView(generics.CreateAPIView):
    queryset = User.objects.all()
    serializer_class = UserRegistrationSerializer
    permission_classes = [AllowAny]

class ForgotPasswordView(APIView):
    permission_classes = [AllowAny]
    
    def post(self, request):
        email = request.data.get('email')
        if not email:
            return Response({'error': 'Email is required'}, status=status.HTTP_400_BAD_REQUEST)
        # In a real app, you would generate a token and send an email here.
        return Response({'message': 'If an account with that email exists, a password reset link has been sent.'}, status=status.HTTP_200_OK)

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
        qr_string = aba.generate_khqr(merchant_ref=merchant_ref, amount=val, currency=currency)

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

