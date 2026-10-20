from rest_framework import serializers
from .models import *

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'role', 'phone', 'first_name', 'last_name', 'avatar', 'avatar_url']
        read_only_fields = ['id']

class AddressSerializer(serializers.ModelSerializer):
    class Meta:
        model = Address
        fields = ['id', 'street', 'city', 'state', 'zip_code', 'is_default', 'lat', 'lng', 'label', 'delivery_instructions']
        read_only_fields = ['id']

class FoodItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = FoodItem
        fields = [
            'id', 'category', 'name', 'description', 'price', 'original_price',
            'image', 'image_url', 'is_available', 'ingredients',
            'is_vegetarian', 'is_halal', 'is_spicy', 'preparation_time_mins',
        ]
        read_only_fields = ['id']

    def to_representation(self, instance):
        data = super().to_representation(instance)
        if not data.get('image') and instance.image_url:
            data['image'] = instance.image_url
        if instance.category and instance.category.restaurant:
            data['restaurant'] = instance.category.restaurant.id
            data['restaurant_name'] = instance.category.restaurant.name
        return data
        
    def validate_price(self, value):
        if value <= 0:
            raise serializers.ValidationError('Price must be greater than zero.')
        return value

class FoodCategorySerializer(serializers.ModelSerializer):
    items = FoodItemSerializer(many=True, read_only=True)
    
    class Meta:
        model = FoodCategory
        fields = ['id', 'restaurant', 'name', 'items']
        read_only_fields = ['id']

class RestaurantSerializer(serializers.ModelSerializer):
    food_categories = FoodCategorySerializer(many=True, read_only=True)
    class Meta:
        model = Restaurant
        fields = [
            'id', 'name', 'category', 'description', 'address', 'phone', 'logo',
            'banner', 'rating', 'delivery_time_min', 'delivery_time_max',
            'delivery_fee', 'is_active', 'lat', 'lng',
            'opening_time', 'closing_time', 'min_order_amount',
            'food_categories',
        ]
        read_only_fields = ['id', 'rating', 'food_categories']

class RestaurantListSerializer(serializers.ModelSerializer):
    class Meta:
        model = Restaurant
        fields = [
            'id', 'name', 'category', 'description', 'address', 'phone', 'logo',
            'banner', 'rating', 'delivery_time_min', 'delivery_time_max',
            'delivery_fee', 'is_active', 'lat', 'lng',
            'opening_time', 'closing_time', 'min_order_amount',
        ]
        read_only_fields = ['id', 'rating']

class OrderItemSerializer(serializers.ModelSerializer):
    food_name = serializers.CharField(source='food_item.name', read_only=True)

    class Meta:
        model = OrderItem
        fields = ['id', 'food_item', 'food_name', 'food_name_snapshot', 'quantity', 'price', 'special_instructions']
        read_only_fields = ['id', 'price', 'food_name']

class DriverSerializer(serializers.ModelSerializer):
    user_id = serializers.IntegerField(source='user.id', read_only=True)
    username = serializers.CharField(source='user.username', read_only=True)
    full_name = serializers.SerializerMethodField()
    phone = serializers.SerializerMethodField()
    email = serializers.CharField(source='user.email', read_only=True)
    rating = serializers.FloatField(default=4.9, read_only=True)

    class Meta:
        model = Driver
        fields = [
            'id', 'user_id', 'username', 'full_name', 'phone', 'email',
            'vehicle_type', 'license_plate', 'is_online',
            'current_lat', 'current_lng', 'rating',
        ]
        read_only_fields = ['id', 'user_id', 'username', 'email']

    def get_full_name(self, obj):
        name = obj.user.get_full_name()
        return name if name else obj.user.username

    def get_phone(self, obj):
        return obj.user.phone or '+855 12 888 999'

    def to_representation(self, instance):
        data = super().to_representation(instance)
        request = self.context.get('request')
        is_staff = bool(request and request.user and request.user.is_authenticated and request.user.is_staff)
        if not is_staff:
            data.pop('phone', None)
            data.pop('license_plate', None)
        return data


class OrderSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True, read_only=True)
    restaurant = serializers.PrimaryKeyRelatedField(queryset=Restaurant.objects.all(), required=False)
    restaurant_name = serializers.CharField(source='restaurant.name', read_only=True)
    restaurant_image = serializers.SerializerMethodField()
    assigned_driver = serializers.SerializerMethodField()
    payment_info = serializers.SerializerMethodField()
    delivery_token_info = serializers.SerializerMethodField()
    customer_info = serializers.SerializerMethodField()

    class Meta:
        model = Order
        fields = [
            'id', 'order_reference', 'restaurant', 'restaurant_name', 'restaurant_image', 'address', 'status', 'payment_status',
            'subtotal', 'delivery_fee_charged', 'discount_amount', 'coupon_code', 'total_amount',
            'special_instructions', 'delivery_address_snapshot', 'estimated_delivery_time',
            'confirmed_at', 'ready_at', 'picked_up_at', 'delivered_at', 'cancelled_at', 'cancellation_reason',
            'created_at', 'updated_at', 'items', 'assigned_driver', 'payment_info', 'delivery_token_info', 'customer_info',
        ]
        read_only_fields = [
            'id', 'order_reference', 'restaurant_name', 'restaurant_image', 'status', 'payment_status',
            'subtotal', 'delivery_fee_charged', 'discount_amount', 'total_amount',
            'delivery_address_snapshot', 'estimated_delivery_time',
            'confirmed_at', 'ready_at', 'picked_up_at', 'delivered_at', 'cancelled_at', 'cancellation_reason',
            'created_at', 'updated_at', 'items', 'assigned_driver', 'payment_info', 'delivery_token_info', 'customer_info',
        ]

    def get_restaurant_image(self, obj):
        if obj.restaurant:
            img = obj.restaurant.logo or obj.restaurant.banner
            if img:
                request = self.context.get('request')
                if request:
                    return request.build_absolute_uri(img.url)
                return img.url
        return None

    def get_assigned_driver(self, obj):
        delivery = getattr(obj, 'delivery', None)
        if delivery and delivery.driver:
            driver = delivery.driver
            return {
                'id': driver.id,
                'name': driver.user.get_full_name() or driver.user.username,
                'phone': driver.user.phone or '+855 12 888 999',
                'vehicle_type': driver.vehicle_type,
                'license_plate': driver.license_plate,
                'is_online': driver.is_online,
                'status': delivery.status,
                'current_lat': float(driver.current_lat) if driver.current_lat else None,
                'current_lng': float(driver.current_lng) if driver.current_lng else None,
            }
        return None

    def get_payment_info(self, obj):
        payment = getattr(obj, 'payment', None)
        if payment:
            return {
                'id': payment.id,
                'provider': payment.provider,
                'method': payment.method,
                'status': payment.status,
                'amount': str(payment.amount),
                'currency': payment.currency,
                'qr_payload': payment.qr_payload,
                'merchant_reference': payment.merchant_reference,
            }
        return None

    def get_delivery_token_info(self, obj):
        token = getattr(obj, 'delivery_token', None)
        if not token:
            return None
        request = self.context.get('request')
        user = request.user if request and hasattr(request, 'user') else None
        delivery = getattr(obj, 'delivery', None)
        is_assigned_driver = (user and delivery and delivery.driver and delivery.driver.user_id == user.id)
        is_staff = (user and getattr(user, 'is_staff', False))

        info = {
            'has_active_token': not token.is_used and not token.is_expired(),
            'is_used': token.is_used,
            'is_expired': token.is_expired(),
            'expires_at': token.expires_at.isoformat() if token.expires_at else None,
            'driver_arrived': delivery.status == 'arrived' if delivery else False,
            'delivery_status': delivery.status if delivery else None,
        }
        if is_assigned_driver or is_staff:
            info['token'] = token.token
            info['verification_pin'] = token.verification_pin
            info['qr_payload'] = f"FOODGO:DELIVERY:CONFIRM:v1?order_id={obj.id}&token={token.token}"
        return info

    def get_customer_info(self, obj):
        if obj.customer:
            return {
                'id': obj.customer.id,
                'name': obj.customer.get_full_name() or obj.customer.username,
                'phone': obj.customer.phone or '',
                'email': obj.customer.email or '',
            }
        return None


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
    email = serializers.EmailField(required=True)
    
    class Meta:
        model = User
        fields = ['username', 'email', 'password', 'first_name', 'last_name', 'phone', 'role']
        read_only_fields = ['role']

    def validate_username(self, value):
        norm = value.strip()
        if len(norm) < 3:
            raise serializers.ValidationError("Username must be at least 3 characters long.")
        if ' ' in norm:
            raise serializers.ValidationError("Username cannot contain spaces.")
        if User.objects.filter(username__iexact=norm).exists():
            raise serializers.ValidationError("This username is already taken. Please choose another.")
        return norm

    def validate_email(self, value):
        norm = value.strip().lower()
        if User.objects.filter(email__iexact=norm).exists():
            raise serializers.ValidationError("An account with this email address already exists.")
        return norm

    def validate_password(self, value):
        if len(value) < 6:
            raise serializers.ValidationError("Password must be at least 6 characters.")
        return value
        
    def create(self, validated_data):
        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data.get('email', '').lower(),
            password=validated_data['password'],
            first_name=validated_data.get('first_name', ''),
            last_name=validated_data.get('last_name', ''),
            role='customer'
        )
        if 'phone' in validated_data and validated_data['phone']:
            user.phone = validated_data['phone']
            user.save(update_fields=['phone'])
        return user

class LiveItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = LiveItem
        fields = '__all__'


class WalletTransactionSerializer(serializers.ModelSerializer):
    class Meta:
        model = WalletTransaction
        fields = '__all__'

class WalletSerializer(serializers.ModelSerializer):
    transactions = WalletTransactionSerializer(many=True, read_only=True)
    
    class Meta:
        model = Wallet
        fields = ['id', 'user', 'balance', 'transactions']


class ReviewSerializer(serializers.ModelSerializer):
    class Meta:
        model = Review
        fields = '__all__'

class PaymentSerializer(serializers.ModelSerializer):
    customer_username = serializers.CharField(source='order.customer.username', read_only=True)
    order_reference = serializers.CharField(source='order.order_reference', read_only=True)

    class Meta:
        model = Payment
        fields = [
            'id', 'order', 'customer_username', 'order_reference', 'provider', 'method', 'transaction_id',
            'merchant_reference', 'amount', 'currency', 'qr_payload',
            'qr_image', 'status', 'provider_response', 'created_at',
            'updated_at', 'paid_at', 'expires_at'
        ]
        read_only_fields = [
            'id', 'customer_username', 'order_reference', 'transaction_id', 'merchant_reference', 'qr_payload',
            'qr_image', 'status', 'provider_response', 'created_at',
            'updated_at', 'paid_at', 'expires_at'
        ]

class RestaurantCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = RestaurantCategory
        fields = ['id', 'name', 'image']

class NotificationSerializer(serializers.ModelSerializer):
    order_id = serializers.SerializerMethodField()

    class Meta:
        model = Notification
        fields = ['id', 'user', 'title', 'message', 'notification_type', 'data', 'is_read', 'created_at', 'order_id']
        read_only_fields = ['id', 'user', 'created_at', 'order_id']

    def get_order_id(self, obj):
        if isinstance(obj.data, dict):
            return obj.data.get('order_id')
        return None

class FavoriteSerializer(serializers.ModelSerializer):
    restaurant_name = serializers.CharField(source='restaurant.name', read_only=True)
    restaurant_image = serializers.SerializerMethodField()
    rating = serializers.DecimalField(source='restaurant.rating', max_digits=3, decimal_places=2, read_only=True)
    delivery_fee = serializers.DecimalField(source='restaurant.delivery_fee', max_digits=6, decimal_places=2, read_only=True)

    class Meta:
        model = Favorite
        fields = ['id', 'customer', 'restaurant', 'restaurant_name', 'restaurant_image', 'rating', 'delivery_fee', 'created_at']
        read_only_fields = ['id', 'customer', 'restaurant_name', 'restaurant_image', 'rating', 'delivery_fee', 'created_at']

    def get_restaurant_image(self, obj):
        img = obj.restaurant.logo or obj.restaurant.banner
        if img:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(img.url)
            return img.url
        return None

class CouponSerializer(serializers.ModelSerializer):
    class Meta:
        model = Coupon
        fields = ['id', 'code', 'discount_percent', 'max_discount_amount', 'min_order_amount', 'is_active']
        read_only_fields = ['id']


class AuditLogSerializer(serializers.ModelSerializer):
    admin_username = serializers.CharField(source='admin_user.username', read_only=True, default='System')

    class Meta:
        model = AuditLog
        fields = ['id', 'admin_user', 'admin_username', 'action', 'target_type', 'target_id', 'details', 'ip_address', 'timestamp']
        read_only_fields = ['id', 'admin_user', 'admin_username', 'action', 'target_type', 'target_id', 'details', 'ip_address', 'timestamp']


class AdminUserSerializer(serializers.ModelSerializer):
    order_count = serializers.SerializerMethodField()
    wallet_balance = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            'id', 'username', 'email', 'role', 'phone', 'first_name', 'last_name',
            'is_active', 'is_staff', 'is_superuser', 'date_joined', 'last_login',
            'avatar', 'avatar_url', 'order_count', 'wallet_balance'
        ]
        read_only_fields = ['id', 'date_joined', 'last_login', 'order_count', 'wallet_balance']

    def get_order_count(self, obj):
        return getattr(obj, 'orders', None).count() if hasattr(obj, 'orders') else 0

    def get_wallet_balance(self, obj):
        if hasattr(obj, 'wallet') and obj.wallet:
            return str(obj.wallet.balance)
        return '0.00'


