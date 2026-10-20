# FoodGo — Login, Authentication & QR Payment Comprehensive Audit Report

**Date**: 2026-10-20  
**Role**: Senior Full-Stack Developer, Authentication Engineer, Payment Integration Engineer, and QA Engineer  
**Repository**: [https://github.com/Ratanazen/FoodGo](https://github.com/Ratanazen/FoodGo)

---

## 1. Executive Summary

This audit investigates the end-to-end authentication and payment subsystems across the Django 6.1 Daphne ASGI backend and the Flutter 3.x web/mobile frontend. The audit identified specific root causes of login failures, session persistence issues, registration validation gaps, and QR payment edge-case state handling, providing an actionable remediation roadmap.

---

## 2. Authentication Subsystem Audit

### 2.1 Backend Contract & Endpoints
- **Token Endpoint**: `POST /api/token/` (`TokenObtainPairView`).
  - Accepts `{"username": "<identifier>", "password": "<password>"}`.
  - Backed by `EmailAuthBackend` (`backend/core/authentication.py`), which supports both `email` and `username` case-insensitively (`email__iexact` and `username__iexact`).
  - Returns `{"access": "<JWT>", "refresh": "<JWT>"}`.
- **Token Refresh**: `POST /api/token/refresh/` (`TokenRefreshView`).
  - Accepts `{"refresh": "<JWT>"}` and returns `{"access": "<new_JWT>"}`.
- **User Profile**: `GET /api/me/` (`UserMeView`).
  - Requires `Bearer <access_token>`. Returns user model payload (`id`, `username`, `email`, `role`, `phone`, etc.).
- **Registration**: `POST /api/register/` (`UserRegistrationView`).
  - Accepts `username`, `email`, `password`, `first_name`, `last_name`, `phone`.
- **Password Reset**: `POST /api/forgot-password/` (`ForgotPasswordView`).
  - Accepts `{"email": "..."}`.

### 2.2 Identified Authentication Defects & Root Causes

1. **Hardcoded Fallback Credentials in `api_service.dart`**:
   - **Finding**: Lines 83-104 of `foodgo_flutter/lib/services/api_service.dart` contained a hardcoded fallback granting mock JWT tokens for `'admin'` / `'admin123'` and `'customer1'` / `'customer123'` whenever the backend returned an error.
   - **Root Cause**: Developer mock left in place for offline testing, violating the security requirement: *"Do not create a fake login flow or hard-coded successful credentials."*
   - **Fix**: Remove all mock credential intercepts; authenticate solely against the real Django API and propagate authentic status codes.

2. **Base URL Defaulting & Host Mismatch**:
   - **Finding**: `AppConfig.apiBaseUrl` defaulted to `https://food-go-app.vercel.app/api/`. When running locally on `http://127.0.0.1:8080` (e.g. via `run_all.sh`), the frontend tried to send auth requests across the internet to Vercel instead of the local server running on `http://127.0.0.1:8000/api/`.
   - **Root Cause**: Static fallback lacked intelligent localhost/local-network auto-detection.
   - **Fix**: In `AppConfig`, when `kIsWeb` is active and `Uri.base.host` is `'localhost'` or `'127.0.0.1'`, dynamically default to `http://${Uri.base.host}:8000/api/` unless an explicit environment URL is specified.

3. **Registration Username vs Full Name Conflict**:
   - **Finding**: `register_screen.dart` used a single `_fullNameController` and sent `username: _fullNameController.text.trim()`. If a user entered "Alice Smith", Django's `UnicodeUsernameValidator` rejected the request because spaces are disallowed in usernames.
   - **Root Cause**: Frontend form lacked a dedicated username input or sanitization logic.
   - **Fix**: Provide dedicated Username and Full Name inputs or auto-sanitize username from email/name with server-side validation.

4. **Missing Email Uniqueness Validation in `UserRegistrationSerializer`**:
   - **Finding**: `UserRegistrationSerializer` did not validate `email__iexact` uniqueness before creating the user.
   - **Root Cause**: Relied only on default database constraints; can trigger 500 integrity errors or allow duplicate email accounts.
   - **Fix**: Add `validate_email` and `validate_username` with clean ValidationError responses.

5. **Session Leakage & Fallback User Mock in `UserProvider`**:
   - **Finding**: In `user_provider.dart`, `fetchUser()` had a catch block setting `_user` to a hardcoded mock user (`customer1`) if the request failed. Additionally, `logout()` did not clear `_user`.
   - **Root Cause**: Mock data retention masked unauthenticated states.
   - **Fix**: Add `clearUser()` invoked upon logout; remove mock user fallback on network error.

6. **Login UI Validation & Remember Me**:
   - **Finding**: `login_screen.dart` lacked Remember Me functionality and displayed generic error messages without distinguishing invalid credentials from network reachability issues.
   - **Fix**: Add Remember Me checkbox (storing username in `SharedPreferences`), distinct failure notifications, inline field validation, and FoodGo branding.

---

## 3. QR Payment Subsystem Audit

### 3.1 Architecture Overview
- **Payment Creation**: `POST /api/payments/create/` row-locks the order via `Order.objects.select_for_update()` and atomically generates a `Payment` record with NBC-compliant EMVCo TLV payload and CRC16-CCITT checksum.
- **Payment Verification**: `POST /api/payments/<id>/status/` and bank webhooks (`POST /api/payments/<provider>/callback/`).
- **Payment Lifecycle**: `PENDING` -> `PAID`, `EXPIRED`, `CANCELLED`, `FAILED`, and `REFUNDED`.

### 3.2 Identified QR Payment UI Gaps & Fix Plan

1. **Network Error State Handling**:
   - When polling or checking status encounters a network timeout or offline state, the UI must display a distinct network retry warning without duplicating payment creation or aborting the countdown timer.
2. **Success Confirmation Details**:
   - Ensure `PAID` state confirms verified backend payment with order reference, verified amount, and direct navigation to order details/success.
3. **Safe Regeneration & Cancellation**:
   - Verify that regenerating an expired QR properly initializes a new 5-minute countdown and cleans up old timers.
   - Verify that cancelled sessions abort all in-flight asynchronous polling.

---

## 4. Remediation Plan

| Phase | Component | Action Items |
|---|---|---|
| **Phase 2** | `login_screen.dart` | Redesign with FoodGo branding, Remember Me, show/hide password, inline validation, accessibility, and clean error banners. |
| **Phase 3** | `api_service.dart`, `app_config.dart`, `user_provider.dart` | Remove mock tokens, add localhost auto-detection, implement `clearUser()` on logout, harden token refresh. |
| **Phase 3** | `serializers.py` | Add `validate_email` and `validate_username` to `UserRegistrationSerializer`. |
| **Phase 4** | `qr_payment_screen.dart` | Add network error handling state, verified amount display, and seamless order success transitions. |
| **Phase 5** | Responsive Layouts | Constrain login (maxWidth: 420) and QR payment (maxWidth: 500) with safe areas and keyboard handling. |
| **Phase 6** | Backend Security | Enforce case-insensitivity, role boundaries, and atomic database state transitions. |
| **Phase 7** | Regression Testing | Add comprehensive test cases in Django (`tests_auth.py`, `tests_payment.py`) and Flutter (`admin_test.dart`, `auth_test.dart`). |
| **Phase 8** | Documentation | Update `README.md`, `docs/authentication.md`, `docs/payment-flow.md`, and `.env.example`. |
