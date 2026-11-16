# FoodGo v2.0 — Comprehensive UI/UX & Visual Experience Audit

## Executive Summary
This document provides an exhaustive, screen-by-screen and component-level audit of the FoodGo user interface and visual design system across Customer, Driver, and Admin workflows. It outlines concrete deficiencies, typography gaps, asset shortcomings, and accessibility bottlenecks, setting the foundation for the **FoodGo v2.0 Full App Redesign**.

---

## 1. Core Visual Design & Asset Deficiencies

### 1.1 Remote Network Asset Dependency (Lottie Fallbacks)
- **Problem:** `LottieAsset` (`foodgo_flutter/lib/widgets/lottie_assets.dart`) relies entirely on remote CDN endpoints (`https://assets10.lottiefiles.com/...`) for critical UX states:
  - Empty cart (`emptyBox`)
  - Order cooking / preparation (`cooking`)
  - Order success checkmark (`success`)
  - Delivery motorcycle (`deliveryBike`)
- **Impact:** On slow Cambodian mobile data (Smart/Cellcard) or offline states, remote JSON network requests fail or lag, forcing the app to drop to generic Material icons (`Icons.moped`, `Icons.animation`).
- **Remediation:** Replace remote dependencies with embedded, high-performance Flutter vector `CustomPainter` artwork and local SVG vector assets that render at 60/120fps offline.

### 1.2 Information Architecture & Hierarchy in Food Discovery
- **Problem:** `HomeScreen` has a crowded header where address dropdown, notification icon, profile avatar, search bar, filter button, and promotional banners compete for immediate user attention.
- **Problem:** Food cards display macronutrients (`calories`, `proteins`, `fats`, `carbo`) in dense typography, cluttering the discovery view for typical hunger-driven browsing.
- **Remediation:** 
  - Restructure `HomeScreen` into clear visual sections: Geo-Location Delivery Header, Search & Dynamic Filter Bar, Curated Promo Carousel, Category Pills with Khmer glyph padding, Featured Local Kitchens, and High-Impact Food Item Grid.
  - Standardize dish cards into two clean variants:
    1. **Featured Showcase Card:** Hero photography, ratings badge, preparation time, and one-tap "+ Add" CTA with quantity stepper.
    2. **Compact Menu List Card:** Horizontal thumb layout with dietary badges (Organic, Halal, Vegan), dual USD/KHR pricing, and haptic add-to-cart.

### 1.3 Component Geometry & Spacing Discrepancies
- **Corner Radii:** Different screens mix inconsistent border radii (`BorderRadius.circular(12)`, `16`, `20`, `24`, and `30`).
- **Elevation & Shadows:** Mixed usage of hard black shadows (`Colors.black26`) and colored ambient glow (`GlassTheme.dynamicPrimaryColor.withValues(alpha: 0.2)`).
- **Remediation:** Enforce the 8-point spatial grid system (`4px`, `8px`, `12px`, `16px`, `24px`, `32px`, `48px`) and uniform geometry tokens in `DESIGN_SYSTEM.md`.

---

## 2. Screen-by-Screen Audit

### 2.1 Customer Experience Screens

| Screen | Current Implementation | Critical Deficiencies | v2.0 Redesign Objective |
| :--- | :--- | :--- | :--- |
| **1. Splash Screen** | 3-phase staggered brand animation | Relies on hardcoded text strings; lacks app initialization status indicator | Full-screen organic brand scene with dynamic progress bar and version metadata |
| **2. Onboarding** | 3-slide PageView with generic material icons | Uses icons instead of rich illustrations; no slide preview thumbnails | Custom vector illustrations for food discovery, live courier GPS, and KHQR payments |
| **3. Login & Register** | 3D glass cards with vector auth painters | Password visibility toggles, keyboard focus overflow on small screens | Compact form layouts with autofocus, inline validation, and role selector chips |
| **4. Phone & OTP Auth** | 6-box glass PIN input modal | Legacy views allowed mock OTP; lack resend countdown timer visual | Authoritative SMS OTP screen with 60s countdown ring, carrier badge, and +855 format |
| **5. Home Discovery** | Scrollable feed with 31 theme skins | Overloaded header, macronutrient text clutter on cards | Clean visual hierarchy, prominent Cambodian food photography, sticky search bar |
| **6. Search & Filters** | List view with text search query | Lacks recent searches, trending food tags, and price range slider | Modern search screen with chips (Breakfast, Khmer Noodle, Bobor, Burgers) and instant results |
| **7. Restaurant Categories** | Horizontal pill category list | Fixed categories without dynamic kitchen count | Rich icon badges with Khmer subtitles and category kitchen counts |
| **8. Restaurant Details** | SliverAppBar with cover image & menu | Collapsing toolbar clips title on small screens; lacks dietary filter | Hero cover banner with delivery fee calculator, minimum order meter, and tabbed menu categories |
| **9. Food Details Screen** | Modal bottom sheet / standalone screen | Nutrition facts cramped; spice level selection not prominent | Full sheet with high-res food hero image, spice meter, custom add-ons, and floating action bar |
| **10. Cart Screen** | Dismissible list items with promo code | Empty state uses remote Lottie; checkout bar overlaps bottom navigation | Sticky glass checkout drawer with real-time bill breakdown, coupon chip, and vector empty state |
| **11. Checkout Screen** | Multi-step address, delivery notes & payment | Inconsistent payment selector; lack delivery instructions preset | Clear 3-step checkout: Delivery Address, Drop-off Instructions, and Authoritative Payment Selection |
| **12. KHQR Payment** | Dynamic EMVCo QR with live countdown | Timer expiration leaves user on dead screen without refresh CTA | Authoritative KHQR screen with countdown ring, Deep Link to Bakong app, and auto-polling |
| **13. Order Confirmation** | Simple success dialog / screen | Lacks order receipt summary and quick route to live map | Festive order success modal with delivery estimate, receipt breakdown, and "Track Order" button |
| **14. Live Order Tracking** | Leaflet / flutter_map with courier pin | Static polyline without live waypoint milestones | Interactive delivery map with courier bike animation, ETA badge, and customer-driver call button |
| **15. Order History** | Tabbed Active / History order cards | Reorder button missing; status badges have inconsistent colors | Detailed order history with instant "Reorder" action, invoice download, and item review rating |
| **16. Customer Profile** | Glass profile card with quick settings | Hardcoded version labels; mixed styling across settings items | Modern user hub with avatar upload, saved addresses, payment methods, and theme center entry |
| **17. Notifications** | Basic list tile notifications | Lacks clear notification categories (Orders vs Promotions) | Grouped notifications (Order Updates, Promo Vouchers, System Alerts) with unread indicators |
| **18. Theme Center** | 31 cultural and modern skins | Good motion toggles; lacks high-contrast mode indicator | Visual preview cards with live skin mockup, reduced-motion compliance badge, and color tokens |
| **19. Empty / Error States** | Plain text and generic icon | Remote Lottie URLs fail offline; error views lack diagnostic codes | Dedicated vector empty state illustrations for Cart, Orders, Favorites, and Network Offline |

---

### 2.2 Driver Experience Screens

| Screen | Current Implementation | Critical Deficiencies | v2.0 Redesign Objective |
| :--- | :--- | :--- | :--- |
| **1. Driver Login & OTP** | Shared auth modal with role parameter | Driver profile approval status not displayed prominently | Dedicated driver entrance with KYC approval status check |
| **2. Availability Toggle** | Switch in driver dashboard header | Bilingual Frankenstein text (`Online & Available`) | Streamlined online/offline master pill with GPS status indicator |
| **3. Assigned Orders** | Card list in active tab | Route distance and estimated courier payout unclear | Priority order banner with pickup ETA, restaurant contact, and customer notes |
| **4. Order Acceptance** | Modal with Accept / Decline buttons | Missing countdown timer for order acceptance | 30-second acceptance radar with earnings preview, distance, and item summary |
| **5. Restaurant Pickup** | Pickup checklist in order card | Missing one-tap navigation to restaurant in Google Maps/Waze | Step-by-step pickup guide with order verification code and navigation launcher |
| **6. Customer Delivery** | Delivery address text display | Customer delivery notes and phone call button buried | Prominent customer pin card with one-tap phone call, gate code, and drop-off notes |
| **7. Navigation & Route** | Map screen with coordinates | Lacks turn-by-turn guidance integration | In-app map with route polyline and direct launcher for external navigation |
| **8. Cash / QR Confirmation** | `DriverViewSet.verify_payment` modal | Driver previously had backdoor to confirm bank QR payments | Strict separation: Driver can ONLY confirm physical cash on COD; bank QR is gateway-verified |
| **9. Proof of Delivery** | Optional delivery QR scanner modal | Camera scanner fails on low-light or damaged QR codes | Dual proof: Delivery QR scan or 6-digit customer confirmation PIN entry |
| **10. Driver Order History** | Simple past orders list | Lacks daily/weekly earnings chart and tips breakdown | Earnings summary card with completed trips, tips, distance traveled, and trip details |
| **11. Driver Profile** | Profile tab in driver dashboard | PII exposure previously unredacted in API serializer | Secure courier profile with vehicle details, driver license status, and shift analytics |
| **12. Location & Offline Errors** | Standard snackbars | Location permission denial drops driver without guidance | In-screen location recovery banner with direct system settings launcher |

---

### 2.3 Admin Dashboard Screens

| Section | Current Implementation | Critical Deficiencies | v2.0 Redesign Objective |
| :--- | :--- | :--- | :--- |
| **1. Admin Auth & Access** | JWT login with `is_staff` check | Role expiration not handled; session renewal silent fail | Secure admin portal with auto-logout, session timer, and role badge |
| **2. Overview & Analytics** | Metric cards with revenue & order count | Static numbers without timeframe filters (Today, 7D, 30D) | Responsive KPI cards with trend indicators, hourly order chart, and revenue dual USD/KHR |
| **3. Customer Management** | Basic user list with search | Lacks customer order count, wallet balance, and ban toggle | Searchable customer table with status chips, wallet inspection, and account toggle dialog |
| **4. Driver Management** | Driver cards with approve/reject buttons | Approvals previously mislogged in audit logs | Verification queue with driver license photo preview, vehicle type, and audit logging |
| **5. Restaurant Management** | Restaurant cards with active toggle | Lacks commission rate settings and opening hours editor | Kitchen management table with operating status, rating, category tags, and commission rate |
| **6. Menu & Category** | Item list with price and description | Lacks stock availability toggle and allergen badges | Visual menu catalog with photo thumbnails, instant stock toggle, and price editor |
| **7. Orders Management** | Filterable order table with status pills | Order refund and cancellation lack confirmation dialogs | Real-time dispatch board with live order status chips (Pending, Cooking, In Transit, Delivered) |
| **8. Payment Audit Records** | Transaction table with gateway refs | Lacks filtering by gateway provider (Bakong, ABA, COD) | Reconciliation ledger with transaction reference, HMAC status, provider logo, and export CTA |
| **9. Promo & Vouchers** | Promo code list in cart provider | No admin UI to create new vouchers or set expiry dates | Voucher manager with discount percentage/flat rate, minimum spend, and quota meter |
| **10. System Health & Logs** | Audit log tab in admin dashboard | Lacks dual-backend and MongoDB synchronization status | Operational status panel showing Render Daphne, Vercel API, PostgreSQL, and Mongo ping |

---

## 3. Accessibility & Responsive Viewport Matrix

| Viewport Category | Width Range | Target Devices | Identified Vulnerabilities | Resolution Strategy |
| :--- | :--- | :--- | :--- | :--- |
| **Compact Mobile** | 320px – 375px | iPhone SE, Galaxy A03 | Button labels truncate; text scaler > 1.2 causes `RenderFlex` overflow | Clamp text scaler `0.85`–`1.40`; use auto-wrapping chips and flexible bottom bars |
| **Standard Mobile** | 375px – 430px | iPhone 14/15, Galaxy S22/S23 | Standard baseline; optimal single-column layout | 16px lateral padding; full-bleed card layouts with rounded glass containers |
| **Tablet Viewport** | 600px – 900px | iPad 10th Gen, Galaxy Tab A | Wide single column causes excessive whitespace and stretched food cards | Adaptive 2-column or 3-column grid layout using `ResponsiveLayout` |
| **Desktop / Web** | 1024px – 1920px | Chrome, Safari, Edge Desktop | Unconstrained full width makes text unreadable across 1440px+ | Max content constraint (`max-width: 1200px`) centered with sticky sidebar navigation |
