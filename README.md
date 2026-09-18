# FoodGo - Food Delivery Application

A full-stack food delivery application inspired by Foodpanda.

## Technologies Used
* **Frontend:** React, Tailwind CSS, Vite, Axios, React Router Dom
* **Backend:** Django, Django REST Framework, Simple JWT
* **Database:** SQLite (Default for development) / PostgreSQL
* **Payments:** Stripe (integration stubbed)
* **Image Storage:** Cloudinary (integration stubbed)

## Project Structure
* `backend/` - Django backend API
* `frontend/` - React frontend application

## Setup Instructions

### Backend Setup
1. `cd backend`
2. Create and activate a virtual environment:
   ```bash
   python -m venv venv
   source venv/bin/activate
   ```
3. Install dependencies:
   ```bash
   pip install django djangorestframework psycopg2-binary django-cors-headers djangorestframework-simplejwt django-filter cloudinary stripe
   ```
4. Run migrations:
   ```bash
   python manage.py migrate
   ```
5. Create a superuser:
   ```bash
   python manage.py createsuperuser
   ```
6. Start the development server:
   ```bash
   python manage.py runserver
   ```

### Frontend Setup
1. `cd frontend`
2. Install dependencies:
   ```bash
   npm install
   ```
3. Start the development server:
   ```bash
   npm run dev
   ```

## API Endpoints (Base URL: `/api/`)
* `/token/` - Get JWT token
* `/token/refresh/` - Refresh JWT token
* `/restaurants/` - List/Create restaurants
* `/food-categories/` - List/Create food categories
* `/food-items/` - List/Create food items
* `/orders/` - List/Create orders

FoodGo is a Flutter food-delivery client backed by a Django REST API. The repository does not contain a React or Vite frontend.

## Architecture

- `backend/`: Django 6.1, Django REST Framework, Simple JWT, SQLite by default, PostgreSQL via `DATABASE_URL`.
- `foodgo_flutter/`: Flutter/Dart application using Provider, Dio, GoRouter, secure token storage, and Material UI.
- `backend/core/`: users, restaurants, food catalog, carts, orders, payments, addresses, and related API resources.

## Backend Setup

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver
```

Configuration is supplied through environment variables. Local development defaults to SQLite and `DEBUG=True`:

```bash
export DJANGO_SECRET_KEY='replace-this-in-development'
export DJANGO_DEBUG='True'
export DJANGO_ALLOWED_HOSTS='127.0.0.1,localhost'
export CORS_ALLOWED_ORIGINS='http://localhost:3000'
```

Production should set `DJANGO_DEBUG=False`, a strong `DJANGO_SECRET_KEY`, explicit hosts, and a PostgreSQL `DATABASE_URL`, such as `postgresql://user:password@host:5432/foodgo`. Never commit these values.

Useful checks:

```bash
python manage.py check
python manage.py check --deploy
python manage.py makemigrations --check
python manage.py test
```

## API

The API is rooted at `/api/`. JWT endpoints are `/api/token/` and `/api/token/refresh/`. Catalog resources include `/api/restaurants/`, `/api/food-categories/`, and `/api/food-items/`; authenticated resources include `/api/carts/`, `/api/cart-items/`, and `/api/orders/`. Public registration is `/api/register/`, and the Django admin is `/admin/`.

Catalog reads are public, but writes require authentication and ownership or staff permissions. Customer carts and orders are scoped to the authenticated user. Order totals and historical item prices are calculated server-side.

## Flutter Setup

```bash
cd foodgo_flutter
flutter pub get
flutter run --dart-define=FOODGO_API_URL=http://127.0.0.1:8000/api/
```

The API URL is configurable with `FOODGO_API_URL`; the loopback URL is only the local-development default. Validate the client with `flutter analyze` and `flutter test`.

## Production

Build platform artifacts with commands such as `flutter build apk --release` or `flutter build web --release`. Serve Django behind HTTPS with a production WSGI/ASGI server and PostgreSQL. Stripe and Cloudinary credentials are not configured in source; integrations must be completed with server-side environment variables before enabling live payments or remote media storage.

## Current Scope and Risks

The repository contains no Docker or CI configuration and no Flutter test suite yet. Checkout, addresses, and order history screens still need to be connected to their backend resources before they can be considered production-complete.
