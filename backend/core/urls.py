from .auth_views import RequestOTPView, VerifyOTPView, GoogleLoginView, ChangePasswordView, LogoutView, DeleteAccountView
from .payment_views import (
    CreatePaymentView, PaymentDetailView, PaymentStatusView,
    CancelPaymentView, RefundPaymentView, ABACallbackView, ACLEDACallbackView, BakongCallbackView
)
from .admin_views import (
    AdminAnalyticsView, AdminOrderViewSet, AdminUserViewSet,
    AdminRestaurantViewSet, AdminAuditLogViewSet
)
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import *

router = DefaultRouter()
router.register(r'restaurants', RestaurantViewSet)
router.register(r'restaurant-categories', RestaurantCategoryViewSet)
router.register(r'food-categories', FoodCategoryViewSet)
router.register(r'food-items', FoodItemViewSet)
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
router.register(r'admin/users', AdminUserViewSet, basename='admin-users')
router.register(r'admin/restaurants', AdminRestaurantViewSet, basename='admin-restaurants')
router.register(r'admin/audit-logs', AdminAuditLogViewSet, basename='admin-audit-logs')

urlpatterns = [
    path('auth/phone-login/request/', RequestOTPView.as_view(), name='otp_request'),
    path('auth/phone-login/verify/', VerifyOTPView.as_view(), name='otp_verify'),
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
]
