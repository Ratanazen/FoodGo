# 🏦 ABA KHQR Integration Guide

## Overview
ABA PayWay / KHQR integration enables customers to scan dynamic KHQR codes using **ABA Mobile**, **Bakong**, or any partner financial institution in Cambodia.

## Environment Variables
```ini
ABA_ENABLED=True
ABA_MERCHANT_ID=foodgo_merchant_01
ABA_API_KEY=your_aba_api_key
ABA_API_SECRET=your_aba_secret_key
ABA_API_URL=https://checkout-sandbox.payway.com.kh/api/payment-gateway/v1/payments/purchase
ABA_CALLBACK_URL=http://127.0.0.1:8000/api/payments/aba/callback/
```

## Payload Specification
Dynamic QR codes follow the **National Bank of Cambodia (NBC) KHQR Specification**:
- Tag `00`: Format Indicator (`01`)
- Tag `01`: Point of Initiation Method (`12` for dynamic)
- Tag `29`: Merchant Account Information (`abaakhppxxx@abaa`)
- Tag `53`: Transaction Currency (`840` for USD, `116` for KHR)
- Tag `54`: Transaction Amount
- Tag `62`: Merchant Reference (`FG-ABA-<order_id>-<timestamp>`)
- Tag `63`: CRC Checksum
