import base64
import hashlib
import io
import logging
import time

try:
    import qrcode
except ImportError:
    qrcode = None

logger = logging.getLogger(__name__)

def crc16_ccitt(data: str) -> str:
    """
    Computes standard EMVCo CRC16-CCITT checksum for KHQR strings.
    Polynomial: 0x1021
    Initial value: 0xFFFF
    Returns a 4-character uppercase hexadecimal string.
    """
    crc = 0xFFFF
    for ch in data.encode('ascii'):
        crc ^= (ch << 8)
        for _ in range(8):
            if crc & 0x8000:
                crc = ((crc << 1) ^ 0x1021) & 0xFFFF
            else:
                crc = (crc << 1) & 0xFFFF
    return f"{crc:04X}"


def tlv(tag: str, value: str) -> str:
    """
    Encodes an EMVCo Tag-Length-Value (TLV) element.
    Tag: 2-digit string
    Length: 2-digit string representing character length
    Value: string content
    """
    return f"{tag}{len(value):02d}{value}"


def build_emvco_khqr(
    account_id: str,
    merchant_name: str,
    merchant_city: str,
    merchant_ref: str,
    amount,
    currency: str = "USD",
    acquiring_bank_guid: str = "bakong@khqr",
    merchant_category_code: str = "5812",
    expiration_minutes: int = 30,
) -> tuple[str, str]:
    """
    Builds a fully compliant National Bank of Cambodia (NBC) EMVCo Dynamic KHQR string
    and returns (qr_string, md5_hash).

    Tags implemented according to NBC KHQR standard:
    - Tag 00: Format Indicator ('01')
    - Tag 01: Point of Initiation Method ('12' for Dynamic, '11' for Static)
    - Tag 29: Merchant Account Information (Individual KHQR)
        - Sub-tag 00: Bakong Account Identifier (e.g. 'sonar_seang@bkrt')
    - Tag 52: Merchant Category Code ('5812' for Eating Places / Restaurants)
    - Tag 53: Transaction Currency ('840' for USD, '116' for KHR)
    - Tag 54: Transaction Amount
    - Tag 58: Country Code ('KH')
    - Tag 59: Merchant Name (max 25 chars)
    - Tag 60: Merchant City (max 15 chars)
    - Tag 62: Additional Data Field Template
        - Sub-tag 01: Bill Number / Reference Number (max 25 chars)
    - Tag 99: Creation & Expiration Timestamp (required for Dynamic KHQR)
        - Sub-tag 00: Creation timestamp in epoch milliseconds (13 digits)
        - Sub-tag 01: Expiration timestamp in epoch milliseconds (13 digits)
    - Tag 63: CRC16 Checksum Placeholder ('6304') + 4-digit CRC16 hex
    """
    curr_upper = currency.upper()
    currency_code = "840" if curr_upper == "USD" else "116"

    amount_float = float(amount)
    is_static = amount_float <= 0

    if curr_upper == "KHR":
        formatted_amount = f"{int(amount_float)}"
    else:
        formatted_amount = f"{amount_float:.2f}".rstrip("0").rstrip(".")

    # Tag 29: Individual Bakong Account Information (Sub-tag 00 is Bakong Account ID per NBC KHQR spec)
    clean_account_id = (account_id or "sonar_seang@bkrt").strip()[:32]
    tag_29 = tlv("29", tlv("00", clean_account_id))

    # Tag 62: Additional Data Field Template (Sub-tag 01 is Bill / Ref Number, max 25 chars)
    clean_ref = str(merchant_ref or "").strip()[:25]
    tag_62 = tlv("62", tlv("01", clean_ref)) if clean_ref else ""

    # Tag 99: Creation & Expiration Timestamp in milliseconds (required by NBC / ACLEDA / ABA for Dynamic KHQR)
    now_ms = int(time.time() * 1000)
    exp_ms = now_ms + (max(1, int(expiration_minutes)) * 60 * 1000)
    tag_99_val = tlv("00", str(now_ms))
    if not is_static:
        tag_99_val += tlv("01", str(exp_ms))
    tag_99 = tlv("99", tag_99_val)

    point_of_initiation = "11" if is_static else "12"
    tag_54 = "" if is_static else tlv("54", formatted_amount)

    # Assemble raw EMVCo payload up to Tag 63 header
    raw_payload = (
        tlv("00", "01") +
        tlv("01", point_of_initiation) +
        tag_29 +
        tlv("52", str(merchant_category_code)[:4]) +
        tlv("53", currency_code) +
        tag_54 +
        tlv("58", "KH") +
        tlv("59", str(merchant_name or "FoodGo Restaurant").strip()[:25]) +
        tlv("60", str(merchant_city or "Phnom Penh").strip()[:15]) +
        tag_62 +
        tag_99 +
        "6304"
    )

    # Calculate real mathematical CRC16
    checksum = crc16_ccitt(raw_payload)
    qr_string = raw_payload + checksum
    md5_hash = hashlib.md5(qr_string.encode('utf-8')).hexdigest()

    return qr_string, md5_hash


def generate_qr_base64(payload: str) -> str | None:
    """
    Renders an EMVCo QR code string into a base64-encoded PNG Data URL.
    Returns None if the qrcode engine is unavailable or rendering fails.
    """
    if qrcode is None:
        return None
    try:
        qr = qrcode.QRCode(
            version=None,
            error_correction=qrcode.constants.ERROR_CORRECT_M,
            box_size=10,
            border=2,
        )
        qr.add_data(payload)
        qr.make(fit=True)
        img = qr.make_image(fill_color="black", back_color="white")
        buf = io.BytesIO()
        img.save(buf, format="PNG")
        encoded = base64.b64encode(buf.getvalue()).decode("ascii")
        return f"data:image/png;base64,{encoded}"
    except Exception as exc:
        logger.warning(f"Failed to generate QR image base64: {exc}")
        return None
