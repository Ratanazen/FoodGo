from decimal import Decimal
from django.db import models
from django.contrib.auth.models import AbstractUser
from django.utils import timezone

class User(AbstractUser):
    ROLE_CHOICES = (
        ('customer', 'Customer'),
        ('restaurant_owner', 'Restaurant Owner'),
        ('driver', 'Driver'),
        ('admin', 'Admin'),
    )
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='customer')
    phone = models.CharField(max_length=20, blank=True, null=True)
    avatar = models.ImageField(upload_to='avatars/', blank=True, null=True)
    avatar_url = models.URLField(max_length=500, blank=True, null=True, help_text="Direct web link or Google profile photo")

class Address(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='addresses')
    street = models.CharField(max_length=255)
    city = models.CharField(max_length=100)
    state = models.CharField(max_length=100)
    zip_code = models.CharField(max_length=20)
    is_default = models.BooleanField(default=False)
    lat = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    lng = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    label = models.CharField(max_length=50, default='home', help_text="home, work, other")
    delivery_instructions = models.TextField(blank=True, default='')

    class Meta:
        verbose_name_plural = 'Addresses'

    def __str__(self):
        return f"{self.street}, {self.city} ({self.user.username})"

class RestaurantCategory(models.Model):
    name = models.CharField(max_length=100)
    image = models.ImageField(upload_to='categories/', blank=True, null=True)

    class Meta:
        verbose_name_plural = 'Restaurant categories'

    def __str__(self):
        return self.name

class Restaurant(models.Model):
    owner = models.OneToOneField(User, on_delete=models.CASCADE, related_name='restaurant')
    name = models.CharField(max_length=255)
    category = models.ForeignKey(RestaurantCategory, on_delete=models.SET_NULL, null=True, related_name='restaurants')
    description = models.TextField(blank=True)
    address = models.TextField()
    phone = models.CharField(max_length=20)
    logo = models.ImageField(upload_to='restaurants/logos/', blank=True, null=True)
    banner = models.ImageField(upload_to='restaurants/banners/', blank=True, null=True)
    rating = models.DecimalField(max_digits=3, decimal_places=2, default=0.0)
    delivery_time_min = models.IntegerField(default=15)
    delivery_time_max = models.IntegerField(default=45)
    delivery_fee = models.DecimalField(max_digits=6, decimal_places=2, default=0.0)
    is_active = models.BooleanField(default=True)
    lat = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    lng = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    opening_time = models.TimeField(null=True, blank=True, default='08:00:00')
    closing_time = models.TimeField(null=True, blank=True, default='22:00:00')
    min_order_amount = models.DecimalField(max_digits=6, decimal_places=2, default=0.0)

    def __str__(self):
        return self.name
    
class FoodCategory(models.Model):
    restaurant = models.ForeignKey(Restaurant, on_delete=models.CASCADE, related_name='food_categories')
    name = models.CharField(max_length=100)

    class Meta:
        verbose_name_plural = 'Food categories'

    def __str__(self):
        return f"{self.name} ({self.restaurant.name})"

class FoodItem(models.Model):
    category = models.ForeignKey(FoodCategory, on_delete=models.CASCADE, related_name='items')
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    price = models.DecimalField(max_digits=8, decimal_places=2)
    image = models.ImageField(upload_to='foods/', blank=True, null=True)
    image_url = models.URLField(max_length=500, blank=True, null=True, help_text="Paste direct web image URL (e.g. Unsplash) or upload file")
    is_available = models.BooleanField(default=True)
    ingredients = models.CharField(max_length=255, blank=True, help_text="Comma separated ingredients")
    original_price = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)
    is_vegetarian = models.BooleanField(default=False)
    is_halal = models.BooleanField(default=False)
    is_spicy = models.BooleanField(default=False)
    preparation_time_mins = models.IntegerField(default=15)

    def __str__(self):
        return f"{self.name} - ${self.price}"

class Order(models.Model):
    STATUS_CHOICES = (
        ('pending', 'Pending'),
        ('confirmed', 'Confirmed'),
        ('driver_assigned', 'Driver Assigned'),
        ('driver_accepted', 'Driver Accepted'),
        ('preparing', 'Preparing'),
        ('ready_for_pickup', 'Ready for Pickup'),
        ('picked_up', 'Picked Up'),
        ('on_the_way', 'On the Way'),
        ('out_for_delivery', 'Out for Delivery'),
        ('driver_arrived', 'Driver Arrived'),
        ('delivered', 'Delivered'),
        ('failed_delivery', 'Failed Delivery'),
        ('cancelled', 'Cancelled'),
        # Backward-compatible choices
        ('ready', 'Ready for Pickup (Legacy)'),
        ('arrived', 'Driver Arrived (Legacy)'),
    )
    PAYMENT_STATUS_CHOICES = (
        ('UNPAID', 'Unpaid'),
        ('PENDING', 'Pending'),
        ('PAID', 'Paid'),
        ('FAILED', 'Failed'),
        ('REFUNDED', 'Refunded'),
    )
    order_reference = models.CharField(max_length=50, blank=True, null=True, unique=True, db_index=True)
    customer = models.ForeignKey(User, on_delete=models.CASCADE, related_name='orders')
    restaurant = models.ForeignKey(Restaurant, on_delete=models.CASCADE, related_name='orders')
    address = models.ForeignKey(Address, on_delete=models.SET_NULL, null=True)
    status = models.CharField(max_length=30, choices=STATUS_CHOICES, default='pending')
    payment_status = models.CharField(max_length=20, choices=PAYMENT_STATUS_CHOICES, default='UNPAID')
    subtotal = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    delivery_fee_charged = models.DecimalField(max_digits=6, decimal_places=2, default=0.00)
    discount_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    coupon_code = models.CharField(max_length=50, blank=True, null=True)
    total_amount = models.DecimalField(max_digits=10, decimal_places=2)
    special_instructions = models.TextField(blank=True)
    delivery_address_snapshot = models.TextField(blank=True, default='')
    estimated_delivery_time = models.DateTimeField(null=True, blank=True)
    confirmed_at = models.DateTimeField(null=True, blank=True)
    ready_at = models.DateTimeField(null=True, blank=True)
    picked_up_at = models.DateTimeField(null=True, blank=True)
    delivered_at = models.DateTimeField(null=True, blank=True)
    cancelled_at = models.DateTimeField(null=True, blank=True)
    cancellation_reason = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def save(self, *args, **kwargs):
        if not self.order_reference:
            import secrets
            from django.utils import timezone
            date_str = timezone.now().strftime('%Y%m%d')
            rand_hex = secrets.token_hex(3).upper()
            self.order_reference = f"FG-{date_str}-{rand_hex}"
        super().save(*args, **kwargs)

    def __str__(self):
        ref = self.order_reference or f"#{self.id}"
        return f"Order {ref} - {self.customer.username} (${self.total_amount})"

class OrderItem(models.Model):
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name='items')
    food_item = models.ForeignKey(FoodItem, on_delete=models.SET_NULL, null=True)
    quantity = models.IntegerField(default=1)
    price = models.DecimalField(max_digits=8, decimal_places=2)
    food_name_snapshot = models.CharField(max_length=255, blank=True, default='')
    special_instructions = models.TextField(blank=True, default='')

    def save(self, *args, **kwargs):
        if not self.food_name_snapshot and self.food_item:
            self.food_name_snapshot = self.food_item.name
        super().save(*args, **kwargs)

    def __str__(self):
        name = self.food_item.name if self.food_item else 'Item'
        return f"{self.quantity}x {name} (${self.price})"

class Cart(models.Model):
    customer = models.OneToOneField(User, on_delete=models.CASCADE, related_name='cart')
    restaurant = models.ForeignKey(Restaurant, on_delete=models.SET_NULL, null=True, blank=True)

    def __str__(self):
        return f"Cart ({self.customer.username})"

class CartItem(models.Model):
    cart = models.ForeignKey(Cart, on_delete=models.CASCADE, related_name='items')
    food_item = models.ForeignKey(FoodItem, on_delete=models.CASCADE)
    quantity = models.IntegerField(default=1)

    def __str__(self):
        return f"{self.quantity}x {self.food_item.name}"

class Payment(models.Model):
    PROVIDER_CHOICES = (
        ('BAKONG', 'Bakong KHQR'),
        ('ABA', 'ABA KHQR'),
        ('ACLEDA', 'ACLEDA KHQR'),
        ('COD', 'Cash on Delivery'),
        ('WALLET', 'FoodGo Wallet'),
    )
    METHOD_CHOICES = (
        ('KHQR', 'KHQR'),
        ('COD', 'Cash on Delivery'),
        ('WALLET', 'Wallet Account Balance'),
    )
    STATUS_CHOICES = (
        ('PENDING', 'Pending'),
        ('PROCESSING', 'Processing'),
        ('PAID', 'Paid'),
        ('FAILED', 'Failed'),
        ('EXPIRED', 'Expired'),
        ('CANCELLED', 'Cancelled'),
        ('REFUNDED', 'Refunded'),
    )

    order = models.OneToOneField(Order, on_delete=models.CASCADE, related_name='payment')
    provider = models.CharField(max_length=20, choices=PROVIDER_CHOICES, default='ABA')
    method = models.CharField(max_length=20, choices=METHOD_CHOICES, default='KHQR')
    transaction_id = models.CharField(max_length=100, blank=True, unique=True, null=True)
    merchant_reference = models.CharField(max_length=100, blank=True, unique=True, null=True)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    currency = models.CharField(max_length=10, default='USD')
    qr_payload = models.TextField(blank=True, null=True)
    qr_image = models.TextField(blank=True, null=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='PENDING')
    provider_response = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)
    paid_at = models.DateTimeField(null=True, blank=True)
    expires_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"Payment #{self.id} (Order #{self.order_id} - {self.provider} - {self.status})"

class Driver(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='driver_profile')
    vehicle_type = models.CharField(max_length=50)
    license_plate = models.CharField(max_length=50)
    is_online = models.BooleanField(default=False)
    is_approved = models.BooleanField(default=True, db_index=True)
    current_lat = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    current_lng = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    operational_status = models.CharField(max_length=30, default='available')
    last_location_update = models.DateTimeField(null=True, blank=True)
    total_deliveries = models.IntegerField(default=0)
    total_earnings = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal('0.00'))

    def __str__(self):
        return f"Driver: {self.user.username} ({self.vehicle_type})"

class Delivery(models.Model):
    STATUS_CHOICES = (
        ('assigned', 'Assigned'),
        ('accepted', 'Accepted'),
        ('arrived_at_restaurant', 'Arrived at Restaurant'),
        ('preparing', 'Preparing'),
        ('ready_for_pickup', 'Ready for Pickup'),
        ('picked_up', 'Picked Up'),
        ('on_the_way', 'On the Way'),
        ('out_for_delivery', 'Out for Delivery'),
        ('arrived', 'Arrived at Customer'),
        ('delivered', 'Delivered'),
        ('failed_delivery', 'Failed Delivery'),
        ('cancelled', 'Cancelled'),
    )
    order = models.OneToOneField(Order, on_delete=models.CASCADE, related_name='delivery')
    driver = models.ForeignKey(Driver, on_delete=models.SET_NULL, null=True, blank=True, related_name='deliveries')
    pickup_time = models.DateTimeField(null=True, blank=True)
    delivery_time = models.DateTimeField(null=True, blank=True)
    status = models.CharField(max_length=30, choices=STATUS_CHOICES, default='assigned')
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name_plural = 'Deliveries'

    def __str__(self):
        return f"Delivery for Order #{self.order_id} ({self.status})"

class OrderStatusHistory(models.Model):
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name='status_history')
    from_status = models.CharField(max_length=30, blank=True, null=True)
    to_status = models.CharField(max_length=30)
    actor = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='order_status_changes')
    actor_role = models.CharField(max_length=30, blank=True, default='')  # 'customer', 'driver', 'restaurant', 'admin', 'system'
    notes = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['created_at']
        verbose_name = 'Order Status History'
        verbose_name_plural = 'Order Status Histories'

    def __str__(self):
        actor_name = self.actor.username if self.actor else 'System'
        return f"Order #{self.order_id}: {self.from_status} -> {self.to_status} by {actor_name} ({self.created_at:%Y-%m-%d %H:%M})"

class DeliveryConfirmationToken(models.Model):
    order = models.OneToOneField(Order, on_delete=models.CASCADE, related_name='delivery_token')
    driver = models.ForeignKey(Driver, on_delete=models.CASCADE, related_name='delivery_tokens')
    token = models.CharField(max_length=64, unique=True, db_index=True)
    verification_pin = models.CharField(max_length=6, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField(db_index=True)
    is_used = models.BooleanField(default=False, db_index=True)
    used_at = models.DateTimeField(null=True, blank=True)
    confirmed_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='confirmed_deliveries')
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.TextField(blank=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Delivery Confirmation Token'
        verbose_name_plural = 'Delivery Confirmation Tokens'

    def __str__(self):
        status = 'USED' if self.is_used else ('EXPIRED' if self.is_expired() else 'ACTIVE')
        return f"Delivery Token for Order #{self.order_id} ({status})"

    def is_expired(self):
        return timezone.now() > self.expires_at

    def is_valid(self):
        return not self.is_used and not self.is_expired()


class Review(models.Model):
    order = models.OneToOneField(Order, on_delete=models.CASCADE, related_name='review')
    rating = models.IntegerField(default=5)
    comment = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Review for Order #{self.order_id}: {self.rating}/5"

class Favorite(models.Model):
    customer = models.ForeignKey(User, on_delete=models.CASCADE, related_name='favorites')
    restaurant = models.ForeignKey(Restaurant, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True, null=True, blank=True)

    class Meta:
        unique_together = ('customer', 'restaurant')

    def __str__(self):
        return f"{self.customer.username} - {self.restaurant.name}"
    
class Coupon(models.Model):
    code = models.CharField(max_length=20, unique=True)
    discount_percent = models.IntegerField(default=10)
    max_discount_amount = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)
    min_order_amount = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    is_active = models.BooleanField(default=True)

    def __str__(self):
        return f"{self.code} ({self.discount_percent}% off)"

class Notification(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notifications')
    title = models.CharField(max_length=100)
    message = models.TextField()
    notification_type = models.CharField(max_length=50, default='system')
    data = models.JSONField(default=dict, blank=True)
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.title} -> {self.user.username}"

class LiveItem(models.Model):
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    price = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)
    image = models.ImageField(upload_to='live_items/', blank=True, null=True)
    is_live = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name

class Wallet(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='wallet')
    balance = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal('0.00'))

    def __str__(self):
        return f"{self.user.username}'s Wallet (${self.balance})"

class WalletTransaction(models.Model):
    wallet = models.ForeignKey(Wallet, on_delete=models.CASCADE, related_name='transactions')
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    transaction_type = models.CharField(max_length=20, choices=[
        ('deposit', 'Deposit'),
        ('withdrawal', 'Withdrawal'),
        ('payment', 'Payment'),
        ('refund', 'Refund')
    ])
    description = models.CharField(max_length=255, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.transaction_type.upper()} ${self.amount} ({self.wallet.user.username})"

class AuditLog(models.Model):
    ACTION_CHOICES = (
        ('ASSIGN_DRIVER', 'Assign Driver'),
        ('CANCEL_ORDER', 'Cancel Order'),
        ('REFUND_PAYMENT', 'Refund Payment'),
        ('TOGGLE_USER_ACTIVE', 'Toggle User Active Status'),
        ('TOGGLE_RESTAURANT', 'Toggle Restaurant Status'),
        ('UPDATE_MENU_ITEM', 'Update Menu Item'),
        ('SYSTEM_CONFIG', 'System Configuration Change'),
    )
    admin_user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='audit_logs')
    action = models.CharField(max_length=50, choices=ACTION_CHOICES)
    target_type = models.CharField(max_length=50)
    target_id = models.CharField(max_length=50)
    details = models.JSONField(default=dict, blank=True)
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-timestamp']

    def __str__(self):
        actor = self.admin_user.username if self.admin_user else 'System'
        return f"[{self.timestamp:%Y-%m-%d %H:%M}] {actor} -> {self.action} on {self.target_type} #{self.target_id}"

class ExchangeRate(models.Model):
    base_currency = models.CharField(max_length=3, default='USD')
    target_currency = models.CharField(max_length=3, default='KHR')
    rate = models.DecimalField(max_digits=12, decimal_places=4, default=Decimal('4100.0000'))
    source = models.CharField(max_length=100, default='National Bank of Cambodia (NBC)')
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('base_currency', 'target_currency')

    def __str__(self):
        return f"1 {self.base_currency} = {self.rate} {self.target_currency} ({self.source})"

