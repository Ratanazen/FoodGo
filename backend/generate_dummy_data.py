import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from core.models import User, Restaurant, FoodCategory, FoodItem
import decimal

owner2, _ = User.objects.get_or_create(username='owner2', defaults={'role': 'restaurant_owner'})

if Restaurant.objects.count() == 1:
    r2 = Restaurant.objects.create(
        owner=owner2, name="Crystal Pizza", description="Authentic crystal crust", 
        address="456 Crystal Ave", rating=4.5, delivery_time_min=20, delivery_time_max=45,
        delivery_fee=decimal.Decimal("3.99"), is_active=True
    )
    
    cat2 = FoodCategory.objects.create(restaurant=r2, name="Pizzas")
    FoodItem.objects.create(category=cat2, name="Pepperoni", description="Pepperoni", price=decimal.Decimal("14.99"), is_available=True)

print("Data generated")
