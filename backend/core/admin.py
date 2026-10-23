from django.contrib import admin
from django.utils.html import format_html
from django.utils.safestring import mark_safe
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
            users_models, restaurant_models, order_models, finance_models, marketing_models = [], [], [], [], []

            for model in app['models']:
                name = model['object_name']
                if name in ['User', 'Address', 'Driver', 'Favorite']:
                    users_models.append(model)
                elif name in ['Restaurant', 'RestaurantCategory', 'FoodCategory', 'FoodItem']:
                    restaurant_models.append(model)
                elif name in ['Order', 'OrderItem', 'Cart', 'CartItem', 'Delivery', 'Review', 'OrderStatusHistory']:
                    order_models.append(model)
                elif name in ['Payment', 'Wallet', 'WalletTransaction']:
                    finance_models.append(model)
                else:
                    marketing_models.append(model)

            base = {'app_url': app['app_url'], 'has_module_perms': True}
            if users_models:
                new_app_list.append({**base, 'name': 'Users & Profiles', 'app_label': 'core_users', 'models': users_models})
            if restaurant_models:
                new_app_list.append({**base, 'name': 'Restaurants & Food', 'app_label': 'core_restaurants', 'models': restaurant_models})
            if order_models:
                new_app_list.append({**base, 'name': 'Orders & Deliveries', 'app_label': 'core_orders', 'models': order_models})
            if finance_models:
                new_app_list.append({**base, 'name': 'Finance & Wallets', 'app_label': 'core_finance', 'models': finance_models})
            if marketing_models:
                new_app_list.append({**base, 'name': 'Marketing & Promotions', 'app_label': 'core_marketing', 'models': marketing_models})
            
            # Remove the original core app to avoid duplicates
            if users_models or restaurant_models or order_models or finance_models or marketing_models:
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
    Delivery, DeliveryConfirmationToken, Review, Favorite, Coupon, Notification, LiveItem,
    Wallet, WalletTransaction, AuditLog, OrderStatusHistory,
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
    total_revenue_khr = f"{int(float(total_revenue) * 4100):,}"

    from .models import Wallet, WalletTransaction
    total_wallet_balance = Wallet.objects.aggregate(total=Sum('balance'))['total'] or 0
    total_wallet_balance_khr = f"{int(float(total_wallet_balance) * 4100):,}"
    recent_wallet_txns = WalletTransaction.objects.select_related('wallet__user').order_by('-created_at')[:6]

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

    if extra_context is None:
        extra_context = {}
    extra_context.update({
        'total_orders': total_orders,
        'pending_orders': pending_orders,
        'total_revenue': f'{total_revenue:,.2f}',
        'total_revenue_khr': total_revenue_khr,
        'total_wallet_balance': f'{total_wallet_balance:,.2f}',
        'total_wallet_balance_khr': total_wallet_balance_khr,
        'total_users': total_users,
        'customer_count': customer_count,
        'total_restaurants': total_restaurants,
        'active_restaurants': active_restaurants,
        'total_food_items': total_food_items,
        'total_drivers': total_drivers,
        'online_drivers': online_drivers,
        'recent_orders': recent_orders,
        'recent_wallet_txns': recent_wallet_txns,
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
def image_preview(image_field=None, image_url=None, size=50):
    """Return an HTML <img> tag for an image field or url, or a styled badge if missing."""
    url = None
    if image_field and hasattr(image_field, 'url'):
        try:
            url = image_field.url
        except Exception:
            url = None
    elif image_url:
        url = image_url

    if url:
        return format_html(
            '<img src="{}" width="{}" height="{}" style="object-fit:cover;border-radius:8px;box-shadow:0 2px 6px rgba(0,0,0,0.12);" />',
            url, size, size
        )
    return mark_safe('<span style="color:#aaa;font-size:11px;background:rgba(0,0,0,0.05);padding:3px 8px;border-radius:6px;">No photo</span>')


class DriverInline(admin.StackedInline):
    model = Driver
    extra = 0
    can_delete = False
    fields = ['vehicle_type', 'license_plate', 'is_online', 'current_lat', 'current_lng']


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    fieldsets = BaseUserAdmin.fieldsets + (
        ('Extra Info', {'fields': ('role', 'phone', 'avatar', 'avatar_url')}),
    )
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('username', 'email', 'role', 'first_name', 'last_name', 'phone'),
        }),
        ('Permissions', {
            'classes': ('collapse',),
            'fields': ('is_active', 'is_staff', 'is_superuser'),
        }),
    )
    inlines = [DriverInline]
    list_display = ['user_avatar_thumb', 'username', 'email', 'role_badge', 'phone', 'is_staff', 'is_active', 'date_joined']
    list_filter = ['role', 'is_staff', 'is_active']
    search_fields = ['username', 'email', 'phone', 'first_name', 'last_name']

    def get_inlines(self, request, obj=None):
        if not obj or '_popup' in request.GET or '_popup' in request.POST:
            return []
        if getattr(obj, 'role', '') == 'driver':
            return [DriverInline]
        return []

    @admin.display(description='Avatar')
    def user_avatar_thumb(self, obj):
        return image_preview(obj.avatar, obj.avatar_url, size=36)
    ordering = ['-date_joined']
    readonly_fields = ['date_joined', 'last_login']
    actions = ['promote_to_admin', 'convert_to_driver', 'convert_to_owner', 'convert_to_customer']

    def save_model(self, request, obj, form, change):
        if obj.role == 'admin':
            obj.is_staff = True
            obj.is_superuser = True
        super().save_model(request, obj, form, change)
        if obj.role == 'driver' and not hasattr(obj, 'driver_profile'):
            from decimal import Decimal
            Driver.objects.get_or_create(
                user=obj,
                defaults={
                    'vehicle_type': 'Motorcycle (Honda Wave 125i)',
                    'license_plate': 'PP-1AB-2026',
                    'is_online': True,
                    'current_lat': Decimal('11.5580'),
                    'current_lng': Decimal('104.9210'),
                }
            )

    @admin.action(description='Promote Selected Users to Admin (Staff + Superuser)')
    def promote_to_admin(self, request, queryset):
        count = queryset.update(role='admin', is_staff=True, is_superuser=True)
        self.message_user(request, f'Successfully promoted {count} user(s) to Admin.')

    @admin.action(description='Convert Selected Users to Delivery Driver')
    def convert_to_driver(self, request, queryset):
        from decimal import Decimal
        count = 0
        for user in queryset:
            user.role = 'driver'
            user.save(update_fields=['role'])
            Driver.objects.get_or_create(
                user=user,
                defaults={
                    'vehicle_type': 'Motorcycle (Honda Wave 125i)',
                    'license_plate': 'PP-1AB-2026',
                    'is_online': True,
                    'current_lat': Decimal('11.5580'),
                    'current_lng': Decimal('104.9210'),
                }
            )
            count += 1
        self.message_user(request, f'Converted {count} user(s) to Delivery Driver.')

    @admin.action(description='Convert Selected Users to Restaurant Owner')
    def convert_to_owner(self, request, queryset):
        count = queryset.update(role='restaurant_owner')
        self.message_user(request, f'Converted {count} user(s) to Restaurant Owner.')

    @admin.action(description='Convert Selected Users to Customer')
    def convert_to_customer(self, request, queryset):
        count = queryset.update(role='customer')
        self.message_user(request, f'Converted {count} user(s) to Customer.')

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
class FoodCategoryInline(admin.TabularInline):
    model = FoodCategory
    extra = 1
    show_change_link = True
    classes = ['collapse']


@admin.register(RestaurantCategory)
class RestaurantCategoryAdmin(admin.ModelAdmin):
    list_display = ['name', 'category_image']
    search_fields = ['name']

    @admin.display(description='Image')
    def category_image(self, obj):
        return image_preview(obj.image, size=40)


@admin.register(Restaurant)
class RestaurantAdmin(admin.ModelAdmin):
    list_display = ['restaurant_logo', 'name', 'owner', 'category', 'rating_stars', 'delivery_fee', 'is_active']
    list_filter = ['is_active', 'category']
    search_fields = ['name', 'owner__username', 'phone']
    readonly_fields = ['rating']
    list_editable = ['is_active']
    inlines = [FoodCategoryInline]
    save_on_top = True

    def get_inlines(self, request, obj=None):
        if '_popup' in request.GET or '_popup' in request.POST:
            return []
        return super().get_inlines(request, obj)

    def save_model(self, request, obj, form, change):
        super().save_model(request, obj, form, change)
        if obj.owner and obj.owner.role != 'restaurant_owner' and obj.owner.role != 'admin':
            obj.owner.role = 'restaurant_owner'
            obj.owner.save(update_fields=['role'])

    @admin.display(description='Logo')
    def restaurant_logo(self, obj):
        return image_preview(obj.logo, size=40)

    @admin.display(description='Rating')
    def rating_stars(self, obj):
        filled = int(obj.rating)
        empty = 5 - filled
        filled_html = '<i class="fas fa-star" style="color:#f39c12;"></i>' * filled
        empty_html = '<i class="far fa-star" style="color:#bdc3c7;"></i>' * empty
        from django.utils.safestring import mark_safe
        return format_html(
            '{} {} ({})',
            mark_safe(filled_html), mark_safe(empty_html), obj.rating
        )


class FoodItemInline(admin.TabularInline):
    model = FoodItem
    extra = 3
    fields = ['food_thumb', 'name', 'price', 'image_url', 'is_available']
    readonly_fields = ['food_thumb']
    show_change_link = True

    @admin.display(description='Photo')
    def food_thumb(self, obj):
        if obj and obj.pk:
            return image_preview(obj.image, obj.image_url, 36)
        return '—'


@admin.register(FoodCategory)
class FoodCategoryAdmin(admin.ModelAdmin):
    list_display = ['name', 'restaurant', 'items_count']
    list_filter = ['restaurant']
    search_fields = ['name', 'restaurant__name']
    inlines = [FoodItemInline]
    save_on_top = True

    def get_inlines(self, request, obj=None):
        if '_popup' in request.GET or '_popup' in request.POST:
            return []
        return super().get_inlines(request, obj)

    @admin.display(description='Items')
    def items_count(self, obj):
        count = obj.items.count()
        return format_html('<span style="background:#27ae60;color:#fff;padding:2px 8px;border-radius:10px;font-size:11px;font-weight:600;">{} items</span>', count)


@admin.register(FoodItem)
class FoodItemAdmin(admin.ModelAdmin):
    list_display = ['food_image', 'name', 'get_restaurant', 'category', 'price', 'is_available']
    list_filter = ['is_available', 'category__restaurant', 'category']
    search_fields = ['name', 'description', 'category__name', 'category__restaurant__name', 'ingredients']
    list_editable = ['price', 'is_available']
    list_per_page = 25
    save_on_top = True
    save_as = True
    actions = ['duplicate_items', 'make_available', 'make_unavailable']

    @admin.action(description='Duplicate Selected Food Items')
    def duplicate_items(self, request, queryset):
        count = 0
        for item in queryset:
            FoodItem.objects.create(
                category=item.category,
                name=f"{item.name} (Copy)",
                description=item.description,
                price=item.price,
                image=item.image,
                image_url=item.image_url,
                is_available=item.is_available,
                ingredients=item.ingredients,
            )
            count += 1
        self.message_user(request, f'Successfully duplicated {count} item(s).')

    @admin.action(description='Mark Selected Items Available')
    def make_available(self, request, queryset):
        count = queryset.update(is_available=True)
        self.message_user(request, f'Marked {count} items as available.')

    @admin.action(description='Mark Selected Items Unavailable')
    def make_unavailable(self, request, queryset):
        count = queryset.update(is_available=False)
        self.message_user(request, f'Marked {count} items as unavailable.')

    fieldsets = (
        ('Basic Information', {
            'fields': ('name', 'category', 'price', 'is_available'),
            'description': 'Select the food category and enter the food item name and price in USD.',
        }),
        ('Food Photo / Image', {
            'fields': ('image_url', 'image', 'food_image_large'),
            'description': 'Paste a direct web image link (e.g. Unsplash URL) OR upload an image file from your device.',
        }),
        ('Description & Ingredients', {
            'fields': ('description', 'ingredients'),
            'classes': ('collapse',),
            'description': 'Detailed information shown on customer food details and search results.',
        }),
    )
    readonly_fields = ['food_image_large']

    @admin.display(description='Photo')
    def food_image(self, obj):
        return image_preview(obj.image, obj.image_url, 44)

    @admin.display(description='Preview')
    def food_image_large(self, obj):
        return image_preview(obj.image, obj.image_url, 140)

    @admin.display(description='Restaurant', ordering='category__restaurant__name')
    def get_restaurant(self, obj):
        return obj.category.restaurant.name

    @admin.display(description='Price', ordering='price')
    def price_display(self, obj):
        return format_html('<span style="font-weight:700;color:#27ae60;">${}</span>', f"{float(obj.price):.2f}")



# ─────────────────────────────────────────────
# Orders & Deliveries
# ─────────────────────────────────────────────
class OrderItemInline(admin.TabularInline):
    model = OrderItem
    extra = 0
    readonly_fields = ['food_item', 'quantity', 'price']
    can_delete = False


class DeliveryInline(admin.StackedInline):
    model = Delivery
    extra = 0
    fields = ['driver', 'status', 'pickup_time', 'delivery_time']
    autocomplete_fields = ['driver']


class OrderStatusHistoryInline(admin.TabularInline):
    model = OrderStatusHistory
    extra = 0
    readonly_fields = ['from_status', 'to_status', 'actor', 'actor_role', 'notes', 'created_at']
    can_delete = False
    ordering = ['created_at']


@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = ['id', 'customer', 'restaurant', 'assigned_driver_badge', 'status_badge', 'payment_status', 'total_amount', 'bill_action', 'created_at']
    list_filter = ['status', 'payment_status', 'created_at', 'restaurant']
    search_fields = ['customer__username', 'id']
    inlines = [OrderItemInline, DeliveryInline, OrderStatusHistoryInline]
    readonly_fields = ['created_at', 'view_bill_link']
    date_hierarchy = 'created_at'
    ordering = ['-created_at']
    actions = ['auto_assign_driver', 'mark_preparing', 'mark_on_the_way', 'mark_delivered']

    @admin.display(description='Assigned Driver')
    def assigned_driver_badge(self, obj):
        delivery = getattr(obj, 'delivery', None)
        if delivery and delivery.driver:
            driver = delivery.driver
            online_dot = mark_safe('<span style="display:inline-block;width:8px;height:8px;border-radius:50%;background:#22c55e;"></span>') if driver.is_online else mark_safe('<span style="display:inline-block;width:8px;height:8px;border-radius:50%;background:#94a3b8;"></span>')
            return format_html(
                '<span style="background:#1e293b;color:#f8fafc;padding:3px 8px;border-radius:8px;font-size:11px;font-weight:600;display:inline-flex;align-items:center;gap:6px;">'
                '{} <strong>{}</strong> <span style="opacity:0.75;">({})</span></span>',
                online_dot, driver.user.username, driver.vehicle_type or 'Bike'
            )
        return mark_safe('<span style="color:#94a3b8;font-size:11px;font-style:italic;">— Unassigned —</span>')

    @admin.action(description='Auto-Assign Available Online Driver')
    def auto_assign_driver(self, request, queryset):
        driver = Driver.objects.filter(is_online=True).first() or Driver.objects.first()
        if not driver:
            self.message_user(request, 'No drivers exist. Please create a driver first.', level='error')
            return
        count = 0
        for order in queryset:
            Delivery.objects.update_or_create(order=order, defaults={'driver': driver, 'status': 'assigned'})
            if order.status == 'pending':
                order.status = 'confirmed'
                order.save(update_fields=['status'])
            count += 1
        self.message_user(request, f'Assigned driver {driver.user.username} to {count} order(s).')

    @admin.action(description='Mark Selected Orders as Preparing')
    def mark_preparing(self, request, queryset):
        count = queryset.update(status='preparing')
        self.message_user(request, f'Updated {count} order(s) to Preparing.')

    @admin.action(description='Mark Selected Orders as On the Way')
    def mark_on_the_way(self, request, queryset):
        count = queryset.update(status='on_the_way')
        self.message_user(request, f'Updated {count} order(s) to On the Way.')

    @admin.action(description='Mark Selected Orders as Delivered')
    def mark_delivered(self, request, queryset):
        count = queryset.update(status='delivered')
        self.message_user(request, f'Updated {count} order(s) to Delivered.')

    def get_urls(self):
        from django.urls import path
        urls = super().get_urls()
        custom_urls = [
            path('<path:object_id>/bill/', self.admin_site.admin_view(self.order_bill_view), name='order-bill'),
        ]
        return custom_urls + urls

    def order_bill_view(self, request, object_id, *args, **kwargs):
        from django.shortcuts import get_object_or_404, render
        order = get_object_or_404(Order.objects.select_related('customer', 'restaurant', 'address'), pk=object_id)
        items = []
        subtotal = 0
        for oi in order.items.select_related('food_item', 'food_item__category'):
            line_total = oi.price * oi.quantity
            subtotal += line_total
            items.append({
                'food_item': oi.food_item,
                'quantity': oi.quantity,
                'price': f'{oi.price:.2f}',
                'total': f'{line_total:.2f}',
            })

        payment = getattr(order, 'payment', None)

        try:
            total_khr = f"{int(float(order.total_amount) * 4100):,}"
        except Exception:
            total_khr = "0"

        context = {
            'order': order,
            'items': items,
            'subtotal': f'{subtotal:.2f}',
            'payment': payment,
            'total_khr': total_khr,
            'title': f'Bill Receipt - Order #{order.id}',
        }
        return render(request, 'core/order_bill.html', context)

    @admin.display(description='Bill / Receipt')
    def bill_action(self, obj):
        url = reverse('admin:order-bill', args=[obj.id])
        return format_html(
            '<a href="{}" target="_blank" style="background:#10b981;color:#fff;padding:3px 10px;border-radius:6px;font-size:11px;font-weight:700;text-decoration:none;display:inline-flex;align-items:center;gap:4px;">'
            '&#128438; Print Bill</a>',
            url
        )

    @admin.display(description='Print Bill')
    def view_bill_link(self, obj):
        if not obj or not obj.id:
            return '-'
        url = reverse('admin:order-bill', args=[obj.id])
        return format_html(
            '<a href="{}" target="_blank" style="background:#10b981;color:#fff;padding:8px 16px;border-radius:8px;font-size:13px;font-weight:700;text-decoration:none;display:inline-flex;align-items:center;gap:6px;">'
            '&#128424; Open &amp; Print Order Bill</a>',
            url
        )

    @admin.display(description='Status')
    def status_badge(self, obj):
        colors = {
            'pending': '#f39c12',
            'confirmed': '#3498db',
            'driver_assigned': '#0284c7',
            'driver_accepted': '#0369a1',
            'preparing': '#9b59b6',
            'ready': '#1abc9c',
            'ready_for_pickup': '#0d9488',
            'picked_up': '#2980b9',
            'on_the_way': '#e67e22',
            'out_for_delivery': '#d97706',
            'driver_arrived': '#6366f1',
            'arrived': '#6366f1',
            'delivered': '#27ae60',
            'failed_delivery': '#dc2626',
            'cancelled': '#e74c3c',
        }
        color = colors.get(obj.status, '#95a5a6')
        return format_html(
            '<span style="background:{};color:#fff;padding:2px 10px;border-radius:12px;font-size:11px;font-weight:600;">{}</span>',
            color, obj.get_status_display()
        )


@admin.register(OrderStatusHistory)
class OrderStatusHistoryAdmin(admin.ModelAdmin):
    list_display = ['id', 'order', 'from_status', 'to_status', 'actor', 'actor_role', 'notes', 'created_at']
    list_filter = ['to_status', 'actor_role', 'created_at']
    search_fields = ['order__id', 'order__order_reference', 'actor__username', 'notes']
    readonly_fields = ['order', 'from_status', 'to_status', 'actor', 'actor_role', 'notes', 'created_at']
    ordering = ['-created_at']


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
    list_display = ['id', 'order', 'provider', 'method', 'amount', 'currency', 'payment_status_badge', 'merchant_reference', 'transaction_id', 'created_at']
    list_filter = ['status', 'provider', 'method', 'currency', 'created_at']
    search_fields = ['order__id', 'transaction_id', 'merchant_reference']
    readonly_fields = ['order', 'amount', 'currency', 'merchant_reference', 'transaction_id', 'created_at', 'updated_at', 'paid_at', 'provider_response', 'qr_payload']

    @admin.display(description='Status')
    def payment_status_badge(self, obj):
        colors = {
            'PENDING': '#f39c12',
            'PROCESSING': '#3498db',
            'PAID': '#27ae60',
            'FAILED': '#e74c3c',
            'EXPIRED': '#7f8c8d',
            'CANCELLED': '#95a5a6',
            'REFUNDED': '#8e44ad',
        }
        color = colors.get(obj.status.upper(), '#95a5a6')
        return format_html(
            '<span style="background:{};color:#fff;padding:2px 10px;border-radius:12px;font-size:11px;font-weight:600;">{}</span>',
            color, obj.status.upper()
        )


@admin.register(Driver)
class DriverAdmin(admin.ModelAdmin):
    list_display = ['user', 'driver_phone', 'vehicle_type', 'license_plate', 'is_approved', 'is_online', 'deliveries_count', 'earnings_display']
    list_filter = ['is_approved', 'is_online', 'vehicle_type']
    search_fields = ['user__username', 'user__first_name', 'user__last_name', 'license_plate', 'user__phone']
    list_editable = ['is_approved', 'is_online']
    actions = ['approve_drivers', 'suspend_drivers', 'make_online', 'make_offline']

    def formfield_for_foreignkey(self, db_field, request, **kwargs):
        if db_field.name == 'user':
            from django.db.models import Q
            object_id = None
            if request and hasattr(request, 'resolver_match') and request.resolver_match:
                object_id = request.resolver_match.kwargs.get('object_id')
            if object_id:
                current_driver = Driver.objects.filter(pk=object_id).first()
                current_user_id = current_driver.user_id if current_driver else None
                kwargs['queryset'] = User.objects.filter(
                    Q(driver_profile__isnull=True) | Q(id=current_user_id)
                ).order_by('username')
            else:
                kwargs['queryset'] = User.objects.filter(
                    driver_profile__isnull=True
                ).order_by('username')
        return super().formfield_for_foreignkey(db_field, request, **kwargs)

    def save_model(self, request, obj, form, change):
        if obj.user:
            if obj.user.role != 'driver' and obj.user.role != 'admin':
                obj.user.role = 'driver'
                obj.user.save(update_fields=['role'])

            existing = Driver.objects.filter(user=obj.user).exclude(pk=obj.pk).first()
            if existing:
                existing.vehicle_type = obj.vehicle_type or existing.vehicle_type
                existing.license_plate = obj.license_plate or existing.license_plate
                existing.is_online = obj.is_online
                existing.is_approved = obj.is_approved
                if obj.current_lat is not None:
                    existing.current_lat = obj.current_lat
                if obj.current_lng is not None:
                    existing.current_lng = obj.current_lng
                existing.save()
                obj.pk = existing.pk
                return
        super().save_model(request, obj, form, change)

    @admin.display(description='Phone')
    def driver_phone(self, obj):
        return obj.user.phone or '—'

    @admin.display(description='Online', boolean=True)
    def online_badge(self, obj):
        return obj.is_online

    @admin.display(description='Deliveries')
    def deliveries_count(self, obj):
        count = obj.deliveries.count()
        return format_html('<span style="background:#34495e;color:#fff;padding:2px 8px;border-radius:10px;font-size:11px;">{}</span>', count)

    @admin.display(description='Earnings', ordering='total_earnings')
    def earnings_display(self, obj):
        return format_html('<span style="font-weight:700;color:#27ae60;">${}</span>', f"{float(obj.total_earnings):.2f}")

    @admin.action(description='Approve Selected Drivers')
    def approve_drivers(self, request, queryset):
        count = queryset.update(is_approved=True)
        self.message_user(request, f'Approved {count} driver(s).')

    @admin.action(description='Suspend Selected Drivers')
    def suspend_drivers(self, request, queryset):
        count = queryset.update(is_approved=False, is_online=False)
        self.message_user(request, f'Suspended {count} driver(s).')

    @admin.action(description='Set Selected Drivers Online')
    def make_online(self, request, queryset):
        count = queryset.update(is_online=True)
        self.message_user(request, f'Set {count} driver(s) online.')

    @admin.action(description='Set Selected Drivers Offline')
    def make_offline(self, request, queryset):
        count = queryset.update(is_online=False)
        self.message_user(request, f'Set {count} driver(s) offline.')


@admin.register(Delivery)
class DeliveryAdmin(admin.ModelAdmin):
    list_display = ['id', 'order', 'driver', 'status_badge', 'pickup_time', 'delivery_time', 'created_at']
    list_filter = ['status', 'created_at']
    search_fields = ['order__id', 'order__order_reference', 'driver__user__username']
    actions = ['release_assignment', 'mark_delivered']

    @admin.display(description='Status')
    def status_badge(self, obj):
        colors = {
            'assigned': '#f39c12',
            'accepted': '#3498db',
            'arrived_at_restaurant': '#9b59b6',
            'picked_up': '#2980b9',
            'on_the_way': '#e67e22',
            'arrived': '#1abc9c',
            'delivered': '#27ae60',
            'cancelled': '#e74c3c',
        }
        color = colors.get(obj.status, '#95a5a6')
        return format_html(
            '<span style="background:{};color:#fff;padding:2px 10px;border-radius:12px;font-size:11px;font-weight:600;">{}</span>',
            color, obj.get_status_display()
        )

    @admin.action(description='Release Selected Deliveries for Reassignment')
    def release_assignment(self, request, queryset):
        count = queryset.update(driver=None, status='assigned')
        self.message_user(request, f'Released {count} delivery assignment(s) for reassignment.')

    @admin.action(description='Mark Selected Deliveries as Delivered')
    def mark_delivered(self, request, queryset):
        now = timezone.now()
        count = 0
        for delivery in queryset:
            delivery.status = 'delivered'
            delivery.delivery_time = now
            delivery.save(update_fields=['status', 'delivery_time'])
            order = delivery.order
            order.status = 'delivered'
            order.delivered_at = now
            order.save(update_fields=['status', 'delivered_at'])
            if delivery.driver:
                fee = order.delivery_fee_charged if order.delivery_fee_charged else Decimal('2.00')
                delivery.driver.total_deliveries += 1
                delivery.driver.total_earnings += fee
                delivery.driver.save(update_fields=['total_deliveries', 'total_earnings'])
            count += 1
        self.message_user(request, f'Marked {count} delivery/order(s) as Delivered.')


@admin.register(Review)
class ReviewAdmin(admin.ModelAdmin):
    list_display = ['order', 'star_rating', 'created_at']
    list_filter = ['rating']
    search_fields = ['order__id']
    readonly_fields = ['created_at']

    @admin.display(description='Rating')
    def star_rating(self, obj):
        filled = int(obj.rating)
        empty = 5 - filled
        filled_html = '<i class="fas fa-star" style="color:#f39c12;"></i>' * filled
        empty_html = '<i class="far fa-star" style="color:#bdc3c7;"></i>' * empty
        from django.utils.safestring import mark_safe
        return format_html(
            '{} {}',
            mark_safe(filled_html), mark_safe(empty_html)
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


class WalletTransactionInline(admin.TabularInline):
    model = WalletTransaction
    extra = 0
    readonly_fields = ['amount', 'transaction_type', 'description', 'created_at']
    can_delete = False


@admin.register(Wallet)
class WalletAdmin(admin.ModelAdmin):
    list_display = ['user', 'balance_display', 'transactions_count']
    search_fields = ['user__username', 'user__email']
    readonly_fields = ['transactions_count']
    inlines = [WalletTransactionInline]

    @admin.display(description='Balance (USD & KHR)')
    def balance_display(self, obj):
        usd_str = f"${float(obj.balance):.2f}"
        khr_str = f"៛{int(float(obj.balance) * 4100):,} KHR"
        return format_html(
            '<strong style="color:#27ae60;font-size:14px;">{}</strong> <span style="color:#888;font-size:11px;">(≈ {})</span>',
            usd_str, khr_str
        )

    @admin.display(description='Transactions')
    def transactions_count(self, obj):
        count = obj.transactions.count()
        return format_html('<span style="background:#34495e;color:#fff;padding:2px 8px;border-radius:10px;font-size:11px;">{} txns</span>', count)


@admin.register(WalletTransaction)
class WalletTransactionAdmin(admin.ModelAdmin):
    list_display = ['wallet_user', 'transaction_type_badge', 'amount_display', 'description', 'created_at']
    list_filter = ['transaction_type', 'created_at']
    search_fields = ['wallet__user__username', 'description']

    def get_readonly_fields(self, request, obj=None):
        if obj is None:
            return ['created_at']
        return ['wallet', 'amount', 'transaction_type', 'description', 'created_at']

    @admin.display(description='User')
    def wallet_user(self, obj):
        return obj.wallet.user.username

    @admin.display(description='Type')
    def transaction_type_badge(self, obj):
        colors = {
            'deposit': '#27ae60',
            'withdrawal': '#e67e22',
            'payment': '#2980b9',
            'refund': '#8e44ad',
        }
        color = colors.get(obj.transaction_type, '#95a5a6')
        return format_html(
            '<span style="background:{};color:#fff;padding:2px 8px;border-radius:10px;font-size:11px;font-weight:600;">{}</span>',
            color, obj.get_transaction_type_display()
        )

    @admin.display(description='Amount')
    def amount_display(self, obj):
        is_pos = obj.transaction_type in ('deposit', 'refund')
        sign = '+' if is_pos else '-'
        color = '#27ae60' if is_pos else '#e74c3c'
        amt_str = f"{float(obj.amount):.2f}"
        return format_html('<strong style="color:{};">{}${}</strong>', color, sign, amt_str)


@admin.register(DeliveryConfirmationToken)
class DeliveryConfirmationTokenAdmin(admin.ModelAdmin):
    list_display = ('id', 'order_link', 'driver_name', 'verification_pin', 'is_used', 'created_at', 'expires_at')
    list_filter = ('is_used', 'created_at')
    search_fields = ('token', 'verification_pin', 'order__id', 'driver__user__username')
    readonly_fields = ('created_at', 'used_at', 'token', 'verification_pin', 'confirmed_by', 'ip_address', 'user_agent')

    @admin.display(description='Order')
    def order_link(self, obj):
        return f"Order #{obj.order_id}"

    @admin.display(description='Driver')
    def driver_name(self, obj):
        return obj.driver.user.get_full_name() or obj.driver.user.username


@admin.register(AuditLog)
class AuditLogAdmin(admin.ModelAdmin):
    list_display = ('id', 'timestamp', 'admin_user', 'action', 'target_type', 'target_id')
    list_filter = ('action', 'target_type', 'timestamp')
    search_fields = ('target_id', 'admin_user__username', 'admin_user__email', 'details')
    readonly_fields = ('admin_user', 'action', 'target_type', 'target_id', 'details', 'ip_address', 'timestamp')


