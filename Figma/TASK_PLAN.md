# FoodGo v2.0 — Master Autonomous Task Plan

**Last Updated**: November 2026  
**Status Legend**:  
- `PASS`: Successfully implemented, executed, and verified.  
- `FAIL`: Attempted, resulted in an active defect.  
- `BLOCKED`: Prevented by missing external permissions or sandboxed tool unavailability.  
- `NOT RUN`: Deferred to a future milestone.  

---

## Task Matrix

| Task ID | Description | Role / Agent | Affected Files | Status | Test / Verification |
|---|---|---|---|---|---|
| **TASK-01** | Repository & Git Audit | DevOps Lead | Root, Git history | `PASS` | Git log, status, branch checked |
| **TASK-02** | Splash Screen Hang Fix | Mobile Engineer | `splash_screen.dart`, `secure_storage.dart` | `PASS` | Fallback timer & non-blocking auth test |
| **TASK-03** | KHQR Scan & Pay Flow | Fintech Engineer | `glass_qr_pay_modal.dart`, `checkout_screen.dart` | `PASS` | USD/KHR toggle & transaction verified |
| **TASK-04** | Figma MCP Connection Check | Systems Architect | Figma MCP configuration | `BLOCKED` | Plugin not installed; card surfaced |
| **TASK-05** | UI/UX & Technical Audit | Lead Designer | `docs/v2/UI_UX_AUDIT.md`, `docs/v2/AUDIT.md` | `PASS` | Architecture & screen matrix created |
| **TASK-06** | Emerald Glass Design System | Design Systems Lead | `docs/v2/DESIGN_SYSTEM.md`, `glass_theme.dart` | `PASS` | Color tokens & 8pt elevation verified |
| **TASK-07** | Screen Specs & Handoff | Product Designer | `docs/v2/SCREEN_SPECIFICATIONS.md`, `FIGMA_HANDOFF.md` | `PASS` | All 18 screen flows documented |
| **TASK-08** | Cambodian Localization System | Localization Lead | `language_provider.dart`, `main.dart` | `PASS` | Khmer/EN toggle unit tests passing |
| **TASK-09** | Food Customizer Modal | UI Engineer | `glass_food_customizer_modal.dart`, `restaurant_details_screen.dart` | `PASS` | Portion sizes, spice & toppings verified |
| **TASK-10** | Cart Free Delivery & Tip | Full-Stack Dev | `cart_provider.dart`, `cart_screen.dart` | `PASS` | Threshold & driver tip unit tests passing |
| **TASK-11** | Driver Delivery Portal UI | Mobile Engineer | `driver_dashboard_screen.dart`, `app_router.dart` | `PASS` | Online duty toggle & trip progression verified |
| **TASK-12** | Restaurant KDS Admin Portal | Web/Mobile Dev | `admin_dashboard_screen.dart`, `app_router.dart` | `PASS` | Live orders Kanban & stock toggle verified |
| **TASK-13** | Backend Seed Data (Khmer Cuisine)| Backend Engineer | `seed_data.py`, `models.py` | `PASS` | Amok, Lok Lak, Kuy Teav seeded |
| **TASK-14** | Django API Test Suite | QA Engineer | `backend/core/tests.py` | `PASS` | 5/5 Django REST tests passing |
| **TASK-15** | Flutter Unit Test Suite | QA Engineer | `foodgo_flutter/test/providers_test.dart` | `PASS` | 9/9 Flutter unit tests passing |
| **TASK-16** | Flutter Static Analysis | QA Engineer | `foodgo_flutter/` | `PASS` | `flutter analyze` 0 issues |
| **TASK-17** | Video Showcase Docs | Media Director | `docs/video/STORYBOARD.md`, `VOICEOVER_KM.md` | `PASS` | 5-minute Khmer video storyboard ready |
| **TASK-18** | Architecture & Release Docs | Release Lead | `docs/v2/ARCHITECTURE.md`, `RELEASE_CHECKLIST.md` | `PASS` | Verification check passed |
