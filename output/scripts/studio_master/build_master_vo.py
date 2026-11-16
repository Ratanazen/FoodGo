#!/usr/bin/env python3
"""Synthesize all 14 academic chapters (~8m 45s) in fluent Khmer via edge-tts
(km-KH-PisethNeural, +0%), measure exact spoken timing per cue, pad clean visual
breathing holds so total runtime hits ~520-540s (8-10 min), and export
plan_master.json."""

import asyncio
import json
import os
import subprocess
import edge_tts

BASE = os.path.dirname(os.path.abspath(__file__))
VO_DIR = os.path.join(BASE, "vo")
VOICE = "km-KH-PisethNeural"
RATE = "+0%"

# Each segment: (id, chapter_label, title_en, lines: [(tts_kh, cap_km, cap_en)])
# Note: tts_kh writes English acronyms phonetically in Khmer for flawless PisethNeural G2P pronunciation,
# while cap_km & cap_en keep exact developer/code identifiers cleanly visible in captions.
SEGMENTS = [
    (
        "seg01_intro",
        "01 · INTRODUCTION",
        "FoodGo Smart Delivery Platform",
        [
            ("សួស្តីគណៈកម្មការ និងសាស្ត្រាចារ្យ សាកលវិទ្យាល័យពាណិជ្ជសាស្រ្ត អេស៊ីលីដា ជាទីគោរព។",
             "សួស្តីគណៈកម្មការ និងសាស្ត្រាចារ្យ សាកលវិទ្យាល័យពាណិជ្ជសាស្រ្ត អេស៊ីលីដា។",
             "Greetings faculty & committee of ACLEDA University of Business."),
            ("ថ្ងៃនេះ ក្រុមនិស្សិតយើងខ្ញុំទាំង ៥ នាក់ សូមបង្ហាញពីគម្រោង ហ្វ៊ូដហ្គោ ដែលជាប្រព័ន្ធកុម្ម៉ង់ និងដឹកជញ្ជូនម្ហូបអាហារទំនើប។",
             "ក្រុមនិស្សិតទាំង ៥ នាក់ សូមបង្ហាញពីគម្រោង FoodGo ដឹកជញ្ជូនម្ហូបអាហារទំនើប។",
             "Our 5-member team presents FoodGo, a modern food delivery platform."),
            ("សមាជិកក្រុមរួមមាន អែម រតនា ហេន យ៉ាងគុយ ថាន់ សម្បត្តិបររ័ត្ន ជាង បូរិន និង លី គឹមឈុន។",
             "សមាជិក៖ ០១ អែម រតនា · ០២ ហេន យ៉ាងគុយ · ០៣ ថាន់ សម្បត្តិបររ័ត្ន · ០៤ ជាង បូរិន · ០៥ លី គឹមឈុន។",
             "Team: 01 Em Ratana, 02 Hen Yaungkuy, 03 Than Sombath Borarat, 04 Cheang borin, 05 Ly KimChhun."),
            ("គោលបំណងចម្បងរបស់ ហ្វ៊ូដហ្គោ គឺផ្ដល់ភាពងាយស្រួលទាំងអតិថិជន អ្នកដឹកជញ្ជូន ម្ចាស់ហាង និងអ្នកគ្រប់គ្រងនៅភ្នំពេញ។",
             "គោលបំណងចម្បង៖ ភ្ជាប់អតិថិជន អ្នកដឹកជញ្ជូន ម្ចាស់ហាង និងអ្នកគ្រប់គ្រងនៅភ្នំពេញ។",
             "Core purpose: Uniting Customers, Couriers, Restaurants & Admins in Phnom Penh."),
        ],
    ),
    (
        "seg02_problem",
        "02 · PROBLEM STATEMENT",
        "Local Delivery Challenges in Cambodia",
        [
            ("នៅក្នុងទីផ្សារបច្ចុប្បន្ន កម្មវិធីកុម្ម៉ង់ម្ហូបអាហារភាគច្រើននៅមានបញ្ហាប្រឈមសំខាន់ៗចំនួនបួន។",
             "ទីផ្សារកុម្ម៉ង់ម្ហូបបច្ចុប្បន្ន ជួបប្រទះបញ្ហាប្រឈមសំខាន់ៗចំនួន ៤។",
             "Existing delivery platforms face four key operational pain points."),
            ("ទីមួយ គឺឧបសគ្គភាសាខ្មែរ និងការគណនាប្ដូរប្រាក់ដុល្លារទៅប្រាក់រៀលដោយដៃ ដែលងាយបង្កកំហុស។",
             "១. ឧបសគ្គភាសាខ្មែរ និងកំហុសក្នុងការគណនាតម្លៃ USD / KHR ដោយដៃ។",
             "1. Limited Khmer UX and error-prone manual USD/KHR calculations."),
            ("ទីពីរ ការបង់ប្រាក់តាមរូបភាព ពិបាកផ្ទៀងផ្ទាត់ និងត្រូវរង់ចាំយូរ។",
             "២. ការផ្ទៀងផ្ទាត់បង់ប្រាក់ដោយរូបភាពបង្កាន់ដៃ មានហានិភ័យ និងយឺតយ៉ាវ។",
             "2. Manual screenshot slips create verification delays & fraud risks."),
            ("ទីបី ការតាមដានទីតាំងអ្នកដឹកជញ្ជូនពឹងផ្អែកលើការផ្ទុកទំព័រឡើងវិញ បណ្ដាលឱ្យយឺតទិន្នន័យ។",
             "៣. ការតាមដានទីតាំងដោយការ Refresh ទំព័រ ធ្វើឱ្យយឺត និងខាតបង់ធនធាន Server។",
             "3. HTTP polling lags real-time rider tracking & burdens servers."),
        ],
    ),
    (
        "seg03_objectives",
        "03 · PROJECT OBJECTIVES",
        "Goals & User Value Targets",
        [
            ("ដើម្បីដោះស្រាយបញ្ហាទាំងនេះ គម្រោង ហ្វ៊ូដហ្គោ បានកំណត់គោលដៅជាក់លាក់ចំនួនបួន។",
             "ដើម្បីដោះស្រាយបញ្ហានេះ FoodGo កំណត់គោលបំណងច្បាស់លាស់ ៤ ចំណុច។",
             "To solve these issues, FoodGo targets four clear engineering objectives."),
            ("ទីមួយ បង្កើតកម្មវិធី FoodGo ដែលគាំទ្រភាសាខ្មែរ និងអង់គ្លេសយ៉ាងច្បាស់ស្អាត។",
             "១. បង្កើតចំណុចប្រទាក់ ខ្មែរ / អង់គ្លេស ដែលប្ដូរបានភ្លាមៗក្នុង ១ ចុច។",
             "1. Build 1-tap seamless Khmer & English switching across mobile & web."),
            ("ទីពីរ បង្កើតប្រព័ន្ធប្ដូរប្រាក់ស្វ័យប្រវត្តិ ក្នុងអត្រា ៤១០០ រៀល ក្នុងមួយដុល្លារ គ្រប់កន្ត្រកទំនិញ និងបង្កាន់ដៃ។",
             "២. គណនា USD/KHR ស្វ័យប្រវត្តិ (1 USD = 4,100 ៛) លើគ្រប់ការកុម្ម៉ង់។",
             "2. Enforce exact automatic dual USD/KHR sync (4,100 KHR per USD)."),
            ("ទីបី ដាក់ឱ្យដំណើរការការទូទាត់ បាគង ខេអេចឃ្យូអរ ឌីណាមិក ជាមួយការផ្ទៀងផ្ទាត់ពេលវេលាពិត និងផែនទីភ្នំពេញផ្ទាល់។",
             "៣. ទូទាត់ Bakong KHQR ឌីណាមិក និងតាមដានផែនទី OSRM ពេលវេលាពិត។",
             "3. Deliver dynamic Bakong KHQR settlement & live Phnom Penh GPS tracking."),
        ],
    ),
    (
        "seg04_solution",
        "04 · PROPOSED SOLUTION",
        "Unified Multi-Portal Architecture",
        [
            ("ដំណោះស្រាយរបស់យើង គឺការបង្រួបបង្រួមប្រព័ន្ធទាំងមូលទៅក្នុងវេទិកា ហ្វ៊ូដហ្គោ តែមួយ។",
             "ដំណោះស្រាយ៖ បង្រួបបង្រួមតួនាទីទាំង ៤ នៅក្នុងប្រព័ន្ធ FoodGo តែមួយ។",
             "Our solution unifies all 4 operational roles in one FoodGo platform."),
            ("អ្នកប្រើប្រាស់អាចចូលប្រើតាមតួនាទី អតិថិជន អ្នកដឹកជញ្ជូន ម្ចាស់ហាង ឬអ្នកគ្រប់គ្រងដោយសុវត្ថិភាព។",
             "គាំទ្រការចូលប្រើប្រាស់ ៤ តួនាទី ដោយសុវត្ថិភាព JWT និង OTP ទូរស័ព្ទ។",
             "Customers, Couriers, Owners & Admins authenticate securely via JWT & OTP."),
            ("ប្រព័ន្ធបញ្ជូនទិន្នន័យការបង់ប្រាក់ និងទីតាំងដឹកជញ្ជូន តាមរយៈ WebSocket។",
             "រាល់ការបង់ប្រាក់ និងទីតាំងដឹកជញ្ជូន ត្រូវបានបញ្ជូនភ្លាមៗតាម WebSocket។",
             "Every payment, status update & courier coordinate pushes live via WebSocket."),
            ("វិធីនេះជួយកាត់បន្ថយកំហុស និងបង្កើនភាពជឿជាក់សម្រាប់អាជីវកម្មនៅកម្ពុជា។",
             "លុបបំបាត់កំហុសគណនាដោយដៃ និងលើកកម្ពស់ទំនុកចិត្តពាណិជ្ជកម្មឌីជីថល។",
             "This eliminates manual errors and boosts trust across local food commerce."),
        ],
    ),
    (
        "seg05a_features_ui",
        "05A · FEATURES — UX & PRICING",
        "Bilingual Discovery & Smart Vouchers",
        [
            ("ចូលដល់មុខងារសំខាន់ៗ ហ្វ៊ូដហ្គោ ផ្ដល់ជូនការរុករកមុខម្ហូបដ៏រហ័ស ជាមួយរូបភាពច្បាស់លាស់ និងប្រភេទអាហារសម្បូរបែប។",
             "មុខងារសំខាន់ៗ ៥A៖ ម៉ឺនុយរហ័ស ការស្វែងរក និងចំណាត់ថ្នាក់ម្ហូបអាហារ។",
             "Key Features 5A: Fast menu browsing, category filters & crisp dish previews."),
            ("អ្នកប្រើប្រាស់អាចប្ដូរភាសាខ្មែរ និងអង់គ្លេស រួមជាមួយពណ៌ GlassTheme ចំនួន ១៦ ម៉ូដ។",
             "ប្ដូរភាសា ខ្មែរ/អង់គ្លេស និងជ្រើសរើស Theme បង្ហាញបានដល់ទៅ ១៦ ប្រភេទ។",
             "Switch KH/EN languages anytime & customize from 16 GlassTheme palettes."),
            ("នៅក្នុងកន្ត្រកទំនិញ ប្រព័ន្ធគណនាប្រូម៉ូកូដ FOODGO30 និងថ្លៃដឹកជញ្ជូនស្វ័យប្រវត្តិ។",
             "អនុវត្តប្រូម៉ូកូដបញ្ចុះតម្លៃ (FOODGO30) និងគណនាប្រាក់រៀលភ្លាមៗ។",
             "Apply voucher codes like FOODGO30 with instant live USD & KHR totals."),
        ],
    ),
    (
        "seg05b_features_khqr",
        "05B · FEATURES — BAKONG KHQR",
        "EMVCo Standard & Live Payment Lock",
        [
            ("ចំពោះការទូទាត់ FoodGo បង្កើតលេខកូដ Bakong KHQR ឌីណាមិក តាមស្តង់ដារ EMVCo។",
             "មុខងារសំខាន់ៗ ៥B៖ បង្កើតកូដ Bakong KHQR ឌីណាមិកតាមស្តង់ដារ EMVCo CRC16។",
             "Key Features 5B: Dynamic EMVCo CRC16-CCITT Bakong KHQR generation."),
            ("អតិថិជនអាចស្កេនបង់ប្រាក់ពីធនាគារ Bakong, ABA, ACLEDA និង Wing។",
             "គាំទ្រ Bakong · ABA · ACLEDA · Wing ជាមួយនាឡិកាកំណត់ពេលជិត ៣០ នាទី។",
             "Compatible with Bakong, ABA, ACLEDA & Wing under a live countdown timer."),
            ("ពេលអតិថិជនស្កេនបង់ប្រាក់រួច ម៉ាស៊ីនមេនឹងរុញសញ្ញា វេបសកឃិត ហើយបង្កើតលេខសម្គាល់ការប្រគល់ម្ហូបដោយសុវត្ថិភាព។",
             "ផ្ទៀងផ្ទាត់ការបង់ប្រាក់តាម WebSocket និងបង្កើត Delivery Token សុវត្ថិភាព។",
             "Server pushes WebSocket receipt locks & generates Delivery Handover Tokens."),
        ],
    ),
    (
        "seg06_tech_stack",
        "06 · TECHNOLOGY STACK",
        "Production Frameworks & Tooling",
        [
            ("ខាងផ្នែកបច្ចេកវិទ្យា ហ្វ៊ូដហ្គោ ត្រូវបានអភិវឌ្ឍឡើងដោយផ្សំបច្ចេកវិទ្យាទំនើបលំដាប់ឧស្សាហកម្ម។",
             "ប្រព័ន្ធបច្ចេកវិទ្យា FoodGo ត្រូវបានអភិវឌ្ឍលើស្ថាបត្យកម្មទំនើប និងរឹងមាំ។",
             "FoodGo is engineered on an industry-grade full-stack foundation."),
            ("ផ្នែកខាងមុខប្រើប្រាស់ Dart និង Flutter បង្កើតបានអេក្រង់កម្មវិធីចំនួន ៣១។",
             "Frontend៖ Dart 3 & Flutter 3 ដែលមានទំព័រកម្មវិធីចំនួន ៣១ សម្រាប់ Mobile & Web។",
             "Frontend: Dart 3 & Flutter 3 powering 31 clean screens across Mobile & Web."),
            ("ផ្នែកខាងក្រោយប្រើ Python និង Django REST Framework រួមជាមួយ Daphne ASGI។",
             "Backend៖ Python, Django REST Framework, Daphne ASGI & Channels WebSockets។",
             "Backend: Python, Django REST Framework, Daphne ASGI & Channels."),
            ("ទិន្នន័យប្រើប្រាស់ PostgreSQL ជាមួយ Redis និងប្រព័ន្ធផែនទី OpenStreetMap OSRM។",
             "មូលដ្ឋានទិន្នន័យ៖ PostgreSQL & Redis រួមជាមួយ OpenStreetMap & OSRM។",
             "Storage & Routing: PostgreSQL, Redis pub/sub & OpenStreetMap + OSRM."),
        ],
    ),
    (
        "seg07_architecture",
        "07 · UI/UX & ARCHITECTURE",
        "4-Layer Architecture & Data Model",
        [
            ("សូមពិនិត្យមើលស្ថាបត្យកម្មប្រព័ន្ធ និងទំនាក់ទំនងទិន្នន័យទាំងបួនស្រទាប់របស់ ហ្វ៊ូដហ្គោ។",
             "ស្ថាបត្យកម្មប្រព័ន្ធ ៤ ស្រទាប់របស់ FoodGo ភ្ជាប់យ៉ាងរលូនពីអតិថិជនដល់ធនាគារ។",
             "Explore FoodGo's 4-tier architecture from Flutter clients to payment rails."),
            ("ស្រទាប់ទីមួយ គឺកម្មវិធី ហ្វ្លាត់ធើ ទាំងបួនតួនាទី ដែលភ្ជាប់មកកាន់ផ្លូវ អេភីអាយ ចំនួន ៥៩ របស់ ចាងហ្គោ។",
             "១. Flutter Portals ភ្ជាប់ទៅកាន់ផ្លូវ API ចំនួន ៥៩ នៅលើ Django Core។",
             "1. All 4 Flutter client portals communicate through 59 REST & WS routes."),
            ("នៅស្រទាប់ទិន្នន័យ មានម៉ូដែលចំនួន ២៦ សម្រាប់គ្រប់គ្រងការបញ្ជាទិញ និងការទូទាត់។",
             "២. ម៉ូដែលទិន្នន័យ ២៦ គ្រប់គ្រង Order, Payment, Delivery, Wallet & AuditLog។",
             "2. 26 ORM models govern Users, Orders, Payments, Deliveries & AuditLogs."),
            ("បណ្តាញ WebSocket និង Redis បញ្ជូនទីតាំងផ្ទាល់ជាមួយផែនទី OSRM នៅភ្នំពេញ។",
             "៣. Redis Channels បញ្ជូនទីតាំងផ្ទាល់ ខណៈ OSRM គណនាផ្លូវលឿនបំផុតក្នុងភ្នំពេញ។",
             "3. Redis pub/sub streams live sockets while OSRM computes Phnom Penh routes."),
        ],
    ),
    (
        "seg08a_demo_checkout",
        "08A · LIVE DEMO — CHECKOUT",
        "Real App Flow: Cart to Receipt",
        [
            ("ឥឡូវនេះ សូមទស្សនាការបង្ហាញផ្ទាល់លើកម្មវិធីពិតរបស់ ហ្វ៊ូដហ្គោ ជាជំហានៗ។",
             "ការបង្ហាញកម្មវិធីពិត (Live Demo 8A)៖ ពីការជ្រើសរើសម្ហូបដល់បង្កាន់ដៃ។",
             "Live Demo 8A: Real end-to-end Flutter checkout experience."),
            ("អតិថិជនបន្ថែមមុខម្ហូបចូលកន្ត្រក អនុវត្តលេខកូដបញ្ចុះតម្លៃ ហើយមើលតម្លៃសរុបជាប្រាក់ដុល្លារ និងរៀលភ្លាមៗ។",
             "អតិថិជនដាក់ម្ហូបក្នុងកន្ត្រក ប្រើប្រូម៉ូកូដ FOODGO30 និងពិនិត្យតម្លៃដុល្លារ/រៀល។",
             "Customer adds items, applies FOODGO30 voucher & confirms USD/KHR total."),
            ("ក្រោយបញ្ជាក់ការបញ្ជាទិញ ប្រព័ន្ធបង្កើតលេខកូដ KHQR ដោយស្វ័យប្រវត្តិ។",
             "ប្រព័ន្ធបង្កើតបង្កាន់ដៃ Order និងត្រៀម KHQR ភ្លាមៗសម្រាប់បង់ប្រាក់។",
             "Order ID & itemized dual-currency bill lock automatically for KHQR."),
        ],
    ),
    (
        "seg08b_demo_gps",
        "08B · LIVE DEMO — GPS TRACKING",
        "Real-Time Phnom Penh Rider Radar",
        [
            ("ក្នុងដំណាក់កាលដឹកជញ្ជូន អតិថិជនអាចមើលផ្លូវធ្វើដំណើរលើផែនទីភ្នំពេញជាក់ស្ដែង។",
             "Live Demo 8B៖ តាមដានអ្នកដឹកជញ្ជូនលើផែនទីទីក្រុងភ្នំពេញពេលវេលាពិត។",
             "Live Demo 8B: Live Phnom Penh GPS courier radar on OpenStreetMap."),
            ("ផែនទីបង្ហាញទីតាំងភោជនីយដ្ឋាន ទីតាំងផ្ទះអតិថិជន និងពេលវេលាប៉ាន់ស្មានរបស់អ្នកដឹកជញ្ជូនជារៀងរាល់វិនាទី។",
             "បង្ហាញចម្ងាយផ្លូវ ចលនាអ្នកដឹក Bob Rider និងម៉ោងមកដល់ ETA ផ្ទាល់។",
             "Map plots rider telemetry, route polyline & dynamic 3-min ETA countdown."),
            ("ជំហានស្ថានភាពទាំងបួន ធ្វើបច្ចុប្បន្នភាពដោយស្វ័យប្រវត្តិ ដោយមិនចាំបាច់ចុចផ្ទុកទំព័រឡើងវិញឡើយ។",
             "ស្ថានភាពទាំង ៤ ដំណាក់កាលប្ដូរដោយស្វ័យប្រវត្តិ ដោយមិនចាំបាច់ Refresh ទំព័រ។",
             "Status steps advance live without refreshing the app."),
        ],
    ),
    (
        "seg08c_demo_driver",
        "08C · LIVE DEMO — DRIVER PORTAL",
        "Courier Shift & Verified Handover",
        [
            ("ប្ដូរមកមើលតួនាទីអ្នកដឹកជញ្ជូន អ្នកបើកបរអាចបើកប៊ូតុងអនឡាញដើម្បីទទួលការងារដឹកជញ្ជូនជិតខ្លួនបំផុត។",
             "Live Demo 8C៖ ផ្នែកអ្នកដឹកជញ្ជូន (Driver Portal) និងការផ្ញើទីតាំង GPS។",
             "Live Demo 8C: Courier Portal online toggle, job claim & GPS broadcast."),
            ("នៅពេលទទួលការកុម្ម៉ង់ ប្រព័ន្ធការពារកុំឱ្យអ្នកដឹកជញ្ជូនពីរនាក់ទទួលការងារជាន់គ្នា។",
             "ការទទួលការងារត្រូវបានការពារដោយ Atomic Lock មិនឱ្យទទួលការងារជាន់គ្នា។",
             "Order claims are protected atomically so two drivers never collide."),
            ("ពេលដល់គោលដៅ អ្នកដឹកជញ្ជូនបញ្ចប់ការប្រគល់អាហារតាមរយៈកូដ PIN ៦ ខ្ទង់។",
             "បញ្ចប់ការដឹកជញ្ជូនយ៉ាងត្រឹមត្រូវ ដោយបញ្ជាក់កូដ PIN ៦ ខ្ទង់ ឬ Delivery QR។",
             "Courier completes handover securely via 6-digit PIN or Delivery QR."),
        ],
    ),
    (
        "seg08d_demo_admin",
        "08D · LIVE DEMO — OWNER & ADMIN",
        "Live Merchant & Admin Console",
        [
            ("ចំណែកក្នុងផ្ទាំងម្ចាស់ភោជនីយដ្ឋាន និងផ្ទាំង Admin Console អ្នកគ្រប់គ្រងអាចត្រួតពិនិត្យដំណើរការប្រព័ន្ធទាំងមូលបានភ្លាមៗ។",
             "Live Demo 8D៖ ផ្ទាំងគ្រប់គ្រងម្ចាស់ហាង និង Admin Command Center។",
             "Live Demo 8D: Restaurant Owner workflow & Admin Console telemetry."),
            ("ប្រព័ន្ធបង្ហាញទិន្នន័យជាក់ស្ដែង រួមមានចំណូល ៤៨៧ ដុល្លារ និងការកុម្ម៉ង់ ៤៩ ដង។",
             "បង្ហាញចំណូល 487.49 ដុល្លារ · 49 ការកុម្ម៉ង់ · អ្នកដឹក 6 · អតិថិជន 13 នាក់។",
             "Live KPIs track Revenue ($487.49), Orders (49), Drivers (6) & Customers."),
            ("អ្នកគ្រប់គ្រងក៏អាចត្រួតពិនិត្យបញ្ជីការទូទាត់ ការសងប្រាក់វិញ និងកំណត់ត្រាសកម្មភាពទាំងអស់បានផងដែរ។",
             "គ្រប់គ្រងតារាងប្រតិបត្តិការ Bakong/ABA/ACLEDA និង Audit Log ពេញលេញ។",
             "Inspect every KHQR settlement ledger, refund & AuditLog entry cleanly."),
        ],
    ),
    (
        "seg09_results",
        "09 · RESULTS & CHALLENGES",
        "Verified Testing & Engineering Fixes",
        [
            ("ចំពោះលទ្ធផលសម្រេចបាន ប្រព័ន្ធ ហ្វ៊ូដហ្គោ ត្រូវបានផ្ទៀងផ្ទាត់ដោយតេស្តស្វ័យប្រវត្តិយ៉ាងតឹងរ៉ឹង។",
             "លទ្ធផលសម្រេចបាន៖ ការធ្វើតេស្តស្វ័យប្រវត្តិសរុប ៤៧៤ ករណី ជោគជ័យពេញលេញ។",
             "Verification Results: 474 automated software checks validated across stack."),
            ("រួមមានតេស្ត Django ចំនួន ២២៥ និងតេស្ត Flutter ចំនួន ២៤៩ គ្របដណ្ដប់លើសុវត្ថិភាព។",
             "រួមមាន 225 Backend Django Tests & 249 Flutter Unit/Widget Tests (26 Models · 59 APIs)។",
             "Includes 225 Django core test functions & 249 Flutter unit/widget tests."),
            ("បញ្ហាប្រឈមធំៗដែលយើងដោះស្រាយបាន រួមមានការចាក់សោទិន្នន័យពេលទទួលការងារ និងការបញ្ជូន វេបសកឃិត។",
             "ដោះស្រាយបញ្ហា Race Condition តាម select_for_update() & WebSocket Group Push។",
             "Key fixes: select_for_update() locking & clean alpha backdrop compositing."),
        ],
    ),
    (
        "seg10_conclusion",
        "10 · CONCLUSION & Q&A",
        "ACLEDA University Capstone Finale",
        [
            ("សរុបមក FoodGo បានសម្រេចប្រព័ន្ធដឹកជញ្ជូនម្ហូបអាហារដ៏ទំនើបសម្រាប់ប្រទេសកម្ពុជា។",
             "សេចក្ដីសន្និដ្ឋាន៖ FoodGo សម្រេចបានប្រព័ន្ធដឹកជញ្ជូនម្ហូបពេញលេញសម្រាប់កម្ពុជា។",
             "Conclusion: FoodGo delivers a complete bilingual KHQR & OSRM ecosystem."),
            ("ជំហានបន្ទាប់ ក្រុមការងារគ្រោងភ្ជាប់ប្រព័ន្ធ Bakong ពិតប្រាកដ និងការជូនដំណឹងថ្មីៗ។",
             "ទិសដៅអនាគត៖ Production Bakong Webhook, Push Alerts & Multi-Branch Dispatch។",
             "Roadmap: Production Bakong webhooks, Push Notifications & Cloud Scale."),
            ("ក្រុមនិស្សិតសាកលវិទ្យាល័យពាណិជ្ជសាស្រ្ត អេស៊ីលីដា សូមថ្លែងអំណរគុណ និងស្វាគមន៍រាល់សំណួររបស់គណៈកម្មការ។ សូមអរគុណ។",
             "សូមអរគុណ! ក្រុមនិស្សិត ACLEDA University សូមស្វាគមន៍សំណួរ និងមតិកែលម្អ (Q&A)។",
             "Thank you! The ACLEDA University Capstone Team welcomes your Q&A."),
        ],
    ),
]


def dur_sec(path: str) -> float:
    res = subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", path],
        capture_output=True, text=True, check=True,
    )
    return float(res.stdout.strip())


async def synth_line(spoken: str, mp3_path: str):
    for attempt in range(4):
        try:
            comm = edge_tts.Communicate(spoken, voice=VOICE, rate=RATE)
            with open(mp3_path, "wb") as f:
                async for chunk in comm.stream():
                    if chunk["type"] == "audio":
                        f.write(chunk["data"])
            if os.path.getsize(mp3_path) > 400:
                return
        except Exception as e:
            if attempt == 3:
                raise RuntimeError(f"TTS failed for: {spoken!r} ({e})")
            print(f"retrying TTS ({e})...", flush=True)
        await asyncio.sleep(0.8 * (attempt + 1))


async def build():
    os.makedirs(VO_DIR, exist_ok=True)
    master_subs = []
    segments_meta = []
    global_t = 0.0
    sr = 48000

    for seg_idx, (seg_id, ch_label, title_en, lines) in enumerate(SEGMENTS, 1):
        seg_dir = os.path.join(VO_DIR, seg_id)
        os.makedirs(seg_dir, exist_ok=True)
        line_timings = []
        seg_t = 2.00

        for l_idx, (spoken, cap_km, cap_en) in enumerate(lines, 1):
            mp3_p = os.path.join(seg_dir, f"l{l_idx}.mp3")
            wav_p = os.path.join(seg_dir, f"l{l_idx}.wav")
            # Force re-synth when text changed vs cached hash could matter; check hash marker
            h_file = os.path.join(seg_dir, f"l{l_idx}.txt")
            old_t = open(h_file, encoding="utf-8").read() if os.path.exists(h_file) else ""
            if old_t != spoken or not (os.path.exists(wav_p) and os.path.getsize(wav_p) > 8000):
                await synth_line(spoken, mp3_p)
                subprocess.run(
                    [
                        "ffmpeg", "-v", "error", "-y", "-i", mp3_p,
                        "-af", "silenceremove=start_periods=1:start_threshold=-48dB:start_silence=0.04,areverse,silenceremove=start_periods=1:start_threshold=-48dB:start_silence=0.06,areverse",
                        "-ar", str(sr), "-ac", "1", "-c:a", "pcm_s16le", wav_p,
                    ],
                    check=True,
                )
                with open(h_file, "w", encoding="utf-8") as hf:
                    hf.write(spoken)
                await asyncio.sleep(0.35)

            d = dur_sec(wav_p)
            gap_after = 4.55 if l_idx < len(lines) else 5.25
            line_timings.append({
                "idx": l_idx,
                "local_start": round(seg_t, 3),
                "local_end": round(seg_t + d, 3),
                "global_start": round(global_t + seg_t, 3),
                "global_end": round(global_t + seg_t + d + 0.18, 3),
                "cap_km": cap_km,
                "cap_en": cap_en,
                "wav": wav_p,
                "dur": round(d, 3),
            })
            master_subs.append({
                "start": round(global_t + seg_t, 3),
                "end": round(global_t + seg_t + d + 0.18, 3),
                "km": cap_km,
                "en": cap_en,
            })
            seg_t += d + gap_after

        n_frames = int(round(seg_t * 30))
        seg_dur = round(n_frames / 30.0, 4)

        segments_meta.append({
            "idx": seg_idx,
            "id": seg_id,
            "ch_label": ch_label,
            "title_en": title_en,
            "start": round(global_t, 4),
            "dur": seg_dur,
            "frames": n_frames,
            "lines": line_timings,
        })
        global_t += seg_dur
        print(f"  [{seg_idx:02d}/14] {seg_id:22s} dur={seg_dur:6.2f}s  cum={global_t:6.2f}s", flush=True)

    plan = {
        "voice": VOICE,
        "rate": RATE,
        "total_dur": round(global_t, 3),
        "total_frames": sum(s["frames"] for s in segments_meta),
        "segments": segments_meta,
        "subs": master_subs,
    }
    with open(os.path.join(BASE, "plan_master.json"), "w", encoding="utf-8") as f:
        json.dump(plan, f, ensure_ascii=False, indent=2)
    print(f"TOTAL MASTER DURATION: {global_t:.2f}s ({global_t/60:.2f} min), {len(master_subs)} subtitle cues")


if __name__ == "__main__":
    asyncio.run(build())
