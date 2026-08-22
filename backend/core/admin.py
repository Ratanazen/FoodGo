from django.contrib import admin

def custom_get_app_list(request, app_label=None):
    app_dict = admin.site._build_app_dict(request, app_label)
    app_list = sorted(app_dict.values(), key=lambda x: x['name'].lower())
    
    new_app_list = []
    for app in app_list:
        if app['app_label'] == 'core':
            users_models = []
            restaurant_models = []
            order_models = []
            marketing_models = []
            
            for model in app['models']:
                name = model['object_name']
                if name in ['User', 'Address', 'Driver', 'Favorite']:
                    users_models.append(model)
                elif name in ['Restaurant', 'RestaurantCategory', 'FoodCategory', 'FoodItem']:
                    restaurant_models.append(model)
                elif name in ['Order', 'OrderItem', 'Cart', 'CartItem', 'Delivery', 'Payment', 'Review']:
                    order_models.append(model)
                else:
                    marketing_models.append(model)
                    
            if users_models:
                new_app_list.append({'name': 'Users & Profiles', 'app_label': 'core_users', 'app_url': app['app_url'], 'has_module_perms': True, 'models': users_models})
            if restaurant_models:
                new_app_list.append({'name': 'Restaurants & Food', 'app_label': 'core_restaurants', 'app_url': app['app_url'], 'has_module_perms': True, 'models': restaurant_models})
            if order_models:
                new_app_list.append({'name': 'Orders & Deliveries', 'app_label': 'core_orders', 'app_url': app['app_url'], 'has_module_perms': True, 'models': order_models})
            if marketing_models:
                new_app_list.append({'name': 'Marketing & Promotions', 'app_label': 'core_marketing', 'app_url': app['app_url'], 'has_module_perms': True, 'models': marketing_models})
        else:
            new_app_list.append(app)
    return new_app_list

admin.site.get_app_list = custom_get_app_list
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import (
    User, Address, RestaurantCategory, Restaurant, FoodCategory,
    FoodItem, Order, OrderItem, Cart, CartItem, Payment, Driver,
    Delivery, Review, Favorite, Coupon, Notification, LiveItem
)

@admin.register(User)
class UserAdmin(BaseUserAdmin):
    fieldsets = BaseUserAdmin.fieldsets + (
        ('Extra Info', {'fields': ('role', 'phone')}),
    )
    list_display = ['username', 'email', 'role', 'phone', 'is_staff']
    list_filter = ['role', 'is_staff', 'is_active']
    search_fields = ['username', 'email', 'phone']

@admin.register(Address)
class AddressAdmin(admin.ModelAdmin):
    list_display = ['user', 'street', 'city', 'state', 'zip_code', 'is_default']
    list_filter = ['city', 'state', 'is_default']
    search_fields = ['user__username', 'street', 'city', 'zip_code']

@admin.register(RestaurantCategory)
class RestaurantCategoryAdmin(admin.ModelAdmin):
    list_display = ['name', 'image']
    search_fields = ['name']

@admin.register(Restaurant)
class RestaurantAdmin(admin.ModelAdmin):
    list_display = ['name', 'owner', 'category', 'rating', 'is_active']
    list_filter = ['is_active', 'category']
    search_fields = ['name', 'owner__username', 'phone']

@admin.register(FoodCategory)
class FoodCategoryAdmin(admin.ModelAdmin):
    list_display = ['name', 'restaurant']
    list_filter = ['restaurant']
    search_fields = ['name', 'restaurant__name']

@admin.register(FoodItem)
class FoodItemAdmin(admin.ModelAdmin):
    list_display = ['name', 'category', 'price', 'is_available']
    list_filter = ['is_available', 'category__restaurant', 'category']
    search_fields = ['name', 'description']

class OrderItemInline(admin.TabularInline):
    model = OrderItem
    extra = 0

@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = ['id', 'customer', 'restaurant', 'status', 'total_amount', 'created_at']
    list_filter = ['status', 'created_at', 'restaurant']
    search_fields = ['customer__username', 'id']
    inlines = [OrderItemInline]

@admin.register(OrderItem)
class OrderItemAdmin(admin.ModelAdmin):
    list_display = ['order', 'food_item', 'quantity', 'price']
    list_filter = ['order__restaurant']
    search_fields = ['order__id', 'food_item__name']

class CartItemInline(admin.TabularInline):
    model = CartItem
    extra = 0

@admin.register(Cart)
class CartAdmin(admin.ModelAdmin):
    list_display = ['customer', 'restaurant']
    search_fields = ['customer__username']
    inlines = [CartItemInline]

@admin.register(CartItem)
class CartItemAdmin(admin.ModelAdmin):
    list_display = ['cart', 'food_item', 'quantity']
    search_fields = ['cart__customer__username', 'food_item__name']

@admin.register(Payment)
class PaymentAdmin(admin.ModelAdmin):
    list_display = ['order', 'method', 'amount', 'status', 'transaction_id']
    list_filter = ['status', 'method']
    search_fields = ['order__id', 'transaction_id']

@admin.register(Driver)
class DriverAdmin(admin.ModelAdmin):
    list_display = ['user', 'vehicle_type', 'license_plate', 'is_online']
    list_filter = ['is_online']
    search_fields = ['user__username', 'license_plate']

@admin.register(Delivery)
class DeliveryAdmin(admin.ModelAdmin):
    list_display = ['order', 'driver', 'status', 'pickup_time', 'delivery_time']
    list_filter = ['status']
    search_fields = ['order__id', 'driver__user__username']

@admin.register(Review)
class ReviewAdmin(admin.ModelAdmin):
    list_display = ['order', 'rating', 'created_at']
    list_filter = ['rating']
    search_fields = ['order__id']

@admin.register(Favorite)
class FavoriteAdmin(admin.ModelAdmin):
    list_display = ['customer', 'restaurant']
    search_fields = ['customer__username', 'restaurant__name']

@admin.register(Coupon)
class CouponAdmin(admin.ModelAdmin):
    list_display = ['code', 'discount_percent', 'is_active']
    list_filter = ['is_active']
    search_fields = ['code']

@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ['user', 'title', 'is_read', 'created_at']
    list_filter = ['is_read', 'created_at']
    search_fields = ['user__username', 'title', 'message']

@admin.register(LiveItem)
class LiveItemAdmin(admin.ModelAdmin):
    list_display = ['name', 'price', 'is_live', 'created_at']
    list_filter = ['is_live', 'created_at']
    search_fields = ['name', 'description']
