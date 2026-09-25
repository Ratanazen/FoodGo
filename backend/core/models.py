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

class Address(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='addresses')
    street = models.CharField(max_length=255)
    city = models.CharField(max_length=100)
    state = models.CharField(max_length=100)
    zip_code = models.CharField(max_length=20)
    is_default = models.BooleanField(default=False)
    lat = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    lng = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)

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

    def __str__(self):
        return f"{self.name} - ${self.price}"

class Order(models.Model):
    STATUS_CHOICES = (
        ('pending', 'Pending'),
        ('confirmed', 'Confirmed'),
        ('preparing', 'Preparing'),
        ('ready', 'Ready for Pickup'),
        ('picked_up', 'Picked Up'),
        ('on_the_way', 'On the Way'),
        ('delivered', 'Delivered'),
        ('cancelled', 'Cancelled')
    )
    PAYMENT_STATUS_CHOICES = (
        ('UNPAID', 'Unpaid'),
        ('PENDING', 'Pending'),
        ('PAID', 'Paid'),
        ('FAILED', 'Failed'),
        ('REFUNDED', 'Refunded'),
    )
    customer = models.ForeignKey(User, on_delete=models.CASCADE, related_name='orders')
    restaurant = models.ForeignKey(Restaurant, on_delete=models.CASCADE, related_name='orders')
    address = models.ForeignKey(Address, on_delete=models.SET_NULL, null=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    payment_status = models.CharField(max_length=20, choices=PAYMENT_STATUS_CHOICES, default='UNPAID')
    total_amount = models.DecimalField(max_digits=10, decimal_places=2)
    special_instructions = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Order #{self.id} - {self.customer.username} (${self.total_amount})"

class OrderItem(models.Model):
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name='items')
    food_item = models.ForeignKey(FoodItem, on_delete=models.SET_NULL, null=True)
    quantity = models.IntegerField(default=1)
    price = models.DecimalField(max_digits=8, decimal_places=2)

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
    current_lat = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    current_lng = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)

    def __str__(self):
        return f"Driver: {self.user.username} ({self.vehicle_type})"

class Delivery(models.Model):
    order = models.OneToOneField(Order, on_delete=models.CASCADE, related_name='delivery')
    driver = models.ForeignKey(Driver, on_delete=models.SET_NULL, null=True, blank=True, related_name='deliveries')
    pickup_time = models.DateTimeField(null=True, blank=True)
    delivery_time = models.DateTimeField(null=True, blank=True)
    status = models.CharField(max_length=20, default='assigned')

    class Meta:
        verbose_name_plural = 'Deliveries'

    def __str__(self):
        return f"Delivery for Order #{self.order_id} ({self.status})"

class Review(models.Model):
    order = models.OneToOneField(Order, on_delete=models.CASCADE, related_name='review')
    rating = models.IntegerField(default=5)
    comment = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Review for Order #{self.order_id}: {self.rating}★"

class Favorite(models.Model):
    customer = models.ForeignKey(User, on_delete=models.CASCADE, related_name='favorites')
    restaurant = models.ForeignKey(Restaurant, on_delete=models.CASCADE)

    def __str__(self):
        return f"{self.customer.username} - {self.restaurant.name}"
    
class Coupon(models.Model):
    code = models.CharField(max_length=20, unique=True)
    discount_percent = models.IntegerField()
    is_active = models.BooleanField(default=True)

    def __str__(self):
        return f"{self.code} ({self.discount_percent}% off)"

class Notification(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notifications')
    title = models.CharField(max_length=100)
    message = models.TextField()
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

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
