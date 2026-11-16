from datetime import timedelta
from decimal import Decimal
from django.test import TestCase
from django.urls import reverse
from django.utils import timezone
from rest_framework.test import APIClient
from rest_framework import status
from core.models import User, Restaurant, Order, Delivery, Driver, DeliveryConfirmationToken
from core.serializers import OrderSerializer

class DeliveryConfirmationQRTests(TestCase):
    def setUp(self):
        self.client = APIClient()

        # Users
        self.customer = User.objects.create_user(
            username='alice_customer',
            email='alice@example.com',
            password='password123',
            role='customer'
        )
        self.other_customer = User.objects.create_user(
            username='eve_stranger',
            email='eve@example.com',
            password='password123',
            role='customer'
        )
        self.driver_user1 = User.objects.create_user(
            username='bob_driver',
            email='bob@example.com',
            password='password123',
            role='driver'
        )
        self.driver_user2 = User.objects.create_user(
            username='charlie_driver',
            email='charlie@example.com',
            password='password123',
            role='driver'
        )
        self.admin_user = User.objects.create_user(
            username='admin_staff',
            email='admin@example.com',
            password='password123',
            is_staff=True
        )

        # Drivers
        self.driver1 = Driver.objects.create(
            user=self.driver_user1,
            vehicle_type='Motorcycle (Honda Wave)',
            license_plate='PP-1AA-1234',
            is_online=True
        )
        self.driver2 = Driver.objects.create(
            user=self.driver_user2,
            vehicle_type='Motorcycle (Scoopy)',
            license_plate='PP-2BB-5678',
            is_online=True
        )

        # Restaurant & Order
        self.owner = User.objects.create_user(
            username='owner_rest',
            email='owner@example.com',
            password='password123',
            role='restaurant_owner'
        )
        self.restaurant = Restaurant.objects.create(
            owner=self.owner,
            name='Phnom Penh Kitchen',
            address='Street 240, Phnom Penh',
            phone='012345678'
        )

        self.order = Order.objects.create(
            customer=self.customer,
            restaurant=self.restaurant,
            total_amount=Decimal('18.50'),
            status='on_the_way',
            payment_status='UNPAID'
        )

        # Assign delivery to Driver 1
        self.delivery = Delivery.objects.create(
            order=self.order,
            driver=self.driver1,
            status='on_the_way'
        )

    def test_driver_can_generate_delivery_qr(self):
        """Assigned driver can generate QR token, 6-digit PIN, and delivery updates to 'arrived'."""
        self.client.force_authenticate(user=self.driver_user1)
        url = reverse('order-delivery-qr', args=[self.order.id])
        response = self.client.post(url, {}, format='json')

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('token', response.data)
        self.assertIn('verification_pin', response.data)
        self.assertIn('qr_payload', response.data)
        self.assertEqual(len(response.data['verification_pin']), 6)
        self.assertTrue(response.data['qr_payload'].startswith('FOODGO:DELIVERY:CONFIRM:v1'))
        self.assertIn(f"order_id={self.order.id}", response.data['qr_payload'])

        # Check Delivery status updated to 'arrived'
        self.delivery.refresh_from_db()
        self.assertEqual(self.delivery.status, 'arrived')

        # Check DB record
        token_obj = DeliveryConfirmationToken.objects.get(order=self.order)
        self.assertEqual(token_obj.driver, self.driver1)
        self.assertFalse(token_obj.is_used)
        self.assertTrue(token_obj.is_valid())

    def test_unassigned_driver_cannot_generate_delivery_qr(self):
        """Driver not assigned to this delivery cannot generate QR."""
        self.client.force_authenticate(user=self.driver_user2)
        url = reverse('order-delivery-qr', args=[self.order.id])
        response = self.client.post(url, {}, format='json')

        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_customer_cannot_generate_delivery_qr(self):
        """Customer cannot generate driver's delivery QR token."""
        self.client.force_authenticate(user=self.customer)
        url = reverse('order-delivery-qr', args=[self.order.id])
        response = self.client.post(url, {}, format='json')

        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_customer_confirms_delivery_via_qr_token(self):
        """Customer scans driver's QR code token, atomically confirms delivery and preserves payment status."""
        # 1. Driver generates QR
        self.client.force_authenticate(user=self.driver_user1)
        qr_resp = self.client.post(reverse('order-delivery-qr', args=[self.order.id]), {}, format='json')
        token = qr_resp.data['token']

        # 2. Customer confirms delivery
        self.client.force_authenticate(user=self.customer)
        url = reverse('order-confirm-delivery', args=[self.order.id])
        response = self.client.post(url, {'token': token}, format='json')

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['status'], 'SUCCESS')
        self.assertEqual(response.data['order_status'], 'delivered')
        self.assertIsNotNone(response.data['delivery_time'])

        # 3. Check Order and Delivery states in DB
        self.order.refresh_from_db()
        self.assertEqual(self.order.status, 'delivered')
        # CRITICAL: Payment status must be preserved (not altered to PAID)
        self.assertEqual(self.order.payment_status, 'UNPAID')

        self.delivery.refresh_from_db()
        self.assertEqual(self.delivery.status, 'delivered')
        self.assertIsNotNone(self.delivery.delivery_time)

        # 4. Check Token record
        token_obj = DeliveryConfirmationToken.objects.get(order=self.order)
        self.assertTrue(token_obj.is_used)
        self.assertIsNotNone(token_obj.used_at)
        self.assertEqual(token_obj.confirmed_by, self.customer)

    def test_customer_confirms_delivery_via_pin(self):
        """Customer enters 6-digit PIN fallback to confirm delivery."""
        self.client.force_authenticate(user=self.driver_user1)
        qr_resp = self.client.post(reverse('order-delivery-qr', args=[self.order.id]), {}, format='json')
        pin = qr_resp.data['verification_pin']

        self.client.force_authenticate(user=self.customer)
        url = reverse('order-confirm-delivery', args=[self.order.id])
        response = self.client.post(url, {'verification_pin': pin}, format='json')

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['status'], 'SUCCESS')

        self.order.refresh_from_db()
        self.assertEqual(self.order.status, 'delivered')

    def test_customer_confirms_delivery_via_full_qr_payload_string(self):
        """Customer scanner passes full QR URI payload string; backend parses and extracts token cleanly."""
        self.client.force_authenticate(user=self.driver_user1)
        qr_resp = self.client.post(reverse('order-delivery-qr', args=[self.order.id]), {}, format='json')
        qr_payload = qr_resp.data['qr_payload']

        self.client.force_authenticate(user=self.customer)
        url = reverse('order-confirm-delivery', args=[self.order.id])
        response = self.client.post(url, {'token': qr_payload}, format='json')

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['status'], 'SUCCESS')

    def test_unauthorized_customer_cannot_confirm_delivery(self):
        """User who does not own the order cannot confirm delivery."""
        self.client.force_authenticate(user=self.driver_user1)
        qr_resp = self.client.post(reverse('order-delivery-qr', args=[self.order.id]), {}, format='json')
        token = qr_resp.data['token']

        # Different user tries to confirm
        self.client.force_authenticate(user=self.other_customer)
        url = reverse('order-confirm-delivery', args=[self.order.id])
        response = self.client.post(url, {'token': token}, format='json')

        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
        self.order.refresh_from_db()
        self.assertEqual(self.order.status, 'on_the_way')

    def test_expired_token_rejected(self):
        """Expired delivery token cannot confirm order."""
        self.client.force_authenticate(user=self.driver_user1)
        qr_resp = self.client.post(reverse('order-delivery-qr', args=[self.order.id]), {}, format='json')
        token = qr_resp.data['token']

        # Force token to expired
        token_obj = DeliveryConfirmationToken.objects.get(token=token)
        token_obj.expires_at = timezone.now() - timedelta(minutes=5)
        token_obj.save()

        self.client.force_authenticate(user=self.customer)
        url = reverse('order-confirm-delivery', args=[self.order.id])
        response = self.client.post(url, {'token': token}, format='json')

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('expired', response.data['detail'].lower())
        self.order.refresh_from_db()
        self.assertNotEqual(self.order.status, 'delivered')

    def test_replay_attack_rejected(self):
        """Duplicate scan of already-used delivery token is handled cleanly."""
        self.client.force_authenticate(user=self.driver_user1)
        qr_resp = self.client.post(reverse('order-delivery-qr', args=[self.order.id]), {}, format='json')
        token = qr_resp.data['token']

        # First scan -> Success
        self.client.force_authenticate(user=self.customer)
        url = reverse('order-confirm-delivery', args=[self.order.id])
        resp1 = self.client.post(url, {'token': token}, format='json')
        self.assertEqual(resp1.status_code, status.HTTP_200_OK)

        # Second scan -> Already delivered idempotency
        resp2 = self.client.post(url, {'token': token}, format='json')
        self.assertEqual(resp2.status_code, status.HTTP_200_OK)
        self.assertEqual(resp2.data['status'], 'ALREADY_DELIVERED')

    def test_invalid_token_and_pin_rejected(self):
        """Submitting wrong token or PIN returns HTTP 400."""
        self.client.force_authenticate(user=self.driver_user1)
        self.client.post(reverse('order-delivery-qr', args=[self.order.id]), {}, format='json')

        self.client.force_authenticate(user=self.customer)
        url = reverse('order-confirm-delivery', args=[self.order.id])
        response = self.client.post(url, {'token': 'completely-wrong-token'}, format='json')

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('Invalid', response.data['detail'])

    def test_admin_support_confirm_delivery_override(self):
        """Staff/Admin can manually confirm delivery with reason fallback."""
        self.client.force_authenticate(user=self.driver_user1)
        self.client.post(reverse('order-delivery-qr', args=[self.order.id]), {}, format='json')

        self.client.force_authenticate(user=self.admin_user)
        url = reverse('order-support-confirm-delivery', args=[self.order.id])
        response = self.client.post(url, {'reason': 'Customer phone lost battery'}, format='json')

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['status'], 'SUCCESS')

        self.order.refresh_from_db()
        self.assertEqual(self.order.status, 'delivered')
        self.delivery.refresh_from_db()
        self.assertEqual(self.delivery.status, 'delivered')

        token_obj = DeliveryConfirmationToken.objects.get(order=self.order)
        self.assertTrue(token_obj.is_used)
        self.assertIn('Customer phone lost battery', token_obj.user_agent)

    def test_order_serializer_delivery_token_privacy(self):
        """Delivery token and PIN are NOT leaked to the customer in OrderSerializer."""
        self.client.force_authenticate(user=self.driver_user1)
        self.client.post(reverse('order-delivery-qr', args=[self.order.id]), {}, format='json')

        # Customer view
        class MockCustomerRequest:
            user = self.customer

        serializer_customer = OrderSerializer(self.order, context={'request': MockCustomerRequest()})
        token_info_cust = serializer_customer.data['delivery_token_info']
        self.assertIsNotNone(token_info_cust)
        self.assertTrue(token_info_cust['has_active_token'])
        # Secret token and PIN must NOT be in customer response
        self.assertNotIn('token', token_info_cust)
        self.assertNotIn('verification_pin', token_info_cust)

        # Driver view
        class MockDriverRequest:
            user = self.driver_user1

        serializer_driver = OrderSerializer(self.order, context={'request': MockDriverRequest()})
        token_info_driver = serializer_driver.data['delivery_token_info']
        self.assertIsNotNone(token_info_driver)
        # Driver CAN see token and PIN
        self.assertIn('token', token_info_driver)
        self.assertIn('verification_pin', token_info_driver)

    def test_order_reference_generation(self):
        """Order automatically generates a unique order reference formatted like FG-YYYYMMDD-XXXXXX."""
        self.order.refresh_from_db()
        self.assertIsNotNone(self.order.order_reference)
        self.assertTrue(self.order.order_reference.startswith('FG-'))
        self.assertEqual(len(self.order.order_reference), 18) # FG-YYYYMMDD-XXXXXX

    def test_driver_declares_arrival_endpoint(self):
        """Assigned driver can notify arrival via delivery_arrive action."""
        self.client.force_authenticate(user=self.driver_user1)
        url = reverse('order-delivery-arrive', args=[self.order.id])
        response = self.client.post(url, {}, format='json')

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['status'], 'SUCCESS')
        self.assertEqual(response.data['delivery_status'], 'arrived')
        self.assertEqual(response.data['order_status'], 'driver_arrived')

        self.order.refresh_from_db()
        self.assertEqual(self.order.status, 'driver_arrived')
        self.delivery.refresh_from_db()
        self.assertEqual(self.delivery.status, 'arrived')

    def test_dual_qr_flow_assigned_driver_can_confirm(self):
        """Assigned driver can submit customer QR token or PIN to confirm delivery in reverse flow."""
        # Generate token
        self.client.force_authenticate(user=self.driver_user1)
        qr_resp = self.client.post(reverse('order-delivery-qr', args=[self.order.id]), {}, format='json')
        token = qr_resp.data['token']

        # Driver confirms delivery (e.g. scanned from customer screen)
        url = reverse('order-confirm-delivery', args=[self.order.id])
        response = self.client.post(url, {'token': token}, format='json')

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['status'], 'SUCCESS')
        self.order.refresh_from_db()
        self.assertEqual(self.order.status, 'delivered')

    def test_direct_patch_status_delivered_prohibited(self):
        """Direct status transition to delivered via PATCH is prohibited and requires QR confirmation."""
        self.client.force_authenticate(user=self.customer)
        url = reverse('order-detail', args=[self.order.id])
        response = self.client.patch(url, {'status': 'delivered'}, format='json')

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('prohibited', str(response.data))

    def test_invalid_state_transition_rejected(self):
        """Invalid state machine transitions are rejected with HTTP 400."""
        self.order.status = 'cancelled'
        self.order.save()

        self.client.force_authenticate(user=self.customer)
        url = reverse('order-detail', args=[self.order.id])
        response = self.client.patch(url, {'status': 'preparing'}, format='json')

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_explicit_route_aliases(self):
        """Verify explicit route aliases like /delivery/arrive/ and /delivery/confirm/ work identically."""
        self.client.force_authenticate(user=self.driver_user1)
        arrive_url = reverse('order_delivery_arrive_alias', args=[self.order.id])
        resp_arrive = self.client.post(arrive_url, {}, format='json')
        self.assertEqual(resp_arrive.status_code, status.HTTP_200_OK)

        tracking_url = reverse('order_tracking_alias', args=[self.order.id])
        resp_track = self.client.get(tracking_url)
        self.assertEqual(resp_track.status_code, status.HTTP_200_OK)
        self.assertEqual(resp_track.data['order_id'], self.order.id)

    def test_customer_can_retrieve_customer_delivery_qr(self):
        """Customer who owns the order can retrieve their delivery confirmation QR and PIN."""
        self.client.force_authenticate(user=self.customer)
        url = reverse('order-customer-delivery-qr', args=[self.order.id])
        response = self.client.get(url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('token', response.data)
        self.assertIn('verification_pin', response.data)
        self.assertIn('qr_payload', response.data)
        self.assertEqual(len(response.data['verification_pin']), 6)
        self.assertTrue(response.data['qr_payload'].startswith('FOODGO:DELIVERY:CONFIRM:v1'))
        self.assertEqual(response.data['order_id'], self.order.id)

    def test_unauthorized_customer_cannot_retrieve_customer_delivery_qr(self):
        """A customer who does NOT own the order cannot retrieve its delivery QR."""
        self.client.force_authenticate(user=self.other_customer)
        url = reverse('order-customer-delivery-qr', args=[self.order.id])
        response = self.client.get(url)

        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_customer_can_retrieve_delivery_qr_for_pending_order(self):
        """Customer can retrieve delivery QR even if order is freshly pending or confirmed."""
        from core.models import Order
        pending_order = Order.objects.create(
            customer=self.customer,
            restaurant=self.restaurant,
            total_amount=Decimal('10.00'),
            status='pending',
            payment_status='PAID'
        )
        self.client.force_authenticate(user=self.customer)
        url = reverse('order-customer-delivery-qr', args=[pending_order.id])
        response = self.client.get(url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('token', response.data)
        self.assertIn('verification_pin', response.data)


    def test_customer_can_regenerate_expired_delivery_qr(self):
        """Customer can rotate/regenerate delivery QR, invalidating previous token."""
        self.client.force_authenticate(user=self.customer)
        # 1. Retrieve initial token
        url = reverse('order-customer-delivery-qr', args=[self.order.id])
        resp1 = self.client.get(url)
        old_token = resp1.data['token']

        # 2. Regenerate
        regen_url = reverse('order-customer-regenerate-delivery-qr', args=[self.order.id])
        resp2 = self.client.post(regen_url, {}, format='json')
        self.assertEqual(resp2.status_code, status.HTTP_200_OK)
        new_token = resp2.data['token']
        self.assertNotEqual(old_token, new_token)
        self.assertEqual(resp2.data['rotation_count'], 1)

        # 3. Old token cannot confirm delivery
        self.client.force_authenticate(user=self.driver_user1)
        confirm_url = reverse('order-confirm-delivery', args=[self.order.id])
        res_old = self.client.post(confirm_url, {'token': old_token}, format='json')
        self.assertEqual(res_old.status_code, status.HTTP_400_BAD_REQUEST)

        # 4. New token successfully confirms delivery
        res_new = self.client.post(confirm_url, {'token': new_token}, format='json')
        self.assertEqual(res_new.status_code, status.HTTP_200_OK)
        self.order.refresh_from_db()
        self.assertEqual(self.order.status, 'delivered')

    def test_driver_can_validate_customer_qr_before_confirming(self):
        """Assigned driver can pre-validate customer's QR before completing handover."""
        self.client.force_authenticate(user=self.customer)
        qr_resp = self.client.get(reverse('order-customer-delivery-qr', args=[self.order.id]))
        token = qr_resp.data['token']

        # Driver validates
        self.client.force_authenticate(user=self.driver_user1)
        val_url = reverse('order-driver-validate-qr', args=[self.order.id])
        resp = self.client.post(val_url, {'token': token}, format='json')

        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data['status'], 'VALID')

        # Order must still remain in transit until confirmation
        self.order.refresh_from_db()
        self.assertNotEqual(self.order.status, 'delivered')

    def test_unassigned_driver_cannot_validate_qr(self):
        """Unassigned driver is rejected when attempting to validate QR."""
        self.client.force_authenticate(user=self.customer)
        qr_resp = self.client.get(reverse('order-customer-delivery-qr', args=[self.order.id]))
        token = qr_resp.data['token']

        self.client.force_authenticate(user=self.driver_user2)
        val_url = reverse('order-driver-validate-qr', args=[self.order.id])
        resp = self.client.post(val_url, {'token': token}, format='json')

        self.assertEqual(resp.status_code, status.HTTP_403_FORBIDDEN)

    def test_driver_scans_and_confirms_customer_qr(self):
        """Primary flow: Customer displays QR, driver scans and confirms delivery atomically."""
        # 1. Customer retrieves delivery QR
        self.client.force_authenticate(user=self.customer)
        qr_resp = self.client.get(reverse('order-customer-delivery-qr', args=[self.order.id]))
        token = qr_resp.data['token']

        # 2. Driver scans customer QR
        self.client.force_authenticate(user=self.driver_user1)
        confirm_url = reverse('order-confirm-delivery', args=[self.order.id])
        confirm_resp = self.client.post(confirm_url, {'token': token}, format='json')

        self.assertEqual(confirm_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(confirm_resp.data['status'], 'SUCCESS')
        self.assertEqual(confirm_resp.data['order_status'], 'delivered')

        # Check DB states
        self.order.refresh_from_db()
        self.assertEqual(self.order.status, 'delivered')
        self.delivery.refresh_from_db()
        self.assertEqual(self.delivery.status, 'delivered')

        # Driver deliveries and earnings incremented
        self.driver1.refresh_from_db()
        self.assertEqual(self.driver1.total_deliveries, 1)

    def test_payment_qr_cannot_confirm_delivery(self):
        """Bakong payment QR or random string cannot be accepted as delivery confirmation QR."""
        self.client.force_authenticate(user=self.customer)
        self.client.get(reverse('order-customer-delivery-qr', args=[self.order.id]))

        self.client.force_authenticate(user=self.driver_user1)
        confirm_url = reverse('order-confirm-delivery', args=[self.order.id])
        # Try passing a Bakong KHQR payload or random payment string
        bakong_qr = "00020101021229300016aba.khqr@bakong520459995802KH5915PhnomPenhKitchen"
        resp = self.client.post(confirm_url, {'token': bakong_qr}, format='json')

        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)
        self.order.refresh_from_db()
        self.assertNotEqual(self.order.status, 'delivered')

    def test_delivery_qr_does_not_mark_order_paid(self):
        """Delivery confirmation via delivery QR does NOT alter payment status to PAID."""
        self.assertEqual(self.order.payment_status, 'UNPAID')

        self.client.force_authenticate(user=self.customer)
        qr_resp = self.client.get(reverse('order-customer-delivery-qr', args=[self.order.id]))
        token = qr_resp.data['token']

        self.client.force_authenticate(user=self.driver_user1)
        confirm_url = reverse('order-confirm-delivery', args=[self.order.id])
        resp = self.client.post(confirm_url, {'token': token}, format='json')

        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.order.refresh_from_db()
        self.assertEqual(self.order.status, 'delivered')
        # Crucial: Delivery confirmation strictly separates from payment
        self.assertEqual(self.order.payment_status, 'UNPAID')

    def test_driver_delivery_qr_regenerate_flag_rotates_token(self):
        """Passing regenerate=True to delivery_qr rotates the token and increments rotation_count."""
        self.client.force_authenticate(user=self.driver_user1)
        url = reverse('order-delivery-qr', args=[self.order.id])

        resp1 = self.client.post(url, {}, format='json')
        self.assertEqual(resp1.status_code, status.HTTP_200_OK)
        token1 = resp1.data['token']

        # Without regenerate=True, unexpired token is reused
        resp2 = self.client.post(url, {}, format='json')
        self.assertEqual(resp2.data['token'], token1)

        # With regenerate=True, a new token is generated and rotation_count increments
        resp3 = self.client.post(url, {'regenerate': True}, format='json')
        self.assertEqual(resp3.status_code, status.HTTP_200_OK)
        self.assertNotEqual(resp3.data['token'], token1)
        token_obj = DeliveryConfirmationToken.objects.get(order=self.order)
        self.assertEqual(token_obj.rotation_count, 1)


class EndToEndCustomerPaymentDriverMapFlowTests(TestCase):
    """
    Full multi-role lifecycle test:
    Customer Order -> Bakong KHQR Webhook & Wallet Payment -> Restaurant Prep
    -> Driver Accept & GPS Telemetry -> Live Map Tracking -> Customer QR/PIN Handover
    -> Delivered State & Driver Earnings.
    """

    def setUp(self):
        from core.models import Address, FoodCategory, FoodItem, Wallet

        self.client = APIClient()
        self.customer = User.objects.create_user(
            username='e2e_customer',
            email='e2e_cust@foodgo.kh',
            password='password123',
            role='customer',
            phone='+85512000111',
            phone_normalized='+85512000111',
            is_phone_verified=True,
        )
        self.owner = User.objects.create_user(
            username='e2e_owner',
            email='e2e_owner@foodgo.kh',
            password='password123',
            role='restaurant_owner',
        )
        self.driver_user = User.objects.create_user(
            username='e2e_driver',
            email='e2e_driver@foodgo.kh',
            password='password123',
            role='driver',
            phone='+85512999888',
            phone_normalized='+85512999888',
            is_phone_verified=True,
        )
        self.driver = Driver.objects.create(
            user=self.driver_user,
            vehicle_type='Motorcycle (Honda Wave 125i)',
            license_plate='PP-9E2E-2026',
            is_online=True,
            is_approved=True,
            current_lat=Decimal('11.555000'),
            current_lng=Decimal('104.920000'),
        )
        self.restaurant = Restaurant.objects.create(
            owner=self.owner,
            name='E2E Khmer Grill',
            address='Street 308, BKK1, Phnom Penh',
            phone='+855 12 345 678',
            delivery_fee=Decimal('1.50'),
            lat=Decimal('11.556400'),
            lng=Decimal('104.928200'),
            is_active=True,
        )
        self.category = FoodCategory.objects.create(
            restaurant=self.restaurant,
            name='Signature Bowls',
        )
        self.food = FoodItem.objects.create(
            category=self.category,
            name='Kampot Pepper Beef Bowl',
            price=Decimal('7.50'),
            is_available=True,
        )
        self.address = Address.objects.create(
            user=self.customer,
            street='Street 240, Daun Penh',
            city='Phnom Penh',
            state='Phnom Penh',
            zip_code='120207',
            lat=Decimal('11.564500'),
            lng=Decimal('104.932800'),
            is_default=True,
        )
        self.wallet = Wallet.objects.create(
            user=self.customer,
            balance=Decimal('100.00'),
        )

    def test_full_customer_khqr_payment_restaurant_driver_gps_map_and_qr_delivery(self):
        # 1. Customer places an order
        self.client.force_authenticate(user=self.customer)
        order_res = self.client.post(
            '/api/orders/',
            {
                'restaurant': self.restaurant.id,
                'address': self.address.id,
                'items': [{'food_item': self.food.id, 'quantity': 2}],
                'special_instructions': 'Call upon arrival at gate',
            },
            format='json',
        )
        self.assertEqual(order_res.status_code, status.HTTP_201_CREATED)
        order_id = order_res.data['id']
        expected_total = Decimal('16.50')  # (7.50 * 2) + 1.50 delivery fee
        self.assertEqual(Decimal(str(order_res.data['total_amount'])), expected_total)

        # 2. Customer generates Bakong KHQR payment & settles via callback
        pay_res = self.client.post(
            '/api/payments/create/',
            {'order_id': order_id, 'provider': 'BAKONG', 'currency': 'USD'},
            format='json',
        )
        self.assertEqual(pay_res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(pay_res.data['provider'], 'BAKONG')
        self.assertEqual(pay_res.data['method'], 'KHQR')
        self.assertEqual(pay_res.data['status'], 'PENDING')
        self.assertTrue(pay_res.data['qr_payload'].startswith('000201'))
        merchant_ref = pay_res.data['merchant_reference']

        cb_res = self.client.post(
            '/api/payments/bakong/callback/',
            {
                'merchant_reference': merchant_ref,
                'amount': '16.50',
                'currency': 'USD',
                'transaction_id': 'BKG-E2E-TXN-001',
                'status': 'PAID',
            },
            format='json',
        )
        self.assertEqual(cb_res.status_code, status.HTTP_200_OK)

        order_obj = Order.objects.get(id=order_id)
        self.assertEqual(order_obj.payment_status, 'PAID')
        self.assertEqual(order_obj.status, 'confirmed')

        # 3. Restaurant accepts, prepares, and marks ready
        self.client.force_authenticate(user=self.owner)
        self.assertEqual(
            self.client.post(f'/api/orders/{order_id}/restaurant-accept/', {}, format='json').status_code,
            status.HTTP_200_OK,
        )
        self.assertEqual(
            self.client.post(f'/api/orders/{order_id}/start-preparing/', {}, format='json').status_code,
            status.HTTP_200_OK,
        )
        self.assertEqual(
            self.client.post(f'/api/orders/{order_id}/ready-for-pickup/', {}, format='json').status_code,
            status.HTTP_200_OK,
        )

        # 4. Auto-assigned online driver sees the ready-for-pickup ticket in active-deliveries,
        # accepts it, arrives at restaurant, picks up, and broadcasts GPS telemetry
        self.client.force_authenticate(user=self.driver_user)
        active_res = self.client.get('/api/drivers/active-deliveries/')
        self.assertEqual(active_res.status_code, status.HTTP_200_OK)
        self.assertTrue(any(o['id'] == order_id for o in active_res.data))

        self.assertEqual(
            self.client.post(f'/api/drivers/orders/{order_id}/accept/', {}, format='json').status_code,
            status.HTTP_200_OK,
        )
        self.assertEqual(
            self.client.post(f'/api/drivers/orders/{order_id}/arrive-restaurant/', {}, format='json').status_code,
            status.HTTP_200_OK,
        )
        self.assertEqual(
            self.client.post(f'/api/drivers/orders/{order_id}/pickup/', {}, format='json').status_code,
            status.HTTP_200_OK,
        )

        loc_res = self.client.post(
            '/api/drivers/location/',
            {'lat': 11.5592, 'lng': 104.9255, 'speed': 32.5, 'bearing': 68.0},
            format='json',
        )
        self.assertEqual(loc_res.status_code, status.HTTP_200_OK)
        self.assertEqual(loc_res.data['active_orders_updated'], 1)

        # 5. Customer fetches live Map tracking data and verifies driver GPS + route points
        self.client.force_authenticate(user=self.customer)
        track_res = self.client.get(f'/api/orders/{order_id}/track/')
        self.assertEqual(track_res.status_code, status.HTTP_200_OK)
        self.assertTrue(track_res.data['driver_assigned'])
        self.assertTrue(track_res.data['is_picked_up'])
        self.assertEqual(track_res.data['tracking_stage'], 'on_the_way')
        self.assertAlmostEqual(track_res.data['driver_location']['lat'], 11.5592, places=4)
        self.assertAlmostEqual(track_res.data['driver_location']['lng'], 104.9255, places=4)
        self.assertAlmostEqual(track_res.data['restaurant_location']['lat'], 11.5564, places=4)
        self.assertAlmostEqual(track_res.data['customer_location']['lat'], 11.5645, places=4)

        # 6. Driver arrives at customer -> Customer generates QR + PIN -> Driver confirms delivery
        self.client.force_authenticate(user=self.driver_user)
        self.assertEqual(
            self.client.post(f'/api/drivers/orders/{order_id}/arrive-customer/', {}, format='json').status_code,
            status.HTTP_200_OK,
        )

        self.client.force_authenticate(user=self.customer)
        qr_res = self.client.post(f'/api/orders/{order_id}/customer_delivery_qr/', {}, format='json')
        self.assertEqual(qr_res.status_code, status.HTTP_200_OK)
        token = qr_res.data['token']
        self.assertEqual(len(qr_res.data['verification_pin']), 6)

        self.client.force_authenticate(user=self.driver_user)
        confirm_res = self.client.post(
            f'/api/orders/{order_id}/confirm_delivery/',
            {'token': token},
            format='json',
        )
        self.assertEqual(confirm_res.status_code, status.HTTP_200_OK)
        self.assertEqual(confirm_res.data['order_status'], 'delivered')

        # 7. Verify anti-replay idempotency, updated earnings, and delivered tracking map state
        replay_res = self.client.post(
            f'/api/orders/{order_id}/confirm_delivery/',
            {'token': token},
            format='json',
        )
        self.assertEqual(replay_res.status_code, status.HTTP_200_OK)
        self.assertEqual(replay_res.data['status'], 'ALREADY_DELIVERED')

        earnings_res = self.client.get('/api/drivers/earnings/')
        self.assertEqual(earnings_res.status_code, status.HTTP_200_OK)
        self.assertEqual(earnings_res.data['completed_trips'], 1)
        self.assertAlmostEqual(earnings_res.data['total_earnings_usd'], 1.50, places=2)

        final_track = self.client.get(f'/api/orders/{order_id}/track/')
        self.assertEqual(final_track.status_code, status.HTTP_200_OK)
        self.assertEqual(final_track.data['status'], 'delivered')

    def test_customer_wallet_order_deducts_balance_and_confirms(self):
        self.client.force_authenticate(user=self.customer)
        order_res = self.client.post(
            '/api/orders/',
            {
                'restaurant': self.restaurant.id,
                'address': self.address.id,
                'items': [{'food_item': self.food.id, 'quantity': 1}],
            },
            format='json',
        )
        self.assertEqual(order_res.status_code, status.HTTP_201_CREATED)
        order_id = order_res.data['id']

        pay_res = self.client.post(
            '/api/payments/create/',
            {'order_id': order_id, 'provider': 'WALLET', 'currency': 'USD'},
            format='json',
        )
        self.assertEqual(pay_res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(pay_res.data['status'], 'PAID')

        self.wallet.refresh_from_db()
        self.assertEqual(self.wallet.balance, Decimal('91.00'))  # 100 - (7.50 + 1.50)
        order_obj = Order.objects.get(id=order_id)
        self.assertEqual(order_obj.payment_status, 'PAID')
        self.assertEqual(order_obj.status, 'confirmed')

    def test_cod_order_with_picked_driver_and_driver_handover_confirmation(self):
        # 1. Customer places COD order and explicitly picks driver in Checkout
        self.client.force_authenticate(user=self.customer)
        order_res = self.client.post(
            '/api/orders/',
            {
                'restaurant': self.restaurant.id,
                'address': self.address.id,
                'driver_id': self.driver.id,
                'items': [{'food_item': self.food.id, 'quantity': 2}],
                'special_instructions': 'Call upon arrival COD',
            },
            format='json',
        )
        self.assertEqual(order_res.status_code, status.HTTP_201_CREATED)
        order_id = order_res.data['id']
        self.assertEqual(order_res.data['assigned_driver']['id'], self.driver.id)

        pay_res = self.client.post(
            '/api/payments/create/',
            {'order_id': order_id, 'provider': 'COD', 'currency': 'USD'},
            format='json',
        )
        self.assertEqual(pay_res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(pay_res.data['provider'], 'COD')
        self.assertEqual(pay_res.data['status'], 'PENDING')

        # Order stays confirmed / PENDING while delivery starts at 'assigned'
        order_detail = self.client.get(f'/api/orders/{order_id}/')
        self.assertEqual(order_detail.status_code, status.HTTP_200_OK)
        self.assertEqual(order_detail.data['status'], 'confirmed')
        self.assertEqual(order_detail.data['payment_status'], 'PENDING')
        self.assertEqual(order_detail.data['assigned_driver']['status'], 'assigned')

        # 2. Driver logs in and progresses the COD order through every dashboard step
        self.client.force_authenticate(user=self.driver_user)
        active_res = self.client.get('/api/drivers/active-deliveries/')
        self.assertEqual(active_res.status_code, status.HTTP_200_OK)
        active_ids = [o['id'] for o in active_res.data]
        self.assertIn(order_id, active_ids)

        arrive_rest = self.client.post(f'/api/drivers/orders/{order_id}/arrive-restaurant/')
        self.assertEqual(arrive_rest.status_code, status.HTTP_200_OK)
        active_after_arrive = self.client.get('/api/drivers/active-deliveries/')
        cod_card = next(o for o in active_after_arrive.data if o['id'] == order_id)
        self.assertEqual(cod_card['assigned_driver']['status'], 'arrived_at_restaurant')

        pickup_res = self.client.post(f'/api/drivers/orders/{order_id}/pickup/')
        self.assertEqual(pickup_res.status_code, status.HTTP_200_OK)
        arrive_cust = self.client.post(f'/api/drivers/orders/{order_id}/arrive-customer/')
        self.assertEqual(arrive_cust.status_code, status.HTTP_200_OK)

        # 3. Driver confirms COD cash collection & delivery handover
        deliver_res = self.client.post(
            f'/api/drivers/orders/{order_id}/deliver/',
            {'payment_collected': True},
            format='json',
        )
        self.assertEqual(deliver_res.status_code, status.HTTP_200_OK)

        order_obj = Order.objects.get(id=order_id)
        self.assertEqual(order_obj.status, 'delivered')
        self.assertEqual(order_obj.payment_status, 'PAID')
        self.driver.refresh_from_db()
        self.assertEqual(self.driver.total_deliveries, 1)
        self.assertEqual(self.driver.total_earnings, Decimal('1.50'))





