# 🍔 FoodGo - Enterprise Food Delivery Platform

FoodGo is a modern, production-ready, full-stack food delivery application built with a beautifully animated **Flutter (Glassmorphism)** frontend and a robust **Django REST Framework / WebSockets** backend.

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Django](https://img.shields.io/badge/Django-6.1-092E20?logo=django)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-316192?logo=postgresql)

## ✨ Core Features
*   **Role-Based Architecture:** Unified app routing for Customers, Restaurant Owners, Drivers, and Admins.
*   **Real-Time Live Map Tracking:** Powered by Django Channels (WebSockets). Watch your driver move live on the map.
*   **Fintech Wallet System:** Integrated digital wallet with top-ups, transaction history, and strict checkout deductions.
*   **Mobile Authentication:** OTP-based phone login combined with secure JWT tokens.
*   **Algorithmic Recommendations:** Lightweight collaborative filtering suggesting foods based on order history.
*   **Glassmorphic UI:** A visually stunning, mathematically constrained mobile UI (even on desktop web).
*   **Containerized Ecosystem:** Fully deployable via a single `docker-compose.yml`.

## 🏗️ Architecture Stack
*   **Frontend:** Flutter (Provider, GoRouter, flutter_animate, google_maps_flutter)
*   **Backend API:** Python, Django 6.1, Django REST Framework, SimpleJWT
*   **Real-time / Async:** Daphne, Django Channels, Redis
*   **Database:** PostgreSQL (production), SQLite (local dev)
*   **CI/CD:** GitHub Actions workflows included

## 🚀 Quick Start (One-Click Dev Environment)
If you are developing locally on Linux/macOS, we've provided a script to spin up the entire ecosystem:
```bash
# Start Django API + Daphne WebSockets + Flutter Web Server instantly
./run_all.sh
```

## 🐳 Docker Production Deployment
```bash
# Copy env file
cp .env.example .env

# Spin up Postgres, Redis, Django, and Nginx/Flutter
docker-compose up -d --build
```

## 💳 Real Production-Style Payment Gateways (KHQR & COD)
FoodGo supports multi-provider checkout:
*   **ABA KHQR (Dynamic QR):** Generates compliant dynamic Bakong/ABA KHQR strings with 5-minute expirations and merchant reference verification.
*   **ACLEDA KHQR:** Full partner API merchant integration supporting real-time webhook callbacks.
*   **Cash on Delivery (COD):** Confirms order immediately with `payment_status='PENDING'` for in-person cash handover to the delivery driver.

### 📡 Payment Endpoints
*   `POST /api/payments/create/` — Initiate order payment & dynamic KHQR generation.
*   `POST /api/payments/<id>/status/` — Non-blocking polling & status verification.
*   `POST /api/payments/<id>/cancel/` — Cancel an in-flight payment attempt.
*   `POST /api/payments/aba/callback/` — Idempotent webhook receiver for ABA PayWay.
*   `POST /api/payments/acleda/callback/` — Idempotent webhook receiver for ACLEDA Bank.

### 🧪 Simulating an Instant KHQR Webhook
To simulate a customer scanning and paying via ABA Mobile in development:
```bash
curl -X POST http://127.0.0.1:8000/api/payments/aba/callback/ \
  -H "Content-Type: application/json" \
  -d '{"merchant_reference": "<MERCHANT_REF_FROM_SCREEN>", "amount": "<ORDER_AMOUNT>", "currency": "USD", "transaction_id": "ABA-TXN-999"}'
```

## 🛡️ Security
*   JWT Access/Refresh tokens securely stored in `flutter_secure_storage`.
*   Object-level permissions (Owners can only see their restaurant's orders).
*   Zero client-side payment trust: Order status only transitions to `confirmed` after backend signature & amount verification.

