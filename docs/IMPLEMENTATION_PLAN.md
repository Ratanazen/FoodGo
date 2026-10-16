# FoodGo Implementation Plan & Architecture Roadmap

**Version:** 3.0.0-PROD  
**Date:** October 2026  
**Repository:** [https://github.com/Ratanazen/FoodGo](https://github.com/Ratanazen/FoodGo)  

---

## 1. Architectural Objectives

This document details the complete technical roadmap for delivering a production-ready, bank-integrated food delivery platform for Cambodia. The plan covers server-authoritative order management, cryptographic delivery confirmation, Cambodian bank QR payments (Bakong KHQR, ABA PayWay, ACLEDA), and cross-platform Flutter experiences.

---

## 2. Multi-Phase Roadmap

### Phase 1 — Repository Audit & Technical Foundation
- Inspect Flutter client, Django REST Framework backend, database models, migrations, and test coverage.
- Identify architectural gaps, security issues, and unimplemented provider stubs.
- Deliver `docs/PROJECT_AUDIT.md`, `docs/IMPLEMENTATION_PLAN.md`, and `docs/API_DOCUMENTATION.md`.

### Phase 2 — Server-Authoritative User Order Management
- Implement server-side pricing: calculate subtotal, validate menu item availability, apply database coupons, compute delivery fees, and assign drivers.
- Auto-generate non-colliding human-readable order references (`FG-YYYYMMDD-XXXXXX`).
- Enforce order state machine: `pending` $\to$ `confirmed` $\to$ `preparing` $\to$ `ready_for_pickup` $\to$ `picked_up` $\to$ `on_the_way` $\to$ `driver_arrived` $\to$ `delivered`.
- Enforce strict validation blocking direct client status updates to `delivered`.

### Phase 3 — Secure Order QR Architecture
- Generate cryptographically secure tokens linked to individual orders using `secrets.token_urlsafe(32)`.
- Strip all sensitive PII (customer names, phone numbers, delivery addresses, payment tokens) from QR payloads.
- Mask secret tokens in serializer representations for non-authorized viewers.

### Phase 4 — Driver Delivery Handover Flow & Dual Verification
- **Driver Doorstep Action:** Driver taps "Arrived at Customer" in `DriverDashboardScreen`, triggering `POST /api/orders/<id>/delivery_qr/`.
- **Dynamic Handover QR:** Displays high-contrast QR code, 6-digit backup PIN, live 15-minute countdown timer, and background scan listener.
- **Customer Verification:** Customer scans driver QR or enters 6-digit PIN in `DeliveryScannerModal`.
- **Dual Flow Support:** Support alternative direction where customer displays order QR and assigned driver scans it.
- **Atomic Execution:** Locks database records with `select_for_update()`, marks `delivered`, records timestamp and confirming user, while preserving `payment_status`.

### Phase 5 — Cambodian Bank Payment System
- **Modular Provider Interface:** Abstract `PaymentProvider` class with standardized `create_payment`, `verify_payment`, `get_payment_status`, `process_callback`, and `refund`.
- **NBC Bakong KHQR:** Generate standard EMVCo KHQR payloads with Merchant Account Information (Tag 29), Transaction Currency (Tag 53: USD/KHR), and CRC16-CCITT checksum.
- **ABA PayWay:** Implement payload signing with HMAC-SHA512.
- **ACLEDA x-Pay:** Support ACLEDA KHQR dynamic checkout with webhook signature validation.
- **FoodGo Wallet & COD:** Full digital wallet ledger with ACID transaction balance locking and Cash on Delivery order confirmation.
- **Currency Support:** Dual currency support with official NBC exchange rate ($1.00\text{ USD} = 4,100\text{ KHR}$).

### Phase 6 — Backend API Hardening & Route Compatibility
- Standardize REST endpoints with uniform HTTP response envelopes and status codes.
- Provide route aliases ensuring compatibility with both legacy endpoints and enterprise specifications (`/api/orders/<id>/delivery/arrive/`, `/api/orders/<id>/delivery/confirm/`, `/api/payments/webhooks/<provider>/`).
- Implement object-level permissions and rate limiting on sensitive endpoints.

### Phase 7 — Flutter User Mobile App
- Seamless checkout flow forwarding server-validated promo codes.
- Multi-state payment screen (`QRPaymentScreen`) supporting Loading, Pending, Success, Expired, Cancelled, and Failed cards.
- Integrated `DeliveryScannerModal` with animated camera viewfinder and 6-digit PIN tab.
- Live order tracking timeline and bill receipt dialogs.

### Phase 8 — Flutter Driver Portal
- Unified role-based driver portal (`DriverDashboardScreen`) for online/offline toggling, live GPS broadcasting, and assigned delivery queues.
- "Arrived at Customer" trigger with integrated `DeliveryQrModal`.
- Status polling and instant celebratory confirmation when customer scans.

### Phase 9 — Database Architecture & Cryptographic Security
- Apply non-destructive migrations (`0014`, `0015`).
- Ensure monetary values utilize `DecimalField`.
- Store secrets and credentials exclusively in `.env` configurations.

### Phase 10 — Automated Quality Assurance
- Automated Django REST Framework test suites for orders, payment gateways, and delivery confirmation tokens.
- Flutter static analysis (`flutter analyze` with 0 issues).
- Flutter widget/unit test suites (`flutter test` covering all models, providers, and utilities).

### Phase 11 — Enterprise Documentation & Release
- Comprehensive documentation: `README.md`, `.env.example`, `docs/API_DOCUMENTATION.md`, `docs/PAYMENT_SETUP.md`, `docs/DELIVERY_QR.md`, and `docs/TESTING.md`.
