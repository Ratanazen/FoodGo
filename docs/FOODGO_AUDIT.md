# 🔍 FoodGo v2 → v3 — Full Repository & Architecture Audit

**Audit Date:** September 22, 2026  
**Repository:** [https://github.com/Ratanazen/FoodGo.git](https://github.com/Ratanazen/FoodGo.git)  
**Target Roadmap:** FoodGo v2 (Stable Customer MVP) ➔ FoodGo v3 (Full Multi-Role Cambodian Food Delivery Platform)  
**Audited Components:** `backend/`, `foodgo_flutter/`, `docker-compose.yml`, `.github/workflows/ci.yml`, `.env.example`, `README.md`

---

## 1. Executive Summary & Verification Pass

| Verification Step | Target Command | Result | Status |
| :--- | :--- | :--- | :--- |
| **Django System Check** | `python manage.py check` | `System check identified no issues (0 silenced)` | 🟢 PASSED (0 issues) |
| **Django Database Check** | `python manage.py makemigrations --check` | `No changes detected` | 🟢 PASSED |
| **Django Test Suite** | `python manage.py test` | `Ran 13 tests in 7.391s: OK` | 🟢 PASSED (13/13) |
| **Flutter Dependencies** | `flutter pub get` | Dependencies resolved, `qr_flutter` & `web_socket_channel` loaded | 🟢 PASSED |
| **Flutter Static Analysis**| `flutter analyze` | `No issues found! (ran in 1.4s)` | 🟢 PASSED (0 issues) |
| **Flutter Test Suite** | `flutter test` | `All tests passed!` (CartProvider & PaymentModel) | 🟢 PASSED |

---

## 2. Existing Architecture Overview

```
FOODGO PLATFORM
│
├── Flutter Client (Customer, Restaurant Owner, Driver)
│   ├── UI (Glassmorphic Theme, Material 3, Constrained 450px Web Mobile Shell)
│   ├── Providers (Auth, Cart, Restaurant, User, Theme)
│   ├── GoRouter (State-driven authentication guards & ShellRoute)
│   ├── Storage (flutter_secure_storage with encryption)
│   └── Dio API Client (JWT Bearer interceptor, refresh token handshake)
│
▼
Django REST Framework (Daphne ASGI Server)
│   ├── Authentication & Role-Based Permissions (Customer, Restaurant Owner, Driver, Admin)
│   ├── Business Services (PaymentService, Recommendation Engine, Driver Tracking Consumer)
│   └── Database Engine (PostgreSQL / SQLite fallback)
│
├── Real-Time Layer (WebSockets via Django Channels + Redis)
│   └── /ws/tracking/<order_id>/ for driver GPS streaming
│
└── Payment Gateway Layer
    ├── ABA KHQR Provider (Dynamic NBC standard KHQR string generator)
    ├── ACLEDA KHQR Provider (Partner merchant dynamic payload generator)
    └── Cash on Delivery (COD Provider with atomic status transitions)
```

---

## 3. Comprehensive Module Audit

### 3.1 Authentication & Profile (v2.0)
- **Implemented:**
  - Standard username/password registration (`/api/register/`) and JWT acquisition (`/api/token/`, `/api/token/refresh/`).
  - Mobile phone OTP login (`/api/auth/phone-login/request/` and `/verify/`).
  - Secure token storage on mobile/web via `flutter_secure_storage`.
  - User profile endpoint (`/api/me/`) fetching current user details, role, and addresses.
  - Startup flow routing: `SplashScreen` routes active sessions directly to `/home`, and unauthenticated users to `/login`.
- **Known Limitations:**
  - In development mode, the OTP verification uses a sandbox code (`1234`). Production requires a real SMS gateway (e.g. Twilio or Plasgate).

### 3.2 Food & Restaurant Catalog (v2.1)
- **Implemented:**
  - `RestaurantViewSet` with prefetching of `food_categories` and `items`.
  - Filterable and searchable foods (`FoodItemViewSet`).
  - Dynamic detail screen for restaurants with category filter tabs.
  - Food item customization (special instructions, quantity).

### 3.3 Cart, Addresses & Checkout (v2.2)
- **Implemented:**
  - In-memory responsive `CartProvider` synced with backend `Cart` and `CartItem` models.
  - Server-authoritative price and total calculation in `OrderViewSet` (never trusting client math).
  - Address model and address management screens with default address flags.
  - Checkout screen providing real-time selection between **ABA KHQR**, **ACLEDA KHQR**, and **Cash on Delivery (COD)**.

### 3.4 KHQR Payment System (v2.3 / v3.3)
- **Implemented:**
  - Extensible `PaymentProvider` interface in `backend/core/payments/base.py`.
  - `ABAKHQRProvider` (`aba.py`) generating dynamic NBC standard KHQR strings (`00020101...`).
  - `ACLEDAKHQRProvider` (`acleda.py`) generating dynamic ACLEDA partner KHQR strings.
  - `CODProvider` (`cod.py`) enabling Cash on Delivery with immediate order confirmation.
  - Database schema (`Payment` model) tracking `provider`, `method`, `merchant_reference`, `transaction_id`, `amount`, `currency`, `qr_payload`, `status`, `expires_at`, `paid_at`, `provider_response`.
  - Idempotent callback endpoints (`/api/payments/aba/callback/` and `/api/payments/acleda/callback/`).
  - Flutter `QRPaymentScreen` rendering dynamic QR via `qr_flutter`, with countdown timer, non-blocking polling, and "I've Paid" server-side status inquiry.
- **Provider Status:**
  - Sandbox mode active (`PAYMENT_ENV=sandbox`).
  - Official merchant onboarding credentials (ABA Merchant ID / ACLEDA Partner ID) are configurable via `.env` and currently run with developer sandbox keys.

### 3.5 Orders & Tracking (v2.4 / v3.2)
- **Implemented:**
  - Status progression: `pending` ➔ `confirmed` ➔ `preparing` ➔ `ready` ➔ `picked_up` ➔ `on_the_way` ➔ `delivered` (or `cancelled`).
  - Real-time GPS driver tracking through Daphne/Channels WebSockets (`ws://127.0.0.1:8000/ws/tracking/<order_id>/`).
  - Simulated driver movement script (`simulate_driver.py`).
  - Flutter Map integration via `flutter_map` and `latlong2`.

### 3.6 Multi-Role Portals (v3.0 - v3.5)
- **Implemented:**
  - `RestaurantDashboardScreen`: Dedicated order management view for `restaurant_owner` users to accept and prepare orders.
  - `DriverDashboardScreen`: Dedicated interface for drivers to toggle online/offline and accept pickup tasks.
  - Django Admin Suite: Enhanced dashboard grouping models into Users, Restaurants, Orders, Deliveries, and Payments with custom status badges.

### 3.7 DevOps & Containerization (v3.6 - v3.7)
- **Implemented:**
  - `docker-compose.yml`: Multi-container architecture running PostgreSQL 15, Redis 7, Django Daphne, and Flutter Web.
  - CI/CD: `.github/workflows/ci.yml` running linting, migrations check, Django test suite, and Flutter static analysis on every pull request and push.
  - Environment Isolation: `.env.example` templates covering all database, JWT, Stripe, ABA, ACLEDA, Cloudinary, and Maps variables.

---

## 4. Issues Discovered and Remediated

1. **Flutter Navigation Assertion Crash:**
   - *Problem:* Calling `Navigator.pop(context)` from root routes in `explore_screen.dart` and `addresses_screen.dart` crashed `GoRouter` with `AssertionError: currentConfiguration.isNotEmpty`.
   - *Remediation:* Replaced with safe fallback navigation checks using `context.canPop() ? context.pop() : context.go('/home')`.
2. **Missing Flutter Test Directory:**
   - *Problem:* `flutter test` reported `Test directory "test" not found`.
   - *Remediation:* Created `foodgo_flutter/test/unit_test.dart` testing `CartProvider` and `PaymentModel` deserialization.
3. **JWT HMAC Key Length Warning:**
   - *Problem:* `InsecureKeyLengthWarning: The HMAC key is 18 bytes long, which is below the minimum recommended length of 32 bytes for SHA256`.
   - *Remediation:* Updated `SECRET_KEY` fallback in `backend/config/settings.py` to a 50+ character cryptographic default, with `.env` override.
4. **Duplicate ViewSet Actions:**
   - *Problem:* `my_restaurant` action was accidentally duplicated inside `FoodCategoryViewSet`.
   - *Remediation:* Cleaned up redundant action, preserving the valid action on `RestaurantViewSet`.

---

## 5. Next Planned Milestones
- Expand dedicated documentation files in `docs/` as specified in Section 53 of the master roadmap.
- Add live FCM push notification dispatch when order statuses transition.
- Connect production merchant keys when bank partner agreements are finalized.
