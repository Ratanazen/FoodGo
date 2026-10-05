# 🍔 FoodGo - Enterprise Food Delivery Platform

FoodGo is a modern, production-ready, full-stack food delivery application built with a beautifully animated **Flutter (Glassmorphism)** frontend and a robust **Django REST Framework / WebSockets** backend.

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Django](https://img.shields.io/badge/Django-6.1-092E20?logo=django)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-316192?logo=postgresql)
![License](https://img.shields.io/badge/license-MIT-green.svg)

---

## ✨ Core Features
* **Role-Based Architecture:** Unified app routing for Customers, Restaurant Owners, Drivers, and Admins.
* **Real-Time Live Map Tracking:** Powered by Django Channels (WebSockets). Watch delivery drivers move live on Google Maps.
* **Cambodian KHQR Fintech Gateways:** Supports Bakong NBC Open API, ABA Bank Dynamic KHQR, ACLEDA Bank KHQR, and Cash on Delivery (COD).
* **In-App Digital Wallet:** Integrated wallet with instant top-ups, transaction ledger, and automated checkout deductions.
* **Glassmorphic Design System:** Unified dark theme inspired by modern delivery platforms (Foodpanda & Grab), fully centralized in `GlassTheme`.
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

## 💳 KHQR & Payment Gateways

FoodGo provides realistic Cambodian fintech integrations:
* **Bakong KHQR (NBC Open API):** Real KHQR-compliant strings with amount, merchant name, and currency tagging.
* **ABA KHQR (Dynamic QR):** 5-minute auto-expiring QR code with live countdown timer and webhook polling.
* **ACLEDA KHQR:** Partner API integration with real-time callbacks.
* **Cash on Delivery (COD):** Direct driver cash settlement upon arrival.

### Simulating an Instant Payment Webhook
To simulate an ABA or ACLEDA mobile payment callback in development:
```bash
curl -X POST http://127.0.0.1:8000/api/payments/aba/callback/ \
  -H "Content-Type: application/json" \
  -d '{"merchant_reference": "<MERCHANT_REF_FROM_SCREEN>", "amount": "<ORDER_AMOUNT>", "currency": "USD", "transaction_id": "ABA-TEST-TXN-101"}'
```

---

## 🧪 Automated Testing & Verification

Run the full automated test suites:

```bash
# 1. Flutter Unit Tests (18 tests)
cd foodgo_flutter
flutter test

# 2. Flutter Static Code Analysis
flutter analyze

# 3. Django Backend Test Suite (24 tests)
cd ../backend
python manage.py test
```

---

## 🐳 Docker Deployment

To spin up the entire production stack (PostgreSQL, Redis, Daphne, Flutter Nginx):

```bash
# Copy sample environment configuration
cp .env.example .env

# Build and start all containers
docker-compose up -d --build
```

---

## 🛡️ Security & Architecture Best Practices
* **No Hardcoded Secrets:** Production environments use `.env` configs; CI runs an automated secret leak audit.
* **JWT Token Rotation:** Access and refresh tokens stored safely in secure client storage.
* **Centralized Design Tokens:** 100% of custom colors and glassmorphic styles are governed by `GlassTheme`.
* **Dual Branch Synchronization:** `main` and `master` branches are kept synchronized with green GitHub Actions CI builds.


