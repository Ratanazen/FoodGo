from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated, AllowAny
from .models import *
from .serializers import *

class RestaurantViewSet(viewsets.ModelViewSet):
    queryset = Restaurant.objects.all()
    serializer_class = RestaurantSerializer
    permission_classes = [AllowAny]

class FoodCategoryViewSet(viewsets.ModelViewSet):
    queryset = FoodCategory.objects.all()
    serializer_class = FoodCategorySerializer
    permission_classes = [AllowAny]

class FoodItemViewSet(viewsets.ModelViewSet):
    queryset = FoodItem.objects.all()
    serializer_class = FoodItemSerializer
    permission_classes = [AllowAny]

class OrderViewSet(viewsets.ModelViewSet):
    queryset = Order.objects.all()
    serializer_class = OrderSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        if user.role == 'customer':
            return Order.objects.filter(customer=user)
        elif user.role == 'restaurant_owner':
            return Order.objects.filter(restaurant__owner=user)
        return Order.objects.all()
