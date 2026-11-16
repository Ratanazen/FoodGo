# FoodGo v3.7 Master Architecture & Roadmap Plan

This plan documents the completed v2.0 - v3.7 milestones and the remaining target architecture for subsequent minor releases (v3.8+).

---

## Version Progression Matrix

| Version | Milestone Focus | Status | Details |
| :--- | :--- | :--- | :--- |
| **v2.0** | Foundation, Clean Architecture, Glassmorphism UI | [Passed] Completed | Provider, GoRouter, GlassTheme, Base Design System |
| **v2.1** | Restaurant Catalog & Food Search | [Passed] Completed | Search bar, category filters, real backend food listings |
| **v2.2** | Persistent Cart & Server-Side Totals | [Passed] Completed | Cart quantity controls, server-authoritative calculations |
| **v2.3** | Orders, Statuses & Review System | [Passed] Completed | Order lifecycle, verified delivered review enforcement |
| **v2.4** | Security Hardening & Zero Linter Issues | [Passed] Completed | `flutter_secure_storage`, 0 flutter analyze issues |
| **v2.5** | Mobile OTP Authentication | [Passed] Completed | Phone auth endpoints + Glass OTP interface |
| **v3.0** | Restaurant Owner Management | [Passed] Completed | `RestaurantDashboardScreen`, order state progression |
| **v3.1** | Driver Delivery System | [Passed] Completed | `DriverDashboardScreen`, online/offline toggle |
| **v3.2** | Live Tracking & WebSockets | [Passed] Completed | Django Channels, Daphne, live map simulation |
| **v3.3** | Fintech Digital Wallet & Ledger | [Passed] Completed | User wallet, top-ups, checkout balance validation |
| **v3.4** | Algorithmic Recommendations | [Passed] Completed | Collaborative filtering recommendation endpoint |
| **v3.5** | Web-to-Mobile Responsive Design | [Passed] Completed | 450px centered mobile shell on desktop web |
| **v3.6** | Containerization (Docker Stack) | [Passed] Completed | Dockerfile, docker-compose (Django, Postgres, Redis, Flutter) |
| **v3.7** | CI/CD Automation & Full Audit Docs | [Passed] Completed | GitHub Actions workflow, `.env.example`, `FOODGO_AUDIT.md` |
| **v3.8** | Zero-Leak, Zero-Emoji & Form Fixes | [Passed] Completed | 12 form audits, CSPRNG doorstep QR, 114 automated tests |
| **v3.9** | Customer Convenience & UI Animations | [Passed] Completed | Price tier chips, special cooking instructions, pulse feedback, reorder |
| **v4.0** | Administrator Console & Audit Logging | [Passed] Completed | 5-tab Flutter Admin Dashboard, AuditLog model, 125 automated tests |
| **v4.1** | Dual-Engine Search & Smart Filter System | [Passed] Completed | Dual dish & restaurant scope, persistent history, filter modal, 132 tests |

---

## Remaining Milestones to Final Release (v4.2 - v4.5)

### Phase 4.2: In-App Notifications & Automated Milestone Dispatch
- [x] Connect `Order.save` status transitions to automated `Notification.objects.create`.
- [x] In-App Notification Center with live unread badge on `HomeScreen`.
- [x] Filter notifications by category (`All`, `Orders`, `Promos`).

### Phase 4.3: Real-Time Driver Route WebSocket Simulator
- [x] WebSocket consumer `OrderTrackingConsumer` coordinate broadcasting.
- [x] Update `scripts/simulate_driver.py` with real Phnom Penh delivery route.
- [x] Real-time polyline translation with rotating courier marker on `LiveTrackingScreen`.
- [x] Automated test suite `backend/core/tests_tracking_ws.py` verifying GPS telemetry broadcast & token security.

### Phase 4.4: Dynamic Multi-Currency NBC Rate Engine & App Switcher
- [ ] National Bank of Cambodia (NBC) customary rate caching engine (`4,100 KHR / USD`).
- [ ] App-wide currency toggle in settings updating all prices across menu, cart, checkout, and admin.

### Phase 4.5: Final Production Hardening & Release Sign-Off
- [ ] Database backup and disaster recovery automation (`scripts/backup_db.sh`).
- [ ] Production readiness checklist and security headers audit.
- [ ] Final Zero-Emoji and zero-warning verification across 100% of files.
- [ ] Release tag: `v4.5-production`.

---

## Architecture & Verification Standards
- **Linter Rule:** Strict requirement of zero warnings or errors in `flutter analyze`.
- **Automated Tests:** 132 tests passing (67 Django + 65 Flutter) at 100% pass rate.
- **Backend Standard:** Strict zero-warning requirement in `python manage.py check`.
- **Zero-Emoji Policy:** Vector Material and SVG icons only; zero emojis across all code and documentation.
- **Secret Safety:** All credentials strictly isolated to `.env.example` and omitted from version control.
