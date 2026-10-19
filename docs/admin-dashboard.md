# FoodGo Administrator Console & API Documentation

## Overview

The FoodGo Admin Console is a complete operations center built for platform administrators and dispatch supervisors. It provides real-time oversight of orders, drivers, customers, restaurants, revenue metrics, and system security.

---

## Authentication & Authorization

All Admin endpoints require Bearer JWT authentication and staff authorization:
- Header: `Authorization: Bearer <access_token>`
- Permission: `IsAdminOrStaff` (verifies `user.is_staff` or `user.role in ['admin', 'staff']`)
- Anonymous or non-privileged requests receive HTTP 403 Forbidden.

---

## REST API Specification

### 1. Analytics & Health
- **Endpoint**: `GET /api/admin/analytics/?period={today|week|month|all}`
- **Description**: Returns order counts, total gross volume in USD and approximate KHR (rate: 4,100 KHR/USD), active delivery couriers, customer count, and ASGI database connection health.
- **Response Example**:
```json
{
  "period": "today",
  "total_orders": 38,
  "completed_orders": 31,
  "total_revenue_usd": 684.50,
  "total_revenue_khr": 2806450,
  "active_drivers_count": 8,
  "active_customers_count": 142,
  "system_health": {
    "database": "healthy",
    "asgi": "active"
  }
}
```

### 2. Order Management
- **List & Search**: `GET /api/admin/orders/?status={status}&search={query}`
  - Status filters: `all`, `pending`, `confirmed`, `preparing`, `on_the_way`, `delivered`, `cancelled`.
  - Search query searches order IDs, customer usernames, and restaurant names.
- **Assign Driver**: `POST /api/admin/orders/{id}/assign_driver/`
  - Payload: `{"driver_id": 12}`
  - Automatically transitions order status to `confirmed` (if pending) and logs an immutable `ASSIGN_DRIVER` record in `AuditLog`.
- **Cancel Order**: `POST /api/admin/orders/{id}/cancel_order/`
  - Payload: `{"reason": "Customer requested cancellation prior to prep"}`
  - Sets order status to `cancelled` and records an immutable `CANCEL_ORDER` entry.

### 3. User Directory
- **List & Search**: `GET /api/admin/users/?role={role}&search={query}`
  - Role filters: `all`, `customer`, `driver`, `restaurant_owner`, `admin`.
- **Toggle User Status**: `POST /api/admin/users/{id}/toggle_status/`
  - Toggles `is_active` boolean on the target user account and records an immutable `TOGGLE_USER_ACTIVE` entry.

### 4. Restaurant Directory
- **List & Search**: `GET /api/admin/restaurants/?search={query}`
- **Toggle Restaurant Status**: `POST /api/admin/restaurants/{id}/toggle_status/`
  - Toggles `is_active` boolean and records a `TOGGLE_RESTAURANT` entry.

### 5. Audit Trail
- **Endpoint**: `GET /api/admin/audit-logs/?page={page}`
- **Description**: Read-only chronological stream of administrative events containing:
  - `action`: Type of action performed.
  - `actor_username`: Admin who triggered the action.
  - `target_model` & `target_id`: Affected entity.
  - `changes`: JSON delta of attributes before and after.
  - `ip_address`: Remote client IP address.
  - `created_at`: UTC timestamp.

---

## Flutter Admin Dashboard Architecture

The frontend implementation resides in `foodgo_flutter/lib/features/admin/presentation/admin_dashboard_screen.dart` and is managed by `AdminProvider` (`foodgo_flutter/lib/providers/admin_provider.dart`).

### Five Primary Navigation Tabs
1. **Overview & Analytics**:
   - 4 Metric KPI Cards: Total Orders, Revenue (USD & KHR dual display), Active Couriers, and Registered Customers.
   - Live System Status Card (Database connection check).
   - Order Status Pipeline breakdown chips.
   - Filter chips for timeframe analysis (`Today`, `7 Days`, `30 Days`, `All Time`).
2. **Orders Tab**:
   - Live search input field with debounce.
   - Status filter chips.
   - Order cards displaying order items, customer details, delivery address, driver assignment dialog, and cancel order modal.
3. **Users Tab**:
   - Role filter chips (`All`, `Customers`, `Drivers`, `Owners`, `Admins`).
   - Active/Inactive toggle switch per user row.
4. **Restaurants Tab**:
   - Search filter for restaurant names.
   - Active toggle switch, delivery fee, and rating inspection.
5. **Audit Logs Tab**:
   - Chronological list of administrative modifications with action badges and actor attribution.

