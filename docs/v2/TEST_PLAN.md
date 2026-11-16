# FoodGo v2.0 — Comprehensive Test Plan

**Version:** 2.0.0  
**Test Lead:** Agent 5 (QA Automation Specialist)  
**Coordination:** Agent 1 (Integration Architect)

---

## 1. Test Matrix Overview

| Test Layer | Framework / Tools | Target Coverage | Environment |
| :--- | :--- | :--- | :--- |
| **Backend Unit & API** | Django `TestCase`, DRF `APIClient` | Core CRUD, Auth, Phone OTP, Dual-Hosting | PostgreSQL / SQLite |
| **Fintech & Payment** | DRF `APIClient`, Mock Webhooks | Bakong KHQR, ABA, ACLEDA, COD, Wallet | Sandbox / Isolated Test DB |
| **Frontend Unit & Widget** | Flutter `flutter_test`, `WidgetTester` | Themes, Localization, Cart, Checkout, Driver | Headless Flutter Runner |
| **Accessibility & Text Scale** | Flutter `WidgetTester` | 4-tier scaling (`0.85x` - `1.30x`), Khmer Unicode | Headless Flutter Runner |
| **Android Device Testing** | Physical Device (`SM-S908U` / API 36) | Deep links, GPS coordinates, Network switch | ADB over Wi-Fi (`192.168.18.221`) |
| **CI/CD Pipeline** | GitHub Actions (`ci.yml`) | Secret audit, Django tests, Flutter analyze & test | Ubuntu Latest Containers |

---

## 2. Test Suites Inventory

### 2.1 Backend Tests (`backend/core/tests*`)
* `core/tests.py`: Core API endpoints, user authentication, cart, order placement, driver dispatch (4 test classes).
* `core/tests_payment.py`: Bakong KHQR dynamic generation, webhook signature validation, idempotency, refund rules.
* `core/tests_phone_otp.py`: Cambodian phone regex (`+855`), OTP cryptography, 60s cooldown, rate limiting.
* `core/tests_delivery_qr.py`: Doorstep single-use delivery tokens, 6-digit backup PIN, dual QR handover.
* `core/tests_dual_hosting.py`: Zero-leakage health probes, cross-instance JWT auth, idempotency keys.
* `core/tests_admin.py`: Admin analytics aggregation, manual courier dispatch, audit logging.
* `core/tests_auth.py`: Case-insensitive email login, password validation, token refresh.
* `core/test_mongo_user.py`: MongoDB Atlas user mirroring and telemetry.
* `core/tests_v4.py`: Notification dispatch, coupons, favorites, password update.

### 2.2 Flutter Tests (`foodgo_flutter/test/`)
* `test/theme_palette_test.dart`: 31 Brand & Cultural themes, Material 3 compliance.
* `test/localization_test.dart`: 100% key parity between English and Khmer dictionaries.
* `test/text_scale_accessibility_test.dart`: 4-tier text scale without `RenderFlex` overflow.
* `test/live_qr_payment_test.dart`: QRPaymentScreen, Bakong KHQR, WebSocket status updates.
* `test/checkout_screen_banks_test.dart`: Bank options (Bakong, ABA, ACLEDA, Wing), zero-dollar cart items.
* `test/driver_module_test.dart`: DriverDashboardScreen (Active, Available, Earnings, Profile tabs).
* `test/auth_token_refresh_test.dart`: SecureStorage token rotation, 401 recovery interceptor.
* `test/unit_test.dart`: CartProvider, PaymentModel, MapConfig, AddressProvider.

---

## 3. Execution Commands & Verification Matrix

### 3.1 Backend Execution
```bash
# Run full backend test suite
python backend/manage.py test core

# Run fintech & security suites
python backend/manage.py test core.tests_payment core.tests_delivery_qr core.tests_phone_otp
```

### 3.2 Flutter Execution
```bash
cd foodgo_flutter
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

### 3.3 Android Physical Device ADB Execution
```bash
# Build and install APK
flutter build apk --release
adb -s 192.168.18.221:41287 install -r build/app/outputs/flutter-apk/app-release.apk

# Verify launch and deep link
adb -s 192.168.18.221:41287 shell am start -n kh.foodgo.app/com.example.foodgo_flutter.MainActivity
```

---

## 4. Status Criteria & Reporting Rules

* **PASS**: Directly verified with verifiable command exit code 0 and test runner summary.
* **FAIL**: A test or assertion failed with stack trace evidence.
* **BLOCKED**: Verification cannot proceed due to missing prerequisite (e.g. retail bank production merchant credentials).
* **NOT RUN**: Test not attempted.
