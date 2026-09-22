import os
import time
import logging
from datetime import timedelta
from django.utils import timezone
from .base import PaymentProvider

logger = logging.getLogger(__name__)

class ACLEDAKHQRProvider(PaymentProvider):
    def __init__(self):
        self.enabled = os.environ.get("ACLEDA_ENABLED", "True").lower() in ("true", "1", "yes")
        self.payment_env = os.environ.get("PAYMENT_ENV", "sandbox")
        self.merchant_id = os.environ.get("ACLEDA_MERCHANT_ID", "acleda_foodgo_01")
        self.api_key = os.environ.get("ACLEDA_API_KEY", "mock_acleda_api_key")
        self.api_secret = os.environ.get("ACLEDA_API_SECRET", "mock_acleda_secret_key")
        self.api_url = os.environ.get("ACLEDA_API_URL", "https://api.acledabank.com.kh/sandbox/v1/x-pay/partner/merchant/payment")
        self.callback_url = os.environ.get("ACLEDA_CALLBACK_URL", "http://127.0.0.1:8000/api/payments/acleda/callback/")

    def create_payment(self, order, amount, currency: str = "USD", **kwargs):
        merchant_ref = f"FG-AC-{order.id}-{int(time.time())}"
        expires_at = timezone.now() + timedelta(minutes=5)

        currency_code = "840" if currency.upper() == "USD" else "116"
        qr_string = f"00020101021229380016acledakhppxxx@acleda0110{self.merchant_id}520458125303{currency_code}54{len(str(amount)):02d}{amount}5802KH5912FoodGo_Order6010Phnom_Penh62{len(merchant_ref):02d}{merchant_ref}63045678"

        provider_response = {
            "merchant_id": self.merchant_id,
            "merchant_reference": merchant_ref,
            "amount": str(amount),
            "currency": currency,
            "qr_string": qr_string,
            "environment": self.payment_env,
            "status": "PENDING"
        }

        return {
            "merchant_reference": merchant_ref,
            "qr_payload": qr_string,
            "qr_image": None,
            "expires_at": expires_at,
            "provider_response": provider_response
        }

    def get_payment_status(self, payment):
        if timezone.now() > payment.expires_at and payment.status == "PENDING":
            return {
                "status": "EXPIRED",
                "transaction_id": payment.transaction_id,
                "paid_at": None,
                "raw_response": {"reason": "Payment window expired (5 minutes)"}
            }
        return {
            "status": payment.status,
            "transaction_id": payment.transaction_id,
            "paid_at": payment.paid_at,
            "raw_response": payment.provider_response or {}
        }

    def verify_payment(self, payment, callback_data: dict) -> bool:
        received_ref = callback_data.get("merchant_reference")
        received_amount = str(callback_data.get("amount", ""))
        received_currency = callback_data.get("currency", "")

        if received_ref != payment.merchant_reference:
            return False

        if float(received_amount) != float(payment.amount):
            return False

        if received_currency.upper() != payment.currency.upper():
            return False

        return True

    def handle_callback(self, callback_data: dict):
        return {
            "merchant_reference": callback_data.get("merchant_reference"),
            "transaction_id": callback_data.get("transaction_id") or f"ACL-TXN-{int(time.time())}",
            "status": callback_data.get("status", "PAID"),
            "amount": callback_data.get("amount"),
            "currency": callback_data.get("currency", "USD"),
            "raw_response": callback_data
        }

    def refund(self, payment, amount=None):
        return {"status": "REFUNDED", "amount": amount or str(payment.amount)}
