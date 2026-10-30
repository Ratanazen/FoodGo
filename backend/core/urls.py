from .auth_views import RequestOTPView, VerifyOTPView, GoogleLoginView, ChangePasswordView, LogoutView, DeleteAccountView
from .phone_views import (
    SendPhoneOTPView,
    VerifyPhoneOTPView,
    PhoneStatusView,
    ChangePhoneView,
)
from .payment_views import (
    CreatePaymentView, PaymentDetailView, PaymentStatusView,
    CancelPaymentView, RefundPaymentView, ABACallbackView, ACLEDACallbackView, BakongCallbackView
)
from .admin_views import (
    AdminAnalyticsView, AdminOrderViewSet, AdminUserViewSet,
    AdminRestaurantViewSet, AdminAuditLogViewSet, AdminPaymentViewSet,
    AdminDriverViewSet
)
from django.urls import path, include
from rest_framework_simplejwt.views import TokenRefreshView
from rest_framework.routers import DefaultRouter
from .views import *

router = DefaultRouter()
router.register(r'restaurants', RestaurantViewSet)
router.register(r'restaurant-categories', RestaurantCategoryViewSet)
router.register(r'food-categories', FoodCategoryViewSet)
router.register(r'categories', FoodCategoryViewSet, basename='categories')
router.register(r'food-items', FoodItemViewSet)
router.register(r'foods', FoodItemViewSet, basename='foods')
router.register(r'orders', OrderViewSet)
router.register(r'wallets', WalletViewSet, basename='wallet')
router.register(r'reviews', ReviewViewSet)
router.register(r'recommendations', RecommendationViewSet, basename='recommendation')
router.register(r'notifications', NotificationViewSet, basename='notification')
router.register(r'favorites', FavoriteViewSet, basename='favorite')
router.register(r'coupons', CouponViewSet, basename='coupon')
router.register(r'carts', CartViewSet)
router.register(r'cart-items', CartItemViewSet)
router.register(r'live-items', LiveItemViewSet)
router.register(r'drivers', DriverViewSet, basename='driver')
router.register(r'addresses', AddressViewSet, basename='address')
router.register(r'admin/orders', AdminOrderViewSet, basename='admin-orders')
router.register(r'admin/payments', AdminPaymentViewSet, basename='admin-payments')
router.register(r'admin/users', AdminUserViewSet, basename='admin-users')
router.register(r'admin/restaurants', AdminRestaurantViewSet, basename='admin-restaurants')
router.register(r'admin/audit-logs', AdminAuditLogViewSet, basename='admin-audit-logs')
router.register(r'admin/drivers', AdminDriverViewSet, basename='admin-drivers')

urlpatterns = [
    # Phone Verification & OTP Endpoints (Cambodian SMS)
    path('auth/phone/send-otp/', SendPhoneOTPView.as_view(), name='phone_send_otp'),
    path('auth/phone/verify-otp/', VerifyPhoneOTPView.as_view(), name='phone_verify_otp'),
    path('auth/phone/status/', PhoneStatusView.as_view(), name='phone_status'),
    path('auth/phone/change/', ChangePhoneView.as_view(), name='phone_change'),
    # Aliases for phone login and standard OTP endpoints
    path('auth/phone-login/request/', SendPhoneOTPView.as_view(), name='otp_request'),
    path('auth/phone-login/verify/', VerifyPhoneOTPView.as_view(), name='otp_verify'),
    path('auth/otp/request/', SendPhoneOTPView.as_view(), name='auth_otp_request'),
    path('auth/otp/verify/', VerifyPhoneOTPView.as_view(), name='auth_otp_verify'),
    path('auth/refresh/', TokenRefreshView.as_view(), name='auth_refresh'),
    path('auth/me/', UserMeView.as_view(), name='auth_me'),
    path('auth/google/', GoogleLoginView.as_view(), name='google_login'),
    path('auth/change-password/', ChangePasswordView.as_view(), name='change_password'),
    path('auth/logout/', LogoutView.as_view(), name='auth_logout'),
    path('auth/delete-account/', DeleteAccountView.as_view(), name='delete_account'),
    path('', include(router.urls)),
    path('register/', UserRegistrationView.as_view(), name='register'),
    path('me/', UserMeView.as_view(), name='user-me'),
    path('admin/analytics/', AdminAnalyticsView.as_view(), name='admin_analytics'),
    path('forgot-password/', ForgotPasswordView.as_view(), name='forgot_password'),
    # Real KHQR & COD Payment Endpoints
    path('payments/', CreatePaymentView.as_view(), name='payment_create_root'),
    path('payments/create/', CreatePaymentView.as_view(), name='payment_create'),
    path('payments/<int:pk>/', PaymentDetailView.as_view(), name='payment_detail'),
    path('payments/<int:pk>/status/', PaymentStatusView.as_view(), name='payment_status'),
    path('payments/<int:pk>/verify/', PaymentStatusView.as_view(), name='payment_verify'),
    path('payments/<int:pk>/cancel/', CancelPaymentView.as_view(), name='payment_cancel'),
    path('payments/<int:pk>/refund/', RefundPaymentView.as_view(), name='payment_refund'),
    path('payments/aba/callback/', ABACallbackView.as_view(), name='payment_aba_callback'),
    path('payments/acleda/callback/', ACLEDACallbackView.as_view(), name='payment_acleda_callback'),
    path('payments/bakong/callback/', BakongCallbackView.as_view(), name='payment_bakong_callback'),
    path('payments/webhooks/aba/', ABACallbackView.as_view(), name='payment_webhook_aba'),
    path('payments/webhooks/acleda/', ACLEDACallbackView.as_view(), name='payment_webhook_acleda'),
    path('payments/webhooks/bakong/', BakongCallbackView.as_view(), name='payment_webhook_bakong'),
    # Explicit Order Delivery QR & Tracking Path Aliases
    path('orders/<int:pk>/tracking/', OrderViewSet.as_view({'get': 'track'}), name='order_tracking_alias'),
    path('orders/<int:pk>/delivery/arrive/', OrderViewSet.as_view({'post': 'delivery_arrive'}), name='order_delivery_arrive_alias'),
    path('orders/<int:pk>/delivery/qr/', OrderViewSet.as_view({'post': 'delivery_qr'}), name='order_delivery_qr_alias'),
    path('orders/<int:pk>/delivery/confirm/', OrderViewSet.as_view({'post': 'confirm_delivery'}), name='order_delivery_confirm_alias'),
    path('orders/<int:pk>/customer_delivery_qr/', OrderViewSet.as_view({'get': 'customer_delivery_qr', 'post': 'customer_delivery_qr'}), name='order_customer_delivery_qr_alias'),
    path('orders/<int:pk>/customer_regenerate_delivery_qr/', OrderViewSet.as_view({'post': 'customer_regenerate_delivery_qr'}), name='order_customer_regenerate_delivery_qr_alias'),
    path('orders/<int:pk>/driver_validate_qr/', OrderViewSet.as_view({'post': 'driver_validate_qr'}), name='order_driver_validate_qr_alias'),
    # Multi-Currency NBC Exchange Rate Endpoint
    path('currency/rates/', CurrencyRateView.as_view(), name='currency_rates'),
    # Multi-Cloud Uptime & Telemetry Health Checks
    path('health', HealthCheckView.as_view(), name='api_health_check_no_slash'),
    path('health/', HealthCheckView.as_view(), name='api_health_check'),
    path('health/mongodb', MongoHealthCheckView.as_view(), name='api_health_mongodb_no_slash'),
    path('health/mongodb/', MongoHealthCheckView.as_view(), name='api_health_mongodb'),
    path('health/live', HealthLiveView.as_view(), name='api_health_live_no_slash'),
    path('health/live/', HealthLiveView.as_view(), name='api_health_live'),
    path('health/ready', HealthReadyView.as_view(), name='api_health_ready_no_slash'),
    path('health/ready/', HealthReadyView.as_view(), name='api_health_ready'),
    path('healthz', HealthCheckView.as_view(), name='api_healthz_no_slash'),
    path('healthz/', HealthCheckView.as_view(), name='api_healthz'),
    # MongoDB Atlas Media & Sync Services
    path('media/mongo/upload/', MongoImageUploadView.as_view(), name='mongo_image_upload'),
    path('media/mongo/<path:filename>', MongoImageView.as_view(), name='mongo_image_serve'),
    path('mongodb/stats/', MongoHealthCheckView.as_view(), name='mongo_stats'),
    path('mongodb/sync/', MongoSyncView.as_view(), name='mongo_sync'),
]
