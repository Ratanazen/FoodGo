# FoodGo v2.0 Presentation Video — Storyboard & Timeline

**Duration**: `08:40.7` (`520.70s`, 14 segments across 10 chapters)  
**Resolution**: `1920×1080` (Full HD, 16:9, `30 FPS`, H.264 + Stereo AAC 48 kHz)  
**Narration**: Khmer (`km-KH-PisethNeural`) with bilingual Khmer + English subtitles  

---

## Segment Breakdown

| # | Segment ID | Window | Chapter | Title | Visual Focus |
| :---: | :--- | :---: | :--- | :--- | :--- |
| 01 | `seg01_intro` | `00:00 – 00:45` | `01 · INTRODUCTION` | FoodGo Smart Delivery Platform | AUB Capstone intro, 5-member team, live Home feed preview, Minato host avatar |
| 02 | `seg02_problem` | `00:45 – 01:26` | `02 · PROBLEM STATEMENT` | Local Delivery Challenges in Cambodia | 4 pain points (Khmer UX/manual FX, screenshot slips, HTTP polling lags) |
| 03 | `seg03_objectives` | `01:26 – 02:10` | `03 · PROJECT OBJECTIVES` | Goals & User Value Targets | 1-tap KH/EN toggle, `1 USD = 4,100 KHR` sync, dynamic KHQR, OSRM GPS |
| 04 | `seg04_solution` | `02:10 – 02:51` | `04 · PROPOSED SOLUTION` | Unified Multi-Portal Architecture | 4 roles secured by SimpleJWT & SMS OTP, live WebSocket event streaming |
| 05 | `seg05a_features_ui` | `02:51 – 03:25` | `05A · FEATURES — UX & PRICING` | Bilingual Discovery & Smart Vouchers | 16 `GlassTheme` palettes, Khmer/EN UI, `FOODGO30` promo & dual currency |
| 06 | `seg05b_features_khqr` | `03:25 – 03:58` | `05B · FEATURES — BAKONG KHQR` | EMVCo Standard & Live Payment Lock | Dynamic EMVCo CRC16-CCITT KHQR (Bakong/ABA/ACLEDA/Wing), WebSocket lock |
| 07 | `seg06_tech_stack` | `03:58 – 04:38` | `06 · TECHNOLOGY STACK` | Production Frameworks & Tooling | Flutter 3 / Dart 3 (`31` screens), Django REST + Daphne ASGI, PostgreSQL/Redis, OSRM |
| 08 | `seg07_architecture` | `04:38 – 05:21` | `07 · UI/UX & ARCHITECTURE` | 4-Layer Architecture & Data Model | 4-tier pipeline across 59 REST/WS API routes and 26 Django ORM models |
| 09 | `seg08a_demo_checkout` | `05:21 – 05:52` | `08A · LIVE DEMO — CHECKOUT` | Real App Flow: Cart to Receipt | Real Flutter capture: cart, `FOODGO30` voucher, dual USD/KHR bill, KHQR receipt |
| 10 | `seg08b_demo_gps` | `05:52 – 06:25` | `08B · LIVE DEMO — GPS TRACKING` | Real-Time Phnom Penh Rider Radar | Live OpenStreetMap polyline, driver marker movement & dynamic ETA steps |
| 11 | `seg08c_demo_driver` | `06:25 – 06:58` | `08C · LIVE DEMO — DRIVER PORTAL` | Courier Shift & Verified Handover | Online toggle, `select_for_update()` claim safety & 6-digit PIN / QR handover |
| 12 | `seg08d_demo_admin` | `06:58 – 07:33` | `08D · LIVE DEMO — OWNER & ADMIN` | Live Merchant & Admin Console | Executive revenue/order telemetry, Bakong/ABA/ACLEDA audit & `AuditLog` |
| 13 | `seg09_results` | `07:33 – 08:07` | `09 · RESULTS & CHALLENGES` | Verified Testing & Engineering Fixes | 474 automated checks (225 Django core + 249 Flutter), locking & WebSocket push |
| 14 | `seg10_conclusion` | `08:07 – 08:41` | `10 · CONCLUSION & Q&A` | ACLEDA University Capstone Finale | Summary, Bakong webhook/push roadmap & ACLEDA University Q&A |
