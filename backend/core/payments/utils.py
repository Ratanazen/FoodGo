import hashlib
import logging

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
    merchant_category_code: str = "5812"
) -> tuple[str, str]:
    """
    Builds a fully compliant National Bank of Cambodia (NBC) EMVCo Dynamic KHQR string
    and returns (qr_string, md5_hash).

    Tags implemented according to NBC KHQR standard:
    - Tag 00: Format Indicator ('01')
    - Tag 01: Point of Initiation Method ('12' for Dynamic)
    - Tag 29: Merchant Account Information
        - Sub-tag 00: Globally Unique Identifier (e.g. 'bakong@khqr', 'abaakhppxxx@abaa')
        - Sub-tag 01: Account Identifier
    - Tag 52: Merchant Category Code ('5812' for Eating Places / Restaurants)
    - Tag 53: Transaction Currency ('840' for USD, '116' for KHR)
    - Tag 54: Transaction Amount
    - Tag 58: Country Code ('KH')
    - Tag 59: Merchant Name
    - Tag 60: Merchant City
    - Tag 62: Additional Data Field Template
        - Sub-tag 01: Bill Number / Reference Number
    - Tag 63: CRC16 Checksum Placeholder ('6304') + 4-digit CRC16 hex
    """
    curr_upper = currency.upper()
    currency_code = "840" if curr_upper == "USD" else "116"

    if curr_upper == "KHR":
        formatted_amount = f"{int(float(amount))}"
    else:
        formatted_amount = f"{float(amount):.2f}"

    # Tag 29: Merchant Account Information
    tag_29_val = tlv("00", acquiring_bank_guid) + tlv("01", account_id)
    tag_29 = tlv("29", tag_29_val)

    # Tag 62: Additional Data Field Template (Sub-tag 01 is Bill / Ref Number)
    tag_62_val = tlv("01", merchant_ref)
    tag_62 = tlv("62", tag_62_val)

    # Assemble raw EMVCo payload up to Tag 63 header
    raw_payload = (
        tlv("00", "01") +
        tlv("01", "12") +
        tag_29 +
        tlv("52", merchant_category_code) +
        tlv("53", currency_code) +
        tlv("54", formatted_amount) +
        tlv("58", "KH") +
        tlv("59", merchant_name) +
        tlv("60", merchant_city) +
        tag_62 +
        "6304"
    )

    # Calculate real mathematical CRC16
    checksum = crc16_ccitt(raw_payload)
    qr_string = raw_payload + checksum
    md5_hash = hashlib.md5(qr_string.encode('utf-8')).hexdigest()

    return qr_string, md5_hash
