# 🔐 Authentication Architecture

FoodGo employs a dual-authentication strategy:

1. **Standard JWT (JSON Web Tokens):**
   - Access token lifespan: 60 minutes
   - Refresh token lifespan: 7 days
   - Client storage: `flutter_secure_storage` (encrypted)
   - Interceptors in `ApiClient` automatically inject Bearer headers and capture 401 Unauthorized errors.

2. **Mobile OTP (One-Time Password):**
   - User enters phone number.
   - Server generates a 4-digit code (mocked as `1234` in development).
   - Upon verification, user is authenticated and issued JWT tokens.

3. **Startup Flow Routing:**
   - App launches on `SplashScreen`.
   - Checks `AuthProvider.isAuthenticated`.
   - Active tokens route immediately to `/home`.
   - New or expired sessions route to `/login`.
