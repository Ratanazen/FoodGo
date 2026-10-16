from decimal import Decimal
from django.test import TestCase
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient
from core.models import (
    User, Address, RestaurantCategory, Restaurant, FoodCategory,
    FoodItem, Order, OrderItem, Coupon, Notification, Favorite
)

class FoodGoV4FeatureTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.customer = User.objects.create_user(
            username='khmer_foodie',
            email='foodie@foodgo.kh',
            password='Password123!',
            role='customer',
            phone='+85512999888'
        )
        self.restaurant_owner = User.objects.create_user(
            username='chef_dara',
            email='dara@foodgo.kh',
            password='Password123!',
            role='restaurant_owner'
        )
        self.category = RestaurantCategory.objects.create(name='Khmer Cuisine')
        self.restaurant = Restaurant.objects.create(
            owner=self.restaurant_owner,
            name='Kravanh Restaurant',
            category=self.category,
            address='Street 240, Phnom Penh',
            phone='+85523111222',
            delivery_fee=Decimal('1.50'),
            is_active=True
        )
        self.food_cat = FoodCategory.objects.create(restaurant=self.restaurant, name='Main Dishes')
        self.food_item = FoodItem.objects.create(
            category=self.food_cat,
            name='Beef Lok Lak',
            price=Decimal('7.00'),
            is_available=True,
            is_spicy=True
        )

    def test_notification_flow(self):
        self.client.force_authenticate(user=self.customer)
        notif1 = Notification.objects.create(
            user=self.customer,
            title='Order Prepared',
            message='Your Beef Lok Lak is hot and ready!',
            notification_type='order'
        )
        notif2 = Notification.objects.create(
            user=self.customer,
            title='Promo Voucher',
            message='Get 20% off with FOODGO20',
            notification_type='promo'
        )

        # 1. Unread count
        res = self.client.get('/api/notifications/unread-count/')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['unread_count'], 2)

        # 2. Mark single as read
        res = self.client.patch(f'/api/notifications/{notif1.id}/read/')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        notif1.refresh_from_db()
        self.assertTrue(notif1.is_read)

        # 3. Mark all read
        res = self.client.post('/api/notifications/mark-all-read/')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(Notification.objects.filter(user=self.customer, is_read=False).count(), 0)

    def test_favorite_toggle_and_check(self):
        self.client.force_authenticate(user=self.customer)

        # Check initial: false
        res = self.client.get(f'/api/favorites/check/?restaurant_id={self.restaurant.id}')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertFalse(res.data['is_favorited'])

        # Toggle: adds to favorites
        res = self.client.post('/api/favorites/toggle/', {'restaurant': self.restaurant.id})
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertTrue(res.data['is_favorited'])

        # Check again: true
        res = self.client.get(f'/api/favorites/check/?restaurant_id={self.restaurant.id}')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertTrue(res.data['is_favorited'])

        # Toggle again: removes from favorites
        res = self.client.post('/api/favorites/toggle/', {'restaurant': self.restaurant.id})
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertFalse(res.data['is_favorited'])

    def test_coupon_validation(self):
        Coupon.objects.create(
            code='SPECIAL20',
            discount_percent=20,
            min_order_amount=Decimal('10.00'),
            max_discount_amount=Decimal('5.00'),
            is_active=True
        )

        # 1. Below min order amount
        res = self.client.post('/api/coupons/validate/', {'code': 'SPECIAL20', 'subtotal': '8.00'})
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertFalse(res.data['valid'])

        # 2. Valid with discount applied
        res = self.client.post('/api/coupons/validate/', {'code': 'SPECIAL20', 'subtotal': '20.00'})
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertTrue(res.data['valid'])
        self.assertEqual(res.data['discount_amount'], '4.00')

        # 3. Cap max discount
        res = self.client.post('/api/coupons/validate/', {'code': 'SPECIAL20', 'subtotal': '50.00'})
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['discount_amount'], '5.00')

    def test_order_cancel_and_reorder(self):
        self.client.force_authenticate(user=self.customer)
        order = Order.objects.create(
            customer=self.customer,
            restaurant=self.restaurant,
            total_amount=Decimal('8.50'),
            subtotal=Decimal('7.00'),
            delivery_fee_charged=Decimal('1.50'),
            status='pending'
        )
        OrderItem.objects.create(order=order, food_item=self.food_item, quantity=1, price=Decimal('7.00'))

        # Cancel order
        res = self.client.post(f'/api/orders/{order.id}/cancel/', {'reason': 'Changed mind'})
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        order.refresh_from_db()
        self.assertEqual(order.status, 'cancelled')
        self.assertEqual(order.cancellation_reason, 'Changed mind')
        self.assertIsNotNone(order.cancelled_at)

        # Reorder into cart
        res = self.client.post(f'/api/orders/{order.id}/reorder/')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['items_added'], 1)

    def test_auth_change_password(self):
        self.client.force_authenticate(user=self.customer)

        # Wrong old password
        res = self.client.post('/api/auth/change-password/', {
            'old_password': 'WrongPassword!',
            'new_password': 'NewPassword123!'
        })
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)

        # Correct old password
        res = self.client.post('/api/auth/change-password/', {
            'old_password': 'Password123!',
            'new_password': 'NewPassword123!'
        })
        self.assertEqual(res.status_code, status.HTTP_200_OK)

        # Check authentication with new password
        anon = APIClient()
        login_res = anon.post('/api/token/', {
            'username': 'khmer_foodie',
            'password': 'NewPassword123!'
        })
        self.assertEqual(login_res.status_code, status.HTTP_200_OK)
