from unittest.mock import patch
from decimal import Decimal
from django.test import TestCase, override_settings
from django.urls import reverse
from django.contrib.auth import get_user_model
from django.core.cache import cache
from rest_framework.test import APIClient
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken

from core.models import (
    Restaurant,
    FoodCategory,
    FoodItem,
    Order,
    OrderItem,
    Address,
    Payment,
    Wallet,
    WalletTransaction,
    Delivery,
    Driver,
    DeliveryConfirmationToken,
    PhoneOTPChallenge,
)
from core.sms_service import TestConsoleSMSProvider

User = get_user_model()


@override_settings(SMS_PROVIDER='test', DEBUG=True)
class DualBackendHostingTests(TestCase):
    """
    Automated verification suite for FoodGo Dual-Backend Hosting:
    - Safe Health Probes (/health/live, /health/ready) with zero secret leakage
    - Origin host headers and cross-instance JWT authentication
    - Checkout idempotency (Idempotency-Key prevents duplicate orders)
    - Phone OTP single-use consumption and replay attack rejection
    - Payment webhook idempotency (order payments and wallet top-ups)
    - Delivery confirmation single-use token protection
    """

    def setUp(self):
        cache.clear()
        self.client = APIClient()

        # Create restaurant owner
        self.owner = User.objects.create_user(
            username='dual_owner',
            email='owner@foodgo.app',
            password='Password123!',
            role='restaurant',
        )

        # Create standard customer
        self.customer = User.objects.create_user(
            username='dual_customer',
            email='customer@foodgo.app',
            password='Password123!',
            phone='012888999',
            role='customer',
        )

        # Create restaurant and food item
        self.restaurant = Restaurant.objects.create(
            owner=self.owner,
            name='Dual Backend Cafe',
            address='Street 2004, Phnom Penh',
            phone='012345678',
        )
        self.category = FoodCategory.objects.create(
            restaurant=self.restaurant,
            name='Burgers',
        )
        self.food_item = FoodItem.objects.create(
            category=self.category,
            name='Cheeseburger',
            price=Decimal('5.50'),
        )

        # Create address
        self.address = Address.objects.create(
            user=self.customer,
            street='Street 2004',
            city='Phnom Penh',
            is_default=True,
        )

    def tearDown(self):
        cache.clear()

    # --------------------------------------------------------------------------
    # 1. Safe Health Probes (/health/live and /health/ready)
    # --------------------------------------------------------------------------
    def test_health_live_probe_returns_200(self):
        """Liveness probe must return 200 {'status': 'live'} without DB dependency."""
        for path in ['/health/live', '/health/live/', '/api/health/live/']:
            response = self.client.get(path)
            self.assertEqual(response.status_code, status.HTTP_200_OK)
            self.assertEqual(response.json(), {'status': 'live'})

    def test_health_ready_probe_returns_200_when_healthy(self):
        """Readiness probe must return 200 {'status': 'ready'} when database is responsive."""
        for path in ['/health/ready', '/health/ready/', '/api/health/ready/']:
            response = self.client.get(path)
            self.assertEqual(response.status_code, status.HTTP_200_OK)
            self.assertEqual(response.json(), {'status': 'ready'})

    def test_health_ready_probe_fails_safely_with_zero_leakage_when_db_down(self):
        """Readiness probe returns 503 {'status': 'unavailable'} on DB failure with zero secret leakage."""
        with patch('django.db.connection.cursor', side_effect=Exception('FATAL: password authentication failed')):
            response = self.client.get('/health/ready/')
            self.assertEqual(response.status_code, status.HTTP_503_SERVICE_UNAVAILABLE)
            data = response.json()
            self.assertEqual(data, {'status': 'unavailable'})
            # Ensure no credentials or DB error messages are exposed
            self.assertNotIn('password', str(data).lower())
            self.assertNotIn('fatal', str(data).lower())

    # --------------------------------------------------------------------------
    # 2. JWT Cross-Instance Authorization
    # --------------------------------------------------------------------------
    def test_cross_instance_jwt_token_validation(self):
        """JWT generated on Origin A can be authenticated on Origin B with shared SECRET_KEY."""
        refresh = RefreshToken.for_user(self.customer)
        access_token = str(refresh.access_token)

        # Authenticate using token
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {access_token}')
        response = self.client.get('/api/auth/me/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.json()['username'], 'dual_customer')

    # --------------------------------------------------------------------------
    # 3. Checkout Idempotency & Replay Protection
    # --------------------------------------------------------------------------
    def test_checkout_idempotency_prevents_duplicate_orders(self):
        """Submitting duplicate orders with identical Idempotency-Key returns cached order."""
        self.client.force_authenticate(user=self.customer)
        idempotency_key = 'order-checkout-uuid-998877'

        payload = {
            'restaurant': self.restaurant.id,
            'address': self.address.id,
            'total_amount': '11.00',
            'delivery_fee': '1.50',
            'status': 'pending',
            'payment_status': 'PENDING',
            'items': [
                {
                    'food_item': self.food_item.id,
                    'quantity': 2,
                    'unit_price': '5.50',
                }
            ],
        }

        # First request
        res1 = self.client.post(
            '/api/orders/',
            payload,
            format='json',
            HTTP_IDEMPOTENCY_KEY=idempotency_key,
        )
        self.assertEqual(res1.status_code, status.HTTP_201_CREATED)
        first_order_id = res1.json()['id']

        initial_order_count = Order.objects.filter(customer=self.customer).count()

        # Second request with identical Idempotency-Key header
        res2 = self.client.post(
            '/api/orders/',
            payload,
            format='json',
            HTTP_IDEMPOTENCY_KEY=idempotency_key,
        )
        self.assertEqual(res2.status_code, status.HTTP_200_OK)
        self.assertEqual(res2.json()['id'], first_order_id)

        # Confirm no duplicate order was created in database
        final_order_count = Order.objects.filter(customer=self.customer).count()
        self.assertEqual(initial_order_count, final_order_count)

    # --------------------------------------------------------------------------
    # 4. OTP Replay Prevention (Single-Use Verification)
    # --------------------------------------------------------------------------
    def test_otp_single_use_and_replay_rejection(self):
        """OTP can only be verified once. Subsequent attempts must be rejected."""
        phone = '012999888'

        # Request OTP
        req_res = self.client.post('/api/auth/phone/send-otp/', {'phone': phone, 'purpose': 'customer_verification'}, format='json')
        self.assertEqual(req_res.status_code, status.HTTP_200_OK)

        # Extract delivered OTP code from test provider
        self.assertTrue(len(TestConsoleSMSProvider.delivered_messages) > 0)
        otp_code = TestConsoleSMSProvider.delivered_messages[-1]['otp']

        # Verify OTP first time
        v1 = self.client.post(
            '/api/auth/phone/verify-otp/',
            {'phone': phone, 'otp': otp_code, 'purpose': 'customer_verification'},
            format='json',
        )
        self.assertEqual(v1.status_code, status.HTTP_200_OK)

        # Attempt to replay the same OTP a second time
        v2 = self.client.post(
            '/api/auth/phone/verify-otp/',
            {'phone': phone, 'otp': otp_code, 'purpose': 'customer_verification'},
            format='json',
        )
        self.assertEqual(v2.status_code, status.HTTP_400_BAD_REQUEST)

    # --------------------------------------------------------------------------
    # 5. Payment Webhook Callback Idempotency
    # --------------------------------------------------------------------------
    def test_order_payment_callback_idempotency(self):
        """Second payment callback for already-paid order returns 200 without duplicate execution."""
        order = Order.objects.create(
            customer=self.customer,
            restaurant=self.restaurant,
            address=self.address,
            total_amount=Decimal('15.00'),
            status='pending',
            payment_status='PENDING',
        )
        payment = Payment.objects.create(
            order=order,
            merchant_reference='ORDER-PAY-REF-1001',
            amount=Decimal('15.00'),
            currency='USD',
            method='KHQR',
            provider='BAKONG',
            status='PENDING',
        )

        with patch('core.payment_views.payment_service.get_provider') as mock_prov_getter:
            mock_provider = mock_prov_getter.return_value
            mock_provider.verify_payment.return_value = True
            mock_provider.handle_callback.return_value = {
                'transaction_id': 'TX-9988',
                'raw_response': {'status': 'SUCCESS'},
            }

            # First callback execution
            cb1 = self.client.post(
                '/api/payments/bakong/callback/',
                {'merchant_reference': 'ORDER-PAY-REF-1001'},
                format='json',
            )
            self.assertEqual(cb1.status_code, status.HTTP_200_OK)

            payment.refresh_from_db()
            self.assertEqual(payment.status, 'PAID')

            # Second identical callback
            cb2 = self.client.post(
                '/api/payments/bakong/callback/',
                {'merchant_reference': 'ORDER-PAY-REF-1001'},
                format='json',
            )
            self.assertEqual(cb2.status_code, status.HTTP_200_OK)
            self.assertIn('already processed', cb2.json().get('detail', '').lower())

    def test_wallet_topup_callback_idempotency(self):
        """Top-up callback with identical reference cannot credit user wallet twice."""
        wallet = Wallet.objects.create(user=self.customer, balance=Decimal('10.00'))
        ref = f'TOPUP-{self.customer.id}-UNIQUE998'

        # First topup callback
        cb1 = self.client.post(
            '/api/payments/bakong/callback/',
            {'merchant_reference': ref, 'amount': '25.00', 'currency': 'USD'},
            format='json',
        )
        self.assertEqual(cb1.status_code, status.HTTP_200_OK)
        wallet.refresh_from_db()
        self.assertEqual(wallet.balance, Decimal('35.00'))

        # Second duplicate callback
        cb2 = self.client.post(
            '/api/payments/bakong/callback/',
            {'merchant_reference': ref, 'amount': '25.00', 'currency': 'USD'},
            format='json',
        )
        self.assertEqual(cb2.status_code, status.HTTP_200_OK)
        self.assertIn('already processed', cb2.json().get('message', '').lower())

        # Confirm wallet balance was not credited twice
        wallet.refresh_from_db()
        self.assertEqual(wallet.balance, Decimal('35.00'))

    # --------------------------------------------------------------------------
    # 6. Delivery Confirmation Idempotency
    # --------------------------------------------------------------------------
    def test_delivery_confirmation_token_single_use(self):
        """Delivery confirmation token can only be consumed once."""
        order = Order.objects.create(
            customer=self.customer,
            restaurant=self.restaurant,
            address=self.address,
            total_amount=Decimal('12.00'),
            status='out_for_delivery',
            payment_status='PAID',
        )

        driver_user = User.objects.create_user(
            username='dual_driver',
            password='Password123!',
            role='driver',
        )
        driver = Driver.objects.create(
            user=driver_user,
            vehicle_type='motorbike',
            license_plate='1AB-9988',
        )
        Delivery.objects.create(
            order=order,
            driver=driver,
            status='on_the_way',
        )

        # 1. Driver generates delivery QR
        self.client.force_authenticate(user=driver_user)
        qr_resp = self.client.post(
            reverse('order-delivery-qr', args=[order.id]),
            {},
            format='json',
        )
        self.assertEqual(qr_resp.status_code, status.HTTP_200_OK)
        token = qr_resp.data['token']

        # 2. Customer confirms delivery first time
        self.client.force_authenticate(user=self.customer)
        url = reverse('order-confirm-delivery', args=[order.id])
        c1 = self.client.post(url, {'token': token}, format='json')
        self.assertEqual(c1.status_code, status.HTTP_200_OK)

        order.refresh_from_db()
        self.assertEqual(order.status, 'delivered')

        # 3. Second attempt with same token on already delivered order returns ALREADY_DELIVERED
        c2 = self.client.post(url, {'token': token}, format='json')
        self.assertEqual(c2.status_code, status.HTTP_200_OK)
        self.assertEqual(c2.data['status'], 'ALREADY_DELIVERED')

        # 4. Attempting to replay the used token on a second order is rejected
        order2 = Order.objects.create(
            customer=self.customer,
            restaurant=self.restaurant,
            address=self.address,
            total_amount=Decimal('8.00'),
            status='out_for_delivery',
            payment_status='PAID',
        )
        url2 = reverse('order-confirm-delivery', args=[order2.id])
        c3 = self.client.post(url2, {'token': token}, format='json')
        self.assertEqual(c3.status_code, status.HTTP_400_BAD_REQUEST)

    def test_mongo_health_check_endpoint(self):
        """
        Verify /api/health/mongodb/ and /health/mongodb/ return cluster connectivity status.
        """
        response = self.client.get(reverse('api_health_mongodb'))
        self.assertIn(response.status_code, [status.HTTP_200_OK, status.HTTP_503_SERVICE_UNAVAILABLE])
        self.assertIn('status', response.data)

    def test_mongo_image_upload_and_serve(self):
        """
        Verify image upload to MongoDB GridFS and subsequent retrieval.
        """
        import base64
        test_png_bytes = b'\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDRtest_png_binary'
        b64_str = base64.b64encode(test_png_bytes).decode('utf-8')

        from core.mongodb import get_mongo_client
        _client = get_mongo_client()
        _is_live = False
        if _client is not None:
            try:
                _client.admin.command('ping')
                _is_live = True
            except Exception:
                _is_live = False

        if not _is_live:
            from unittest.mock import patch
            mock_files = {}

            def fake_save(filename, file_data, content_type=None, metadata=None):
                mock_files[filename] = {
                    'id': 'mock_gridfs_id_999',
                    'filename': filename,
                    'content': file_data,
                    'content_type': content_type or 'image/png',
                    'metadata': metadata or {}
                }
                return 'mock_gridfs_id_999'

            def fake_get(filename_or_id):
                return mock_files.get(filename_or_id)

            with patch('core.mongodb.save_image_mongo', side_effect=fake_save), \
                 patch('core.mongodb.get_image_mongo', side_effect=fake_get):
                upload_url = reverse('mongo_image_upload')
                post_resp = self.client.post(upload_url, {
                    'image_base64': f'data:image/png;base64,{b64_str}',
                    'filename': 'unit_test_badge.png'
                }, format='json')
                self.assertEqual(post_resp.status_code, status.HTTP_201_CREATED)
                self.assertEqual(post_resp.data['status'], 'success')
                self.assertEqual(post_resp.data['filename'], 'unit_test_badge.png')
                self.assertTrue(post_resp.data['url'].startswith('/api/media/mongo/'))

                get_url = reverse('mongo_image_serve', kwargs={'filename': 'unit_test_badge.png'})
                get_resp = self.client.get(get_url)
                self.assertEqual(get_resp.status_code, status.HTTP_200_OK)
                self.assertEqual(get_resp.content, test_png_bytes)

                bad_url = reverse('mongo_image_serve', kwargs={'filename': 'nonexistent_file_xyz_123.jpg'})
                bad_resp = self.client.get(bad_url)
                self.assertEqual(bad_resp.status_code, status.HTTP_404_NOT_FOUND)
            return

        # 1. Upload via JSON base64
        upload_url = reverse('mongo_image_upload')
        post_resp = self.client.post(upload_url, {
            'image_base64': f'data:image/png;base64,{b64_str}',
            'filename': 'unit_test_badge.png'
        }, format='json')
        self.assertEqual(post_resp.status_code, status.HTTP_201_CREATED)
        self.assertEqual(post_resp.data['status'], 'success')
        self.assertEqual(post_resp.data['filename'], 'unit_test_badge.png')
        self.assertTrue(post_resp.data['url'].startswith('/api/media/mongo/'))

        # 2. Retrieve via GET /api/media/mongo/<filename>
        get_url = reverse('mongo_image_serve', kwargs={'filename': 'unit_test_badge.png'})
        get_resp = self.client.get(get_url)
        self.assertEqual(get_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(get_resp.content, test_png_bytes)

        # 3. Requesting nonexistent file returns 404
        bad_url = reverse('mongo_image_serve', kwargs={'filename': 'nonexistent_file_xyz_123.jpg'})
        bad_resp = self.client.get(bad_url)
        self.assertEqual(bad_resp.status_code, status.HTTP_404_NOT_FOUND)


    def test_mongo_sync_endpoint(self):
        """
        Verify POST /api/mongodb/sync/ mirrors data to MongoDB Atlas collections.
        """
        url = reverse('mongo_sync')
        resp = self.client.post(url, {}, format='json')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data['status'], 'success')
        self.assertIn('catalog_synced', resp.data)
        self.assertIn('orders_synced', resp.data)

