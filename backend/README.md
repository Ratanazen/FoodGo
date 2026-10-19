# FoodGo Backend Service

Production-ready Django REST Framework and Daphne ASGI backend for **FoodGo**, powering high-performance food delivery workflows, real-time WebSocket driver GPS tracking, Cambodian banking payment integrations (Bakong KHQR, ABA PayWay, ACLEDA, COD, Wallet), and cryptographic doorstep delivery confirmation.

[![Django](https://img.shields.io/badge/Django-6.1-092E20?logo=django)](https://djangoproject.com)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-316192?logo=postgresql)](https://postgresql.org)
[![Tests](https://img.shields.io/badge/Backend%20Tests-57%20Passing-brightgreen)](https://djangoproject.com)

---

## Architecture & Core Modules

* **Framework:** Django 6.1 / 5.1 with Django REST Framework (DRF)
* **Real-Time / Async:** Daphne ASGI + Django Channels (WebSockets for live driver location updates)
* **Database:** PostgreSQL 15 (production with `DATABASE_URL`), SQLite (local dev fallback)
* **Authentication:** JWT with `rest_framework_simplejwt` and role-based permissions (`Customer`, `Owner`, `Driver`, `Admin`)
* **Fintech Integrations:**
  * **Bakong NBC Open API:** EMVCo-compliant dynamic KHQR generation with CRC16-CCITT checksum calculation
  * **ABA PayWay:** HMAC-SHA512 payload signatures, 5-minute dynamic QR expiration, and webhook listener
  * **ACLEDA Bank x-Pay:** Partner API integration with real-time callbacks
  * **Digital Wallet:** In-app ledger balance with atomic ACID deductions (`select_for_update`)
* **Doorstep QR Delivery Confirmation:** Cryptographically secure 256-bit CSPRNG token (`secrets.token_urlsafe(32)`) and 6-digit backup PIN with atomic validation and anti-replay guards.

---

## Directory Structure

```
backend/
├── config/                  # ASGI / WSGI entrypoints, URL routing, settings
│   ├── asgi.py
│   ├── settings.py          # Unified env-based database & auth configuration
│   └── urls.py
├── core/                    # Core business logic app
│   ├── admin.py             # Django admin customizations
│   ├── consumers.py         # Live WebSocket driver GPS consumers
│   ├── migrations/          # Database migrations
│   ├── models.py            # User, Restaurant, FoodItem, Order, DeliveryQR, Wallet
│   ├── payment_gateways.py  # Bakong, ABA PayWay, ACLEDA, Wallet, COD logic
│   ├── routing.py           # Channels WebSocket routes (/ws/tracking/<id>/)
│   ├── serializers.py       # DRF serializers
│   ├── tests.py             # Full test suite (57 tests)
│   └── views.py             # REST endpoints (Orders, Menus, Auth, Payments)
├── manage.py
└── requirements.txt
```

---

## Setup & Local Execution

```bash
# 1. Create and activate Python virtual environment
python3 -m venv venv
source venv/bin/activate

# 2. Install dependencies
pip install -r requirements.txt

# 3. Run database migrations
python manage.py migrate

# 4. Seed database with full menu and demo users
python manage.py seed_full_menu

# 5. Start ASGI server
python manage.py runserver 0.0.0.0:8000
```

---

## Automated Testing

```bash
# Run the complete backend test suite (57 tests)
python manage.py test

# Run Django system checks
python manage.py check

# Test static assets collection
python manage.py collectstatic --noinput
```
