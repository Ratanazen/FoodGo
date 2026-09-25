import logging
from django.db import transaction
from django.utils import timezone
from rest_framework import status, permissions
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.generics import RetrieveAPIView
from .models import Order, Payment
from .serializers import PaymentSerializer
from .payments.service import payment_service

logger = logging.getLogger(__name__)

class CreatePaymentView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        order_id = request.data.get('order_id')
        provider_name = request.data.get('provider', 'ABA').upper()
        currency = request.data.get('currency', 'USD').upper()

        if not order_id:
            return Response({'detail': 'order_id is required.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            order = Order.objects.select_related('customer').get(id=order_id, customer=request.user)
        except Order.DoesNotExist:
            return Response({'detail': 'Order not found.'}, status=status.HTTP_404_NOT_FOUND)

        if order.payment_status == 'PAID':
            return Response({'detail': 'Order is already paid.'}, status=status.HTTP_400_BAD_REQUEST)

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

        with transaction.atomic():
            # Clear any previous payment for this order to satisfy OneToOne constraint and allow re-generating QR
            Payment.objects.filter(order=order).delete()

            payment = Payment.objects.create(
                order=order,
                provider=provider_name,
                method=method,
                merchant_reference=result['merchant_reference'],
                transaction_id=result.get('transaction_id'),
                amount=order.total_amount,
                currency=currency,
                qr_payload=result.get('qr_payload'),
                qr_image=result.get('qr_image'),
                expires_at=result.get('expires_at'),
                paid_at=result.get('paid_at'),
                provider_response=result.get('provider_response', {}),
                status=payment_status
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

    def post(self, request, pk):
        try:
            payment = Payment.objects.select_related('order').get(id=pk)
        except Payment.DoesNotExist:
            return Response({'detail': 'Payment not found.'}, status=status.HTTP_404_NOT_FOUND)

        if not request.user.is_staff and payment.order.customer != request.user:
            return Response({'detail': 'Permission denied.'}, status=status.HTTP_403_FORBIDDEN)

        # Check provider status
        try:
            provider = payment_service.get_provider(payment.provider)
            status_info = provider.get_payment_status(payment)
        except Exception as e:
            return Response({'detail': str(e)}, status=status.HTTP_400_BAD_REQUEST)

        # Expiration handling
        if status_info.get('status') == 'EXPIRED' and payment.status == 'PENDING':
            payment.status = 'EXPIRED'
            payment.save(update_fields=['status'])

        return Response(PaymentSerializer(payment).data)


class CancelPaymentView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        try:
            payment = Payment.objects.select_related('order').get(id=pk)
        except Payment.DoesNotExist:
            return Response({'detail': 'Payment not found.'}, status=status.HTTP_404_NOT_FOUND)

        if not request.user.is_staff and payment.order.customer != request.user:
            return Response({'detail': 'Permission denied.'}, status=status.HTTP_403_FORBIDDEN)

        if payment.status in ('PAID', 'REFUNDED'):
            return Response({'detail': f'Cannot cancel payment in {payment.status} status.'}, status=status.HTTP_400_BAD_REQUEST)

        payment.status = 'CANCELLED'
        payment.save(update_fields=['status'])
        return Response({'message': 'Payment cancelled successfully.', 'payment': PaymentSerializer(payment).data})


class BaseCallbackView(APIView):
    permission_classes = [permissions.AllowAny]
    provider_name = ""

    def post(self, request):
        logger.info(f"Received {self.provider_name} webhook/callback: {request.data}")
        merchant_ref = request.data.get('merchant_reference')
        if not merchant_ref:
            return Response({'detail': 'merchant_reference is missing.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            payment = Payment.objects.select_related('order').get(merchant_reference=merchant_ref)
        except Payment.DoesNotExist:
            return Response({'detail': 'Payment record not found.'}, status=status.HTTP_404_NOT_FOUND)

        # Idempotency check: if already paid, return 200 immediately
        if payment.status == 'PAID':
            return Response({'detail': 'Payment already processed.'}, status=status.HTTP_200_OK)

        provider = payment_service.get_provider(self.provider_name)

        if not provider.verify_payment(payment, request.data):
            return Response({'detail': 'Payment verification failed.'}, status=status.HTTP_400_BAD_REQUEST)

        parsed = provider.handle_callback(request.data)

        with transaction.atomic():
            payment.status = 'PAID'
            payment.transaction_id = parsed.get('transaction_id')
            payment.paid_at = timezone.now()
            payment.provider_response = parsed.get('raw_response', {})
            payment.save(update_fields=['status', 'transaction_id', 'paid_at', 'provider_response'])

            order = payment.order
            order.payment_status = 'PAID'
            order.status = 'confirmed' # Payment satisfied, order confirmed for restaurant!
            order.save(update_fields=['payment_status', 'status'])

        return Response({'status': 'SUCCESS', 'message': 'Payment verified and order confirmed.'}, status=status.HTTP_200_OK)


class ABACallbackView(BaseCallbackView):
    provider_name = "ABA"


class ACLEDACallbackView(BaseCallbackView):
    provider_name = "ACLEDA"
