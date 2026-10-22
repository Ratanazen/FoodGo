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


