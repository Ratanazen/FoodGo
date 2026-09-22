# 🔔 Notifications Architecture

## System Events
1. Order Confirmed
2. Order Preparing
3. Driver Picked Up
4. Order Delivered
5. Payment Succeeded / Failed

## Notification Delivery
- Persistent database records stored in `Notification` model.
- Flutter UI displays badge count in AppBar and interactive notifications screen.
- FCM (Firebase Cloud Messaging) stubbed and configurable via environment credentials.
