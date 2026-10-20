# FoodGo Payment Provider Integration & Configuration Guide

This guide documents the setup, environment configuration, credentials, and verification procedures for all supported payment methods in FoodGo.

---

## 1. Supported Providers

| Provider | Method | Mechanism | Supported Currencies |
|---|---|---|---|
| **Bakong KHQR** | KHQR | NBC Open API / Dynamic KHQR | USD, KHR |
| **ABA PayWay** | KHQR | ABA PayWay Gateway / Dynamic KHQR | USD, KHR |
| **ACLEDA KHQR** | KHQR | ACLEDA E-Commerce API / Dynamic KHQR | USD, KHR |
| **FoodGo Wallet** | Wallet | Instant balance deduction | USD |
| **Cash on Delivery** | COD | In-person cash collection upon delivery | USD, KHR |

---

## 2. Environment Variables Configuration

Add the following keys to your `.env` or production environment settings:

```ini
# ==============================================================================
# GLOBAL PAYMENT CONFIGURATION
# ==============================================================================
PAYMENT_ENV=sandbox                       # 'sandbox' or 'production'
PAYMENT_WEBHOOK_SECRET=your_super_secret_webhook_key_here

# ==============================================================================
# BAKONG KHQR (NBC OPEN API)
# ==============================================================================
BAKONG_ENABLED=True
BAKONG_API_URL=https://api-bakong.nbc.gov.kh/v1
BAKONG_MERCHANT_ID=foodgo_bakong_merchant
BAKONG_MERCHANT_NAME=FoodGo Restaurant
BAKONG_MERCHANT_CITY=Phnom Penh
BAKONG_ACQUIRING_BANK=Bakong
BAKONG_TOKEN=your_nbc_bakong_api_token_here

# ==============================================================================
# ABA PAYWAY KHQR
# ==============================================================================
ABA_ENABLED=True
ABA_API_URL=https://checkout-sandbox.payway.com.kh/api/payment-gateway/v1/payments/purchase
ABA_MERCHANT_ID=foodgo_aba_merchant
ABA_MERCHANT_NAME=FoodGo Restaurant
ABA_MERCHANT_CITY=Phnom Penh
ABA_API_KEY=your_aba_payway_api_key
ABA_API_SECRET=your_aba_payway_secret_key
ABA_CALLBACK_URL=http://127.0.0.1:8000/api/payments/aba/callback/

# ==============================================================================
# ACLEDA KHQR
# ==============================================================================
ACLEDA_ENABLED=True
ACLEDA_API_URL=https://epayment-sandbox.acledabank.com.kh/api/v1/payment
ACLEDA_MERCHANT_ID=foodgo_acleda_merchant
ACLEDA_MERCHANT_NAME=FoodGo Restaurant
ACLEDA_MERCHANT_CITY=Phnom Penh
ACLEDA_API_KEY=your_acleda_api_key
ACLEDA_API_SECRET=your_acleda_api_secret
ACLEDA_CALLBACK_URL=http://127.0.0.1:8000/api/payments/acleda/callback/
```

---

## 3. Webhook Endpoints & Verification

### Endpoints
- **Bakong Callback**: `POST /api/payments/bakong/callback/`
- **ABA Callback**: `POST /api/payments/aba/callback/`
- **ACLEDA Callback**: `POST /api/payments/acleda/callback/`

### Security Headers
In non-development environments (`DEBUG=False` and `IS_TESTING=False`), incoming requests MUST supply:
```http
X-Webhook-Secret: <PAYMENT_WEBHOOK_SECRET>
```
If the header is missing or does not match `PAYMENT_WEBHOOK_SECRET`, the endpoint immediately returns `401 Unauthorized`.

### Request Body Schema
```json
{
  "merchant_reference": "FG-ABA-101-1718000000",
  "amount": "15.50",
  "currency": "USD",
  "transaction_id": "BANK-TXN-987654321",
  "status": "PAID"
}
```

---

## 4. Sandbox Testing & Simulation

### Testing via Web UI
In developer mode or sandbox environments, the Flutter `QRPaymentScreen` displays a **Simulate Webhook Pay (Test Mode)** button. Clicking this button immediately fires a synthetic callback matching the active payment session, verifying the real-time UI transition to PAID without needing an external mobile banking app.

### Testing via cURL
```bash
# 1. Create a payment session
curl -X POST http://127.0.0.1:8000/api/payments/create/ \
  -H "Authorization: Bearer <CUSTOMER_JWT_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"order_id": 1, "provider": "ABA", "currency": "USD"}'

# 2. Simulate bank webhook
curl -X POST http://127.0.0.1:8000/api/payments/aba/callback/ \
  -H "Content-Type: application/json" \
  -d '{
    "merchant_reference": "FG-ABA-1-...",
    "amount": "15.50",
    "currency": "USD",
    "transaction_id": "TEST-CURL-001",
    "status": "PAID"
  }'
```

---

## 5. Administrative Operations & Refunds

1. **Viewing Payments**:
   Log in to the Admin Console at `/admin/dashboard` or via API `GET /api/admin/payments/`. You can filter transactions by status (`PAID`, `PENDING`, `REFUNDED`, `FAILED`, `EXPIRED`) or search by merchant reference, transaction ID, customer username, or order ID.

2. **Issuing a Refund**:
   Send a POST request to `/api/admin/payments/{id}/refund/`:
   ```bash
   curl -X POST http://127.0.0.1:8000/api/admin/payments/1/refund/ \
     -H "Authorization: Bearer <ADMIN_JWT_TOKEN>" \
     -H "Content-Type: application/json" \
     -d '{"reason": "Customer cancellation request"}'
   ```
   This action:
   - Updates `payment.status` to `REFUNDED`.
   - Updates `order.payment_status` to `REFUNDED` and cancels the order if still in progress.
   - Writes an immutable record to `AuditLog` containing administrator details, timestamps, IP address, and refund justification.
