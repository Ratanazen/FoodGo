# FoodGo v2.0 — Android APK Package (`APK/`)

**Course / Group**: ACLEDA University of Business (AUB) • Batch 09 • Year 3 • Semester 1 • Group 7 (`aub-batch-09-y3-s1-m-g7-Food-Delivery-App`)  
**Version**: `2.0.0+20`  
**Platform**: Android Universal APK (`arm64-v8a`, `armeabi-v7a`, `x86_64`)  
**Framework**: Flutter 3.x (Material 3 + Frosted Glass & 16-Palette `GlassTheme`)

---

## Included Files & Direct Download
- **Tracked Repository APK**: [`APK/FoodGo-v2.0-release.apk`](./FoodGo-v2.0-release.apk) (`88,989,421` bytes / `89.0 MB`)
- **Direct APK Download (`Ratanazen/FoodGo` Release)**: [Download `FoodGo-v2.0-release.apk`](https://github.com/Ratanazen/FoodGo/releases/download/v2.0-showcase/FoodGo-v2.0-release.apk)
- **Direct APK Download (`AUB Group 7` Release)**: [Download `FoodGo-v2.0-release.apk`](https://github.com/tonghengkeo-aub/aub-batch-09-y3-s1-m-g7-Food-Delivery-App/releases/download/v2.0/FoodGo-v2.0-release.apk)
- [`FoodGo-v2.0-release.apk.sha1`](./FoodGo-v2.0-release.apk.sha1) — SHA-1 checksum (`a887562b5e28e5d3a78077680e9f12e627be5cc2`)
- [`FoodGo-v2.0-release.apk.sha256`](./FoodGo-v2.0-release.apk.sha256) — SHA-256 checksum (`43eb57358015dd0352670e3e3451df936a159877f14e39ab30aa16422505e2ee`)

---

## Verify Integrity

```bash
cd APK
sha1sum -c FoodGo-v2.0-release.apk.sha1
sha256sum -c FoodGo-v2.0-release.apk.sha256
```

---

## Installation Instructions

### Option A: Direct Install on Android Phone
1. Transfer `APK/FoodGo-v2.0-release.apk` to your Android device (or download it from GitHub Releases).
2. Tap the file in your File Manager and allow **Install from Unknown Sources** if prompted.
3. Launch **FoodGo**.

### Option B: Install via ADB (Android Emulator or USB Debugging)
```bash
adb install -r APK/FoodGo-v2.0-release.apk
```

---

## Backend Endpoints & Local Build Override

By default, the release APK connects to:
- **Primary API (`AppConfig.defaultLiveUrl`)**: `https://food-go-app.vercel.app/api/`
- **Edge Fallback (`AppConfig.cloudflareEdgeUrl`)**: `https://foodgo.rtnaeam611.workers.dev/api/`
- **Live WebSocket (`AppConfig.wsBaseUrl` / `wsPaymentBaseUrl`)**: `wss://foodgo-53pl.onrender.com/ws/tracking/` and `/ws/payments/`

To compile a release APK targeting a local development backend instead:
```bash
cd foodgo_flutter
# Android Emulator -> host Django server
flutter build apk --release --dart-define=FOODGO_API_URL=http://10.0.2.2:8000/api/ --dart-define=FOODGO_WS_URL=ws://10.0.2.2:8000/ws/tracking/

# Physical Android device on same Wi-Fi LAN
flutter build apk --release --dart-define=FOODGO_API_URL=http://<YOUR_PC_LAN_IP>:8000/api/
```
