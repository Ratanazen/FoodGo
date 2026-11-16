# FoodGo v2.0 — Full App Redesign & Engineering Master Task Plan

**Version:** 2.0.0  
**Status:** In Progress (Phase 0 Complete, Phase 1 Design Docs Ready)  
**Coordinated AI Team:** Agents A through F  

---

## 1. Ten-Phase Execution Graph

```
[Phase 0: Inspection & Git Safety] (DONE)
       │
       ▼
[Phase 1: UI/UX Audit & Design System Specs] (DONE)
       │
       ▼
[Phase 2: Core Shared Components & Visual Vector Assets]
       │
       ├──────────────────────────────┬──────────────────────────────┐
       ▼                              ▼                              ▼
[Phase 3: Customer App Redesign] [Phase 4: Driver App Redesign] [Phase 5: Admin Dashboard Redesign]
       │                              │                              │
       └──────────────────────────────┼──────────────────────────────┘
                                      ▼
             [Phase 6: API, Database, Auth & Payment Hardening] (VERIFIED)
                                      ▼
             [Phase 7: Full Stack UI-Backend Integration]
                                      ▼
             [Phase 8: Comprehensive QA, Regression & Responsive Tests]
                                      ▼
             [Phase 9: Production Release Gate & Final Master Report]
```

---

## 2. Phase-by-Phase Task Matrix & Status

### Phase 0 — Repository Audit & Git Safety Check
- [x] **TASK-0.1:** Verify `pwd`, `git status --short`, and current branch (`main`).
- [x] **TASK-0.2:** Validate zero uncommitted user changes were stashed, overwritten, or destroyed.
- [x] **TASK-0.3:** Inspect frameworks, package manifests, and environment templates.
- [x] **TASK-0.4:** Create Phase 0 audit documentation in `docs/v2/`.

### Phase 1 — UI/UX Audit, Screen Inventory & Design System
- [x] **TASK-1.1:** Produce `docs/v2/UI_UX_AUDIT.md` (screen-by-screen audit across customer, driver, and admin).
- [x] **TASK-1.2:** Produce `docs/v2/DESIGN_SYSTEM.md` (tokens, typography, geometry, shadows, motion, component specs).
- [x] **TASK-1.3:** Produce `docs/v2/SCREEN_SPECIFICATIONS.md` (specifications for 19 customer, 12 driver, and 10 admin screens).

### Phase 2 — Core Shared Components & Visual Assets
- [ ] **TASK-2.1:** Build offline vector illustration painters (`VectorEmptyIllustration` for empty cart, no orders, empty search, network offline).
- [ ] **TASK-2.2:** Build reusable `FeaturedFoodCard` and `RestaurantRowCard` adhering to 8-point spatial grid and dual pricing.
- [ ] **TASK-2.3:** Enhance `GlassTextField` and `SearchField` with clear button, voice placeholder, and inline error styling.
- [ ] **TASK-2.4:** Build `DietaryTagBadge` and `ModernStatusBadge` component tokens.

### Phase 3 — Customer App Redesign
- [ ] **TASK-3.1:** Redesign `OnboardingScreen` with 3 custom vector illustration scenes and skip/action flow.
- [ ] **TASK-3.2:** Refactor `HomeScreen` header and food item grid for clean information hierarchy and instant cart add.
- [ ] **TASK-3.3:** Polish `CartScreen` with `VectorEmptyIllustration`, item quantity steppers, and sticky glass checkout drawer.
- [ ] **TASK-3.4:** Enhance `RestaurantDetailsScreen` and `FoodItemDetailsScreen` with hero covers, dietary tags, and customization sheets.
- [ ] **TASK-3.5:** Verify `QRPaymentScreen` countdown ring, Bakong deep link, and automatic status transition.

### Phase 4 — Driver App Redesign
- [ ] **TASK-4.1:** Streamline `DriverDashboardScreen` availability master toggle with live GPS indicator.
- [ ] **TASK-4.2:** Redesign order cards with pickup ETA, restaurant contact, customer notes, and route navigation.
- [ ] **TASK-4.3:** Enforce strict cash-only confirmation for COD deliveries, routing bank QR to gateway verification.
- [ ] **TASK-4.4:** Verify proof-of-delivery dual modal (QR scanner or 6-digit confirmation PIN).

### Phase 5 — Admin Dashboard Redesign
- [ ] **TASK-5.1:** Polish KPI metric cards in `AdminDashboardScreen` with trend indicators and dual USD/KHR revenue.
- [ ] **TASK-5.2:** Refactor driver verification queue to log actions under `APPROVE_DRIVER` and `SUSPEND_DRIVER`.
- [ ] **TASK-5.3:** Verify active palette dynamic styling, eliminating hardcoded lime contrast violations.

### Phase 6 — API, Database, Auth & Payment Security (Hardened)
- [x] **TASK-6.1:** Restrict `DriverViewSet.verify_payment` strictly to COD cash.
- [x] **TASK-6.2:** Remove `auth_secret is None` bypass in `payment_views.py`.
- [x] **TASK-6.3:** Atomic `select_for_update()` on wallet top-up callbacks.
- [x] **TASK-6.4:** Redact driver PII and live GPS coordinates in serializer for unassigned users.
- [x] **TASK-6.5:** Eliminate mock OTP "1234" views and bind SMS settings.
- [x] **TASK-6.6:** Cleanly applied migration `0023_alter_auditlog_action.py`.

### Phase 7 — Full Stack UI-Backend Integration
- [ ] **TASK-7.1:** Verify real-time cart and order creation with backend PostgreSQL / SQLite.
- [ ] **TASK-7.2:** Verify live WebSocket `/ws/*` tracking via Cloudflare Edge Worker and Daphne ASGI.
- [ ] **TASK-7.3:** Verify Bakong KHQR dynamic payload generation and server-side verification.

### Phase 8 — Comprehensive Testing, Regression & Responsive Layouts
- [x] **TASK-8.1:** Run Django backend test suite (`python manage.py test core`).
- [x] **TASK-8.2:** Run Flutter test suite (`flutter test`).
- [x] **TASK-8.3:** Run Flutter static analysis (`flutter analyze --no-fatal-infos`).
- [ ] **TASK-8.4:** Verify responsive layout across 320px phone, tablet landscape, and desktop viewports.

### Phase 9 — Production Readiness & Final Master Report
- [ ] **TASK-9.1:** Verify release APK compilation (`flutter build apk --release`).
- [ ] **TASK-9.2:** Verify release Web bundle compilation (`flutter build web --release`).
- [ ] **TASK-9.3:** Deliver final 15-section report fulfilling the Definition of Done.

### Phase 10 — Security Hardening, Portal Polish & Next Feature Updates
- [x] **TASK-10.1:** Remove auto-fallback mock Google account chooser modal (`GoogleAuthService`) and align `RegisterScreen` with Phone SMS OTP flow.
- [x] **TASK-10.2:** Close production mock-token bypass (`GoogleLoginView` in `backend/core/auth_views.py`) and remove legacy plaintext password caching in `LoginScreen`.
- [x] **TASK-10.3:** Fix Restaurant Portal wide-grid overflow (`mainAxisExtent`), modal controller leaks, status color coverage, and pull-to-refresh; fix Admin driver assignment async toast & zero-emoji compliance.
- [ ] **TASK-10.4:** Add Restaurant Portal menu item edit/delete bottom sheet and order status filter chips (`Pending`, `Preparing`, `Ready`).
- [ ] **TASK-10.5:** Wire `AdminProvider.approveDriver` / `suspendDriver` action controls into Admin Console Drivers filter view.
- [ ] **TASK-10.6:** Integrate or consolidate Phase 2 scaffolded modules (`FloatingOrderMiniTracker`, `core/network/dio_client.dart`, `l10n/*.arb`, `core/router/app_router.dart`) into active app entrypoint.
- [ ] **TASK-10.7:** Build and re-verify updated APK on physical Android device (`Samsung Galaxy S22 Ultra`) across Restaurant Portal, Register, and Admin screens.
