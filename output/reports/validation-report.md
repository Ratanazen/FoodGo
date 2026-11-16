# FoodGo 10-Chapter Project Presentation — Validation & QA Report

**Audit Date:** 2026-11-15  
**Primary Output:** [`/home/reny/FoodGo/output/final/project-presentation.mp4`](file:///home/reny/FoodGo/output/final/project-presentation.mp4)  
**Builder Script:** [`/home/reny/FoodGo/output/scripts/build_project_presentation.py`](file:///home/reny/FoodGo/output/scripts/build_project_presentation.py)  
**Artifact Copy:** [`/home/reny/.gemini/antigravity/brain/cd7399e3-4f43-48fd-a82e-f7613f1cbe6e/project-presentation.mp4`](file:///home/reny/.gemini/antigravity/brain/cd7399e3-4f43-48fd-a82e-f7613f1cbe6e/project-presentation.mp4)

---

## 1. Deliverables Checklist

| Required Deliverable | File Path | Status | Observed Details |
| :--- | :--- | :---: | :--- |
| Final 10-Chapter MP4 | [`output/final/project-presentation.mp4`](file:///home/reny/FoodGo/output/final/project-presentation.mp4) | **PASS** | `42,042,359` bytes (`41M`), SHA-256 `e9474626f5613f2fc9a469ff7c36dcb05261cef784ce517cb0b81bb3296ca7b7` |
| Artifact Synced MP4 | [`project-presentation.mp4`](file:///home/reny/.gemini/antigravity/brain/cd7399e3-4f43-48fd-a82e-f7613f1cbe6e/project-presentation.mp4) | **PASS** | Exact byte & SHA-256 match (`e9474626f5613f2fc9a469ff7c36dcb05261cef784ce517cb0b81bb3296ca7b7`) |
| Inline Player Widget | [`project_presentation_inline.html`](file:///home/reny/.gemini/antigravity/brain/cd7399e3-4f43-48fd-a82e-f7613f1cbe6e/project_presentation_inline.html) | **PASS** | 10-chapter seek buttons synced to `timeline.json`, local `<source>` tags without `?v=` query strings |
| Narration Script | [`output/scripts/narration.md`](file:///home/reny/FoodGo/output/scripts/narration.md) | **PASS** | Khmer neural narration (`km-KH-PisethNeural`) + English caption summaries across all 10 chapters (`530.47s`) |
| Storyboard | [`output/scripts/storyboard.md`](file:///home/reny/FoodGo/output/scripts/storyboard.md) | **PASS** | 10-chapter / 14-segment timeline, 10 distinct Frame Styles, 8 transparent Minato poses |
| Subtitles (SRT / VTT) | [`output/subtitles/project-presentation.srt`](file:///home/reny/FoodGo/output/subtitles/project-presentation.srt) | **PASS** | `132` timed cues (`.vtt` also synchronized), `0` `...` ellipsis truncations |
| Contact Grid (16-Tile) | [`output/previews/project-presentation-grid.png`](file:///home/reny/FoodGo/output/previews/project-presentation-grid.png) | **PASS** | All 14 segments + Style Catalog summary card + Verified Output Specs card (`4×4` @ `480×270`) |
| Legacy Archive Defense MP4 | [`output/final/foodgo-demo-full.mp4`](file:///home/reny/FoodGo/output/final/foodgo-demo-full.mp4) | **PASS** | Preserved untouched alongside [`output/reports/storyboard.md`](file:///home/reny/FoodGo/output/reports/storyboard.md) |

---

## 2. Media & Encoding Verification (`ffprobe` + `ffmpeg` Decode)

| Check | Command / Evidence | Result | Observed Output |
| :--- | :--- | :---: | :--- |
| File Existence & Non-Zero Size | `ls -lh` + `sha256sum` | **PASS** | `42,042,359` bytes (`41M`), SHA-256 identical across workspace & artifact copies |
| Video Stream (`0:0`) | `ffprobe` | **PASS** | `h264` (`High`), `1920x1080`, `r_frame_rate=30/1`, `nb_frames=15913`, `duration=530.466583s` (`08:50.47` / `8.84 min`) |
| Audio Stream (`0:1`) | `ffprobe` | **PASS** | `aac` (`LC`), `48000 Hz`, `2` channels (stereo), `nb_frames=24867`, `bit_rate=634043` overall, `-16 LUFS` loudnorm |
| Workspace Decode Integrity | `ffmpeg -v error -i output/final/project-presentation.mp4 -f null -` | **PASS** | Exit code `0` (`WS_DECODE_OK`), zero decode errors |
| Artifact Decode Integrity | `ffmpeg -v error -i .../project-presentation.mp4 -f null -` | **PASS** | Exit code `0` (`ART_DECODE_OK`), zero decode errors |
| Subtitle Integrity | `grep -c ' --> '` & `grep -c '\.\.\.'` on `.srt` | **PASS** | `132` timed cues; `0` ellipsis (`...`) truncations |

---

## 3. Visual Frame Inspection (`read_file` PNG Sampling)

Inspected [`project-presentation-grid.png`](file:///home/reny/.gemini/antigravity/brain/cd7399e3-4f43-48fd-a82e-f7613f1cbe6e/project-presentation-grid.png) (`4×4` overview of all 14 rendered segments + 2 capstone summary tiles) and 4 extracted `1920×1080` frames (`chk_p_s01.png`, `chk_p_s04.png`, `chk_p_s07.png`, `chk_p_s10.png`):

| Sampled Target | Status | Verified Visual Elements |
| :--- | :---: | :--- |
| `chk_p_s01.png` (`1. Introduction`, `10.0s`) | **PASS** | ACLEDA University white-pill emblem top-left + hero header, clear purpose paragraph, 5 team member cards (`01 Em Ratana`–`05 Ly KimChhun`), live Flutter app preview (`ch01_intro.mp4`), `OCTAGON SCHOLAR` pod + `standing` Minato sprite, bottom-left 5-member dock, untruncated Khmer/EN captions. |
| `chk_p_s04.png` (`4. Proposed Solution`, `135.0s`) | **PASS** | Crimson/cyan/amber two-column cards (*How FoodGo Solves the Problem* vs *What Makes FoodGo Special?*), `EXPRESS HEX` chamfered pod + transparent `delivery_scooter` Minato sprite, live 4-portal entry screen (`ch03_auth_portals.mp4`), crisp margins & captions. |
| `chk_p_s07.png` (`7. UI/UX & System Architecture`, `295.0s`) | **PASS** | `16` GlassTheme palettes card, `25` ORM classes card, verified `backend/config/asgi.py` (`ProtocolTypeRouter`), large `architecture_diagram.png` center stage, live Khmer home inset (`ch04_home_localization.mp4`), `RADAR ARCHITECT` pod + `investigate` Minato. |
| `chk_p_s10.png` (`10. Conclusion & Q&A`, `500.0s`) | **PASS** | Key Results & Future Roadmap columns, bottom ACLEDA crest + `Questions & Discussion (Q&A)` + all 5 member badges, `KEYNOTE GALA` pod + `standing` Minato, live Q&A outro inset (`ch12_qa_outro.mp4`). |
| `project-presentation-grid.png` (All 14 segments) | **PASS** | All 10 unique Frame Styles (`style1`–`style10`), all 8 clean Minato + Delivery sprites (`standing`, `think`, `find`, `delivery_scooter`, `delivery_bag`, `investigate`, `run`, `delivery_handover`), real mobile recordings across Chapters `5A`, `5B`, `8A`–`8D`, `224/224` & `244/244` KPI cards in Ch `9`, and populated Tiles `15`–`16`. |

---

## 4. Source & Test Verification After Final Edits

| Verification Command | Result | Observed Output |
| :--- | :---: | :--- |
| `/home/reny/FoodGo/backend/venv/bin/python -m unittest discover -s artifacts/foodgo-project-video/studio -p "test_*.py" -v` | **PASS** | `Ran 29 tests in 14.190s` — `OK` |
| `cd backend && ./venv/bin/python manage.py check && ./venv/bin/python manage.py test core` | **PASS** | `System check identified no issues (0 silenced).` / `Found 225 test(s).` / `Ran 225 tests in 10.709s` (exit code `0`) |
| `cd foodgo_flutter && flutter analyze --no-pub && flutter test` | **PASS** | `No issues found! (ran in 4.9s)` / `+249: All tests passed!` |
| `git status --short` | **PASS** | All pre-existing user changes in `backend/` and `foodgo_flutter/` preserved untouched; no `git commit`/`push`. |

---

## 5. Known Disclosures & Baseline Notes

1. **Test Count Evolution:** Earlier repo baseline screenshots/KPI slides recorded `224` Django + `244` Flutter (`468` total); after additional user test edits (`tests_phone_otp.py`, etc.), today's live re-run verified **`225` Django + `249` Flutter = `474` application tests + `29` Video Studio tests (`503` total passing)**.
2. **External Dependencies (Honest Sandbox / Standby):** Local MongoDB Atlas SSL TLSv1 handshake remains disclosed in Chapter `9` (`standby`, app falls back to SQLite cleanly), and `SimoSMS` / `Bakong NBC` rails run in sandbox mode until production merchant credentials are provisioned.
