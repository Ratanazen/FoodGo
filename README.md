# 🍔 FoodGo - Enterprise Food Delivery Platform

FoodGo is a modern, production-ready, full-stack food delivery application built with a beautifully animated **Flutter** frontend and a robust **Django REST Framework / WebSockets** backend.

[![CI/CD](https://github.com/Ratanazen/FoodGo/actions/workflows/ci.yml/badge.svg)](https://github.com/Ratanazen/FoodGo/actions/workflows/ci.yml)
![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Django](https://img.shields.io/badge/Django-6.1-092E20?logo=django)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-316192?logo=postgresql)
![Tests](https://img.shields.io/badge/Tests-114%20Passing-brightgreen)
![Analyze](https://img.shields.io/badge/Flutter%20Analyze-0%20Issues-brightgreen)
![License](https://img.shields.io/badge/license-MIT-green.svg)

---

## ✨ Core Features & Modern UI/UX

### 1. Modern Food Delivery Experience
* **Minimalist Location Header:** Clean search circle button, centered `Location` / `📍 Naperville, Illinois ⌄`, and notification bell with unread badge `1`.
* **Spaghetti Hero Promo Card:** High-contrast dark container (`#1E1E20`) highlighting `"Free Delivery For Spaghetti"`, `"Up to 3 times per day"`, with neon-lime `"Order Now"` pill button (`#CCFF00`) and round spaghetti dish presentation.
* **4 Quick Categories:** Rounded square category filter cards (`Burger` 🍔, `Chicken` 🍗, `Fries` 🍟, `Drink` 🥤) with active selection state.
* **Recommended For You 2-Column Grid:** Dynamic dish cards featuring `Golden Spicy Chicken` ($5.00), `Cheese Burger Nagi` ($4.50), `Double Beef Cheese Burger` ($6.50), and `Crispy French Fries` ($3.00) with interactive favorite hearts and circular neon-lime `+` add-to-cart buttons.
* **Food Item Details Screen:** Clean floating circular top buttons, hero dish image with realistic soft drop shadow, **4 macro-nutrients nutrition card** (`198 kcal`, `25.2 proteins`, `13.8 fats`, `23.7 carbo`), expandable `"Show more"` description, and sticky bottom bar with bag button & large neon-lime `"Buy Now"` pill button.
* **Live Order Tracking Sheet (TikTok Reference):** Interactive route polyline on Google Maps, live pulsing status dot, 5-stage milestone stepper (`Confirmed` → `Preparing` → `Picked up` → `On the way` → `Delivered`), driver info card (`Ahmad Faizal`), route breakdown card, and itemized order receipt.

### 2. Modern Illustrated Authentication Flow
* **Offline Vector Character Illustrations:** Pure canvas-drawn vector illustrations rendered via custom painters (`AuthIllustration`):
  * **Sign In:** Character reviewing mobile charts with floating notification pills.
  * **Sign Up:** Character holding an inspection checklist clipboard.
  * **Forget Password:** Character working on laptop with security lock.
* **Sign In Screen:** User name & password fields with eye toggle, right-aligned *"Forget password"* link, royal blue `Login` button (`#1B64F2`), Google & Facebook social buttons, and quick mobile OTP login.
* **Sign Up Screen:** Full name, email, password inputs, legal terms disclaimer, royal blue `Create Account` button, and Google sign-up.
* **Forget Password Screen:** Email input with royal blue `Send OTP` button and simulated OTP dispatch feedback.

### 3. Application-Wide Screen Modernization
* **Cart Screen:** Minimalist circular header, neon-lime quantity steppers (`-` and `+`) with tactile haptic feedback, free delivery milestone progress bar, dual currency total ($ USD & ៛ KHR), and high-impact neon-lime `"Proceed to Checkout"` button.
* **Profile Screen:** User profile header with neon-lime accent ring, 3-column quick action shortcuts (Wallet, Orders, My KHQR Pay Me), and modern rounded `_ProfileOption` tiles with circular icon containers and subtle chevrons.
* **Orders Screen:** Animated filter pill chips (`All`, `Active`, `Delivered`, `Cancelled`) with active lime selection, order cards with status badges, and neon-lime `"Order Again"` CTA.
* **Explore Screen:** Modern category chips with lime selection, rounded pill search bar (`BorderRadius.circular(28)`), and circular map floating action.
* **Favorites Screen:** Minimalist AppBar with circular back button, lime indicator TabBar, lime price accents, and circular lime `+` add-to-cart buttons.
* **Search Screen:** Rounded pill search input with lime search icon and clear action, trending search chips, and modal dish detail sheet with neon-lime add-to-cart button.

### 4. Fintech & Security Features
* **Cambodian KHQR Fintech Gateways:** Seamless dual-currency support (USD `$`, KHR `៛`), Bakong NBC Open API, ABA Bank Dynamic KHQR with live 5-minute countdown, ACLEDA Bank KHQR, and Cash on Delivery (COD).
* **In-App Digital Wallet:** Instant top-ups via KHQR with atomic ACID ledger deduction.
* **Cryptographic Doorstep QR Delivery Confirmation:** Cryptographically secure 15-minute expiring token and 6-digit backup PIN preventing fraudulent delivery handovers.
* **Real-Time WebSockets:** Powered by Django Channels & Redis for live driver GPS simulation and status updates.

---

## 🏗️ Architecture Stack

* **Frontend:** Flutter 3.x (Provider state management, GoRouter, `flutter_animate`, Google Maps / OpenStreetMap)
* **Backend API:** Python 3.10+, Django 6.1 / 5.1, Django REST Framework, SimpleJWT
* **Real-time / Async:** Daphne ASGI, Django Channels, WebSockets, Redis
* **Database:** PostgreSQL 15 (production), SQLite (local dev)
* **Design Tokens:** Centralized modern theme tokens in `GlassTheme` (neon-lime `#CCFF00`, auth blue `#1B64F2`, dark surfaces `#1E1E20`)
* **CI/CD:** GitHub Actions automated test suites, linting, web compilation, and Docker builds

---

## 🚀 Quick Start (One-Click Environment)

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

## 🛠️ Step-by-Step Manual Running

If you prefer running services in separate terminal windows:

### 1. Prerequisites
- **Python 3.10+**
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

## 👥 Pre-Configured Demo Accounts

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

## 🚴 Live Driver GPS Simulation

To test live delivery tracking over WebSockets in real time:

```bash
# From project root with backend running:
source backend/venv/bin/activate
python scripts/simulate_driver.py
```
This script pushes live moving GPS coordinates for Order #1 directly to the WebSocket channel, animating the delivery driver's bike on the customer's map screen.

---

## 💳 Cambodian Bank KHQR & Payment Gateways

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

## 📦 Secure QR Code Delivery Confirmation

FoodGo enforces cryptographic doorstep handover confirmation between courier and customer:
* **Driver Arrival:** Courier taps "Arrived at Customer" to generate a short-lived, cryptographically secure delivery token and 6-digit backup PIN (`POST /api/orders/<id>/delivery_qr/`).
* **High-Contrast Modal:** Driver displays `DeliveryQrModal` with high-contrast QR code, 6-digit PIN, and 15-minute countdown timer.
* **Customer Verification:** Customer scans driver QR or enters PIN in `DeliveryScannerModal` (`POST /api/orders/<id>/confirm_delivery/`).
* **Atomic State Transition:** Backend validates expiration, single-use anti-replay, and driver binding with `select_for_update()`, atomically updating order and delivery to `delivered`.
* **Payment Preservation:** Handover confirmation strictly preserves payment status (`UNPAID` remains `UNPAID` until settled).
* **Dual Flow & Fallback:** Supports reverse scanning (driver scanning customer QR) and authorized admin clearance override.

---

## 🧪 Automated Testing & CI/CD Pipelines

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
# 1. Django Backend Test Suite (57 tests — 100% Passing)
cd backend
./venv/bin/python manage.py test

# 2. Django System Checks & Static Assets Collection
python manage.py check
python manage.py collectstatic --noinput

# 3. Flutter Static Code Analysis (0 issues across 69+ files)
cd ../foodgo_flutter
flutter analyze --no-pub

# 4. Flutter Unit & Widget Tests (57 tests — 100% Passing)
flutter test

# 5. Flutter Web Release Compilation
flutter build web --release
```

### Quality Assurance Verification Matrix

| Test Suite | Tests Run | Result | Execution Time |
| :--- | :---: | :---: | :---: |
| **Django Backend (`backend/manage.py test`)** | **57** | **57 Passed (100%)** | ~51.1s |
| **Flutter Frontend (`foodgo_flutter/test/`)** | **57** | **57 Passed (100%)** | ~5.4s |
| **Flutter Static Analysis (`flutter analyze --no-pub`)** | **69+ Files** | **0 Errors, 0 Warnings** | ~2.2s |
| **Flutter Web Build (`flutter build web --release`)** | **Full Web Bundle** | **Success (`✓ Built build/web`)** | ~74s |
| **Django Static Collection (`collectstatic`)** | **249 Files** | **Success** | ~1.2s |

---

## 📚 Complete Technical Documentation

Comprehensive documentation is provided in the `docs/` directory:
- [**TikTok Reference UI/UX Analysis**](docs/reference-analysis.md) — Comprehensive visual breakdown of TikTok reference video frames and component specs.
- [**Modernization Implementation Plan**](docs/implementation-plan.md) — Roadmap for modern delivery experience.
- [**Codebase Implementation Audit**](docs/implementation-audit.md) — Full repository audit and payment verification.
- [**Project Audit Report**](docs/PROJECT_AUDIT.md) — Codebase architecture and security audit.
- [**API Documentation**](docs/API_DOCUMENTATION.md) — Full REST API reference with JSON request/response payloads.
- [**Payment Setup Guide**](docs/PAYMENT_SETUP.md) — Merchant onboarding for Bakong, ABA PayWay, and ACLEDA.
- [**Delivery Confirmation Guide**](docs/DELIVERY_QR.md) — Cryptographic delivery confirmation and security guarantees.
- [**Testing Guide**](docs/TESTING.md) — Step-by-step instructions for running test suites in dev and CI.

---

## 🐳 Docker Deployment

To spin up the entire production stack (PostgreSQL, Redis, Daphne ASGI, Flutter Nginx):

```bash
# Copy sample environment configuration
cp backend/.env.example backend/.env

# Build and start all containers
docker-compose up -d --build
```

---

## 🛡️ Security & Architecture Best Practices

* **Zero PII in QR Payloads:** Delivery and payment QR codes never include customer names, phones, addresses, or credentials.
* **Server-Authoritative Pricing:** Subtotals, discounts, delivery fees, and totals are computed strictly on the server.
* **CSPRNG Tokens:** Generated using `secrets.token_urlsafe(32)` (256 bits entropy).
* **Decimal Precision:** All monetary amounts in Django use `DecimalField` to prevent floating-point loss.
* **Atomic Transactions:** Critical operations utilize `transaction.atomic` and `select_for_update()`.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
