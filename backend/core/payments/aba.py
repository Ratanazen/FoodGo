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

logger = logging.getLogger(__name__)

class ABAKHQRProvider(PaymentProvider):
    def __init__(self):
        self.enabled = os.environ.get("ABA_ENABLED", "True").lower() in ("true", "1", "yes")
        self.payment_env = os.environ.get("PAYMENT_ENV", "sandbox")
        self.merchant_id = os.environ.get("ABA_MERCHANT_ID", "foodgo_merchant_01")
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

    def create_payment(self, order, amount, currency: str = "USD", **kwargs):
        merchant_ref = f"FG-ABA-{order.id}-{int(time.time())}"
        expires_at = timezone.now() + timedelta(minutes=5)
        
        # Bakong / ABA Dynamic KHQR payload structure according to NBC KHQR standard
        currency_code = "840" if currency.upper() == "USD" else "116"
        qr_string = f"00020101021229380016abaakhppxxx@abaa0110{self.merchant_id}520458125303{currency_code}54{len(str(amount)):02d}{amount}5802KH5912FoodGo_Order6010Phnom_Penh62{len(merchant_ref):02d}{merchant_ref}6304ABCD"

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
