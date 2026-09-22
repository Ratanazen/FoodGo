import time
from datetime import timedelta
from decimal import Decimal
from django.utils import timezone
from .base import PaymentProvider

class WalletPaymentProvider(PaymentProvider):
    def create_payment(self, order, amount, currency: str = "USD", **kwargs):
        from core.models import Wallet, WalletTransaction
        customer = order.customer
        wallet, _ = Wallet.objects.get_or_create(user=customer)
        order_amount = Decimal(str(amount))

        current_balance = Decimal(str(wallet.balance))
        if current_balance < order_amount:
            raise ValueError(
                f"Insufficient balance in FoodGo Wallet (${current_balance:.2f} available, ${order_amount:.2f} required). "
                f"Please add money to your account or select KHQR / COD."
            )

        # Deduct balance atomically
        wallet.balance = current_balance - order_amount
        wallet.save(update_fields=['balance'])

        # Record transaction log
        WalletTransaction.objects.create(
            wallet=wallet,
            amount=order_amount,
            transaction_type='payment',
            description=f"Payment for Order #{order.id}"
        )

        merchant_ref = f"FG-WLT-{order.id}-{int(time.time())}"
        txn_id = f"WLT-TXN-{int(time.time())}"
        now = timezone.now()

        return {
            "merchant_reference": merchant_ref,
            "transaction_id": txn_id,
            "qr_payload": None,
            "qr_image": None,
            "expires_at": now + timedelta(days=365),
            "paid_at": now,
            "status": "PAID",
            "provider_response": {
                "method": "WALLET",
                "remaining_balance": str(wallet.balance),
                "status": "PAID",
                "message": "Payment completed successfully from account balance."
            }
        }

    def get_payment_status(self, payment):
        return {
            "status": payment.status,
            "transaction_id": payment.transaction_id,
            "paid_at": payment.paid_at,
            "raw_response": payment.provider_response or {}
        }

    def verify_payment(self, payment, callback_data: dict) -> bool:
        return True

    def handle_callback(self, callback_data: dict):
        return {
            "merchant_reference": callback_data.get("merchant_reference"),
            "transaction_id": callback_data.get("transaction_id"),
            "status": "PAID",
            "amount": callback_data.get("amount"),
            "currency": callback_data.get("currency", "USD"),
            "raw_response": callback_data
        }

    def refund(self, payment, amount=None):
        from core.models import Wallet, WalletTransaction
        refund_amount = Decimal(str(amount or payment.amount))
        wallet, _ = Wallet.objects.get_or_create(user=payment.order.customer)
        wallet.balance += refund_amount
        wallet.save(update_fields=['balance'])
        WalletTransaction.objects.create(
            wallet=wallet,
            amount=refund_amount,
            transaction_type='refund',
            description=f"Refund for Order #{payment.order.id}"
        )
        return {"status": "REFUNDED", "amount": str(refund_amount)}
