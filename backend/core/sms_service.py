import re
import secrets
import hmac
import hashlib
import logging
import requests
from django.conf import settings
from django.utils import timezone

logger = logging.getLogger(__name__)

# Active Cambodian mobile network operator prefixes (without leading 0)
CAMBODIA_VALID_PREFIXES = {
    # Smart Axiata
    '10', '15', '16', '69', '70', '81', '86', '87', '93', '96', '98',
    # CamGSM / Cellcard
    '11', '12', '14', '17', '61', '76', '77', '78', '79', '85', '89', '92', '95', '99',
    # Viettel / Metfone
    '23', '31', '60', '66', '67', '68', '71', '88', '90', '97',
    # South East Asia Telecom (Seatel)
    '18',
    # Cootel
    '38',
}


def normalize_cambodia_phone(raw_phone: str) -> tuple[str, bool, str]:
    """
    Validates and normalizes Cambodian phone numbers to E.164 format (+855...).
    Supports inputs such as:
    - 012 345 678 -> +85512345678
    - 098-765-432 -> +85598765432
    - +855 12 345 678 -> +85512345678
    - 85512345678 -> +85512345678
    Returns (normalized_e164, is_valid, error_message).
    """
    if not raw_phone:
        return '', False, 'Phone number is required.'

    # Strip whitespace, dashes, dots, parentheses
    cleaned = re.sub(r'[\s\-\.\(\)]', '', str(raw_phone).strip())

    # Standardize to international format
    if cleaned.startswith('00855'):
        cleaned = '+855' + cleaned[5:]
    elif cleaned.startswith('0'):
        cleaned = '+855' + cleaned[1:]
    elif cleaned.startswith('855') and not cleaned.startswith('+855'):
        cleaned = '+' + cleaned
    elif not cleaned.startswith('+855'):
        if cleaned.isdigit():
            cleaned = '+855' + cleaned
        else:
            return '', False, 'Invalid phone number format. Only Cambodian (+855) mobile phone numbers are supported.'

    # Basic E.164 pattern check for Cambodia (+855 followed by 8 or 9 digits)
    if not re.match(r'^\+855[1-9]\d{7,8}$', cleaned):
        return '', False, 'Invalid Cambodian phone number length. Mobile numbers must have 8 or 9 digits.'

    # Check 2-digit operator prefix
    digits_after_country = cleaned[4:]
    prefix_2 = digits_after_country[:2]
    if prefix_2 not in CAMBODIA_VALID_PREFIXES:
        return '', False, f'Unsupported Cambodian mobile operator prefix: 0{prefix_2}.'

    return cleaned, True, None


def mask_phone(phone_normalized: str) -> str:
    """
    Masks a phone number for safe UI display without exposing full digits.
    Example: +85512345678 -> +855 12 *** 678
    """
    if not phone_normalized or len(phone_normalized) < 8:
        return phone_normalized or ''
    if phone_normalized.startswith('+855') and len(phone_normalized) >= 11:
        op = phone_normalized[4:6]
        suffix = phone_normalized[-3:]
        return f"+855 {op} *** {suffix}"
    prefix = phone_normalized[:7]
    suffix = phone_normalized[-3:]
    return f"{prefix} *** {suffix}"


def generate_secure_otp(length: int = 6) -> str:
    """
    Generates a cryptographically secure random numeric OTP.
    Uses Python secrets module (CSPRNG).
    """
    digits = "0123456789"
    return "".join(secrets.choice(digits) for _ in range(length))


def generate_salt(length: int = 16) -> str:
    """
    Generates a cryptographically random hexadecimal salt.
    """
    return secrets.token_hex(length)


def hash_otp(otp: str, salt: str) -> str:
    """
    Generates a keyed HMAC-SHA256 representation of the OTP.
    Plaintext OTPs are never stored in the database.
    """
    secret = getattr(settings, 'SECRET_KEY', 'foodgo_secure_key').encode('utf-8')
    payload = f"{salt}:{otp}".encode('utf-8')
    return hmac.new(secret, payload, hashlib.sha256).hexdigest()


def verify_otp_hash(submitted_otp: str, salt: str, target_hash: str) -> bool:
    """
    Constant-time comparison of the computed HMAC hash against the stored hash.
    Protects against timing attacks.
    """
    if not submitted_otp or not salt or not target_hash:
        return False
    computed = hash_otp(submitted_otp.strip(), salt)
    return hmac.compare_digest(computed, target_hash)


# ─────────────────────────────────────────────────────────────
# SMS Provider Adapters
# ─────────────────────────────────────────────────────────────

class BaseSMSProvider:
    name = "base"

    def send_otp(self, phone_normalized: str, otp: str, purpose: str = 'verification') -> tuple[bool, str, dict]:
        """
        Sends OTP SMS to recipient.
        Returns (success: bool, provider_message_id: str, error_or_meta: dict).
        """
        raise NotImplementedError


class SimoSMSProvider(BaseSMSProvider):
    """
    Primary Cambodian SMS Gateway adapter (smscambodia.com / ViHaT Group).
    Supports all major Cambodian operators (Smart, Cellcard, Metfone, Seatel, Cootel).
    API Endpoint: https://smscambodia.com/smsapi/
    """
    name = "simosms"

    def __init__(self):
        self.api_url = getattr(settings, 'SMS_API_BASE_URL', 'https://smscambodia.com/smsapi/').rstrip('/')
        self.api_key = getattr(settings, 'SMS_API_KEY', '')
        self.api_secret = getattr(settings, 'SMS_API_SECRET', '')
        self.sender_id = getattr(settings, 'SMS_SENDER_ID', 'FoodGo')

    def send_otp(self, phone_normalized: str, otp: str, purpose: str = 'verification') -> tuple[bool, str, dict]:
        if not self.api_key:
            logger.warning("SimoSMS credentials not configured in environment (SMS_API_KEY).")
            return False, '', {'error': 'SMS provider credentials not configured.'}

        # SimoSMS receiver expects standard format (e.g. 85512345678 or +85512345678)
        receiver = phone_normalized.lstrip('+')
        message = f"FoodGo: Your verification code is {otp}. Valid for 5 minutes. Do not share this code with anyone."

        payload = {
            'ApiKey': self.api_key,
            'SecretKey': self.api_secret,
            'Phone': receiver,
            'Content': message,
            'Brandname': self.sender_id,
            'SmsType': 2, # 2 = Transactional / OTP message
        }

        try:
            resp = requests.post(
                f"{self.api_url}/",
                json=payload,
                timeout=10,
                headers={'Content-Type': 'application/json', 'Accept': 'application/json'}
            )
            data = resp.json() if resp.status_code == 200 else {}
            code_result = str(data.get('CodeResult', ''))

            # SimoSMS CodeResult 100 = Success
            if code_result == '100':
                msg_id = str(data.get('SMSID', ''))
                return True, msg_id, {'status': 'DELIVERED', 'sms_id': msg_id}

            # Map SimoSMS error codes
            error_mapping = {
                '101': 'Authorization failed. Invalid API credentials.',
                '103': 'Insufficient SMS account balance.',
                '104': 'Sender ID does not exist or is not approved.',
                '118': 'Invalid message type specified.',
                '119': 'Sender name character exceeds 21 characters.',
            }
            err_msg = error_mapping.get(code_result, f"SMS gateway error code: {code_result}")
            logger.error("SimoSMS delivery failed for %s: %s", mask_phone(phone_normalized), err_msg)
            return False, '', {'error': err_msg, 'code_result': code_result}

        except requests.exceptions.RequestException as e:
            logger.error("Network timeout contacting SimoSMS gateway: %s", str(e))
            return False, '', {'error': 'SMS Gateway connection timeout. Please retry.'}


class WeUMSSMSProvider(BaseSMSProvider):
    """
    Alternative Asian multi-channel gateway (weums365.com).
    """
    name = "weums"

    def __init__(self):
        self.api_url = getattr(settings, 'WEUMS_API_URL', 'https://weums365.com/api/v1/messages')
        self.api_key = getattr(settings, 'WEUMS_API_KEY', '')

    def send_otp(self, phone_normalized: str, otp: str, purpose: str = 'verification') -> tuple[bool, str, dict]:
        if not self.api_key:
            return False, '', {'error': 'WeUMS API key not configured.'}

        message = f"FoodGo: Your verification code is {otp}. Valid for 5 minutes."
        payload = {
            'to': phone_normalized,
            'message': message,
            'channels': ['sms'],
            'priority': 'high',
        }

        try:
            resp = requests.post(
                self.api_url,
                json=payload,
                headers={'Authorization': f"Bearer {self.api_key}", 'Content-Type': 'application/json'},
                timeout=10
            )
            if resp.status_code in (200, 201):
                data = resp.json()
                msg_id = str(data.get('id', data.get('message_id', '')))
                return True, msg_id, {'status': 'ACCEPTED', 'id': msg_id}
            return False, '', {'error': f"WeUMS returned HTTP {resp.status_code}", 'response': resp.text[:200]}
        except requests.exceptions.RequestException as e:
            return False, '', {'error': f"WeUMS connection error: {str(e)}"}


class TestConsoleSMSProvider(BaseSMSProvider):
    """
    Isolated test / dry-run provider for development and automated test suites.
    Keeps a record of sent dispatches in memory for verification without leaking plain OTPs into persistent logs.
    """
    name = "test"
    delivered_messages = []

    @classmethod
    def reset(cls):
        cls.delivered_messages.clear()

    def send_otp(self, phone_normalized: str, otp: str, purpose: str = 'verification') -> tuple[bool, str, dict]:
        msg_id = f"TEST-SMS-{secrets.token_hex(6)}"
        record = {
            'phone_normalized': phone_normalized,
            'otp': otp,
            'purpose': purpose,
            'message_id': msg_id,
            'sent_at': timezone.now().isoformat(),
        }
        self.delivered_messages.append(record)
        return True, msg_id, {'status': 'TEST_SENT', 'message_id': msg_id}


def get_sms_provider() -> BaseSMSProvider:
    """
    Factory returning the configured SMS Provider adapter.
    """
    provider_name = getattr(settings, 'SMS_PROVIDER', 'simosms').lower()
    if provider_name == 'simosms':
        return SimoSMSProvider()
    elif provider_name == 'weums':
        return WeUMSSMSProvider()
    elif provider_name in ('test', 'console', 'mock'):
        return TestConsoleSMSProvider()
    # Default to SimoSMS
    return SimoSMSProvider()
