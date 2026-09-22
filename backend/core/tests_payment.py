from decimal import Decimal
from django.test import TestCase
from django.urls import reverse
from django.utils import timezone
from rest_framework.test import APIClient
from rest_framework import status
from core.models import User, Restaurant, Order, Payment

class PaymentIntegrationTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(username='customer1', email='cust@test.com', password='password123', role='customer')
        self.owner = User.objects.create_user(username='owner1', email='owner@test.com', password='password123', role='restaurant_owner')
        self.restaurant = Restaurant.objects.create(owner=self.owner, name='Test Rest', address='123 St', phone='012345678')
        self.order = Order.objects.create(customer=self.user, restaurant=self.restaurant, total_amount=Decimal('15.50'), status='pending', payment_status='UNPAID')
        self.client.force_authenticate(user=self.user)

    def test_create_aba_payment(self):
        url = reverse('payment_create')
        response = self.client.post(url, {'order_id': self.order.id, 'provider': 'ABA', 'currency': 'USD'}, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['provider'], 'ABA')
        self.assertEqual(response.data['method'], 'KHQR')
        self.assertEqual(response.data['status'], 'PENDING')
        self.assertTrue(response.data['qr_payload'].startswith('00020101'))
        self.assertTrue('FG-ABA-' in response.data['merchant_reference'])

    def test_create_acleda_payment(self):
        url = reverse('payment_create')
        response = self.client.post(url, {'order_id': self.order.id, 'provider': 'ACLEDA', 'currency': 'USD'}, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['provider'], 'ACLEDA')
        self.assertEqual(response.data['method'], 'KHQR')
        self.assertTrue(response.data['qr_payload'].startswith('00020101'))

    def test_create_cod_payment(self):
        url = reverse('payment_create')
        response = self.client.post(url, {'order_id': self.order.id, 'provider': 'COD', 'currency': 'USD'}, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.order.refresh_from_db()
        self.assertEqual(self.order.status, 'confirmed') # COD orders confirm immediately
        self.assertEqual(self.order.payment_status, 'PENDING')

    def test_aba_callback_verification_and_idempotency(self):
        # 1. Create payment
        create_res = self.client.post(reverse('payment_create'), {'order_id': self.order.id, 'provider': 'ABA', 'currency': 'USD'}, format='json')
        merchant_ref = create_res.data['merchant_reference']

        # 2. Simulate webhook
        callback_url = reverse('payment_aba_callback')
        callback_data = {
            'merchant_reference': merchant_ref,
            'amount': '15.50',
            'currency': 'USD',
            'transaction_id': 'ABA-TXN-REAL-12345',
            'status': 'PAID'
        }
        res = self.client.post(callback_url, callback_data, format='json')
        self.assertEqual(res.status_code, status.HTTP_200_OK)

        self.order.refresh_from_db()
        payment = Payment.objects.get(merchant_reference=merchant_ref)
        self.assertEqual(payment.status, 'PAID')
        self.assertEqual(self.order.payment_status, 'PAID')
        self.assertEqual(self.order.status, 'confirmed')

        # 3. Idempotency test (same callback sent again)
        res_dup = self.client.post(callback_url, callback_data, format='json')
        self.assertEqual(res_dup.status_code, status.HTTP_200_OK)

    def test_callback_amount_mismatch_rejected(self):
        create_res = self.client.post(reverse('payment_create'), {'order_id': self.order.id, 'provider': 'ABA', 'currency': 'USD'}, format='json')
        merchant_ref = create_res.data['merchant_reference']

        callback_url = reverse('payment_aba_callback')
        bad_data = {
            'merchant_reference': merchant_ref,
            'amount': '5.00', # wrong amount!
            'currency': 'USD',
            'transaction_id': 'ABA-FAKE-123'
        }
        res = self.client.post(callback_url, bad_data, format='json')
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)
        payment = Payment.objects.get(merchant_reference=merchant_ref)
        self.assertEqual(payment.status, 'PENDING') # must remain PENDING

    def test_create_wallet_payment_success(self):
        from core.models import Wallet
        # Fund user's wallet
        wallet, _ = Wallet.objects.get_or_create(user=self.user)
        wallet.balance = Decimal('50.00')
        wallet.save()

        url = reverse('payment_create')
        response = self.client.post(url, {'order_id': self.order.id, 'provider': 'WALLET', 'currency': 'USD'}, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['provider'], 'WALLET')
        self.assertEqual(response.data['status'], 'PAID')

        self.order.refresh_from_db()
        self.assertEqual(self.order.payment_status, 'PAID')
        self.assertEqual(self.order.status, 'confirmed')

        wallet.refresh_from_db()
        self.assertEqual(wallet.balance, Decimal('34.50')) # 50.00 - 15.50

    def test_create_wallet_payment_insufficient_balance(self):
        from core.models import Wallet
        wallet, _ = Wallet.objects.get_or_create(user=self.user)
        wallet.balance = Decimal('5.00') # Not enough for 15.50 order
        wallet.save()

        url = reverse('payment_create')
        response = self.client.post(url, {'order_id': self.order.id, 'provider': 'WALLET', 'currency': 'USD'}, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('Insufficient', response.data['detail'])

    def test_wallet_top_up_and_khqr(self):
        # 1. Instant top up
        topup_url = reverse('wallet-top-up')
        res = self.client.post(topup_url, {'amount': '25.00'}, format='json')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(Decimal(str(res.data['balance'])), Decimal('25.00'))

        # 2. KHQR top up string generation
        khqr_url = reverse('wallet-khqr-topup')
        khqr_res = self.client.post(khqr_url, {'amount': '50.00'}, format='json')
        self.assertEqual(khqr_res.status_code, status.HTTP_200_OK)
        self.assertTrue(khqr_res.data['qr_payload'].startswith('00020101'))
        self.assertEqual(khqr_res.data['amount'], '50.00')

