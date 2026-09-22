from .auth_views import RequestOTPView, VerifyOTPView
from .payment_views import (
    CreatePaymentView, PaymentDetailView, PaymentStatusView,
    CancelPaymentView, ABACallbackView, ACLEDACallbackView
)
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import *

router = DefaultRouter()
router.register(r'restaurants', RestaurantViewSet)
router.register(r'food-categories', FoodCategoryViewSet)
router.register(r'food-items', FoodItemViewSet)
router.register(r'orders', OrderViewSet)
router.register(r'wallets', WalletViewSet, basename='wallet')
router.register(r'reviews', ReviewViewSet)
router.register(r'recommendations', RecommendationViewSet, basename='recommendation')
router.register(r'carts', CartViewSet)
router.register(r'cart-items', CartItemViewSet)
router.register(r'live-items', LiveItemViewSet)
urlpatterns = [
    path('auth/phone-login/request/', RequestOTPView.as_view(), name='otp_request'),
    path('auth/phone-login/verify/', VerifyOTPView.as_view(), name='otp_verify'),
    path('', include(router.urls)),
    path('register/', UserRegistrationView.as_view(), name='register'),
    path('me/', UserMeView.as_view(), name='user-me'),
    path('forgot-password/', ForgotPasswordView.as_view(), name='forgot_password'),
    # Real KHQR & COD Payment Endpoints
    path('payments/create/', CreatePaymentView.as_view(), name='payment_create'),
    path('payments/<int:pk>/', PaymentDetailView.as_view(), name='payment_detail'),
    path('payments/<int:pk>/status/', PaymentStatusView.as_view(), name='payment_status'),
    path('payments/<int:pk>/cancel/', CancelPaymentView.as_view(), name='payment_cancel'),
    path('payments/aba/callback/', ABACallbackView.as_view(), name='payment_aba_callback'),
    path('payments/acleda/callback/', ACLEDACallbackView.as_view(), name='payment_acleda_callback'),
]
