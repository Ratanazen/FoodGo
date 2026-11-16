---
name: foodgo-academic-presentation
description: Build 8-10 minute academic capstone presentation videos using Chromium HTML/Canvas motion graphics (onetake + Playwright), clean ACLEDA University branding, real Flutter app screen recordings, synced Khmer neural narration, and verified repo metrics.
---

# FoodGo Academic Capstone Presentation Skill (Chromium Studio Pipeline)

Use this skill whenever producing or updating FoodGo's 8–10 minute senior capstone defense presentation video (`1920x1080`, `30 FPS`, H.264 + `48 kHz` stereo AAC).

## 1. Mandatory 10-Section (14-Chapter) Defense Structure
1. **01 · Introduction** (`seg01_intro`): Project name (`FoodGo`), ACLEDA University of Business crest, 5 team members (`01 Em Ratana`, `02 Hen Yaungkuy`, `03 Than Sombath Borarat`, `04 Cheang borin`, `05 Ly KimChhun`), and multi-role purpose.
2. **02 · Problem Statement** (`seg02_problem`): Khmer typography gaps, manual USD/KHR errors (`1 USD = 4,100 KHR`), manual transfer slip fraud risks, HTTP polling lag.
3. **03 · Project Objectives** (`seg03_objectives`): 1-tap KH/EN switching, automatic dual currency sync, dynamic EMVCo Bakong KHQR, live OSRM map tracking.
4. **04 · Proposed Solution** (`seg04_solution`): Unified 4-role platform (`Customer`, `Driver`, `Restaurant Owner`, `Admin`), JWT + OTP security, Daphne ASGI WebSockets.
5. **05 · Key Features** (`seg05a_features_ui`, `seg05b_features_khqr`): Bilingual discovery, 16 `GlassTheme` palettes, `FOODGO30` promo codes, dynamic EMVCo CRC16 KHQR across Bakong/ABA/ACLEDA/Wing + Delivery PIN/QR tokens.
6. **06 · Technology Stack** (`seg06_tech_stack`): Dart 3 / Flutter 3 + Python / Django REST Framework / Daphne ASGI + PostgreSQL / Redis + OpenStreetMap / OSRM.
7. **07 · UI/UX & System Architecture** (`seg07_architecture`): 4-tier architecture diagram, `26` ORM models (`backend/core/models.py`), `59` REST/WS routes (`backend/core/urls.py`).
8. **08 · Live App Demo** (`seg08a_demo_checkout`, `seg08b_demo_gps`, `seg08c_demo_driver`, `seg08d_demo_admin`): Real Flutter recordings inside `destination-out` matte phone bezels covering Cart/Checkout, Phnom Penh GPS radar, Courier PIN handover, and Owner/Admin console.
9. **09 · Results & Challenges** (`seg09_results`): Verified test metrics (`225` Django core test functions, `249` Flutter unit/widget tests = `474` automated checks) and key concurrency/compositing engineering solutions (`select_for_update()`, exterior floodfill cutouts).
10. **10 · Conclusion & Q&A** (`seg10_conclusion`): Ecosystem impact, future roadmap (production Bakong webhook, push alerts, multi-branch scaling), ACLEDA capstone team credits, and Q&A welcome.

## 2. Studio Architecture & Branding Rules
- **Engine:** Chromium Playwright HTML/Canvas (`output/scripts/studio_master/comp_studio.html` + `motion.js`) paired with `sfx_palette.py` room-reverbed cues and `edge-tts` (`km-KH-PisethNeural`, `+0%`).
- **Every-Frame Invariants (`AGENTS.md`):**
  - Top-left **ACLEDA University** white-pill badge (`សាកលវិទ្យាល័យ ពាណិជ្ជសាស្រ្ត អេស៊ីលីដា`) rendered without color-key damage.
  - Permanent 5-member bottom footer strip (`01 Em Ratana` .. `05 Ly KimChhun`) inside safe margins.
  - Right-side styled presenter pedestal showing clean RGBA Minato poses (`standing`, `think`, `find`, `investigate`, `run`, `delivery_bag`, `delivery_scooter`, `delivery_handover`) with exterior floodfill cutouts (never color-keying white regions).
  - Non-overlapping Chromium-rendered Khmer (`Kantumruy Pro`) + English (`Inter`) caption strip at `y = 896`.
- **Reproducible Deliverable Paths:**
  - Script orchestrator: `output/scripts/build_studio_presentation.py` (`output/scripts/studio_master/*`)
  - Final MP4: `output/final/foodgo-presentation.mp4`
  - Subtitles: `output/subtitles/foodgo-presentation.{srt,vtt}`
  - Visual Grid QA: `output/previews/foodgo-presentation-grid.png`

## 3. Mandatory Verification Gate
Before reporting any presentation video complete:
1. Run `ffprobe` on `output/final/foodgo-presentation.mp4` (confirm `1920x1080`, `30 FPS`, stereo `48 kHz` AAC, duration inside `8–10 min`).
2. Run `ffmpeg -v error -i output/final/foodgo-presentation.mp4 -f null -` and check `volumedetect` headroom (`<= -3.5 dBFS` peak).
3. Extract a 16-frame preview grid from the encoded MP4 and visually inspect frames via `read_file`.
