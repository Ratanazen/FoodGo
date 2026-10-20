# FoodGo — Complete Web & Mobile UI/UX, Flow & Architecture Audit

**Repository**: [Ratanazen/FoodGo](https://github.com/Ratanazen/FoodGo)  
**Date**: October 20, 2026  
**Role**: Senior Full-Stack Developer, UI/UX Designer, Mobile & Web Engineer, QA Engineer  

---

## 1. Executive Summary & Architecture Overview

FoodGo is a unified, multi-platform food delivery and ordering ecosystem built with **Flutter 3.x / Dart 3.x** on the frontend (serving responsive Web, Android, iOS, and Desktop) and **Django 5.1+ / Django REST Framework (DRF)** on the backend, powered by **Daphne ASGI** for real-time WebSocket telemetry, and **PostgreSQL 15** for relational persistence.

```mermaid
graph TD
    ClientWeb[Flutter Web / Mobile App] -->|HTTPS REST API| DjangoBackend[Django 5.1+ REST Framework]
    ClientWeb -->|WSS Real-Time Telemetry| DaphneASGI[Daphne ASGI Channels]
    DjangoBackend --> DB[(PostgreSQL 15 Database)]
    DjangoBackend --> PaymentGateway[NBC Bakong KHQR / ABA PayWay / ACLEDA]
    DaphneASGI --> InMemory[Channels Layer]
```

### 1.1 Web Frontend Architecture
- **Framework**: Flutter Web (CanvasKit / HTML renderer).
- **Responsive System**: Custom `ResponsiveLayout` with breakpoints for Mobile (`< 600px`), Tablet (`600px - 1024px`), Desktop (`1024px - 1440px`), and Ultra-Wide (`> 1440px`).
- **State Management**: MultiProvider architecture (`CartProvider`, `AdminProvider`, `AuthProvider`, `RestaurantProvider`, `AddressProvider`, `NotificationProvider`, `FavoritesProvider`, `CurrencyProvider`, `ThemeProvider`).
- **Routing**: `go_router` 14.8.1 with deep linking, query parameters, and animated sub-routes.
- **Zero-Emoji Policy**: 100% vector Material Icons (`Icons.*`) and SVG assets (`SvgAssetIcon`). Zero raw unicode emoji characters.

### 1.2 Backend Framework & Services
- **API Engine**: Django REST Framework with SimpleJWT bearer token authorization.
- **Role Hierarchy**: `customer`, `restaurant_owner`, `driver`, `admin` (superuser/staff).
- **Payment Engine**: Strategy pattern with Cambodian payment gateway providers: `BakongKHQRProvider` (NBC Open API), `ABAKHQRProvider` (PayWay), `ACLEDAKHQRProvider` (x-Pay), `WalletPaymentProvider` (in-app balance), and `CODProvider`.

---

## 2. Comprehensive Defect & Finding Log

| Issue ID | Severity | Category | Affected File(s) | Root Cause | Remediation & Verification |
| :--- | :---: | :--- | :--- | :--- | :--- |
| **AUD-01** | **CRITICAL** | QR Payment | `backend/core/payments/aba.py`<br>`backend/core/payments/acleda.py` | Hardcoded dummy CRC16 checksums (`ABCD`, `5678`) in EMVCo KHQR string, rejecting scans in banking apps. | Replaced with dynamic mathematical CRC16-CCITT algorithm and TLV formatting in `utils.py`. Verified via checksum test. |
| **AUD-02** | **HIGH** | Admin Console | `backend/core/admin_views.py`<br>`backend/core/tests_admin.py` | Admin analytics filtered payments by `status='COMPLETED'`, but the model definition is `'PAID'`, resulting in `$0.00` calculated revenue. | Fixed filter to `status='PAID'`. Revenue computes accurately in both USD and KHR. |
| **AUD-03** | **HIGH** | Admin Feature | `backend/core/admin_views.py`<br>`backend/core/urls.py` | Missing `AdminPaymentViewSet`. Administrators had no dedicated API to search, filter, or audit payment transactions or issue authorized refunds. | Created `AdminPaymentViewSet` with status/provider filtering, search, and refund action logged to `AuditLog`. |
| **AUD-04** | **HIGH** | Concurrency | `backend/core/payment_views.py` | `CreatePaymentView` and `BaseCallbackView` lacked row-level locking (`select_for_update`), permitting duplicate payment intents or race conditions during callbacks. | Wrapped order lookup in `select_for_update()` and handled prior payments gracefully using `update_or_create()`. |
| **AUD-05** | **MEDIUM** | UX / Order Flow | `foodgo_flutter/.../orders_screen.dart` | Unpaid orders displayed `Payment Status: UNPAID` with no button to re-open the KHQR payment modal or pay. | Added "Complete Payment (KHQR)" action button directly on unpaid order cards. |
| **AUD-06** | **MEDIUM** | Admin Frontend | `foodgo_flutter/.../admin_dashboard_screen.dart`<br>`foodgo_flutter/.../admin_provider.dart` | Admin console lacked a dedicated Payments tab to view transactions, payment methods, and execute refunds. | Added 6th tab **Payments** in `AdminDashboardScreen` with search, status filters, and refund modal. |
| **AUD-07** | **MEDIUM** | State Machine | `backend/core/payment_views.py` | `PaymentStatusView` handled only `PAID` and `EXPIRED` transitions; `FAILED` or `CANCELLED` left the order and payment in ambiguous pending states. | Expanded status transitions to handle `FAILED`, `CANCELLED`, `EXPIRED`, and `PAID` atomically. |
| **AUD-08** | **LOW** | Web Responsiveness | `foodgo_flutter/.../qr_payment_screen.dart` | Fixed width on desktop screens caused excessive whitespace on wide displays. | Applied `ResponsiveLayout` container with maximum content width constraints. |

---

## 3. Disambiguation of QR Protocols

1. **Customer Payment QR** (`QRPaymentScreen`):
   - Generated dynamically on backend via `/api/payments/create/`.
   - Formatted in compliance with National Bank of Cambodia (NBC) EMVCo KHQR specification.
   - Authoritative amount retrieved from backend; 5-minute countdown expiration.
   - Polling checks `/api/payments/<id>/status/` until state becomes `PAID`.
2. **Doorstep Delivery Handover QR** (`DeliveryQrModal`):
   - Generated on backend via `/api/orders/<id>/delivery_qr/` for courier proof of delivery.
   - Encodes a 256-bit cryptographically secure token and 6-digit backup PIN.
   - Customer or courier scans at physical handover, marking order `delivered`.
3. **P2P Wallet "My QR"** (`MyQrModal`):
   - User's static/dynamic personal QR code for balance top-up or peer-to-peer transfers.

---

## 4. Design System Compliance & Zero-Emoji Audit
- **Zero-Emoji Policy**: 100% verified. Zero raw unicode emojis across all repository files.
- **GlassTheme Tokens**:
  - Primary Green: `#4CAF50` / Neon Lime Accent: `#CCFF00`
  - Dark Surface: `#121212` / Background Dark: `#0A0E0D`
  - NBC Bakong Red: `#EF4444` / ABA Blue: `#003E7E` / ACLEDA Navy: `#003366`
- **Typography**: Google Fonts (Poppins / Inter) with fallback to system sans-serif.
