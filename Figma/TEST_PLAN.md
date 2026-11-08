# FoodGo v2.0 — Automated & Manual Test Plan

**Scope**: Unit Testing, Integration Testing, Static Analysis, Performance, and Security Validation  
**Execution Environment**: Linux 6.6, Flutter 3.13 / Dart SDK, Python 3.12 / Django 6.1  

---

## 1. Test Suite Summary

### 1.1 Flutter Automated Unit Tests (`foodgo_flutter/test/providers_test.dart`)
- **CartProvider**:
  - Empty cart initial state verification (`totalAmount == 0.0`, `deliveryFee == 0.0`).
  - Item addition, quantity increments, and subtotal calculation.
  - Free delivery threshold verification: orders $\ge \$15.00$ automatically waive delivery fee ($0.00).
  - Driver tip calculation addition ($0.50, $1.00, $2.00).
  - Coupon application (`FOODGO30` applied discount calculation).
- **LanguageProvider**:
  - Default initialization (`en-US`).
  - Switching to Khmer (`km-KH`) with key phrase translation verification (`place_order`, `driver_mode`).
- **RestaurantProvider**:
  - Default authentic Cambodian dishes and restaurants loading check.
  - Favorite toggle state check.

### 1.2 Django Backend Tests (`backend/core/tests.py`)
- **API Tests**:
  - `test_restaurant_list_api`: Verifies HTTP 200 OK and populated restaurant data.
  - `test_food_items_api`: Verifies menu item filtering by restaurant ID.
  - `test_user_registration`: Verifies user creation and JWT token issuance.
  - `test_authenticated_order_creation_and_khqr`: Verifies transactional order creation with total amount calculation and payment model binding.
  - `test_favorite_toggle_api`: Verifies dynamic add/remove of customer favorite food items.

---

## 2. Test Execution Commands

```bash
# 1. Run Flutter Unit Tests
cd foodgo_flutter && flutter test

# 2. Run Flutter Static Analysis
cd foodgo_flutter && flutter analyze

# 3. Run Django Backend Tests
cd backend && ./venv/bin/python manage.py test core
```
