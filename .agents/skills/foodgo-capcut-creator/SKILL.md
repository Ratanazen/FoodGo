---
name: foodgo-capcut-creator
description: Automated Studio Master & CapCut Pro video pipeline for FoodGo: multi-track timeline JSON builder, ACLEDA University 8-10 min academic presentation assembler (Chromium + onetake SFX + FFmpeg), and bilingual Khmer/English caption workflows.
---

# FoodGo Studio Master & CapCut Creator Skill

Authoritative workflow for assembling FoodGo video deliverables cleanly across both automated Chromium Studio pipelines (`output/scripts/build_studio_presentation.py`) and CapCut pack structures (`output/capcut-pack/`).

## 1. Verified FoodGo Engineering Facts (Source-Checked)
Always ground scripts, cards, and metrics directly in repository sources—never invent numbers:
- **Backend Models & Routes:** `26` ORM models in `backend/core/models.py` (`User` + `25` domain models); `59` URL paths in `backend/core/urls.py`.
- **Verified Tests:** `225` Django backend test functions (`backend/core/`) and `249` Flutter tests (`foodgo_flutter/test/`).
- **Currency & Payments:** Exact `1 USD = 4,100 KHR` FX sync; dynamic EMVCo Bakong KHQR (`CRC16-CCITT`, Tag 99) compatible with Bakong, ABA, ACLEDA, and Wing.
- **Real-Time Dispatch:** Daphne ASGI + Django Channels WebSockets, `select_for_update()` atomic driver claim lock, OpenStreetMap + OSRM routing in Phnom Penh.

## 2. Studio Master Production Pipeline
- **Layout Geometry (`1920x1080`, `30 FPS`):**
  - Left mobile recordings (`344x744` scaled from `540x1170` raw Flutter captures in `output/capcut-pack/media/01_raw_mobile_clips/`) composited seamlessly behind Chromium `destination-out` rounded phone cutouts (`x=96, y=126, r=28`).
  - Chromium HTML/Canvas (`comp_studio.html`) handles alternating Obsidian Night (`#100C0A`) and Warm Cream Paper (`#F7F0E6`) backgrounds, Fraunces + Kantumruy Pro typography, ACLEDA University white-pill emblem, right Minato RGBA pedestal, and permanent 5-member ACLEDA team footer (`01 Em Ratana` .. `05 Ly KimChhun`).
  - **Caption Strip (`y=896`, `1920x114`):** Rendered directly in Chromium Playwright (`__renderCaptionOnly`) to avoid `libass` Khmer subscript rendering bugs and activated at exact millisecond intervals via FFmpeg `overlay=0:896:enable='between(t,...)'`.
- **Voiceover & Audio Mix:**
  - `edge-tts` (`km-KH-PisethNeural`, `rate=+0%`). Keep Khmer sentences concise and natural so Bing Khmer G2P synthesizes reliably without `NoAudioReceived`.
  - Mix with `onetake/scripts/sfx_palette.py` (`Score`, `sub`, `air`, `wood`, `bubble`, `glass`) at `48000 Hz` stereo with dynamic speech ducking (`max_volume <= -3.5 dBFS`).

## 3. Clean Workspace Hygiene & Verification
- Maintain a single authoritative deliverable in `output/final/foodgo-presentation.mp4` (+ synced `output/subtitles/foodgo-presentation.{srt,vtt}` and `output/previews/foodgo-presentation-grid.png`); remove stale intermediate MP4s or players after verified replacement.
- Never append `?v=` cache-busting query strings in inline HTML players; always include relative filename + `file:///...` fallback `<source>` tags and keep inline embed cards compact (`height <= 440px`).
- Never commit or push automatically without explicit user permission.
