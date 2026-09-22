from .auth_views import RequestOTPView, VerifyOTPView
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import *

router = DefaultRouter()
router.register(r'restaurants', RestaurantViewSet)
router.register(r'food-categories', FoodCategoryViewSet)
router.register(r'food-items', FoodItemViewSet)
router.register(r'orders', OrderViewSet)
router.register(r'wallets', WalletViewSet, basename='wallet')
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
]
