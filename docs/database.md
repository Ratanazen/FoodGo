# 🗄️ Database Schema & Models

Production Database: **PostgreSQL 15**  
Local / Fallback: **SQLite 3**

## Core Models

### 1. User
- `username`, `email`, `password`, `first_name`, `last_name`, `phone`
- `role`: `['customer', 'restaurant_owner', 'driver', 'admin']`

### 2. Restaurant
- `owner`: FK(User)
- `name`, `address`, `phone`, `delivery_time_min`, `delivery_time_max`, `delivery_fee`, `rating`, `is_active`
- `lat`, `lng`: Decimal coordinates

### 3. FoodItem
- `category`: FK(FoodCategory)
- `name`, `description`, `price`, `image`, `is_available`, `ingredients`

### 4. Order
- `customer`: FK(User)
- `restaurant`: FK(Restaurant)
- `address`: FK(Address)
- `status`: `['pending', 'confirmed', 'preparing', 'ready', 'picked_up', 'on_the_way', 'delivered', 'cancelled']`
- `payment_status`: `['UNPAID', 'PENDING', 'PAID', 'FAILED', 'REFUNDED']`
- `total_amount`: Decimal(10, 2)

### 5. Payment
- `order`: OneToOne(Order)
- `provider`: `['ABA', 'ACLEDA', 'COD']`
- `method`: `['KHQR', 'COD']`
- `merchant_reference`: Unique string (`FG-ABA-<order>-<ts>`)
- `transaction_id`: Unique string
- `amount`: Decimal(10, 2)
- `currency`: `['USD', 'KHR']`
- `qr_payload`: NBC / Bank-compliant dynamic string
- `status`: `['PENDING', 'PROCESSING', 'PAID', 'FAILED', 'EXPIRED', 'CANCELLED', 'REFUNDED']`
- `expires_at`, `paid_at`, `provider_response`

### 6. Wallet & WalletTransaction
- `user`: OneToOne(User)
- `balance`: Decimal(10, 2)
- `transactions`: FK(WalletTransaction) with types `['deposit', 'withdrawal', 'payment', 'refund']`
