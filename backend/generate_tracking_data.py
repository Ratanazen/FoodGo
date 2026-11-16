import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from core.models import User, Restaurant, Driver, Delivery, Order, Address, FoodItem, OrderItem
import decimal

# Give restaurants coordinates in Phnom Penh, Cambodia
r1 = Restaurant.objects.filter(name="Glass Burger").first()
if r1:
    r1.lat = decimal.Decimal("11.552900")
    r1.lng = decimal.Decimal("104.925400") # BKK1, Phnom Penh
    r1.save()

# Create customer and address in Phnom Penh
customer, _ = User.objects.get_or_create(username='customer1', defaults={'role': 'customer'})
address, _ = Address.objects.get_or_create(user=customer, street="Norodom Blvd, Daun Penh", city="Phnom Penh", state="Phnom Penh", zip_code="12000", defaults={
    'lat': decimal.Decimal("11.564500"),
    'lng': decimal.Decimal("104.932800") # Royal Palace / Daun Penh
})

# Create driver in Phnom Penh
driver_user, _ = User.objects.get_or_create(username='driver1', defaults={'role': 'driver'})
driver, _ = Driver.objects.get_or_create(user=driver_user, defaults={
    'vehicle_type': 'Motorcycle (Honda Wave 125i)', 'license_plate': 'PP-2026', 'is_online': True,
    'current_lat': decimal.Decimal("11.556400"),
    'current_lng': decimal.Decimal("104.928200") # Independence Monument
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
