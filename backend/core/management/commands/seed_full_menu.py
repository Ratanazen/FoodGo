from decimal import Decimal
from django.core.management.base import BaseCommand
from core.models import Restaurant, RestaurantCategory, FoodCategory, FoodItem, User

class Command(BaseCommand):
    help = 'Seeds the database with a full, rich food delivery menu across restaurants and categories'

    def handle(self, *args, **options):
        self.stdout.write('Starting menu seeding...')

        # Ensure restaurant categories
        cat_pizza, _ = RestaurantCategory.objects.get_or_create(name='Pizza')
        cat_burger, _ = RestaurantCategory.objects.get_or_create(name='Burger')
        cat_asian, _ = RestaurantCategory.objects.get_or_create(name='Asian & Khmer')
        cat_drinks, _ = RestaurantCategory.objects.get_or_create(name='Drinks & Shakes')

        # 1. Update/Setup Restaurants
        r1 = Restaurant.objects.filter(id=1).first()
        if r1:
            r1.category = cat_burger
            r1.description = 'Phnom Penh finest smashed burgers, hand-crafted sides, and thick shakes.'
            r1.address = 'Street 308, BKK1, Phnom Penh'
            r1.phone = '+855 12 345 678'
            r1.rating = Decimal('4.85')
            r1.delivery_fee = Decimal('1.50')
            r1.save()

        r2 = Restaurant.objects.filter(id=2).first()
        if r2:
            r2.category = cat_pizza
            r2.description = 'Authentic wood-fired Neapolitan pizzas, artisanal cheeses, and classic pastas.'
            r2.address = 'Bassac Lane, Chamkarmon, Phnom Penh'
            r2.phone = '+855 23 987 654'
            r2.rating = Decimal('4.90')
            r2.delivery_fee = Decimal('2.00')
            r2.save()

        r3 = Restaurant.objects.filter(id=3).first()
        if r3:
            r3.name = 'Phnom Penh Flavors (Khmer Kitchen)'
            r3.category = cat_asian
            r3.description = 'Authentic Cambodian home-style recipes, fragrant curries, Lok Lak, and refreshing drinks.'
            r3.address = 'Street 240, Daun Penh, Phnom Penh'
            r3.phone = '+855 96 111 2233'
            r3.rating = Decimal('4.95')
            r3.delivery_fee = Decimal('1.25')
            r3.save()

        # ==========================
        # RESTAURANT 1: Glass Burger
        # ==========================
        if r1:
            fc_sig_burger, _ = FoodCategory.objects.get_or_create(restaurant=r1, name='Signature Burgers')
            fc_sides_burger, _ = FoodCategory.objects.get_or_create(restaurant=r1, name='Fries & Sides')
            fc_drinks_burger, _ = FoodCategory.objects.get_or_create(restaurant=r1, name='Shakes & Refreshers')

            r1_items = [
                (fc_sig_burger, 'Classic Double Smash Cheeseburger', 'Two seasoned smashed beef patties, double American cheddar, caramelized onions, house burger sauce on toasted brioche', '8.99', 'Beef, Cheddar, Brioche, Pickles, House Sauce'),
                (fc_sig_burger, 'Truffle Bacon Swiss Burger', 'Black Angus beef patty, melted Swiss cheese, crispy smoked bacon, sauteed mushrooms, and black truffle aioli', '11.50', 'Angus Beef, Swiss Cheese, Bacon, Truffle Aioli'),
                (fc_sig_burger, 'Crispy Spicy Chicken Burger', 'Crispy buttermilk fried chicken breast, spicy cabbage slaw, pickled jalapenos, and chipotle mayo', '7.99', 'Fried Chicken, Coleslaw, Jalapeno, Chipotle Mayo'),
                (fc_sig_burger, 'Smoky BBQ Bacon Burger', 'Char-grilled beef patty, onion rings, hickory BBQ glaze, aged cheddar, and crispy bacon', '9.99', 'Beef, Onion Rings, BBQ Sauce, Bacon, Cheddar'),
                (fc_sides_burger, 'Golden Truffle Parmesan Fries', 'Crispy skin-on french fries tossed in white truffle oil, sea salt, and grated aged parmesan', '4.50', 'Potatoes, Truffle Oil, Parmesan, Sea Salt'),
                (fc_sides_burger, 'Beer-Battered Onion Rings', 'Thick cut sweet onion rings in golden crunchy batter, served with house ranch', '3.99', 'Sweet Onions, Beer Batter, Ranch Dip'),
                (fc_sides_burger, 'Crispy Mozzarella Sticks', 'Golden fried mozzarella sticks with molten herb center, served with marinara sauce', '4.99', 'Mozzarella, Italian Herbs, Breadcrumbs, Marinara'),
                (fc_drinks_burger, 'Salted Caramel Milkshake', 'Hand-spun vanilla bean ice cream, salted caramel swirl, topped with whipped cream', '4.25', 'Whole Milk, Vanilla Ice Cream, Salted Caramel'),
                (fc_drinks_burger, 'Fresh Mint Craft Lemonade', 'Freshly squeezed lemons with garden mint leaves and pure cane sugar over ice', '2.75', 'Fresh Lemon, Garden Mint, Cane Sugar'),
            ]
            for cat, name, desc, price, ing in r1_items:
                FoodItem.objects.update_or_create(
                    category=cat, name=name,
                    defaults={'description': desc, 'price': Decimal(price), 'ingredients': ing, 'is_available': True}
                )

        # ==========================
        # RESTAURANT 2: Crystal Pizza
        # ==========================
        if r2:
            fc_pizza, _ = FoodCategory.objects.get_or_create(restaurant=r2, name='Artisanal Pizzas')
            fc_pasta, _ = FoodCategory.objects.get_or_create(restaurant=r2, name='Pastas & Italian Mains')
            fc_pizza_sides, _ = FoodCategory.objects.get_or_create(restaurant=r2, name='Appetizers & Desserts')

            r2_items = [
                (fc_pizza, 'Pepperoni Supreme Pizza', 'Crisp crust, San Marzano tomato sauce, fresh mozzarella, double spicy pepperoni, and dried oregano', '14.99', 'Pepperoni, Mozzarella, Tomato Sauce, Oregano'),
                (fc_pizza, 'Quattro Formaggi (4 Cheese)', 'Four cheese blend of gorgonzola, fontina, fresh mozzarella, and parmigiano-reggiano with fresh rosemary', '15.50', 'Mozzarella, Gorgonzola, Fontina, Parmesan, Rosemary'),
                (fc_pizza, 'Margherita Di Bufala', 'Fresh Italian buffalo mozzarella, crushed San Marzano tomatoes, fresh basil leaves, extra virgin olive oil', '12.99', 'Buffalo Mozzarella, San Marzano Tomatoes, Basil, EVOO'),
                (fc_pizza, 'Truffle Wild Mushroom Bianco', 'Roasted cremini mushrooms, garlic white truffle cream, fior di latte mozzarella, and fresh thyme', '16.99', 'Cremini Mushrooms, White Truffle Cream, Mozzarella, Thyme'),
                (fc_pasta, 'Creamy Fettuccine Carbonara', 'Fettuccine pasta with crispy pancetta, farm egg yolk, freshly cracked black pepper, and pecorino romano', '11.99', 'Fettuccine, Pancetta, Egg Yolk, Pecorino Romano'),
                (fc_pasta, 'Penne All Arrabbiata', 'Al dente penne in fiery garlic and chili San Marzano tomato sauce topped with fresh parsley', '9.99', 'Penne, Red Chili, Garlic, Tomato Sauce, Parsley'),
                (fc_pizza_sides, 'Garlic Cheesy Breadsticks', 'Freshly baked breadsticks brushed with garlic herb butter and melted mozzarella, with marinara', '4.99', 'Garlic Butter, Mozzarella, Italian Herbs'),
                (fc_pizza_sides, 'Classic Italian Tiramisu', 'Espresso-soaked Savoiardi ladyfingers layered with whipped mascarpone cream and cocoa powder', '5.50', 'Mascarpone, Espresso, Ladyfingers, Cocoa'),
            ]
            for cat, name, desc, price, ing in r2_items:
                FoodItem.objects.update_or_create(
                    category=cat, name=name,
                    defaults={'description': desc, 'price': Decimal(price), 'ingredients': ing, 'is_available': True}
                )

        # ==========================
        # RESTAURANT 3: Khmer Kitchen
        # ==========================
        if r3:
            fc_khmer_main, _ = FoodCategory.objects.get_or_create(restaurant=r3, name='Khmer Specialties')
            fc_khmer_noodle, _ = FoodCategory.objects.get_or_create(restaurant=r3, name='Noodles & Snacks')
            fc_khmer_drinks, _ = FoodCategory.objects.get_or_create(restaurant=r3, name='Cambodian Drinks')

            r3_items = [
                (fc_khmer_main, 'Kampot Pepper Beef Lok Lak', 'Tender cubes of marinated beef sirloin wok-seared to perfection, served with Kampot pepper lime dip, egg, and jasmine rice', '7.50', 'Beef Sirloin, Kampot Pepper, Lime, Garlic, Jasmine Rice'),
                (fc_khmer_main, 'Bai Sach Chrouk (Grilled Pork Rice)', 'Sliced pork marinated in coconut milk and garlic, slowly char-grilled and served over fragrant broken rice with pickled daikon', '4.50', 'Pork, Coconut Milk, Garlic, Broken Rice, Pickles'),
                (fc_khmer_main, 'Traditional Royal Fish Amok', 'Steamed local snakehead fish fillet in aromatic lemongrass kroeung curry and rich coconut cream, wrapped in banana leaf', '6.99', 'Fish Fillet, Lemongrass Paste, Coconut Cream, Noni Leaf'),
                (fc_khmer_main, 'Khmer Red Chicken Curry (Kari Sach Moan)', 'Fragrant red coconut curry with tender chicken drumsticks, sweet potato, carrots, and warm crusty baguette', '5.99', 'Chicken, Sweet Potato, Coconut Milk, Baguette'),
                (fc_khmer_noodle, 'Num Banh Chok (Khmer Noodles)', 'Silky fermented rice noodles submerged in lemongrass-infused yellow fish gravy, topped with crisp cucumbers and herbs', '4.25', 'Rice Noodles, Fish Gravy, Lemongrass, Herbs'),
                (fc_khmer_noodle, 'Crispy Pork & Taro Spring Rolls', 'Handmade crispy spring rolls filled with seasoned pork, grated taro, and glass noodles with sweet fish sauce dip', '3.50', 'Pork, Taro, Glass Noodles, Sweet Fish Sauce'),
                (fc_khmer_drinks, 'Khmer Iced Milk Coffee (Cafe Teuk Doh Koh)', 'Strong slow-drip Cambodian dark roast coffee mixed with sweetened condensed milk over crushed ice', '2.50', 'Dark Roast Coffee, Condensed Milk, Crushed Ice'),
                (fc_khmer_drinks, 'Sparkling Passion Fruit Soda', 'Fresh local passion fruit pulp with soda water, crushed mint, and natural honey', '2.75', 'Passion Fruit, Soda Water, Mint, Honey'),
            ]
            for cat, name, desc, price, ing in r3_items:
                FoodItem.objects.update_or_create(
                    category=cat, name=name,
                    defaults={'description': desc, 'price': Decimal(price), 'ingredients': ing, 'is_available': True}
                )

        self.stdout.write(self.style.SUCCESS(f'Successfully seeded {FoodItem.objects.count()} food items across {FoodCategory.objects.count()} categories!'))
