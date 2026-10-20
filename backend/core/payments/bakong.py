import os
import time
import hashlib
import logging
import requests
from datetime import timedelta
from django.utils import timezone
from .base import PaymentProvider
from .utils import build_emvco_khqr, crc16_ccitt, tlv

logger = logging.getLogger(__name__)

class BakongKHQRProvider(PaymentProvider):
    """
    Official NBC Bakong KHQR Open API Provider.
    Generates EMVCo KHQR strings and verifies payment transactions
    directly with the National Bank of Cambodia Bakong Open API via MD5 tracking.
    """

    def __init__(self):
        self.enabled = os.environ.get("BAKONG_ENABLED", "True").lower() in ("true", "1", "yes")
        self.api_token = os.environ.get("BAKONG_API_TOKEN", "")
        self.api_url = os.environ.get(
            "BAKONG_API_URL",
            "https://api-bakong.nbc.gov.kh/v1/check_transaction_by_md5"
        )
        self.account_id = os.environ.get("BAKONG_ACCOUNT_ID", "sonar_seang@bkrt")
        self.merchant_name = os.environ.get("BAKONG_MERCHANT_NAME", "FoodGo Restaurant")
        self.merchant_city = os.environ.get("BAKONG_MERCHANT_CITY", "Phnom Penh")

    @staticmethod
    def _crc16_ccitt(data: str) -> str:
        return crc16_ccitt(data)

    @staticmethod
    def _tlv(tag: str, value: str) -> str:
        return tlv(tag, value)

    def generate_khqr(self, merchant_ref: str, amount, currency: str = "USD") -> tuple[str, str]:
        """
        Builds a compliant EMVCo Dynamic KHQR string and computes its 32-char MD5 tracking hash.
        """
        return build_emvco_khqr(
            account_id=self.account_id,
            merchant_name=self.merchant_name,
            merchant_city=self.merchant_city,
            merchant_ref=merchant_ref,
            amount=amount,
            currency=currency,
            acquiring_bank_guid="bakong@khqr",
            merchant_category_code="5812"
        )

    def create_payment(self, order, amount, currency: str = "USD", **kwargs):
        merchant_ref = f"FG-BK-{order.id}-{int(time.time())}"
        expires_at = timezone.now() + timedelta(minutes=5)

        qr_string, md5_hash = self.generate_khqr(
            merchant_ref=merchant_ref,
            amount=amount,
            currency=currency
        )

        provider_response = {
            "account_id": self.account_id,
            "merchant_name": self.merchant_name,
            "merchant_reference": merchant_ref,
            "amount": str(amount),
            "currency": currency,
            "qr_string": qr_string,
            "md5": md5_hash,
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
        # 1. If already paid, return status
        if payment.status == "PAID":
            return {
                "status": "PAID",
                "transaction_id": payment.transaction_id,
                "paid_at": payment.paid_at,
                "raw_response": payment.provider_response or {}
            }

        # 2. Check 5-minute expiration window
        if payment.expires_at and timezone.now() > payment.expires_at and payment.status == "PENDING":
            return {
                "status": "EXPIRED",
                "transaction_id": payment.transaction_id,
                "paid_at": None,
                "raw_response": {"reason": "Payment window expired (5 minutes)"}
            }

        # 3. Query NBC Bakong Open API check_transaction_by_md5
        md5_hash = (payment.provider_response or {}).get("md5")
        if not md5_hash and payment.qr_payload:
            md5_hash = hashlib.md5(payment.qr_payload.encode('utf-8')).hexdigest()

        if md5_hash and self.api_token:
            try:
                headers = {
                    "Authorization": f"Bearer {self.api_token}",
                    "Content-Type": "application/json"
                }
                resp = requests.post(
                    self.api_url,
                    headers=headers,
                    json={"md5": md5_hash},
                    timeout=5
                )
                if resp.status_code == 200:
                    data = resp.json()
                    # Bakong responseCode 0 means transaction succeeded and verified!
                    if data.get("responseCode") == 0 and data.get("data"):
                        txn_data = data.get("data")
                        return {
                            "status": "PAID",
                            "transaction_id": txn_data.get("hash") or f"BAKONG-{md5_hash}",
                            "paid_at": timezone.now(),
                            "raw_response": txn_data
                        }
                    else:
                        logger.debug(f"Bakong status check: {data.get('responseMessage')}")
            except Exception as e:
                logger.warning(f"Failed to query Bakong Open API: {e}")

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
            "transaction_id": callback_data.get("transaction_id") or f"BKG-TXN-{int(time.time())}",
            "status": callback_data.get("status", "PAID"),
            "amount": callback_data.get("amount"),
            "currency": callback_data.get("currency", "USD"),
            "raw_response": callback_data
        }

    def refund(self, payment, amount=None):
        return {"status": "REFUNDED", "amount": amount or str(payment.amount)}
