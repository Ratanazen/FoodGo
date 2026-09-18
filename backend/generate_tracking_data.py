import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from core.models import User, Restaurant, Driver, Delivery, Order, Address, FoodItem, OrderItem
import decimal

# Give restaurants coordinates
r1 = Restaurant.objects.filter(name="Glass Burger").first()
if r1:
    r1.lat = decimal.Decimal("37.774900")
    r1.lng = decimal.Decimal("-122.419400") # SF
    r1.save()

# Create customer and address
customer, _ = User.objects.get_or_create(username='customer1', defaults={'role': 'customer'})
address, _ = Address.objects.get_or_create(user=customer, street="123 Destination", city="SF", state="CA", zip_code="94103", defaults={
    'lat': decimal.Decimal("37.785800"),
    'lng': decimal.Decimal("-122.406400") # A bit away from restaurant
})

# Create driver
driver_user, _ = User.objects.get_or_create(username='driver1', defaults={'role': 'driver'})
driver, _ = Driver.objects.get_or_create(user=driver_user, defaults={
    'vehicle_type': 'Bike', 'license_plate': 'BIKE1', 'is_online': True,
    'current_lat': decimal.Decimal("37.778000"),
    'current_lng': decimal.Decimal("-122.412000") # In between
})

if r1:
    # Create Order
    order, _ = Order.objects.get_or_create(customer=customer, restaurant=r1, status='on_the_way', defaults={
        'address': address,
        'total_amount': decimal.Decimal("15.99")
    })
    if order.items.count() == 0:
        food = FoodItem.objects.first()
        if food:
            OrderItem.objects.create(order=order, food_item=food, quantity=1, price=food.price)
    
    # Create Delivery
    Delivery.objects.get_or_create(order=order, defaults={
        'driver': driver,
        'status': 'on_the_way'
    })

print("Tracking data generated")
