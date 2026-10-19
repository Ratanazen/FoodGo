# FoodGo — TikTok Reference Video UI/UX Analysis

## 1. Source Reference Details
- **Platform**: TikTok
- **Creator**: `@dailyflutterui`
- **Video ID**: `7696552901430250759`
- **Short Link**: `https://vt.tiktok.com/ZSgL7AymR/`
- **Resolution**: 720 x 998 px, 30 fps
- **Simulator Environment**: iOS 26.3 on iPhone 17 Pro Max
- **Editor Environment**: VS Code with Flutter project (`lib/features/home/home_page.dart`, `home_header.dart`, `home_sections.dart`)

---

## 2. Screen-by-Screen Visual Specifications

### Screen A: Modernized Home Screen

#### 1. Curved Lush Green Header Container
- **Geometry**: Curved bottom edge (`BorderRadius.vertical(bottom: Radius.circular(32))`).
- **Gradient**: Lush green delivery gradient (`#25752C` to `#43A047`).
- **User Avatar**: Circular avatar (diameter ~40dp) on the left.
- **Deliver-To Selector**:
  - Top row: Small green dot (`●`) + `"Deliver to"` in light sage green (`#C8E6C9`).
  - Bottom row: Bold `"Home"` followed by truncated street address (`"12 Jalan Ampang, Kuala L..."`) and a dropdown chevron icon (`Icons.keyboard_arrow_down`).
- **Notification Bell**: Right-aligned circular button with subtle translucent white background and red unread dot indicator.

#### 2. Rounded Pill Search Bar
- **Shape**: Rounded pill (`BorderRadius.circular(30)`).
- **Background**: Solid white (`#FFFFFF`) with subtle ambient shadow (`Color(0x12000000)`, blur 12, offset (0, 4)).
- **Leading Icon**: Search icon (`Icons.search`) in medium grey (`#757575`).
- **Placeholder**: `"Search restaurants or dishes"`.
- **Trailing Action**: Filter adjustment sliders icon button.

#### 3. Hero Promo Banner
- **Card**: Rounded container with curved colorful background, scooter courier graphic.
- **Copy**: Bold display text `"FAST & FREE DELIVERY!"`, secondary `"On all orders this week!"`.
- **Call-to-Action**: Accent rounded button `"ORDER NOW"` with energetic red/orange background.

#### 4. Categories Carousel
- **Header**: Section title `"Categories"` (bold dark charcoal) with right-aligned green `"See All"`.
- **Active Category**: Solid green pill with white text and category icon.
- **Inactive Categories**: Clean white rounded cards (`BorderRadius.circular(16)`), subtle shadow, 3D style icon (`Burger`, `Pizza`, `Sushi`, `Chicken`), dark charcoal text.

#### 5. Deals For You Carousel
- **Header**: Section title `"Deals for you"` with `"See All"`.
- **Deal Cards**: Rounded horizontal cards displaying:
  - Promo badge (e.g. `"30% OFF"` or `"FREE DELIVERY"`).
  - Coupon voucher code chip (`FOODIE30`, `FREESHIP`).
  - Action button: Solid green rounded `"Claim"` button that applies the coupon instantly.

#### 6. Restaurants Near You (2-Column Grid)
- **Header**: Section title `"Restaurants near you"` with `"See All"`.
- **Grid Layout**: 2-Column responsive grid (`SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2)`).
- **Card Elements**:
  - Top image with rounded corners (`Radius.circular(16)`).
  - Discount ribbon/pill top-left: e.g. `"20% OFF"`, `"15% OFF"`, `"25% OFF"`.
  - Brand logo badge top-right: e.g. McDonald's Golden Arches, KFC badge, Domino's tile, Pizza Hut logo.
  - Restaurant title: Bold typography (e.g. `McDonald's - Bukit Bintang`, `KFC - Jalan Ampang`).
  - Metadata row: Rating star `★ 4.6`, delivery time `20 min`, and distance `1.2 km`.

#### 7. Floating Persistent Active Order Floater
- **Placement**: Floats directly above the bottom navigation bar with elevation.
- **Content**:
  - Driver circular photo (`Ahmad`).
  - Title: `"Ahmad is on the way"` (or `"Preparing your food"` depending on status).
  - Destination subtitle: `"To Home · Arriving 11:15 PM"`.
  - Right ETA Badge: Light green pill container with bold ETA `"11 min"` (dynamically updating to `"9 min"` as observed in frame 24).
- **Interaction**: Tapping opens the full Live Tracking screen.

#### 8. Bottom Navigation Shell
- **Structure**: 5 items:
  1. `Home` (Green filled icon + label when selected)
  2. `Saved` (Favorites heart icon)
  3. `Cart` (Shopping bag icon with badge)
  4. `Offers` (Ticket / discount voucher icon)
  5. `Profile` (User avatar icon)

---

### Screen B: Live Order Tracking Screen

#### 1. Map Canvas & Route Layer
- **Map View**: OpenStreetMap / CartoDB tiles rendered under full screen.
- **Origin Pin**: Circular restaurant pin with restaurant logo (e.g. McDonald's).
- **Destination Pin**: Bold red teardrop pin with house glyph (`PY20 Ampar Park`).
- **Route Polyline**: Smooth green route line connecting restaurant to customer.
- **Courier Marker**: Motorbike rider icon moving along the polyline.
- **Top Navigation Bar**: Floating circular back arrow button (left), center pill badge `"Order #1904"`, floating recenter target button (right).

#### 2. Draggable Milestone Sheet
- **Live Status Indicator**: Green pulsing dot with `"● Live · 0:16"`.
- **Status Headline**: Bold text `"Preparing your food"` → updates to `"On the way to you"`.
- **Status Subtitle**: `"McDonald's is cooking it fresh"` → `"Ahmad is 3.4 km away"`.
- **ETA Card**: Right-side container with large bold `"15 min"` / `"12 min"` and subtitle `"Arriving 11:15 PM"`.
- **5-Step Progress Stepper**:
  - Steps: `Confirmed` → `Preparing` → `Picked up` → `On the way` → `Delivered`.
  - Horizontal progress bar connecting steps with green fill for completed/active milestones.
- **Courier / Driver Card**:
  - Circular driver avatar (`Ahmad Faizal`).
  - Driver rating: `★ 4.9 · 2384 trips`.
  - Action buttons: Light green chat bubble button + solid green phone call button.
  - Vehicle badge: Motorbike icon with `"Honda EX5 · Red"` and dark license plate pill `"WXY 4821"`.
- **Status Timeline**:
  - Step 1: `● Order confirmed` with timestamp `10:55 PM`.
  - Step 2: `● Preparing your food` with timestamp `10:55 PM`.
  - Step 3: `● Rider picked up` with duration pill `0:01`.
  - Step 4: `○ On the way`.
  - Step 5: `○ Delivered`.
- **Route Summary Card**:
  - `From` McDonald's - Bukit Bintang.
  - Vertical dotted connector line.
  - `To` Home (12 Jalan Ampang, Kuala Lumpur).
  - Footer pill: `% 3.5 km · 6 min ride`.
- **Itemized Order Receipt**:
  - Dish thumbnail, `2x Big Mac`, `$10.98`.
  - Dish thumbnail, `1x French Fries`, `$2.90`.
  - Dish thumbnail, `1x McFlurry Oreo`, `$3.00`.

---

## 3. Classification of Elements

### Directly Observed (From Video Frames)
- Curved lush green top header with avatar, dropdown deliver-to location, and notification bell.
- White pill search bar with filter icon.
- FAST & FREE DELIVERY promo hero banner.
- Categories carousel with green active pill.
- Deals for you carousel with claimable coupon codes.
- 2-Column restaurant grid with discount badges, brand logos, ratings, times, distances.
- Floating persistent active order floater above bottom navigation bar with live ETA badge.
- 5-Tab bottom navigation bar (`Home`, `Saved`, `Cart`, `Offers`, `Profile`).
- Live tracking screen with map polyline, rider marker, `● Live` indicator, 5-step stepper, driver contact buttons, timeline, route card, and itemized dishes.

### Suggested Improvements (Best Practices)
- Support both **Lush Green Light Theme** and **Dark Glassmorphism Theme** seamlessly via `ThemeProvider`.
- Dual-currency display (USD `$` and Cambodian Riel `៛`) on all restaurant prices and order items.
- Delivery Confirmation QR scanner directly accessible from the Live Tracking screen.
- Auto-reconnecting WebSocket client with polling fallback for driver GPS updates.

### Unverified / Inaccessible from Video
- Exact backend API contracts used by `@dailyflutterui` (the video demonstrates UI state in Flutter; FoodGo connects to its real DRF backend).
- In-depth checkout sheet (the video transitions directly between Home and Live Tracking).
