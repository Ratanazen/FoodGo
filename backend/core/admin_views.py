from decimal import Decimal
from datetime import timedelta
from django.db import models, connection, transaction
from django.db.models import Sum, Count, Q
from django.utils import timezone
from rest_framework import viewsets, status, generics
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.decorators import action

from .models import User, Order, Payment, Driver, Delivery, Restaurant, FoodItem, AuditLog, OrderStatusHistory
from .serializers import (
    OrderSerializer, AdminUserSerializer, RestaurantSerializer,
    AuditLogSerializer, PaymentSerializer, DriverSerializer
)
from .permissions import IsAdminOrStaff
from .notifications import dispatch_order_notification

def _get_client_ip(request):
    x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
    if x_forwarded_for:
        return x_forwarded_for.split(',')[0].strip()
    return request.META.get('REMOTE_ADDR')

class AdminAnalyticsView(APIView):
    permission_classes = [IsAdminOrStaff]

    def get(self, request):
        period = request.query_params.get('period', 'all').lower()
        now = timezone.now()

        orders_qs = Order.objects.all()
        payments_qs = Payment.objects.filter(status='PAID')

        if period == 'today':
            start_date = now.replace(hour=0, minute=0, second=0, microsecond=0)
            orders_qs = orders_qs.filter(created_at__gte=start_date)
            payments_qs = payments_qs.filter(created_at__gte=start_date)
        elif period == 'week':
            start_date = now - timedelta(days=7)
            orders_qs = orders_qs.filter(created_at__gte=start_date)
            payments_qs = payments_qs.filter(created_at__gte=start_date)
        elif period == 'month':
            start_date = now - timedelta(days=30)
            orders_qs = orders_qs.filter(created_at__gte=start_date)
            payments_qs = payments_qs.filter(created_at__gte=start_date)
        elif period == 'year':
            start_date = now - timedelta(days=365)
            orders_qs = orders_qs.filter(created_at__gte=start_date)
            payments_qs = payments_qs.filter(created_at__gte=start_date)

        total_orders = orders_qs.count()
        pending_orders = orders_qs.filter(status__in=['pending', 'confirmed', 'preparing']).count()
        active_orders = orders_qs.filter(status__in=['ready', 'ready_for_pickup', 'picked_up', 'on_the_way']).count()
        completed_orders = orders_qs.filter(status='delivered').count()
        cancelled_orders = orders_qs.filter(status='cancelled').count()

        rev_agg = payments_qs.aggregate(total=Sum('amount'))['total'] or Decimal('0.00')
        revenue_usd = f"{rev_agg:.2f}"
        revenue_khr = f"{int(rev_agg * Decimal('4100')):,} ៛"

        active_customers = User.objects.filter(role='customer', is_active=True).count()
        total_customers = User.objects.filter(role='customer').count()
        active_drivers = Driver.objects.filter(is_online=True).count()
        total_drivers = Driver.objects.count()
        total_restaurants = Restaurant.objects.count()
        active_restaurants = Restaurant.objects.filter(is_active=True).count()
        total_food_items = FoodItem.objects.count()

        status_counts = orders_qs.values('status').annotate(count=Count('id'))
        order_status_distribution = {item['status']: item['count'] for item in status_counts}

        # Recent activities (latest orders and audit events)
        recent_orders = orders_qs.order_by('-created_at')[:5]
        recent_orders_data = [
            {
                'id': o.id,
                'reference': o.order_reference or f"ORD-{o.id:04d}",
                'customer': o.customer.get_full_name() or o.customer.username,
                'restaurant': o.restaurant.name if o.restaurant else 'N/A',
                'amount': f"${o.total_amount:.2f}",
                'status': o.status,
                'created_at': o.created_at.isoformat(),
            }
            for o in recent_orders
        ]

        recent_audits = AuditLog.objects.all().select_related('admin_user')[:5]
        recent_audits_data = AuditLogSerializer(recent_audits, many=True).data

        # Database and system health check
        db_healthy = True
        try:
            connection.ensure_connection()
        except Exception:
            db_healthy = False

        system_health = {
            'database': 'healthy' if db_healthy else 'degraded',
            'api_service': 'operational',
            'daphne_asgi': 'running',
            'timestamp': now.isoformat(),
        }

        return Response({
            'period': period,
            'metrics': {
                'total_orders': total_orders,
                'pending_orders': pending_orders,
                'active_orders': active_orders,
                'completed_orders': completed_orders,
                'cancelled_orders': cancelled_orders,
                'total_revenue': float(rev_agg),
                'total_revenue_usd': revenue_usd,
                'total_revenue_khr': revenue_khr,
                'active_customers': active_customers,
                'total_customers': total_customers,
                'active_drivers': active_drivers,
                'total_drivers': total_drivers,
                'total_restaurants': total_restaurants,
                'active_restaurants': active_restaurants,
                'total_food_items': total_food_items,
            },
            'order_status_distribution': order_status_distribution,
            'recent_orders': recent_orders_data,
            'recent_audits': recent_audits_data,
            'system_health': system_health,
        })

class AdminOrderViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAdminOrStaff]
    serializer_class = OrderSerializer
    queryset = Order.objects.all().select_related(
        'restaurant', 'customer', 'address', 'delivery__driver__user', 'payment'
    ).prefetch_related('items__food_item').order_by('-created_at')

    def get_queryset(self):
        qs = super().get_queryset()
        status_param = self.request.query_params.get('status')
        if status_param and status_param != 'all':
            qs = qs.filter(status=status_param)
        search_query = self.request.query_params.get('search')
        if search_query:
            qs = qs.filter(
                Q(order_reference__icontains=search_query) |
                Q(customer__username__icontains=search_query) |
                Q(customer__first_name__icontains=search_query) |
                Q(customer__phone__icontains=search_query) |
                Q(restaurant__name__icontains=search_query)
            )
        return qs

    @action(detail=True, methods=['post'])
    def assign_driver(self, request, pk=None):
        order = self.get_object()
        driver_id = request.data.get('driver_id')
        if not driver_id:
            return Response({'error': 'driver_id is required'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            driver = Driver.objects.select_related('user').get(id=driver_id)
        except Driver.DoesNotExist:
            return Response({'error': 'Driver not found'}, status=status.HTTP_404_NOT_FOUND)

        delivery, _ = Delivery.objects.get_or_create(order=order)
        delivery.driver = driver
        delivery.status = 'assigned'
        delivery.save()

        if order.status in ('pending', 'confirmed'):
            order.status = 'preparing'
            order.save()

        AuditLog.objects.create(
            admin_user=request.user,
            action='ASSIGN_DRIVER',
            target_type='Order',
            target_id=str(order.id),
            details={
                'driver_id': driver.id,
                'driver_name': driver.user.get_full_name() or driver.user.username,
                'order_reference': order.order_reference,
            },
            ip_address=_get_client_ip(request)
        )

        driver_name = driver.user.get_full_name() or driver.user.username
        dispatch_order_notification(
            order,
            status_key='preparing',
            custom_title='Driver Assigned',
            custom_message=f"Courier {driver_name} has been assigned to your order #{order.id}."
        )

        return Response(OrderSerializer(order, context={'request': request}).data)

    @action(detail=True, methods=['post'])
    def cancel_order(self, request, pk=None):
        order = self.get_object()
        if order.status == 'delivered':
            return Response({'error': 'Cannot cancel an order that has already been delivered.'}, status=status.HTTP_400_BAD_REQUEST)

        reason = request.data.get('cancellation_reason', 'Cancelled by administrator')
        order.status = 'cancelled'
        order.cancellation_reason = reason
        order.cancelled_at = timezone.now()
        order.save()

        AuditLog.objects.create(
            admin_user=request.user,
            action='CANCEL_ORDER',
            target_type='Order',
            target_id=str(order.id),
            details={'reason': reason, 'order_reference': order.order_reference},
            ip_address=_get_client_ip(request)
        )

        dispatch_order_notification(
            order,
            status_key='cancelled',
            custom_title='Order Cancelled by Support',
            custom_message=f"Order #{order.id} was cancelled by administrator. Reason: {reason}"
        )

        return Response(OrderSerializer(order, context={'request': request}).data)

    @action(detail=True, methods=['post'])
    def reassign_driver(self, request, pk=None):
        order = self.get_object()
        driver_id = request.data.get('driver_id')
        reason = request.data.get('reason', 'Administrative reassignment')
        if not driver_id:
            return Response({'error': 'driver_id is required'}, status=status.HTTP_400_BAD_REQUEST)
        try:
            driver = Driver.objects.select_related('user').get(id=driver_id)
        except Driver.DoesNotExist:
            return Response({'error': 'Driver not found'}, status=status.HTTP_404_NOT_FOUND)

        delivery, _ = Delivery.objects.get_or_create(order=order)
        prev_driver_name = delivery.driver.user.username if delivery.driver else 'None'
        delivery.driver = driver
        delivery.status = 'assigned'
        delivery.save(update_fields=['driver', 'status', 'updated_at'])

        AuditLog.objects.create(
            admin_user=request.user,
            action='ASSIGN_DRIVER',
            target_type='Order',
            target_id=str(order.id),
            details={
                'driver_id': driver.id,
                'driver_name': driver.user.get_full_name() or driver.user.username,
                'previous_driver': prev_driver_name,
                'reason': reason,
                'order_reference': order.order_reference,
            },
            ip_address=_get_client_ip(request)
        )

        OrderStatusHistory.objects.create(
            order=order,
            from_status=order.status,
            to_status=order.status,
            actor=request.user,
            actor_role='admin',
            notes=f"Reassigned from {prev_driver_name} to {driver.user.username}: {reason}"
        )

        dispatch_order_notification(
            order,
            status_key='driver_assigned',
            custom_title='Delivery Reassigned',
            custom_message=f"Courier {driver.user.get_full_name() or driver.user.username} has been assigned to your order #{order.id}."
        )

        return Response(OrderSerializer(order, context={'request': request}).data)

    @action(detail=True, methods=['post'])
    def update_status(self, request, pk=None):
        order = self.get_object()
        new_status = request.data.get('status')
        reason = request.data.get('reason', 'Administrative status update')
        if not new_status:
            return Response({'error': 'status is required'}, status=status.HTTP_400_BAD_REQUEST)

        valid_choices = [c[0] for c in Order.STATUS_CHOICES]
        if new_status not in valid_choices:
            return Response({'error': f'Invalid status. Allowed choices: {valid_choices}'}, status=status.HTTP_400_BAD_REQUEST)

        from_status = order.status
        order.status = new_status
        now = timezone.now()
        update_fields = ['status']
        if new_status == 'delivered':
            order.delivered_at = now
            update_fields.append('delivered_at')
            if hasattr(order, 'delivery') and order.delivery:
                order.delivery.status = 'delivered'
                order.delivery.delivery_time = now
                order.delivery.save(update_fields=['status', 'delivery_time'])
        elif new_status == 'cancelled':
            order.cancelled_at = now
            order.cancellation_reason = reason
            update_fields.extend(['cancelled_at', 'cancellation_reason'])
            if hasattr(order, 'delivery') and order.delivery:
                order.delivery.status = 'cancelled'
                order.delivery.save(update_fields=['status'])

        order.save(update_fields=update_fields)

        OrderStatusHistory.objects.create(
            order=order,
            from_status=from_status,
            to_status=new_status,
            actor=request.user,
            actor_role='admin',
            notes=reason
        )

        AuditLog.objects.create(
            admin_user=request.user,
            action='SYSTEM_CONFIG',
            target_type='Order',
            target_id=str(order.id),
            details={'from_status': from_status, 'to_status': new_status, 'reason': reason},
            ip_address=_get_client_ip(request)
        )

        dispatch_order_notification(order, status_key=new_status, custom_message=reason)
        return Response(OrderSerializer(order, context={'request': request}).data)

class AdminUserViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAdminOrStaff]
    serializer_class = AdminUserSerializer
    queryset = User.objects.all().order_by('-date_joined')

    def get_queryset(self):
        qs = super().get_queryset()
        role_param = self.request.query_params.get('role')
        if role_param and role_param != 'all':
            qs = qs.filter(role=role_param)
        search_query = self.request.query_params.get('search')
        if search_query:
            qs = qs.filter(
                Q(username__icontains=search_query) |
                Q(email__icontains=search_query) |
                Q(phone__icontains=search_query) |
                Q(first_name__icontains=search_query) |
                Q(last_name__icontains=search_query)
            )
        return qs

    @action(detail=True, methods=['post'])
    def toggle_status(self, request, pk=None):
        user = self.get_object()
        if user == request.user:
            return Response({'error': 'You cannot deactivate your own administrative account.'}, status=status.HTTP_400_BAD_REQUEST)

        user.is_active = not user.is_active
        user.save()

        AuditLog.objects.create(
            admin_user=request.user,
            action='TOGGLE_USER_ACTIVE',
            target_type='User',
            target_id=str(user.id),
            details={'username': user.username, 'new_status': user.is_active},
            ip_address=_get_client_ip(request)
        )

        return Response(AdminUserSerializer(user, context={'request': request}).data)

class AdminRestaurantViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAdminOrStaff]
    serializer_class = RestaurantSerializer
    queryset = Restaurant.objects.all().order_by('-rating')

    def get_queryset(self):
        qs = super().get_queryset()
        search_query = self.request.query_params.get('search')
        if search_query:
            qs = qs.filter(name__icontains=search_query)
        return qs

    @action(detail=True, methods=['post'])
    def toggle_status(self, request, pk=None):
        restaurant = self.get_object()
        restaurant.is_active = not restaurant.is_active
        restaurant.save()

        AuditLog.objects.create(
            admin_user=request.user,
            action='TOGGLE_RESTAURANT',
            target_type='Restaurant',
            target_id=str(restaurant.id),
            details={'restaurant_name': restaurant.name, 'new_status': restaurant.is_active},
            ip_address=_get_client_ip(request)
        )

        return Response(RestaurantSerializer(restaurant, context={'request': request}).data)

class AdminAuditLogViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [IsAdminOrStaff]
    serializer_class = AuditLogSerializer
    queryset = AuditLog.objects.all().select_related('admin_user').order_by('-timestamp')

    def get_queryset(self):
        qs = super().get_queryset()
        action_param = self.request.query_params.get('action')
        if action_param:
            qs = qs.filter(action=action_param)
        target_param = self.request.query_params.get('target_type')
        if target_param:
            qs = qs.filter(target_type=target_param)
        return qs

class AdminPaymentViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [IsAdminOrStaff]
    serializer_class = PaymentSerializer
    queryset = Payment.objects.all().select_related('order', 'order__customer').order_by('-created_at')

    def get_queryset(self):
        qs = super().get_queryset()
        status_param = self.request.query_params.get('status')
        if status_param and status_param != 'all':
            qs = qs.filter(status=status_param.upper())
        provider_param = self.request.query_params.get('provider')
        if provider_param and provider_param != 'all':
            qs = qs.filter(provider=provider_param.upper())
        search_query = self.request.query_params.get('search')
        if search_query:
            qs = qs.filter(
                Q(merchant_reference__icontains=search_query) |
                Q(transaction_id__icontains=search_query) |
                Q(order__order_reference__icontains=search_query) |
                Q(order__customer__username__icontains=search_query)
            )
        return qs

    @action(detail=True, methods=['post'])
    def refund(self, request, pk=None):
        payment = self.get_object()
        if payment.status != 'PAID':
            return Response(
                {'error': f'Cannot refund payment in {payment.status} status. Only PAID transactions are eligible for refund.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        reason = request.data.get('reason', 'Administrative refund')
        from .payments.service import payment_service
        try:
            provider = payment_service.get_provider(payment.provider)
            refund_result = provider.refund(payment)
        except Exception as e:
            return Response({'error': f'Provider refund failed: {str(e)}'}, status=status.HTTP_400_BAD_REQUEST)

        with transaction.atomic():
            payment.status = 'REFUNDED'
            payment.save(update_fields=['status'])
            order = payment.order
            order.payment_status = 'REFUNDED'
            if order.status not in ['delivered', 'cancelled']:
                order.status = 'cancelled'
                order.cancellation_reason = reason
                order.save(update_fields=['payment_status', 'status', 'cancellation_reason'])
            else:
                order.save(update_fields=['payment_status'])

            AuditLog.objects.create(
                admin_user=request.user,
                action='REFUND_PAYMENT',
                target_type='Payment',
                target_id=str(payment.id),
                details={
                    'amount': str(payment.amount),
                    'currency': payment.currency,
                    'order_id': order.id,
                    'order_reference': order.order_reference,
                    'reason': reason,
                    'provider': payment.provider
                },
                ip_address=_get_client_ip(request)
            )

        return Response({
            'message': f'Payment #{payment.id} refunded successfully.',
            'payment': PaymentSerializer(payment, context={'request': request}).data,
            'result': refund_result
        })

class AdminDriverViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAdminOrStaff]
    serializer_class = DriverSerializer
    queryset = Driver.objects.select_related('user').all().order_by('-id')

    def get_queryset(self):
        qs = super().get_queryset()
        approved = self.request.query_params.get('approved')
        if approved is not None:
            qs = qs.filter(is_approved=approved.lower() in ('true', '1'))
        online = self.request.query_params.get('online')
        if online is not None:
            qs = qs.filter(is_online=online.lower() in ('true', '1'))
        search_query = self.request.query_params.get('search')
        if search_query:
            qs = qs.filter(
                Q(user__username__icontains=search_query) |
                Q(user__first_name__icontains=search_query) |
                Q(user__phone__icontains=search_query) |
                Q(license_plate__icontains=search_query) |
                Q(vehicle_type__icontains=search_query)
            )
        return qs

    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        driver = self.get_object()
        driver.is_approved = True
        driver.save(update_fields=['is_approved'])
        AuditLog.objects.create(
            admin_user=request.user,
            action='APPROVE_DRIVER',
            target_type='Driver',
            target_id=str(driver.id),
            details={'action': 'approve', 'driver_username': driver.user.username},
            ip_address=_get_client_ip(request)
        )
        return Response({
            'status': 'SUCCESS',
            'message': f'Driver {driver.user.username} approved.',
            'driver': DriverSerializer(driver, context={'request': request}).data
        })

    @action(detail=True, methods=['post'])
    def suspend(self, request, pk=None):
        driver = self.get_object()
        driver.is_approved = False
        driver.is_online = False
        driver.save(update_fields=['is_approved', 'is_online'])
        AuditLog.objects.create(
            admin_user=request.user,
            action='SUSPEND_DRIVER',
            target_type='Driver',
            target_id=str(driver.id),
            details={'action': 'suspend', 'driver_username': driver.user.username},
            ip_address=_get_client_ip(request)
        )
        return Response({
            'status': 'SUCCESS',
            'message': f'Driver {driver.user.username} suspended.',
            'driver': DriverSerializer(driver, context={'request': request}).data
        })
