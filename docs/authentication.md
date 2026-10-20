# FoodGo Authentication & Authorization Specification

**Version**: 2.0.0  
**Updated**: 2026-10-20  
**Repository**: [https://github.com/Ratanazen/FoodGo](https://github.com/Ratanazen/FoodGo)

---

## 1. Architectural Overview

FoodGo uses a stateless JSON Web Token (JWT) authentication system paired with Django's pluggable authentication backend architecture on the backend and Provider-driven state management with secure hardware-backed storage on the Flutter frontend.

```
+-------------------------------------------------------------+
|                      Flutter Client                         |
|                                                             |
|  [LoginScreen] --------> [AuthProvider]                     |
|         |                      |                            |
|         v                      v                            |
|  [SharedPreferences]     [ApiService]                       |
|  (Remember Me)                 |                            |
|                                v                            |
|                    [ApiClient (Dio Interceptor)]            |
|                                |                            |
|                                v                            |
|                     [FlutterSecureStorage]                  |
|                     (JWT Access & Refresh)                  |
+-------------------------------------------------------------+
                                |
                   HTTPS / JSON (REST API)
                                |
                                v
+-------------------------------------------------------------+
|                   Django 6.1 Backend                        |
|                                                             |
|  [TokenObtainPairView]                                      |
|         |                                                   |
|         v                                                   |
|  [EmailAuthBackend]                                         |
|  (Case-insensitive email & username lookup)                 |
|         |                                                   |
|         v                                                   |
|  [SimpleJWT Framework]                                      |
|  (HMAC-SHA256 Token Signing & Validation)                   |
|         |                                                   |
|         v                                                   |
|  [User Model (Role-Based: admin, driver, owner, customer)]  |
+-------------------------------------------------------------+
```

---

## 2. API Endpoints Contract

### 2.1 Obtain Token Pair (Login)
- **Method**: `POST`
- **Path**: `/api/token/`
- **Auth Required**: None
- **Request Body**:
  ```json
  {
    "username": "customer1",
    "password": "customer123"
  }
  ```
  *Note: The `username` field accepts either the user's username or email address (case-insensitively via `EmailAuthBackend`).*
- **Success Response (200 OK)**:
  ```json
  {
    "access": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
  ```
- **Error Response (401 Unauthorized)**:
  ```json
  {
    "detail": "No active account found with the given credentials"
  }
  ```

### 2.2 Refresh Access Token
- **Method**: `POST`
- **Path**: `/api/token/refresh/`
- **Auth Required**: None
- **Request Body**:
  ```json
  {
    "refresh": "<refresh_token>"
  }
  ```
- **Success Response (200 OK)**:
  ```json
  {
    "access": "<new_access_token>"
  }
  ```

### 2.3 User Profile (`/api/me/`)
- **Method**: `GET`
- **Path**: `/api/me/`
- **Auth Required**: `Bearer <access_token>`
- **Success Response (200 OK)**:
  ```json
  {
    "id": 1,
    "username": "customer1",
    "email": "customer1@foodgo.com",
    "first_name": "Customer",
    "last_name": "One",
    "role": "customer",
    "phone": "+85512345678"
  }
  ```

### 2.4 User Registration
- **Method**: `POST`
- **Path**: `/api/register/`
- **Auth Required**: None
- **Validation Rules**:
  - `username`: Minimum 3 characters, no spaces, unique case-insensitively (`username__iexact`).
  - `email`: Valid email syntax, unique case-insensitively (`email__iexact`).
  - `password`: Minimum 6 characters.
- **Request Body**:
  ```json
  {
    "username": "newcustomer",
    "email": "newcustomer@example.com",
    "password": "securepassword123",
    "first_name": "New",
    "last_name": "Customer",
    "phone": "+85512999888"
  }
  ```
- **Success Response (201 Created)**:
  ```json
  {
    "id": 15,
    "username": "newcustomer",
    "email": "newcustomer@example.com",
    "role": "customer"
  }
  ```

### 2.5 Password Management
- **Forgot Password**: `POST /api/forgot-password/` with `{"email": "user@example.com"}`. Generates secure reset token.
- **Reset Password**: `POST /api/reset-password/` with `{"token": "...", "new_password": "..."}`.
- **Change Password**: `POST /api/change-password/` (Authenticated) with `{"old_password": "...", "new_password": "..."}`.

---

## 3. Token Lifecycle & Storage Architecture

### 3.1 Token Lifetimes
| Token Type | Lifetime | Purpose | Storage Mechanism |
|------------|----------|---------|-------------------|
| **Access Token** | 60 minutes | API authorization header (`Bearer`) | Encrypted KeyStore / Keychain (`FlutterSecureStorage`) |
| **Refresh Token** | 7 days | Rotates access token without re-login | Encrypted KeyStore / Keychain (`FlutterSecureStorage`) |
| **Remembered Identifier** | Indefinite (until uncheck) | Pre-fills username/email input field | Key-Value Store (`SharedPreferences`) |

### 3.2 Automated Token Refresh Interceptor
In `ApiClient` (`foodgo_flutter/lib/core/network/api_client.dart`), Dio interceptors manage token attachment and transparent renewal:
1. Every outgoing HTTP request appends `Authorization: Bearer <access_token>`.
2. On receipt of `401 Unauthorized`:
   - If the failing request is NOT the refresh endpoint itself:
   - The client invokes `POST /api/token/refresh/` using the stored refresh token.
   - Upon successful renewal, the access token in `SecureStorage` is updated.
   - All pending and failed requests are retried seamlessly with the new token.
   - If token refresh fails, stored tokens are cleared and the user is redirected to the login screen.

---

## 4. Role-Based Access Control (RBAC) & Routing

FoodGo supports 4 primary user roles:
1. **`admin` / `staff`**: System administrator with access to metrics, orders, audit logs, and user management.
2. **`driver`**: Delivery partner with access to assigned deliveries, live route status, and payout tracking.
3. **`restaurant_owner`**: Restaurant manager with access to menu management, incoming orders, and revenue reporting.
4. **`customer`**: Standard end-user with access to food browsing, cart, checkout, and QR payment.

### 4.1 Post-Login Redirection Logic
Upon successful authentication in `LoginScreen`:
```dart
final role = userProvider.user?['role']?.toString().toLowerCase();
if (role == 'admin' || role == 'staff') {
  context.go('/admin-dashboard');
} else if (role == 'driver') {
  context.go('/driver-dashboard');
} else if (role == 'restaurant_owner') {
  context.go('/restaurant-dashboard');
} else {
  context.go('/home');
}
```

---

## 5. Security & Session Integrity Best Practices

1. **Zero Mock Credentials**:
   No hardcoded tokens or bypassed authentication exist in frontend code. All authentications execute against the backend server.
2. **Intelligent Localhost Auto-Detection**:
   When developing on Flutter Web (`kIsWeb`) on `localhost` or `127.0.0.1`, requests automatically route to `http://127.0.0.1:8000/api/` matching the local Django Daphne server, avoiding cross-origin confusion or accidental production traffic.
3. **Complete Logout Cleanup**:
   Invoking `AuthProvider.logout()` triggers:
   - `SecureStorage.clearTokens()`: Purges access and refresh tokens.
   - `UserProvider.clearUser()`: Resets cached profile state and role permissions.
4. **Remember Me Privacy**:
   The "Remember Me" feature ONLY saves the username/email identifier in `SharedPreferences` (`saved_login_identifier`). Passwords and auth tokens are never persisted in unencrypted storage.
5. **Sanitized Input & Error Obfuscation**:
   Usernames are sanitized of whitespace and checked case-insensitively. Authentication failure returns generic, user-safe messages without leaking database or stack traces.

---

## 6. Test Suite & Verification Matrix

| Subsystem | Test File | Test Cases | Status |
|-----------|-----------|------------|--------|
| **Backend Authentication** | `backend/core/tests_auth.py` | 15 regression tests: username/email login, invalid credentials (401), registration duplicate validation, token refresh, `/api/me/` role immutability, logout, password change | 15/15 OK (100%) |
| **Backend Core Suite** | `backend/core/tests.py`, `tests_qr.py`, etc. | 80 existing tests covering orders, KHQR payments, driver assignment, audit logs | 80/80 OK (100%) |
| **Frontend Widget & Unit** | `foodgo_flutter/test/admin_test.dart` | 10 tests: Admin tabs, Cart instructions, User role checks, QRPayment KHQR scan & network error SnackBar, LoginScreen branding, form validation, password toggle, inline error banner | 10/10 OK (100%) |
| **Frontend Full Suite** | `foodgo_flutter/test/` | 87 tests covering unit, UI, currency, notification, and search functionality | 87/87 OK (100%) |
