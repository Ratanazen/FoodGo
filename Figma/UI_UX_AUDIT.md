# FoodGo v2.0 — UI/UX & Technical Architecture Audit

**Date**: November 2026  
**Auditor**: Senior Product Designer & Full-Stack Architect  
**Platform**: Flutter 3.13 (Mobile & Web) + Django 6.1 REST Framework  
**Scope**: Customer Mobile App, Driver Delivery Experience, Restaurant/Admin Dashboard, API Contracts, and Cambodian Localization  

---

## 1. Executive Summary

FoodGo is a food delivery application targeting the Cambodian market. While the current codebase implements core consumer workflows (authentication, restaurant browsing, cart, KHQR payment, checkout, and OpenStreetMap order tracking) with a modern glassmorphism aesthetic, significant architectural and experiential gaps remain for a production-grade v2.0 release.

This audit evaluates the current state across Information Architecture, Visual Design, Typography & Cambodian Localization, Component Geometry, Driver & Admin Capabilities, and Test Coverage.

---

## 2. Git & Repository Status

- **Branch**: `master` (ahead of origin/master by 2 commits, working tree clean).
- **Core Stacks**:
  - **Frontend**: Flutter SDK `^3.13.0`, Material 3, `go_router ^14.2.0`, `provider ^6.1.5+1`, `flutter_map ^8.3.1`, `flutter_animate ^4.5.2`, `cached_network_image ^3.4.1`.
  - **Backend**: Django 6.1, Django REST Framework, SimpleJWT, SQLite3 database, seed command (`core/management/commands/seed_data.py`).
- **Tests**:
  - `foodgo_flutter/test`: Empty.
  - `backend/core/tests.py`: Empty.

---

## 3. Comprehensive Screen & Feature Audit

| Screen / Module | Current Implementation Status | Identified UX & Architectural Gaps in v1.0 | Proposed v2.0 Redesign & Enhancements |
|---|---|---|---|
| **Splash Screen** | Responsive with guaranteed fallback timer (2600ms) & progress indicator. | Static background without animated brand identity or sound/haptics. | Micro-animated FoodGo logo, smooth ripple effect, instant session handshake. |
| **Onboarding Flow** | 3-step carousel with skip/next actions. | Generic placeholder imagery, no Khmer localization, no permission priming. | Rich vector illustrations of Phnom Penh delivery, dual-language picker (KH/EN), location permission primer. |
| **Authentication** | Email + Password, Register, Forgot Password. | Missing Phone OTP authentication (standard in Cambodia: Smart/Cellcard/Metfone), no biometric login. | Phone number + OTP SMS tab, Google/Apple SSO buttons, biometric (FaceID/Fingerprint) toggle. |
| **Home Screen** | Greeting, search bar, category chips, popular food cards, featured restaurants. | Hardcoded categories (Burger/Pizza), lack of authentic Khmer street food categories, generic promotions banner. | Dynamic hero carousel (daily promotions, flash deals), Khmer culinary taxonomy (*Amok, Kuy Teav, Bai Sach Chrouk*), delivery time filters. |
| **Search & Filter** | Keyword filter with chips. | Filter sheet is static, no distance/price slider, no dietary tags (Halal, Vegetarian, Vegan). | Multi-attribute bottom sheet (distance, rating, price brackets, opening status, dietary badges), trending queries. |
| **Restaurant Details** | Banner, meta tags (rating, delivery fee), category tabs, food cards. | No search within menu, no restaurant story/licensing, food customization modal is basic without modifiers (spiciness, toppings). | Sticky menu navigation bar, interactive customization modal with required/optional modifier groups, dietary badges. |
| **Food Customization Modal** | Bottom sheet with quantity counter and basic add-to-cart. | Cannot select size, spicy level, ice level, or paid add-ons. | Multi-tier modifier architecture: single-select (Size), multi-select (Add extra meat/cheese), special requests input. |
| **Cart Screen** | Quantity stepper, item removal, price summary, checkout button. | No restaurant minimum order check, no tip selector for drivers, no promo code validator. | Minimum order threshold meter, dynamic coupon input with instant discount calculation, custom driver tip ($0.50, $1.00, $2.00, Custom). |
| **Checkout & KHQR Pay** | Address card, payment selection, KHQR Modal with USD/KHR switch & custom QR matrix. | No scheduled delivery slot, no alternate delivery phone number. | Delivery timing options (ASAP vs. Scheduled Slot), contact phone verification, enhanced KHQR Deep-Linking to ABA Mobile / Bakong app. |
| **Order Tracking / Map** | Flutter Map (OpenStreetMap), driver pin, destination pin, status sheet. | Static driver position, no real-time ETA calculation, no in-app call/chat with driver. | Animated driver trajectory interpolation, live call driver button, floating ETA pill, push notification trigger simulation. |
| **Orders History** | List of past orders with status chips and reorder. | Missing live active orders banner, no download receipt/invoice option. | Dual tabs ("Active Orders" & "Past Orders"), order timeline stepper, digital invoice download. |
| **Driver Delivery Flow** | **Completely Missing in UI** (`Driver` and `Delivery` models exist in Django backend only). | Drivers have no interface to accept trips, navigate, or mark delivery complete. | Dedicated Driver Portal / Screen: Duty Status (Online/Offline), Incoming Order Modal with timer, Pickup & Dropoff directions, Delivery Proof. |
| **Restaurant / Admin Portal**| **Missing in UI** (Only Django `/admin/` exists). | Restaurant managers cannot toggle menu item availability or manage live orders on tablet/web. | Responsive Web / Tablet Admin Dashboard: Live Orders Kanban (Pending, Preparing, Ready, Dispatched), Menu Item Switcher, Sales Summary. |

---

## 4. Visual Design, Typography & Cambodian Localization

1. **Khmer Language & Typography**:
   - Current typography uses generic system fonts with zero support for Khmer script kerning and baseline harmony.
   - **v2.0 Requirement**: Support `Kantumruy Pro` / `Siemreap` / `Battambang` font families with seamless bilingual switching (English / ភាសាខ្មែរ).
2. **Color Palette & Visual Geometry**:
   - Primary: Emerald Green (`#10B981` / `#059669`) symbolizing freshness and clean delivery.
   - Accent: Angkor Gold (`#F59E0B`) and KHQR Crimson (`#E1232E`) for authentic local payment identification.
   - Surface Geometry: Refined glassmorphism with subtle 1px border highlights, consistent 16px/24px/32px radius hierarchy, and tactile haptic feedback.
3. **Imagery & Original Assets**:
   - Transition from generic pizza/burger photos to curated Cambodian gastronomic delicacies (*Fish Amok, Beef Lok Lak, Phnom Penh Kuy Teav, Nom Banh Chok, Fresh Sugar Cane Juice*).

---

## 5. Security & Technical Debt

- **Keyring Timeouts**: Successfully resolved Linux keyring / platform channel delays by implementing 800ms timeouts with shared_preferences fallback.
- **Data Pre-population**: Offline caching in `RestaurantProvider` ensures the app never displays blank screens even during network dropouts.
- **Unit & Integration Tests**: Zero test files exist. A comprehensive suite of unit tests for providers and golden widget tests for glass cards must be established.
