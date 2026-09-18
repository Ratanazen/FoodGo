from rest_framework.decorators import action
from decimal import Decimal

from django.db import transaction
from rest_framework import viewsets
from rest_framework.exceptions import PermissionDenied, ValidationError
from rest_framework.permissions import IsAuthenticated, AllowAny, IsAuthenticatedOrReadOnly
from .models import *
from .serializers import *

class RestaurantViewSet(viewsets.ModelViewSet):
    queryset = Restaurant.objects.all()
    serializer_class = RestaurantSerializer
    permission_classes = [IsAuthenticatedOrReadOnly]

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)

    def get_queryset(self):
        queryset = Restaurant.objects.select_related('category').prefetch_related('food_categories')
        if self.request.user.is_staff:
            return queryset
        if self.request.method in ('PUT', 'PATCH', 'DELETE'):
            return queryset.filter(owner=self.request.user)
        return queryset.filter(is_active=True)

class FoodCategoryViewSet(viewsets.ModelViewSet):
    queryset = FoodCategory.objects.all()
    serializer_class = FoodCategorySerializer
    permission_classes = [IsAuthenticatedOrReadOnly]

    def get_queryset(self):
        queryset = FoodCategory.objects.select_related('restaurant')
        if self.request.method in ('PUT', 'PATCH', 'DELETE') and not self.request.user.is_staff:
            return queryset.filter(restaurant__owner=self.request.user)
        return queryset

    def perform_create(self, serializer):
        restaurant = serializer.validated_data['restaurant']
        if not self.request.user.is_staff and restaurant.owner_id != self.request.user.id:
            raise PermissionDenied('You can only manage your own restaurant.')
        serializer.save()

class FoodItemViewSet(viewsets.ModelViewSet):
    queryset = FoodItem.objects.all()
    serializer_class = FoodItemSerializer
    permission_classes = [IsAuthenticatedOrReadOnly]

    def get_queryset(self):
        queryset = FoodItem.objects.select_related('category', 'category__restaurant')
        if self.request.method in ('PUT', 'PATCH', 'DELETE') and not self.request.user.is_staff:
            return queryset.filter(category__restaurant__owner=self.request.user)
        return queryset.filter(is_available=True) if self.request.method == 'GET' else queryset

    def perform_create(self, serializer):
        category = serializer.validated_data['category']
        if not self.request.user.is_staff and category.restaurant.owner_id != self.request.user.id:
            raise PermissionDenied('You can only manage food for your own restaurant.')
        serializer.save()

class OrderViewSet(viewsets.ModelViewSet):
    queryset = Order.objects.all()
    serializer_class = OrderSerializer
    permission_classes = [IsAuthenticated]
    def get_queryset(self):
        user = self.request.user
        if user.role == 'customer' and not user.is_staff:
            return Order.objects.filter(customer=user).select_related('restaurant', 'address').prefetch_related('items')
        elif user.role == 'restaurant_owner':
            return Order.objects.filter(restaurant__owner=user)
        return Order.objects.all()

    @transaction.atomic
    def perform_create(self, serializer):
        user = self.request.user
        if user.role != 'customer' and not user.is_staff:
            raise PermissionDenied('Only customers can place orders.')

        cart = getattr(user, 'cart', None)
        cart_items = list(cart.items.select_related('food_item', 'food_item__category') if cart else [])
        if not cart_items:
            raise ValidationError({'cart': ['Your cart is empty.']})

        restaurant = serializer.validated_data['restaurant']
        if any(item.food_item.category.restaurant_id != restaurant.id for item in cart_items):
            raise ValidationError({'restaurant': ['All cart items must belong to the selected restaurant.']})

        address = serializer.validated_data.get('address')
        if address and address.user_id != user.id and not user.is_staff:
            raise ValidationError({'address': ['The selected address does not belong to you.']})

        subtotal = sum(
            (item.food_item.price * item.quantity for item in cart_items),
            Decimal('0.00'),
        )
        order = serializer.save(customer=user, total_amount=subtotal + restaurant.delivery_fee)
        OrderItem.objects.bulk_create([
            OrderItem(order=order, food_item=item.food_item, quantity=item.quantity, price=item.food_item.price)
            for item in cart_items
        ])
        cart.items.all().delete()
        cart.restaurant = None
        cart.save(update_fields=['restaurant'])

    from rest_framework.decorators import action
    from rest_framework.response import Response
    
    @action(detail=True, methods=['get'])
    def track(self, request, pk=None):
        order = self.get_object()
        data = {
            'status': order.status,
            'restaurant_location': {
                'lat': order.restaurant.lat,
                'lng': order.restaurant.lng,
            } if order.restaurant.lat and order.restaurant.lng else None,
            'customer_location': {
                'lat': order.address.lat,
                'lng': order.address.lng,
            } if order.address and order.address.lat and order.address.lng else None,
            'driver_location': None,
        }
        
        if hasattr(order, 'delivery') and order.delivery.driver:
            driver = order.delivery.driver
            if driver.current_lat and driver.current_lng:
                data['driver_location'] = {
                    'lat': driver.current_lat,
                    'lng': driver.current_lng,
                }
        
        return Response(data)

class CartViewSet(viewsets.ModelViewSet):
    queryset = Cart.objects.all()
    serializer_class = CartSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        if user.is_staff:
            return Cart.objects.all()
        return Cart.objects.filter(customer=user)

    def perform_create(self, serializer):
        serializer.save(customer=self.request.user)

class CartItemViewSet(viewsets.ModelViewSet):
    queryset = CartItem.objects.all()
    serializer_class = CartItemSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        queryset = CartItem.objects.select_related('cart', 'food_item')
        if self.request.user.is_staff:
            return queryset
        return queryset.filter(cart__customer=self.request.user)

    def perform_create(self, serializer):
        user = self.request.user
        cart, _ = Cart.objects.get_or_create(customer=user)
        food_item = serializer.validated_data['food_item']
        if not food_item.is_available:
            raise ValidationError({'food_item': ['This food item is not available.']})
        if cart.restaurant_id and cart.restaurant_id != food_item.category.restaurant_id:
            raise ValidationError({'food_item': ['A cart can contain items from one restaurant only.']})
        cart.restaurant = food_item.category.restaurant
        cart.save(update_fields=['restaurant'])
        serializer.save(cart=cart)

from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.exceptions import PermissionDenied

class UserRegistrationView(generics.CreateAPIView):
    queryset = User.objects.all()
    serializer_class = UserRegistrationSerializer
    permission_classes = [AllowAny]

class ForgotPasswordView(APIView):
    permission_classes = [AllowAny]
    
    def post(self, request):
        email = request.data.get('email')
        if not email:
            return Response({'error': 'Email is required'}, status=status.HTTP_400_BAD_REQUEST)
        # In a real app, you would generate a token and send an email here.
        return Response({'message': 'If an account with that email exists, a password reset link has been sent.'}, status=status.HTTP_200_OK)

class LiveItemViewSet(viewsets.ModelViewSet):
    queryset = LiveItem.objects.all()
    serializer_class = LiveItemSerializer
    permission_classes = [IsAuthenticatedOrReadOnly]
