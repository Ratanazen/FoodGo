from decimal import Decimal
from django.utils import timezone
from django.test import TestCase, TransactionTestCase
from django.urls import reverse
from rest_framework.test import APIClient
from rest_framework import status
from core.models import (
    User, Restaurant, FoodCategory, FoodItem, Order, OrderItem,
    Cart, CartItem, Wallet, Review, Driver, Delivery, Notification, Address,
    Payment, OrderStatusHistory
)
from core.tests_admin import AdminFeatureTestCase

class FoodGoCoreAPITests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.customer = User.objects.create_user(
            username='khmer_foodie',
            email='foodie@foodgo.kh',
            password='Password123!',
            role='customer',
            phone='+85512888999'
        )
        self.owner = User.objects.create_user(
            username='chef_sok',
            email='sok@foodgo.kh',
            password='Password123!',
            role='restaurant_owner'
        )
        self.restaurant = Restaurant.objects.create(
            owner=self.owner,
            name='Angkor Delights',
            address='Street 08, Pub Street, Siem Reap',
            phone='012345678',
            delivery_fee=Decimal('1.50'),
            is_active=True
        )
        self.category = FoodCategory.objects.create(
            restaurant=self.restaurant,
            name='Khmer Specials'
        )
        self.food_item = FoodItem.objects.create(
            category=self.category,
            name='Fish Amok',
            description='Traditional steamed fish curry in banana leaf',
            price=Decimal('6.50'),
            is_available=True
        )

    def test_user_registration(self):
        url = reverse('register')
        data = {
            'username': 'new_customer',
            'email': 'new@foodgo.kh',
            'password': 'SecurePass123!',
            'first_name': 'Dara',
            'last_name': 'Chan'
        }
        res = self.client.post(url, data, format='json')
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data['username'], 'new_customer')
        self.assertEqual(res.data['role'], 'customer')

    def test_jwt_token_obtain(self):
        url = reverse('token_obtain_pair')
        data = {
            'username': 'khmer_foodie',
            'password': 'Password123!'
        }
        res = self.client.post(url, data, format='json')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertIn('access', res.data)
        self.assertIn('refresh', res.data)

    def test_jwt_token_obtain_via_email(self):
        url = reverse('token_obtain_pair')
        data = {
            'username': 'foodie@foodgo.kh',
            'password': 'Password123!'
        }
        res = self.client.post(url, data, format='json')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertIn('access', res.data)

    def test_jwt_token_obtain_via_phone(self):
        url = reverse('token_obtain_pair')
        data = {
            'username': '+85512888999',
            'password': 'Password123!'
        }
        res = self.client.post(url, data, format='json')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertIn('access', res.data)

    def test_jwt_token_obtain_invalid_password(self):
        url = reverse('token_obtain_pair')
        data = {
            'username': 'khmer_foodie',
            'password': 'WrongPassword999!'
        }
        res = self.client.post(url, data, format='json')
        self.assertEqual(res.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_jwt_token_obtain_nonexistent_user(self):
        url = reverse('token_obtain_pair')
        data = {
            'username': 'does_not_exist_user',
            'password': 'Password123!'
        }
        res = self.client.post(url, data, format='json')
        self.assertEqual(res.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_user_me_endpoint(self):
        self.client.force_authenticate(user=self.customer)
        url = reverse('user-me')
        res = self.client.get(url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['username'], 'khmer_foodie')
        self.assertEqual(res.data['role'], 'customer')

    def test_restaurant_listing_public(self):
        url = reverse('restaurant-list')
        res = self.client.get(url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertTrue(len(res.data) >= 1)
        self.assertEqual(res.data[0]['name'], 'Angkor Delights')

    def test_food_item_listing(self):
        url = reverse('fooditem-list')
        res = self.client.get(url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertTrue(len(res.data) >= 1)
        self.assertEqual(res.data[0]['name'], 'Fish Amok')

    def test_restaurant_owner_dashboard_endpoint(self):
        self.client.force_authenticate(user=self.owner)
        url = reverse('restaurant-my-restaurant')
        res = self.client.get(url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['name'], 'Angkor Delights')

    def test_cart_and_order_flow(self):
        self.client.force_authenticate(user=self.customer)
        
        # 1. Add item to cart
        cart, _ = Cart.objects.get_or_create(customer=self.customer)
        CartItem.objects.create(cart=cart, food_item=self.food_item, quantity=2)

        # 2. Place order
        url = reverse('order-list')
        data = {
            'restaurant': self.restaurant.id,
            'special_instructions': 'Extra spicy please'
        }
        res = self.client.post(url, data, format='json')
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data['status'], 'pending')
        
        # Total = 6.50 * 2 + 1.50 (delivery fee) = 14.50
        order = Order.objects.get(id=res.data['id'])
        self.assertEqual(order.total_amount, Decimal('14.50'))
        self.assertEqual(order.payment_status, 'UNPAID')
        self.assertEqual(order.items.count(), 1)
        self.assertEqual(order.items.first().quantity, 2)

    def test_delivered_order_review(self):
        self.client.force_authenticate(user=self.customer)
        order = Order.objects.create(
            customer=self.customer,
            restaurant=self.restaurant,
            total_amount=Decimal('10.00'),
            status='delivered',
            payment_status='PAID'
        )
        url = reverse('review-list')
        data = {
            'order': order.id,
            'rating': 5,
            'comment': 'Delicious authentic Amok!'
        }
        res = self.client.post(url, data, format='json')
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data['rating'], 5)

    def test_google_login_new_user(self):
        url = reverse('google_login')
        payload = {
            'id_token': 'test-google-token',
            'email': 'sothea.chan@gmail.com',
            'name': 'Sothea Chan'
        }
        res = self.client.post(url, payload, format='json')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertIn('access', res.data)
        self.assertIn('refresh', res.data)
        self.assertTrue(res.data['is_new_user'])
        self.assertEqual(res.data['user']['email'], 'sothea.chan@gmail.com')
        self.assertEqual(res.data['user']['role'], 'customer')

    def test_google_login_existing_user(self):
        # Already exists from setUp: foodie@foodgo.kh
        url = reverse('google_login')
        payload = {
            'id_token': 'test-google-token',
            'email': 'foodie@foodgo.kh',
            'name': 'Khmer Foodie'
        }
        res = self.client.post(url, payload, format='json')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertIn('access', res.data)
        self.assertFalse(res.data['is_new_user'])
        self.assertEqual(res.data['user']['username'], 'khmer_foodie')

    def test_list_drivers(self):
        driver_user = User.objects.create_user(
            username='rider_test',
            email='rider@foodgo.kh',
            password='Password123!',
            role='driver',
            phone='+85512345678'
        )
        Driver.objects.create(
            user=driver_user,
            vehicle_type='Honda Wave',
            license_plate='PP-9999',
            is_online=True
        )
        res = self.client.get('/api/drivers/')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertGreaterEqual(len(res.data), 1)
        driver_data = next((d for d in res.data if d['username'] == 'rider_test'), None)
        self.assertIsNotNone(driver_data)
        self.assertEqual(driver_data['vehicle_type'], 'Honda Wave')
        self.assertTrue(driver_data['is_online'])

    def test_order_creation_with_driver_assignment(self):
        self.client.force_authenticate(user=self.customer)
        driver_user = User.objects.create_user(
            username='speedy_rider',
            email='speedy@foodgo.kh',
            password='Password123!',
            role='driver'
        )
        driver = Driver.objects.create(
            user=driver_user,
            vehicle_type='Yamaha Fazzio',
            license_plate='PP-8888',
            is_online=True
        )
        res = self.client.post('/api/orders/', {
            'restaurant': self.restaurant.id,
            'driver_id': driver.id,
            'items': [{'food_item': self.food_item.id, 'quantity': 2}]
        }, format='json')
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        order_id = res.data['id']
        self.assertEqual(res.data['assigned_driver']['name'], 'speedy_rider')

        # Test tracking returns driver profile
        track_res = self.client.get(f'/api/orders/{order_id}/track/')
        self.assertEqual(track_res.status_code, status.HTTP_200_OK)
        self.assertIn('driver', track_res.data)
        self.assertEqual(track_res.data['driver']['id'], driver.id)
        self.assertEqual(track_res.data['driver']['vehicle_type'], 'Yamaha Fazzio')

    def test_food_item_search_by_restaurant_and_category(self):
        # Create additional dish with specific price
        FoodItem.objects.create(
            category=self.category,
            name='Beef Lok Lak',
            description='Stir fried marinated beef cubes with Kampot pepper sauce',
            price=Decimal('12.00'),
            is_available=True
        )

        # Search by restaurant name 'Angkor' should find items
        res = self.client.get('/api/food-items/?search=Angkor')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        results = res.data if isinstance(res.data, list) else res.data.get('results', [])
        self.assertTrue(any(item['name'] == 'Fish Amok' for item in results))

        # Search by category 'Specials' should find items
        res_cat = self.client.get('/api/food-items/?search=Specials')
        self.assertEqual(res_cat.status_code, status.HTTP_200_OK)
        results_cat = res_cat.data if isinstance(res_cat.data, list) else res_cat.data.get('results', [])
        self.assertTrue(any(item['name'] == 'Beef Lok Lak' for item in results_cat))

    def test_food_item_price_filters_and_ordering(self):
        FoodItem.objects.create(
            category=self.category,
            name='Kuy Teav Soup',
            description='Pork noodle soup',
            price=Decimal('3.50'),
            is_available=True
        )
        FoodItem.objects.create(
            category=self.category,
            name='Kampot Crab Feast',
            description='Fresh seafood with black pepper',
            price=Decimal('25.00'),
            is_available=True
        )

        # Filter price <= 5.00
        res_low = self.client.get('/api/food-items/?max_price=5.00')
        self.assertEqual(res_low.status_code, status.HTTP_200_OK)
        results_low = res_low.data if isinstance(res_low.data, list) else res_low.data.get('results', [])
        self.assertTrue(all(float(item['price']) <= 5.00 for item in results_low))

        # Filter price >= 20.00
        res_high = self.client.get('/api/food-items/?min_price=20.00')
        self.assertEqual(res_high.status_code, status.HTTP_200_OK)
        results_high = res_high.data if isinstance(res_high.data, list) else res_high.data.get('results', [])
        self.assertTrue(all(float(item['price']) >= 20.00 for item in results_high))

        # Ordering price_asc
        res_asc = self.client.get('/api/food-items/?ordering=price_asc')
        self.assertEqual(res_asc.status_code, status.HTTP_200_OK)
        results_asc = res_asc.data if isinstance(res_asc.data, list) else res_asc.data.get('results', [])
        prices = [float(item['price']) for item in results_asc]
        self.assertEqual(prices, sorted(prices))

    def test_restaurant_search_and_price_tier(self):
        res = self.client.get('/api/restaurants/?search=Angkor')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        results = res.data if isinstance(res.data, list) else res.data.get('results', [])
        self.assertTrue(any(r['name'] == 'Angkor Delights' for r in results))

        # Price tier filter '$' (delivery_fee <= 1.50)
        res_tier = self.client.get('/api/restaurants/?price_tier=$')
        self.assertEqual(res_tier.status_code, status.HTTP_200_OK)
        results_tier = res_tier.data if isinstance(res_tier.data, list) else res_tier.data.get('results', [])
        self.assertTrue(any(r['name'] == 'Angkor Delights' for r in results_tier))

    def test_order_creation_triggers_notification(self):
        self.client.force_authenticate(user=self.customer)
        data = {
            'restaurant': self.restaurant.id,
            'items': [{'food_item': self.food_item.id, 'quantity': 2}],
            'payment_method': 'COD'
        }
        res = self.client.post('/api/orders/', data, format='json')
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        order_id = res.data['id']

        notif = Notification.objects.filter(user=self.customer, data__order_id=order_id).first()
        self.assertIsNotNone(notif)
        self.assertEqual(notif.notification_type, 'order')
        self.assertIn('Placed', notif.title)
        self.assertFalse(notif.is_read)

    def test_order_status_update_triggers_notification(self):
        order = Order.objects.create(
            customer=self.customer,
            restaurant=self.restaurant,
            total_amount=Decimal('15.00'),
            status='pending'
        )
        staff_user = User.objects.create_superuser('admin_tester', 'admin@foodgo.kh', 'Admin123!')
        self.client.force_authenticate(user=staff_user)
        res = self.client.patch(f'/api/orders/{order.id}/', {'status': 'confirmed'}, format='json')
        self.assertEqual(res.status_code, status.HTTP_200_OK)

        notif = Notification.objects.filter(user=self.customer, data__order_id=order.id, data__status='confirmed').first()
        self.assertIsNotNone(notif)
        self.assertIn('Confirmed', notif.title)

    def test_order_save_automated_milestone_dispatch(self):
        # 1. Order.objects.create triggers automated milestone notification
        order = Order.objects.create(
            customer=self.customer,
            restaurant=self.restaurant,
            total_amount=Decimal('28.50'),
            status='pending'
        )
        placed_notif = Notification.objects.filter(
            user=self.customer,
            data__order_id=order.id,
            data__status='pending'
        ).first()
        self.assertIsNotNone(placed_notif)
        self.assertEqual(placed_notif.title, 'Order Placed')

        # 2. Status transition on Order.save triggers next milestone
        order.status = 'confirmed'
        order.save()
        confirmed_notif = Notification.objects.filter(
            user=self.customer,
            data__order_id=order.id,
            data__status='confirmed'
        ).first()
        self.assertIsNotNone(confirmed_notif)
        self.assertEqual(confirmed_notif.title, 'Order Confirmed')

        # 3. Saving without status change does not duplicate
        initial_count = Notification.objects.filter(user=self.customer, data__order_id=order.id).count()
        order.special_instructions = 'Extra sauce please'
        order.save()
        after_count = Notification.objects.filter(user=self.customer, data__order_id=order.id).count()
        self.assertEqual(initial_count, after_count)

        # 4. Rapid manual dispatch does not create duplicate
        from core.notifications import dispatch_order_notification
        dup_check = dispatch_order_notification(order, status_key='confirmed')
        self.assertIsNotNone(dup_check)
        self.assertEqual(
            Notification.objects.filter(user=self.customer, data__order_id=order.id, data__status='confirmed').count(),
            1
        )


    def test_notification_apis_and_unread_count(self):
        Notification.objects.create(
            user=self.customer,
            title='Promo Voucher',
            message='Enjoy 20% discount!',
            notification_type='promo',
            is_read=False
        )
        Notification.objects.create(
            user=self.customer,
            title='Order Update',
            message='Order on the way',
            notification_type='order',
            is_read=False
        )
        self.client.force_authenticate(user=self.customer)

        res_count = self.client.get('/api/notifications/unread-count/')
        self.assertEqual(res_count.status_code, status.HTTP_200_OK)
        self.assertEqual(res_count.data['unread_count'], 2)

        res_mark = self.client.post('/api/notifications/mark-all-read/')
        self.assertEqual(res_mark.status_code, status.HTTP_200_OK)

        res_count_after = self.client.get('/api/notifications/unread-count/')
        self.assertEqual(res_count_after.data['unread_count'], 0)

    def test_order_tracking_api_endpoint(self):
        order = Order.objects.create(
            customer=self.customer,
            restaurant=self.restaurant,
            total_amount=Decimal('20.00'),
            status='on_the_way'
        )
        self.client.force_authenticate(user=self.customer)
        res = self.client.get(f'/api/orders/{order.id}/track/')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertIn('restaurant_location', res.data)
        self.assertIn('status', res.data)
        self.assertEqual(res.data['status'], 'on_the_way')

    def test_websocket_check_order_access(self):
        from core.consumers import check_order_access_sync

        order = Order.objects.create(
            customer=self.customer,
            restaurant=self.restaurant,
            total_amount=Decimal('20.00'),
            status='on_the_way'
        )
        other_user = User.objects.create_user('other_person', 'other@foodgo.kh', 'Pass123!')

        can_connect_customer, _ = check_order_access_sync(order.id, self.customer)
        self.assertTrue(can_connect_customer)

        can_connect_other, _ = check_order_access_sync(order.id, other_user)
        self.assertFalse(can_connect_other)

        staff_user = User.objects.create_superuser('boss', 'boss@foodgo.kh', 'Admin123!')
        can_connect_staff, _ = check_order_access_sync(order.id, staff_user)
        self.assertTrue(can_connect_staff)

    def test_currency_rates_api(self):
        res = self.client.get('/api/currency/rates/')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['base_currency'], 'USD')
        self.assertEqual(res.data['target_currency'], 'KHR')
        self.assertAlmostEqual(res.data['rate'], 4100.0)
        self.assertIn('rates', res.data)
        self.assertEqual(res.data['rates']['KHR'], 4100.0)

    def test_health_check_endpoints(self):
        # 1. Test /api/health/
        res = self.client.get('/api/health/')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['status'], 'healthy')
        self.assertEqual(res.data['service'], 'foodgo-backend')
        self.assertEqual(res.data['database'], 'connected')
        self.assertIn('timestamp', res.data)

        # 2. Test root /healthz/
        res_z = self.client.get('/healthz/')
        self.assertEqual(res_z.status_code, status.HTTP_200_OK)
        self.assertEqual(res_z.data['status'], 'healthy')

        # 3. Test root /health/
        res_h = self.client.get('/health/')
        self.assertEqual(res_h.status_code, status.HTTP_200_OK)
        self.assertEqual(res_h.data['status'], 'healthy')

        # 4. Test MongoDB Health Probe
        res_m = self.client.get('/health/mongodb/')
        self.assertIn(res_m.status_code, [status.HTTP_200_OK, status.HTTP_503_SERVICE_UNAVAILABLE])
        self.assertIn('status', res_m.data)


class DriverModuleTestCase(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.customer = User.objects.create_user(
            username='somnang_cust',
            email='somnang@foodgo.kh',
            password='Customer123!',
            role='customer',
            phone='+855 12 111 222'
        )
        self.address = Address.objects.create(
            user=self.customer,
            street='Street 271, Boeng Tumpun',
            city='Phnom Penh',
            state='Phnom Penh',
            zip_code='12000',
            lat=Decimal('11.5420'),
            lng=Decimal('104.9120')
        )
        self.owner = User.objects.create_user(
            username='chef_dara',
            email='dara@foodgo.kh',
            password='Owner123!',
            role='restaurant_owner'
        )
        self.restaurant = Restaurant.objects.create(
            owner=self.owner,
            name='Kravanh Bistro',
            address='St 240, Daun Penh, Phnom Penh',
            phone='+855 23 888 777',
            delivery_fee=Decimal('2.50'),
            lat=Decimal('11.5580'),
            lng=Decimal('104.9280')
        )
        self.category = FoodCategory.objects.create(
            restaurant=self.restaurant,
            name='Khmer Specialties'
        )
        self.food_item = FoodItem.objects.create(
            category=self.category,
            name='Fish Amok Royal',
            price=Decimal('7.50'),
            is_available=True
        )

        # Drivers
        self.driver_user1 = User.objects.create_user(
            username='rider_borey',
            email='borey@foodgo.kh',
            password='Driver123!',
            role='driver',
            phone='+855 77 333 444',
            is_phone_verified=True,
            phone_normalized='+85577333444'
        )
        self.driver1 = Driver.objects.create(
            user=self.driver_user1,
            vehicle_type='Honda Click 125i',
            license_plate='PP-1AA-1234',
            is_online=True,
            is_approved=True
        )

        self.driver_user2 = User.objects.create_user(
            username='rider_chhaya',
            email='chhaya@foodgo.kh',
            password='Driver123!',
            role='driver',
            phone='+855 77 555 666',
            is_phone_verified=True,
            phone_normalized='+85577555666'
        )
        self.driver2 = Driver.objects.create(
            user=self.driver_user2,
            vehicle_type='Yamaha Scoopy',
            license_plate='PP-1BB-5678',
            is_online=True,
            is_approved=True
        )

    def _create_sample_order(self, payment_status='PAID'):
        order = Order.objects.create(
            customer=self.customer,
            restaurant=self.restaurant,
            address=self.address,
            status='confirmed',
            payment_status=payment_status,
            subtotal=Decimal('15.00'),
            delivery_fee_charged=Decimal('2.50'),
            total_amount=Decimal('17.50')
        )
        OrderItem.objects.create(
            order=order,
            food_item=self.food_item,
            quantity=2,
            price=Decimal('7.50')
        )
        return order

    def test_driver_registration(self):
        data = {
            'username': 'new_rider_rith',
            'email': 'rith@foodgo.kh',
            'password': 'DriverPass123!',
            'first_name': 'Rith',
            'last_name': 'Sok',
            'phone': '+855 92 999 888',
            'vehicle_type': 'Honda Dream 125',
            'license_plate': 'PP-1CC-9999',
        }
        res = self.client.post('/api/drivers/register/', data, format='json')
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data['status'], 'SUCCESS')
        created_user = User.objects.get(username='new_rider_rith')
        self.assertEqual(created_user.role, 'driver')
        self.assertTrue(hasattr(created_user, 'driver_profile'))
        self.assertEqual(created_user.driver_profile.license_plate, 'PP-1CC-9999')

    def test_driver_me_profile_and_toggle_online(self):
        self.client.force_authenticate(user=self.driver_user1)
        res = self.client.get('/api/drivers/me/')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['username'], 'rider_borey')
        self.assertEqual(res.data['vehicle_type'], 'Honda Click 125i')
        self.assertTrue(res.data['is_online'])

        # Toggle offline
        toggle_res = self.client.post('/api/drivers/toggle-online/', {'is_online': False})
        self.assertEqual(toggle_res.status_code, status.HTTP_200_OK)
        self.assertFalse(toggle_res.data['is_online'])
        self.driver1.refresh_from_db()
        self.assertFalse(self.driver1.is_online)

    def test_atomic_delivery_acceptance_concurrency(self):
        order = self._create_sample_order()

        # Driver 1 accepts
        self.client.force_authenticate(user=self.driver_user1)
        res1 = self.client.post(f'/api/drivers/orders/{order.id}/accept/')
        self.assertEqual(res1.status_code, status.HTTP_200_OK)
        self.assertEqual(res1.data['status'], 'SUCCESS')

        # Driver 2 tries to accept the same order -> 409 Conflict
        self.client.force_authenticate(user=self.driver_user2)
        res2 = self.client.post(f'/api/drivers/orders/{order.id}/accept/')
        self.assertEqual(res2.status_code, status.HTTP_409_CONFLICT)
        self.assertIn('already been accepted', res2.data['error'])

    def test_driver_pickup_and_delivery_lifecycle(self):
        order = self._create_sample_order()
        self.client.force_authenticate(user=self.driver_user1)

        # 1. Accept
        res_accept = self.client.post(f'/api/drivers/orders/{order.id}/accept/')
        self.assertEqual(res_accept.status_code, status.HTTP_200_OK)

        # 2. Arrive at restaurant
        res_arrive_rest = self.client.post(f'/api/drivers/orders/{order.id}/arrive-restaurant/')
        self.assertEqual(res_arrive_rest.status_code, status.HTTP_200_OK)
        order.refresh_from_db()
        self.assertEqual(order.delivery.status, 'arrived_at_restaurant')

        # 3. Pickup food
        res_pickup = self.client.post(f'/api/drivers/orders/{order.id}/pickup/')
        self.assertEqual(res_pickup.status_code, status.HTTP_200_OK)
        order.refresh_from_db()
        self.assertEqual(order.delivery.status, 'picked_up')
        self.assertEqual(order.status, 'on_the_way')
        self.assertIsNotNone(order.picked_up_at)

        # 4. Arrive at customer
        res_arrive_cust = self.client.post(f'/api/drivers/orders/{order.id}/arrive-customer/')
        self.assertEqual(res_arrive_cust.status_code, status.HTTP_200_OK)
        order.refresh_from_db()
        self.assertEqual(order.delivery.status, 'arrived')
        self.assertEqual(order.status, 'driver_arrived')

        # 5. Deliver
        res_deliver = self.client.post(f'/api/drivers/orders/{order.id}/deliver/', {'payment_collected': True})
        self.assertEqual(res_deliver.status_code, status.HTTP_200_OK)
        order.refresh_from_db()
        self.assertEqual(order.delivery.status, 'delivered')
        self.assertEqual(order.status, 'delivered')
        self.assertEqual(order.payment_status, 'PAID')

        # Check driver stats & verified earnings
        self.driver1.refresh_from_db()
        self.assertEqual(self.driver1.total_deliveries, 1)
        self.assertEqual(self.driver1.total_earnings, Decimal('2.50'))

    def test_driver_earnings_and_history_api(self):
        order = self._create_sample_order()
        Delivery.objects.create(
            order=order,
            driver=self.driver1,
            status='delivered',
            delivery_time=timezone.now()
        )
        order.status = 'delivered'
        order.delivered_at = timezone.now()
        order.save()
        self.driver1.total_deliveries = 1
        self.driver1.total_earnings = Decimal('2.50')
        self.driver1.save()

        self.client.force_authenticate(user=self.driver_user1)

        # Test /api/drivers/earnings/
        res_earnings = self.client.get('/api/drivers/earnings/')
        self.assertEqual(res_earnings.status_code, status.HTTP_200_OK)
        self.assertGreaterEqual(res_earnings.data['today_earnings_usd'], 2.50)
        self.assertEqual(res_earnings.data['completed_trips'], 1)

        # Test /api/drivers/history/
        res_history = self.client.get('/api/drivers/history/')
        self.assertEqual(res_history.status_code, status.HTTP_200_OK)
        self.assertEqual(len(res_history.data), 1)
        self.assertEqual(res_history.data[0]['id'], order.id)

    def test_unapproved_driver_cannot_accept_orders(self):
        self.driver2.is_approved = False
        self.driver2.save()

        order = self._create_sample_order()
        self.client.force_authenticate(user=self.driver_user2)
        res = self.client.post(f'/api/drivers/orders/{order.id}/accept/')
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)
        self.assertIn('pending administrator approval', res.data['error'])

    def test_driver_cancellation_releases_order(self):
        order = self._create_sample_order()
        self.client.force_authenticate(user=self.driver_user1)

        # Accept order
        self.client.post(f'/api/drivers/orders/{order.id}/accept/')

        # Cancel before pickup
        res_cancel = self.client.post(f'/api/drivers/orders/{order.id}/cancel/', {
            'reason': 'Flat tire on the way to restaurant'
        })
        self.assertEqual(res_cancel.status_code, status.HTTP_200_OK)
        self.assertTrue(res_cancel.data['reassigned'])

        order.refresh_from_db()
        self.assertIsNone(order.delivery.driver)
        self.assertEqual(order.delivery.status, 'assigned')

    def test_driver_verify_cod_payment(self):
        order = self._create_sample_order(payment_status='UNPAID')
        Delivery.objects.create(order=order, driver=self.driver1, status='arrived')
        self.client.force_authenticate(user=self.driver_user1)

        res = self.client.post(f'/api/drivers/orders/{order.id}/verify-payment/')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['payment_status'], 'PAID')
        order.refresh_from_db()
        self.assertEqual(order.payment_status, 'PAID')


class DeliverySystemTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.admin_user = User.objects.create_superuser(
            username='admin_delivery',
            password='Password123!',
            email='admin@foodgo.com',
            role='admin'
        )
        self.customer = User.objects.create_user(
            username='cust_delivery',
            password='Password123!',
            email='cust@foodgo.com',
            role='customer',
            phone='+85512111222'
        )
        self.restaurant_owner = User.objects.create_user(
            username='owner_delivery',
            password='Password123!',
            email='owner@foodgo.com',
            role='restaurant_owner'
        )
        self.restaurant = Restaurant.objects.create(
            owner=self.restaurant_owner,
            name='Phnom Penh Bistro',
            address='St 240, Phnom Penh',
            phone='+855 23 888 777',
            delivery_fee=Decimal('2.50'),
            is_active=True
        )
        self.food_category = FoodCategory.objects.create(
            name='Main Courses',
            restaurant=self.restaurant
        )
        self.food_item = FoodItem.objects.create(
            category=self.food_category,
            name='Fish Amok Royal',
            price=Decimal('12.00'),
            is_available=True
        )
        self.address = Address.objects.create(
            user=self.customer,
            street='Building 12, St 63',
            city='Phnom Penh',
            state='Phnom Penh',
            zip_code='12000',
            lat=Decimal('11.5500'),
            lng=Decimal('104.9200')
        )
        self.driver_user1 = User.objects.create_user(
            username='courier1',
            password='Password123!',
            role='driver',
            phone='+855 12 345 678',
            is_phone_verified=True,
            phone_normalized='+85512345678'
        )
        self.driver1 = Driver.objects.create(
            user=self.driver_user1,
            vehicle_type='Motorcycle (Honda Wave)',
            license_plate='PP-1011',
            is_online=True,
            is_approved=True
        )
        self.driver_user2 = User.objects.create_user(
            username='courier2',
            password='Password123!',
            role='driver',
            phone='+855 12 987 654',
            is_phone_verified=True,
            phone_normalized='+85512987654'
        )
        self.driver2 = Driver.objects.create(
            user=self.driver_user2,
            vehicle_type='Scooter',
            license_plate='PP-2022',
            is_online=True,
            is_approved=True
        )

    def _create_order(self, payment_status='UNPAID'):
        order = Order.objects.create(
            customer=self.customer,
            restaurant=self.restaurant,
            address=self.address,
            subtotal=Decimal('12.00'),
            delivery_fee_charged=Decimal('2.50'),
            total_amount=Decimal('14.50'),
            status='pending',
            payment_status=payment_status
        )
        OrderItem.objects.create(
            order=order,
            food_item=self.food_item,
            quantity=1,
            price=Decimal('12.00')
        )
        return order

    def test_full_delivery_lifecycle_and_history_logging(self):
        # 1. Customer creates order
        self.client.force_authenticate(user=self.customer)
        res_create = self.client.post('/api/orders/', {
            'restaurant': self.restaurant.id,
            'address': self.address.id,
            'items': [{'id': self.food_item.id, 'quantity': 1}]
        }, format='json')
        self.assertEqual(res_create.status_code, status.HTTP_201_CREATED)
        order_id = res_create.data['id']
        order = Order.objects.get(id=order_id)
        self.assertEqual(order.status, 'pending')
        self.assertIsNotNone(order.estimated_delivery_time)

        # Check initial OrderStatusHistory
        history = list(order.status_history.all())
        self.assertEqual(len(history), 1)
        self.assertEqual(history[0].to_status, 'pending')
        self.assertEqual(history[0].actor, self.customer)
        self.assertEqual(history[0].actor_role, 'customer')

        # 2. Restaurant accepts order
        self.client.force_authenticate(user=self.restaurant_owner)
        res_accept = self.client.post(f'/api/orders/{order_id}/restaurant-accept/')
        self.assertEqual(res_accept.status_code, status.HTTP_200_OK)
        order.refresh_from_db()
        self.assertEqual(order.status, 'confirmed')

        # 3. Restaurant starts preparing
        res_prep = self.client.post(f'/api/orders/{order_id}/start-preparing/')
        self.assertEqual(res_prep.status_code, status.HTTP_200_OK)
        order.refresh_from_db()
        self.assertEqual(order.status, 'preparing')

        # 4. Restaurant marks ready for pickup
        res_ready = self.client.post(f'/api/orders/{order_id}/ready-for-pickup/')
        self.assertEqual(res_ready.status_code, status.HTTP_200_OK)
        order.refresh_from_db()
        self.assertEqual(order.status, 'ready_for_pickup')
        self.assertIsNotNone(order.ready_at)

        # 5. Driver accepts delivery
        self.client.force_authenticate(user=self.driver_user1)
        res_driver_accept = self.client.post(f'/api/drivers/orders/{order_id}/accept/')
        self.assertEqual(res_driver_accept.status_code, status.HTTP_200_OK)

        # 6. Driver arrives at restaurant
        res_arr_rest = self.client.post(f'/api/drivers/orders/{order_id}/arrive-restaurant/')
        self.assertEqual(res_arr_rest.status_code, status.HTTP_200_OK)

        # 7. Driver picks up order
        res_pickup = self.client.post(f'/api/drivers/orders/{order_id}/pickup/')
        self.assertEqual(res_pickup.status_code, status.HTTP_200_OK)
        order.refresh_from_db()
        self.assertEqual(order.status, 'on_the_way')
        self.assertIsNotNone(order.picked_up_at)

        # 8. Driver arrives at customer
        res_arr_cust = self.client.post(f'/api/drivers/orders/{order_id}/arrive-customer/')
        self.assertEqual(res_arr_cust.status_code, status.HTTP_200_OK)
        order.refresh_from_db()
        self.assertEqual(order.status, 'driver_arrived')

        # 9. Driver delivers order (COD collection)
        res_deliver = self.client.post(f'/api/drivers/orders/{order_id}/deliver/', {'payment_collected': True})
        self.assertEqual(res_deliver.status_code, status.HTTP_200_OK)
        order.refresh_from_db()
        self.assertEqual(order.status, 'delivered')
        self.assertEqual(order.payment_status, 'PAID')
        self.assertIsNotNone(order.delivered_at)

        # Verify driver earnings were credited
        self.driver1.refresh_from_db()
        self.assertEqual(self.driver1.total_deliveries, 1)
        self.assertEqual(self.driver1.total_earnings, Decimal('2.50'))

        # Verify full audit history trail
        all_history = list(order.status_history.order_by('created_at'))
        statuses_logged = [h.to_status for h in all_history]
        self.assertIn('pending', statuses_logged)
        self.assertIn('confirmed', statuses_logged)
        self.assertIn('preparing', statuses_logged)
        self.assertIn('ready_for_pickup', statuses_logged)
        self.assertIn('on_the_way', statuses_logged)
        self.assertIn('driver_arrived', statuses_logged)
        self.assertIn('delivered', statuses_logged)

    def test_driver_concurrency_anti_collision(self):
        order = self._create_order()
        # Driver 1 accepts order
        self.client.force_authenticate(user=self.driver_user1)
        res1 = self.client.post(f'/api/drivers/orders/{order.id}/accept/')
        self.assertEqual(res1.status_code, status.HTTP_200_OK)

        # Driver 2 attempts to accept the same order
        self.client.force_authenticate(user=self.driver_user2)
        res2 = self.client.post(f'/api/drivers/orders/{order.id}/accept/')
        self.assertEqual(res2.status_code, status.HTTP_409_CONFLICT)
        self.assertIn('already been accepted by another driver', res2.data['error'])

    def test_restaurant_reject_and_refund(self):
        order = self._create_order(payment_status='PAID')
        payment = Payment.objects.create(
            order=order,
            provider='ABA',
            method='KHQR',
            amount=Decimal('14.50'),
            currency='USD',
            status='PAID',
            merchant_reference='REF-REJECT-001'
        )

        self.client.force_authenticate(user=self.restaurant_owner)
        res = self.client.post(f'/api/orders/{order.id}/restaurant-reject/', {
            'reason': 'Kitchen at full capacity'
        })
        self.assertEqual(res.status_code, status.HTTP_200_OK)

        order.refresh_from_db()
        self.assertEqual(order.status, 'cancelled')
        self.assertEqual(order.payment_status, 'REFUNDED')

        payment.refresh_from_db()
        self.assertEqual(payment.status, 'REFUNDED')

        latest_history = order.status_history.last()
        self.assertEqual(latest_history.to_status, 'cancelled')
        self.assertEqual(latest_history.actor_role, 'restaurant')
        self.assertIn('Kitchen at full capacity', latest_history.notes)

    def test_customer_cancellation_safeguard(self):
        order = self._create_order()
        self.client.force_authenticate(user=self.customer)

        # Move order to preparing
        order.status = 'preparing'
        order.save(update_fields=['status'])

        # Customer attempts to cancel order while preparing
        res_cancel = self.client.post(f'/api/orders/{order.id}/cancel/', {
            'reason': 'Changed mind'
        })
        self.assertEqual(res_cancel.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('Cannot cancel order in "preparing" status', res_cancel.data['detail'])

        order.refresh_from_db()
        self.assertEqual(order.status, 'preparing')

    def test_failed_delivery_workflow(self):
        order = self._create_order()
        Delivery.objects.create(order=order, driver=self.driver1, status='on_the_way')
        order.status = 'on_the_way'
        order.save(update_fields=['status'])

        self.client.force_authenticate(user=self.driver_user1)
        res_fail = self.client.post(f'/api/drivers/orders/{order.id}/failed-delivery/', {
            'reason': 'Customer phone switched off and gate locked'
        })
        self.assertEqual(res_fail.status_code, status.HTTP_200_OK)

        order.refresh_from_db()
        self.assertEqual(order.status, 'failed_delivery')
        self.assertEqual(order.delivery.status, 'failed_delivery')

        latest_history = order.status_history.last()
        self.assertEqual(latest_history.to_status, 'failed_delivery')
        self.assertIn('Customer phone switched off', latest_history.notes)

    def test_admin_driver_management_and_reassignment(self):
        self.client.force_authenticate(user=self.admin_user)

        # 1. Admin suspends driver 2
        res_suspend = self.client.post(f'/api/admin/drivers/{self.driver2.id}/suspend/')
        self.assertEqual(res_suspend.status_code, status.HTTP_200_OK)
        self.driver2.refresh_from_db()
        self.assertFalse(self.driver2.is_approved)
        self.assertFalse(self.driver2.is_online)

        # 2. Admin approves driver 2 back
        res_approve = self.client.post(f'/api/admin/drivers/{self.driver2.id}/approve/')
        self.assertEqual(res_approve.status_code, status.HTTP_200_OK)
        self.driver2.refresh_from_db()
        self.assertTrue(self.driver2.is_approved)

        # 3. Admin reassigns order from driver 1 to driver 2
        order = self._create_order()
        Delivery.objects.create(order=order, driver=self.driver1, status='assigned')

        res_reassign = self.client.post(f'/api/admin/orders/{order.id}/reassign_driver/', {
            'driver_id': self.driver2.id,
            'reason': 'Driver 1 reported vehicle breakdown'
        })
        self.assertEqual(res_reassign.status_code, status.HTTP_200_OK)
        order.refresh_from_db()
        self.assertEqual(order.delivery.driver, self.driver2)


class WebSocketAsyncAccessTests(TransactionTestCase):
    def test_database_sync_to_async_order_access(self):
        from asgiref.sync import async_to_sync
        from core.consumers import check_order_access

        customer = User.objects.create_user(
            username='ws_cust_async',
            email='ws_cust@foodgo.kh',
            password='Password123!',
            role='customer'
        )
        owner = User.objects.create_user(
            username='ws_owner_async',
            email='ws_owner@foodgo.kh',
            password='Password123!',
            role='restaurant_owner'
        )
        restaurant = Restaurant.objects.create(
            owner=owner,
            name='Async Delights',
            address='Pub Street',
            phone='012345678',
            delivery_fee=Decimal('1.50')
        )
        order = Order.objects.create(
            customer=customer,
            restaurant=restaurant,
            total_amount=Decimal('15.00'),
            status='on_the_way'
        )

        can_connect, is_assigned = async_to_sync(check_order_access)(order.id, customer)
        self.assertTrue(can_connect)
        self.assertFalse(is_assigned)


class DriverAutoTrackingAndPickupTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.customer = User.objects.create_user(
            username='track_cust',
            email='track_cust@foodgo.kh',
            password='Password123!',
            role='customer',
        )
        self.owner = User.objects.create_user(
            username='track_owner',
            email='track_owner@foodgo.kh',
            password='Password123!',
            role='restaurant_owner',
        )
        self.restaurant = Restaurant.objects.create(
            owner=self.owner,
            name='AutoTrack Kitchen',
            address='St 240, Phnom Penh',
            phone='023888999',
            lat=Decimal('11.556400'),
            lng=Decimal('104.928200'),
            delivery_fee=Decimal('2.00'),
        )
        self.category = FoodCategory.objects.create(
            restaurant=self.restaurant,
            name='Mains',
        )
        self.food_item = FoodItem.objects.create(
            category=self.category,
            name='Amok Fish',
            price=Decimal('6.50'),
            is_available=True,
        )
        self.address = Address.objects.create(
            user=self.customer,
            street='Street 271, Boeng Tumpun',
            city='Phnom Penh',
            lat=Decimal('11.562100'),
            lng=Decimal('104.916000'),
        )

    def _make_driver(self, username, is_online=True, is_approved=True, lat=None, lng=None):
        user = User.objects.create_user(
            username=username,
            email=f'{username}@foodgo.kh',
            password='Password123!',
            role='driver',
        )
        return Driver.objects.create(
            user=user,
            vehicle_type='Motorcycle',
            license_plate=f'PP-{username[:4].upper()}',
            is_online=is_online,
            is_approved=is_approved,
            current_lat=Decimal(str(lat)) if lat is not None else None,
            current_lng=Decimal(str(lng)) if lng is not None else None,
        )

    def test_auto_assign_picks_nearest_online_approved_driver_when_not_picked(self):
        self._make_driver('unapproved_d', is_online=True, is_approved=False, lat='11.556400', lng='104.928200')
        self._make_driver('offline_d', is_online=False, is_approved=True, lat='11.556400', lng='104.928200')
        self._make_driver('far_d', is_online=True, is_approved=True, lat='11.610000', lng='104.880000')
        near_driver = self._make_driver('near_d', is_online=True, is_approved=True, lat='11.556900', lng='104.928500')

        self.client.force_authenticate(user=self.customer)
        res = self.client.post('/api/orders/', {
            'restaurant': self.restaurant.id,
            'address': self.address.id,
            'items': [{'food_item': self.food_item.id, 'quantity': 1}],
        }, format='json')
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertIsNotNone(res.data['assigned_driver'])
        self.assertEqual(res.data['assigned_driver']['id'], near_driver.id)
        self.assertFalse(res.data['assigned_driver']['is_picked_up'])

    def test_track_pre_pickup_vs_picked_up_and_unassigned_behavior(self):
        # Create an unrelated driver in DB to prove track() does not invent Driver.objects.first()
        self._make_driver('unrelated_d', is_online=True, is_approved=True)
        order = Order.objects.create(
            customer=self.customer,
            restaurant=self.restaurant,
            address=self.address,
            total_amount=Decimal('8.50'),
            status='preparing',
        )

        self.client.force_authenticate(user=self.customer)
        res_unassigned = self.client.get(f'/api/orders/{order.id}/track/')
        self.assertEqual(res_unassigned.status_code, status.HTTP_200_OK)
        self.assertFalse(res_unassigned.data['driver_assigned'])
        self.assertFalse(res_unassigned.data['is_picked_up'])
        self.assertEqual(res_unassigned.data['tracking_stage'], 'awaiting_driver')
        self.assertIsNone(res_unassigned.data['driver'])
        self.assertIsNone(res_unassigned.data['driver_location'])

        # Assign driver with no GPS reported yet while still pre-pickup
        assigned_driver = self._make_driver('assigned_d', is_online=True, is_approved=True)
        Delivery.objects.create(order=order, driver=assigned_driver, status='assigned')

        res_pre_pickup = self.client.get(f'/api/orders/{order.id}/track/')
        self.assertEqual(res_pre_pickup.status_code, status.HTTP_200_OK)
        self.assertTrue(res_pre_pickup.data['driver_assigned'])
        self.assertFalse(res_pre_pickup.data['is_picked_up'])
        self.assertEqual(res_pre_pickup.data['tracking_stage'], 'en_route_to_restaurant')
        # Must NOT jump to 45% midpoint along customer route
        expected_mid_lng = round(104.9282 + (104.9160 - 104.9282) * 0.45, 6)
        self.assertNotAlmostEqual(res_pre_pickup.data['driver_location']['lng'], expected_mid_lng, places=4)

        # Driver arrives at restaurant (still not picked up) -> then picks up food
        self.client.force_authenticate(user=assigned_driver.user)
        arrive_res = self.client.post(f'/api/drivers/orders/{order.id}/arrive-restaurant/')
        self.assertEqual(arrive_res.status_code, status.HTTP_200_OK)

        self.client.force_authenticate(user=self.customer)
        res_at_rest = self.client.get(f'/api/orders/{order.id}/track/')
        self.assertFalse(res_at_rest.data['is_picked_up'])
        self.assertEqual(res_at_rest.data['tracking_stage'], 'at_restaurant')
        self.assertAlmostEqual(res_at_rest.data['driver_location']['lat'], 11.5564, places=4)

        self.client.force_authenticate(user=assigned_driver.user)
        pickup_res = self.client.post(f'/api/drivers/orders/{order.id}/pickup/')
        self.assertEqual(pickup_res.status_code, status.HTTP_200_OK)

        self.client.force_authenticate(user=self.customer)
        res_picked = self.client.get(f'/api/orders/{order.id}/track/')
        self.assertTrue(res_picked.data['is_picked_up'])
        self.assertEqual(res_picked.data['tracking_stage'], 'on_the_way')
        self.assertIsNotNone(res_picked.data['picked_up_at'])

    def test_driver_location_endpoint_syncs_db_and_reports_active_orders(self):
        driver = self._make_driver('gps_d', is_online=True, is_approved=True)
        order = Order.objects.create(
            customer=self.customer,
            restaurant=self.restaurant,
            address=self.address,
            total_amount=Decimal('10.00'),
            status='picked_up',
        )
        Delivery.objects.create(order=order, driver=driver, status='picked_up')

        self.client.force_authenticate(user=driver.user)
        loc_res = self.client.post('/api/drivers/location/', {
            'lat': 11.5591,
            'lng': 104.9225,
            'speed': 33.5,
            'bearing': 72.0,
        }, format='json')
        self.assertEqual(loc_res.status_code, status.HTTP_200_OK)
        self.assertEqual(loc_res.data['active_orders_updated'], 1)
        self.assertIn('last_location_update', loc_res.data)

        self.client.force_authenticate(user=self.customer)
        track_res = self.client.get(f'/api/orders/{order.id}/track/')
        self.assertEqual(track_res.status_code, status.HTTP_200_OK)
        self.assertAlmostEqual(track_res.data['driver_location']['lat'], 11.5591, places=4)
        self.assertAlmostEqual(track_res.data['driver_location']['lng'], 104.9225, places=4)


