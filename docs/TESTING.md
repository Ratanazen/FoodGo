# FoodGo Comprehensive Quality Assurance & Testing Guide

**Version:** 4.1.0-PROD  
**Date:** October 2026  
**Repository:** [https://github.com/Ratanazen/FoodGo](https://github.com/Ratanazen/FoodGo)  

---

## 1. Overview of Test Coverage

FoodGo maintains comprehensive automated test coverage across both backend services and the mobile client application:
- **Django REST Framework Tests:** **74 / 74 Tests Passing** (100% Pass Rate).
- **Flutter Static Analysis:** **0 Issues Found** (`flutter analyze --no-pub`).
- **Flutter Unit & Widget Tests:** **81 / 81 Tests Passing** (`flutter test --no-pub`).
- **Total Automated Tests:** **155 / 155 Tests Passing** (100% Pass Rate).

---

## 2. Backend Automated Test Suite (Django REST Framework)

### 2.1 Execution Command
```bash
cd backend
backend/venv/bin/python manage.py test core
```

### 2.2 Test Structure & Suites
1. **Core Features & Authentication (`core/tests.py`) — 23 Tests:**
   - User registration and JWT authentication.
   - Food category and menu item queries.
   - Server-side cart management.
   - Address creation, default address toggling, and isolation.
   - Review creation and restaurant rating aggregation.
   - Coupon discount calculation.

2. **Fintech Gateways & Payments (`core/tests_payment.py`) — 10 Tests:**
   - `test_create_aba_payment`: ABA dynamic KHQR payload generation.
   - `test_create_acleda_payment`: ACLEDA x-Pay KHQR payload generation.
   - `test_create_bakong_payment`: NBC Bakong EMVCo tag structuring.
   - `test_create_cod_payment`: Immediate order confirmation on Cash on Delivery.
   - `test_create_wallet_payment_success`: Digital wallet atomic balance deduction.
   - `test_create_wallet_payment_insufficient_balance`: Balance validation guard.
   - `test_cancel_wallet_payment_issues_automatic_refund`: Automatic refund on cancellation.
   - `test_aba_callback_verification_and_idempotency`: HMAC webhook verification and idempotent replay handling.
   - `test_callback_amount_mismatch_rejected`: Amount tampering rejection.
   - `test_admin_refund_endpoint`: Authorized staff partial/full refund.

3. **Secure Delivery Confirmation QR (`core/tests_delivery_qr.py`) — 18 Tests:**
   - `test_driver_can_generate_delivery_qr`: Assigned driver generates token and PIN; sets `delivery.status = 'arrived'`.
   - `test_unassigned_driver_cannot_generate_delivery_qr`: Unassigned driver rejected with `403 Forbidden`.
   - `test_customer_cannot_generate_delivery_qr`: Customer rejected with `403 Forbidden`.
   - `test_customer_confirms_delivery_via_qr_token`: Customer confirms delivery via token; sets `order.status = 'delivered'` and `delivery.status = 'delivered'`.
   - `test_customer_confirms_delivery_via_pin`: Customer confirms delivery via 6-digit backup PIN.
   - `test_customer_confirms_delivery_via_full_qr_payload_string`: Customer scanner extracts token cleanly from full URI string.
   - `test_unauthorized_customer_cannot_confirm_delivery`: Non-owner rejected with `403 Forbidden`.
   - `test_expired_token_rejected`: 15-minute expiration enforcement.
   - `test_replay_attack_rejected`: Replay scan returns idempotent `ALREADY_DELIVERED`.
   - `test_invalid_token_and_pin_rejected`: Wrong token/PIN rejected with `400 Bad Request`.
   - `test_admin_support_confirm_delivery_override`: Staff manual override logs reason into audit trail.
   - `test_order_serializer_delivery_token_privacy`: Secret tokens and PINs masked from customer serializer view.
   - `test_order_reference_generation`: Format validation (`FG-YYYYMMDD-XXXXXX`).
   - `test_driver_declares_arrival_endpoint`: `POST /api/orders/<id>/delivery_arrive/` updates statuses.
   - `test_dual_qr_flow_assigned_driver_can_confirm`: Assigned driver confirms delivery by scanning customer token.
   - `test_direct_patch_status_delivered_prohibited`: Direct PATCH to `status = 'delivered'` rejected with `400 Bad Request`.
   - `test_invalid_state_transition_rejected`: Invalid status transitions rejected by state machine.
   - `test_explicit_route_aliases`: Verification of route aliases (`/delivery/arrive/`, `/delivery/confirm/`, `/tracking/`).

4. **Admin Operations & Audit Logging (`core/tests_admin.py`) — 7 Tests:**
   - `test_non_admin_cannot_access_analytics`: Strict 403 Forbidden enforcement on unauthorized roles.
   - `test_admin_analytics_endpoint`: Aggregates order volume, USD/KHR revenues, couriers, and ASGI database health check.
   - `test_admin_assign_driver_and_audit_log`: Manual dispatch assignment transitions orders and creates immutable `AuditLog` entry.
   - `test_admin_cancel_order_and_audit_log`: Admin cancellation creates immutable `AuditLog` entry with cancellation reason.
   - `test_admin_toggle_user_status`: Disables/enables user account with audit trail.
   - `test_admin_toggle_restaurant_status`: Disables/enables restaurant with audit trail.
   - `test_admin_audit_logs_endpoint`: Paginated chronological audit trail retrieval.

---

## 3. Frontend Quality Assurance (Flutter)

### 3.1 Static Code Analysis
```bash
cd foodgo_flutter
flutter analyze --no-pub
```
- **Result:** `No issues found!` (0 errors, 0 warnings, 0 lints).

### 3.2 Unit & Widget Test Suite
```bash
cd foodgo_flutter
flutter test --no-pub
```
- **Total Tests:** 81 Tests Passing (`00:04 +81: All tests passed!`).
- **Covered Areas:**
  - `AdminProvider`: State defaults, filter mutations, data retrieval.
  - `AdminDashboardScreen`: Full 5-tab UI layout verification (Overview, Orders, Users, Restaurants, Audit Logs) and period filter chips.
  - `CartProvider`: Quantity increments, item removals, grand total recalculation, discount computation, and special cooking instructions.
  - `KhmerCurrency` & `CurrencyProvider`: Dynamic National Bank of Cambodia (NBC) rate engine, USD/KHR dual-currency conversion, SharedPreferences persistence, and `SettingsScreen` currency switcher modal.
  - `NotificationProvider` & `NotificationsScreen`: Real-time unread notification count badge in `HomeScreen` header, milestone notifications, category filters (`All`, `Orders`, `Promos`), swipe-to-delete, and order details bottom sheet modal.
  - `SearchScreen`: Dual search engine (Dishes & Restaurants), persistent search history with chip removal, quick craving suggestion chips with vector icons, and advanced filter bottom sheet modal.
  - `PaymentModel`: Deserialization, state getters (`isPending`, `isPaid`, `isExpired`, `isFailed`, `isProcessing`, `isRefunded`).
  - `MapConfig` & `MapScreen`: Route polyline verification, Haversine distance / ETA estimation, bearing calculation, and rotating motorcycle courier marker.
  - `AddressProvider`: Default address selection and local persistence fallbacks.
  - `Delivery Confirmation QR & PIN Tests`: URI query parameter parsing, 6-digit regex format validation, and payment preservation checks.
  - `ResponsiveLayout`: Mobile, tablet, and desktop layout constraints.
  - `KHQR Pay Me`: NBC standard EMVCo tag construction.

