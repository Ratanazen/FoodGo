from abc import ABC, abstractmethod
from typing import Dict, Any, Optional

class PaymentProvider(ABC):
    @abstractmethod
    def create_payment(self, order, amount, currency: str = "USD", **kwargs) -> Dict[str, Any]:
        """
        Creates a payment intent / dynamic QR payload for the order.
        Returns a dict containing:
        {
            'merchant_reference': str,
            'qr_payload': str,
            'qr_image': Optional[str],
            'expires_at': datetime,
            'provider_response': dict
        }
        """
        pass

    @abstractmethod
    def get_payment_status(self, payment) -> Dict[str, Any]:
        """
        Checks real-time transaction status from the payment gateway.
        Returns:
        {
            'status': 'PAID' | 'PENDING' | 'FAILED' | 'EXPIRED',
            'transaction_id': Optional[str],
            'paid_at': Optional[datetime],
            'raw_response': dict
        }
        """
        pass

    @abstractmethod
    def verify_payment(self, payment, callback_data: Dict[str, Any]) -> bool:
        """
        Validates webhook / callback payload authenticity, signature and amounts.
        """
        pass

    @abstractmethod
    def handle_callback(self, callback_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Processes provider webhook / callback payload.
        """
        pass

    @abstractmethod
    def refund(self, payment, amount: Optional[float] = None) -> Dict[str, Any]:
        """
        Refunds a paid payment.
        """
        pass
