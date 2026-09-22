# 🚴 Driver & Delivery System

## Driver Roles
- Drivers toggle their operational status via `DriverDashboardScreen`.
- Database tracks: `is_online`, `current_lat`, `current_lng`, `vehicle_type`, `license_plate`.

## Real-Time Tracking
- Driver GPS coordinates broadcast over WebSockets to room `order_<order_id>`.
- Daphne routes payloads directly to subscribed customers without polling overhead.
