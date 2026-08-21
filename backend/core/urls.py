from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import *

router = DefaultRouter()
router.register(r'restaurants', RestaurantViewSet)
router.register(r'food-categories', FoodCategoryViewSet)
router.register(r'food-items', FoodItemViewSet)
router.register(r'orders', OrderViewSet)

urlpatterns = [
    path('', include(router.urls)),
]
