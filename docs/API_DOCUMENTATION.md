# FoodGo API Documentation & Reference

**Version:** 3.0.0-PROD  
**Base URL:** `http://127.0.0.1:8000/api/` (Production: `https://api.foodgo.app/api/`)  
**Auth Header:** `Authorization: Bearer <access_token>`  
**Content-Type:** `application/json`  

---

## 1. Authentication & User Profile

### 1.1 Register Customer
- **Endpoint:** `POST /api/register/`
- **Permissions:** Public
- **Request:**
  ```json
  {
    "username": "channa_sok",
    "email": "channa@example.com",
    "password": "StrongPassword123!",
    "first_name": "Channa",
    "last_name": "Sok",
    "phone": "+85512888999"
  }
  ```
- **Response (201 Created):**
  ```json
  {
    "id": 14,
    "username": "channa_sok",
    "email": "channa@example.com",
    "role": "customer",
    "phone": "+85512888999"
  }
  ```

### 1.2 Obtain JWT Token (Login)
- **Endpoint:** `POST /api/token/`
- **Permissions:** Public
- **Request:**
  ```json
  {
    "username": "channa_sok",
    "password": "StrongPassword123!"
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "access": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
  ```

### 1.3 Current User Profile
- **Endpoint:** `GET /api/me/` or `GET /api/auth/me/`
- **Permissions:** Authenticated
- **Response (200 OK):**
  ```json
  {
    "id": 14,
    "username": "channa_sok",
    "email": "channa@example.com",
    "first_name": "Channa",
    "last_name": "Sok",
    "role": "customer",
    "phone": "+85512888999",
    "phone_normalized": "+85512888999",
    "is_phone_verified": true,
    "phone_verified_at": "2026-10-22T08:30:00Z"
  }
  ```

### 1.4 Request Cambodian SMS OTP
- **Endpoint:** `POST /api/auth/otp/request/` (Alias: `POST /api/auth/phone/send-otp/`)
- **Permissions:** Public
- **Request:**
  ```json
  {
    "phone": "012 888 999",
    "purpose": "customer_verification"
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "status": "SUCCESS",
    "message": "Verification code dispatched successfully via SMS.",
    "phone_masked": "+855 12 *** 999",
    "cooldown_seconds": 60,
    "expires_in_seconds": 300,
    "challenge_id": 42
  }
  ```

### 1.5 Verify SMS OTP
- **Endpoint:** `POST /api/auth/otp/verify/` (Alias: `POST /api/auth/phone/verify-otp/`)
- **Permissions:** Public
- **Request:**
  ```json
  {
    "phone": "012 888 999",
    "otp": "123456",
    "purpose": "customer_verification"
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "status": "SUCCESS",
    "message": "Phone number verified successfully.",
    "phone_normalized": "+85512888999",
    "is_phone_verified": true,
    "verified_at": "2026-10-22T08:31:00Z"
  }
  ```

### 1.6 Refresh JWT Token
- **Endpoint:** `POST /api/auth/refresh/` (Alias: `POST /api/token/refresh/`)
- **Permissions:** Public
- **Request:**
  ```json
  {
    "refresh": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "access": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
  ```

### 1.7 Logout & Revoke Refresh Token
- **Endpoint:** `POST /api/auth/logout/`
- **Permissions:** Authenticated
- **Request:**
  ```json
  {
    "refresh": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "status": "SUCCESS",
    "message": "Successfully logged out."
  }
  ```

---

## 2. Order Management

### 2.1 Create Order (Server-Authoritative Pricing)
- **Endpoint:** `POST /api/orders/`
- **Permissions:** Customer Only
- **Request:**
  ```json
  {
    "restaurant": 1,
    "address": 2,
    "coupon_code": "FOODGO30",
    "special_instructions": "Please leave at gate",
    "items": [
      { "food_item": 5, "quantity": 2 }
    ]
  }
  ```
- **Response (201 Created):**
  ```json
  {
    "id": 42,
    "order_reference": "FG-20261013-A8F12C",
    "restaurant": 1,
    "restaurant_name": "Phnom Penh Kitchen",
    "address": 2,
    "status": "pending",
    "payment_status": "UNPAID",
    "total_amount": "14.20",
    "special_instructions": "Please leave at gate",
    "created_at": "2026-10-13T14:30:00Z",
    "items": [
      {
        "id": 91,
        "food_item": 5,
        "food_item_name": "Beef Lok Lak",
        "quantity": 2,
        "price": "6.50"
      }
    ],
    "assigned_driver": {
      "id": 3,
      "name": "Bob Rider",
      "phone": "+855 12 888 999",
      "vehicle_type": "Motorcycle (Honda Wave)",
      "license_plate": "PP-1AB-2026",
      "is_online": true
    },
    "payment_info": null,
    "delivery_token_info": null
  }
  ```

### 2.2 Live Order Tracking
- **Endpoint:** `GET /api/orders/<id>/tracking/` (or `GET /api/orders/<id>/track/`)
- **Permissions:** Authenticated (Owner, Driver, Staff)
- **Response (200 OK):**
  ```json
  {
    "order_id": 42,
    "status": "on_the_way",
    "restaurant_name": "Phnom Penh Kitchen",
    "delivery_address": "Street 240, Daun Penh, Phnom Penh",
    "restaurant_location": { "lat": 11.5564, "lng": 104.9282 },
    "customer_location": { "lat": 11.5621, "lng": 104.9160 },
    "driver_location": { "lat": 11.5590, "lng": 104.9220 },
    "driver": {
      "id": 3,
      "name": "Bob Rider",
      "phone": "+855 12 888 999",
      "vehicle_type": "Motorcycle (Honda Wave 125i)",
      "license_plate": "PP-1AB-2026",
      "rating": 4.9
    }
  }
  ```

### 2.3 Driver Arrival Notification
- **Endpoint:** `POST /api/orders/<id>/delivery_arrive/` (or `POST /api/orders/<id>/delivery/arrive/`)
- **Permissions:** Assigned Driver or Staff
- **Response (200 OK):**
  ```json
  {
    "status": "SUCCESS",
    "message": "Driver arrival recorded.",
    "order_id": 42,
    "delivery_status": "arrived",
    "order_status": "driver_arrived",
    "arrived_at": "2026-10-13T14:45:00Z"
  }
  ```

---

## 3. Delivery Confirmation QR & PIN

### 3.1 Generate / Retrieve Delivery Handover QR
- **Endpoint:** `POST /api/orders/<id>/delivery_qr/` (or `POST /api/orders/<id>/delivery/qr/`)
- **Permissions:** Assigned Driver or Staff Only
- **Response (200 OK):**
  ```json
  {
    "order_id": 42,
    "token": "x8K_mQ92LpZ-38sA91Bw77rT10yU99qW",
    "verification_pin": "592817",
    "qr_payload": "FOODGO:DELIVERY:CONFIRM:v1?order_id=42&token=x8K_mQ92LpZ-38sA91Bw77rT10yU99qW",
    "expires_at": "2026-10-13T15:00:00Z",
    "driver_name": "Bob Rider",
    "vehicle_type": "Motorcycle (Honda Wave)",
    "license_plate": "PP-1AB-2026",
    "status": "arrived"
  }
  ```

### 3.2 Confirm Delivery (Customer or Assigned Driver)
- **Endpoint:** `POST /api/orders/<id>/confirm_delivery/` (or `POST /api/orders/<id>/delivery/confirm/`)
- **Permissions:** Order Customer or Assigned Driver
- **Request (via QR Token):**
  ```json
  {
    "token": "x8K_mQ92LpZ-38sA91Bw77rT10yU99qW"
  }
  ```
  *OR (via 6-digit backup PIN):*
  ```json
  {
    "verification_pin": "592817"
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "status": "SUCCESS",
    "message": "Delivery confirmed successfully!",
    "order_id": 42,
    "order_status": "delivered",
    "delivery_time": "2026-10-13T14:47:32Z",
    "driver_name": "Bob Rider",
    "confirmed_by": "channa_sok"
  }
  ```

### 3.3 Support Manual Clearance Override
- **Endpoint:** `POST /api/orders/<id>/support_confirm_delivery/`
- **Permissions:** Staff / Admin Only
- **Request:**
  ```json
  {
    "reason": "Customer phone battery depleted at delivery point"
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "status": "SUCCESS",
    "message": "Order delivery confirmed via support override.",
    "order_id": 42,
    "delivery_time": "2026-10-13T14:50:00Z"
  }
  ```

---

## 4. Cambodian Bank Payments & KHQR

### 4.1 Create Payment Intent
- **Endpoint:** `POST /api/payments/create/` (or `POST /api/payments/`)
- **Permissions:** Authenticated Order Owner
- **Request:**
  ```json
  {
    "order_id": 42,
    "provider": "BAKONG",
    "currency": "USD"
  }
  ```
  *(Supported providers: `BAKONG`, `ABA`, `ACLEDA`, `WALLET`, `COD`)*
- **Response (201 Created):**
  ```json
  {
    "id": 105,
    "order": 42,
    "provider": "BAKONG",
    "method": "KHQR",
    "transaction_id": "TXN-BAKONG-42-1728830000",
    "merchant_reference": "FG-BAKONG-42-1728830000",
    "amount": "14.20",
    "currency": "USD",
    "status": "PENDING",
    "qr_payload": "00020101021229340014foodgo@acleda0108USD4100520458125303840540514.205802KH5911FoodGo Corp6010Phnom Penh62190115FG-BAKONG-426304E8A2",
    "qr_image": null,
    "expires_at": "2026-10-13T14:35:00Z",
    "created_at": "2026-10-13T14:30:00Z"
  }
  ```

### 4.2 Poll / Verify Payment Status
- **Endpoint:** `POST /api/payments/<id>/status/` (or `POST /api/payments/<id>/verify/`)
- **Permissions:** Owner or Staff
- **Response (200 OK):**
  ```json
  {
    "id": 105,
    "order_id": 42,
    "provider": "BAKONG",
    "status": "PAID",
    "amount": "14.20",
    "currency": "USD",
    "merchant_reference": "FG-BAKONG-42-1728830000",
    "paid_at": "2026-10-13T14:32:15Z"
  }
  ```

### 4.3 Inbound Webhooks
- **Endpoints:**
  - `POST /api/payments/aba/callback/` (or `/api/payments/webhooks/aba/`)
  - `POST /api/payments/acleda/callback/` (or `/api/payments/webhooks/acleda/`)
  - `POST /api/payments/bakong/callback/` (or `/api/payments/webhooks/bakong/`)
- **Permissions:** Public / Gateway Webhook (Verified by HMAC signature or `PAYMENT_WEBHOOK_SECRET`)
- **Response (200 OK):**
  ```json
  {
    "status": "SUCCESS",
    "message": "Payment verified and order updated",
    "order_id": 42,
    "payment_id": 105
  }
  ```

---

## 5. Public Order Tracking

### 5.1 Public Live Tracking Lookup
- **Endpoint:** `GET /api/orders/<id>/tracking/`
- **Permissions:** Public (`AllowAny`)
- **Response (200 OK):**
  ```json
  {
    "order_id": 42,
    "status": "on_the_way",
    "restaurant_name": "Phnom Penh Kitchen",
    "delivery_address": "Street 240, Daun Penh, Phnom Penh",
    "restaurant_location": {
      "lat": 11.5564,
      "lng": 104.9282
    },
    "customer_location": {
      "lat": 11.5621,
      "lng": 104.9160
    },
    "driver_location": {
      "lat": 11.5589,
      "lng": 104.9227
    },
    "driver": {
      "id": 7,
      "name": "Dara Chan",
      "phone": "+85512888999",
      "vehicle_type": "Motorcycle (Honda Wave)",
      "license_plate": "PP-1AB-2026",
      "is_online": true,
      "rating": 4.9
    }
  }
  ```

---

## 6. Android Emulator & Network Security Configuration

Android API 28+ blocks cleartext HTTP traffic by default. FoodGo includes a configured `network_security_config.xml` to allow cleartext communication between Android emulators and local development hosts.

### 6.1 Network Security Config File
Location: `foodgo_flutter/android/app/src/main/res/xml/network_security_config.xml`
```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="true">10.0.2.2</domain>
        <domain includeSubdomains="true">127.0.0.1</domain>
        <domain includeSubdomains="true">localhost</domain>
    </domain-config>
    <base-config cleartextTrafficPermitted="false">
        <trust-anchors>
            <certificates src="system" />
            <certificates src="user" />
        </trust-anchors>
    </base-config>
</network-security-config>
```

### 6.2 AndroidManifest.xml Integration
The configuration is linked in `foodgo_flutter/android/app/src/main/AndroidManifest.xml`:
```xml
<application
    android:label="FoodGo"
    android:name="${applicationName}"
    android:icon="@mipmap/launcher_icon"
    android:networkSecurityConfig="@xml/network_security_config">
```

### 6.3 Local Development Target URLs
- **Web:** `http://127.0.0.1:8000/api/` (Auto-detected when host is `localhost` or `127.0.0.1`)
- **Android Emulator:** `http://10.0.2.2:8000/api/` (Selectable from the login screen Server Dialog)
- **Production:** `https://food-go-app.vercel.app/api/`
