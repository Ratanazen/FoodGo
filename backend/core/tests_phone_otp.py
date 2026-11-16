import secrets
from decimal import Decimal
from unittest.mock import patch, MagicMock
from django.conf import settings
from django.test import TestCase, override_settings
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken

from .models import User, Driver, Restaurant, FoodItem, Order, Delivery, PhoneOTPChallenge
from .sms_service import (
    normalize_cambodia_phone,
    mask_phone,
    generate_secure_otp,
    generate_salt,
    hash_otp,
    verify_otp_hash,
    TestConsoleSMSProvider,
    SimoSMSProvider,
    WeUMSSMSProvider,
    get_sms_provider,
)


class CambodianPhoneNormalizationTests(TestCase):
    """
    Test suite for Cambodian mobile phone number normalization and validation.
    Verifies support for Smart, Cellcard, Metfone, Seatel, Cootel and E.164 formatting.
    """

    def test_normalize_local_cellcard_number(self):
        normalized, valid, err = normalize_cambodia_phone("012 345 678")
        self.assertTrue(valid)
        self.assertEqual(normalized, "+85512345678")
        self.assertIsNone(err)

    def test_normalize_local_smart_number(self):
        normalized, valid, err = normalize_cambodia_phone("010-987-654")
        self.assertTrue(valid)
        self.assertEqual(normalized, "+85510987654")

    def test_normalize_local_metfone_8digit_subscriber(self):
        normalized, valid, err = normalize_cambodia_phone("097 123 4567")
        self.assertTrue(valid)
        self.assertEqual(normalized, "+855971234567")

    def test_normalize_international_e164_with_plus(self):
        normalized, valid, err = normalize_cambodia_phone("+855 77 111 222")
        self.assertTrue(valid)
        self.assertEqual(normalized, "+85577111222")

    def test_normalize_international_without_plus(self):
        normalized, valid, err = normalize_cambodia_phone("855 81 222 333")
        self.assertTrue(valid)
        self.assertEqual(normalized, "+85581222333")

    def test_normalize_international_with_double_zero(self):
        normalized, valid, err = normalize_cambodia_phone("00855 86 444 555")
        self.assertTrue(valid)
        self.assertEqual(normalized, "+85586444555")

    def test_reject_invalid_prefix(self):
        normalized, valid, err = normalize_cambodia_phone("020 123 456")
        self.assertFalse(valid)
        self.assertIn("Unsupported Cambodian mobile operator prefix", err)

    def test_reject_foreign_phone_number(self):
        normalized, valid, err = normalize_cambodia_phone("+1 415 555 2671")
        self.assertFalse(valid)
        self.assertIn("Only Cambodian (+855) mobile phone numbers", err)

    def test_reject_too_short_phone_number(self):
        normalized, valid, err = normalize_cambodia_phone("012 34")
        self.assertFalse(valid)
        self.assertIn("Invalid Cambodian phone number length", err)

    def test_reject_empty_or_none(self):
        normalized, valid, err = normalize_cambodia_phone("")
        self.assertFalse(valid)
        self.assertEqual(err, "Phone number is required.")

        normalized, valid, err = normalize_cambodia_phone(None)
        self.assertFalse(valid)
        self.assertEqual(err, "Phone number is required.")

    def test_mask_phone(self):
        masked = mask_phone("+85512345678")
        self.assertEqual(masked, "+855 12 *** 678")

        masked_short = mask_phone("+855")
        self.assertEqual(masked_short, "+855")


class OTPCryptographyTests(TestCase):
    """
    Test suite for cryptographically secure OTP generation, salting,
    and HMAC-SHA256 hashing.
    """

    def test_generate_secure_otp_length_and_content(self):
        otp = generate_secure_otp(length=6)
        self.assertEqual(len(otp), 6)
        self.assertTrue(otp.isdigit())

        # Test CSPRNG distribution across multiple calls
        otps = {generate_secure_otp(length=6) for _ in range(50)}
        self.assertGreater(len(otps), 45)

    def test_generate_salt(self):
        salt1 = generate_salt()
        salt2 = generate_salt()
        self.assertNotEqual(salt1, salt2)
        self.assertEqual(len(salt1), 32)  # 16 bytes hex

    def test_salted_hmac_sha256_hashing_and_verification(self):
        otp = "741852"
        salt = generate_salt()
        hashed = hash_otp(otp, salt)

        # Hash must never equal plaintext OTP
        self.assertNotEqual(hashed, otp)
        self.assertEqual(len(hashed), 64)  # SHA-256 hex

        # Correct OTP verifies
        self.assertTrue(verify_otp_hash(otp, salt, hashed))

        # Incorrect OTP fails
        self.assertFalse(verify_otp_hash("123456", salt, hashed))

        # Altered salt fails
        wrong_salt = generate_salt()
        self.assertFalse(verify_otp_hash(otp, wrong_salt, hashed))

    def test_empty_verification_returns_false(self):
        self.assertFalse(verify_otp_hash("", "salt", "hash"))
        self.assertFalse(verify_otp_hash("123456", "", "hash"))
        self.assertFalse(verify_otp_hash("123456", "salt", ""))


@override_settings(SMS_PROVIDER='test', OTP_RESEND_COOLDOWN_SECONDS=60, OTP_EXPIRY_SECONDS=300, OTP_RATE_LIMIT_PER_HOUR=5)
class PhoneOTPEndpointsTests(TestCase):
    """
    Integration tests for /api/auth/phone/* endpoints.
    Verifies OTP dispatch, validation, anti-abuse, cooldowns, and status.
    """

    def setUp(self):
        TestConsoleSMSProvider.reset()
        self.client = APIClient()

        self.customer = User.objects.create_user(
            username='sopheak_customer',
            email='sopheak@foodgo.kh',
            password='Password123!',
            role='customer',
            phone='+855 12 888 999',
            is_phone_verified=False
        )

        self.verified_user = User.objects.create_user(
            username='verified_dara',
            email='dara@foodgo.kh',
            password='Password123!',
            role='customer',
            phone='+855 77 999 888',
            phone_normalized='+85577999888',
            is_phone_verified=True,
            phone_verified_at=timezone.now()
        )

    def test_send_otp_success_and_db_storage(self):
        self.client.force_authenticate(user=self.customer)
        res = self.client.post('/api/auth/phone/send-otp/', {
            'phone': '012 888 999',
            'purpose': 'customer_verification'
        })
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['status'], 'SUCCESS')
        self.assertEqual(res.data['phone_masked'], '+855 12 *** 999')
        self.assertEqual(res.data['cooldown_seconds'], 60)

        # Verify challenge in DB
        challenge = PhoneOTPChallenge.objects.filter(phone_normalized='+85512888999').first()
        self.assertIsNotNone(challenge)
        self.assertEqual(challenge.purpose, 'customer_verification')
        self.assertFalse(challenge.is_consumed)
        self.assertEqual(challenge.attempts, 0)

        # Plaintext OTP is NEVER stored in database
        latest_sent = TestConsoleSMSProvider.delivered_messages[-1]
        plain_otp = latest_sent['otp']
        self.assertNotEqual(challenge.hashed_otp, plain_otp)
        self.assertFalse(PhoneOTPChallenge.objects.filter(hashed_otp=plain_otp).exists())

    def test_send_otp_cooldown_enforcement(self):
        self.client.force_authenticate(user=self.customer)
        # First request succeeds
        res1 = self.client.post('/api/auth/phone/send-otp/', {'phone': '012 888 999'})
        self.assertEqual(res1.status_code, status.HTTP_200_OK)

        # Immediate second request triggers 429 Cooldown
        res2 = self.client.post('/api/auth/phone/send-otp/', {'phone': '012 888 999'})
        self.assertEqual(res2.status_code, status.HTTP_429_TOO_MANY_REQUESTS)
        self.assertIn('Please wait', res2.data['error'])
        self.assertGreater(res2.data['cooldown_seconds'], 0)

    def test_send_otp_hourly_rate_limit_lockout(self):
        now = timezone.now()
        # Seed 5 challenges within the last 30 minutes with cooldown already expired
        for i in range(5):
            past_time = now - timezone.timedelta(minutes=40 - i * 5)
            PhoneOTPChallenge.objects.create(
                phone_raw='012 555 444',
                phone_normalized='+85512555444',
                purpose='customer_verification',
                hashed_otp='dummyhash',
                salt='dummysalt',
                expires_at=past_time + timezone.timedelta(minutes=5),
                resend_available_at=past_time + timezone.timedelta(seconds=60),
                created_at=past_time
            )

        # 6th request within an hour must return 429 rate limit exceeded
        res = self.client.post('/api/auth/phone/send-otp/', {'phone': '012 555 444'})
        self.assertEqual(res.status_code, status.HTTP_429_TOO_MANY_REQUESTS)
        self.assertIn('Hourly OTP request limit exceeded', res.data['error'])

    def test_send_otp_rejects_already_verified_number_on_another_account(self):
        self.client.force_authenticate(user=self.customer)
        # Attempt to claim verified_dara's number
        res = self.client.post('/api/auth/phone/send-otp/', {
            'phone': '077 999 888',
            'purpose': 'customer_verification'
        })
        self.assertEqual(res.status_code, status.HTTP_409_CONFLICT)
        self.assertIn('already verified with another account', res.data['error'])

    def test_verify_otp_success_and_atomic_consumption(self):
        self.client.force_authenticate(user=self.customer)
        self.client.post('/api/auth/phone/send-otp/', {'phone': '012 888 999'})

        sent_otp = TestConsoleSMSProvider.delivered_messages[-1]['otp']

        # Verify OTP
        res = self.client.post('/api/auth/phone/verify-otp/', {
            'phone': '012 888 999',
            'otp': sent_otp
        })
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['status'], 'SUCCESS')
        self.assertTrue(res.data['is_phone_verified'])

        # User is updated
        self.customer.refresh_from_db()
        self.assertTrue(self.customer.is_phone_verified)
        self.assertEqual(self.customer.phone_normalized, '+85512888999')
        self.assertIsNotNone(self.customer.phone_verified_at)

        # Challenge is consumed
        challenge = PhoneOTPChallenge.objects.filter(phone_normalized='+85512888999').first()
        self.assertTrue(challenge.is_consumed)
        self.assertIsNotNone(challenge.consumed_at)

        # Replay attempt fails immediately
        replay_res = self.client.post('/api/auth/phone/verify-otp/', {
            'phone': '012 888 999',
            'otp': sent_otp
        })
        self.assertEqual(replay_res.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('No active verification request found', replay_res.data['error'])

    def test_verify_otp_invalid_code_decrements_attempts(self):
        self.client.force_authenticate(user=self.customer)
        self.client.post('/api/auth/phone/send-otp/', {'phone': '012 888 999'})

        # Submit wrong code
        res = self.client.post('/api/auth/phone/verify-otp/', {
            'phone': '012 888 999',
            'otp': '000000'
        })
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('Invalid verification code', res.data['error'])
        self.assertEqual(res.data['attempts_remaining'], 4)

        challenge = PhoneOTPChallenge.objects.filter(phone_normalized='+85512888999').first()
        self.assertEqual(challenge.attempts, 1)
        self.assertFalse(challenge.is_consumed)

    def test_verify_otp_max_attempts_lockout(self):
        self.client.force_authenticate(user=self.customer)
        self.client.post('/api/auth/phone/send-otp/', {'phone': '012 888 999'})

        # Fail 5 times
        for _ in range(5):
            self.client.post('/api/auth/phone/verify-otp/', {
                'phone': '012 888 999',
                'otp': '999999'
            })

        # 6th attempt is blocked with max attempts exceeded
        res = self.client.post('/api/auth/phone/verify-otp/', {
            'phone': '012 888 999',
            'otp': '999999'
        })
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('Maximum verification attempts exceeded', res.data['error'])

    def test_verify_otp_expired_challenge(self):
        # Create an expired challenge
        past = timezone.now() - timezone.timedelta(seconds=400)
        otp = "654321"
        salt = generate_salt()
        PhoneOTPChallenge.objects.create(
            user=self.customer,
            phone_raw='012 888 999',
            phone_normalized='+85512888999',
            purpose='customer_verification',
            hashed_otp=hash_otp(otp, salt),
            salt=salt,
            expires_at=past,
            resend_available_at=past
        )

        res = self.client.post('/api/auth/phone/verify-otp/', {
            'phone': '012 888 999',
            'otp': otp
        })
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('expired', res.data['error'])

    def test_phone_status_authenticated(self):
        self.client.force_authenticate(user=self.verified_user)
        res = self.client.get('/api/auth/phone/status/')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['phone'], '+85577999888')
        self.assertTrue(res.data['is_phone_verified'])
        self.assertEqual(res.data['role'], 'customer')

    def test_change_phone_workflow(self):
        self.client.force_authenticate(user=self.verified_user)

        # Cannot change to same number
        res_same = self.client.post('/api/auth/phone/change/', {'new_phone': '+855 77 999 888'})
        self.assertEqual(res_same.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('identical to your current phone number', res_same.data['error'])

        # Request change to new number
        res = self.client.post('/api/auth/phone/change/', {'new_phone': '015 333 444'})
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['status'], 'SUCCESS')

        sent_otp = TestConsoleSMSProvider.delivered_messages[-1]['otp']

        # Verify new number OTP
        verify_res = self.client.post('/api/auth/phone/verify-otp/', {
            'phone': '015 333 444',
            'otp': sent_otp,
            'purpose': 'phone_change'
        })
        self.assertEqual(verify_res.status_code, status.HTTP_200_OK)

        self.verified_user.refresh_from_db()
        self.assertEqual(self.verified_user.phone_normalized, '+85515333444')
        self.assertTrue(self.verified_user.is_phone_verified)

    def test_phone_login_creates_account_and_returns_jwt(self):
        phone = "098 765 432"
        # 1. Send OTP for phone_login
        res_send = self.client.post('/api/auth/phone/send-otp/', {
            'phone': phone,
            'purpose': 'phone_login'
        })
        self.assertEqual(res_send.status_code, status.HTTP_200_OK)

        sent_otp = TestConsoleSMSProvider.delivered_messages[-1]['otp']

        # 2. Verify OTP
        res_verify = self.client.post('/api/auth/phone/verify-otp/', {
            'phone': phone,
            'otp': sent_otp,
            'purpose': 'phone_login'
        })
        self.assertEqual(res_verify.status_code, status.HTTP_200_OK)
        self.assertIn('access', res_verify.data)
        self.assertIn('refresh', res_verify.data)
        self.assertEqual(res_verify.data['user']['phone'], '+85598765432')
        self.assertTrue(res_verify.data['user']['is_phone_verified'])


@override_settings(SMS_PROVIDER='test')
class DriverPhoneEnforcementTests(TestCase):
    """
    Test suite for Driver phone verification enforcement.
    Ensures drivers without verified Cambodian phone numbers are blocked
    from accepting delivery assignments (HTTP 403 Forbidden).
    """

    def setUp(self):
        TestConsoleSMSProvider.reset()
        self.client = APIClient()

        self.owner = User.objects.create_user(
            username='bayon_owner',
            email='owner@bayon.kh',
            password='Password123!',
            role='restaurant_owner'
        )
        self.restaurant = Restaurant.objects.create(
            owner=self.owner,
            name='Bayon Khmer Kitchen',
            address='St 240, Phnom Penh',
            phone='+85523999111',
            lat=Decimal('11.5564'),
            lng=Decimal('104.9282'),
            is_active=True
        )
        self.customer = User.objects.create_user(
            username='chann_cust',
            email='chann@foodgo.kh',
            password='Password123!',
            role='customer'
        )

        # Unverified Driver
        self.unverified_driver_user = User.objects.create_user(
            username='unverified_rider',
            email='unverified@foodgo.kh',
            password='Driver123!',
            role='driver',
            phone='+855 12 111 222',
            is_phone_verified=False
        )
        self.unverified_driver = Driver.objects.create(
            user=self.unverified_driver_user,
            vehicle_type='Honda Click',
            license_plate='PP-1AA-0001',
            is_online=True,
            is_approved=True
        )

        # Verified Driver
        self.verified_driver_user = User.objects.create_user(
            username='verified_rider',
            email='verified@foodgo.kh',
            password='Driver123!',
            role='driver',
            phone='+855 12 333 444',
            phone_normalized='+85512333444',
            is_phone_verified=True,
            phone_verified_at=timezone.now()
        )
        self.verified_driver = Driver.objects.create(
            user=self.verified_driver_user,
            vehicle_type='Yamaha Scoopy',
            license_plate='PP-1AA-0002',
            is_online=True,
            is_approved=True
        )

    def _create_order(self):
        order = Order.objects.create(
            customer=self.customer,
            restaurant=self.restaurant,
            status='confirmed',
            payment_status='PAID',
            total_amount=Decimal('8.50'),
            delivery_fee_charged=Decimal('2.00')
        )
        return order

    def test_unverified_driver_blocked_from_accepting_order(self):
        order = self._create_order()
        self.client.force_authenticate(user=self.unverified_driver_user)

        res = self.client.post(f'/api/drivers/orders/{order.id}/accept/')
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)
        self.assertIn('Verified Cambodian phone number required', res.data['error'])

        # Delivery assignment was not created
        self.assertFalse(Delivery.objects.filter(order=order, driver=self.unverified_driver).exists())

    def test_verified_driver_can_accept_order(self):
        order = self._create_order()
        self.client.force_authenticate(user=self.verified_driver_user)

        res = self.client.post(f'/api/drivers/orders/{order.id}/accept/')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['status'], 'SUCCESS')

        delivery = Delivery.objects.filter(order=order, driver=self.verified_driver).first()
        self.assertIsNotNone(delivery)
        self.assertEqual(delivery.status, 'accepted')

    def test_driver_phone_change_resets_verification_status(self):
        self.client.force_authenticate(user=self.verified_driver_user)
        self.assertTrue(self.verified_driver_user.is_phone_verified)

        # Update phone number via Driver profile endpoint
        res = self.client.patch('/api/drivers/me/', {
            'phone': '098 123 789'
        })
        self.assertEqual(res.status_code, status.HTTP_200_OK)

        self.verified_driver_user.refresh_from_db()
        self.assertFalse(self.verified_driver_user.is_phone_verified)
        self.assertIsNone(self.verified_driver_user.phone_verified_at)


class SMSProvidersIntegrationTests(TestCase):
    """
    Test suite for SMS Gateway provider adapters (SimoSMS and WeUMS).
    Mocks HTTP requests to verify API payloads and error handling.
    """

    @patch('requests.post')
    def test_simosms_provider_success(self, mock_post):
        mock_resp = MagicMock()
        mock_resp.status_code = 200
        mock_resp.json.return_value = {
            'CodeResult': '100',
            'SMSID': 'SIMO-SMS-987654321',
            'CountRegenerate': 0
        }
        mock_post.return_value = mock_resp

        with override_settings(SMS_API_KEY='test_api_key', SMS_API_SECRET='test_secret'):
            provider = SimoSMSProvider()
            success, msg_id, meta = provider.send_otp('+85512345678', '123456')

            self.assertTrue(success)
            self.assertEqual(msg_id, 'SIMO-SMS-987654321')
            self.assertEqual(meta['status'], 'DELIVERED')

            # Verify request payload
            call_kwargs = mock_post.call_args[1]
            payload = call_kwargs['json']
            self.assertEqual(payload['Phone'], '85512345678')
            self.assertIn('123456', payload['Content'])
            self.assertEqual(payload['SmsType'], 2)

    @patch('requests.post')
    def test_simosms_provider_error_mapping(self, mock_post):
        mock_resp = MagicMock()
        mock_resp.status_code = 200
        mock_resp.json.return_value = {'CodeResult': '103'}  # Insufficient balance
        mock_post.return_value = mock_resp

        with override_settings(SMS_API_KEY='test_key'):
            provider = SimoSMSProvider()
            success, msg_id, meta = provider.send_otp('+85512345678', '123456')

            self.assertFalse(success)
            self.assertEqual(meta['error'], 'Insufficient SMS account balance.')
            self.assertEqual(meta['code_result'], '103')

    @patch('requests.post')
    def test_weums_provider_success(self, mock_post):
        mock_resp = MagicMock()
        mock_resp.status_code = 201
        mock_resp.json.return_value = {'id': 'WEUMS-MSG-112233'}
        mock_post.return_value = mock_resp

        with override_settings(WEUMS_API_KEY='test_weums_key'):
            provider = WeUMSSMSProvider()
            success, msg_id, meta = provider.send_otp('+85512345678', '654321')

            self.assertTrue(success)
            self.assertEqual(msg_id, 'WEUMS-MSG-112233')
            self.assertEqual(meta['status'], 'ACCEPTED')


@override_settings(SMS_PROVIDER='test')
class StandardAuthRoutesTests(TestCase):
    """
    Test suite verifying Section 3 standard auth endpoints:
    POST /api/auth/otp/request
    POST /api/auth/otp/verify
    POST /api/auth/refresh
    GET  /api/auth/me
    POST /api/auth/logout
    """

    def setUp(self):
        TestConsoleSMSProvider.reset()
        self.client = APIClient()
        self.user = User.objects.create_user(
            username='auth_standard_user',
            email='auth_standard@foodgo.kh',
            password='TestPassword123!',
            role='customer',
            phone='+85512888999'
        )

    def test_standard_otp_request_endpoint(self):
        response = self.client.post('/api/auth/otp/request/', {
            'phone': '012 888 999',
            'purpose': 'customer_verification'
        })
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['status'], 'SUCCESS')
        self.assertIn('phone_masked', response.data)
        self.assertEqual(len(TestConsoleSMSProvider.delivered_messages), 1)

    def test_standard_otp_verify_endpoint(self):
        # 1. Request OTP
        self.client.post('/api/auth/otp/request/', {
            'phone': '012 888 999',
            'purpose': 'customer_verification'
        })
        sent_otp = TestConsoleSMSProvider.delivered_messages[0]['otp']

        # 2. Verify OTP
        response = self.client.post('/api/auth/otp/verify/', {
            'phone': '012 888 999',
            'otp': sent_otp,
            'purpose': 'customer_verification'
        })
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['status'], 'SUCCESS')
        self.assertTrue(response.data['is_phone_verified'])

        # Reload user
        self.user.refresh_from_db()
        self.assertTrue(self.user.is_phone_verified)
        self.assertEqual(self.user.phone_normalized, '+85512888999')

    def test_standard_auth_me_endpoint(self):
        self.client.force_authenticate(user=self.user)
        response = self.client.get('/api/auth/me/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['username'], 'auth_standard_user')
        self.assertEqual(response.data['email'], 'auth_standard@foodgo.kh')
        self.assertIn('is_phone_verified', response.data)
        self.assertIn('phone_normalized', response.data)

    def test_standard_token_refresh_endpoint(self):
        refresh = RefreshToken.for_user(self.user)
        response = self.client.post('/api/auth/refresh/', {
            'refresh': str(refresh)
        })
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('access', response.data)

    def test_standard_logout_endpoint(self):
        self.client.force_authenticate(user=self.user)
        refresh = RefreshToken.for_user(self.user)
        response = self.client.post('/api/auth/logout/', {
            'refresh': str(refresh)
        })
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_me_profile_update_and_phone_normalization(self):
        self.client.force_authenticate(user=self.user)
        patch_res = self.client.patch('/api/me/', {
            'first_name': 'NewFirst',
            'last_name': 'NewLast',
        })
        self.assertEqual(patch_res.status_code, status.HTTP_200_OK)
        self.assertEqual(patch_res.data['first_name'], 'NewFirst')
        self.assertEqual(patch_res.data['last_name'], 'NewLast')

        patch_res2 = self.client.patch('/api/me/', {
            'phone': '098 765 432',
        })
        self.assertEqual(patch_res2.status_code, status.HTTP_200_OK)
        self.assertEqual(patch_res2.data['phone_normalized'], '+85598765432')
        self.assertFalse(patch_res2.data['is_phone_verified'])

        patch_res3 = self.client.patch('/api/me/', {
            'phone': 'invalid_phone_123',
        })
        self.assertEqual(patch_res3.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('phone', patch_res3.data)

    def test_forgot_password_dispatches_real_phone_otp_challenge_and_rejects_invalid_phone(self):
        # Valid Cambodian mobile triggers real OTP challenge creation & SMS dispatch
        res = self.client.post('/api/forgot-password/', {
            'identifier': '012 888 999',
        })
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertIn('phone_masked', res.data)
        self.assertEqual(len(TestConsoleSMSProvider.delivered_messages), 1)
        challenge = PhoneOTPChallenge.objects.filter(
            phone_normalized='+85512888999',
            purpose='password_reset',
        ).first()
        self.assertIsNotNone(challenge)

        # Invalid phone-like identifier must return 400 rather than silently returning 200
        bad_res = self.client.post('/api/forgot-password/', {
            'identifier': '1234567',
        })
        self.assertEqual(bad_res.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('error', bad_res.data)

