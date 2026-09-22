# FoodGo — Test Report

**Date:** September 22, 2026
**Commit:** `8c77d10` (master)

---

## Flutter Tests

| # | Group | Test | Result |
|:--|:------|:-----|:-------|
| 1 | CartProvider Tests | Add item updates quantity and totalAmount | ✅ PASS |
| 2 | PaymentModel Tests | fromJson deserializes correctly | ✅ PASS |
| 3 | CartProvider Edge Cases | Remove item that does not exist does nothing | ✅ PASS |
| 4 | CartProvider Edge Cases | Clear empty cart does not throw | ✅ PASS |
| 5 | CartProvider Edge Cases | Adding multiple different items calculates total correctly | ✅ PASS |
| 6 | CartProvider Edge Cases | Adding same item multiple times increases quantity | ✅ PASS |
| 7 | PaymentModel Edge Cases | fromJson handles PAID status | ✅ PASS |
| 8 | PaymentModel Edge Cases | fromJson handles EXPIRED status | ✅ PASS |
| 9 | PaymentModel Edge Cases | fromJson handles null qr_payload | ✅ PASS |

**Result:** 9/9 passed ✅

---

## Django Backend Tests

| # | Result |
|:--|:-------|
| 16 tests | All PASS |

**Result:** 16/16 passed ✅

---

## Static Analysis

| Tool | Result |
|:-----|:-------|
| `flutter analyze` | No issues found ✅ |
| `python manage.py check` | System check identified no issues ✅ |

---

## Build Verification

| Build | Result | Time |
|:------|:-------|:-----|
| `flutter build web --release` | ✓ Built build/web | 63.4s |
| Font tree-shaking (CupertinoIcons) | 257,628 → 1,472 bytes (99.4% reduction) | — |
| Font tree-shaking (MaterialIcons) | 1,645,184 → 20,404 bytes (98.8% reduction) | — |

---

## Summary

- **Total Flutter tests:** 9/9 PASS
- **Total Backend tests:** 16/16 PASS
- **Static analysis:** 0 issues
- **Release build:** SUCCESS
- **No regressions detected**
