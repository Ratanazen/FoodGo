# FoodGo v2.0 — Architecture & Codebase Audit Report

**Audit Date:** 2026-11-01  
**Target Repository:** `Ratanazen/FoodGo`  
**Lead Architect:** Agent 1 (Integration & Architecture)  
**Contributors:** Agent 2 (UI/UX & Localization), Agent 3 (Backend & Reliability), Agent 4 (Payment & Security), Agent 5 (QA Automation & Release)

---

## 1. Repository Inventory & Baseline State

* **Repository Root:** `/home/reny/FoodGo`
* **Current Branch:** `main` (ahead of `origin/main` by 1 commit: `2b688a9`)
* **Frameworks:**
  * Client: Flutter 3.29.x / Dart 3.7+ (`foodgo_flutter/`) with Web & Android targets
  * Backend: Django 5.1 / Daphne ASGI 4.1 (`backend/`)
  * Proxy: Cloudflare Edge Worker (`worker.js`)
  * Hosting Targets: Vercel Serverless (`api/index.py`), Render Container (`render.yaml`)
* **Databases:** PostgreSQL (production), SQLite (`/tmp/db.sqlite3` serverless fallback), MongoDB Atlas (telemetry & menu mirror)

---

## 2. Subsystem Audit Findings

### 2.1 UI/UX, Frontend & Localization (Agent 2)
1. **Localization Coverage:** 14 out of 21 feature modules have 0% localization calls (`context.tr()`), including `admin/`, `orders/`, `restaurants/`, `search/`, and `support/`.
2. **Broken Translation Keys:** `glass_states.dart` references non-existent keys `errors.serverError` and `errors.networkError`, rendering raw string keys on UI errors.
3. **Frankenstein Concatenation:** `driver_dashboard_screen.dart` concatenates translated Khmer with English: `'${context.tr('driver.online')} & Available'`.
4. **Typography:** `AppTypography` class exists in `lib/core/theme/` but is never imported or used. English text uses `GoogleFonts.inter` without local bundling in `assets/fonts/`, posing offline rendering risks.
5. **Khmer Glyph Rendering:** `glass_bottom_navigation.dart` forces `letterSpacing: -0.2` which corrupts Khmer subscript ligatures.
6. **Accessibility & Contrast:** Lime accent (`#CCFF00`) with white text has a contrast ratio of 1.3:1 (fails WCAG AA 4.5:1).
7. **Orientation Lock:** `main.dart` forces `DeviceOrientation.portraitUp/Down`, breaking tablet and desktop web layouts.

### 2.2 Backend, APIs, Database & Reliability (Agent 3)
1. **Edge WebSocket Dropping:** `worker.js` proxy only intercepts `/api/`, `/health`, `/admin`, `/static/`, `/media/`. WebSocket paths (`/ws/*`) fall through and are dropped by Cloudflare.
2. **Cold-Start Anti-Pattern:** `asgi.py` unconditionally invokes migrations and admin creation on serverless cold starts.
3. **Driver Location Exposure:** `DriverViewSet` has `AllowAny` permission at class level, allowing unauthenticated anonymous queries to fetch driver GPS coordinates and emails.
4. **Idempotency TOCTOU:** In `OrderViewSet.create`, the idempotency key is cached *after* the database write. Without Redis, in-memory cache misses occur across serverless instances.
5. **Ephemeral State:** When `DATABASE_URL` is omitted, Vercel writes to `/tmp/db.sqlite3` which is wiped on container recycle and never syncs with Render.
6. **Audit Log Actions:** `AuditLog.ACTION_CHOICES` lacks driver approval/suspension options, mislabeling admin driver actions as `UPDATE_MENU_ITEM`.

### 2.3 Payment, OTP & Security (Agent 4)
1. **CRITICAL Driver Verification Backdoor:** `DriverViewSet.verify_payment` allows couriers to unilaterally mark bank QR payments (Bakong, ABA, ACLEDA) as `PAID` without bank authorization.
2. **CRITICAL Webhook Sandbox Bypass:** `payment_views.py:L316-L325` allows `auth_secret is None` when `PAYMENT_ENV != 'production'`, permitting unauthenticated callback forgery in sandbox.
3. **CRITICAL Wallet Top-Up Injection:** Top-up callback in `payment_views.py` credits arbitrary amounts without pre-existing payment records or bank validation.
4. **SMS Gateway Bug:** `settings.py` never exports `SMS_API_KEY` from `os.environ` to `django.conf.settings`, breaking real SMS OTP dispatch.
5. **Credential Hygiene:** Hardcoded fallback JWT token in `bakong.py:L25` and fallback webhook secret in `payment_views.py:L312`.

### 2.4 QA Automation, Android Build & CI/CD (Agent 5)
1. **Android Release Keystore:** `android/app/build.gradle.kts` signs release builds with debug keys. Namespace remains default `com.example.foodgo_flutter`.
2. **CI/CD Gap:** `.github/workflows/ci.yml` builds Flutter Web, but completely omits Android build verification (`flutter build apk`).
3. **Version Drift:** UI screens hardcode `'Build 12'`, `pubspec.yaml` specifies `1.1.0+1`, and backend specifies `4.6.0`.
4. **Test Baseline:** 25 Flutter test files (~185 tests) and 9 Django test files (155 tests). Missing E2E integration test suite.

---

## 3. Prioritized Defect Matrix

| ID | Severity | Module | Description | Status |
| :--- | :--- | :--- | :--- | :--- |
| SEC-01 | P0 Critical | Backend Payments | Driver bank payment verification backdoor | Pending Fix |
| SEC-02 | P0 Critical | Backend Webhooks | Webhook callback sandbox secret bypass | Pending Fix |
| SEC-03 | P0 Critical | Backend Wallet | Arbitrary wallet top-up balance injection | Pending Fix |
| BLD-01 | P0 Critical | Android Gradle | Release build signs with debug keystore | Pending Fix |
| SEC-04 | P1 High | Backend Privacy | Driver location data leakage on `GET /api/drivers/` | Pending Fix |
| NET-01 | P1 High | Edge Proxy | Cloudflare Worker drops `/ws/*` WebSocket traffic | Pending Fix |
| OTP-01 | P1 High | Backend SMS | `settings.py` missing SMS configuration exports | Pending Fix |
| I18N-01 | P1 High | Flutter UI | 14 feature screens unlocalized; broken error keys | Pending Fix |
| UI-01 | P2 Medium | Flutter UI | WCAG contrast violation on lime accent | Pending Fix |
| VER-01 | P2 Medium | Client & Build | Version drift across UI, pubspec, and version.json | Pending Fix |
