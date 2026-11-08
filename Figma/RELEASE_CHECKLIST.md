# FoodGo v2.0 — Production Release Checklist

**Release Target**: FoodGo v2.0 Production Release  
**Status**: Ready for Verification & User Sign-off  

---

## 1. Quality & Code Verification
- [x] **Static Analysis**: `flutter analyze` completed with **0 issues**.
- [x] **Flutter Unit Tests**: 9/9 tests passed (`flutter test`).
- [x] **Backend Unit Tests**: 5/5 tests passed (`python manage.py test core`).
- [x] **Startup Hang Prevention**: 800ms timeouts on Secure Storage + SharedPreferences fallback + post-frame callback timer (2600ms) + tap-to-skip.
- [x] **Zero Blank Screens**: Pre-populated fallback Cambodian data in `RestaurantProvider`.

---

## 2. Feature & Experience Completeness
- [x] **Cambodian Localization**: Khmer (ភាសាខ្មែរ) and English switcher across navigation, home, settings, driver, and admin portals.
- [x] **Authentic Khmer Cuisine**: Real dishes seeded (Royal Fish Amok, Siem Reap Beef Lok Lak, Phnom Penh Kuy Teav, Bai Sach Chrouk).
- [x] **Interactive Food Customizer**: Portion sizes, 4-tier spiciness selector, paid toppings checklist, special chef notes.
- [x] **Interactive KHQR Payment**: `GlassQrPayModal` with USD/KHR toggle (`1 USD = 4,100 ៛`), custom QR matrix, bank badges, countdown timer, and simulated verification.
- [x] **Cart Enhancements**: Cambodian free delivery meter ($15.00 threshold) and rider tip selector.
- [x] **Driver Delivery Portal**: Online/Offline duty toggle, incoming delivery radar (30s timer), turn-by-turn milestone progression.
- [x] **Restaurant Kitchen KDS**: Live orders Kanban (Pending, Preparing, Ready, Dispatched) and stock availability toggle.

---

## 3. Pending Deployment Actions (Requiring User Approval)
- [ ] Push Git commits to remote GitHub repository (`git push origin master`).
- [ ] Install official Figma MCP plugin from marketplace (`antigravity-plugins-partners/plugin/figma`) and authenticate.
- [ ] Run production release build (`flutter build apk --release` / `flutter build web --release`).
