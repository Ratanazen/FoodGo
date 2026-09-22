# 🏛️ FoodGo Architecture Document

## High-Level Topology

```
+-------------------------------------------------------------+
|                      FLUTTER CLIENT                         |
|   (Mobile & Web with 450px Max-Width Responsive Shell)      |
|  - Providers: Auth, Cart, Restaurant, User, Theme           |
|  - Storage: flutter_secure_storage                          |
|  - Routing: GoRouter with Authentication Guards             |
+-------------------------------------------------------------+
                              │ HTTP / JSON
                              │ WebSockets (ws://)
                              ▼
+-------------------------------------------------------------+
|                  ASGI APPLICATION SERVER                    |
|                (Django 6.1 + Daphne + Channels)             |
+-------------------------------------------------------------+
       │                      │                      │
       ▼                      ▼                      ▼
+--------------+      +--------------+      +-----------------+
|  PostgreSQL  |      | Redis Cache  |      | Payment Gateway |
|  Database    |      | & Channel    |      | - ABA KHQR      |
|  (Data Store)|      | Layer        |      | - ACLEDA KHQR   |
+--------------+      +--------------+      | - Cash on Del.  |
                                            +-----------------+
```

## Frontend Layers
1. **Core:**
   - `network/`: Dio HTTP client with automatic Authorization token attachment and 401 handling.
   - `storage/`: Encrypted keystore/keychain access via `flutter_secure_storage`.
   - `theme/`: Material 3 with customizable Glassmorphic dark/light styles.
2. **Features:**
   - Modular structure: `auth/`, `home/`, `search/`, `restaurants/`, `cart/`, `checkout/`, `payment/`, `orders/`, `profile/`, `dashboard/`.
3. **Providers:**
   - Centralized change-notifiers managing state reactively without unnecessary widget rebuilds.

## Backend Layers
1. **API Router & ViewSets:** Django REST Framework ViewSets handling permissions, validation, and serialization.
2. **Payment Service:** Abstract provider architecture (`backend/core/payments/`) separating provider-specific KHQR logic from core business logic.
3. **Real-Time Consumer:** Daphne ASGI server handling WebSocket streams at `/ws/tracking/<order_id>/` for live driver location broadcasts.
