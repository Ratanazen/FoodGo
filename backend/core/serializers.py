from rest_framework import serializers
from .models import *

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'role', 'phone', 'first_name', 'last_name']
        read_only_fields = ['id']

class AddressSerializer(serializers.ModelSerializer):
    class Meta:
        model = Address
        fields = ['id', 'street', 'city', 'state', 'zip_code', 'is_default', 'lat', 'lng']
        read_only_fields = ['id']

class FoodCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = FoodCategory
        fields = ['id', 'restaurant', 'name']
        read_only_fields = ['id']

class FoodItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = FoodItem
        fields = ['id', 'category', 'name', 'description', 'price', 'image', 'is_available', 'ingredients']
        read_only_fields = ['id']

    def validate_price(self, value):
        if value <= 0:
            raise serializers.ValidationError('Price must be greater than zero.')
        return value

class RestaurantSerializer(serializers.ModelSerializer):
    food_categories = FoodCategorySerializer(many=True, read_only=True)
    class Meta:
        model = Restaurant
        fields = [
            'id', 'name', 'category', 'description', 'address', 'phone', 'logo',
            'banner', 'rating', 'delivery_time_min', 'delivery_time_max',
            'delivery_fee', 'is_active', 'food_categories',
        ]
        read_only_fields = ['id', 'rating', 'food_categories']

class OrderItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = OrderItem
        fields = ['id', 'food_item', 'quantity', 'price']
        read_only_fields = ['id', 'price']

class OrderSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True, read_only=True)
    class Meta:
        model = Order
        fields = [
            'id', 'restaurant', 'address', 'status', 'total_amount',
            'special_instructions', 'created_at', 'items',
        ]
        read_only_fields = ['id', 'status', 'total_amount', 'created_at', 'items']


class CartItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = CartItem
        fields = ['id', 'food_item', 'quantity']
        read_only_fields = ['id']

    def validate_quantity(self, value):
        if value < 1:
            raise serializers.ValidationError('Quantity must be at least one.')
        return value


class CartSerializer(serializers.ModelSerializer):
    items = CartItemSerializer(many=True, read_only=True)
    class Meta:
        model = Cart
        fields = ['id', 'restaurant', 'items']
        read_only_fields = ['id', 'items']


class UserRegistrationSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)
    
    class Meta:
        model = User
        fields = ['username', 'email', 'password', 'first_name', 'last_name', 'phone', 'role']
        read_only_fields = ['role']
        
    def create(self, validated_data):
        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data.get('email', ''),
            password=validated_data['password'],
            first_name=validated_data.get('first_name', ''),
            last_name=validated_data.get('last_name', ''),
            role='customer'
        )
        if 'phone' in validated_data:
            user.phone = validated_data['phone']
            user.save()
        return user

class LiveItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = LiveItem
        fields = '__all__'
