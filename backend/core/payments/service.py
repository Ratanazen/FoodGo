from .aba import ABAKHQRProvider
from .acleda import ACLEDAKHQRProvider
from .bakong import BakongKHQRProvider
from .card import CardPaymentProvider
from .cod import CODProvider
from .wallet import WalletPaymentProvider

class PaymentService:
    def __init__(self):
        bakong = BakongKHQRProvider()
        aba = ABAKHQRProvider()
        acleda = ACLEDAKHQRProvider()
        card = CardPaymentProvider()
        cod = CODProvider()
        wallet = WalletPaymentProvider()
        self._providers = {
            "BAKONG": bakong,
            "BAKONG_KHQR": bakong,
            "KHQR": bakong,
            "CARD": card,
            "CREDIT_CARD": card,
            "ABA": aba,
            "ABA_KHQR": aba,
            "ACLEDA": acleda,
            "ACLEDA_KHQR": acleda,
            "COD": cod,
            "CASH_ON_DELIVERY": cod,
            "WALLET": wallet,
        }

    def get_provider(self, provider_code: str):
        provider = self._providers.get(provider_code.upper())
        if not provider:
            raise ValueError(f"Unsupported payment provider: {provider_code}")
        return provider

    def get_available_methods(self):
        """
        Returns supported and configured payment methods metadata for clients,
        strictly omitting secret keys, passwords, and private tokens.
        Only one Bank method is presented (Bakong KHQR - universal Cambodian rail),
        alongside Card, COD, and Wallet.
        """
        bakong = self._providers["BAKONG"]
        card = self._providers["CARD"]
        aba = self._providers["ABA"]
        acleda = self._providers["ACLEDA"]
        cod = self._providers["COD"]
        wallet = self._providers["WALLET"]

        return [
            {
                "code": "BAKONG",
                "name": "Bakong KHQR",
                "khmer_name": "Bakong KHQR (ធនាគារជាតិនៃកម្ពុជា)",
                "method": "KHQR",
                "is_enabled": getattr(bakong, "enabled", True),
                "is_configured": getattr(bakong, "is_configured", True),
                "currencies": ["USD", "KHR"],
                "icon": "bakong_logo",
                "description": "National Bank of Cambodia universal KHQR rail — supports Bakong, ABA, ACLEDA & 50+ banks"
            },
            {
                "code": "CARD",
                "name": "Credit / Debit Card",
                "khmer_name": "កាតឥណទាន / ឥណពន្ធ (Card)",
                "method": "CARD",
                "is_enabled": getattr(card, "enabled", True),
                "is_configured": getattr(card, "is_configured", True),
                "currencies": ["USD"],
                "icon": "card",
                "description": "Pay with Visa, Mastercard, JCB, or UnionPay"
            },
            {
                "code": "ABA",
                "name": "ABA KHQR",
                "khmer_name": "ABA KHQR (ABA Mobile / PayWay)",
                "method": "KHQR",
                "is_enabled": getattr(aba, "enabled", True),
                "is_configured": getattr(aba, "is_configured", True),
                "currencies": ["USD", "KHR"],
                "icon": "khqr_logo",
                "description": "Pay with ABA Mobile or any KHQR app"
            },
            {
                "code": "ACLEDA",
                "name": "ACLEDA KHQR",
                "khmer_name": "ACLEDA KHQR (ACLEDA Mobile)",
                "method": "KHQR",
                "is_enabled": getattr(acleda, "enabled", True),
                "is_configured": getattr(acleda, "is_configured", True),
                "currencies": ["USD", "KHR"],
                "icon": "khqr_logo",
                "description": "Pay with ACLEDA Mobile or any KHQR app"
            },
            {
                "code": "COD",
                "name": "Cash on Delivery",
                "khmer_name": "ទូទាត់ជាសាច់ប្រាក់ពេលដឹកដល់ (Cash on Delivery)",
                "method": "COD",
                "is_enabled": getattr(cod, "enabled", True),
                "is_configured": True,
                "currencies": ["USD", "KHR"],
                "icon": "cash",
                "description": "Pay driver in cash upon food arrival"
            },
            {
                "code": "WALLET",
                "name": "FoodGo Wallet",
                "khmer_name": "កាបូបលុយ FoodGo (1-Tap Pay)",
                "method": "WALLET",
                "is_enabled": True,
                "is_configured": True,
                "currencies": ["USD"],
                "icon": "wallet",
                "description": "Instant 1-tap payment from FoodGo balance"
            }
        ]

payment_service = PaymentService()
