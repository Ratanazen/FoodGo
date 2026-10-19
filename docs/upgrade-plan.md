# FoodGo Feature Upgrade, UI Animation & Admin App Plan

## 1. Executive Summary

FoodGo has been upgraded with modern UI animations, customer convenience features, driver route delivery notes, and a full-featured Flutter Administrator Experience supported by secure Django REST APIs and immutable audit logging.

All pre-existing production features, including Khmer QR (Bakong NBC KHQR) payments, Cambodia fintech rails (ABA PAY, Wing, ACLEDA, Pi Pay), TikTok-style interactive live order tracking, and restaurant/driver portals, remain fully intact and operational.

---

## 2. Scope of Enhancements

### A. Customer Experience & UI Animations
1. Price Tier Filtering:
   - Added selectable price tier filter chips (`All`, `Top Rated`, `Fastest`, `Free Delivery`, `$`, `$$`, `$$$`) to both the Recommended Dishes catalog and the Restaurant Directory.
   - Dynamic real-time filtering allows budget-conscious customers to easily isolate affordable meals, mid-range favorites, or gourmet dining options.
2. Special Cooking Instructions:
   - Added dedicated special instructions text input on the Food Item Details screen (`food_item_details_screen.dart`).
   - Integrated instructions state into `CartProvider` (`specialInstructions`), seamlessly carrying forward culinary preferences and allergy alerts to the checkout screen and backend order payloads.
3. Interactive Animated Feedback:
   - Animated visual feedback on adding items to the cart: smooth checkmark transitions on the shopping bag action button.
   - Synchronized cart bounce animation in `GlassBottomNavigation` triggering whenever the cart item count increases.
   - Interactive notification SnackBars with direct "View Cart" one-tap routing.
4. Orders Reorder & Support Concierge:
   - One-tap "Order Again" button on all completed deliveries in `orders_screen.dart`, repopulating the user's cart with selected order items.
   - Integrated FoodGo Customer Support Concierge bottom sheet with options for 24/7 hotline calling, live chat agent routing, missing item/damage issue reporting dialog, and delivery FAQ policies.
5. Dual-Engine Search & Smart Filter System:
   - Segmented scope tabs (`All`, `Dishes`, `Restaurants`) enabling simultaneous cross-catalog querying.
   - Persistent search history backed by `SharedPreferences` (`foodgo_recent_searches`) with individual chip removal and "Clear All".
   - Quick craving recommendation chips with Material vector icons (Burgers, Khmer Food, Coffee & Drinks, Pizza, Healthy Bowls, Desserts, Fried Chicken, Noodles).
   - Advanced Filter Bottom Sheet modal with Sort By (Recommended, Price Low/High, Rating), Price Tiers (`$`, `$$`, `$$$`), Vegetarian Friendly toggle, and Minimum Rating thresholds.
   - Backend search filter expansion in `FoodItemViewSet` and `RestaurantViewSet` with multi-field matching (`category__restaurant__name`, `category__name`), price boundaries, and ordering.

### B. Driver Portal Enhancements
1. Special Instructions Display:
   - Active delivery cards in `driver_dashboard_screen.dart` prominently display customer notes and gate codes with warning badges.
   - Eliminates delivery confusion and improves on-time delivery rates.

### C. Administrator Console & Backend Architecture
1. Audit Logging (`AuditLog` Model):
   - Created `AuditLog` in `backend/core/models.py` with indexed timestamps, actor tracking, IP recording, and structured JSON change payloads.
   - Covers critical administrative actions: `ASSIGN_DRIVER`, `CANCEL_ORDER`, `REFUND_PAYMENT`, `TOGGLE_USER_ACTIVE`, `TOGGLE_RESTAURANT`, `UPDATE_MENU_ITEM`, and `SYSTEM_CONFIG`.
2. Admin REST API Endpoints:
   - `GET /api/admin/analytics/?period=today|week|month|all`: Aggregates order volume, revenue (USD and KHR), active users, active couriers, and ASGI database health check.
   - `GET /api/admin/orders/`: Full order management with query search and status filtering.
   - `POST /api/admin/orders/{id}/assign_driver/`: Manual driver assignment with audit logging.
   - `POST /api/admin/orders/{id}/cancel_order/`: Administrative cancellation with custom cancellation reason and audit trail.
   - `GET /api/admin/users/`: Paginated user list with role filters (`customer`, `driver`, `restaurant_owner`, `admin`).
   - `POST /api/admin/users/{id}/toggle_status/`: Quick account enable/disable switch.
   - `GET /api/admin/restaurants/`: Restaurant list with search and toggle status action.
   - `GET /api/admin/audit-logs/`: Immutable, paginated audit trail.
3. Flutter Admin Dashboard (`AdminDashboardScreen`):
   - 5 interactive tabs: Overview & Analytics, Orders Management, User Directory, Restaurant Directory, and Audit Logs.
   - Glassmorphic UI adhering to the FoodGo Design System with zero emojis.
### D. In-App Notifications & Automated Dispatch
1. Milestone Notifications:
   - Backend dispatch triggers on all key order milestone events (`pending`, `confirmed`, `preparing`, `ready`, `on_the_way`, `driver_arrived`, `delivered`, `cancelled`).
   - Customer and driver alerts with localized message copy and timestamped records.
2. Flutter Notification Center:
   - Dynamic unread count badge in `HomeScreen` location header (`Icons.notifications_none_rounded`).
   - `NotificationsScreen` with filter tabs (`All`, `Orders`, `Promos`), swipe-to-delete, mark-as-read, clear-all, and one-tap order detail bottom sheet routing to tracking (`/map/:id`).

### E. Live Driver Route GPS WebSocket & Telemetry
1. Daphne ASGI WebSocket Hardening:
   - Coordinate boundary validation (-90 <= lat <= 90, -180 <= lng <= 180) and 200ms debounce throttling.
   - Bearing angle calculation and real-time heading forwarding to active room subscribers.
2. Realistic Phnom Penh Simulation Waypoints:
   - `scripts/simulate_driver.py` with actual Phnom Penh street routes (BKK1 -> Independence Monument -> Wat Botum -> Sisowath Quay -> Koh Pich).
3. Client Animation & Marker Rotation:
   - `MapScreen` with continuous polyline progress interpolation, rotating courier motorcycle icon (`Transform.rotate`) driven by heading calculations, and live speed/ETA readout.

### F. Dynamic Multi-Currency NBC Rate Engine
1. National Bank of Cambodia (NBC) Exchange Rate API:
   - `ExchangeRate` model and `/api/currency/rates/` endpoint with customary rate (`4,100 KHR / USD`) and auto-seeding cache (`0018_exchangerate.py`).
2. App-Wide Currency Switcher:
   - `CurrencyProvider` providing user choice (`$ USD`, `៛ KHR`, `Dual ($ / ៛)`) stored in `SharedPreferences`.
   - `SettingsScreen` currency modal with dynamic app-wide recalculation across menus, cart, and checkout.

### G. Database Backup & Disaster Recovery
1. Enterprise Backup Script (`scripts/backup_db.sh`):
   - Supports both PostgreSQL (production) and SQLite (development fallback).
   - Automated gzip compression, 7-day retention rotation, and restore verification mode.

---

## 3. Verification & Quality Gates

- Django Backend Tests: 73/73 tests passing (100% pass rate).
- Flutter Tests: 81/81 tests passing (100% pass rate).
- Total Automated Tests: 154 tests passing (100% pass rate).
- Flutter Analyzer: Zero warnings, zero errors (`flutter analyze --no-pub`).
- Code Formatting: All Dart files formatted according to official Dart conventions.
- Zero-Emoji Compliance: All code, UI assets, tests, and documentation adhere strictly to Material and vector SVG icons (0 emojis detected across repository).

