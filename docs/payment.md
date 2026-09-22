# 💳 Payment Subsystem Architecture

FoodGo provides a multi-provider payment engine designed to prevent fraudulent client-side confirmations.

## Workflow

```
[Flutter Checkout]
        │
        ▼ 1. POST /api/payments/create/ (order_id, provider='ABA')
[Django PaymentService]
        │
        ▼ 2. Generates dynamic NBC KHQR payload & 5-min expiration
[Flutter QRPaymentScreen]
        │
        ├── 3. Scanned by Customer Banking App (ABA Mobile, Bakong, etc.)
        │
        ▼ 4. Bank sends Webhook Callback -> POST /api/payments/aba/callback/
[Django Webhook Handler]
        │
        ▼ 5. Validates amount, currency, merchant reference & signature
[Payment marked PAID] ──▶ [Order marked CONFIRMED]
        │
        ▼ 6. Flutter non-blocking poll or "I've Paid" triggers refresh
[Flutter Order Success Screen]
```

## Security Rules
- Flutter **NEVER** marks an order as paid.
- Amount is strictly recalculated from database order items.
- Duplicate callbacks are processed idempotently.
