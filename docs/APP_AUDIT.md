# FoodGo Mobile Application Audit (v3.0)

**Date:** September 22, 2026  
**Auditor:** Senior Mobile Application Engineer  
**Repository:** `https://github.com/Ratanazen/FoodGo.git`  
**Application Directory:** `foodgo_flutter/`

---

## 1. Technical Baseline

| Metric / Layer | Specification | Notes |
| :--- | :--- | :--- |
| **Framework** | Flutter 3.47.5 (Channel stable) | Dart SDK 3.13.4 |
| **Target Platforms** | Android, iOS, Web, Desktop | Tested on Web (`127.0.0.1:8080`) & Android |
| **Architecture Pattern** | Feature-driven presentation + Provider State + Core Service Layer | Layered into `app/`, `core/`, `features/`, `providers/`, `services/`, `widgets/` |
| **State Management** | `Provider` (`provider: ^6.1.5+1`) | `CartProvider`, `AuthProvider`, `UserProvider`, `RestaurantProvider`, `ThemeProvider` |
| **Networking** | `Dio` (`dio: ^5.7.0`) via `ApiClient` / `ApiService` | Connect/Receive timeout: 10s. Interceptors for Bearer JWT injection |
| **Local / Secure Storage** | `flutter_secure_storage: ^11.0.0` & `shared_preferences: ^2.5.5` | Access and refresh tokens stored safely in secure hardware-backed storage |
| **Navigation** | `go_router: ^14.2.0` | Declarative routing with `ShellRoute` bottom navigation bar |
| **Design System** | Glassmorphism (`GlassContainer`, `GlassCard`, `GlassButton`, `GlassAppBar`) | Dark themed, custom glowing accents, `GlassTheme.primaryGreen` |
| **Maps & Real-time Tracking** | `flutter_map: ^8.3.1`, `latlong2`, `web_socket_channel: ^3.0.3` | OpenStreetMap + live WebSocket tracking |
| **QR Payment Engine** | `qr_flutter: ^4.1.0` | Native rendering of Cambodian KHQR specifications |

---

## 2. Current Features & Capabilities

- **Customer Journey:**
  - Splash & Onboarding screens.
  - Multi-method authentication: JWT login, registration, and phone OTP request/verify.
  - Home feed with food categories, promotional banners, and popular restaurant cards.
  - Search screen with instant debounced food/restaurant lookup.
  - Restaurant details with banner hero animations and menu item cards.
  - Cart with real-time quantity adjustments, subtotal, delivery fee, and grand total.
  - Multi-provider Checkout:
    - ABA Bank KHQR (instant QR code generation + polling)
    - ACLEDA Bank KHQR
    - Cash on Delivery (COD)
    - FoodGo In-App Wallet balance deduction
  - Live order tracking with dynamic driver location marker moving over `flutter_map`.
  - Profile management, notifications screen, delivery address management, favorite meals.
  - FoodGo Wallet screen with live balance check, KHQR top-up modal, and transaction history.

- **Role Dashboards:**
  - Restaurant Owner Portal: Order list management & instant Menu Item manager (adding dishes with image URLs, categories, prices, in-stock toggling).
  - Driver Portal: Active order delivery status updates.

---

## 3. Current Dependencies Audit

```yaml
dependencies:
  flutter: sdk
  cupertino_icons: ^1.0.8
  provider: ^6.1.5+1
  dio: ^5.7.0
  flutter_secure_storage: ^11.0.0
  shared_preferences: ^2.5.5
  go_router: ^14.2.0
  flutter_map: ^8.3.1
  latlong2: ^0.10.1
  flutter_animate: ^4.5.2
  cached_network_image: ^3.4.1
  connectivity_plus: ^6.1.0
  equatable: ^2.0.7
  geolocator: ^14.0.3
  web_socket_channel: ^3.0.3
  qr_flutter: ^4.1.0
```
- **Audit Verdict:** All dependencies are modern and fully compatible with Flutter 3.47 / Dart 3.13. No vulnerable legacy packages found.

---

## 4. Known Bugs & Code Smells Identified

1. **Mock Orders in `OrdersScreen`:**
   - `lib/features/orders/presentation/orders_screen.dart` currently renders 4 hardcoded placeholder orders (`itemCount: 4`, `Order #102$index`). It should fetch real order records from the Django API `/api/orders/` with active state management, empty states, and pull-to-refresh.
2. **Duplicate HTTP Layer:**
   - Both `ApiClient` (`lib/core/network/api_client.dart`) and `ApiService` (`lib/services/api_service.dart`) exist. `ApiService` wraps `ApiClient`, but some screens directly instantiate it without a singleton or provider.
3. **Token Refresh Interceptor Gap:**
   - In `ApiClient`, `onError` has an unhandled comment: `// Here we could implement token refresh logic on 401`. When an access token expires, requests fail with 401 instead of automatically exchanging the refresh token via `/api/token/refresh/`.
4. **Network Image Error Fallbacks:**
   - Several widgets use standard `Image.network` instead of `CachedNetworkImage`, causing redundant downloads and missing smooth caching.
5. **Connectivity State Awareness:**
   - `connectivity_plus` is imported in `pubspec.yaml` but not yet wired to a global offline banner or retry state when connection is lost.

---

## 5. Security & Data Protection Review

- **Credential Storage:** PASS. Access tokens and refresh tokens are managed via `FlutterSecureStorage`. No passwords or tokens are stored in plain text or `SharedPreferences`.
- **Logging Safety:** PASS. `kDebugMode` guards logging; credentials and tokens are not logged.
- **Backend Secrets:** PASS. Zero backend secrets, API keys, or private certificates are embedded in Flutter code. Dynamic base URL configured via `--dart-define=FOODGO_API_URL=...`.
- **Payment Verification:** PASS. Flutter does NOT mark orders as paid. Payments are verified strictly through backend provider services (`verify/` API).

---

## 6. Performance & UI/UX Audit

- **Asset Caching:** Need wider utilization of `CachedNetworkImage` for restaurant banners and food item photos to preserve user mobile bandwidth and eliminate frame drops.
- **Empty & Error States:** Several screens (e.g. `OrdersScreen`, `FavoritesScreen`) need clearer empty states and retry buttons on network failure.
- **Touch Targets & Contrast:** Excellent contrast with `GlassTheme.primaryGreen` (#35B86B) on dark backgrounds (#0E1511). Touch targets meet the 48x48 dp minimum.

---

## 7. Recommended Upgrade Plan

1. **Phase 1: Networking & Auth Resilience:**
   - Add automatic JWT 401 token refresh interceptor in `ApiClient` using the stored refresh token.
   - Centralize API client access.
2. **Phase 2: Orders Screen Real Data Integration:**
   - Connect `OrdersScreen` to `GET /api/orders/` with live status tags (Pending, Confirmed, Preparing, On Delivery, Delivered, Cancelled), total amount, restaurant info, and pull-to-refresh.
3. **Phase 3: Image Caching & Offline State Handling:**
   - Standardize food and restaurant images on `CachedNetworkImage` with clean shimmer/fallback widgets.
   - Add network error banner/retry mechanisms.
4. **Phase 4: Expanded Test Suite:**
   - Add unit and widget tests for:
     - Auth Provider token management
     - Orders model deserialization & status parsing
     - Cart item calculations & edge cases
5. **Phase 5: Release Verification & Documentation:**
   - Run `flutter analyze`, `flutter test`, `flutter build web --release`.
   - Compile `docs/UPDATE_REPORT.md` and `docs/TEST_REPORT.md`.
