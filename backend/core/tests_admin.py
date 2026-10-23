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

    def test_user_registration_always_forces_customer_role(self):
        """Self-registration via API only creates customer accounts; admin/driver/owner roles are forbidden."""
        payload = {
            'username': 'attacker_trying_admin',
            'email': 'attacker@example.com',
            'password': 'SecurePassword123!',
            'role': 'admin'
        }
        res = self.client.post('/api/register/', payload, format='json')
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        created_user = User.objects.get(username='attacker_trying_admin')
        self.assertEqual(created_user.role, 'customer')
        self.assertFalse(created_user.is_staff)
        self.assertFalse(created_user.is_superuser)

    def test_user_admin_save_model_admin_role_auto_grants_staff(self):
        """When an admin creates an Admin user in Django admin, staff & superuser flags are automatically granted."""
        from django.contrib.admin.sites import site
        from core.admin import UserAdmin
        ua = UserAdmin(User, site)
        new_admin = User(username='new_admin_exec', email='admin2@foodgo.com', role='admin')
        ua.save_model(None, new_admin, None, False)
        self.assertTrue(new_admin.is_staff)
        self.assertTrue(new_admin.is_superuser)

    def test_user_admin_save_model_driver_role_auto_provisions_profile(self):
        """When an admin creates a Driver user in Django admin, a Driver profile is automatically created."""
        from django.contrib.admin.sites import site
        from core.admin import UserAdmin
        ua = UserAdmin(User, site)
        new_driver_user = User.objects.create_user(username='new_driver_user', email='d@foodgo.com', role='driver')
        ua.save_model(None, new_driver_user, None, False)
        self.assertTrue(hasattr(new_driver_user, 'driver_profile'))
        self.assertEqual(new_driver_user.driver_profile.license_plate, 'PP-1AB-2026')

    def test_driver_admin_save_model_updates_user_role_and_updates_cleanly(self):
        """DriverAdmin.save_model ensures user.role is 'driver' and safely updates existing records without IntegrityError."""
        from django.contrib.admin.sites import site
        from core.admin import DriverAdmin
        da = DriverAdmin(Driver, site)

        normal_user = User.objects.create_user(username='normal_to_driver', email='norm@foodgo.com', role='customer')
        # Create driver via admin
        driver_entry = Driver(user=normal_user, vehicle_type='Honda Scoopy', license_plate='PP-8888', is_online=True)
        da.save_model(None, driver_entry, None, False)

        normal_user.refresh_from_db()
        self.assertEqual(normal_user.role, 'driver')
        self.assertEqual(Driver.objects.filter(user=normal_user).count(), 1)

        # Attempt to save a duplicate Driver entry for the same user (e.g. from popup workflow)
        duplicate_entry = Driver(user=normal_user, vehicle_type='Yamaha Fazzio', license_plate='PP-7777', is_online=True)
        da.save_model(None, duplicate_entry, None, False)

        # Confirm it updated the existing record without crashing
        self.assertEqual(Driver.objects.filter(user=normal_user).count(), 1)
        driver_saved = Driver.objects.get(user=normal_user)
        self.assertEqual(driver_saved.license_plate, 'PP-7777')

    def test_restaurant_admin_save_model_sets_owner_role(self):
        """RestaurantAdmin.save_model ensures owner user.role is updated to 'restaurant_owner'."""
        from django.contrib.admin.sites import site
        from core.admin import RestaurantAdmin
        ra = RestaurantAdmin(Restaurant, site)

        user_for_owner = User.objects.create_user(username='promoted_owner', email='powner@foodgo.com', role='customer')
        rest = Restaurant.objects.create(
            owner=user_for_owner,
            name='Owner Promo Diner',
            address='Street 271',
            phone='+85598765432'
        )
        ra.save_model(None, rest, None, False)

        user_for_owner.refresh_from_db()
        self.assertEqual(user_for_owner.role, 'restaurant_owner')

    def test_user_admin_convert_to_owner_action(self):
        """UserAdmin convert_to_owner bulk action updates user roles to restaurant_owner."""
        from django.contrib.admin.sites import site
        from core.admin import UserAdmin
        from django.test import RequestFactory
        from django.contrib.messages.storage.fallback import FallbackStorage

        ua = UserAdmin(User, site)
        user_c = User.objects.create_user(username='bulk_cust_to_owner', email='b@foodgo.com', role='customer')

        rf = RequestFactory()
        req = rf.post('/admin/core/user/')
        setattr(req, 'session', {})
        setattr(req, '_messages', FallbackStorage(req))

        ua.convert_to_owner(req, User.objects.filter(id=user_c.id))
        user_c.refresh_from_db()
        self.assertEqual(user_c.role, 'restaurant_owner')

    def test_driver_admin_foreignkey_filters_available_users(self):
        """DriverAdmin.formfield_for_foreignkey only lists users without an existing driver profile."""
        from django.contrib.admin.sites import site
        from core.admin import DriverAdmin
        from django.test import RequestFactory

        da = DriverAdmin(Driver, site)
        rf = RequestFactory()
        req = rf.get('/admin/core/driver/add/')
        field = da.formfield_for_foreignkey(Driver._meta.get_field('user'), req)

        # self.driver_user already has self.driver, so it must not be in the queryset
        self.assertNotIn(self.driver_user, field.queryset)
        # self.customer does NOT have a driver, so it must be in the queryset
        self.assertIn(self.customer, field.queryset)

    def test_user_admin_changelist_render(self):
        """UserAdmin changelist renders without TypeError on user_avatar_thumb with no photo."""
        from django.test import Client
        client = Client()
        client.force_login(self.admin)
        resp = client.get('/admin/core/user/')
        self.assertEqual(resp.status_code, 200)
        self.assertContains(resp, 'No photo')

    def test_order_admin_changelist_render(self):
        """OrderAdmin changelist renders without TypeError on assigned_driver_badge."""
        from django.test import Client
        client = Client()
        client.force_login(self.admin)
        resp = client.get('/admin/core/order/')
        self.assertEqual(resp.status_code, 200)
        self.assertContains(resp, 'Unassigned')

    def test_restaurant_admin_changelist_render(self):
        """RestaurantAdmin changelist renders without TypeError on restaurant_logo with no photo."""
        from django.test import Client
        client = Client()
        client.force_login(self.admin)
        resp = client.get('/admin/core/restaurant/')
        self.assertEqual(resp.status_code, 200)
        self.assertContains(resp, 'No photo')

    def test_fooditem_admin_changelist_render(self):
        """FoodItemAdmin changelist renders without TypeError."""
        from django.test import Client
        client = Client()
        client.force_login(self.admin)
        resp = client.get('/admin/core/fooditem/')
        self.assertEqual(resp.status_code, 200)

    def test_admin_can_create_driver_user_and_profile(self):
        """Admin can create a new delivery driver with auto-provisioned driver profile."""
        from django.test import Client
        from core.models import Driver
        client = Client()
        client.force_login(self.admin)
        resp = client.post('/admin/core/user/add/', {
            'username': 'new_admin_driver_test',
            'password1': 'DriverPass2026!',
            'password2': 'DriverPass2026!',
            'role': 'driver',
            'email': 'driver_new@foodgo.com',
            'first_name': 'Sok',
            'last_name': 'Driver',
            'is_active': 'on',
            '_save': 'Save',
        })
        self.assertEqual(resp.status_code, 302)
        driver_user = User.objects.filter(username='new_admin_driver_test').first()
        self.assertIsNotNone(driver_user)
        self.assertEqual(driver_user.role, 'driver')
        profile = Driver.objects.filter(user=driver_user).first()
        self.assertIsNotNone(profile)
        self.assertTrue(profile.is_approved)

    def test_admin_can_create_restaurant_owner(self):
        """Admin can create a new restaurant owner."""
        from django.test import Client
        client = Client()
        client.force_login(self.admin)
        resp = client.post('/admin/core/user/add/', {
            'username': 'new_admin_owner_test',
            'password1': 'OwnerPass2026!',
            'password2': 'OwnerPass2026!',
            'role': 'restaurant_owner',
            'email': 'owner_new@foodgo.com',
            'first_name': 'Vann',
            'last_name': 'Owner',
            'is_active': 'on',
            '_save': 'Save',
        })
        self.assertEqual(resp.status_code, 302)
        owner_user = User.objects.filter(username='new_admin_owner_test').first()
        self.assertIsNotNone(owner_user)
        self.assertEqual(owner_user.role, 'restaurant_owner')




