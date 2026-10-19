# 🍔 FoodGo - Enterprise Food Delivery Platform

FoodGo is a modern, production-ready, full-stack food delivery application built with a beautifully animated **Flutter (Glassmorphism)** frontend and a robust **Django REST Framework / WebSockets** backend.

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Django](https://img.shields.io/badge/Django-6.1-092E20?logo=django)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-316192?logo=postgresql)
![License](https://img.shields.io/badge/license-MIT-green.svg)

---

## ✨ Core Features
* **Modern Delivery UI/UX (TikTok Reference):** Lush green gradient curved header, Deliver-to address switcher, elevated pill search bar, hero promo banner, horizontal 3D categories, deals carousel with voucher claim, 2-column restaurant card grid, and persistent floating active order tracker with live ETA.
* **Modern Live Order Tracking Sheet:** Floating top navigation bar, interactive route polyline, live pulsing badge, 5-stage milestone stepper (`Confirmed` → `Preparing` → `Picked up` → `On the way` → `Delivered`), driver info card (`Ahmad Faizal`), route breakdown card, and itemized order receipt.
* **Role-Based Architecture:** Unified app routing for Customers, Restaurant Owners, Drivers, and Admins.
* **Real-Time Live Map Tracking:** Powered by Django Channels (WebSockets). Watch delivery drivers move live on Google Maps.
* **Cambodian KHQR Fintech Gateways:** Supports Bakong NBC Open API, ABA Bank Dynamic KHQR, ACLEDA Bank KHQR, and Cash on Delivery (COD).
* **In-App Digital Wallet:** Integrated wallet with instant top-ups, transaction ledger, and automated checkout deductions.
* **Dual Design System:** Modern Lush Green Clean theme & Dark Glassmorphism, fully centralized in `GlassTheme`.
* **Containerized Ecosystem:** Ready for one-command deployment via Docker & Compose.

---

## 🏗️ Architecture Stack
* **Frontend:** Flutter 3.x (Provider state management, GoRouter, `flutter_animate`, `flutter_map` / Google Maps)
* **Backend API:** Python 3.10+, Django 6.1 / 5.1, Django REST Framework, SimpleJWT
* **Real-time / Async:** Daphne, Django Channels, WebSockets, Redis
* **Database:** PostgreSQL (production), SQLite (local dev)
* **CI/CD:** GitHub Actions automated test suites and linters

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
- **Flutter Web App:** http://127.0.0.1:8080 (or your Chrome window)

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

## 🧪 Automated Testing & Verification

Run the full automated test suites:

```bash
# 1. Django Backend Test Suite (57 tests — 100% Passing)
cd backend
./venv/bin/python manage.py test

# 2. Flutter Static Code Analysis (0 issues)
cd ../foodgo_flutter
flutter analyze --no-pub

# 3. Flutter Unit & Widget Tests (54 tests — 100% Passing)
flutter test
```

---

## 📚 Complete Technical Documentation

Comprehensive documentation is provided in the `docs/` directory:
- [**TikTok Reference UI/UX Analysis**](docs/reference-analysis.md) — Comprehensive visual breakdown of TikTok reference video frames and component specs.
- [**Modernization Implementation Plan**](docs/implementation-plan.md) — P0-P3 roadmap for modern delivery experience.
- [**Codebase Implementation Audit**](docs/implementation-audit.md) — Full repository audit and payment verification.
- [**Project Audit Report**](docs/PROJECT_AUDIT.md) — Codebase architecture and security audit.
- [**API Documentation**](docs/API_DOCUMENTATION.md) — Full REST API reference with JSON request/response payloads.
- [**Payment Setup Guide**](docs/PAYMENT_SETUP.md) — Merchant onboarding for Bakong, ABA PayWay, and ACLEDA.
- [**Delivery Confirmation Guide**](docs/DELIVERY_QR.md) — Cryptographic delivery confirmation and security guarantees.
- [**Testing Guide**](docs/TESTING.md) — Step-by-step instructions for running test suites in dev and CI.

---

## 🐳 Docker Deployment

To spin up the entire production stack (PostgreSQL, Redis, Daphne, Flutter Nginx):

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


