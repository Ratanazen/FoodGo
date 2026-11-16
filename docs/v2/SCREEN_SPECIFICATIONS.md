# FoodGo v2.0 — Screen Specifications & Interaction Blueprints

## Overview
This document specifies the information architecture, component hierarchy, visual assets, and interaction behaviors for every screen across the Customer, Driver, and Admin applications in FoodGo v2.0.

---

## 1. Customer Application (19 Screens)

### 1.1 Splash Screen (`/`)
- **Visual Assets:** High-resolution vector FoodGo 3D logo, organic leaf emblem, animated version badge (`v2.0.0+20`).
- **Hierarchy:** Centered brand mark -> Pulsing status ring -> Initializing services status text -> Version footer.
- **Interactions:** Staggered scale and fade entrance (1200ms); checks JWT auth token and route:
  - Valid customer token -> `/home`
  - Valid driver token -> `/driver`
  - Valid admin token -> `/admin`
  - First-time user -> `/onboarding`
  - Unauthenticated -> `/login`

### 1.2 Onboarding (`/onboarding`)
- **Visual Assets:** 3 custom vector scenes:
  1. *Culinary Discovery:* Fresh organic ingredients, Cambodian culinary spices, chef prep.
  2. *Live Courier Transit:* Electric delivery scooter with GPS route line across Phnom Penh landmarks.
  3. *NBC Bakong KHQR:* Secure digital payment shield with KHQR symbol and instant receipt.
- **Hierarchy:** Top skip button -> Illustration canvas (240px height) -> Page title (Heading 1) -> Description -> Bottom dot indicators and Next / Get Started button.
- **Accessibility:** Keyboard arrow navigation, voiceover semantic labels for each slide.

### 1.3 Login Screen (`/login`)
- **Components:** `AuthIllustration(type: signIn)`, `GlassTextField` (Username/Email), `GlassTextField` (Password with visibility toggle), "Forgot Password?" text button, `GlassButton` ("Sign In"), Biometric / Phone Login alternative chip.
- **States:** Autofocus on username; inline red error banners for invalid credentials; loading spinner inside button during API post.

### 1.4 Registration Screen (`/register`)
- **Components:** `AuthIllustration(type: signUp)`, Role selector chips (Customer, Courier Driver, Restaurant Owner), Form fields (Full Name, Phone Number, Password, Confirm Password), Terms & Privacy checkbox.
- **Validation:** Live client validation (minimum 6-character password, matching confirmation, valid Cambodian phone `+855` or `01x-xxx-xxx`).

### 1.5 Phone & OTP Verification Modal / Screen (`/verify-otp`)
- **Components:** Shield lock icon, Phone number display with edit button, 6-box `ModernOtpInput`, 60-second countdown ring, "Resend Code" button, Verify CTA button.
- **Behavior:** Automatically submits when 6th digit is typed; disables resend button until countdown expires; vibrates with haptic error on invalid code.

### 1.6 Home & Food Discovery (`/home`)
- **Components:**
  - *Location Delivery Header:* Pin icon, current address label, city dropdown, notification bell with unread badge, profile avatar.
  - *Search & Filter Bar:* Tappable pill search field triggering instant search or category filter sheet.
  - *Promotional Carousel:* Auto-scrolling promo banners (e.g. 30% OFF Whole Order, Free Delivery, Khmer New Year Special).
  - *Category Pills:* Horizontal list (All, Salads, Bowls, Burgers, Khmer Food, Drinks, Desserts) with active indicator.
  - *Featured Kitchens:* Horizontal scroll of top-rated restaurant cards.
  - *Food Item Grid:* 2-column responsive grid of dish cards with instant "+ Add" button.

### 1.7 Search & Filter Screen (`/search`)
- **Components:** Full-width search bar with clear button, filter icon, "Recent Searches" tags, "Trending Cuisines" chips, filtered results grid with sorting dropdown (Popular, Price: Low to High, Delivery Time, Top Rated).
- **Empty State:** `VectorEmptyView(type: noSearchResults)` when query yields 0 restaurants or dishes.

### 1.8 Restaurant Categories Screen (`/categories`)
- **Components:** Category cards with photography, icon badge, count of active kitchens, and delivery time average.

### 1.9 Restaurant Details Screen (`/restaurants/:id`)
- **Components:**
  - *SliverAppBar Banner:* Restaurant hero cover photo, back button, favorite toggle button.
  - *Header Card:* Restaurant name, rating badge, distance in km, delivery time estimate, dietary badges.
  - *Menu Categories Bar:* Sticky horizontal category tab bar (Starters, Main Dishes, Drinks, Specials).
  - *Menu Items List:* Vertical dish list with image thumbnail, description, price, and add button.
  - *Floating Mini Cart:* Appears at bottom if cart contains items from this restaurant.

### 1.10 Food Item Details Sheet / Screen (`/food/:id`)
- **Components:** High-res food hero photo, dish title, price, dietary badges, calorie/macro summary, customization options (Spice level, Extra toppings, Special instructions input), quantity stepper, and "Add to Cart ($X.XX)" button.

### 1.11 Cart Screen (`/cart`)
- **Components:** Restaurant banner, list of cart items with quantity stepper and swipe-to-delete, coupon code input field with apply button, order summary card (Subtotal, Delivery Fee, Discount, Total in USD and KHR), "Proceed to Checkout" button.
- **Empty State:** `VectorEmptyView(type: emptyCart)` with "Browse Menu" button.

### 1.12 Checkout Screen (`/checkout`)
- **Components:**
  - *Delivery Address:* Selected address card with "Change" button and "Add Note for Driver" (gate code, apartment number).
  - *Delivery Speed Option:* Standard (20-30 min) or Priority Delivery (+ $0.50).
  - *Payment Method Selector:* Radio cards for NBC Bakong KHQR, ABA PayWay, ACLEDA, Wallet Balance, Cash on Delivery (COD).
  - *Order Total Breakdown:* Itemized list with taxes, delivery fees, and applied voucher discount.
  - *Place Order CTA:* Primary button showing total.

### 1.13 Bakong KHQR Payment Screen (`/payment/khqr`)
- **Components:** Bank gateway header (Bakong / NBC logo), merchant name, amount in USD and KHR, generated EMVCo dynamic QR canvas, 5-minute countdown clock, "Save QR" button, "Open in Bakong App" deep link button, real-time polling indicator.
- **Security:** Polls authoritative backend status endpoint every 3 seconds; transitions to success automatically upon bank webhook arrival.

### 1.14 Order Confirmation & Success Screen (`/order-success/:id`)
- **Components:** Animated success checkmark vector, order reference number (`#FG-XXXX`), estimated delivery time arrival, order receipt summary card, "Track Delivery" primary button, "Back to Home" secondary button.

### 1.15 Live Order Tracking Screen (`/tracking/:id`)
- **Components:**
  - *Interactive Map:* OpenStreetMap / flutter_map rendering restaurant pin, customer delivery pin, and live courier motorcycle pin.
  - *Status Milestone Card:* 4-step progress line (Order Received -> Preparing -> In Transit -> Delivered).
  - *Courier Information Card:* Driver name, vehicle type, rating, direct phone call button, and in-transit delivery PIN display.

### 1.16 Order History Screen (`/orders`)
- **Components:** Segmented control (Active Orders vs Past Orders), order cards with restaurant logo, date, item summary, total price, status badge, "Track" button (for active orders) and "Reorder" / "Rate" button (for completed orders).

### 1.17 Customer Profile Screen (`/profile`)
- **Components:** User avatar, name, email, phone number, loyalty points / wallet balance card, navigation list tiles (Delivery Addresses, Payment Methods, Order History, Theme Center, Language Settings, Support, Logout).

### 1.18 Notifications Screen (`/notifications`)
- **Components:** Grouped notification list (Today, Yesterday, Older), icons indicating type (Order Update, Promotional, System Alert), swipe to dismiss, mark all as read.

### 1.19 Theme & Language Settings Screen (`/theme-center`)
- **Components:** Active theme skin preview card, appearance mode selector (System, Light, Dark), 31 theme skin gallery with live color swatches, "Enable Skin Animations" toggle, "Respect Reduced Motion" indicator, Khmer / English language toggle.

---

## 2. Driver Application (12 Screens & Modals)

### 2.1 Driver Authentication & KYC Status
- Driver login with credentials; checks `is_approved` status; shows "Account Under Verification" screen if pending review.

### 2.2 Availability & Shift Controller
- Large tactile online/offline switch with GPS accuracy badge, shift hours counter, and today's completed trip total.

### 2.3 Available Orders Radar
- Incoming order card showing restaurant name, pickup distance, drop-off neighborhood, delivery fee earnings, and acceptance timer.

### 2.4 Order Acceptance Radar
- 30-second acceptance radar modal with map snippet, order items preview, and "Accept Delivery" swipe button.

### 2.5 Restaurant Pickup Flow
- Step 1 of active delivery: turn-by-turn route to restaurant, order pickup ID, item checklist for restaurant handoff, "Confirm Pickup" button.

### 2.6 Customer Delivery Flow
- Step 2 of active delivery: route to customer address, customer special instructions, one-tap phone call button.

### 2.7 Navigation Integration
- Live map view with courier bearing orientation and "Open in Google Maps / Waze" external launch button.

### 2.8 Cash Collection & Payment Verification
- For COD orders: cash collection amount reminder and "Confirm Cash Collected" button.
- For Bank QR orders: displays gateway verification status badge (Driver cannot override bank gateway).

### 2.9 Proof of Delivery Modal
- Dual delivery confirmation: camera scanner for customer delivery QR or 6-digit confirmation PIN numeric entry.

### 2.10 Driver Order History & Earnings
- Tab showing daily earnings, total trips, tips breakdown, and list of completed delivery receipts.

### 2.11 Driver Profile & Vehicle Settings
- Courier details, license plate number, vehicle type (Motorcycle, Scooter), document renewal status, and emergency contact.

### 2.12 Location & Network Error States
- In-screen error banners explaining GPS permission requirements with direct system settings launcher.

---

## 3. Admin Dashboard (10 Sections)

### 3.1 Overview & Analytics
- Metric KPI cards: Daily Gross Revenue (USD + KHR), Active Orders, Online Couriers, Registered Customers, hourly order bar chart.

### 3.2 Live Order Dispatch Board
- Kanban columns or filterable table: Pending Confirmation, In Kitchen, Assigned, Out for Delivery, Completed, Cancelled.

### 3.3 Customer Management
- Searchable user table with customer ID, name, email, phone, total orders, wallet balance, and active/banned status toggle.

### 3.4 Driver Verification & Management
- Driver verification queue: courier application details, driver license photo inspection, approve/reject buttons with audit log recording.

### 3.5 Restaurant & Kitchen Directory
- Partner restaurant directory: active kitchen toggle, rating, category tags, opening hours, commission rate config.

### 3.6 Menu & Dish Catalog
- Item-level price editor, description, high-res food image URL, category assignment, and instant out-of-stock toggle.

### 3.7 Financial & Payment Ledger
- Transaction reconciliation table with gateway transaction ID, merchant reference, payment provider (Bakong, ABA, ACLEDA, COD), amount, currency, HMAC status, and timestamp.

### 3.8 Promotions & Coupon Codes
- Promo voucher creator: coupon code, discount percentage or fixed USD, minimum order threshold, expiration date, max usage quota.

### 3.9 Audit Logs & Security
- Immutable security audit log showing administrative actions (driver approvals, order cancellations, menu edits) with actor ID and IP address.

### 3.10 System Health & Infrastructure Panel
- Real-time status cards for Render Singapore (Daphne ASGI), Vercel Serverless WSGI, PostgreSQL database connection, and MongoDB Atlas sync state.
