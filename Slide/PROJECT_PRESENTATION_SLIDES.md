# FoodGo v2.0 — Project Presentation Slides (`Slide/`)

**University**: ACLEDA University of Business (AUB)  
**Batch / Group**: Batch 09 • Year 3 • Semester 1 • Group 7 (`aub-batch-09-y3-s1-m-g7-Food-Delivery-App`)  
**Project Title**: FoodGo v2.0 — Full-Stack Cambodian Food Delivery Platform (Mobile, Web, Server & KHQR)

---

## Slide 1: Title & Team Overview
- **Project**: FoodGo v2.0 — Cambodian Food Delivery Ecosystem
- **Repository**: `aub-batch-09-y3-s1-m-g7-Food-Delivery-App`
- **Deliverables Included**:
  - `APK/` — Android Release APK (`FoodGo-v2.0-release.apk`)
  - `Database/` — SQLite3 Database + SQL Schema Dump + ERD
  - `Figma/` — Complete Design System, UI/UX Audit & Interactive Canvas
  - `Slide/` — Presentation Deck (HTML Interactive Deck + Markdown)
  - `foodgo-mobile/` — Flutter Cross-Platform Mobile Source Code
  - `foodgo-server/` — Django 5.1 REST Framework + SimpleJWT Backend
  - `foodgo-web/` — Production Compiled Web Application

---

## Slide 2: Problem Statement & Objectives
- **Problem**:
  - Generic food delivery templates lack Cambodian localization (Khmer script `ភាសាខ្មែរ`, dual `USD $` / `KHR ៛` currency at `1 USD = 4,100 KHR`, and National Bank of Cambodia **Bakong KHQR** payment flows).
  - Disconnected customer, delivery driver, and restaurant kitchen workflows.
- **Solution (FoodGo v2.0)**:
  - Unified multi-role platform supporting **Customer**, **Delivery Account (`driver_sokha`)**, and **Kitchen Admin / Partner (`chef_kravanh`)**.
  - Runtime-configurable **API Server & Hosting URL** with live health checks (`/api/health/`) for seamless emulator, LAN device, or cloud hosting.

---

## Slide 3: System Architecture
- **Frontend (`foodgo-mobile/` & `foodgo-web/`)**:
  - Flutter 3.x + Provider State Management (`AuthProvider`, `CartProvider`, `RestaurantProvider`, `LanguageProvider`) + GoRouter + Dio + SecureStorage.
- **Backend (`foodgo-server/`)**:
  - Python Django 5.1 + Django REST Framework + SimpleJWT (`SafeJWTAuthentication` & multi-identifier `EmailAuthBackend` supporting Email, Username, and Phone login) + `QRLoginView` (`/api/auth/qr-login/`).
- **Database (`Database/`)**:
  - 14 relational tables managing users, restaurants, food items, carts, orders, KHQR payments, drivers, deliveries, addresses, favorites, coupons, and notifications.

---

## Slide 4: Key Features Implemented
1. **Cambodian Localization & Dual Currency**:
   - Instant 1-tap toggle between English (`EN`) and Khmer (`ភាសាខ្មែរ`) and automatic `USD ($)` + `KHR (៛)` pricing.
2. **Bakong / ABA KHQR & Instant QR Pass Login**:
   - Interactive KHQR payment modal (`ABA PAY`, `Bakong`, `ACLEDA`, `Wing`) with countdown refresh, clipboard payload copy, and Account/Driver QR ID Pass (`FG-QR:<role>:<username>`).
3. **Delivery Driver Portal (`driver_sokha`)**:
   - Online/Offline radar, 4-step delivery progression (`Accepted -> Picked Up -> On the Way -> Delivered`), live earnings & trip counter, and instant KHQR payout modal.
4. **Kitchen Admin & Partner Portal (`chef_kravanh`)**:
   - Live Kitchen Display System (KDS) order status controls and real-time menu stock toggle (`In Stock` / `Sold Out`).

---

## Slide 5: Quality Assurance & Verification Results
- **Flutter Static Analysis**: `flutter analyze` — **0 issues found**.
- **Flutter Unit & Provider Tests**: `flutter test` — **15 / 15 tests passed** (Cart math, free delivery threshold `>= $15`, coupon `FOODGO30`, Khmer translation, category filtering, driver delivery completion, order cancellation, and API host URL normalization).
- **Django Backend API Tests**: `python manage.py test core` — **11 / 11 tests passed** (Restaurants, Food items, Auth registration, QR Login for Driver & Customer, SafeJWT public access, KHQR order creation, Order status progression & cancellation, Favorites toggle, and `/api/health/`).
