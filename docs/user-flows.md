# FoodGo — End-to-End User Journeys & Flow Architecture

**Project**: [Ratanazen/FoodGo](https://github.com/Ratanazen/FoodGo)  
**Date**: October 20, 2026  
**Status**: Verified  

---

## 1. Customer Journey Flow

```mermaid
sequenceDiagram
    autonumber
    actor C as Customer
    participant F as Flutter Web/Mobile
    participant B as Django Backend
    participant PG as Payment Gateway (Bakong/ABA/ACLEDA)
    participant D as Courier Driver

    C->>F: Select Food Item & Special Instructions
    F->>F: Add to Cart (Item bounce animation)
    C->>F: Proceed to Checkout
    F->>B: POST /api/orders/ (items, restaurant, address, instructions)
    B-->>F: Order Created (#FG-ORD-1234, UNPAID)
    C->>F: Select Payment (ABA / Bakong / ACLEDA KHQR)
    F->>B: POST /api/payments/create/ (order_id, provider='ABA')
    B->>B: Generate EMVCo Dynamic KHQR with CRC16
    B-->>F: Return Payment Record with qr_payload & 5-min expiry
    F->>C: Display QRPaymentScreen (QR code + Countdown Timer)
    C->>PG: Scan KHQR with ABA Mobile / Bakong App & Pay
    PG->>B: Webhook POST /api/payments/aba/callback/ (signed)
    B->>B: select_for_update() + Verify Amount & Currency
    B->>B: Update Payment PAID, Order confirmed
    B-->>PG: 200 OK (Idempotent)
    F->>B: Poll /api/payments/<id>/status/
    B-->>F: Status is PAID!
    F->>C: Navigate to OrderSuccessScreen (Confetti, Cart Cleared)
    C->>F: View Live Order Tracking (Polyline & Courier GPS)
    D->>C: Doorstep Delivery Handover QR
    C->>F: Scan Delivery QR or Input 6-Digit PIN
    F->>B: POST /api/orders/<id>/confirm_delivery/
    B-->>F: Order status marked DELIVERED
```

### 1.1 Recovery & Error Paths
- **Unpaid Order Resumption**: If a customer navigates away or loses connection during payment, they can visit `/orders`, locate the unpaid order, and tap **"Complete Payment (KHQR)"** to resume without placing duplicate orders.
- **QR Expiration**: When the 5-minute window expires, the countdown displays `Payment QR Expired`. The customer can tap **"Regenerate QR"** or return to checkout safely.
- **Insufficient Wallet Balance**: If paying via FoodGo Wallet and the balance is below the order total, an alert prompt directs the user to "My QR" top-up or an alternative KHQR payment method.

---

## 2. Driver Journey Flow

```mermaid
graph TD
    DLogin[Driver Login] --> DDash[Driver Dashboard]
    DDash --> DStatus[Toggle Online Status]
    DStatus --> DOrders[View Assigned Orders]
    DOrders --> DNav[Inspect Order & Map Route]
    DNav --> DPickup[Arrive at Restaurant & Pick Up]
    DPickup --> DTransit[In Transit - Live GPS Broadcast via WebSocket]
    DTransit --> DDoorstep[Arrived at Customer Doorstep]
    DDoorstep --> DQR[Present Handover QR Modal with Backup PIN]
    DQR --> DConfirm[Customer Scans QR or Driver Enters PIN]
    DConfirm --> DDelivered[Order Marked Delivered & Earnings Credited]
```

---

## 3. Administrator Journey Flow

```mermaid
graph TD
    AdminLogin[Admin Login] --> Console[Admin Console / Dashboard]
    Console --> Tab1[1. Analytics Overview - Orders, Revenue USD/KHR, Health]
    Console --> Tab2[2. Orders Management - Search, Filter, Assign Driver, Cancel]
    Console --> Tab3[3. Payments Management - Search, Filter, Audit, Refund]
    Console --> Tab4[4. User Directory - Search, Filter by Role, Toggle Active]
    Console --> Tab5[5. Restaurant Directory - Active Toggles, Ratings]
    Console --> Tab6[6. Audit Logs - Server-side Traceability & IP Logging]
```

### 3.1 Security & Fraud Prevention
- **Authorization**: All administrative routes enforce `IsAdminOrStaff` on the backend.
- **Server-Side Verification**: Administrators cannot arbitrarily flip payment status from unverified to paid without authoritative provider callbacks or banking reconciliation.
- **Audited Refunds**: Initiating a refund triggers provider refund APIs, reverts order payment status to `REFUNDED`, and generates an immutable record in `AuditLog` containing administrative user ID, timestamp, and client IP.
