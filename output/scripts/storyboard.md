# FoodGo — 10-Chapter Project Presentation Storyboard (8.84 Min Academic Edition)

- **Target Deliverable:** `output/final/project-presentation.mp4` (`1920×1080`, `30 FPS`, `H.264 High`, `AAC-LC 48 kHz Stereo`)
- **Measured Total Duration:** `530.47s` (`08:50.47` across `10` Academic Chapters / `14` rendered segments, `15,913` frames, `42,042,359` bytes / `41M`)
- **Institution & Roster (`AGENTS.md` Invariant):** `សាកលវិទ្យាល័យ ពាណិជ្ជសាស្រ្ត អេស៊ីលីដា` (`ACLEDA University`) + Team Members `01 Em Ratana`, `02 Hen Yaungkuy`, `03 Than Sombath Borarat`, `04 Cheang borin`, `05 Ly KimChhun` + White-Pill Emblem & Styled Chibi Minato / Minato Delivery Pod visible across every frame.
- **Fonts:** Khmer UI/Body (`KantumruyPro-Bold.ttf`, `KantumruyPro-Regular.ttf`), Display (`Moul-Regular.ttf`), Code (`JetBrainsMonoNerdFontMono-Regular.ttf`, `JetBrainsMonoNerdFontMono-Bold.ttf`).
- **Reproducible Render Script:** `output/scripts/build_project_presentation.py` (`./backend/venv/bin/python output/scripts/build_project_presentation.py`)

---

## Global Frame Layout & 10 Frame Styles (`1920×1080`)
- **10 Distinct Frame Styles & Backdrops (`output/previews/styles/`):**
  1. `style1` (`OCTAGON SCHOLAR` — `style1_academic_navy_gold.jpg`, Navy/Gold Octagon Pod)
  2. `style2` (`CINEMA FRAME` — `style3_capcut_neon.jpg`, Crimson/Amber Cinema Perforation Pod)
  3. `style3` (`PRISM HORIZON` — `style_objectives_sunrise.jpg`, Dawn Amber/Sky Prism Pod)
  4. `style4` (`EXPRESS HEX` — `style_solution_fusion.jpg`, Orange/Cyan Chamfered Pod)
  5. `style5` (`SHIELD VAULT` — `style_bakong_fintech_pro.jpg`, Emerald/Gold Security Shield Pod)
  6. `style6` (`CYBER RETICLE` — `style_database_er_stage.jpg`, Violet/Cyan Reticle Pod)
  7. `style7` (`RADAR ARCHITECT` — `style2_tech_blueprint.jpg`, Sky/Gold Concentric Radar Pod)
  8. `style8` (`EQUALIZER LIVE` — `style_radar_city_pro.jpg`, Neon Emerald Telemetry Pod)
  9. `style9` (`MEDALLION QA` — `style4_results_honor.png`, Honor Gold/Green Medallion Pod)
  10. `style10` (`KEYNOTE GALA` — `style_qa_stage_gala.jpg`, Royal Gold/Cyan Gala Pod)
- **8 Clean Transparent Minato & Minato Delivery Sprites (`avatar_poses/`):** `standing`, `think`, `find` (with RMS lip-sync mouth states & blink), `delivery_scooter`, `delivery_bag`, `investigate`, `run`, `delivery_handover`.

---

## 10-Chapter Scene-by-Scene Breakdown (14 Segments)

| Ch. | Segment ID | Window (`start – end`) | Duration | Style / Pose | Focus & Visual Media |
| :---: | :--- | :---: | :---: | :--- | :--- |
| **1** | `s01_intro` | `0:00.00 – 0:43.93` | `43.93s` | `style1` • `standing` | **Introduction:** Project name (`FoodGo Enterprise Platform`), purpose, ACLEDA white-pill crest, 5 individual team member cards & live app inset (`ch01_intro.mp4`). |
| **2** | `s02_problem` | `0:43.93 – 1:21.83` | `37.90s` | `style2` • `think` | **Problem Statement:** Two-column analysis of 4 market problems (Khmer typography, USD/KHR friction, manual bank slips, polling races) & necessity + live inset (`ch04`). |
| **3** | `s03_objectives` | `1:21.83 – 2:01.20` | `39.37s` | `style3` • `find` | **Project Objectives:** 4 objectives paired with concrete benefits for Customers, Restaurant Owners, Drivers & Admins + explore UI inset (`ch05`). |
| **4** | `s04_solution` | `2:01.20 – 2:41.03` | `39.83s` | `style4` • `delivery_scooter` | **Proposed Solution:** Full-stack solution & differentiators (`4,100` rate lock, EMVCo KHQR, HMAC-SHA256 `+855` OTP, atomic DB locks) + portal UI (`ch03`). |
| **5A** | `s05a_features_ui` | `2:41.03 – 3:14.97` | `33.93s` | `style5` • `find` | **Key Features (Part A):** Bilingual Khmer/EN toggle, `$` / `KHR` currency switcher, Explore filters & `FOODGO30` promo cart zoom (`ch05_explore_theme.mp4`, `1.35x`). |
| **5B** | `s05b_features_khqr` | `3:14.97 – 3:52.33` | `37.37s` | `style5` • `delivery_bag` | **Key Features (Part B):** Dynamic EMVCo `CRC16-CCITT` Bakong KHQR generation, `29:50` WebSocket countdown & separate SHA-256 Delivery QR + PIN (`ch07`, `1.44x`). |
| **6** | `s06_tech_stack` | `3:52.33 – 4:39.50` | `47.17s` | `style6` • `investigate` | **Technology Stack:** 3-column repo-verified matrix covering Languages (`Dart 3.12+`, `Python 3.14`), Frameworks (`Flutter 3`, `Django 6.1.2`, `Daphne 4.2.3`), Databases & Tools (`SQLite`, `PostgreSQL 15`, `Redis 8.1`, `MongoDB` standby). |
| **7** | `s07_ui_architecture` | `4:39.50 – 5:19.80` | `40.30s` | `style7` • `investigate` | **UI/UX & System Architecture:** 16 GlassTheme tokens, `25` ORM models list, verified `backend/config/asgi.py` excerpt (`L20-27`) & full `architecture_diagram.png`. |
| **8A** | `s08a_demo_checkout` | `5:19.80 – 5:52.80` | `33.00s` | `style8` • `run` | **Live Demo (Ordering):** Real Flutter app checkout flow zooming `1.38x` onto Cart -> Server Order (`$16.99 / 69,659 KHR`, `ch06_cart_checkout.mp4`). |
| **8B** | `s08b_demo_gps` | `5:52.80 – 6:20.37` | `27.57s` | `style8` • `delivery_scooter` | **Live Demo (GPS Tracking):** Real Phnom Penh OSM map zoom `1.42x` tracking `Bob Rider • 33 km/h • 3 min ETA` & 5-stage progress (`ch09_live_tracking.mp4`). |
| **8C** | `s08c_demo_driver` | `6:20.37 – 6:48.10` | `27.73s` | `style8` • `delivery_handover` | **Live Demo (Driver Portal):** Real Driver Partner app flow: Online toggle, atomic claim & 6-digit PIN / QR handover closeout (`ch10_driver_portal.mp4`). |
| **8D** | `s08d_demo_admin` | `6:48.10 – 7:17.13` | `29.03s` | `style8` • `find` | **Live Demo (Owner & Admin):** Real Admin Console telemetry (`$487.49 / 1,998,709 KHR`, `49` orders, `6` drivers, `5` restaurants, `25` users, audit log, `ch11_owner_admin.mp4`). |
| **9** | `s09_results_challenges` | `7:17.13 – 8:05.53` | `48.40s` | `style9` • `think` | **Results & Challenges:** `224/224` Django + `244/244` Flutter + `29/29` Studio QA tests, `select_for_update()` race fix & floodfill emblem masking; disclosed MongoDB TLSv1 standby & Sandbox keys. |
| **10** | `s10_conclusion_qa` | `8:05.53 – 8:50.47` | `44.93s` | `style10` • `standing` | **Conclusion & Q&A:** Key results summary, future roadmap (`Production Bakong/SimoSMS`, `FCM push`, `Play/App Store`), ACLEDA crest, all 5 team cards & Q&A invitation. |
