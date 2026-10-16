# Secure Delivery Confirmation QR & PIN System Documentation

**Version:** 3.0.0-PROD  
**Date:** October 2026  
**Repository:** [https://github.com/Ratanazen/FoodGo](https://github.com/Ratanazen/FoodGo)  

---

## 1. System Architecture

The FoodGo Delivery Confirmation system prevents courier fraud, false non-delivery claims, and delivery handover disputes by cryptographically proving physical co-presence between the customer and driver at the delivery point.

```
+---------------------+                      +---------------------+
|      Driver App     |                      |     Customer App    |
| (Dashboard Screen)  |                      |  (Orders / Map UI)  |
+----------+----------+                      +----------+----------+
           |                                            |
           | 1. Tap "Arrived at Customer"               |
           v                                            |
+---------------------+                                 |
| Django Backend API  |                                 |
|  POST /delivery_qr/ |                                 |
+----------+----------+                                 |
           |                                            |
           | 2. Returns 32-byte secure token + PIN      |
           v                                            |
+---------------------+                                 |
|  DeliveryQrModal    |                                 |
| Displays QR + 6 PIN |                                 |
+----------+----------+                                 |
           |                                            |
           | 3. Customer scans driver screen            |
           |    (or enters 6-digit backup PIN)          |
           +------------------------------------------->+
                                                        | 4. Tap "Confirm"
                                                        v
                                             +---------------------+
                                             | Django Backend API  |
                                             | POST /confirm_deliv/|
                                             +----------+----------+
                                                        |
                                                        | 5. select_for_update()
                                                        |    Marks 'delivered'
                                                        |    Preserves payment
                                                        v
                                             +---------------------+
                                             | Both Apps Instantly |
                                             |   Show Receipt UI   |
                                             +---------------------+
```

---

## 2. Security Standards & Guarantees

### 2.1 Cryptographic Randomness
- Tokens are generated using the host OS CSPRNG:
  ```python
  import secrets
  secure_token = secrets.token_urlsafe(32) # 256 bits entropy
  pin = f"{secrets.randbelow(900000) + 100000}" # 6-digit decimal PIN
  ```
- No sequential or predictable timestamps are used as seeds.

### 2.2 Payload Privacy (Zero PII)
- QR payloads strictly avoid customer names, phone numbers, delivery addresses, passwords, or payment credentials.
- Standard format:
  ```
  FOODGO:DELIVERY:CONFIRM:v1?order_id=42&token=x8K_mQ92LpZ-38sA91Bw77rT10yU99qW
  ```

### 2.3 Strict Driver & Customer Bindings
- **Generation:** Only the assigned courier (`delivery.driver.user_id == request.user.id`) or staff can generate the active delivery token.
- **Confirmation:** Only the order owner or assigned driver can confirm delivery. Third-party users receive `403 Forbidden`.

### 2.4 Single-Use Anti-Replay Defense
- Tokens are enforced single-use. Once verified:
  - `token_obj.is_used = True`
  - `token_obj.used_at = timezone.now()`
  - `token_obj.confirmed_by = request.user`
  - Re-scanning an already-used token returns an idempotent `ALREADY_DELIVERED` status without re-executing state changes.

### 2.5 Short-Lived Expiration
- Tokens expire after 15 minutes. Expired tokens are rejected with `400 Bad Request`.
- If expired, drivers can regenerate a fresh token via the "Refresh" action button.

### 2.6 Independence of Payment Status
- Handover confirmation marks `order.status = 'delivered'` and `delivery.status = 'delivered'`.
- It **never** alters `order.payment_status`. Unpaid orders remain `UNPAID` until settled via payment gateways or cash collection.

---

## 3. Supported Handover Workflows

### 3.1 Primary Workflow: Driver Displays QR $\to$ Customer Scans
1. Driver arrives and taps "Arrived at Customer" in `DriverDashboardScreen`.
2. Driver app displays `DeliveryQrModal` featuring the QR code and 6-digit PIN.
3. Customer opens `DeliveryScannerModal` on `OrdersScreen` or `MapScreen` and scans the QR code.
4. Backend confirms delivery; both apps update to `delivered`.

### 3.2 Alternative Workflow: Customer Displays QR $\to$ Driver Scans
- If configured or preferred, the customer displays their order handover QR, and the driver scans it using the scanner modal or enters the PIN.
- The backend accepts confirmation requests from either party.

### 3.3 Offline / Low-Light Fallback: 6-Digit PIN Entry
- In dim lighting, cracked camera lenses, or camera permission denials, the customer asks the driver for the 6-digit backup PIN shown on the driver's phone.
- The customer enters the PIN into the "Enter 6-Digit PIN" tab in `DeliveryScannerModal`.

### 3.4 Support / Manual Override Fallback
- If the customer's phone battery is depleted, the administrator can clear the delivery manually:
  ```http
  POST /api/orders/42/support_confirm_delivery/
  Content-Type: application/json
  Authorization: Bearer <admin_token>

  {
    "reason": "Customer phone battery depleted; verified with concierge"
  }
  ```
- The backend logs the override reason into `token_obj.user_agent` for full auditability.
