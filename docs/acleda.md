# 🏦 ACLEDA KHQR Integration Guide

## Overview
ACLEDA X-Pay Partner API enables digital payments directly through **ACLEDA mobile** and the inter-bank Bakong payment rail.

## Environment Variables
```ini
ACLEDA_ENABLED=True
ACLEDA_MERCHANT_ID=acleda_foodgo_01
ACLEDA_API_KEY=your_acleda_api_key
ACLEDA_API_SECRET=your_acleda_secret_key
ACLEDA_API_URL=https://api.acledabank.com.kh/sandbox/v1/x-pay/partner/merchant/payment
ACLEDA_CALLBACK_URL=http://127.0.0.1:8000/api/payments/acleda/callback/
```

## Status Flow
1. Payment created with unique merchant reference `FG-AC-<order_id>-<timestamp>`.
2. Dynamic QR rendered in Flutter with expiration timer.
3. ACLEDA webhook hits `/api/payments/acleda/callback/`.
4. Transaction verified and committed in an atomic database transaction.
