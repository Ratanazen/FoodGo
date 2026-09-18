from django.contrib import admin
from django.utils.html import format_html
from django.db.models import Sum, Count
from django.urls import reverse

# ─────────────────────────────────────────────
# Custom App Grouping (sidebar organisation)
# ─────────────────────────────────────────────
def custom_get_app_list(request, app_label=None):
    app_dict = admin.site._build_app_dict(request, app_label)
    app_list = sorted(app_dict.values(), key=lambda x: x['name'].lower())

    new_app_list = []
    for app in app_list:
        if app['app_label'] == 'core':
            users_models, restaurant_models, order_models, marketing_models = [], [], [], []

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

            base = {'app_url': app['app_url'], 'has_module_perms': True}
            if users_models:
                new_app_list.append({**base, 'name': 'Users & Profiles', 'app_label': 'core_users', 'models': users_models})
            if restaurant_models:
                new_app_list.append({**base, 'name': 'Restaurants & Food', 'app_label': 'core_restaurants', 'models': restaurant_models})
            if order_models:
                new_app_list.append({**base, 'name': 'Orders & Deliveries', 'app_label': 'core_orders', 'models': order_models})
            if marketing_models:
                new_app_list.append({**base, 'name': 'Marketing & Promotions', 'app_label': 'core_marketing', 'models': marketing_models})
            
            # Remove the original core app to avoid duplicates
            if users_models or restaurant_models or order_models or marketing_models:
                continue
        new_app_list.append(app)
    return new_app_list


admin.site.get_app_list = custom_get_app_list

# ─────────────────────────────────────────────
# Imports
# ─────────────────────────────────────────────
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import (
    User, Address, RestaurantCategory, Restaurant, FoodCategory,
    FoodItem, Order, OrderItem, Cart, CartItem, Payment, Driver,
    Delivery, Review, Favorite, Coupon, Notification, LiveItem,
)

# ─────────────────────────────────────────────
# Custom Admin Dashboard Data
# ─────────────────────────────────────────────
from django.db.models import Sum, Count
from django.utils import timezone
import json

_original_index = admin.site.index

def custom_admin_index(request, extra_context=None):
    from .models import Order, User, Restaurant, FoodItem, Driver
    from django.db.models.functions import TruncDate

    today = timezone.now()
    week_ago = today - timezone.timedelta(days=6)

    # Stat counts
    total_orders = Order.objects.count()
    pending_orders = Order.objects.filter(status='pending').count()
    total_revenue = Order.objects.filter(status='delivered').aggregate(
        total=Sum('total_amount'))['total'] or 0
    total_users = User.objects.count()
    customer_count = User.objects.filter(role='customer').count()
    total_restaurants = Restaurant.objects.count()
    active_restaurants = Restaurant.objects.filter(is_active=True).count()
    total_food_items = FoodItem.objects.count()
    total_drivers = Driver.objects.count()
    online_drivers = Driver.objects.filter(is_online=True).count()

    # Recent orders
    recent_orders = Order.objects.select_related('customer', 'restaurant').order_by('-created_at')[:8]

    # Top restaurants by order count
    top_restaurants = (
        Restaurant.objects.annotate(order_count=Count('orders'))
        .order_by('-order_count')[:5]
    )

    # Orders per day for the last 7 days
    daily = (
        Order.objects.filter(created_at__gte=week_ago)
        .annotate(day=TruncDate('created_at'))
        .values('day')
        .annotate(count=Count('id'))
        .order_by('day')
    )
    day_map = {str(d['day']): d['count'] for d in daily}
    chart_labels = []
    chart_data = []
    for i in range(6, -1, -1):
        day = (today - timezone.timedelta(days=i)).strftime('%Y-%m-%d')
        chart_labels.append((today - timezone.timedelta(days=i)).strftime('%a'))
        chart_data.append(day_map.get(day, 0))

    # Order status distribution
    status_counts = {s: 0 for s in ['delivered', 'pending', 'preparing', 'on_the_way', 'cancelled']}
    for row in Order.objects.values('status').annotate(c=Count('id')):
        if row['status'] in status_counts:
            status_counts[row['status']] = row['c']
    status_data = list(status_counts.values())

    extra_context = extra_context or {}
    extra_context.update({
        'total_orders': total_orders,
        'pending_orders': pending_orders,
        'total_revenue': f'{total_revenue:,.2f}',
        'total_users': total_users,
        'customer_count': customer_count,
        'total_restaurants': total_restaurants,
        'active_restaurants': active_restaurants,
        'total_food_items': total_food_items,
        'total_drivers': total_drivers,
        'online_drivers': online_drivers,
        'recent_orders': recent_orders,
        'top_restaurants': top_restaurants,
        'chart_labels': json.dumps(chart_labels),
        'chart_data': json.dumps(chart_data),
        'status_data': json.dumps(status_data),
    })
    return _original_index(request, extra_context)


# Patch the default admin site
admin.site.index = custom_admin_index

admin.site.site_title = 'FoodGo Admin'
admin.site.site_header = 'FoodGo Admin Panel'
admin.site.index_title = 'Dashboard'


# ─────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────
def image_preview(image_field, size=50):
    """Return an HTML <img> tag for an image field, or a dash if missing."""
    if image_field:
        return format_html('<img src="{}" width="{}" height="{}" style="object-fit:cover;border-radius:6px;" />', image_field.url, size, size)
    return '—'


# ─────────────────────────────────────────────
# Users & Profiles
# ─────────────────────────────────────────────
@admin.register(User)
class UserAdmin(BaseUserAdmin):
    fieldsets = BaseUserAdmin.fieldsets + (
        ('Extra Info', {'fields': ('role', 'phone')}),
    )
    add_fieldsets = BaseUserAdmin.add_fieldsets + (
        ('Extra Info', {'fields': ('role', 'phone')}),
    )
    list_display = ['username', 'email', 'role_badge', 'phone', 'is_staff', 'is_active', 'date_joined']
    list_filter = ['role', 'is_staff', 'is_active']
    search_fields = ['username', 'email', 'phone']
    ordering = ['-date_joined']
    readonly_fields = ['date_joined', 'last_login']

    @admin.display(description='Role')
    def role_badge(self, obj):
        colors = {
            'admin': '#e74c3c',
            'restaurant_owner': '#e67e22',
            'driver': '#3498db',
            'customer': '#2ecc71',
        }
        color = colors.get(obj.role, '#95a5a6')
        return format_html(
            '<span style="background:{};color:#fff;padding:2px 10px;border-radius:12px;font-size:11px;font-weight:600;">{}</span>',
            color, obj.get_role_display()
        )


@admin.register(Address)
class AddressAdmin(admin.ModelAdmin):
    list_display = ['user', 'street', 'city', 'state', 'zip_code', 'default_badge']
    list_filter = ['city', 'state', 'is_default']
    search_fields = ['user__username', 'street', 'city', 'zip_code']

    @admin.display(description='Default', boolean=True)
    def default_badge(self, obj):
        return obj.is_default


# ─────────────────────────────────────────────
# Restaurants & Food
# ─────────────────────────────────────────────
@admin.register(RestaurantCategory)
class RestaurantCategoryAdmin(admin.ModelAdmin):
    list_display = ['name', 'category_image']
    search_fields = ['name']

    @admin.display(description='Image')
    def category_image(self, obj):
        return image_preview(obj.image, 40)


@admin.register(Restaurant)
class RestaurantAdmin(admin.ModelAdmin):
    list_display = ['restaurant_logo', 'name', 'owner', 'category', 'rating_stars', 'delivery_fee', 'is_active']
    list_filter = ['is_active', 'category']
    search_fields = ['name', 'owner__username', 'phone']
    readonly_fields = ['rating']
    list_editable = ['is_active']

    @admin.display(description='Logo')
    def restaurant_logo(self, obj):
        return image_preview(obj.logo, 40)

    @admin.display(description='Rating')
    def rating_stars(self, obj):
        filled = int(obj.rating)
        return format_html(
            '<span style="color:#f39c12;">{}</span><span style="color:#bdc3c7;">{}</span> ({})',
            '★' * filled, '★' * (5 - filled), obj.rating
        )


@admin.register(FoodCategory)
class FoodCategoryAdmin(admin.ModelAdmin):
    list_display = ['name', 'restaurant']
    list_filter = ['restaurant']
    search_fields = ['name', 'restaurant__name']


@admin.register(FoodItem)
class FoodItemAdmin(admin.ModelAdmin):
    list_display = ['food_image', 'name', 'category', 'price', 'is_available']
    list_filter = ['is_available', 'category__restaurant', 'category']
    search_fields = ['name', 'description']
    list_editable = ['is_available']

    @admin.display(description='Image')
    def food_image(self, obj):
        return image_preview(obj.image, 40)



# ─────────────────────────────────────────────
# Orders & Deliveries
# ─────────────────────────────────────────────
class OrderItemInline(admin.TabularInline):
    model = OrderItem
    extra = 0
    readonly_fields = ['food_item', 'quantity', 'price']
    can_delete = False


@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = ['id', 'customer', 'restaurant', 'status_badge', 'total_amount', 'created_at']
    list_filter = ['status', 'created_at', 'restaurant']
    search_fields = ['customer__username', 'id']
    inlines = [OrderItemInline]
    readonly_fields = ['created_at']
    date_hierarchy = 'created_at'
    ordering = ['-created_at']

    @admin.display(description='Status')
    def status_badge(self, obj):
        colors = {
            'pending': '#f39c12',
            'confirmed': '#3498db',
            'preparing': '#9b59b6',
            'ready': '#1abc9c',
            'picked_up': '#2980b9',
            'on_the_way': '#e67e22',
            'delivered': '#27ae60',
            'cancelled': '#e74c3c',
        }
        color = colors.get(obj.status, '#95a5a6')
        return format_html(
            '<span style="background:{};color:#fff;padding:2px 10px;border-radius:12px;font-size:11px;font-weight:600;">{}</span>',
            color, obj.get_status_display()
        )


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
    list_display = ['customer', 'restaurant', 'item_count']
    search_fields = ['customer__username']
    inlines = [CartItemInline]

    @admin.display(description='Items')
    def item_count(self, obj):
        return obj.items.count()


@admin.register(CartItem)
class CartItemAdmin(admin.ModelAdmin):
    list_display = ['cart', 'food_item', 'quantity']
    search_fields = ['cart__customer__username', 'food_item__name']


@admin.register(Payment)
class PaymentAdmin(admin.ModelAdmin):
    list_display = ['order', 'method', 'amount', 'payment_status_badge', 'transaction_id']
    list_filter = ['status', 'method']
    search_fields = ['order__id', 'transaction_id']


    @admin.display(description='Status')
    def payment_status_badge(self, obj):
        colors = {'pending': '#f39c12', 'paid': '#27ae60', 'failed': '#e74c3c', 'refunded': '#95a5a6'}
        color = colors.get(obj.status, '#95a5a6')
        return format_html(
            '<span style="background:{};color:#fff;padding:2px 10px;border-radius:12px;font-size:11px;font-weight:600;">{}</span>',
            color, obj.status.upper()
        )


@admin.register(Driver)
class DriverAdmin(admin.ModelAdmin):
    list_display = ['user', 'vehicle_type', 'license_plate', 'online_badge']
    list_filter = ['is_online']
    search_fields = ['user__username', 'license_plate']

    @admin.display(description='Online', boolean=True)
    def online_badge(self, obj):
        return obj.is_online


@admin.register(Delivery)
class DeliveryAdmin(admin.ModelAdmin):
    list_display = ['order', 'driver', 'status', 'pickup_time', 'delivery_time']
    list_filter = ['status']
    search_fields = ['order__id', 'driver__user__username']


@admin.register(Review)
class ReviewAdmin(admin.ModelAdmin):
    list_display = ['order', 'star_rating', 'created_at']
    list_filter = ['rating']
    search_fields = ['order__id']
    readonly_fields = ['created_at']

    @admin.display(description='Rating')
    def star_rating(self, obj):
        return format_html(
            '<span style="color:#f39c12;">{}</span><span style="color:#bdc3c7;">{}</span>',
            '★' * int(obj.rating), '★' * (5 - int(obj.rating))
        )


@admin.register(Favorite)
class FavoriteAdmin(admin.ModelAdmin):
    list_display = ['customer', 'restaurant']
    search_fields = ['customer__username', 'restaurant__name']


# ─────────────────────────────────────────────
# Marketing & Promotions
# ─────────────────────────────────────────────
@admin.register(Coupon)
class CouponAdmin(admin.ModelAdmin):
    list_display = ['code', 'discount_percent', 'is_active']
    list_filter = ['is_active']
    search_fields = ['code']
    list_editable = ['is_active']



@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ['user', 'title', 'read_badge', 'created_at']
    list_filter = ['is_read', 'created_at']
    search_fields = ['user__username', 'title', 'message']
    readonly_fields = ['created_at']
    date_hierarchy = 'created_at'

    @admin.display(description='Read', boolean=True)
    def read_badge(self, obj):
        return obj.is_read


@admin.register(LiveItem)
class LiveItemAdmin(admin.ModelAdmin):
    list_display = ['name', 'price', 'is_live', 'created_at']
    list_filter = ['is_live', 'created_at']
    search_fields = ['name', 'description']
    list_editable = ['is_live']

