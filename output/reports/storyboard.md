# FoodGo 7–10 Minute Master Animated Demonstration — Storyboard & Architecture

## Video Production Metadata
- **Project:** FoodGo (Flutter Web & Mobile + Django REST Framework + Bakong KHQR)
- **Target Resolution:** 1920×1080 (16:9 Landscape)
- **Framerate:** 30 FPS
- **Video Codec:** H.264 (AVC `yuv420p`, CRF 18)
- **Audio Codec:** AAC Stereo (192 kbps, 48 kHz, loudness normalized to -16 LUFS)
- **Narration Voice:** `km-KH-PisethNeural` (Khmer Male Neural Narrator with native English tech terms)
- **Subtitles & Fonts:** Bundled `Kantumruy Pro` (Khmer) + Inter (English), synchronized SRT & burned-in bilingual speech bubbles
- **2D Puppet Presenter:** 10-layer Chibi anime character rig (`avatar_clean.png`, sitting pose, transparent background, soft green glow `#22C55E`, idle breathing scale `1.00–1.03`, headband/hair sway, 3.5s blinks, RMS-volume lip-sync, intro hand wave, outro celebratory nod).

---

## Scene-by-Scene Storyboard Breakdown

### Chapter 01: Hook & Product Introduction
- **Duration:** 33.1s (`0:00 – 0:33`)
- **Visual Capture:** Live FoodGo landing view (`http://127.0.0.1:8089/#/home`), smooth cursor scroll across popular dishes, category pills, and 50% OFF promo banner.
- **Avatar Pose & Position:** Enlarged in center (`700px`), greeting hand-wave (`±12°`), soft green glow aura, smooth easing glide to bottom-right anchor at `t=2.2s`.
- **Speech Bubble (Khmer + English):**
  - KM: `ស្វាគមន៍មកកាន់ FoodGo • Smart Food Delivery`
  - EN: `Full App Showcase • Flutter + Django + Bakong KHQR`
- **Narration (Khmer):**
  > សូមស្វាគមន៍មកកាន់ការបង្ហាញជាផ្លូវការនៃ FoodGo App! FoodGo គឺជាប្រព័ន្ធកម្មវិធីបញ្ជាទិញ និងដឹកជញ្ជូនអាហារទំនើបកម្រិតអាជីព ដែលត្រូវបានបង្កើតឡើងយ៉ាងពិសេសសម្រាប់ប្រទេសកម្ពុជា។ នៅក្នុងវីដេអូនាពេលនេះ យើងនឹងនាំលោកអ្នកទៅពិនិត្យមើលគ្រប់មុខងារជាក់ស្តែងទាំងអស់ ចាប់តាំងពីផ្ទាំងកម្មវិធីទូរស័ព្ទ Flutter ដ៏ទាក់ទាញ ការទូទាត់ប្រាក់ភ្លាមៗតាម Bakong KHQR, ABA PAY និង ACLEDA, ការតាមដានការដឹកជញ្ជូនតាមផែនទី GPS ផ្ទាល់ រហូតដល់ប្រព័ន្ធគ្រប់គ្រង Admin និង Driver Dashboard ពេញលេញ។ តោះចាប់ផ្តើមជាមួយគ្នា!

---

### Chapter 02: System Architecture & Tech Stack
- **Duration:** 36.7s (`0:33 – 1:10`)
- **Visual Capture:** Full-screen 1920×1080 animated architecture diagram with live pulsating data packets connecting 4 core tiers:
  1. Frontend Client: Flutter Web/Mobile (Glassmorphism, Kantumruy Pro Khmer, Dual Currency, GoRouter)
  2. Server Engine: Django REST Framework & Django Channels WebSockets (Port `:8000`, JWT Auth, Throttling)
  3. Database Tier: PostgreSQL Database & MongoDB Audit Logs (Docker, Connection Health Checks)
  4. Payment Gateway: Cambodia Bakong KHQR SDK (EMVCo Dynamic TLV, ABA Pay & ACLEDA Webhooks)
- **Avatar Pose & Position:** Bottom-right anchor (~25% footprint), idle breathing + head tilt, soft green glow.
- **Speech Bubble:**
  - KM: `ស្ថាបត្យកម្មប្រព័ន្ធ • Flutter + Django REST`
  - EN: `WebSockets • PostgreSQL • MongoDB • Bakong SDK`
- **Narration (Khmer):**
  > ចំពោះស្ថាបត្យកម្មបច្ចេកវិទ្យា FoodGo ត្រូវបានរៀបចំឡើងយ៉ាងរឹងមាំ និងមានស្តង់ដារខ្ពស់។ ផ្នែកខាងមុខ Frontend ប្រើប្រាស់ Flutter គាំទ្រទាំង iOS, Android និង Web ជាមួយ Glassmorphism UI ទំនើប។ ផ្នែកខាងក្រោយ Backend ដំណើរការដោយ Django REST Framework សហការជាមួយ Django Channels សម្រាប់ WebSockets ដើម្បីធ្វើបច្ចុប្បន្នភាពទិន្នន័យការបញ្ជាទិញ និងទីតាំងអ្នកដឹកជញ្ជូនក្នុងពេលជាក់ស្តែង។ ទិន្នន័យស្នូលត្រូវបានរក្សាទុកដោយសុវត្ថិភាពលើ PostgreSQL និង MongoDB សម្រាប់ទិន្នន័យ logs ព្រមទាំងភ្ជាប់ជាមួយ Bakong KHQR SDK ដោយផ្ទាល់ ធានាបាននូវដំណើរការលឿន និងមានសុវត្ថិភាពខ្ពស់។

---

### Chapter 03: Authentication & Multi-Role Portals
- **Duration:** 29.9s (`1:10 – 1:40`)
- **Visual Capture:** Live `/login` screen showing role tabs (`Customer`, `Driver`, `Restaurant Owner`, `Admin`), username/password inputs, and authenticating with demo account `customer1`.
- **Avatar Pose & Position:** Bottom-right anchor, pointing gesture, RMS lip-sync.
- **Speech Bubble:**
  - KM: `ការចូលប្រើប្រាស់តាមតួនាទី • Multi-Role Access`
  - EN: `Customer • Driver • Restaurant Owner • Admin`
- **Narration (Khmer):**
  > FoodGo មានប្រព័ន្ធផ្ទៀងផ្ទាត់អត្តសញ្ញាណដ៏រឹងមាំ ដោយគាំទ្រការចូលប្រើប្រាស់តាមតួនាទីផ្សេងៗគ្នា រួមមាន អតិថិជនទូទៅ អ្នកបើកបរដឹកជញ្ជូន ម្ចាស់ហាងអាហារ និងអ្នកគ្រប់គ្រងប្រព័ន្ធ Admin។ យើងមានគណនីគំរូដែលត្រៀមរួចជាស្រេច ដើម្បីធ្វើតេស្តប្រព័ន្ធភ្លាមៗ។ ការចូលប្រើប្រាស់ត្រូវបានការពារដោយ JWT Token Authentication, CSRF Protection, និងការត្រួតពិនិត្យសុវត្ថិភាពតឹងរ៉ឹងលើគ្រប់ API Endpoints។ ឥឡូវនេះ យើងនឹងចូលប្រើជាគណនីអតិថិជន customer1 ដើម្បីមើលបទពិសោធន៍ផ្ទាល់!

---

### Chapter 04: Home Screen, Khmer Localization & Currency
- **Duration:** 33.9s (`1:40 – 2:14`)
- **Visual Capture:** Live `/home` screen, header interaction switching language between Khmer (`Kantumruy Pro`) and English, toggling `USD` / `KHR` / `DUAL` currency mode, and browsing popular food cards.
- **Avatar Pose & Position:** Bottom-right anchor, head tilt nod on toggle.
- **Speech Bubble:**
  - KM: `ទំព័រដើមអតិថិជន • គាំទ្រភាសាខ្មែរពេញលេញ`
  - EN: `Khmer Kantumruy Pro • Dual Currency USD / KHR`
- **Narration (Khmer):**
  > នេះជាទំព័រដើម FoodGo ដ៏ស្រស់ស្អាត! ចំណុចពិសេសដំបូងគេ គឺការគាំទ្រភាសាខ្មែរ និងអង់គ្លេសយ៉ាងរលូន ដោយប្រើប្រាស់ពុម្ពអក្សរ Kantumruy Pro ដ៏ច្បាស់ និងត្រឹមត្រូវតាមក្បួនខ្នាត។ លើសពីនេះ ប្រព័ន្ធគាំទ្ររូបិយប័ណ្ណពីរ គឺប្រាក់ដុល្លារអាមេរិក USD និងប្រាក់រៀលខ្មែរ KHR ជាមួយមុខងារ Dual Currency Switcher ដែលអនុញ្ញាតឱ្យបង្ហាញតម្លៃទាំងពីរទន្ទឹមគ្នា។ នៅផ្នែកខាងលើមាន Banner ប្រូម៉ូសិនបញ្ចុះតម្លៃ រួមជាមួយបញ្ជីមុខម្ហូបពេញនិយម និងការបែងចែកប្រភេទអាហារច្បាស់លាស់ ដូចជា បឺហ្គឺរ, ភីហ្សា, ស៊ូស៊ី និងមាន់បំពង។

---

### Chapter 05: Explore, Filter Chips & Theme Center
- **Duration:** 32.6s (`2:14 – 2:47`)
- **Visual Capture:** Live `/explore` screen with active filter chips (`Burger`, `Pizza`, `Sushi`, `Chicken`), transitioning to `/theme-center` and toggling Light Glass mode to demonstrate high-contrast text and border readability.
- **Avatar Pose & Position:** Bottom-right anchor, RMS lip-sync, subtle breathing.
- **Speech Bubble:**
  - KM: `ស្វែងរកមុខម្ហូប • Light & Dark Glass Theme`
  - EN: `High Contrast Text Fix • Filter Chips • Responsive`
- **Narration (Khmer):**
  > នៅទំព័រ Explore អតិថិជនអាចស្វែងរកមុខម្ហូបដែលខ្លួនចូលចិត្តបានយ៉ាងងាយស្រួល តាមរយៈ Filter Chips និងការស្វែងរកភ្លាមៗក្នុងពេលជាក់ស្តែង។ ពិសេសជាងនេះទៅទៀត FoodGo ផ្តល់នូវ Theme Center ទំនើប ដែលអនុញ្ញាតឱ្យផ្លាស់ប្តូររវាង Dark Mode និង Light Mode បានគ្រប់ពេលវេលា។ នៅក្នុងការអាប់ដេតចុងក្រោយនេះ យើងបានដោះស្រាយបញ្ហាកម្រិតពន្លឺអក្សរក្នុង Light Mode ដោយធានាថា អក្សរពណ៌ខ្មៅដិត និងពណ៌កម្រិតខ្ពស់ អាចមើលឃើញយ៉ាងច្បាស់នៅលើផ្ទៃកញ្ចក់ Glassmorphism ស្របតាមស្តង់ដារ Accessibility និង UI/UX លំដាប់ពិភពលោក។

---

### Chapter 06: Menu Detail, Options & Interactive Cart
- **Duration:** 30.4s (`2:47 – 3:17`)
- **Visual Capture:** Live `/cart` view, item quantity modifications, breakdown of subtotal, auto tax, and applying promotional voucher `FOODIE30` (30% discount) and `FREESHIP`.
- **Avatar Pose & Position:** Bottom-right anchor, pointing gesture toward cart breakdown.
- **Speech Bubble:**
  - KM: `កន្ត្រកទំនិញឆ្លាតវៃ • Interactive Cart`
  - EN: `Custom Options • Coupon FOODIE30 • Auto Tax`
- **Narration (Khmer):**
  > នៅពេលជ្រើសរើសមុខម្ហូបណាមួយ អតិថិជនអាចកំណត់បរិមាណ បន្ថែមគ្រឿងផ្សំពិសេស និងកត់ត្រាចំណាំផ្ទាល់ខ្លួនទៅកាន់ចុងភៅបានយ៉ាងលម្អិត។ នៅពេលបន្ថែមទៅក្នុងកន្ត្រកទំនិញ ប្រព័ន្ធនឹងគណនាតម្លៃសរុប ពន្ធ និងថ្លៃសេវាដឹកជញ្ជូនដោយស្វ័យប្រវត្តិ។ អតិថិជនក៏អាចបញ្ចូលគូប៉ុងបញ្ចុះតម្លៃពិសេស ដូចជា FOODIE30 ដើម្បីទទួលបានការបញ្ចុះតម្លៃសាមសិបភាគរយ ឬកូដ FREESHIP សម្រាប់ការដឹកជញ្ជូនដោយឥតគិតថ្លៃ។ អ្វីៗដំណើរការយ៉ាងរលូន និងឆ្លើយតបភ្លាមៗដោយគ្មានភាពស្មុគស្មាញឡើយ!

---

### Chapter 07: Cambodia Bakong KHQR & Bank Payments
- **Duration:** 36.1s (`3:17 – 3:53`)
- **Visual Capture:** Live `/qr-payment` screen displaying dynamically rendered Bakong KHQR code with EMVCo TLV string, merchant details, bank logos (Bakong, ABA Mobile, ACLEDA Mobile), and real-time status polling banner.
- **Avatar Pose & Position:** Bottom-right anchor, excited head tilt, soft green glow.
- **Speech Bubble:**
  - KM: `ទូទាត់ប្រាក់តាម KHQR • Bakong, ABA, ACLEDA`
  - EN: `EMVCo Dynamic TLV • Real-Time Status Polling`
- **Narration (Khmer):**
  > នេះគឺជាបេះដូងដ៏សំខាន់នៃ FoodGo គឺប្រព័ន្ធទូទាត់ប្រាក់តាមស្តង់ដារជាតិ Bakong KHQR! នៅពេលអតិថិជនបញ្ជាក់ការបញ្ជាទិញ ប្រព័ន្ធ Backend នឹងបង្កើតកូដ QR ឌីណាមិកតាមស្តង់ដារ EMVCo TLV ភ្លាមៗ ដែលផ្ទុកនូវព័ត៌មានទឹកប្រាក់ លេខយោងវិក្កយបត្រ និងគណនីហាងយ៉ាងត្រឹមត្រូវ។ អតិថិជនអាចស្កេនទូទាត់តាមរយៈ App ធនាគារនានាក្នុងប្រទេសកម្ពុជា ដូចជា Bakong App, ABA Mobile, ឬ ACLEDA Mobile។ ប្រព័ន្ធ Webhook និង Background Polling នឹងត្រួតពិនិត្យស្ថានភាពការបង់ប្រាក់ក្នុងពេលជាក់ស្តែង នៅពេលទទួលបានប្រាក់ជោគជ័យ ប្រព័ន្ធនឹងផ្លាស់ប្តូរស្ថានភាពទៅជា PAID ដោយស្វ័យប្រវត្តិតែម្តង!

---

### Chapter 08: Orders History, Filter & E-Receipt Viewer
- **Duration:** 28.1s (`3:53 – 4:21`)
- **Visual Capture:** Live `/orders` screen with order status filter tabs (`Active`, `Completed`, `Cancelled`), opening the "View Bill" electronic receipt modal with Structured Summary Viewer and KHQR TLV payload.
- **Avatar Pose & Position:** Bottom-right anchor, RMS lip-sync, calm idle bob.
- **Speech Bubble:**
  - KM: `ប្រវត្តិបញ្ជាទិញ • E-Receipt & KHQR Breakdown`
  - EN: `Structured Summary Viewer • Copy Plain TXT`
- **Narration (Khmer):**
  > នៅលើទំព័រ Orders អតិថិជនអាចត្រួតពិនិត្យរាល់ប្រវត្តិការបញ្ជាទិញពីមុនៗទាំងអស់ ដោយបែងចែកតាមប្រភេទ Active, Completed និង Cancelled យ៉ាងច្បាស់លាស់។ តាមរយៈប៊ូតុង View Bill អតិថិជនអាចបើកមើលវិក្កយបត្រអេឡិចត្រូនិកលម្អិត ដែលដំណើរការដោយបច្ចេកវិទ្យា Structured Summary Viewer។ វាអនុញ្ញាតឱ្យមើលវិក្កយបត្រជាទម្រង់ Formatted Card ដ៏ស្រស់ស្អាត ឬជា Plain TXT សម្រាប់ចម្លងទុក ព្រមទាំងបង្ហាញព័ត៌មានលម្អិតនៃប្រតិបត្តិការ KHQR យ៉ាងមានតម្លាភាព។

---

### Chapter 09: Real-Time Map & GPS Order Tracking
- **Duration:** 30.2s (`4:21 – 4:51`)
- **Visual Capture:** Live order tracking `/track/1` and `/map/1` screens displaying real-time delivery GPS map, driver polyline route geometry, and 5-step milestone progress indicator.
- **Avatar Pose & Position:** Bottom-right anchor, pointing gesture toward map polyline.
- **Speech Bubble:**
  - KM: `តាមដានអ្នកដឹកតាមផែនទី • Live GPS Tracking`
  - EN: `5-Step Milestone • Real-Time Driver Polyline`
- **Narration (Khmer):**
  > បន្ទាប់ពីការបញ្ជាទិញត្រូវបានបញ្ជាក់ អតិថិជនអាចតាមដានដំណើរការដឹកជញ្ជូនបានតាមរយៈផែនទី GPS ផ្ទាល់! ប្រព័ន្ធបង្ហាញផ្លូវធ្វើដំណើរ Polyline រវាងហាងអាហារ អ្នកដឹកជញ្ជូន និងទីតាំងផ្ទះរបស់អតិថិជន។ របារ 5-Step Milestone Stepper បង្ហាញដំណាក់កាលនីមួយៗយ៉ាងច្បាស់ ចាប់ពីការទទួលបញ្ជាទិញ ការចម្អិនក្នុងផ្ទះបាយ ការប្រគល់ឱ្យអ្នកដឹកជញ្ជូន រហូតដល់ការមកដល់គោលដៅ។ អតិថិជនក៏អាចចុចទាក់ទងអ្នកដឹកជញ្ជូនតាមទូរស័ព្ទ ឬផ្ញើសារបានយ៉ាងរហ័សទាន់ចិត្ត។

---

### Chapter 10: Driver Portal & Trip Management
- **Duration:** 30.4s (`4:51 – 5:22`)
- **Visual Capture:** Live `/driver-dashboard` screen, navigating across `Orders` (Accept/Decline cards), `Earnings` (daily/weekly income metrics), and `Profile` (vehicle details & driver ratings).
- **Avatar Pose & Position:** Bottom-right anchor, RMS lip-sync, hair sway.
- **Speech Bubble:**
  - KM: `ផ្ទាំងអ្នកដឹកជញ្ជូន • Driver Dashboard`
  - EN: `Accept Orders • Live Route Navigation • Earnings`
- **Narration (Khmer):**
  > ឥឡូវនេះ យើងងាកមកមើល Driver Portal សម្រាប់អ្នកបើកបរវិញម្តង។ នៅពេលមានការបញ្ជាទិញថ្មី អ្នកបើកបរទទួលបានសេចក្តីជូនដំណឹងភ្លាមៗ ហើយអាចចុច Accept ដើម្បីទទួលការដឹកជញ្ជូន ឬ Decline ប្រសិនបើមិនទាន់ទំនេរ។ ផ្ទាំងគ្រប់គ្រងបង្ហាញអាសយដ្ឋានហាង និងផ្ទះអតិថិជន ព្រមទាំងផ្តល់ប៊ូតុងរុករកតាមផែនទី។ លើសពីនេះ អ្នកបើកបរអាចតាមដានប្រាក់ចំណូលប្រចាំថ្ងៃ ប្រចាំសប្តាហ៍ ក្នុងផ្ទាំង Earnings និងត្រួតពិនិត្យព័ត៌មានយានយន្ត ស្លាកលេខ និងកម្រិត Rating របស់ខ្លួនបានយ៉ាងងាយស្រួល។

---

### Chapter 11: Restaurant Owner & Admin Telemetry Console
- **Duration:** 28.8s (`5:22 – 5:51`)
- **Visual Capture:** Live `/admin-dashboard` screen, reviewing Overview metrics, Health & Telemetry tab (database engine, connection pool, Redis/WebSockets), and Fleet management.
- **Avatar Pose & Position:** Bottom-right anchor, pointing tilt.
- **Speech Bubble:**
  - KM: `ផ្ទាំង Admin & ម្ចាស់ហាង • Telemetry Console`
  - EN: `System Health • DB Pipeline • Revenue Metrics`
- **Narration (Khmer):**
  > សម្រាប់ម្ចាស់ហាង និងអ្នកគ្រប់គ្រងប្រព័ន្ធ FoodGo ផ្តល់នូវ Admin Dashboard ដ៏មានឥទ្ធិពល! ផ្ទាំង Overview បង្ហាញទិន្នន័យចំណូលសរុប ចំនួនការបញ្ជាទិញ និងក្រាហ្វិកវិភាគទិន្នន័យជាក់ស្តែង។ ផ្ទាំង Health & Telemetry ត្រួតពិនិត្យដំណើរការ Server, PostgreSQL Database, Redis Cache និង WebSockets។ ចំណែកផ្ទាំង Fleet និង Pipeline ជួយគ្រប់គ្រងក្រុមអ្នកដឹកជញ្ជូន និងការត្រួតពិនិត្យលំហូរទំនិញទូទាំងប្រព័ន្ធ ធានាឱ្យអាជីវកម្មដំណើរការទៅមុខដោយរលូន គ្មានការរអាក់រអួល។

---

### Chapter 12: QA Verification, Test Suite & Outro
- **Duration:** 36.0s (`5:51 – 6:27`)
- **Visual Capture:** Full-screen QA verification scoreboard with glowing green badges:
  - Django Backend Tests: `221 / 221 PASSED (100%)`
  - Flutter Test Suite: `235 / 235 PASSED (100%)`
  - Dart Analyzer: `0 Issues Found`
  - Production Ready certification banner and outro credits.
- **Avatar Pose & Position:** Starts in corner, glides to center enlarged (`700px`), celebratory nod and wave, soft green glow.
- **Speech Bubble:**
  - KM: `គុណភាពស្តង់ដារខ្ពស់ • ២២១+២៣៥ Tests Pass`
  - EN: `Zero Analyzer Issues • Production Ready • អរគុណ!`
- **Narration (Khmer):**
  > ដើម្បីធានានូវគុណភាពកម្រិតខ្ពស់បំផុត FoodGo ត្រូវបានត្រួតពិនិត្យតាមរយៈការធ្វើតេស្តស្វ័យប្រវត្តិយ៉ាងម៉ត់ចត់ ដោយឆ្លងកាត់ការធ្វើតេស្ត Django Backend ចំនួន ២២១ tests ទទួលបាន PASS ១០០ ភាគរយ, ការធ្វើតេស្ត Flutter Widget និង Unit Tests ចំនួន ២៣៥ tests ទទួលបាន PASS ១០០ ភាគរយ ព្រមទាំងគ្មានបញ្ហា Analyzer ណាមួយកើតឡើងឡើយ! FoodGo គឺជាដំណោះស្រាយបញ្ជាទិញអាហារដ៏ពេញលេញ មានសុវត្ថិភាពខ្ពស់ និងរួចរាល់សម្រាប់ការដាក់ឱ្យប្រើប្រាស់ជាក់ស្តែង។ សូមអរគុណយ៉ាងជ្រាលជ្រៅសម្រាប់ការទស្សនាការបង្ហាញនេះ! សូមជម្រាបលា!
