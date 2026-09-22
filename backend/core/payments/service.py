from .aba import ABAKHQRProvider
from .acleda import ACLEDAKHQRProvider
from .cod import CODProvider
from .wallet import WalletPaymentProvider

class PaymentService:
    def __init__(self):
        self._providers = {
            "ABA": ABAKHQRProvider(),
            "ACLEDA": ACLEDAKHQRProvider(),
            "COD": CODProvider(),
            "WALLET": WalletPaymentProvider(),
        }

    def get_provider(self, provider_code: str):
        provider = self._providers.get(provider_code.upper())
        if not provider:
            raise ValueError(f"Unsupported payment provider: {provider_code}")
        return provider

payment_service = PaymentService()
