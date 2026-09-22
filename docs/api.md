# 📡 FoodGo REST API Documentation

Base URL: `http://127.0.0.1:8000/api/`

## Authentication
| Method | Endpoint | Description | Auth Required |
| :--- | :--- | :--- | :--- |
| `POST` | `register/` | Register new customer account | No |
| `POST` | `token/` | Obtain JWT Access and Refresh tokens | No |
| `POST` | `token/refresh/` | Refresh JWT access token | No |
| `POST` | `auth/phone-login/request/` | Request OTP code for phone | No |
| `POST` | `auth/phone-login/verify/` | Verify OTP code and return JWT tokens | No |
| `GET` | `me/` | Fetch authenticated user profile & role | Yes |

## Restaurants & Foods
| Method | Endpoint | Description | Auth Required |
| :--- | :--- | :--- | :--- |
| `GET` | `restaurants/` | List all active restaurants | No |
| `GET` | `restaurants/{id}/` | Get restaurant detail with categories & food items | No |
| `GET` | `restaurants/my_restaurant/` | Get restaurant for authenticated owner | Yes (Owner) |
| `GET` | `food-items/` | List all available food items | No |
| `GET` | `food-categories/` | List all food categories | No |
| `GET` | `recommendations/for_you/` | Collaborative filtering recommendations | Yes |

## Cart & Orders
| Method | Endpoint | Description | Auth Required |
| :--- | :--- | :--- | :--- |
| `GET` | `carts/` | Get user active cart | Yes |
| `POST` | `cart-items/` | Add item to cart | Yes |
| `DELETE` | `cart-items/{id}/` | Remove item from cart | Yes |
| `GET` | `orders/` | List orders for customer or restaurant owner | Yes |
| `POST` | `orders/` | Place order (calculated server-side) | Yes |
| `GET` | `orders/{id}/` | Get single order detail | Yes |
| `PATCH` | `orders/{id}/` | Update status (Owner/Driver only) | Yes |

## Payments & KHQR
| Method | Endpoint | Description | Auth Required |
| :--- | :--- | :--- | :--- |
| `POST` | `payments/create/` | Create payment intent & dynamic KHQR payload | Yes |
| `GET` | `payments/{id}/` | Get payment detail | Yes |
| `POST` | `payments/{id}/status/` | Inquire payment status | Yes |
| `POST` | `payments/{id}/cancel/` | Cancel pending payment attempt | Yes |
| `POST` | `payments/aba/callback/` | Webhook callback for ABA PayWay | No (Signed) |
| `POST` | `payments/acleda/callback/` | Webhook callback for ACLEDA Bank | No (Signed) |

## WebSockets
- `ws://127.0.0.1:8000/ws/tracking/<order_id>/`: Real-time driver location stream.
