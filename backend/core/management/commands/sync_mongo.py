import os
import mimetypes
from pathlib import Path
from django.core.management.base import BaseCommand
from django.conf import settings
from core.models import Order, Restaurant, FoodItem, User
from core.mongodb import (
    save_order_mongo,
    sync_catalog_to_mongo,
    save_image_mongo,
    get_mongo_stats,
    check_mongo_connection
)

class Command(BaseCommand):
    help = "Synchronize local media images, catalog items, and orders to MongoDB Atlas."

    def add_arguments(self, parser):
        parser.add_argument(
            '--include-media',
            action='store_true',
            help='Also scan MEDIA_ROOT and upload all existing media files to MongoDB Atlas GridFS.',
        )

    def handle(self, *args, **options):
        self.stdout.write(self.style.NOTICE("Testing connection to MongoDB Atlas..."))
        conn = check_mongo_connection()
        if not conn.get('connected'):
            self.stdout.write(self.style.ERROR(f"Connection failed: {conn.get('message')}"))
            return

        self.stdout.write(self.style.SUCCESS(f"Connected to database: {conn.get('database')}"))

        # 1. Sync Catalog (Restaurants & Food Items)
        self.stdout.write("Syncing catalog to MongoDB Atlas...")
        cat_res = sync_catalog_to_mongo()
        self.stdout.write(self.style.SUCCESS(
            f"Catalog synced: {cat_res.get('restaurants', 0)} restaurants, {cat_res.get('food_items', 0)} food items."
        ))

        # 2. Sync Orders
        self.stdout.write("Syncing orders to MongoDB Atlas...")
        orders = Order.objects.all()
        synced_orders = 0
        for order in orders:
            if save_order_mongo(order):
                synced_orders += 1
        self.stdout.write(self.style.SUCCESS(f"Orders synced: {synced_orders}/{orders.count()} orders."))

        # 3. Optional: Sync Media Images
        media_count = 0
        if options.get('include_media'):
            media_root = Path(settings.MEDIA_ROOT)
            self.stdout.write(f"Scanning media directory: {media_root}...")
            if media_root.exists():
                for file_path in media_root.rglob('*'):
                    if file_path.is_file():
                        rel_name = str(file_path.relative_to(media_root)).replace('\\', '/')
                        content_type, _ = mimetypes.guess_type(str(file_path))
                        content_type = content_type or 'application/octet-stream'
                        try:
                            with open(file_path, 'rb') as f:
                                data = f.read()
                            fid = save_image_mongo(
                                filename=rel_name,
                                file_data=data,
                                content_type=content_type,
                                metadata={'source': 'sync_mongo_command'}
                            )
                            if fid:
                                media_count += 1
                        except Exception as e:
                            self.stdout.write(self.style.WARNING(f"Failed to upload {rel_name}: {e}"))
            self.stdout.write(self.style.SUCCESS(f"Media images synced: {media_count} files stored in MongoDB GridFS."))

        # 4. Final Telemetry Stats
        stats = get_mongo_stats()
        self.stdout.write(self.style.SUCCESS(f"MongoDB Atlas updated counts: {stats.get('counts')}"))
