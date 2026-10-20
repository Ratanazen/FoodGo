from decimal import Decimal
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from .models import User, Order, Restaurant, Driver, Delivery, AuditLog, Payment

class AdminFeatureTestCase(APITestCase):
    def setUp(self):
        # Create Admin
        self.admin = User.objects.create_superuser(
            username='admin_test',
            email='admin_test@foodgo.com',
            password='password123',
            role='admin'
        )

        # Create Normal Customer
        self.customer = User.objects.create_user(
            username='cust_test',
            email='cust@foodgo.com',
            password='password123',
            role='customer'
        )

        # Create Driver
        self.driver_user = User.objects.create_user(
            username='driver_test',
            email='driver@foodgo.com',
            password='password123',
            role='driver'
        )
        self.driver = Driver.objects.create(
            user=self.driver_user,
            vehicle_type='Motorbike',
            license_plate='PP-9999',
            is_online=True
        )

        # Create Restaurant
        self.owner = User.objects.create_user(
            username='owner_test',
            email='owner@foodgo.com',
            password='password123',
            role='restaurant_owner'
        )
        self.restaurant = Restaurant.objects.create(
            owner=self.owner,
            name='Test Burger Palace',
            address='123 Main St',
            phone='+85512345678',
            delivery_fee=Decimal('1.50'),
            is_active=True
        )

        # Create Orders
        self.order1 = Order.objects.create(
            customer=self.customer,
            restaurant=self.restaurant,
            total_amount=Decimal('25.00'),
            status='pending',
            payment_status='PAID'
        )
        self.order2 = Order.objects.create(
            customer=self.customer,
            restaurant=self.restaurant,
            total_amount=Decimal('15.00'),
            status='delivered',
            payment_status='PAID'
        )

        # Create Payment
        self.payment1 = Payment.objects.create(
            order=self.order1,
            amount=Decimal('25.00'),
            currency='USD',
            provider='BAKONG',
            method='KHQR',
            status='PAID'
        )

    def test_admin_analytics_requires_admin(self):
        url = reverse('admin_analytics')
        # Anonymous fails
        res = self.client.get(url)
        self.assertEqual(res.status_code, status.HTTP_401_UNAUTHORIZED)

        # Customer fails
        self.client.force_authenticate(user=self.customer)
        res = self.client.get(url)
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

        # Admin succeeds
        self.client.force_authenticate(user=self.admin)
        res = self.client.get(url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertIn('metrics', res.data)
        self.assertEqual(res.data['metrics']['total_orders'], 2)
        self.assertIn('system_health', res.data)
        self.assertEqual(res.data['system_health']['database'], 'healthy')

    def test_admin_analytics_period_filter(self):
        self.client.force_authenticate(user=self.admin)
        url = reverse('admin_analytics') + '?period=today'
        res = self.client.get(url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['period'], 'today')

    def test_admin_assign_driver(self):
        self.client.force_authenticate(user=self.admin)
        url = f"/api/admin/orders/{self.order1.id}/assign_driver/"
        res = self.client.post(url, {'driver_id': self.driver.id}, format='json')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        
        # Verify delivery created
        delivery = Delivery.objects.get(order=self.order1)
        self.assertEqual(delivery.driver, self.driver)

        # Verify audit log recorded
        log = AuditLog.objects.filter(action='ASSIGN_DRIVER', target_id=str(self.order1.id)).first()
        self.assertIsNotNone(log)
        self.assertEqual(log.admin_user, self.admin)

    def test_admin_cancel_order(self):
        self.client.force_authenticate(user=self.admin)
        url = f"/api/admin/orders/{self.order1.id}/cancel_order/"
        res = self.client.post(url, {'cancellation_reason': 'Item unavailable'}, format='json')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        
        self.order1.refresh_from_db()
        self.assertEqual(self.order1.status, 'cancelled')
        self.assertEqual(self.order1.cancellation_reason, 'Item unavailable')

        # Verify audit log
        log = AuditLog.objects.filter(action='CANCEL_ORDER', target_id=str(self.order1.id)).first()
        self.assertIsNotNone(log)

    def test_admin_toggle_user_status(self):
        self.client.force_authenticate(user=self.admin)
        url = f"/api/admin/users/{self.customer.id}/toggle_status/"
        res = self.client.post(url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        
        self.customer.refresh_from_db()
        self.assertFalse(self.customer.is_active)

        # Verify self-deactivation is rejected
        self_url = f"/api/admin/users/{self.admin.id}/toggle_status/"
        self_res = self.client.post(self_url)
        self.assertEqual(self_res.status_code, status.HTTP_400_BAD_REQUEST)

    def test_admin_toggle_restaurant_status(self):
        self.client.force_authenticate(user=self.admin)
        url = f"/api/admin/restaurants/{self.restaurant.id}/toggle_status/"
        res = self.client.post(url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        
        self.restaurant.refresh_from_db()
        self.assertFalse(self.restaurant.is_active)

    def test_admin_audit_logs_endpoint(self):
        # Create an audit log
        AuditLog.objects.create(
            admin_user=self.admin,
            action='SYSTEM_CONFIG',
            target_type='System',
            target_id='0',
            details={'updated': 'tax_rate'}
        )

        self.client.force_authenticate(user=self.admin)
        url = '/api/admin/audit-logs/'
        res = self.client.get(url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        # Check result is a list or paginated results
        results = res.data if isinstance(res.data, list) else res.data.get('results', [])
        self.assertGreaterEqual(len(results), 1)

    def test_admin_payments_list_and_filters(self):
        # Customer access rejected
        self.client.force_authenticate(user=self.customer)
        res = self.client.get('/api/admin/payments/')
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

        # Admin access accepted
        self.client.force_authenticate(user=self.admin)
        res = self.client.get('/api/admin/payments/')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        results = res.data if isinstance(res.data, list) else res.data.get('results', [])
        self.assertEqual(len(results), 1)
        self.assertEqual(results[0]['provider'], 'BAKONG')
        self.assertEqual(results[0]['status'], 'PAID')

        # Filter by status
        res_filter = self.client.get('/api/admin/payments/?status=PAID')
        self.assertEqual(res_filter.status_code, status.HTTP_200_OK)
        results_filter = res_filter.data if isinstance(res_filter.data, list) else res_filter.data.get('results', [])
        self.assertEqual(len(results_filter), 1)

        # Filter by empty status
        res_empty = self.client.get('/api/admin/payments/?status=FAILED')
        self.assertEqual(res_empty.status_code, status.HTTP_200_OK)
        results_empty = res_empty.data if isinstance(res_empty.data, list) else res_empty.data.get('results', [])
        self.assertEqual(len(results_empty), 0)

    def test_admin_payment_refund_and_audit_log(self):
        self.client.force_authenticate(user=self.admin)
        url = f"/api/admin/payments/{self.payment1.id}/refund/"
        res = self.client.post(url, {'reason': 'Customer requested refund via phone'}, format='json')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['payment']['status'], 'REFUNDED')

        self.payment1.refresh_from_db()
        self.assertEqual(self.payment1.status, 'REFUNDED')

        self.order1.refresh_from_db()
        self.assertEqual(self.order1.payment_status, 'REFUNDED')
        self.assertEqual(self.order1.status, 'cancelled')

        # Verify audit log
        log = AuditLog.objects.filter(action='REFUND_PAYMENT', target_id=str(self.payment1.id)).first()
        self.assertIsNotNone(log)
        self.assertEqual(log.admin_user, self.admin)
        self.assertIn('Customer requested refund', log.details.get('reason', ''))

    def test_admin_analytics_revenue_tracking(self):
        self.client.force_authenticate(user=self.admin)
        url = reverse('admin_analytics')
        res = self.client.get(url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        # Total revenue reflects the $25.00 payment with status='PAID'
        self.assertEqual(float(res.data['metrics']['total_revenue']), 25.0)
