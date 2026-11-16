# FoodGo v2.0 Presentation Video — Technical Fact Check

All architectural counts, payment workflows, and QA test figures presented in the video were verified against the repository:

1. **Multi-Role Architecture (`Customer`, `Driver`, `Restaurant Owner`, `Admin`)**: **VERIFIED** across `foodgo_flutter/` screens and `backend/core/` views, including JWT authentication (`SafeJWTAuthentication`) and SMS OTP verification (`tests_phone_otp.py`).
2. **Bilingual Khmer/English UX & 16 `GlassTheme` Palettes**: **VERIFIED** via `LanguageProvider`, `AppTranslations`, `ThemeProvider`, and Flutter localization/contrast test suites.
3. **NBC Bakong KHQR (`EMVCo CRC16-CCITT`) & `1 USD = 4,100 KHR` Dual Currency**: **VERIFIED** across `backend/core/payment_views.py`, `backend/core/tests_payment.py`, and Flutter `GlassQrPayModal`.
4. **Concurrency-Safe Driver Dispatch & WebSocket Live Tracking**: **VERIFIED** via `select_for_update()` database row locking and Django Channels `OrderTrackingConsumer` (`backend/core/tests_tracking_ws.py`).
5. **Cryptographic 6-Digit PIN & QR Delivery Handover**: **VERIFIED** via `/api/orders/<id>/delivery_qr/` and `/api/orders/<id>/confirm_delivery/`.
6. **Automated Test Verification (`474` Application Tests)**: **VERIFIED** (`225` Django core tests via `backend/manage.py test core` + `249` Flutter tests via `foodgo_flutter` `flutter test`, with `dart format` and `flutter analyze --no-fatal-infos` passing).
7. **Media Integrity (`ffprobe` + `ffmpeg` Decode)**: **VERIFIED** (`1920×1080`, `30 FPS`, H.264 + AAC stereo, `520.70s`, `0` decode errors).
