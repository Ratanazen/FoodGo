import logging
import os
import sys
import time
from django.conf import settings
from django.core.exceptions import ImproperlyConfigured
from django.db import transaction
from django.utils import timezone
from rest_framework import status, permissions
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.generics import RetrieveAPIView
from .models import Order, Payment
from .serializers import PaymentSerializer
from .payments.service import payment_service
from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer

logger = logging.getLogger(__name__)

def broadcast_payment_status(payment):
    """
    Broadcasts real-time payment status transition to all connected WebSocket subscribers.
    """
    try:
        channel_layer = get_channel_layer()
        if channel_layer:
            async_to_sync(channel_layer.group_send)(
                f"payment_{payment.id}",
                {
                    "type": "payment_status_update",
                    "payment_id": payment.id,
                    "order_id": payment.order_id,
                    "status": payment.status,
                    "provider": payment.provider,
                    "amount": str(payment.amount),
                    "currency": payment.currency,
                    "transaction_id": payment.transaction_id,
                    "paid_at": payment.paid_at.isoformat() if payment.paid_at else None,
                }
            )
    except Exception as e:
        logger.warning(f"Failed to broadcast payment status over WebSocket: {e}")

class CreatePaymentView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        order_id = request.data.get('order_id')
        provider_name = request.data.get('provider', 'ABA').upper()
        currency = request.data.get('currency', 'USD').upper()

        if not order_id:
            return Response({'detail': 'order_id is required.'}, status=status.HTTP_400_BAD_REQUEST)

        with transaction.atomic():
            try:
                order = Order.objects.select_for_update().select_related('customer').get(id=order_id, customer=request.user)
            except Order.DoesNotExist:
                return Response({'detail': 'Order not found.'}, status=status.HTTP_404_NOT_FOUND)

            if order.payment_status == 'PAID':
                return Response({'detail': 'Order is already paid.'}, status=status.HTTP_400_BAD_REQUEST)

            if order.status == 'cancelled':
                return Response({'detail': 'Cannot create payment for a cancelled order.'}, status=status.HTTP_400_BAD_REQUEST)

            try:
                provider = payment_service.get_provider(provider_name)
                result = provider.create_payment(
                    order=order,
                    amount=order.total_amount,
                    currency=currency
                )
            except ValueError as e:
                return Response({'detail': str(e)}, status=status.HTTP_400_BAD_REQUEST)

            method = 'WALLET' if provider_name == 'WALLET' else ('COD' if provider_name == 'COD' else 'KHQR')
            payment_status = result.get('status', 'PENDING')

            # Atomically update existing payment or create fresh record without hard deleting audit history
            payment, _ = Payment.objects.update_or_create(
                order=order,
                defaults={
                    'provider': provider_name,
                    'method': method,
                    'merchant_reference': result['merchant_reference'],
                    'transaction_id': result.get('transaction_id'),
                    'amount': order.total_amount,
                    'currency': currency,
                    'qr_payload': result.get('qr_payload'),
                    'qr_image': result.get('qr_image'),
                    'expires_at': result.get('expires_at'),
                    'paid_at': result.get('paid_at'),
                    'provider_response': result.get('provider_response', {}),
                    'status': payment_status,
                }
            )

            if payment_status == 'PAID':
                order.payment_status = 'PAID'
                order.status = 'confirmed'
                order.save(update_fields=['payment_status', 'status'])
            elif provider_name == 'COD':
                order.payment_status = 'PENDING'
                order.status = 'confirmed' # COD can proceed according to COD workflow
                order.save(update_fields=['payment_status', 'status'])
            else:
                order.payment_status = 'PENDING'
                order.status = 'pending'
                order.save(update_fields=['payment_status', 'status'])

        broadcast_payment_status(payment)
        return Response(PaymentSerializer(payment).data, status=status.HTTP_201_CREATED)


class PaymentDetailView(RetrieveAPIView):
    queryset = Payment.objects.all()
    serializer_class = PaymentSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        if self.request.user.is_staff:
            return Payment.objects.all()
        return Payment.objects.filter(order__customer=self.request.user)


class PaymentStatusView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, pk):
        return self.post(request, pk)

    def post(self, request, pk):
        try:
            payment = Payment.objects.select_related('order').get(id=pk)
        except Payment.DoesNotExist:
            return Response({'detail': 'Payment not found.'}, status=status.HTTP_404_NOT_FOUND)

        if not request.user.is_staff and payment.order.customer != request.user:
            return Response({'detail': 'Permission denied.'}, status=status.HTTP_403_FORBIDDEN)

        # Check provider status or sandbox simulation
        payment_env = os.environ.get("PAYMENT_ENV", getattr(settings, "PAYMENT_ENV", "sandbox")).lower()
        is_simulate = (
            request.data.get('simulate') in (True, 'true', '1', 1) or
            request.query_params.get('simulate') in (True, 'true', '1', 1) or
            request.data.get('status') == 'PAID' or
            request.query_params.get('status') == 'PAID'
        )

        if is_simulate and (payment_env != "production" or request.user.is_staff or settings.DEBUG):
            status_info = {
                'status': 'PAID',
                'transaction_id': f'SIM-{payment.provider}-{int(time.time())}',
                'paid_at': timezone.now(),
                'raw_response': {'simulated': True, 'mode': 'sandbox'}
            }
        else:
            try:
                provider = payment_service.get_provider(payment.provider)
                status_info = provider.get_payment_status(payment)
            except Exception as e:
                return Response({'detail': str(e)}, status=status.HTTP_400_BAD_REQUEST)

        # Status transitions
        new_status = status_info.get('status')
        status_changed = False
        if new_status == 'PAID' and payment.status != 'PAID':
            with transaction.atomic():
                payment.status = 'PAID'
                payment.transaction_id = status_info.get('transaction_id') or payment.transaction_id
                payment.paid_at = status_info.get('paid_at') or timezone.now()
                if status_info.get('raw_response'):
                    payment.provider_response = status_info.get('raw_response')
                payment.save(update_fields=['status', 'transaction_id', 'paid_at', 'provider_response'])

                order = payment.order
                order.payment_status = 'PAID'
                order.status = 'confirmed'
                order.save(update_fields=['payment_status', 'status'])
                status_changed = True
        elif new_status == 'FAILED' and payment.status != 'FAILED':
            with transaction.atomic():
                payment.status = 'FAILED'
                payment.save(update_fields=['status'])
                order = payment.order
                if order.payment_status != 'PAID':
                    order.payment_status = 'FAILED'
                    order.save(update_fields=['payment_status'])
                status_changed = True
        elif new_status == 'EXPIRED' and payment.status == 'PENDING':
            with transaction.atomic():
                payment.status = 'EXPIRED'
                payment.save(update_fields=['status'])
                order = payment.order
                if order.payment_status != 'PAID':
                    order.payment_status = 'FAILED'
                    order.save(update_fields=['payment_status'])
                status_changed = True

        if status_changed:
            broadcast_payment_status(payment)

        return Response(PaymentSerializer(payment).data)


class CancelPaymentView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, pk):
        return self.post(request, pk)

    def delete(self, request, pk):
        return self.post(request, pk)

    def post(self, request, pk):
        try:
            payment = Payment.objects.select_related('order').get(id=pk)
        except Payment.DoesNotExist:
            return Response({'detail': 'Payment not found.'}, status=status.HTTP_404_NOT_FOUND)

        if not request.user.is_staff and payment.order.customer != request.user:
            return Response({'detail': 'Permission denied.'}, status=status.HTTP_403_FORBIDDEN)

        if payment.status in ('CANCELLED', 'REFUNDED'):
            return Response({'detail': f'Payment is already in {payment.status} status.'}, status=status.HTTP_400_BAD_REQUEST)

        with transaction.atomic():
            if payment.method == 'WALLET' and payment.status == 'PAID':
                provider = payment_service.get_provider('WALLET')
                provider.refund(payment)
                payment.status = 'REFUNDED'
            else:
                payment.status = 'CANCELLED'
            payment.save(update_fields=['status'])

            order = payment.order
            if order.status in ('pending', 'confirmed'):
                order.status = 'cancelled'
                order.payment_status = 'REFUNDED' if payment.status == 'REFUNDED' else 'UNPAID'
                order.save(update_fields=['status', 'payment_status'])

        broadcast_payment_status(payment)
        return Response({'message': f'Payment {payment.status.lower()} successfully.', 'payment': PaymentSerializer(payment).data})


class RefundPaymentView(APIView):
    permission_classes = [permissions.IsAdminUser]

    def post(self, request, pk):
        try:
            payment = Payment.objects.select_related('order').get(id=pk)
        except Payment.DoesNotExist:
            return Response({'detail': 'Payment not found.'}, status=status.HTTP_404_NOT_FOUND)

        if payment.status != 'PAID':
            return Response({'detail': f'Cannot refund payment in {payment.status} status.'}, status=status.HTTP_400_BAD_REQUEST)

        provider = payment_service.get_provider(payment.provider)
        result = provider.refund(payment)

        with transaction.atomic():
            payment.status = 'REFUNDED'
            payment.save(update_fields=['status'])
            order = payment.order
            order.status = 'cancelled'
            order.payment_status = 'REFUNDED'
            order.save(update_fields=['status', 'payment_status'])

        broadcast_payment_status(payment)
        return Response({
            'message': 'Payment refunded successfully.',
            'payment': PaymentSerializer(payment).data,
            'result': result
        }, status=status.HTTP_200_OK)


class BaseCallbackView(APIView):
    permission_classes = [permissions.AllowAny]
    provider_name = ""

    def post(self, request):
        logger.info(f"Received {self.provider_name} webhook/callback: {request.data}")

        # Webhook Authorization Guard
        payment_env = os.environ.get("PAYMENT_ENV", getattr(settings, "PAYMENT_ENV", "sandbox")).lower()
        auth_secret = request.headers.get('X-Webhook-Secret') or request.headers.get('X-Signature') or request.data.get('webhook_secret')
        expected_secret = os.environ.get("PAYMENT_WEBHOOK_SECRET")
        if not expected_secret:
            if getattr(settings, 'IS_TESTING', False) or settings.DEBUG or ('test' in sys.argv and getattr(settings, 'IS_TESTING', True)):
                expected_secret = "foodgo_webhook_secure_key_2026"
            else:
                raise ImproperlyConfigured("PAYMENT_WEBHOOK_SECRET environment variable is not configured.")

        if payment_env == "production":
            is_authorized = (auth_secret == expected_secret or (request.user.is_authenticated and request.user.is_staff))
        else:
            # In sandbox / testing mode, allow if no secret provided, but strictly reject if wrong secret was sent
            is_authorized = (
                auth_secret == expected_secret or
                (request.user.is_authenticated and request.user.is_staff) or
                auth_secret is None
            )

        if not is_authorized:
            logger.warning(f"Unauthorized payment callback attempt for provider {self.provider_name}")
            return Response({'detail': 'Unauthorized webhook call.'}, status=status.HTTP_401_UNAUTHORIZED)

        merchant_ref = request.data.get('merchant_reference')
        if not merchant_ref:
            return Response({'detail': 'merchant_reference is missing.'}, status=status.HTTP_400_BAD_REQUEST)

        if merchant_ref.startswith('TOPUP-'):
            from .models import Wallet, WalletTransaction, User
            existing_tx = WalletTransaction.objects.filter(description__contains=merchant_ref).first()
            if existing_tx:
                return Response({
                    'status': 'SUCCESS',
                    'message': 'Wallet top-up already processed.',
                    'new_balance': str(existing_tx.wallet.balance)
                }, status=status.HTTP_200_OK)

            parts = merchant_ref.split('-')
            try:
                user_id = int(parts[1])
                from decimal import Decimal
                user = User.objects.get(id=user_id)
                wallet, _ = Wallet.objects.get_or_create(user=user)
                amt_str = request.data.get('amount', '10.00')
                currency = request.data.get('currency', 'USD').upper()
                amt = Decimal(str(amt_str))
                if currency == 'KHR' and amt >= Decimal('1000'):
                    amt = (amt / Decimal('4100')).quantize(Decimal('0.01'))
                with transaction.atomic():
                    wallet.balance = Decimal(str(wallet.balance)) + amt
                    wallet.save()
                    WalletTransaction.objects.create(
                        wallet=wallet,
                        amount=amt,
                        transaction_type='deposit',
                        description=f'KHQR Top-Up via {self.provider_name} ({merchant_ref})'
                    )
                return Response({
                    'status': 'SUCCESS',
                    'message': f'Wallet top-up of ${amt} credited successfully.',
                    'new_balance': str(wallet.balance)
                }, status=status.HTTP_200_OK)
            except Exception as e:
                logger.error(f"Error handling topup callback: {e}")
                return Response({'detail': f'Failed to process topup: {str(e)}'}, status=status.HTTP_400_BAD_REQUEST)

        with transaction.atomic():
            try:
                payment = Payment.objects.select_for_update().select_related('order').get(merchant_reference=merchant_ref)
            except Payment.DoesNotExist:
                return Response({'detail': 'Payment record not found.'}, status=status.HTTP_404_NOT_FOUND)

            # Idempotency check: if already paid, return 200 immediately
            if payment.status == 'PAID':
                return Response({'detail': 'Payment already processed.'}, status=status.HTTP_200_OK)

            provider = payment_service.get_provider(self.provider_name)

            if not provider.verify_payment(payment, request.data):
                return Response({'detail': 'Payment verification failed.'}, status=status.HTTP_400_BAD_REQUEST)

            parsed = provider.handle_callback(request.data)

            payment.status = 'PAID'
            payment.transaction_id = parsed.get('transaction_id')
            payment.paid_at = timezone.now()
            payment.provider_response = parsed.get('raw_response', {})
            payment.save(update_fields=['status', 'transaction_id', 'paid_at', 'provider_response'])

            order = payment.order
            order.payment_status = 'PAID'
            order.status = 'confirmed' # Payment satisfied, order confirmed for restaurant!
            order.save(update_fields=['payment_status', 'status'])

        broadcast_payment_status(payment)
        return Response({'status': 'SUCCESS', 'message': 'Payment verified and order confirmed.'}, status=status.HTTP_200_OK)


class ABACallbackView(BaseCallbackView):
    provider_name = "ABA"


class ACLEDACallbackView(BaseCallbackView):
    provider_name = "ACLEDA"


class BakongCallbackView(BaseCallbackView):
    provider_name = "BAKONG"
