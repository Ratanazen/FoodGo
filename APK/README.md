# FoodGo v2.0 — Android APK Package (`APK/`)

**Course / Group**: AUB Batch 09 • Year 3 • Semester 1 • Group 7 (`aub-batch-09-y3-s1-m-g7-Food-Delivery-App`)  
**Platform**: Android (`arm64-v8a`, `armeabi-v7a`, `x86_64`)  
**Framework**: Flutter 3.x (Material 3 + Frosted Glass Design System)

---

## Included Files & Direct Download
- **Direct APK Download (`Ratanazen/FoodGo` Release)**: [Download `FoodGo-v2.0-release.apk`](https://github.com/Ratanazen/FoodGo/releases/download/v2.0-showcase/FoodGo-v2.0-release.apk)
- **Direct APK Download (`AUB Group 7` Release)**: [Download `FoodGo-v2.0-release.apk`](https://github.com/tonghengkeo-aub/aub-batch-09-y3-s1-m-g7-Food-Delivery-App/releases/download/v2.0/FoodGo-v2.0-release.apk)
- `FoodGo-v2.0-release.apk` — Production release Android application package (52 MB).
- `FoodGo-v2.0-release.apk.sha1` — SHA-1 integrity checksum.

---

## Installation Instructions

### Option A: Direct Install on Android Phone
1. Transfer `FoodGo-v2.0-release.apk` to your Android device.
2. Tap the file in your File Manager and allow **Install from Unknown Sources** if prompted.
3. Launch **FoodGo**.

### Option B: Install via ADB (Android Emulator or USB Debugging)
```bash
adb install -r APK/FoodGo-v2.0-release.apk
```

---

## Connecting the APK to the Backend Server (`foodgo-server`)

On the **Login Screen** (or **Profile -> Settings -> API Server & Hosting URL**), tap **Hosting / API** to configure your server endpoint:
- **Android Emulator**: `http://10.0.2.2:8000/api/`
- **Physical Android Phone (Same Wi-Fi LAN)**: `http://<YOUR_PC_LAN_IP>:8000/api/` (run backend with `python manage.py runserver 0.0.0.0:8000`)
- **Local Desktop / Web**: `http://127.0.0.1:8000/api/`

Tap **Test Connection** to verify live `/api/health/` status before saving.

---

## Demo Accounts & Instant QR Login Tokens

| Role | Email / Username | Password | Instant QR Login Token |
| :--- | :--- | :--- | :--- |
| **Customer** | `sreypov@foodgo.kh` (`sreypov`) | `password123` | `FG-QR:customer:sreypov` |
| **Delivery Driver** | `sokha.driver@foodgo.kh` (`driver_sokha`) | `driver123` | `FG-QR:driver:driver_sokha` |
| **Kitchen Admin / Owner** | `chef.kravanh@foodgo.kh` (`chef_kravanh`) | `owner123` | `FG-QR:admin:chef_kravanh` |
