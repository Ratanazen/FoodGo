import os
from unittest import mock
from decimal import Decimal
from django.core.exceptions import ImproperlyConfigured
from django.test import TestCase, TransactionTestCase
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

    def test_create_bakong_payment(self):
        url = reverse('payment_create')
        response = self.client.post(url, {'order_id': self.order.id, 'provider': 'BAKONG', 'currency': 'USD'}, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['provider'], 'BAKONG')
        self.assertEqual(response.data['method'], 'KHQR')
        self.assertEqual(response.data['status'], 'PENDING')
        self.assertTrue(response.data['qr_payload'].startswith('00020101'))
        self.assertTrue('FG-BK-' in response.data['merchant_reference'])
        self.assertEqual(len(response.data['provider_response']['md5']), 32)

    def test_bakong_callback_verification(self):
        create_res = self.client.post(reverse('payment_create'), {'order_id': self.order.id, 'provider': 'BAKONG', 'currency': 'USD'}, format='json')
        merchant_ref = create_res.data['merchant_reference']

        callback_url = reverse('payment_bakong_callback')
        callback_data = {
            'merchant_reference': merchant_ref,
            'amount': '15.50',
            'currency': 'USD',
            'transaction_id': 'BKG-TXN-REAL-998877',
            'status': 'PAID'
        }
        res = self.client.post(callback_url, callback_data, format='json')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.order.refresh_from_db()
        self.assertEqual(self.order.payment_status, 'PAID')
        self.assertEqual(self.order.status, 'confirmed')

    def test_payment_status_polling(self):
        create_res = self.client.post(reverse('payment_create'), {'order_id': self.order.id, 'provider': 'ABA', 'currency': 'USD'}, format='json')
        payment_id = create_res.data['id']

        status_url = reverse('payment_status', args=[payment_id])
        res = self.client.post(status_url, {}, format='json')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['id'], payment_id)
        self.assertEqual(res.data['status'], 'PENDING')

    def test_payment_status_permission_denied_for_other_user(self):
        create_res = self.client.post(reverse('payment_create'), {'order_id': self.order.id, 'provider': 'ABA', 'currency': 'USD'}, format='json')
        payment_id = create_res.data['id']

        other_user = User.objects.create_user(username='other_guy', email='other@test.com', password='password123', role='customer')
        self.client.force_authenticate(user=other_user)

        status_url = reverse('payment_status', args=[payment_id])
        res = self.client.post(status_url, {}, format='json')
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    def test_cancel_payment_success(self):
        create_res = self.client.post(reverse('payment_create'), {'order_id': self.order.id, 'provider': 'ABA', 'currency': 'USD'}, format='json')
        payment_id = create_res.data['id']

        cancel_url = reverse('payment_cancel', args=[payment_id])
        res = self.client.post(cancel_url, {}, format='json')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['payment']['status'], 'CANCELLED')

        payment = Payment.objects.get(id=payment_id)
        self.assertEqual(payment.status, 'CANCELLED')

    def test_cancel_wallet_payment_issues_automatic_refund(self):
        from core.models import Wallet
        wallet, _ = Wallet.objects.get_or_create(user=self.user)
        wallet.balance = Decimal('100.00')
        wallet.save()

        # 1. Pay via Wallet
        create_res = self.client.post(reverse('payment_create'), {'order_id': self.order.id, 'provider': 'WALLET', 'currency': 'USD'}, format='json')
        payment_id = create_res.data['id']
        wallet.refresh_from_db()
        self.assertEqual(wallet.balance, Decimal('84.50'))

        # 2. Cancel order payment -> triggers auto refund
        cancel_url = reverse('payment_cancel', args=[payment_id])
        res = self.client.post(cancel_url, {}, format='json')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['payment']['status'], 'REFUNDED')

        wallet.refresh_from_db()
        self.assertEqual(wallet.balance, Decimal('100.00')) # Fully refunded!

        self.order.refresh_from_db()
        self.assertEqual(self.order.status, 'cancelled')
        self.assertEqual(self.order.payment_status, 'REFUNDED')

    def test_admin_refund_endpoint(self):
        # 1. ABA payment made
        create_res = self.client.post(reverse('payment_create'), {'order_id': self.order.id, 'provider': 'ABA', 'currency': 'USD'}, format='json')
        payment_id = create_res.data['id']
        payment = Payment.objects.get(id=payment_id)
        payment.status = 'PAID'
        payment.save()

        # 2. Regular user cannot call refund endpoint
        refund_url = reverse('payment_refund', args=[payment_id])
        res_user = self.client.post(refund_url, {}, format='json')
        self.assertEqual(res_user.status_code, status.HTTP_403_FORBIDDEN)

        # 3. Staff user can call refund
        admin_user = User.objects.create_superuser(username='staffadmin', email='staff@test.com', password='adminpass123')
        self.client.force_authenticate(user=admin_user)
        res_admin = self.client.post(refund_url, {}, format='json')
        self.assertEqual(res_admin.status_code, status.HTTP_200_OK)
        self.assertEqual(res_admin.data['payment']['status'], 'REFUNDED')

    def test_order_destroy_active_order_rejected(self):
        self.order.status = 'preparing'
        self.order.save()
        res = self.client.delete(reverse('order-detail', args=[self.order.id]))
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('Cannot cancel or delete', str(res.data))

    def test_admin_dashboard_metrics(self):
        from core.admin import custom_admin_index
        from django.test import RequestFactory
        factory = RequestFactory()
        admin_user = User.objects.create_superuser(username='superboss', email='boss@test.com', password='adminpass123')
        req = factory.get('/admin/')
        req.user = admin_user
        extra_ctx = {}
        # custom_admin_index updates extra_ctx
        custom_admin_index(req, extra_context=extra_ctx)
        self.assertIn('total_revenue_khr', extra_ctx)
        self.assertIn('total_wallet_balance', extra_ctx)
        self.assertIn('recent_wallet_txns', extra_ctx)

    def test_server_side_coupon_discount_calculation(self):
        from core.models import Coupon, FoodItem, FoodCategory
        category = FoodCategory.objects.create(restaurant=self.restaurant, name='Fast Food')
        food = FoodItem.objects.create(category=category, name='Classic Burger', price=Decimal('20.00'), is_available=True)
        coupon = Coupon.objects.create(code='FOODGO20', discount_percent=20, is_active=True)

        url = reverse('order-list')
        order_data = {
            'restaurant': self.restaurant.id,
            'items': [{'food_item': food.id, 'quantity': 1}],
            'coupon_code': 'FOODGO20',
        }
        res = self.client.post(url, order_data, format='json')
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        # subtotal: 20.00, discount 20% = 4.00, delivery_fee = 0.00 -> total = 16.00
        expected_total = Decimal('16.00') + Decimal(str(self.restaurant.delivery_fee))
        self.assertEqual(Decimal(str(res.data['total_amount'])), expected_total)

    def test_create_payment_forbidden_for_other_user_order(self):
        other_user = User.objects.create_user(username='intruder', email='intruder@test.com', password='password123', role='customer')
        self.client.force_authenticate(user=other_user)

        url = reverse('payment_create')
        res = self.client.post(url, {'order_id': self.order.id, 'provider': 'ABA', 'currency': 'USD'}, format='json')
        self.assertEqual(res.status_code, status.HTTP_404_NOT_FOUND)

    def test_payment_expiration_transition(self):
        from datetime import timedelta
        create_res = self.client.post(reverse('payment_create'), {'order_id': self.order.id, 'provider': 'ABA', 'currency': 'USD'}, format='json')
        payment_id = create_res.data['id']
        payment = Payment.objects.get(id=payment_id)
        payment.expires_at = timezone.now() - timedelta(minutes=10)
        payment.save(update_fields=['expires_at'])

        status_url = reverse('payment_status', args=[payment_id])
        res = self.client.post(status_url, {}, format='json')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['status'], 'EXPIRED')
        payment.refresh_from_db()
        self.assertEqual(payment.status, 'EXPIRED')

    def test_webhook_unauthorized_with_wrong_secret(self):
        create_res = self.client.post(reverse('payment_create'), {'order_id': self.order.id, 'provider': 'ABA', 'currency': 'USD'}, format='json')
        merchant_ref = create_res.data['merchant_reference']

        callback_url = reverse('payment_aba_callback')
        callback_data = {
            'merchant_reference': merchant_ref,
            'amount': '15.50',
            'currency': 'USD',
            'transaction_id': 'ABA-TXN-FAKE-12345',
            'status': 'PAID'
        }
        # Anonymous client with strict non-testing/non-debug settings
        anon_client = APIClient()
        with self.settings(IS_TESTING=False, DEBUG=False), mock.patch.dict(os.environ, {'PAYMENT_WEBHOOK_SECRET': 'expected_secret_key'}):
            # Wrong secret header
            res = anon_client.post(
                callback_url,
                callback_data,
                format='json',
                HTTP_X_WEBHOOK_SECRET='invalid_wrong_secret'
            )
            self.assertEqual(res.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_webhook_missing_secret_in_production_raises_improperly_configured(self):
        callback_url = reverse('payment_aba_callback')
        callback_data = {
            'merchant_reference': 'FG-TEST-REF',
            'amount': '15.50',
            'currency': 'USD',
            'status': 'PAID'
        }
        anon_client = APIClient()
        with self.settings(IS_TESTING=False, DEBUG=False), mock.patch.dict(os.environ, {}, clear=True):
            with self.assertRaises(ImproperlyConfigured):
                anon_client.post(callback_url, callback_data, format='json')

    def test_emvco_khqr_crc16_validation(self):
        from core.payments.utils import crc16_ccitt, build_emvco_khqr
        # 1. Test crc16_ccitt mathematical correctness
        # Known test vector: "123456789" with CCITT (poly 0x1021, init 0xFFFF) -> 0x29B1
        self.assertEqual(crc16_ccitt("123456789"), "29B1")

        # 2. Test generated KHQR string format and checksum validity
        qr_str, md5_val = build_emvco_khqr(
            account_id="test_merchant_id",
            merchant_name="FoodGo Restaurant",
            merchant_city="Phnom Penh",
            merchant_ref="FG-TEST-REF-001",
            amount=Decimal("12.50"),
            currency="USD",
            acquiring_bank_guid="abaakhppxxx@abaa",
        )
        self.assertTrue(qr_str.startswith("000201010212"))
        self.assertTrue(qr_str.endswith(crc16_ccitt(qr_str[:-4])))
        self.assertEqual(len(md5_val), 32)

    def test_payment_creation_concurrency_update_or_create(self):
        url = reverse('payment_create')
        # First creation
        res1 = self.client.post(url, {'order_id': self.order.id, 'provider': 'ABA', 'currency': 'USD'}, format='json')
        self.assertEqual(res1.status_code, status.HTTP_201_CREATED)
        payment_id_1 = res1.data['id']

        # Second creation for same order updates existing payment record rather than duplicating
        res2 = self.client.post(url, {'order_id': self.order.id, 'provider': 'ACLEDA', 'currency': 'USD'}, format='json')
        self.assertEqual(res2.status_code, status.HTTP_201_CREATED)
        payment_id_2 = res2.data['id']

        self.assertEqual(payment_id_1, payment_id_2)
        payment = Payment.objects.get(order=self.order)
        self.assertEqual(payment.provider, 'ACLEDA')
        self.assertEqual(Payment.objects.filter(order=self.order).count(), 1)

    def test_payment_create_rejects_already_paid_order(self):
        self.order.payment_status = 'PAID'
        self.order.save(update_fields=['payment_status'])

        url = reverse('payment_create')
        res = self.client.post(url, {'order_id': self.order.id, 'provider': 'ABA', 'currency': 'USD'}, format='json')
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('already paid', res.data['detail'])

    def test_payment_serializer_includes_order_summary(self):
        from core.models import FoodCategory, FoodItem, OrderItem
        cat = FoodCategory.objects.create(restaurant=self.restaurant, name='Snacks')
        item = FoodItem.objects.create(category=cat, name='Spring Rolls', price=Decimal('5.50'), is_available=True)
        OrderItem.objects.create(order=self.order, food_item=item, quantity=2, price=Decimal('5.50'))

        create_res = self.client.post(reverse('payment_create'), {'order_id': self.order.id, 'provider': 'BAKONG', 'currency': 'USD'}, format='json')
        self.assertEqual(create_res.status_code, status.HTTP_201_CREATED)
        self.assertIn('order_summary', create_res.data)
        summary = create_res.data['order_summary']
        self.assertEqual(summary['restaurant'], self.restaurant.name)
        self.assertEqual(len(summary['items']), 1)
        self.assertEqual(summary['items'][0]['name'], 'Spring Rolls')

    def test_callback_currency_mismatch_rejected(self):
        create_res = self.client.post(reverse('payment_create'), {'order_id': self.order.id, 'provider': 'BAKONG', 'currency': 'USD'}, format='json')
        merchant_ref = create_res.data['merchant_reference']

        callback_url = reverse('payment_bakong_callback')
        bad_currency_data = {
            'merchant_reference': merchant_ref,
            'amount': '15.50',
            'currency': 'KHR',  # Mismatch! Order was USD
            'transaction_id': 'BKG-FAKE-123'
        }
        res = self.client.post(callback_url, bad_currency_data, format='json')
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)
        payment = Payment.objects.get(merchant_reference=merchant_ref)
        self.assertEqual(payment.status, 'PENDING')

class PaymentWebSocketConsumerTests(TransactionTestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(username='ws_user', email='ws@test.com', password='password123', role='customer')
        self.owner = User.objects.create_user(username='ws_owner', email='wsowner@test.com', password='password123', role='restaurant_owner')
        self.restaurant = Restaurant.objects.create(owner=self.owner, name='WS Rest', address='123 St', phone='012345678')
        self.order = Order.objects.create(customer=self.user, restaurant=self.restaurant, total_amount=Decimal('20.00'), status='pending', payment_status='UNPAID')
        self.client.force_authenticate(user=self.user)

    def test_payment_websocket_push_broadcast(self):
        import asyncio
        from core.consumers import PaymentConsumer
        from channels.testing import WebsocketCommunicator
        from asgiref.sync import sync_to_async

        create_res = self.client.post(reverse('payment_create'), {'order_id': self.order.id, 'provider': 'ABA', 'currency': 'USD'}, format='json')
        payment_id = create_res.data['id']
        merchant_ref = create_res.data['merchant_reference']

        async def run_ws_check():
            comm = WebsocketCommunicator(PaymentConsumer.as_asgi(), f'/ws/payments/{payment_id}/?token=simulator-token')
            connected, _ = await comm.connect()
            self.assertTrue(connected)

            # Receive initial snapshot
            initial_msg = await comm.receive_json_from()
            self.assertEqual(initial_msg['type'], 'payment_status_update')
            self.assertEqual(initial_msg['status'], 'PENDING')

            # Trigger callback confirming payment
            callback_data = {
                'merchant_reference': merchant_ref,
                'amount': '20.00',
                'currency': 'USD',
                'transaction_id': 'ABA-TXN-WS-TEST',
                'status': 'PAID'
            }
            await sync_to_async(self.client.post)(reverse('payment_aba_callback'), callback_data, format='json')

            # WebSocket should receive push notification with PAID status
            push_msg = await comm.receive_json_from()
            self.assertEqual(push_msg['type'], 'payment_status_update')
            self.assertEqual(push_msg['status'], 'PAID')

            await comm.disconnect()

        asyncio.run(run_ws_check())

    def test_client_status_forgery_rejected_pending_remains_pending(self):
        """Simulate=True or ?status=PAID on status endpoint is rejected; payment remains PENDING."""
        self.client.force_authenticate(user=self.user)
        create_res = self.client.post(reverse('payment_create'), {'order_id': self.order.id, 'provider': 'ABA', 'currency': 'USD'}, format='json')
        payment_id = create_res.data['id']
        self.assertEqual(create_res.data['status'], 'PENDING')

        status_url = reverse('payment_status', args=[payment_id])
        status_res = self.client.post(status_url, {'simulate': True, 'status': 'PAID'}, format='json')
        self.assertEqual(status_res.status_code, status.HTTP_200_OK)
        # Authoritative status check: pending remains pending!
        self.assertEqual(status_res.data['status'], 'PENDING')

        self.order.refresh_from_db()
        self.assertEqual(self.order.payment_status, 'PENDING')
        self.assertEqual(self.order.status, 'pending')

    def test_payment_methods_endpoint_public_metadata(self):
        """Payments methods endpoint returns public supported providers without secrets."""
        url = reverse('payment_methods')
        res = self.client.get(url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertTrue(isinstance(res.data, list))
        codes = [m['code'] for m in res.data]
        self.assertIn('BAKONG', codes)
        self.assertIn('ABA', codes)
        self.assertIn('ACLEDA', codes)
        self.assertIn('COD', codes)
        self.assertIn('WALLET', codes)
        # Ensure no secrets leak
        for m in res.data:
            self.assertNotIn('api_key', m)
            self.assertNotIn('api_secret', m)
            self.assertNotIn('api_token', m)
            self.assertNotIn('token', m)

    def test_get_payment_by_order_id(self):
        """Can retrieve payment bound to an order."""
        create_res = self.client.post(reverse('payment_create'), {'order_id': self.order.id, 'provider': 'BAKONG', 'currency': 'USD'}, format='json')
        payment_id = create_res.data['id']

        url = reverse('payment_by_order', args=[self.order.id])
        res = self.client.get(url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['id'], payment_id)
        self.assertEqual(res.data['provider'], 'BAKONG')

    def test_bakong_open_api_authoritative_verification(self):
        """Authoritative verification through NBC Bakong Open API check_transaction_by_md5."""
        create_res = self.client.post(reverse('payment_create'), {'order_id': self.order.id, 'provider': 'BAKONG', 'currency': 'USD'}, format='json')
        payment_id = create_res.data['id']
        payment = Payment.objects.get(id=payment_id)

        mock_resp = mock.MagicMock()
        mock_resp.status_code = 200
        mock_resp.json.return_value = {
            "responseCode": 0,
            "responseMessage": "Success",
            "data": {
                "hash": "BAKONG-HASH-ABC123456",
                "amount": "20.00",
                "currency": "USD",
                "toAccountId": "sonar_seang@bkrt"
            }
        }

        with mock.patch.dict(os.environ, {'BAKONG_API_TOKEN': 'mock_token'}), mock.patch('requests.post', return_value=mock_resp):
            status_url = reverse('payment_status', args=[payment_id])
            res = self.client.post(status_url, {}, format='json')
            self.assertEqual(res.status_code, status.HTTP_200_OK)
            self.assertEqual(res.data['status'], 'PAID')
            self.assertEqual(res.data['transaction_id'], 'BAKONG-HASH-ABC123456')

        self.order.refresh_from_db()
        self.assertEqual(self.order.payment_status, 'PAID')
        self.assertEqual(self.order.status, 'confirmed')

    def test_bakong_open_api_amount_mismatch_fails_verification(self):
        """If Bakong transaction amount does not match order amount, payment is not marked PAID."""
        create_res = self.client.post(reverse('payment_create'), {'order_id': self.order.id, 'provider': 'BAKONG', 'currency': 'USD'}, format='json')
        payment_id = create_res.data['id']

        mock_resp = mock.MagicMock()
        mock_resp.status_code = 200
        mock_resp.json.return_value = {
            "responseCode": 0,
            "data": {
                "hash": "BAKONG-TAMPERED-AMOUNT",
                "amount": "5.00", # Mismatch! Order is 20.00
                "currency": "USD",
            }
        }

        with mock.patch.dict(os.environ, {'BAKONG_API_TOKEN': 'mock_token'}), mock.patch('requests.post', return_value=mock_resp):
            status_url = reverse('payment_status', args=[payment_id])
            res = self.client.post(status_url, {}, format='json')
            self.assertEqual(res.status_code, status.HTTP_200_OK)
            self.assertNotEqual(res.data['status'], 'PAID')

        payment = Payment.objects.get(id=payment_id)
        self.assertNotEqual(payment.status, 'PAID')

    def test_driver_cannot_mark_bank_payment_paid(self):
        """A driver deliver button cannot mark an unpaid bank QR payment as PAID."""
        from core.models import Driver, Delivery
        driver_user = User.objects.create_user(username='driver_jack', password='password123', role='driver')
        driver = Driver.objects.create(user=driver_user, vehicle_type='Motorcycle', license_plate='PP-1234')
        delivery = Delivery.objects.create(order=self.order, driver=driver, status='on_the_way')

        # Create unpaid Bank QR payment
        create_res = self.client.post(reverse('payment_create'), {'order_id': self.order.id, 'provider': 'BAKONG', 'currency': 'USD'}, format='json')
        self.assertEqual(create_res.data['status'], 'PENDING')

        # Driver attempts to complete delivery with payment_collected=True
        driver_client = APIClient()
        driver_client.force_authenticate(user=driver_user)
        deliver_url = f'/api/drivers/orders/{self.order.id}/deliver/'
        res = driver_client.post(deliver_url, {'payment_collected': True}, format='json')
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('Bank QR payment has not been verified yet', res.data['error'])

        # Order must remain unpaid
        self.order.refresh_from_db()
        self.assertNotEqual(self.order.payment_status, 'PAID')

    def test_aba_and_acleda_universal_bakong_fallback_and_null_expires_safety(self):
        """ABA and ACLEDA providers safely handle expires_at=None and support universal Bakong Open API verification."""
        create_res = self.client.post(reverse('payment_create'), {'order_id': self.order.id, 'provider': 'ABA', 'currency': 'USD'}, format='json')
        payment_id = create_res.data['id']
        payment = Payment.objects.get(id=payment_id)
        payment.expires_at = None
        payment.save(update_fields=['expires_at'])

        # Status check with expires_at=None must not raise TypeError
        status_url = reverse('payment_status', args=[payment_id])
        res1 = self.client.get(status_url)
        self.assertEqual(res1.status_code, status.HTTP_200_OK)
        self.assertEqual(res1.data['status'], 'PENDING')

        # Universal Bakong Open API check confirms ABA KHQR payment when BAKONG_API_TOKEN is set
        mock_resp = mock.MagicMock()
        mock_resp.status_code = 200
        mock_resp.json.return_value = {
            "responseCode": 0,
            "data": {
                "hash": "BAKONG-ABA-UNIV-777",
                "amount": "20.00",
                "currency": "USD",
            }
        }
        with mock.patch.dict(os.environ, {'BAKONG_API_TOKEN': 'mock_token'}), mock.patch('requests.post', return_value=mock_resp):
            res2 = self.client.post(status_url, {}, format='json')
            self.assertEqual(res2.status_code, status.HTTP_200_OK)
            self.assertEqual(res2.data['status'], 'PAID')
            self.assertEqual(res2.data['transaction_id'], 'BAKONG-ABA-UNIV-777')

    def test_wallet_khqr_topup_and_verify_topup_via_bakong(self):
        """Wallet khqr_topup returns qr_payload/qr_image/md5 and verify_topup settles via Bakong Open API."""
        res_topup = self.client.post('/api/wallets/khqr_topup/', {'amount': '15.00', 'currency': 'USD'}, format='json')
        self.assertEqual(res_topup.status_code, status.HTTP_200_OK)
        self.assertIn('qr_payload', res_topup.data)
        self.assertIn('qr_image', res_topup.data)
        self.assertIn('md5', res_topup.data)
        merchant_ref = res_topup.data['merchant_reference']
        md5_val = res_topup.data['md5']

        # Before settlement, verify_topup returns PENDING
        res_pending = self.client.post('/api/wallets/verify_topup/', {'merchant_reference': merchant_ref}, format='json')
        self.assertEqual(res_pending.status_code, status.HTTP_200_OK)
        self.assertEqual(res_pending.data['status'], 'PENDING')

        # With Bakong Open API confirming MD5, verify_topup credits wallet idempotently
        mock_resp = mock.MagicMock()
        mock_resp.status_code = 200
        mock_resp.json.return_value = {
            "responseCode": 0,
            "data": {
                "hash": "BAKONG-TOPUP-HASH-001",
                "amount": "15.00",
                "currency": "USD",
            }
        }
        with mock.patch.dict(os.environ, {'BAKONG_API_TOKEN': 'mock_token'}), mock.patch('requests.post', return_value=mock_resp):
            res_credit = self.client.post('/api/wallets/verify_topup/', {
                'merchant_reference': merchant_ref,
                'md5': md5_val,
                'amount': '15.00',
                'currency': 'USD',
            }, format='json')
            self.assertEqual(res_credit.status_code, status.HTTP_200_OK)
            self.assertEqual(res_credit.data['status'], 'CREDITED')
            self.assertEqual(res_credit.data['new_balance'], '15.00')



