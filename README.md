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

## 📚 API Endpoints
*   `/api/auth/phone-login/` - OTP Auth
*   `/api/restaurants/my_restaurant/` - Restaurant Owner Dashboard
*   `/api/wallets/my_wallet/` - User Wallet & Transactions
*   `/ws/tracking/<order_id>/` - Live Driver GPS WebSocket

## 🧪 Testing the Live Map
1. Place an order in the Flutter app.
2. Go to Orders -> Track Order.
3. Run the driver simulation script: `source backend/venv/bin/activate && python simulate_driver.py`

## 🛡️ Security
*   JWT Access/Refresh tokens securely stored in `flutter_secure_storage`.
*   Object-level permissions (Owners can only see their restaurant's orders).
*   Checkout APIs validate Wallet balances server-side to prevent client spoofing.
