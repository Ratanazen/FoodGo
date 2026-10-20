import os
import time
import hmac
import hashlib
import base64
import requests
import logging
from datetime import timedelta
from django.utils import timezone
from .base import PaymentProvider
from .utils import build_emvco_khqr

logger = logging.getLogger(__name__)

class ABAKHQRProvider(PaymentProvider):
    def __init__(self):
        self.enabled = os.environ.get("ABA_ENABLED", "True").lower() in ("true", "1", "yes")
        self.payment_env = os.environ.get("PAYMENT_ENV", "sandbox")
        self.merchant_id = os.environ.get("ABA_MERCHANT_ID", "foodgo_merchant_01")
        self.merchant_name = os.environ.get("ABA_MERCHANT_NAME", "FoodGo Restaurant")
        self.merchant_city = os.environ.get("ABA_MERCHANT_CITY", "Phnom Penh")
        self.api_key = os.environ.get("ABA_API_KEY", "mock_aba_api_key")
        self.api_secret = os.environ.get("ABA_API_SECRET", "mock_aba_secret_key")
        self.api_url = os.environ.get("ABA_API_URL", "https://checkout-sandbox.payway.com.kh/api/payment-gateway/v1/payments/purchase")
        self.callback_url = os.environ.get("ABA_CALLBACK_URL", "http://127.0.0.1:8000/api/payments/aba/callback/")

    def _generate_hash(self, *values) -> str:
        data_str = "".join(str(v) for v in values)
        signature = hmac.new(
            self.api_secret.encode('utf-8'),
            data_str.encode('utf-8'),
            hashlib.sha512
        ).digest()
        return base64.b64encode(signature).decode('utf-8')

    def generate_khqr(self, merchant_ref: str, amount, currency: str = "USD") -> tuple[str, str]:
        return build_emvco_khqr(
            account_id=self.merchant_id,
            merchant_name=self.merchant_name,
            merchant_city=self.merchant_city,
            merchant_ref=merchant_ref,
            amount=amount,
            currency=currency,
            acquiring_bank_guid="abaakhppxxx@abaa",
            merchant_category_code="5812"
        )

    def create_payment(self, order, amount, currency: str = "USD", **kwargs):
        merchant_ref = f"FG-ABA-{order.id}-{int(time.time())}"
        expires_at = timezone.now() + timedelta(minutes=5)
        
        # Bakong / ABA Dynamic KHQR payload structure according to NBC KHQR standard
        qr_string, md5_hash = self.generate_khqr(merchant_ref=merchant_ref, amount=amount, currency=currency)

        provider_response = {
            "merchant_id": self.merchant_id,
            "merchant_reference": merchant_ref,
            "amount": str(amount),
            "currency": currency,
            "qr_string": qr_string,
            "md5": md5_hash,
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
            logger.warning(f"Merchant reference mismatch: {received_ref} vs {payment.merchant_reference}")
            return False

        if float(received_amount) != float(payment.amount):
            logger.warning(f"Amount mismatch: {received_amount} vs {payment.amount}")
            return False

        if received_currency.upper() != payment.currency.upper():
            logger.warning(f"Currency mismatch: {received_currency} vs {payment.currency}")
            return False

        return True

    def handle_callback(self, callback_data: dict):
        return {
            "merchant_reference": callback_data.get("merchant_reference"),
            "transaction_id": callback_data.get("transaction_id") or f"ABA-TXN-{int(time.time())}",
            "status": callback_data.get("status", "PAID"),
            "amount": callback_data.get("amount"),
            "currency": callback_data.get("currency", "USD"),
            "raw_response": callback_data
        }

    def refund(self, payment, amount=None):
        return {"status": "REFUNDED", "amount": amount or str(payment.amount)}
