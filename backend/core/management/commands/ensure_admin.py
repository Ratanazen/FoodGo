from decimal import Decimal
import os
from django.core.management.base import BaseCommand
from core.models import User, Wallet, Address, Driver

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

        # 3. Delivery Drivers (driver1 and driver2)
        driver1_user = User.objects.filter(username='driver1').first()
        if not driver1_user:
            driver1_user = User.objects.create(
                username='driver1',
                email='driver@foodgo.com',
                first_name='Bob',
                last_name='Rider',
                phone='+855 12 888 999',
                role='driver',
                is_active=True
            )
        else:
            driver1_user.email = 'driver@foodgo.com'
            driver1_user.first_name = 'Bob'
            driver1_user.last_name = 'Rider'
            driver1_user.phone = '+855 12 888 999'
            driver1_user.role = 'driver'
            driver1_user.is_active = True
        driver1_user.set_password('driver123')
        driver1_user.save()

        Driver.objects.update_or_create(
            user=driver1_user,
            defaults={
                'vehicle_type': 'Motorcycle (Honda Wave 125i)',
                'license_plate': 'PP-1AB-2026',
                'is_online': True,
                'current_lat': Decimal('11.5580'),
                'current_lng': Decimal('104.9210'),
            }
        )

        driver2_user = User.objects.filter(username='driver2').first()
        if not driver2_user:
            driver2_user = User.objects.create(
                username='driver2',
                email='driver2@foodgo.com',
                first_name='Sophea',
                last_name='Swift',
                phone='+855 12 777 666',
                role='driver',
                is_active=True
            )
        else:
            driver2_user.email = 'driver2@foodgo.com'
            driver2_user.first_name = 'Sophea'
            driver2_user.last_name = 'Swift'
            driver2_user.phone = '+855 12 777 666'
            driver2_user.role = 'driver'
            driver2_user.is_active = True
        driver2_user.set_password('driver123')
        driver2_user.save()

        Driver.objects.update_or_create(
            user=driver2_user,
            defaults={
                'vehicle_type': 'Scooter (Yamaha Fazzio 125)',
                'license_plate': 'PP-2CD-2026',
                'is_online': True,
                'current_lat': Decimal('11.5610'),
                'current_lng': Decimal('104.9195'),
            }
        )

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
