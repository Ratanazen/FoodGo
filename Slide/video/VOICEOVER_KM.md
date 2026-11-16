# FoodGo v2.0 Presentation Video — Khmer Narration & Bilingual Subtitles

- **Voice Engine**: `edge-tts` (`km-KH-PisethNeural`, rate `+0%`)
- **Total Cues**: `48` bilingual Khmer + English cues (also exported in [`foodgo-presentation.srt`](./foodgo-presentation.srt) and [`foodgo-presentation.vtt`](./foodgo-presentation.vtt))

---

## Key Script Segments

- **01 · Introduction (`00:00 – 00:45`)**: Introduces the 5-member ACLEDA University capstone team (`01 Em Ratana`, `02 Hen Yaungkuy`, `03 Than Sombath Borarat`, `04 Cheang borin`, `05 Ly KimChhun`) and the multi-role Phnom Penh food delivery platform.
- **02–04 · Problem, Objectives & Solution (`00:45 – 02:51`)**: Contrasts manual USD/KHR calculation, screenshot payment slips, and HTTP polling against FoodGo's 1-tap bilingual UI, `1 USD = 4,100 KHR` pricing, dynamic Bakong KHQR, JWT/OTP security, and WebSocket event push.
- **05A–07 · Features, Tech Stack & Architecture (`02:51 – 05:21`)**: Covers `16` `GlassTheme` palettes, `FOODGO30` promo logic, EMVCo CRC16-CCITT KHQR (`Bakong`, `ABA`, `ACLEDA`, `Wing`), `31` Flutter screens, `59` Django REST/WebSocket API routes, `26` ORM models, PostgreSQL + Redis, and OpenStreetMap OSRM routing.
- **08A–08D · Real App Walkthroughs (`05:21 – 07:33`)**: Demonstrates end-to-end Flutter checkout, live Phnom Penh courier tracking, atomic driver job claims (`select_for_update()`), 6-digit PIN / QR handover confirmation, and Owner/Admin Console telemetry + `AuditLog`.
- **09–10 · Verified Results & Conclusion (`07:33 – 08:41`)**: Summarizes `474` verified automated software checks (`225` Django core + `249` Flutter tests), race-condition/WebSocket engineering fixes, production roadmap, and Capstone Q&A closing.

Full line-by-line timecoded Khmer and English cues are stored in [`foodgo-presentation.srt`](./foodgo-presentation.srt) and [`foodgo-presentation.vtt`](./foodgo-presentation.vtt).
