from decimal import Decimal
import os
from django.core.management.base import BaseCommand
from core.models import User, Wallet, Address

class Command(BaseCommand):
    help = 'Ensures admin, customer, driver, and owner accounts exist with working passwords'

    def handle(self, *args, **options):
        # 1. Admin Superuser
        admin_username = os.environ.get('DJANGO_SUPERUSER_USERNAME', 'admin')
        admin_password = os.environ.get('DJANGO_SUPERUSER_PASSWORD', 'admin123')
        admin_email = os.environ.get('DJANGO_SUPERUSER_EMAIL', 'admin@foodgo.com')

        admin_user = User.objects.filter(username=admin_username).first()
        if not admin_user:
            admin_user = User.objects.create(
                username=admin_username,
                email=admin_email,
                role='admin',
                is_staff=True,
                is_superuser=True,
                is_active=True
            )
            self.stdout.write(f"Created admin user: {admin_username}")
        else:
            admin_user.is_staff = True
            admin_user.is_superuser = True
            admin_user.is_active = True
            admin_user.role = 'admin'
            if not admin_user.email:
                admin_user.email = admin_email
            self.stdout.write(f"Updated existing admin user: {admin_username}")

        admin_user.set_password(admin_password)
        admin_user.save()

        # 2. Customer User
        cust_user = User.objects.filter(username='customer1').first()
        if not cust_user:
            cust_user = User.objects.create(
                username='customer1',
                email='customer@foodgo.com',
                first_name='Alice',
                last_name='Smith',
                role='customer',
                is_active=True
            )
            self.stdout.write("Created customer1 user")
        else:
            cust_user.email = 'customer@foodgo.com'
            cust_user.role = 'customer'
            cust_user.is_active = True
            self.stdout.write("Updated customer1 user")

        cust_user.set_password('customer123')
        cust_user.save()

        # Ensure customer wallet
        wallet, _ = Wallet.objects.get_or_create(user=cust_user, defaults={'balance': Decimal('100.00')})
        if wallet.balance < Decimal('10.00'):
            wallet.balance = Decimal('100.00')
            wallet.save()

        # Ensure customer address
        Address.objects.get_or_create(
            user=cust_user,
            defaults={
                'street': 'Street 308, Tonle Bassac',
                'city': 'Phnom Penh',
                'state': 'Phnom Penh',
                'zip_code': '120101',
                'lat': Decimal('11.550500'),
                'lng': Decimal('104.928000'),
                'is_default': True
            }
        )

        # 3. Driver User
        driver_user = User.objects.filter(username='driver1').first()
        if not driver_user:
            driver_user = User.objects.create(
                username='driver1',
                email='driver@foodgo.com',
                first_name='Bob',
                last_name='Rider',
                role='driver',
                is_active=True
            )
        else:
            driver_user.email = 'driver@foodgo.com'
            driver_user.role = 'driver'
            driver_user.is_active = True
        driver_user.set_password('driver123')
        driver_user.save()

        # 4. Owner User
        owner_user = User.objects.filter(username='owner').first()
        if not owner_user:
            owner_user = User.objects.create(
                username='owner',
                email='owner@foodgo.com',
                role='restaurant_owner',
                is_active=True
            )
        else:
            owner_user.email = 'owner@foodgo.com'
            owner_user.role = 'restaurant_owner'
            owner_user.is_active = True
        owner_user.set_password('owner123')
        owner_user.save()

        self.stdout.write(self.style.SUCCESS("All authentication accounts verified successfully!"))
