from decimal import Decimal
from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient
from rest_framework import status
from core.models import (
    User, Restaurant, FoodCategory, FoodItem, Order, OrderItem,
    Cart, CartItem, Wallet, Review, Driver, Delivery, Notification
)
from core.tests_admin import AdminFeatureTestCase

class FoodGoCoreAPITests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.customer = User.objects.create_user(
            username='khmer_foodie',
            email='foodie@foodgo.kh',
            password='Password123!',
            role='customer'
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
        from asgiref.sync import async_to_sync
        from core.consumers import check_order_access

        order = Order.objects.create(
            customer=self.customer,
            restaurant=self.restaurant,
            total_amount=Decimal('20.00'),
            status='on_the_way'
        )
        other_user = User.objects.create_user('other_person', 'other@foodgo.kh', 'Pass123!')

        can_connect_customer, _ = async_to_sync(check_order_access)(order.id, self.customer)
        self.assertTrue(can_connect_customer)

        can_connect_other, _ = async_to_sync(check_order_access)(order.id, other_user)
        self.assertFalse(can_connect_other)

        staff_user = User.objects.create_superuser('boss', 'boss@foodgo.kh', 'Admin123!')
        can_connect_staff, _ = async_to_sync(check_order_access)(order.id, staff_user)
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



