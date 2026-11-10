import time
from datetime import timedelta
from decimal import Decimal
from django.utils import timezone
from .base import PaymentProvider

class CardPaymentProvider(PaymentProvider):
    """
    Card Payment Provider for FoodGo.
    Supports Visa, Mastercard, JCB, and UnionPay with simulated/gateway authorization.
    """
    def __init__(self):
        self.enabled = True
        self.is_configured = True

    def create_payment(self, order, amount, currency: str = "USD", **kwargs):
        merchant_ref = f"FG-CARD-{order.id}-{int(time.time())}"
        txn_id = f"CARD-TXN-{int(time.time())}"
        now = timezone.now()

        card_last4 = str(kwargs.get("card_last4") or "4242")
        card_brand = str(kwargs.get("card_brand") or "Visa")

        return {
            "merchant_reference": merchant_ref,
            "transaction_id": txn_id,
            "qr_payload": None,
            "qr_image": None,
            "expires_at": now + timedelta(days=365),
            "paid_at": now,
            "status": "PAID",
            "provider_response": {
                "method": "CARD",
                "card_last4": card_last4,
                "card_brand": card_brand,
                "status": "PAID",
                "message": f"Payment of ${Decimal(str(amount)):.2f} charged successfully to {card_brand} •••• {card_last4}."
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
        return {"status": "REFUNDED", "amount": amount or str(payment.amount)}
