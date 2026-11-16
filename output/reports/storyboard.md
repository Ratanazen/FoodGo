# FoodGo Mobile App Studio Demonstration — Storyboard & Architecture

## Video Production Metadata
- **Project Name:** FoodGo (Smart Mobile Food Delivery Platform)
- **University:** សាកលវិទ្យាល័យ ពាណិជ្ជសាស្រ្ត អេស៊ីលីដា
- **Development Team (5 Members):**
  1. Em Ratana
  2. Hen Yaungkuy
  3. Than Sombath Borarat
  4. Cheang borin
  5. Ly KimChhun
- **Presentation Style:** Live `540×1170` Portrait Mobile App (`< 650px` adaptive breakpoint) framed inside a studio Titanium Smartphone Bezel on a 1920×1080 dark canvas (Ch02 & Ch12 full-screen 16:9 graphics)
- **Resolution & FPS:** 1920×1080 (16:9 Landscape) @ 30 FPS (`yuv420p`, H.264 High profile)
- **Total Duration:** 433.58 seconds (`07:13`, 13,004 video frames)
- **Audio Codec:** AAC-LC Stereo (`48,000 Hz`, `2 channels`, `177.6 kbps`, normalized `-16.0 LUFS` / TP `-1.5 dB` / LRA `11.0`)
- **Narration Voice:** `km-KH-PisethNeural` (Khmer Neural voice across 12 chapters)
- **Subtitles:** Synchronized sentence-level `foodgo-demo-full.srt` & `foodgo-demo-full.vtt` (`71 cues`, bundled `Kantumruy Pro` typography)
- **2D Puppet Presenter:** New Chibi Minato multi-layer anime rig (`avatar_clean.png`, transparent RGBA from uploaded character sheet) + expressive full-body action poses (`standing` 10-layer rig with idle breathing `1.00–1.03`, hair/bandana sway, `3.6s` blinks, RMS lip-sync, salute wave; `find` pointing-left pose with blinking & RMS lip-sync; `investigate` kneeling pose; `run` dashing pose), soft green studio glow `#22C55E` + drop shadow, speech bubble anchored cleanly above head
- **Interactive Video Player:** `foodgo_demo_player.html` (HTML5 player with live chapter jump grid, subtitle toggle, playback speed, and team roster)

---

## Scene-by-Scene Storyboard Breakdown (12 Chapters • 07:13)

| CH | Title (Khmer / English) | Window | Duration | Layout | Verified UI & Content |
| :---: | :--- | :---: | :---: | :--- | :--- |
| **01** | ការណែនាំគម្រោង និងក្រុមនិស្សិតអភិវឌ្ឍន៍ / Project Intro & University Team | `00:00 – 00:46` | 45.95s | Mobile Studio | Introduces `សាកលវិទ្យាល័យ ពាណិជ្ជសាស្រ្ត អេស៊ីលីដា`, `FoodGo`, all 5 members `01–05`, live `540×1170` mobile home with bottom navigation (`Home`, `Saved`, `Cart`, `Offers`, `Profile`), food photos, and greeting Chibi wave (`0..2.8s`). |
| **02** | ស្ថាបត្យកម្មប្រព័ន្ធ និងបច្ចេកវិទ្យាស្នូល / System Architecture & Tech Stack | `00:46 – 01:28` | 41.87s | 16:9 Diagram | Animated 4-tier architecture diagram (`Flutter Mobile <650px`, `Django REST & Channels WebSockets`, `PostgreSQL + MongoDB`, `Bakong KHQR Gateway`) with live traveling data packets and university engineering credits. |
| **03** | ប្រព័ន្ធសុវត្ថិភាព និងការចូលប្រើប្រាស់តាមតួនាទី / Mobile Auth & Role Portals | `01:28 – 02:03` | 35.13s | Mobile Studio | Live mobile `/login` screen showcasing role-based JWT access (`Customer`, `Driver`, `Restaurant Owner`, `Admin`), credential entry, and smooth sign-in transition as `customer1`. |
| **04** | ទំព័រដើមទូរស័ព្ទ និងការប្តូរភាសា/រូបិយប័ណ្ណ / Mobile Home, Khmer UI & Dual Currency | `02:03 – 02:39` | 35.63s | Mobile Studio | Mobile home feed, navigation bar, profile language switch to Khmer (`🇰🇭 ភាសាខ្មែរ` with `Kantumruy Pro` bottom tabs `ទំព័រដើម`, `រក្សាទុក`, `កន្ត្រក`, `ប្រូម៉ូសិន`, `គណនី`), and Dual Currency (`$ USD / ៛ KHR`). |
| **05** | ការស្វែងរកមុខម្ហូប និង Theme Center / Explore Filters & Theme Center | `02:39 – 03:12` | 33.35s | Mobile Studio | Live mobile `/explore` category/filter chips and navigation into `Theme Center` toggling high-contrast Dark & Light glassmorphism themes. |
| **06** | កន្ត្រកទំនិញឆ្លាតវៃ និងគូប៉ុង FOODGO30 / Interactive Mobile Cart & Promo FOODGO30 | `03:12 – 03:47` | 35.37s | Mobile Studio | Adding mobile menu items into live `/cart`, updating quantities (`2×` items), applying promo code `FOODGO30` (`-30%` discount `-$5.70`, total `$16.29 ≈ ៛66,789 KHR`), and preparing checkout. |
| **07** | ការទូទាត់ប្រាក់ឌីជីថល Bakong KHQR / Dynamic Bakong KHQR Payment Gateway | `03:47 – 04:22` | 34.96s | Mobile Studio | Live freshly regenerated Bakong KHQR payment session (`WAITING FOR PAYMENT`, `Order #FG-20261112-01D649`, `USD 16.99 ≈ ៛69,659 KHR`), live `29:52` WebSocket timer, supported bank badges (`Bakong`, `ABA Bank`, `ACLEDA`, `Wing Bank`), and `Check Payment Status`. |
| **08** | ប្រវត្តិការបញ្ជាទិញ និងវិក្កយបត្រអេឡិចត្រូនិក / Mobile Orders & E-Receipt Viewer | `04:22 – 04:54` | 32.13s | Mobile Studio | Mobile `/orders` tabs (`All`, `Active`, `Delivered`, `Cancelled`), inspecting Delivered `Order #21` ($9.48) via `View Bill` E-Receipt modal with itemized summary and `Copy Receipt TXT`. |
| **09** | ការតាមដានទីតាំង GPS លើផែនទីភ្នំពេញផ្ទាល់ / Live Phnom Penh Map & GPS Tracking | `04:54 – 05:28` | 33.42s | Mobile Studio | Live mobile map tracking screen rendering real OpenStreetMap streets of Phnom Penh, courier pin (`Bob Rider • 38 km/h`), green delivery polyline route, `3 min` ETA badge, and 5-step delivery milestone timeline. |
| **10** | ផ្ទាំងគ្រប់គ្រងសម្រាប់អ្នកបើកបរដឹកជញ្ជូន / Mobile Driver Portal & Earnings | `05:28 – 06:01` | 32.78s | Mobile Studio | Authenticated `driver1` mobile session showing active courier mode, `Available (30)` pool orders, daily/weekly `Earnings`, and `Profile` vehicle statistics. |
| **11** | ផ្ទាំងគ្រប់គ្រងម្ចាស់ហាង និង Admin Console / Mobile Admin & Telemetry Console | `06:01 – 06:33` | 32.10s | Mobile Studio | Authenticated `admin` mobile console showing `Overview` KPIs (`$487.49` revenue, `49` orders), `System Health`, and interactive tab switching to live `Orders` management. |
| **12** | ការផ្ទៀងផ្ទាត់គុណភាព និងក្រុមនិស្សិតសាកលវិទ្យាល័យ / QA Verification & Team Credits | `06:33 – 07:13` | 40.74s | 16:9 Outro | University banner `សាកលវិទ្យាល័យ ពាណិជ្ជសាស្រ្ត អេស៊ីលីដា • FoodGo Capstone Project`, automated QA scoreboard (`221/221 Django Tests`, `235/235 Flutter Tests`, `0 Issues`), numbered `01–05` Team Credits, and closing Chibi wave. |
