# Cambodian SMS OTP Verification Specification

This document provides a comprehensive technical overview and operational guide for the Real Cambodian SMS OTP verification system implemented across FoodGo backend and Flutter mobile applications.

---

## 1. SMS Gateway Provider Selection

FoodGo integrates with **SimoSMS** (`smscambodia.com` / ViHaT Group Cambodia) as the primary SMS Gateway, with **WeUMS** (`weums365.com`) as secondary gateway adapter, and an in-memory **TestConsoleSMSProvider** for local development and CI testing.

### Provider Comparison Matrix

| Provider | Direct Carrier Connections | Commercial Deliverability | Public API & Documentation | Production Status |
| :--- | :--- | :--- | :--- | :--- |
| **SimoSMS (`smscambodia.com`)** | Smart, Cellcard, Metfone, Seatel, Cootel | Full Commercial Delivery App Support | Documented HTTP REST API (`/smsapi/`) | **Primary Provider** |
| **WeUMS (`weums365.com`)** | Regional Multi-Channel Routing | Commercial API & High Priority | JSON REST API with Bearer Token | **Secondary / Fallback** |
| **Nomsa (`nomsa.gov.kh`)** | Government Digital Infrastructure | Restricted to `.gov.kh` ministries | Closed to commercial applications | **Audited & Excluded** |
| **TestConsoleSMSProvider** | Local Mock & Memory Store | Isolated Test Suite Verification | In-memory message tracker | **Testing & CI** |

### SimoSMS Gateway Integration Details
- **Base Endpoint**: `https://smscambodia.com/smsapi/`
- **Method**: `POST` (JSON payload)
- **Message Type**: `SmsType = 2` (Transactional / OTP message)
- **Payload Schema**:
  ```json
  {
    "ApiKey": "<YOUR_API_KEY>",
    "SecretKey": "<YOUR_SECRET_KEY>",
    "Phone": "85512345678",
    "Content": "FoodGo: Your verification code is 123456. Valid for 5 minutes. Do not share this code with anyone.",
    "Brandname": "FoodGo",
    "SmsType": 2
  }
  ```
- **Response Codes**:
  - `CodeResult: 100` -> Success / Delivered
  - `CodeResult: 101` -> Authorization failed. Invalid API credentials.
  - `CodeResult: 103` -> Insufficient SMS account balance.
  - `CodeResult: 104` -> Sender ID does not exist or is not approved.
  - `CodeResult: 118` -> Invalid message type specified.
  - `CodeResult: 119` -> Sender name character exceeds 21 characters.

---

## 2. Phone Number Normalization & Validation

Cambodian mobile phone numbers are normalized to the international E.164 format (`+855...`) prior to processing or database lookup.

### Normalization Logic (`normalize_cambodia_phone`)
1. Strips all spaces, hyphens, periods, and parentheses.
2. Formats:
   - `012 345 678` -> `+85512345678`
   - `85512345678` -> `+85512345678`
   - `0085512345678` -> `+85512345678`
   - `+855 12 345 678` -> `+85512345678`
3. Validates length (8 or 9 digits after `+855`).
4. Validates carrier operator prefixes against known Cambodian mobile networks:
   - **Smart**: `010`, `015`, `016`, `069`, `070`, `081`, `086`, `087`, `093`, `096`, `098`
   - **Cellcard**: `011`, `012`, `014`, `017`, `061`, `076`, `077`, `078`, `079`, `085`, `089`, `092`
   - **Metfone**: `031`, `060`, `066`, `067`, `068`, `071`, `088`, `090`, `097`
   - **Seatel**: `018`
   - **Cootel**: `038`
5. Non-Cambodian numbers (e.g. `+1...`, `+84...`) and invalid lengths are rejected with structured 400 Bad Request responses.

---

## 3. Cryptography & Storage Security

### Zero Plaintext Storage Policy
Plaintext OTP codes are **never** stored in the database and **never** logged to disk.
- **Generation**: Cryptographically secure 6-digit random number generated via `secrets.choice("0123456789")` (CSPRNG).
- **Salting**: 32-character hexadecimal random salt generated via `secrets.token_hex(16)`.
- **HMAC Storage**: Keyed HMAC-SHA256 representation using Django's `SECRET_KEY` and the unique challenge salt:
  `hmac.new(SECRET_KEY, f"{salt}:{otp}".encode('utf-8'), hashlib.sha256).hexdigest()`
- **Verification**: Constant-time comparison via `hmac.compare_digest()` to eliminate timing attack vectors.

---

## 4. Anti-Abuse Safeguards & Rate Limiting

| Safeguard | Limit | Action on Violation |
| :--- | :--- | :--- |
| **Resend Cooldown** | 60 seconds per phone number | HTTP 429 Too Many Requests with remaining seconds |
| **Hourly Rate Limit** | 5 requests per hour per number | HTTP 429 Rate Limit Exceeded |
| **Code Expiration** | 300 seconds (5 minutes) | HTTP 400 Bad Request ("Verification code expired") |
| **Maximum Attempts** | 5 failed attempts per challenge | Challenge marked consumed/locked; HTTP 400 |
| **Replay Prevention** | Single-use atomic consumption | Row locked via `select_for_update()`, marked `is_consumed=True` |
| **Collision Protection** | Unique verified phone enforcement | HTTP 409 Conflict if phone is verified by another user |

---

## 5. REST API Endpoints

### 1. Send OTP
- **URL**: `POST /api/auth/phone/send-otp/`
- **Auth**: AllowAny (optional Bearer token)
- **Request Body**:
  ```json
  {
    "phone": "012 345 678",
    "purpose": "customer_verification"
  }
  ```
- **Response (200 OK)**:
  ```json
  {
    "status": "SUCCESS",
    "message": "Verification code dispatched successfully via SMS.",
    "phone_masked": "+855 12 *** 678",
    "cooldown_seconds": 60,
    "expires_in_seconds": 300,
    "challenge_id": 42
  }
  ```

### 2. Verify OTP
- **URL**: `POST /api/auth/phone/verify-otp/`
- **Auth**: AllowAny (optional Bearer token)
- **Request Body**:
  ```json
  {
    "phone": "012 345 678",
    "otp": "123456",
    "purpose": "customer_verification"
  }
  ```
- **Response (200 OK)**:
  ```json
  {
    "status": "SUCCESS",
    "message": "Phone number verified successfully.",
    "phone_normalized": "+85512345678",
    "is_phone_verified": true,
    "verified_at": "2026-10-22T16:15:00.000Z"
  }
  ```

### 3. Phone Verification Status
- **URL**: `GET /api/auth/phone/status/`
- **Auth**: IsAuthenticated
- **Response (200 OK)**:
  ```json
  {
    "phone": "+85512345678",
    "phone_masked": "+855 12 *** 678",
    "is_phone_verified": true,
    "phone_verified_at": "2026-10-22T16:15:00.000Z",
    "role": "driver",
    "can_change_phone": true
  }
  ```

### 4. Change Phone Number
- **URL**: `POST /api/auth/phone/change/`
- **Auth**: IsAuthenticated
- **Request Body**:
  ```json
  {
    "new_phone": "098 765 432"
  }
  ```

---

## 6. Role-Based Enforcement Policies

### Driver Enforcement
- Unverified drivers calling `POST /api/drivers/orders/<id>/accept/` receive `403 Forbidden` with:
  `{"error": "Verified Cambodian phone number required before accepting delivery assignments."}`
- Updating phone number via `PATCH /api/drivers/me/` automatically resets `is_phone_verified = False` and `phone_verified_at = None`.
- The driver portal (`DriverDashboardScreen`) displays a high-contrast warning banner in the Available Orders tab when unverified, with a direct "Verify Phone via SMS" launcher.

### Customer Enforcement
- Profile screen (`ProfileScreen`) displays verified badges for verified accounts and interactive "Verify SMS" chips for unverified accounts.
- Account settings include a dedicated "Phone Verification (SMS OTP)" management tile.
