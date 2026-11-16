# FoodGo v2.0 — Production Release Checklist & Gates

**Release Candidate:** v2.0.0 (Build 20)  
**Lead Coordinator:** Agent 1 (Integration Architect)  
**Release Rule:** Production deployment is strictly prohibited until every gate below is satisfied and the project owner gives separate explicit deployment authorization.

---

## 1. Security & Fintech Verification Gate

* [ ] **SEC-01:** Driver bank payment backdoor eliminated in `views.py`. Delivery drivers can only verify physical cash collection on COD orders.
* [ ] **SEC-02:** Webhook secret sandbox bypass removed in `payment_views.py`. Webhook callbacks strictly enforce HMAC/secret headers in all environments.
* [ ] **SEC-03:** Wallet top-up balance injection vulnerability secured. Top-ups require pre-created payment intent and authoritative bank verification.
* [ ] **SEC-04:** Sensitive tokens (Bakong JWT, webhook secret) removed from source code fallbacks in `bakong.py` and `payment_views.py`.
* [ ] **SEC-05:** Driver location privacy protected: `DriverViewSet` enforces authentication and redacts courier GPS coordinates for anonymous callers.

---

## 2. Infrastructure & Reliability Gate

* [ ] **INF-01:** Cloudflare Edge proxy (`worker.js`) routes `/ws/*` specifically to Render Daphne ASGI container with `Upgrade: websocket`.
* [ ] **INF-02:** Edge worker health check status masking disabled: authentic backend HTTP 5xx codes reach uptime monitoring probes.
* [ ] **INF-03:** Edge worker cookie cache check bug resolved.
* [ ] **INF-04:** Serverless cold-start auto-migrations eliminated from `asgi.py` / `wsgi.py`.
* [ ] **INF-05:** Database backup script `scripts/backup_db.sh` verified and functional.

---

## 3. UI/UX, Localization & Accessibility Gate

* [ ] **UI-01:** Broken error keys in `glass_states.dart` resolved (`errors.serverError`, `errors.networkError`).
* [ ] **UI-02:** Unlocalized strings across 14 feature modules extracted and registered in `app_translations.dart`.
* [ ] **UI-03:** Frankenstein bilingual string concatenation in `driver_dashboard_screen.dart` fixed.
* [ ] **UI-04:** Negative letter-spacing for Khmer script removed in `glass_bottom_navigation.dart` and shared widgets.
* [ ] **UI-05:** WCAG AA contrast ratio (>= 4.5:1) satisfied on lime accent elements.
* [ ] **UI-06:** Text scaler compounding bug resolved with `clamp(minScaleFactor: 0.85, maxScaleFactor: 1.30)` in `main.dart`.
* [ ] **UI-07:** Portrait orientation lock removed for tablet and desktop web viewports.

---

## 4. Build, Android & QA Gate

* [ ] **BLD-01:** Android release build signing configured with `key.properties` and production keystore (replacing debug keystore fallback).
* [ ] **BLD-02:** Android package namespace and application ID updated to `kh.foodgo.app`.
* [ ] **BLD-03:** `.github/workflows/ci.yml` includes automated Android build job.
* [ ] **QA-01:** Full backend test suite passes with 0 failures (`python backend/manage.py test core`).
* [ ] **QA-02:** Full Flutter test suite passes with 0 failures (`flutter test`).
* [ ] **QA-03:** Zero-warning static analysis policy satisfied (`flutter analyze --no-fatal-infos`).
* [ ] **QA-04:** Physical device ADB installation and smoke test executed on Samsung Galaxy S22 Ultra.

---

## 5. Version Synchronization Gate

* [ ] **VER-01:** `foodgo_flutter/pubspec.yaml` updated to `2.0.0+20`.
* [ ] **VER-02:** `public/version.json` updated to `2.0.0` (Build 20).
* [ ] **VER-03:** Hardcoded `'Build 12'` strings in UI dialogs and screens replaced with `2.0.0 (Build 20)`.

---

## 6. Rollback & Failover Procedures

1. **Edge Worker Rollback:** In the event of edge routing degradation, revert `worker.js` via `npx wrangler rollback` or deploy the prior stable worker revision.
2. **Serverless Rollback:** Rollback Vercel deployment to previous production snapshot via Vercel dashboard or CLI (`vercel rollback`).
3. **Database Restore:** If schema corruption occurs, restore latest automated snapshot using:
   ```bash
   bash scripts/backup_db.sh restore <snapshot_file.sql.gz>
   ```
4. **Android Client Rollback:** Release candidate APKs are version-gated with incremented `versionCode: 20` to guarantee forward compatibility.
