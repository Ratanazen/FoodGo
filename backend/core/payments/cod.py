import time
from datetime import timedelta
from django.utils import timezone
from .base import PaymentProvider

class CODProvider(PaymentProvider):
    def create_payment(self, order, amount, currency: str = "USD", **kwargs):
        merchant_ref = f"FG-COD-{order.id}-{int(time.time())}"
        return {
            "merchant_reference": merchant_ref,
            "qr_payload": None,
            "qr_image": None,
            "expires_at": timezone.now() + timedelta(days=2),
            "provider_response": {
                "method": "COD",
                "status": "PENDING_CASH",
                "instructions": "Pay in cash upon food delivery"
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
            "transaction_id": callback_data.get("transaction_id") or f"COD-TXN-{int(time.time())}",
            "status": "PAID",
            "amount": callback_data.get("amount"),
            "currency": callback_data.get("currency", "USD"),
            "raw_response": callback_data
        }

    def refund(self, payment, amount=None):
        return {"status": "REFUNDED", "amount": amount or str(payment.amount)}
