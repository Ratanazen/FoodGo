# Cambodian Bank Payment Integration & Onboarding Guide

**Version:** 3.0.0-PROD  
**Date:** October 2026  
**Repository:** [https://github.com/Ratanazen/FoodGo](https://github.com/Ratanazen/FoodGo)  

---

## 1. Overview of Payment Gateways

FoodGo provides a modular payment architecture implemented under `backend/core/payments/`. It integrates Cambodian national fintech infrastructure and commercial bank gateways:

1. **NBC Bakong KHQR:** Interoperable national standard powered by the National Bank of Cambodia (NBC).
2. **ABA PayWay:** Commercial gateway for ABA Mobile & ABA KHQR.
3. **ACLEDA Bank x-Pay:** ACLEDA KHQR merchant payments.
4. **FoodGo Digital Wallet:** In-app wallet balance with instant KHQR top-ups.
5. **Cash on Delivery (COD):** In-person payment upon food delivery.

---

## 2. Gateway Onboarding & Credentials Setup

### 2.1 NBC Bakong KHQR
- **Merchant Onboarding:**
  1. Open a corporate Bakong merchant account with an NBC member financial institution.
  2. Obtain your official Bakong Account ID (e.g., `foodgo@acleda` or `foodgo@aba`).
  3. Register for Bakong Open API credentials via the NBC Developer Portal.
- **Environment Variables:**
  ```env
  BAKONG_ENABLED=True
  BAKONG_API_URL=https://api-bakong.nbc.gov.kh/v1
  BAKONG_MERCHANT_ID=foodgo@acleda
  BAKONG_MERCHANT_NAME="FoodGo Delivery"
  BAKONG_MERCHANT_CITY="Phnom Penh"
  BAKONG_API_TOKEN=your_official_bakong_token_here
  ```
- **EMVCo KHQR Tags Generated:**
  - Tag `00`: Format Indicator (`01`)
  - Tag `01`: Point of Initiation Method (`12` Dynamic QR)
  - Tag `29`: Merchant Account Information (`00` Global Unique ID, `01` Bakong ID)
  - Tag `52`: Merchant Category Code (`5812` Eating Places & Restaurants)
  - Tag `53`: Transaction Currency (`840` for USD, `116` for KHR)
  - Tag `54`: Transaction Amount
  - Tag `58`: Country Code (`KH`)
  - Tag `59`: Merchant Name (`FoodGo Delivery`)
  - Tag `60`: Merchant City (`Phnom Penh`)
  - Tag `62`: Additional Data Field (Order Reference)
  - Tag `63`: CRC16-CCITT (4-character checksum)

### 2.2 ABA PayWay
- **Merchant Onboarding:**
  1. Contact ABA Bank Card Center / Digital Banking Team for PayWay Merchant Registration.
  2. Receive Merchant ID, Sandbox API Key, and Webhook Public Key.
- **Environment Variables:**
  ```env
  ABA_ENABLED=True
  ABA_API_URL=https://checkout-sandbox.payway.com.kh/api/payment-gateway/v1
  ABA_MERCHANT_ID=ec438921
  ABA_API_KEY=your_aba_api_key_here
  ABA_PUBLIC_KEY=your_aba_public_key_here
  ```
- **Signature Algorithm:** PayWay requires payload signing using `HMAC-SHA512` over concatenated parameters:
  $$\text{Hash} = \text{HMAC-SHA512}(\text{req\_time} + \text{merchant\_id} + \text{tran\_id} + \text{amount} + \text{currency}, \text{api\_key})$$

### 2.3 ACLEDA Bank x-Pay
- **Merchant Onboarding:**
  1. Sign merchant agreement with ACLEDA Bank Plc.
  2. Obtain Merchant Account ID, Partner Secret, and Dynamic KHQR Webhook URL.
- **Environment Variables:**
  ```env
  ACLEDA_ENABLED=True
  ACLEDA_API_URL=https://xpay.acledabank.com.kh/api/v1
  ACLEDA_MERCHANT_ID=ACLEDAMERCH001
  ACLEDA_API_KEY=your_acleda_api_key_here
  ```

---

## 3. Dual-Currency Financial Policy

FoodGo operates in Cambodia's dual-currency economy:
- **Default Settlement Currency:** United States Dollar ($ USD).
- **Khmer Riel (KHR):** Converted at the official standard NBC exchange rate:
  $$1\text{ USD} = 4,100\text{ KHR}$$
- **Formatting Rule:**
  - USD formatted with dollar sign and two decimals: `$14.50`
  - KHR formatted with riel symbol, thousand separators, and integer rounding: `៛59,450`
- Both currencies are visually displayed on all checkout and payment screens using `KhmerCurrency.formatDual()`.

---

## 4. Webhook Security & Idempotency

All inbound gateway notifications are handled with strict defense-in-depth:
1. **Secret & Signature Verification:** Callbacks must provide a valid `X-Webhook-Secret` or HMAC signature.
2. **Amount & Currency Parity:** Callbacks verifying transactions check that the gateway amount matches the order total.
3. **Idempotency Defense:** If payment status is already `PAID`, subsequent calls return `200 OK` without duplicating state changes or double-crediting balances.
4. **Client-Side Independence:** Flutter apps never transition payments to `PAID` directly; status is updated exclusively through server verification or authorized webhooks.
