# 📱 FoodGo Flutter Mobile & Web Client

The official client application for **FoodGo**, built with **Flutter 3.x**. Features a high-contrast, modern UI/UX design system with neon-lime (`#CCFF00`) accents, interactive custom vector character illustrations, real-time WebSocket order tracking, dual-currency Cambodian banking gateways (Bakong KHQR, ABA PayWay, ACLEDA), and cryptographic doorstep delivery confirmation.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Analyze](https://img.shields.io/badge/Flutter%20Analyze-0%20Issues-brightgreen)](https://flutter.dev)
[![Tests](https://img.shields.io/badge/Tests-57%20Passing-brightgreen)](https://flutter.dev)

---

## 🎨 UI/UX Design System & Key Features

### 1. Modern TikTok Reference Experience
* **Minimalist Top Bar:** Search circular button, centered delivery location selector (`📍 Naperville, Illinois ⌄`), and notification bell with active badge.
* **Spaghetti Hero Promo Card:** High-contrast dark container (`#1E1E20`) with `"Free Delivery For Spaghetti"`, round dish presentation, and neon-lime `"Order Now"` pill button (`#CCFF00`).
* **Category Filter Pills:** Rounded square category filter cards (`Burger` 🍔, `Chicken` 🍗, `Fries` 🍟, `Drink` 🥤) with smooth toggle state.
* **Recommended For You Grid:** 2-column dish card layout with floating favorite heart toggles, dual currency pricing ($ USD / ៛ KHR), and circular neon-lime `+` add-to-cart buttons with tactile haptics.
* **Food Item Detail Sheet:** Hero dish image with soft drop shadows, **4 macro-nutrients nutrition card** (`198 kcal`, `25.2 proteins`, `13.8 fats`, `23.7 carbo`), expandable `"Show more"` description, bag action, and neon-lime `"Buy Now"` button.
* **Live Order Tracking Sheet:** Interactive Google Maps polyline route, live pulsing status dot, 5-stage milestone stepper (`Confirmed` → `Preparing` → `Picked up` → `On the way` → `Delivered`), driver card with call action (`Ahmad Faizal`), route breakdown, and itemized receipt.

### 2. Custom Illustrated Auth Flows
* **Vector Character Illustrations:** Pure canvas-drawn vector illustrations via `AuthIllustration` custom painters:
  * **Sign In:** Modern character reviewing mobile charts with floating notification pills.
  * **Sign Up:** Modern character holding inspection checklist clipboard.
  * **Forget Password:** Character working on laptop with security shield badge.
* **Royal Blue Theme Accents:** High-contrast authentication buttons (`#1B64F2`), eye toggle inputs, Google/Facebook social sign-in buttons, and simulated OTP verification.

### 3. Application-Wide Screen Modernization
* **Cart Screen:** Delivery milestone progress bar, dual currency totals, neon-lime steppers (`-` and `+`) with haptics, and neon-lime `"Proceed to Checkout"` CTA.
* **Profile Screen:** Neon-lime accent ring avatar, 3-column quick shortcuts (Wallet, Orders, My KHQR Pay Me), and modern rounded `_ProfileOption` tiles.
* **Orders Screen:** Animated filter pill chips (`All`, `Active`, `Delivered`, `Cancelled`) and neon-lime `"Order Again"` CTA.
* **Explore Screen:** Modern category chips, rounded pill search bar, and circular map floating action.
* **Favorites Screen:** Minimalist circular back button, lime indicator TabBar, and circular lime `+` add-to-cart buttons.
* **Search Screen:** Rounded pill search input with lime search icon and clear action, trending search chips, and modal dish detail sheet.

### 4. Cambodian Fintech & Handover Security
* **Bakong KHQR, ABA PayWay & ACLEDA:** Dynamic KHQR codes with 5-minute countdowns, dual currency (USD/KHR), and simulated webhook payment settlement.
* **In-App Digital Wallet:** Instant top-ups and atomic balance deductions.
* **Doorstep QR Handover Modal:** Cryptographic 15-minute expiring token and 6-digit backup PIN preventing fraudulent delivery handovers.

---

## 📁 Project Structure

```
lib/
├── config/              # Centralized theme tokens (GlassTheme: #CCFF00, #1B64F2, #1E1E20)
├── models/              # Data models (Order, FoodItem, Restaurant, Payment, DeliveryQR)
├── providers/           # Provider state management (Auth, Cart, Order, Restaurant, Theme)
├── screens/             # UI screens
│   ├── auth/            # SignInScreen, SignUpScreen, ForgotPasswordScreen
│   ├── cart/            # CartScreen, CheckoutScreen, PaymentScreen
│   ├── explore/         # ExploreScreen, SearchScreen
│   ├── favorites/       # FavoritesScreen
│   ├── home/            # HomeScreen, FoodDetailScreen
│   └── orders/          # OrdersScreen, OrderTrackingScreen
│   └── profile/         # ProfileScreen, WalletScreen
├── services/            # API client, WebSocket service, KHQR generator, Location
└── widgets/             # Reusable widgets, AuthIllustration painters, dialogs & modals
```

---

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK 3.x**
- **Dart 3.x**
- FoodGo Daphne ASGI backend running on `http://127.0.0.1:8000`

### Running the App

```bash
# 1. Install dependencies
flutter pub get

# 2. Run on Google Chrome (Desktop Web)
flutter run -d chrome

# 3. Run as Web Server on port 8080 (Matches dev stack)
flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0

# 4. Run on Android or iOS device / simulator
flutter run
```

---

## 🧪 Testing & Code Quality

```bash
# 1. Static code analysis (Enforces zero warnings/errors)
flutter analyze --no-pub

# 2. Run all unit and widget tests (57 tests passing)
flutter test

# 3. Build optimized web release bundle
flutter build web --release
```

