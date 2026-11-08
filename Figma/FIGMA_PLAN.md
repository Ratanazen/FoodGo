# FoodGo v2.0 — Figma Design & Component Architecture Plan

**Document ID**: `FG-V2-FIGMA-PLAN`  
**Target Design Platform**: Figma (Auto Layout 5.0, Component Sets, Variables & Token Studio)  
**Design System Name**: *FoodGo Emerald Glass Design System (EGDS)*  
**Primary Locales**: English (`en-US`) and Khmer (`km-KH`)  

---

## 1. Design Tokens & Foundations

### 1.1 Color Tokens (Semantic & Theming)

| Token Name | Light Value | Dark Value | Purpose |
|---|---|---|---|
| `color.brand.primary` | `#10B981` (Emerald 500) | `#059669` (Emerald 600) | Primary CTAs, active indicators, brand markers |
| `color.brand.secondary` | `#F59E0B` (Amber 500) | `#D97706` (Amber 600) | Badges, ratings, promotional highlights |
| `color.payment.khqr` | `#E1232E` (Bakong Crimson)| `#E1232E` | KHQR standard badge & scan frame |
| `color.surface.canvas` | `#F8FAFC` (Slate 50) | `#0B1310` (Deep Forest) | Application background |
| `color.surface.glass` | `rgba(255, 255, 255, 0.78)` | `rgba(22, 34, 27, 0.78)` | Glass cards, modals, app bar |
| `color.surface.glass.border` | `rgba(255, 255, 255, 0.65)` | `rgba(255, 255, 255, 0.12)` | Subtle glass highlight borders (1.2px) |
| `color.text.primary` | `#0F172A` (Slate 900) | `#F1F5F9` (Slate 100) | Main headings, food titles, prices |
| `color.text.secondary` | `#64748B` (Slate 500) | `#94A3B8` (Slate 400) | Subtitles, ingredients, delivery estimates |
| `color.status.success` | `#16A34A` | `#22C55E` | Order delivered, payment confirmed |
| `color.status.warning` | `#EA580C` | `#F97316` | Order preparing, driver arriving |
| `color.status.danger` | `#DC2626` | `#EF4444` | Order cancelled, out of stock |

### 1.2 Spacing & Elevation Grid (8pt System)
- `spacing.2xs`: 4px
- `spacing.xs`: 8px
- `spacing.sm`: 12px
- `spacing.md`: 16px
- `spacing.lg`: 24px
- `spacing.xl`: 32px
- `spacing.2xl`: 48px
- `spacing.3xl`: 64px

### 1.3 Border Radius System
- `radius.badge`: 8px
- `radius.button`: 14px
- `radius.card`: 20px
- `radius.modal`: 32px
- `radius.full`: 9999px

### 1.4 Typography Hierarchy (English: Plus Jakarta Sans / Inter; Khmer: Kantumruy Pro)
- **Display 1**: 32px / Line Height 40px / Bold (900)
- **Heading 1**: 24px / Line Height 32px / Bold (800)
- **Heading 2**: 20px / Line Height 28px / Semi-Bold (700)
- **Title**: 16px / Line Height 24px / Semi-Bold (600)
- **Body Large**: 15px / Line Height 22px / Regular (400) & Medium (500)
- **Body Small**: 13px / Line Height 18px / Regular (400)
- **Caption / Badge**: 11px / Line Height 14px / Bold (700) & Heavy (800)

---

## 2. Component Sets & Variants (Figma)

### 2.1 Buttons (`FG / Button`)
- **Properties**: `Variant` (Primary, Secondary, Glass, Danger, Outline), `Size` (Small: 36px, Medium: 48px, Large: 56px), `State` (Default, Hover, Pressed, Loading, Disabled), `Icon` (None, Leading, Trailing).

### 2.2 Navigation (`FG / BottomBar`, `FG / TopBar`)
- **Bottom Navigation**: 5 destinations (Home, Explore, Cart with badge counter, Orders, Profile) with glass blur background (`sigma: 20`) and active pill indicator.
- **Top Glass App Bar**: Dynamic leading back button or avatar, centered localized screen title, trailing actions (cart, search, filter).

### 2.3 Food & Restaurant Cards
- **`Card / FoodGrid`**: 180px width, top rounded hero food image, heart favorite overlay, rating badge, price pill, and one-tap `+ Add` button.
- **`Card / FoodListItem`**: Horizontal layout (thumbnail on left, title, ingredients snippet, price, quantity stepper on right).
- **`Card / RestaurantBanner`**: Wide card (340px+), hero banner with badge ("Free Delivery", "Open Now"), estimated delivery time (`20-30 min`), and customer review score.

### 2.4 Modals & Sheets
- **`Modal / FoodCustomizer`**: Bottom sheet with hero image, size selector, extra toppings checklist, special note input, and Sticky Add-to-Cart bar.
- **`Modal / KHQRPay`**: Official Bakong/KHQR standard dimensions, merchant name, dynamic amount in USD and KHR (`៛`), live countdown timer, and ABA/Bakong bank badges.
- **`Modal / DriverIncomingOrder`**: Fullscreen/High-priority dialog with 30s accept timer countdown, pickup restaurant name, delivery address distance, and guaranteed earnings.

---

## 3. Screen Inventory & Flow Specifications

### Flow A: Customer Mobile Journey
1. **Screen 01 — Splash & App Initialization**: Animated logo reveal with pre-cached session check.
2. **Screen 02 — Onboarding & Language Selection**: 3 illustrated slides highlighting Phnom Penh street food, instant KHQR payments, and live GPS tracking + Khmer/English language selector.
3. **Screen 03 — Login & Phone OTP**: Dual login via Phone OTP or Email/Password + biometric FaceID shortcut.
4. **Screen 04 — Home / Culinary Discovery**: Khmer category carousels (*Amok, Kuy Teav, Lok Lak, Khmer BBQ, Beverages*), flash promotions, personalized recommendations.
5. **Screen 05 — Search & Smart Filters**: Instant live search, filter bottom sheet (cuisine, price tier, delivery speed, dietary requirements).
6. **Screen 06 — Restaurant Details**: Header parallax image, info modal, sticky horizontal category tabs, food item grid.
7. **Screen 07 — Food Details & Modifiers Sheet**: Size options, spice levels, customizable ingredients, live total calculation.
8. **Screen 08 — Cart & Order Summary**: Free delivery progress bar, driver tip selector ($0.50, $1.00, $2.00), coupon code field.
9. **Screen 09 — Checkout & KHQR Experience**: Address selector, delivery notes, payment method selection, and interactive KHQR payment sheet.
10. **Screen 10 — Order Confirmed & Live Tracking**: Success badge, animated driver marker on OpenStreetMap, live delivery step timeline, in-app call/chat actions.
11. **Screen 11 — Profile & Settings**: Language switcher (English / ភាសាខ្មែរ), theme switch (Glass Dark / Light), address manager, payment cards.

### Flow B: Driver Delivery Flow (New in v2.0)
1. **Screen 12 — Driver Dashboard & Duty Switch**: Online/Offline toggle, today's completed trips, total earnings ($ and ៛), rating.
2. **Screen 13 — Incoming Order Radar**: 30-second countdown alert showing restaurant location, customer drop-off distance, and delivery fee payout.
3. **Screen 14 — Active Delivery Route**: Turn-by-turn map view to restaurant, pickup verification checkbox, route to customer destination.
4. **Screen 15 — Delivery Completion & Proof**: Customer signature pad or photo proof upload, instant payout confirmation.

### Flow C: Restaurant Manager / Admin Dashboard (Responsive Web / Tablet)
1. **Screen 16 — Live Orders Kanban**: Columns for *New Orders (Pending)*, *Kitchen In Progress (Preparing)*, *Ready for Driver*, and *Dispatched*.
2. **Screen 17 — Menu & Inventory Management**: Food item instant availability toggle (In Stock / Sold Out), price editing, daily special flags.
3. **Screen 18 — Revenue & Sales Analytics**: Daily revenue chart, top-selling Khmer dishes, average delivery fulfillment time.

---

## 4. Figma MCP Tooling Status & Developer Handoff

- **Official Figma MCP Plugin**: Catalog ID `antigravity-plugins-partners/plugin/figma`.
- **Status in Session**: Not currently pre-installed in the agent sandbox.
- **Recommendation**: Once authenticated with the Figma token, designers and developers can use Figma Code Connect to link Flutter widgets directly to Figma component nodes (`FG/FoodCard` -> `GlassFoodCard`, `FG/KHQRPayModal` -> `GlassQrPayModal`).
- **Design Tokens Export**: Tokens are exported as Dart constants in `lib/core/theme/glass_theme.dart` and `lib/core/theme/app_tokens.dart`.
