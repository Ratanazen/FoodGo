# FoodGo Mobile App — Update Report

**Date:** September 22, 2026
**Branch:** `feature/mobile-app-update` → merged into `master`
**Commit:** `d42881e` (feature), `8c77d10` (merge)

---

## Project Details

| Field | Value |
|:---|:---|
| **Framework** | Flutter 3.47.5 (Dart 3.13.4) |
| **Architecture** | Feature-driven + Provider + Core Services |
| **Backend** | Django REST Framework (Python 3.x) |

---

## Changed Files

### Modified
1. `foodgo_flutter/lib/core/network/api_client.dart` — JWT token refresh interceptor
2. `foodgo_flutter/lib/features/orders/presentation/orders_screen.dart` — Real API order data
3. `foodgo_flutter/test/unit_test.dart` — Expanded test suite (2 → 9 tests)

### New
4. `docs/APP_AUDIT.md` — Comprehensive project audit document

### Removed
- None (zero destructive changes)

---

## Features Fixed

1. **Token Expiry Handling** — Previously, expired JWT access tokens caused silent 401 failures. Now the ApiClient automatically refreshes tokens and retries requests.
2. **Mock Orders Replaced** — OrdersScreen previously displayed 4 hardcoded fake orders. Now fetches real data from `GET /api/orders/`.

## Features Added

1. **Automatic JWT 401 Token Refresh Interceptor**
   - Catches 401 errors, calls `POST /api/token/refresh/`
   - Uses separate Dio instance to avoid interceptor recursion
   - Concurrency lock prevents multiple simultaneous refresh calls
   - On refresh failure, clears tokens for logout handling

2. **Real Orders Screen with Full State Management**
   - Loading state with CircularProgressIndicator
   - Empty state with "No orders yet" + Browse Food button
   - Error state with retry button
   - Success state with real order data from API
   - Pull-to-refresh via RefreshIndicator
   - Color-coded status badges (Pending/Confirmed/Preparing/On Delivery/Delivered/Cancelled)
   - Status timeline progress indicator for in-progress orders
   - Track Order button for delivered orders

3. **Expanded Test Suite** (2 → 9 tests)
   - CartProvider edge cases: remove non-existent item, clear empty cart, multiple items total, quantity accumulation
   - PaymentModel edge cases: PAID status, EXPIRED status, null qr_payload

---

## Security Improvements

- JWT token refresh prevents session hijacking from expired tokens
- Tokens cleared on refresh failure (force re-authentication)
- No secrets, tokens, or credentials logged or exposed

## Performance Improvements

- Token refresh interceptor prevents unnecessary logouts and re-logins
- Concurrency queue prevents duplicate refresh API calls

## UI/UX Improvements

- Real order data instead of mock placeholders
- Proper loading/empty/error states with actionable buttons
- Pull-to-refresh for order list
- Visual status timeline for in-progress orders
- Color-coded status badges for instant status recognition

---

## Migration Notes

- No database migrations required
- No breaking API changes
- Feature branch merged cleanly with no conflicts

## Rollback Notes

```bash
git revert 8c77d10  # Reverts the merge commit
```

---

## Known Issues

- OrdersScreen shows `Restaurant #ID` instead of restaurant name (planned enhancement)
- `connectivity_plus` package imported but global offline banner not yet implemented

## Remaining TODOs

1. Resolve restaurant names in OrdersScreen via RestaurantProvider cache
2. Add global offline connectivity banner
3. Standardize images on CachedNetworkImage across all screens
4. Add widget tests for OrdersScreen states

---

## Update: September 25, 2026 (Order QR Pay Fix & Admin Bill Printing)

**Commit:** `117f456`

### Issues Resolved:
1. **Order QR Payment Generation Error:**
   - Fixed `IntegrityError: UNIQUE constraint failed: core_payment.order_id` in `backend/core/payment_views.py` when retrying or switching between ABA KHQR and ACLEDA KHQR.
   - Fixed `400 Bad Request` in `OrderViewSet` when ordering from restaurants other than restaurant #1.
   - `OrderViewSet.perform_create` now directly accepts `items` payloads, auto-resolves the restaurant, and computes accurate subtotals and fees with backward-compatible cart fallback.
   - Flutter `checkout_screen.dart` dynamically tracks `restaurantId` from cart items.

2. **Official Admin Bill & Tax Receipt:**
   - Created print-ready `backend/core/templates/core/order_bill.html` with FoodGo branding, items, subtotals, delivery fees, USD & KHR currency conversion, payment metadata, and barcode.
   - Added `order-bill` view and `🧾 Print Bill` action in Django `OrderAdmin`.
   - Added in-app `View Bill` sheet on Flutter `orders_screen.dart` and `restaurant_dashboard_screen.dart`.
