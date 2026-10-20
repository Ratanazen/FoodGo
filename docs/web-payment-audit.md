# FoodGo — Web App & Payment Architecture Audit

**Repository**: [Ratanazen/FoodGo](https://github.com/Ratanazen/FoodGo)  
**Date**: October 20, 2026  
**Auditor**: Full-Stack Senior Web & Payment Integration Engineer  

---

## 1. Verified Architecture Overview

### 1.1 Web Frontend
- **Framework**: Flutter 3.24+ / Dart 3.5+ compiling to Flutter Web (HTML5/CanvasKit/Wasm with Shelf web-server in debug/dev, Nginx multi-stage Alpine in production Docker).
- **State Management & Routing**: `provider` (8 providers: `CartProvider`, `AdminProvider`, `AuthProvider`, `RestaurantProvider`, `AddressProvider`, `NotificationProvider`, `FavoritesProvider`, `CurrencyProvider`) and `go_router` (14.8.1).
- **Design System & Tokens**: Custom `GlassTheme` frosted-glass design system with primary colors (`#4CAF50` green, `#EF4444` NBC Bakong red, `#003E7E` ABA blue, `#003366` ACLEDA navy).
- **Icons & Assets**: 100% Vector Material Icons (`Icons.*`) and SVG assets (`SvgAssetIcon`), strictly conforming to the project's Zero-Emoji Policy.
- **QR Rendering**: `qr_flutter` (4.1.0) generating client-side vector QRs from authoritative EMVCo/KHQR payload strings.

### 1.2 Backend API & Database
- **Framework**: Django 5.1+ and Django REST Framework (DRF) 3.15+.
- **ASGI & WebSocket Server**: Daphne ASGI server running on port 8000 with Django Channels (`InMemoryChannelLayer` for local dev/testing, Redis for scaled production).
- **Database**: PostgreSQL (production on Render/Supabase/Neon) with SQLite fallback for offline local testing.
- **Authentication**: JWT authentication (`rest_framework_simplejwt`) with HTTP-only tokens, Bearer token headers, and role-based permissions (`customer`, `restaurant_owner`, `driver`, `admin`/`staff`).
- **Payment Architecture**: Strategy pattern (`PaymentProvider` base class) with provider implementations:
  - `BakongKHQRProvider`: National Bank of Cambodia (NBC) Bakong Open API with MD5 transaction tracking.
  - `ABAKHQRProvider`: ABA Bank PayWay / KHQR integration.
  - `ACLEDAKHQRProvider`: ACLEDA Bank x-Pay / KHQR integration.
  - `WalletPaymentProvider`: In-app prepaid digital wallet balance.
  - `CODProvider`: Cash on Delivery workflow.

---

## 2. QR Code Architecture Disambiguation

The audit verified three distinct, non-overlapping QR flows in FoodGo:

| QR Type | Component / Screen | Purpose | Endpoint / Payload |
| :--- | :--- | :--- | :--- |
| **Payment QR** | `QRPaymentScreen` | Customer pays for order via Cambodian banking app (Bakong, ABA, ACLEDA) | Dynamic EMVCo KHQR payload (`00020101...`) from `/api/payments/create/` |
| **Delivery Handover QR** | `DeliveryQrModal` | Driver presents at doorstep; Customer scans to confirm order received | Time-limited OTP token (`FOODGO:DELIVERY:CONFIRM:...`) from `/api/orders/<id>/delivery_qr/` |
| **P2P Wallet "My QR"** | `MyQrModal` | Customer receives peer balance transfer or tops up wallet | Dynamic KHQR with account ID (`customer@bkrt`) or top-up tag (`TOPUP-<user_id>`) |

> **Critical Rule**: Under no circumstances should the delivery confirmation QR flow be reused or mixed with the customer payment QR flow.

---

## 3. Discovered Defects and Root Cause Analysis

### Defect 1: Dummy CRC16 Checksum in ABA and ACLEDA KHQR Generation
- **Files**: `backend/core/payments/aba.py` (Line 36), `backend/core/payments/acleda.py` (Line 26)
- **Root Cause**: While `bakong.py` implemented a full CRC16-CCITT algorithm, `aba.py` hardcoded `6304ABCD` and `acleda.py` hardcoded `63045678`. Furthermore, Tag 62 (Additional Data) omitted the EMVCo sub-tag `01` (Bill Number).
- **Impact**: Real Cambodian banking apps (ABA Mobile, ACLEDA, Bakong, Wing) validate the EMVCo CRC16 checksum upon camera scan and reject any QR with an incorrect checksum.
- **Fix**: Centralize the standard NBC EMVCo CRC16-CCITT checksum algorithm and TLV formatting in a shared helper, ensuring 100% mathematically valid KHQR strings for ABA, ACLEDA, and Bakong.

### Defect 2: Admin Analytics Always Reports $0.00 Revenue
- **File**: `backend/core/admin_views.py` (Line 33), `backend/core/tests_admin.py` (Line 78)
- **Root Cause**: `admin_views.py` filtered payments with `status='COMPLETED'`. However, `Payment.STATUS_CHOICES` defines `'PAID'`, `'PENDING'`, `'FAILED'`, `'EXPIRED'`, `'CANCELLED'`, `'REFUNDED'`. The status `'COMPLETED'` does not exist in the database model.
- **Impact**: All revenue queries in the Admin Overview returned `0.00 USD` even after successful payments were verified.
- **Fix**: Update `Payment.objects.filter(status='PAID')` in both `admin_views.py` and `tests_admin.py`.

### Defect 3: Missing Admin Payment Management ViewSet
- **Files**: `backend/core/admin_views.py`, `backend/core/urls.py`
- **Root Cause**: The backend provided admin ViewSets for Orders, Users, Restaurants, and Audit Logs, but lacked a dedicated `AdminPaymentViewSet`.
- **Impact**: The admin console had no API to list payment transactions, filter by payment status (`PAID`, `PENDING`, `EXPIRED`, `FAILED`, `CANCELLED`), search by transaction ID, or trigger an authorized administrative refund.
- **Fix**: Implement `AdminPaymentViewSet` with filtering, searching, pagination, and a server-authorized refund action (`/api/admin/payments/<id>/refund/`), logging all actions to `AuditLog`.

### Defect 4: Missing Payment Creation Concurrency Locks and Hard Deletes
- **File**: `backend/core/payment_views.py` (`CreatePaymentView`)
- **Root Cause**: `Payment.objects.filter(order=order).delete()` executed a hard delete on prior payment records to avoid OneToOne violations, destroying historical records, and did not lock the `Order` row using `select_for_update()`.
- **Impact**: Concurrent checkout requests could create duplicate payments or crash due to race conditions.
- **Fix**: Lock the order record using `Order.objects.select_for_update()`, check order payment eligibility, cancel previous pending payments gracefully, and maintain audit records.

### Defect 5: Unpaid Order Payment Recovery in Orders Screen
- **File**: `foodgo_flutter/lib/features/orders/presentation/orders_screen.dart`
- **Root Cause**: When a customer created an order with KHQR payment but exited the screen before completing payment, the order card showed `Payment Status: UNPAID`, but provided no button to re-open the KHQR payment modal or complete payment.
- **Impact**: Customers had no in-app mechanism to resume payment for an unpaid order.
- **Fix**: Add a "Pay with KHQR" button to unpaid orders in `orders_screen.dart` that fetches or generates the payment and navigates to `QRPaymentScreen`.

### Defect 6: Webhook Concurrency and Idempotency Guard
- **File**: `backend/core/payment_views.py` (`BaseCallbackView`)
- **Root Cause**: Webhook callbacks processed payment status updates without row-level locking (`select_for_update()`).
- **Impact**: Duplicate webhook hits from gateways could trigger simultaneous status transitions or double wallet credits.
- **Fix**: Wrap callback processing in `transaction.atomic()` with `select_for_update()` on the `Payment` model and verify that the payment is not already in terminal `PAID` state.

---

## 4. Implementation Roadmap
1. **EMVCo & KHQR Engine Hardening**: Unify TLV and CRC16-CCITT generation across all providers (`Bakong`, `ABA`, `ACLEDA`).
2. **Backend Concurrency & State Machine**: Apply `select_for_update()`, expand payment state transitions (`PENDING`, `PAID`, `FAILED`, `CANCELLED`, `EXPIRED`, `REFUNDED`), and ensure idempotency.
3. **Admin Backend API**: Add `AdminPaymentViewSet` with search, filter, pagination, and refund capabilities.
4. **Admin Frontend Console**: Add a dedicated **Payments** tab to `AdminDashboardScreen` and integrate with `AdminProvider`.
5. **Customer Web UX**: Add "Pay with KHQR" to unpaid orders in `orders_screen.dart`, enhance empty/loading/error states.
6. **Automated Test Suite Expansion**: Comprehensive backend and frontend tests covering edge cases, idempotency, CRC validation, and admin features.
7. **Production & Hosting Verification**: Run all tests, linters, and verify Docker/CI configurations.
