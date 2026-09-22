from decimal import Decimal
from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient
from rest_framework import status
from core.models import (
    User, Restaurant, FoodCategory, FoodItem, Order, OrderItem,
    Cart, CartItem, Wallet, Review
)

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
