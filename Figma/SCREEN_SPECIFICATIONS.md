# FoodGo v2.0 — Screen Specifications

This specification details the 18 production screens across Customer, Driver, and Restaurant Kitchen Admin experiences.

---

## 1. Customer Screens
1. **`SplashScreen` (`/splash`)**: Animated logo reveal with 2600ms guaranteed fallback timer, non-blocking auth check, and tap-to-continue bypass.
2. **`OnboardingScreen` (`/onboarding`)**: 3-step carousel highlighting Phnom Penh culinary selection, KHQR instant scan, and live GPS tracking.
3. **`LoginScreen` (`/login`) & `RegisterScreen` (`/register`)**: Modern authentication forms with validation, password visibility toggles, and JWT storage.
4. **`ForgotPasswordScreen` (`/forgot-password`)**: Email reset request screen with confirmation snackbars.
5. **`HomeScreen` (`/home`)**: Delivery address bar, bilingual toggle (`🇰🇭 ខ្មែរ` / `🇺🇸 EN`), promo banner, Cambodian category filters, and horizontal popular food carousel with interactive customizer.
6. **`ExploreScreen` (`/explore`)**: Interactive Phnom Penh map preview with cuisine category filter chips and restaurant cards.
7. **`RestaurantDetailsScreen` (`/restaurant/:id`)**: Header hero banner with rating and delivery fees, sticky category filter bar, food menu list, and customizer bottom sheet.
8. **`GlassFoodCustomizerModal`**: Portion size selector (Regular / Large), 4-tier spice selector, paid toppings, special notes, and dynamic price calculation.
9. **`CartScreen` (`/cart`)**: Empty state view, Cambodian free delivery meter ($15.00 threshold), driver tip selector ($0.50, $1.00, $2.00), promo code input, and grand total.
10. **`CheckoutScreen` (`/checkout`)**: Delivery address selector, delivery instructions, ABA KHQR scan-to-pay option, card payment, and cash on delivery.
11. **`GlassQrPayModal`**: Official NBC Bakong KHQR modal with USD/KHR toggle (`1 USD = 4,100 ៛`), live 5-minute countdown, bank badges, and simulated verification.
12. **`OrderSuccessScreen` (`/order-success`)**: Order ID confirmation badge, estimated preparation time (20–30 min), live tracking button, and order history button.
13. **`MapScreen` (`/map`)**: OpenStreetMap live order tracking with driver position marker, destination marker, and status milestone sheet.
14. **`OrdersScreen` (`/orders`)**: Active and past orders listing with item details, status tags, and re-order action.
15. **`ProfileScreen` (`/profile`)**: User information card, links to Edit Profile, Favorites, Addresses, Payment Methods, Driver Portal, and Kitchen KDS.
16. **`SettingsScreen` (`/settings`)**: Theme switcher (Dark / Light mode), Language switcher (English / ភាសាខ្មែរ), Portal navigation, and Account logout.

---

## 2. Driver & Admin Portals
17. **`DriverDashboardScreen` (`/driver`)**: Online/Offline duty switch, daily earnings in USD & KHR, completed trips counter, 30s incoming order radar, and turn-by-turn trip milestone progression.
18. **`AdminDashboardScreen` (`/admin`)**: Revenue snapshot header, Live Orders Kitchen Display System (KDS) Kanban (Pending, Preparing, Ready, Dispatched), and Menu Inventory instant availability toggle.
