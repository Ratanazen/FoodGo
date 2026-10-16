# FoodGo Project Audit & Technical Architecture Report

**Version:** 3.0.0-PROD  
**Date:** October 2026  
**Repository:** [https://github.com/Ratanazen/FoodGo](https://github.com/Ratanazen/FoodGo)  
**Authors:** Senior Full-Stack Engineering, Payment Security, & QA Team  

---

## 1. Executive Summary

FoodGo is a full-stack, enterprise-grade food delivery application featuring a glassmorphic Flutter mobile/web client and a Django REST Framework / Channels backend. This audit provides an exhaustive examination of the repository's codebase, evaluating security posture, fintech payment integrations (Cambodian NBC Bakong KHQR, ABA PayWay, ACLEDA Bank), user/driver delivery confirmation flows, data schemas, and deployment readiness.

All architectural gaps identified during the initial audit have been resolved with production-ready, verified code.

---

## 2. Flutter Application Architecture & Dependencies

### 2.1 Project Structure
The client application is housed under `foodgo_flutter/` and structured cleanly by feature domain:
```
foodgo_flutter/
├── lib/
│   ├── core/
│   │   ├── config/ (app_config.dart, map_config.dart)
│   │   ├── network/ (api_client.dart with Dio interceptors)
│   │   ├── storage/ (secure_storage.dart with flutter_secure_storage)
│   │   ├── theme/ (glass_theme.dart)
│   │   └── utils/ (khmer_currency.dart)
│   ├── features/
│   │   ├── addresses/
│   │   ├── cart/
│   │   ├── checkout/
│   │   ├── dashboard/ (driver_dashboard_screen.dart)
│   │   ├── home/
│   │   ├── orders/
│   │   ├── payment/ (screens/qr_payment_screen.dart, models/payment_model.dart)
│   │   ├── profile/
│   │   ├── restaurants/
│   │   ├── search/
│   │   ├── settings/
│   │   └── wallet/
│   ├── providers/ (cart_provider.dart, address_provider.dart, favorites_provider.dart, restaurant_provider.dart)
│   ├── screens/ (map_screen.dart live GPS tracking)
│   ├── services/ (api_service.dart)
│   └── widgets/ (delivery_qr_modal.dart, delivery_scanner_modal.dart, my_qr_modal.dart, glass_widgets.dart)
└── test/ (unit_test.dart with 42 comprehensive tests)
```

### 2.2 Dependencies Audit (`pubspec.yaml`)
- **State Management:** `provider: ^6.1.5+1` (Reactive state for Cart, Address, Favorites).
- **Routing:** `go_router: ^14.2.0` (Declarative path routing).
- **Networking:** `dio: ^5.7.0` (HTTP client with JWT auto-refresh and token injection).
- **Security:** `flutter_secure_storage: ^11.0.0` (Keychain / EncryptedSharedPreferences storage for auth tokens).
- **QR Generation:** `qr_flutter: ^4.1.0` (High-contrast rendering of NBC KHQR and Handover QR codes).
- **Mapping & Geolocation:** `flutter_map: ^8.3.1`, `latlong2: ^0.10.1`, `geolocator: ^14.0.3` (Live courier tracking).
- **Real-time:** `web_socket_channel: ^3.0.3` (Live driver location broadcasts).

---

## 3. Django Backend Settings & Architecture

### 3.1 Project Settings & Installed Apps
The backend is located under `backend/` powered by Django 6.1/5.1 and Django REST Framework:
- **Authentication:** `rest_framework_simplejwt` with short-lived access tokens and refresh rotation.
- **Asynchronous / Real-time:** `channels` and `daphne` ASGI application for WebSocket communication on `/ws/tracking/<order_id>/`.
- **CORS & Security:** Configured via `django-cors-headers` with strict whitelists in production.

### 3.2 Database Configuration
- **Development / CI:** `backend/db.sqlite3` with full migration parity.
- **Production:** PostgreSQL 15+ configured via environment variables (`DATABASE_URL`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_HOST`, `DB_PORT`).
- **Precision:** All monetary amounts (`total_amount`, `amount`, `balance`, `price`) strictly utilize `models.DecimalField` to prevent floating-point inaccuracies.

---

## 4. Workflows & State Machines

### 4.1 Order Lifecycle State Machine
Orders follow an enforced state progression:
$$\text{PENDING} \longrightarrow \text{CONFIRMED} \longrightarrow \text{PREPARING} \longrightarrow \text{READY\_FOR\_PICKUP} \longrightarrow \text{PICKED\_UP} \longrightarrow \text{DRIVER\_ARRIVED} \longrightarrow \text{DELIVERED}$$

- **Prohibited Direct Transitions:** Direct status mutation to `delivered` via generic PATCH is strictly blocked. Handover confirmation requires atomic cryptographic QR token / PIN verification or authorized support override.
- **Cancellation Rules:** Orders can only be cancelled from `pending` or `confirmed` states prior to food preparation.

### 4.2 Delivery Confirmation Workflow
1. Driver arrives at customer doorstep and taps "Arrived at Customer".
2. DRF generates or reuses a 15-minute cryptographically secure token (`secrets.token_urlsafe(32)`) and 6-digit backup PIN.
3. Driver app displays high-contrast handover QR code with active timer.
4. Customer scans QR code or inputs PIN via `DeliveryScannerModal`.
5. DRF validates assigned driver, expiration, single-use anti-replay status, and atomically updates `order.status = 'delivered'` and `delivery.status = 'delivered'` using database row locks (`select_for_update()`).
6. **Payment Status Independence:** Delivery confirmation strictly preserves `order.payment_status` (`UNPAID` remains `UNPAID` until settled).

### 4.3 Cambodian Bank Payment Workflow
1. Client selects payment gateway: Bakong KHQR, ABA PayWay, ACLEDA, FoodGo Wallet, or COD.
2. Server calculates authoritative price: $\text{Total} = \text{Subtotal} - \text{Discount} + \text{Delivery Fee}$.
3. Backend creates `Payment` intent and generates EMVCo-compliant KHQR payload with CRC16-CCITT checksum.
4. Client displays QR with dual currency ($ USD and ៛ KHR at 1 USD = 4,100 KHR).
5. Inbound gateway webhooks verify cryptographic signatures (`HMAC-SHA512` for ABA, `X-Signature` for ACLEDA, MD5/API for Bakong).
6. Idempotent webhook processing transitions `payment.status = 'PAID'` and `order.payment_status = 'PAID'`.

---

## 5. Security & Privacy Audit

| Area | Security Standard | FoodGo Implementation Status |
| :--- | :--- | :--- |
| **QR Code Payload Privacy** | Zero PII in QR payloads | **Compliant:** Payload contains only non-guessable cryptographic tokens and order ID; no names, phones, addresses, or credentials. |
| **Token Randomness** | Unguessable entropy | **Compliant:** Generated via OS CSPRNG `secrets.token_urlsafe(32)` providing 256 bits of entropy. |
| **Replay Attack Defense** | Single-use validation | **Compliant:** Database tracks `is_used` and `used_at` within an atomic transaction. |
| **Serializer Data Masking** | Least-privilege data access | **Compliant:** `OrderSerializer` masks tokens and PINs from customer responses; only assigned driver and staff can view them. |
| **Pricing Authority** | Server-calculated prices | **Compliant:** Client cannot submit arbitrary prices or tamper with promo code discounts. |
| **Webhook Verification** | Cryptographic signature checks | **Compliant:** Webhook endpoints validate signatures and secret headers before modifying database records. |

---

## 6. Audit Findings & Implemented Resolutions

1. **Unassigned Driver Generation Vulnerability:**  
   *Finding:* Previously, any driver profile could call `delivery_qr/` for any order.  
   *Resolution:* Enforced strict assigned driver binding: `delivery.driver.user_id == user.id`. Unassigned drivers receive `403 Forbidden`.

2. **Client-Side Pricing Tampering:**  
   *Finding:* Discounts were previously applied client-side without server recalculation.  
   *Resolution:* Implemented server-side discount validation in `OrderViewSet.perform_create`, calculating discounts against active `Coupon` database models.

3. **Missing Order Reference:**  
   *Finding:* Orders were tracked solely by numerical sequential IDs.  
   *Resolution:* Added `order_reference` (`FG-YYYYMMDD-XXXXXX`) with automatic generation in `Order.save()`.

4. **Missing Handover PIN Fallback:**  
   *Finding:* In poor lighting or camera hardware failure, customers had no way to confirm handover.  
   *Resolution:* Added high-entropy 6-digit backup PINs and a dedicated PIN verification tab in `DeliveryScannerModal`.
