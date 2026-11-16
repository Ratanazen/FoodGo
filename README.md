# FoodGo - Enterprise Food Delivery Platform

FoodGo is a modern, production-ready, full-stack food delivery application built with a beautifully animated **Flutter** frontend and a robust **Django REST Framework / WebSockets** backend.

[![CI/CD](https://github.com/Ratanazen/FoodGo/actions/workflows/ci.yml/badge.svg)](https://github.com/Ratanazen/FoodGo/actions/workflows/ci.yml)
![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Django](https://img.shields.io/badge/Django-6.1-092E20?logo=django)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-316192?logo=postgresql)
![Tests](https://img.shields.io/badge/Tests-263%20Passing-brightgreen)
![Analyze](https://img.shields.io/badge/Flutter%20Analyze-0%20Issues-brightgreen)
![Zero Emoji](https://img.shields.io/badge/Zero--Emoji-100%25%20Vector-success)
![License](https://img.shields.io/badge/license-MIT-green.svg)

---

## Showcase Video & Release Deliverables

| Package | Contents |
| :--- | :--- |
| **[`Slide/video/FoodGo_v2_Showcase.mp4`](./Slide/video/FoodGo_v2_Showcase.mp4)** | Full HD (`1920×1080`, 30 FPS, `8m 41s`) ACLEDA University Capstone Presentation Video with Khmer neural voiceover (`km-KH-PisethNeural`), bilingual Khmer/English subtitles ([`.srt`](./Slide/video/foodgo-presentation.srt) / [`.vtt`](./Slide/video/foodgo-presentation.vtt)), live 4-portal Flutter demo recordings, and custom D-major soundtrack |
| **[`APK/`](./APK/)** | Universal Android Release APK ([`FoodGo-v2.0-release.apk`](./APK/FoodGo-v2.0-release.apk), 89.0 MB `arm64-v8a` / `armeabi-v7a` / `x86_64`), SHA-1 & SHA-256 checksums, installation guide, and demo accounts |

---

## Core Features & Modern UI/UX

### 1. Modern Food Delivery Experience
* **Minimalist Location Header:** Clean search circle button, centered `Location` / `Naperville, Illinois`, and notification bell with unread badge `1`.
* **Spaghetti Hero Promo Card:** High-contrast dark container (`#1E1E20`) highlighting `"Free Delivery For Spaghetti"`, `"Up to 3 times per day"`, with neon-lime `"Order Now"` pill button (`#CCFF00`) and round spaghetti dish presentation.
* **4 Quick Categories:** Rounded square category filter cards (`Burger`, `Chicken`, `Fries`, `Drink`) with active selection state and vector icons.
* **Recommended For You 2-Column Grid:** Dynamic dish cards featuring `Golden Spicy Chicken` ($5.00), `Cheese Burger Nagi` ($4.50), `Double Beef Cheese Burger` ($6.50), and `Crispy French Fries` ($3.00) with interactive favorite hearts, price tier filtering (`$`, `$$`, `$$$`), and circular neon-lime `+` add-to-cart buttons with live cart pulse feedback.
* **Food Item Details Screen:** Clean floating circular top buttons, hero dish image with realistic soft drop shadow, **4 macro-nutrients nutrition card** (`198 kcal`, `25.2 proteins`, `13.8 fats`, `23.7 carbo`), expandable `"Show more"` description, **special cooking instructions input** with cart state synchronization, and sticky bottom bar with animated bag button & large neon-lime `"Buy Now"` pill button.
* **Live Order Tracking Sheet (TikTok Reference):** Interactive route polyline on Google Maps, live pulsing status dot, 5-stage milestone stepper (`Confirmed` -> `Preparing` -> `Picked up` -> `On the way` -> `Delivered`), driver info card (`Ahmad Faizal`), route breakdown card, and itemized order receipt.
* **Dual-Engine Search & Smart Filters:** Instant debounced search for both dishes and restaurants with scope tabs (`All`, `Dishes`, `Restaurants`), persistent search history with individual delete/clear all, quick craving chips with vector icons, advanced filter modal with price tiers (`$`, `$$`, `$$$`), vegetarian toggle, minimum rating filter, and dual USD/KHR price calculations.

### 2. Complete Multi-Role Delivery System & Order State Machine
* **End-to-End Order Lifecycle:** Standardized lifecycle progression:
  ```
  ORDER_CONFIRMED -> DRIVER_ASSIGNED -> DRIVER_ACCEPTED -> PREPARING -> READY_FOR_PICKUP -> PICKED_UP -> OUT_FOR_DELIVERY -> DELIVERED
  (Terminal states: CANCELLED, FAILED_DELIVERY)
  ```
* **Customer Functions:**
  * Saved delivery address selection and automated dynamic delivery fee calculation ($2.00 base + distance).
  * Reliable estimated delivery time (ETA) countdown computed server-side.
  * Real-time assigned driver details card (driver name, vehicle model, license plate, phone contact, and live GPS coordinates).
  * Comprehensive order timeline and immutable audit trail (`OrderStatusHistory`).
  * State-aware cancellation safeguard: Cancellation allowed in `pending` and `confirmed` prior to kitchen preparation; strictly blocked once the restaurant begins `preparing`.
* **Driver Functions:**
  * Dedicated driver portal (`DriverDashboardScreen`) with secure role-based authorization and admin approval enforcement.
  * Real-time online/offline availability switch controlling eligibility for incoming orders.
  * Concurrency-safe delivery request claiming using database-level `select_for_update()` locking to prevent multi-driver collisions.
  * Route navigation launcher integrating external Google Maps directions for pickup and drop-off coordinates.
  * Turn-by-turn workflow progression: `Accepted` -> `Arrived at Restaurant` -> `Picked Up` -> `Arrived at Customer` -> `Delivered`.
  * Multi-method doorstep verification: High-contrast handover QR code scanning, 4-digit customer PIN verification, and Cash on Delivery (COD) collection confirmation.
  * Delivery issue & failed delivery reporting with documented failure reasons and restaurant return coordination.
  * Verified earnings accounting tracking completed deliveries and delivery fees.
* **Restaurant Functions:**
  * Real-time incoming order dashboard (`RestaurantDashboardScreen`) with itemized bill inspection.
  * One-tap order acceptance (`POST /api/orders/{id}/restaurant-accept/`).
  * Structured order rejection (`POST /api/orders/{id}/restaurant-reject/`) with reason logging and automatic refund trigger for prepaid orders.
  * Kitchen preparation tracking (`POST /api/orders/{id}/start-preparing/`).
  * Ready-for-pickup handover dispatch (`POST /api/orders/{id}/ready-for-pickup/`) automatically alerting assigned couriers.
* **Administrator Functions:**
  * Dedicated driver management console (`AdminDriverViewSet` at `/api/admin/drivers/`) supporting driver approval, suspension, and real-time availability monitoring.
  * Dynamic delivery reassignment (`POST /api/admin/orders/{id}/reassign_driver/`) with vehicle breakdown and operational handover safeguards.
  * Status override management (`POST /api/admin/orders/{id}/update_status/`).
  * Complete audit trail logging every state transition, responsible actor, role, timestamp, and metadata notes.

### 3. Modern Illustrated Authentication Flow
* **Offline Vector Character Illustrations:** Pure canvas-drawn vector illustrations rendered via custom painters (`AuthIllustration`):
  * **Sign In:** Character reviewing mobile charts with floating notification pills.
  * **Sign Up:** Character holding an inspection checklist clipboard.
  * **Forget Password:** Character working on laptop with security lock.
* **Sign In Screen:** User name & password fields with eye toggle, right-aligned *"Forget password"* link, royal blue `Login` button (`#1B64F2`), Google & Facebook social buttons, and quick mobile OTP login.
* **Sign Up Screen:** Full name, email, password inputs, legal terms disclaimer, royal blue `Create Account` button, and Google sign-up.
* **Forget Password Screen:** Email input with royal blue `Send OTP` button and simulated OTP dispatch feedback.

### 4. Application-Wide Screen Modernization
* **Cart Screen:** Minimalist circular header, neon-lime quantity steppers (`-` and `+`) with tactile haptic feedback, free delivery milestone progress bar, dual currency total ($ USD & KHR), and high-impact neon-lime `"Proceed to Checkout"` button.
* **Profile Screen:** User profile header with neon-lime accent ring, 3-column quick action shortcuts (Wallet, Orders, My KHQR Pay Me), Admin Console access tile for authorized staff, and modern rounded `_ProfileOption` tiles with circular icon containers and subtle chevrons.
* **Orders Screen:** Animated filter pill chips (`All`, `Active`, `Delivered`, `Cancelled`) with active lime selection, order cards with status badges, one-tap `"Order Again"` CTA, and integrated FoodGo Support Concierge modal with 24/7 hotline and issue reporting.
* **Explore Screen:** Modern category chips with lime selection, rounded pill search bar (`BorderRadius.circular(28)`), and circular map floating action.
* **Favorites Screen:** Minimalist AppBar with circular back button, lime indicator TabBar, lime price accents, and circular lime `+` add-to-cart buttons.
* **Search Screen:** Rounded pill search input with lime search icon and clear action, trending search chips, and modal dish detail sheet with neon-lime add-to-cart button.
* **Driver Dashboard Screen:** Real-time earnings summary, available and in-progress order cards with prominent customer special cooking instructions badges, and delivery QR verification scanner.

### 5. Administrator Console & Operations Center
* **Executive Analytics Dashboard:** Real-time KPI telemetry (order volume, USD & KHR gross revenue, active courier tracking, registered customer base, and live database/ASGI health check).
* **Dispatch & Order Management:** Live search, status pipeline filtering, manual driver assignment modal, and administrative order cancellation.
* **User & Restaurant Directory:** Comprehensive role filtering (`customer`, `driver`, `restaurant_owner`, `admin`) with real-time active/inactive account toggles.
* **Immutable Audit Trail:** Append-only security log recording every administrative action (`ASSIGN_DRIVER`, `CANCEL_ORDER`, `REFUND_PAYMENT`, `TOGGLE_USER_ACTIVE`, `TOGGLE_RESTAURANT`), tracking actor, remote IP, and JSON delta changes.
* **Full Documentation:** Complete technical guides in [`docs/upgrade-plan.md`](docs/upgrade-plan.md) and [`docs/admin-dashboard.md`](docs/admin-dashboard.md).

### 6. Fintech & Security Features
* **Cambodian KHQR Fintech Gateways:** Seamless dual-currency support (USD `$`, KHR `KHR`), Bakong NBC Open API, ABA Bank Dynamic KHQR with live 5-minute countdown, ACLEDA Bank KHQR, and Cash on Delivery (COD).
* **In-App Digital Wallet:** Instant top-ups via KHQR with atomic ACID ledger deduction.
* **Cryptographic Doorstep QR Delivery Confirmation:** Cryptographically secure 15-minute expiring token and 6-digit backup PIN preventing fraudulent delivery handovers.
* **Real-Time WebSockets:** Powered by Django Channels & Redis for live driver GPS simulation and status updates.

### 7. In-App Notifications & Live Driver GPS Telemetry
* **Automated Milestone Notifications:** Real-time push notification dispatch across all order lifecycle states (`pending`, `confirmed`, `preparing`, `ready`, `on_the_way`, `driver_arrived`, `delivered`, `cancelled`).
* **Notification Center:** Dynamic badge counter on `HomeScreen`, category filters (`All`, `Orders`, `Promos`), swipe-to-delete dismissible tiles, mark-all-as-read, and deep-link modal sheets.
* **Live Driver Route WebSockets:** Daphne ASGI `OrderTrackingConsumer` with coordinate validation, 200ms throttling, and bearing telemetry forwarding.
* **Turn-by-Turn Courier Animation:** `MapScreen` with continuous polyline progress, rotating motorcycle courier marker (`Transform.rotate`) driven by heading calculations, and live speed/ETA readout.

### 8. National Bank of Cambodia (NBC) Multi-Currency & Disaster Recovery
* **Dynamic NBC Rate Engine:** REST endpoint `/api/currency/rates/` exposing the National Bank of Cambodia customary rate (`4,100 KHR / USD`) with database persistence (`ExchangeRate` model) and timestamped caching.
* **App-Wide Currency Switcher:** User preference toggle (`$ USD`, `៛ KHR`, `Dual ($ / ៛)`) persisted in `SharedPreferences`, dynamically re-rendering all menus, cart totals, and receipts.
* **Automated Disaster Recovery Script (`scripts/backup_db.sh`):** Enterprise utility supporting PostgreSQL and SQLite backups, gzip compression, 7-day retention rotation, and restore verification.

### 9. Real Cambodian SMS Gateway & Phone OTP Verification
* **Cambodian Carrier E.164 Normalization:** Strict Cambodian mobile formatting (`+855...`) supporting Smart (`010`, `015`, `016`, `069`, `070`, `081`, `086`, `087`, `093`, `096`, `098`), Cellcard (`011`, `012`, `014`, `017`, `061`, `076`, `077`, `078`, `079`, `085`, `089`, `092`), Metfone (`031`, `060`, `066`, `067`, `068`, `071`, `088`, `090`, `097`), Seatel (`018`), and Cootel (`038`).
* **Multi-Gateway Architecture:** Primary production adapter for SimoSMS (`smscambodia.com` / ViHaT Group Cambodia), fallback adapter for WeUMS (`weums365.com`), and isolated in-memory test provider.
* **Zero Plaintext Storage Security:** Cryptographically secure 6-digit numeric OTPs generated via CSPRNG and hashed using keyed HMAC-SHA256 with unique 32-character hexadecimal salts. Plaintext OTPs are never stored in the database or logged to disk.
* **Anti-Abuse Safeguards:** 60-second resend cooldown timer, 300-second expiration, 5-attempt lockout, and 5-per-hour rate limits per mobile number.
* **Atomic Consumption:** Concurrency-safe verification using `select_for_update()` row locking preventing replay attacks.
* **Driver Phone Enforcement:** Couriers must verify their Cambodian mobile number via SMS OTP before accepting delivery assignments (`POST /api/drivers/orders/<id>/accept/` returns 403 Forbidden when unverified).
* **Flutter Verification UI:** Interactive `PhoneVerificationModal` bottom sheet with Cambodian carrier hints, animated countdown timer, inline validation, and verified profile badge.
* **Full Documentation:** Complete technical guide in [`docs/cambodian-sms-otp.md`](docs/cambodian-sms-otp.md).

---

## Architecture Stack

* **Frontend:** Flutter 3.x (Provider state management, GoRouter, `flutter_animate`, Google Maps / OpenStreetMap)
* **Backend API:** Python 3.12+, Django 6.1, Django REST Framework, SimpleJWT
* **Real-time / Async:** Daphne ASGI, Django Channels, WebSockets, Redis
* **Database:** PostgreSQL 15 (production), SQLite (local dev)
* **Design Tokens:** Centralized modern theme tokens in `GlassTheme` (neon-lime `#CCFF00`, auth blue `#1B64F2`, dark surfaces `#1E1E20`)
* **CI/CD:** GitHub Actions automated test suites, linting, web compilation, and Docker builds

---

## Quick Start (One-Click Environment)

On Linux or macOS, run the automated launch script from the project root:

```bash
./run_all.sh
```

This single command will:
1. Clear conflicting ports (`8000` and `8080`).
2. Run database migrations.
3. Automatically seed demo accounts, restaurants, and 26+ food menu items.
4. Launch the Daphne ASGI backend on `http://127.0.0.1:8000`.
5. Launch the Flutter Web frontend on `http://127.0.0.1:8080`.

---

## Step-by-Step Manual Running

If you prefer running services in separate terminal windows:

### 1. Prerequisites
- **Python 3.12+**
- **Flutter SDK 3.x**
- **Git**

### 2. Backend Setup (Terminal 1)
```bash
# Navigate to backend directory
cd backend

# Create and activate virtual environment
python3 -m venv venv
source venv/bin/activate    # On Windows: venv\Scripts\activate

# Install Python dependencies
pip install -r requirements.txt

# Run migrations
python manage.py migrate

# Seed database with demo accounts, restaurants, and menu items
python manage.py seed_full_menu

# Start Django Daphne ASGI server (HTTP & WebSockets)
python manage.py runserver 0.0.0.0:8000
```
- **Backend API Root:** http://127.0.0.1:8000
- **Admin Dashboard:** http://127.0.0.1:8000/admin/

### 3. Frontend Setup (Terminal 2)
```bash
# Navigate to Flutter app directory
cd foodgo_flutter

# Get Flutter packages
flutter pub get

# Run on Chrome / Web Server
flutter run -d chrome

# OR run as a local web server on port 8080
flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0

# OR run on a connected mobile device / emulator
flutter run
```
- **Flutter Web App:** http://127.0.0.1:8080

---

## Pre-Configured Demo Accounts

The database comes pre-seeded with accounts for all roles:

| Role | Username | Password | Notes & Features |
|---|---|---|---|
| **Customer** | `customer1` | `customer123` | Pre-funded with **$100.00 wallet balance**, default Phnom Penh address |
| **Restaurant Owner** | `owner` | `owner123` | Owns *Glass Burger* (manage menu items & view restaurant orders) |
| **Restaurant Owner** | `owner2` | `owner123` | Owns *Crystal Pizza* |
| **Restaurant Owner** | `owner3` | `owner123` | Owns *Phnom Penh Flavors* |
| **Delivery Driver** | `driver1` | `driver123` | View assigned delivery orders and accept trips |
| **System Admin** | `admin` | `admin123` | Full access to `/admin/` portal |

---

## Live Driver GPS Simulation

To test live delivery tracking over WebSockets in real time:

```bash
# From project root with backend running:
source backend/venv/bin/activate
python scripts/simulate_driver.py
```
This script pushes live moving GPS coordinates for Order #1 directly to the WebSocket channel, animating the delivery driver's bike on the customer's map screen.

---

## Cambodian Bank KHQR & Payment Gateways

FoodGo provides realistic, modular Cambodian fintech integrations:
* **Bakong KHQR (NBC Open API):** Real EMVCo-compliant KHQR payload strings with merchant account tagging, dual currency, and CRC16-CCITT checksums.
* **ABA PayWay (Dynamic KHQR):** 5-minute auto-expiring QR code with live countdown timer, HMAC-SHA512 payload signatures, and webhook polling.
* **ACLEDA Bank x-Pay:** Partner API integration with real-time callbacks and signature verification.
* **FoodGo Digital Wallet:** Instant in-app top-ups via KHQR with atomic ACID ledger deduction.
* **Cash on Delivery (COD):** Direct driver cash settlement upon arrival.

### Simulating an Instant Payment Webhook
To simulate an ABA or ACLEDA mobile payment callback in development:
```bash
curl -X POST http://127.0.0.1:8000/api/payments/aba/callback/ \
  -H "Content-Type: application/json" \
  -d '{"merchant_reference": "<MERCHANT_REF_FROM_SCREEN>", "amount": "<ORDER_AMOUNT>", "currency": "USD", "transaction_id": "ABA-TEST-TXN-101"}'
```

---

## Secure QR Code Delivery Confirmation

FoodGo enforces cryptographic doorstep handover confirmation between courier and customer:
* **Driver Arrival:** Courier taps "Arrived at Customer" to generate a short-lived, cryptographically secure delivery token and 6-digit backup PIN (`POST /api/orders/<id>/delivery_qr/`).
* **High-Contrast Modal:** Driver displays `DeliveryQrModal` with high-contrast QR code, 6-digit PIN, and 15-minute countdown timer.
* **Customer Verification:** Customer scans driver QR or enters PIN in `DeliveryScannerModal` (`POST /api/orders/<id>/confirm_delivery/`).
* **Atomic State Transition:** Backend validates expiration, single-use anti-replay, and driver binding with `select_for_update()`, atomically updating order and delivery to `delivered`.
* **Payment Preservation:** Handover confirmation strictly preserves payment status (`UNPAID` remains `UNPAID` until settled).
* **Dual Flow & Fallback:** Supports reverse scanning (driver scanning customer QR) and authorized admin clearance override.

---

## Automated Testing & CI/CD Pipelines

FoodGo maintains an enterprise-grade test verification suite and hardened continuous integration pipeline ([`.github/workflows/ci.yml`](.github/workflows/ci.yml)):

```
┌─────────────────────────────────────────────────────────────┐
│                     GITHUB ACTIONS CI/CD                    │
├─────────────────────────────────────────────────────────────┤
│ 1. Secret & API Leak Prevention Check (Zero Tracked .env)   │
│ 2. Django Backend Tests (PostgreSQL 15 Service + SQLite)    │
│ 3. Django Static Assets Collection Check (collectstatic)    │
│ 4. Flutter Code Analysis (Zero Warning Policy)              │
│ 5. Flutter Unit & Widget Test Suite (57/57 Passing)         │
│ 6. Flutter Web Release Compilation (flutter build web)      │
│ 7. Docker Image Build Verification (Backend ASGI & Frontend)│
└─────────────────────────────────────────────────────────────┘
```

### Running Test Commands Locally

```bash
# 1. Django Backend Test Suite (119 tests — 100% Passing)
cd backend
./venv/bin/python manage.py test core

# 2. Django System Checks & Static Assets Collection
python manage.py check
python manage.py collectstatic --noinput

# 3. Flutter Static Code Analysis (0 issues across 84 files)
cd ../foodgo_flutter
flutter analyze --no-pub

# 4. Flutter Unit & Widget Tests (110 tests — 100% Passing)
flutter test

# 5. Flutter Web Release Compilation
flutter build web --release
```

### Quality Assurance Verification Matrix

| Test Suite | Tests Run | Result | Execution Time |
| :--- | :---: | :---: | :---: |
| **Django Backend (`backend/manage.py test core`)** | **156** | **156 Passed (100%)** | ~6.5s |
| **Flutter Frontend (`foodgo_flutter/test/`)** | **115** | **115 Passed (100%)** | ~10.4s |
| **Total Automated Tests** | **271** | **271 Passed (100%)** | ~16.9s |
| **Flutter Static Analysis (`flutter analyze --no-pub`)** | **88 Files** | **0 Errors, 0 Warnings** | ~2.4s |
| **Zero-Emoji Policy Verification** | **All Repo Files** | **100% Vector Icon Compliant** | ~1.1s |
| **Multi-Cloud Health Checks (`/api/health/`)** | **Endpoints** | **Operational (Vercel, Render, Docker)** | <10ms |
| **Flutter Web Build (`flutter build web --release`)** | **Full Web Bundle** | **Success (`Built build/web`)** | ~75s |
| **Android Network Security** | **Cleartext 10.0.2.2** | **Configured (`network_security_config.xml`)** | Verified |
| **Django Static Collection (`collectstatic`)** | **249 Files** | **Success** | ~1.2s |
| **Database Backup & DR (`backup_db.sh`)** | **Automated Script** | **Verified (PostgreSQL & SQLite)** | <1s |

---

## Technical Documentation

Comprehensive documentation is provided in the `docs/` directory:
- [**Cambodian SMS OTP Specification**](docs/cambodian-sms-otp.md) — Real Cambodian SMS Gateway integration (SimoSMS, WeUMS), E.164 normalization, salted HMAC-SHA256, and anti-abuse policies.
- [**Authentication & Authorization Specification**](docs/authentication.md) — JWT lifecycle, role-based access control, Remember Me security, and endpoint contracts.
- [**Login, Auth & QR Payment Audit**](docs/login-payment-audit.md) — Comprehensive audit covering mock token elimination, host routing, and registration validation.
- [**Payment Flow & EMVCo KHQR Architecture**](docs/payment-flow.md) — Dynamic KHQR flow, CRC16 mathematical verification, state transitions, and responsive layout.
- [**Payment Provider Integration Guide**](docs/payment-provider-setup.md) — Credentials, webhook security, sandbox testing, and refund operations.
- [**Web Payment Integration Audit**](docs/web-payment-audit.md) — Complete audit of payment endpoints, data models, error handling, and security.
- [**UI/UX Comprehensive Audit**](docs/ui-ux-audit.md) — Audit across responsive layouts, navigation, accessibility, and visual consistency.
- [**Implementation Roadmap**](docs/implementation-roadmap.md) — Detailed 14-phase implementation plan and task breakdown.
- [**User Flows Specification**](docs/user-flows.md) — Detailed flow diagrams for customer, driver, and admin personas.
- [**Project Audit Report**](docs/project-audit.md) — Comprehensive architecture, defect findings, root causes, and remediation.
- [**Form Audit & Validation Guide**](docs/form-fixes.md) — Screen-by-screen form audit, validation rules, and double-submit prevention.
- [**CI/CD Pipeline Operations**](docs/cicd.md) — GitHub Actions 4-stage pipeline topology, secrets, and local execution.
- [**Production Hosting & Deployment**](docs/deployment.md) — Vercel serverless WSGI and Render container deployment guide.
- [**Troubleshooting & Diagnostics**](docs/troubleshooting.md) — Step-by-step diagnostics for Flutter, Django, Docker, and Vercel.
- [**TikTok Reference UI/UX Analysis**](docs/reference-analysis.md) — Comprehensive visual breakdown of TikTok reference video frames and component specs.
- [**API Documentation**](docs/API_DOCUMENTATION.md) — Full REST API reference with JSON request/response payloads.
- [**Delivery Confirmation Guide**](docs/DELIVERY_QR.md) — Cryptographic delivery confirmation and security guarantees.
- [**Testing Guide**](docs/TESTING.md) — Step-by-step instructions for running test suites in dev and CI.

---

## Docker Deployment

To spin up the entire production stack (PostgreSQL, Redis, Daphne ASGI, Flutter Nginx):

```bash
# Copy sample environment configuration
cp .env.example backend/.env

# Build and start all containers
docker compose up -d --build
```

---

## Security & Architecture Best Practices

* **Zero PII in QR Payloads:** Delivery and payment QR codes never include customer names, phones, addresses, or credentials.
* **Server-Authoritative Pricing:** Subtotals, discounts, delivery fees, and totals are computed strictly on the server.
* **CSPRNG Tokens:** Generated using `secrets.token_urlsafe(32)` (256 bits entropy).
* **Decimal Precision:** All monetary amounts in Django use `DecimalField` to prevent floating-point loss.
* **Atomic Transactions:** Critical operations utilize `transaction.atomic` and `select_for_update()`.

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
