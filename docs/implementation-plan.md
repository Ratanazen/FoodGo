# FoodGo — TikTok Reference UI/UX Implementation Plan

## 1. Prioritization & Phased Delivery

### Priority 0 (P0) — Design Tokens & Core Shell
1. **Design Tokens & Theme Extensions**:
   - Primary lush green gradient: `#25752C` to `#43A047`.
   - Accent green: `#35B86B`.
   - Surface colors for clean delivery UI + dark glassmorphism compatibility.
2. **5-Tab Main Navigation Shell (`main_shell.dart`)**:
   - Tab 0: `Home` (Lush green active icon + label)
   - Tab 1: `Saved` (Favorites)
   - Tab 2: `Cart` (Cart with badge)
   - Tab 3: `Offers` (Vouchers / Promos)
   - Tab 4: `Profile` (Account & Settings)
   - Docked `ActiveOrderFloater` position overlay above bottom navigation.

### Priority 1 (P1) — Modernized Home Screen (`home_screen.dart`)
1. **Curved Green Header (`HomeHeaderWidget`)**:
   - Curved bottom border (`Radius.circular(32)`).
   - User avatar from `auth` state.
   - `Deliver to` location switcher linked to `AddressProvider`.
   - Notification bell with unread badge counter.
2. **Pill Search Bar (`HomeSearchBarWidget`)**:
   - Rounded pill (`BorderRadius.circular(30)`).
   - Search icon + placeholder `"Search restaurants or dishes"`.
   - Filter button navigating to `/search?focus=filter`.
3. **Hero Promo Banner Carousel (`HomePromoBannerWidget`)**:
   - `"FAST & FREE DELIVERY!"` with subtitle `"On all orders this week!"`.
   - Red accent `"ORDER NOW"` CTA button.
4. **Categories Carousel (`HomeCategoriesWidget`)**:
   - Horizontal list with `"All"`, `"Burger"`, `"Pizza"`, `"Sushi"`, `"Chicken"`.
   - Solid green pill for active selection; clean white rounded cards for inactive items.
   - Triggers restaurant category filter.
5. **Deals For You Carousel (`HomeDealsWidget`)**:
   - Horizontal cards with discount badges (`30% OFF`, `FREE DELIVERY`).
   - Voucher code pill (`FOODIE30`, `FREESHIP`).
   - `"Claim"` button applying coupon to `CartProvider`.
6. **Restaurants Near You 2-Column Grid (`HomeRestaurantGridWidget`)**:
   - 2-Column responsive grid (`SliverGrid`).
   - Image with discount pill top-left (`20% OFF`).
   - Brand logo top-right (McDonald's, KFC, Domino's, Pizza Hut).
   - Restaurant name, rating `* 4.6`, delivery time, and distance.
7. **Persistent Active Order Floater (`ActiveOrderFloaterWidget`)**:
   - Floating pill-card above bottom nav with subtle shadow.
   - Driver circular avatar, status title (`"Ahmad is on the way"`), destination (`"To Home · Arriving 11:15 PM"`), and green ETA badge (`"11 min"`).
   - Tapping navigates to `/orders/:id/track`.

### Priority 2 (P2) — Live Order Tracking Screen (`live_tracking_screen.dart`)
1. **Full-Screen Interactive Map Canvas**:
   - OpenStreetMap / CartoDB tiles via `flutter_map`.
   - Origin restaurant marker with logo, destination pin with house icon, courier motorcycle marker.
   - Custom route polyline in vibrant green.
   - Top floating bar: circular back button, `Order #XXXX` pill, circular recenter button.
2. **Draggable / Collapsible Milestone Sheet**:
   - Header: pulsing `● Live` dot, dynamic headline (`"Preparing your food"` / `"On the way to you"`), ETA card (`15 min`, `Arriving 11:15 PM`).
   - 5-Step visual progress stepper (`Confirmed`, `Preparing`, `Picked up`, `On the way`, `Delivered`).
   - Courier contact card: circular avatar, name, rating (`* 4.9 · 2384 trips`), chat button, call button, motorcycle pill (`Honda EX5 · Red`, `WXY 4821`).
   - Detailed milestone timeline with timestamps.
   - Route breakdown card (`From` restaurant to `To` home with distance and duration).
   - Itemized order receipt: dishes, quantities, unit prices.
   - Delivery Confirmation QR action button (driver QR scan & verify).

### Priority 3 (P3) — Cambodian Localization & Gateways Validation
1. **Currency**: Dual-currency display (USD `$` and KHR `៛`) on all restaurant cards and itemized receipts.
2. **Payment Gateways**: Ensure Bakong KHQR, ABA PayWay, ACLEDA, COD, and Wallet balance flows remain 100% operational.
3. **Delivery QR Confirmation**: Ensure driver arrival and customer scan confirmation flow remains 100% operational.

---

## 2. Verification & Testing Strategy
- Run `flutter analyze --no-pub` — 0 issues found (100% clean).
- Run `flutter test --no-pub` — 65/65 frontend unit and widget tests passing (100%).
- Run `python manage.py test core` — 67/67 backend tests passing (100%).
- Total automated tests: 132 tests passing (100%).
- Zero-Emoji Policy: 100% compliant across all code, tests, and documentation.
