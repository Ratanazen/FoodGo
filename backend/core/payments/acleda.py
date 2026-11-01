import os
import time
import logging
from datetime import timedelta
from urllib.parse import quote
from django.utils import timezone
from .base import PaymentProvider
from .utils import build_emvco_khqr, generate_qr_base64

logger = logging.getLogger(__name__)

class ACLEDAKHQRProvider(PaymentProvider):
    def __init__(self):
        self.enabled = os.environ.get("ACLEDA_ENABLED", "True").lower() in ("true", "1", "yes")
        self.payment_env = os.environ.get("PAYMENT_ENV", "sandbox")
        self.merchant_id = os.environ.get("ACLEDA_MERCHANT_ID", "acleda_foodgo_01")
        self.merchant_name = os.environ.get("ACLEDA_MERCHANT_NAME", "FoodGo Restaurant")
        self.merchant_city = os.environ.get("ACLEDA_MERCHANT_CITY", "Phnom Penh")
        self.api_key = os.environ.get("ACLEDA_API_KEY", "mock_acleda_api_key")
        self.api_secret = os.environ.get("ACLEDA_API_SECRET", "mock_acleda_secret_key")
        self.api_url = os.environ.get("ACLEDA_API_URL", "https://api.acledabank.com.kh/sandbox/v1/x-pay/partner/merchant/payment")
        self.callback_url = os.environ.get("ACLEDA_CALLBACK_URL", "http://127.0.0.1:8000/api/payments/acleda/callback/")

    def generate_khqr(self, merchant_ref: str, amount, currency: str = "USD") -> tuple[str, str]:
        return build_emvco_khqr(
            account_id=self.merchant_id,
            merchant_name=self.merchant_name,
            merchant_city=self.merchant_city,
            merchant_ref=merchant_ref,
            amount=amount,
            currency=currency,
            acquiring_bank_guid="acledakhppxxx@acleda",
            merchant_category_code="5812"
        )

    def create_payment(self, order, amount, currency: str = "USD", **kwargs):
        merchant_ref = f"FG-AC-{order.id}-{int(time.time())}"
        expires_at = timezone.now() + timedelta(minutes=30)

        qr_string, md5_hash = self.generate_khqr(
            merchant_ref=merchant_ref,
            amount=amount,
            currency=currency
        )
        qr_image_data = generate_qr_base64(qr_string)
        deep_link = f"acledamobile://qr?data={quote(qr_string)}"

        provider_response = {
            "merchant_id": self.merchant_id,
            "merchant_reference": merchant_ref,
            "amount": str(amount),
            "currency": currency,
            "qr_string": qr_string,
            "qr_image": qr_image_data,
            "deep_link": deep_link,
            "md5": md5_hash,
            "environment": self.payment_env,
            "status": "PENDING"
        }

        return {
            "merchant_reference": merchant_ref,
            "qr_payload": qr_string,
            "qr_image": qr_image_data,
            "expires_at": expires_at,
            "provider_response": provider_response
        }

    @property
    def is_configured(self) -> bool:
        return bool(self.enabled and self.merchant_id and self.api_key and self.api_secret)

    def get_payment_status(self, payment):
        if timezone.now() > payment.expires_at and payment.status == "PENDING":
            return {
                "status": "EXPIRED",
                "transaction_id": payment.transaction_id,
                "paid_at": None,
                "raw_response": {"reason": "Payment window expired"}
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
