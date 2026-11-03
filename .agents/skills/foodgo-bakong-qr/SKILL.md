---
name: foodgo-bakong-qr
description: Authoritative guide and workflow for Cambodia Bank QR / Bakong KHQR payment integration, debugging, and verification in FoodGo.
---

# FoodGo Bakong KHQR & Bank QR Payment Skill

## Skill Trigger
Activate this skill whenever a task involves:
- Cambodia Bank QR, KHQR, or National Bank of Cambodia (NBC) Bakong Open API integration.
- Fixing, styling, or debugging the FoodGo payment screen, checkout flow, or QR code display.
- Verifying server-side transaction status, webhooks, MD5 tracking, or status transitions.
- Testing driver delivery payment verification vs. Cash on Delivery (COD).

---

## 1. Inspect-First Workflow
Before making any changes:
1. **Preserve Repository Changes**: Check `git status --short`. Never revert or overwrite uncommitted work.
2. **Framework & Architecture**: FoodGo uses a Django 5 backend (`backend/`) and a Flutter 3 client (`foodgo_flutter/`). Always run commands using the project's dedicated virtual environment (`backend/venv/bin/python`) and `flutter`.
3. **Inspect the Real Order Lifecycle**:
   - `CartProvider` (`foodgo_flutter/lib/providers/cart_provider.dart`)
   - `CheckoutScreen` (`foodgo_flutter/lib/features/checkout/presentation/checkout_screen.dart`)
   - Backend `CreatePaymentView` (`backend/core/payment_views.py`)
   - Backend `BakongKHQRProvider` (`backend/core/payments/bakong.py`)
   - Frontend `QRPaymentScreen` (`foodgo_flutter/lib/features/payment/screens/qr_payment_screen.dart`)
   - Driver Handover `deliver_order` (`backend/core/views.py`) & `DriverDashboardScreen` (`foodgo_flutter/lib/features/dashboard/presentation/driver_dashboard_screen.dart`)

---

## 2. Bakong KHQR Debugging Checklist

When a customer reports that a KHQR code is missing, unreadable, or failing:

1. **Backend Payload Generation**:
   - Verify that `BakongKHQRProvider.generate_khqr()` returned a valid EMVCo dynamic KHQR string.
   - Tag 00 (Payload Format Indicator): `"01"`
   - Tag 01 (Point of Initiation Method): `"12"` (Dynamic)
   - Tag 29 (Merchant Account Information): Must contain Sub-tag 00 (`"bakong@khqr"`) and Sub-tag 01 (`account_id`, e.g. `sonar_seang@bkrt`).
   - Tag 53 (Transaction Currency): `"840"` (USD) or `"116"` (KHR).
   - Tag 54 (Transaction Amount): Decimal formatted string (e.g. `"12.50"`).
   - Tag 58 (Country Code): `"KH"`.
   - Tag 62 (Additional Data Field): Contains Sub-tag 01 (Merchant Reference).
   - Tag 63 (CRC16 Checksum): Exactly 4 hexadecimal characters calculated via CCITT-FALSE (`poly=0x1021, init=0xFFFF`).
2. **Schema & Serialization**:
   - Ensure `POST /api/payments/create/` returns `qr_payload` at the root of the JSON response.
   - Ensure `PaymentModel.fromJson` parses `qr_payload`, `qr_string`, and `qr_image` (including fallback to nested `provider_response`).
3. **Frontend Display & Viewport Resiliency**:
   - Never render a fabricated dummy QR string on the client.
   - If `qrString` is present: Render `QrImageView` with error correction level `QrErrorCorrectLevel.M`.
   - If `qrString` is empty but `qrImage` (base64 Data URL) is present: Decode and render via `Image.memory`.
   - If both are missing: Display the dedicated error card with "Regenerate KHQR Code" action.
   - Responsive sizing: Clamp `qrSize` between `200.0` and `280.0` logical pixels with `20px` quiet-zone padding to fit 320px–360px phones without horizontal scroll or overflow.
   - Contrast: Ensure pure white background (`#FFFFFF`) with dark modules (`#000000`).

---

## 3. Token Secrecy & Credential Rules

1. **Server-Side Exclusivity**:
   - The Bakong Developer Bearer Token (`BAKONG_API_TOKEN`) and webhook secret (`PAYMENT_WEBHOOK_SECRET`) must exist exclusively on the server (`backend/.env`).
   - Never place bank tokens or secrets in Flutter code, assets, public Git commits, or client-facing HTTP response bodies.
2. **Environment Template**:
   - `.env.example` must contain only descriptive empty placeholders (e.g., `BAKONG_API_TOKEN=your_nbc_bakong_jwt_token_here`).
3. **Missing Configuration Reporting**:
   - If credentials for ABA PayWay or ACLEDA direct merchant gateways are missing, route transactions through the universal Bakong KHQR network and clearly report direct gateway credentials as an external dependency.

---

## 4. Server-Side Payment Verification Rules

1. **Authoritative NBC Bakong Open API Query**:
   - Endpoint: `https://api-bakong.nbc.gov.kh/v1/check_transaction_by_md5`
   - Payload: `{"md5": "<32-char-md5-hash-of-khqr-string>"}`
   - Header: `Authorization: Bearer <BAKONG_API_TOKEN>`
   - Status: Valid only when `responseCode == 0` and `data` contains matching `amount`, `currency`, and `toAccountId`.
2. **Signed Webhook Callbacks**:
   - Verify HMAC-SHA256 signature in `X-Signature` or `X-Webhook-Secret`.
   - Enforce exact currency and amount equality.
   - Ensure idempotency: repeated callback deliveries must return HTTP 200 without duplicating order state changes.
3. **Zero Simulation**:
   - Never provide or allow client-side query parameters (`?simulate=true` or `?status=PAID`) to bypass bank authorization.
   - Never mark an order `PAID` from a timer, client button, or customer screenshot.
4. **Driver Role Separation**:
   - Delivery drivers can only verify physical cash collection for Cash on Delivery (`COD`).
   - Driver handover button cannot mark Bank QR (`BAKONG`, `ABA`, `ACLEDA`) payments verified. If payment is unpaid at delivery, the server rejects handover with HTTP 400.

---

## 5. Testing & Quality Standards

1. **Backend Tests**:
   - Run: `backend/venv/bin/python backend/manage.py test core.tests_payment core.tests_delivery_qr core.tests_dual_hosting`
   - Must verify:
     - Client status forgery rejection (pending remains pending).
     - Authoritative NBC Open API check with MD5 hash.
     - Currency and amount mismatch rejection.
     - Signed callback verification and replay prevention.
     - Driver bank payment bypass rejection.
2. **Flutter Tests**:
   - Run: `flutter test test/live_qr_payment_test.dart test/checkout_screen_banks_test.dart test/driver_module_test.dart`
   - Run full suite: `flutter test`
   - Analyze: `flutter analyze --no-fatal-infos`
   - Must verify:
     - Responsive QR card layout.
     - Real-time WebSocket transition from waiting to in-screen success card.
     - Expired, failed, and retry states.
     - Supported banks list display.

---

## 6. Reporting Rules

When presenting payment or QR changes:
1. List all modified source files with links and exact rationale.
2. Detail the exact server-side verification logic and security safeguards implemented.
3. Report full command outputs and test counts honestly.
4. Clearly distinguish verified features from external blockers (e.g. retail bank production merchant accounts).
5. Never commit, push, or deploy without explicit user permission.
