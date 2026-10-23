import os
import logging
from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Order, FoodItem, Restaurant, User
from .mongodb import save_order_mongo, save_image_mongo, get_mongo_db

logger = logging.getLogger(__name__)

@receiver(post_save, sender=Order)
def sync_order_to_mongo(sender, instance, **kwargs):
    """
    Automatically sync order state and details to MongoDB Atlas on save.
    """
    try:
        save_order_mongo(instance)
    except Exception as e:
        logger.warning(f"Failed to auto-sync order #{instance.id} to MongoDB: {e}")

@receiver(post_save, sender=Restaurant)
def sync_restaurant_to_mongo(sender, instance, **kwargs):
    """
    Sync restaurant and its media assets to MongoDB Atlas on save.
    """
    try:
        db = get_mongo_db()
        if db is not None:
            owner_email = instance.owner.email if getattr(instance, 'owner', None) and hasattr(instance.owner, 'email') else ''
            logo_url = instance.logo.url if getattr(instance, 'logo', None) else ''
            banner_url = instance.banner.url if getattr(instance, 'banner', None) else ''
            r_doc = {
                'restaurant_id': instance.id,
                'name': instance.name,
                'address': instance.address,
                'phone': instance.phone,
                'email': owner_email,
                'logo_url': logo_url,
                'banner_url': banner_url,
                'rating': float(instance.rating) if instance.rating is not None else 0.0,
                'is_active': instance.is_active,
                'delivery_fee': float(instance.delivery_fee) if instance.delivery_fee is not None else 0.0
            }
            db.restaurants.update_one({'restaurant_id': instance.id}, {'$set': r_doc}, upsert=True)

            if instance.logo and hasattr(instance.logo, 'file'):
                try:
                    save_image_mongo(instance.logo.name, instance.logo.file, metadata={'type': 'restaurant_logo'})
                except Exception:
                    pass
    except Exception as e:
        logger.warning(f"Failed to auto-sync restaurant #{instance.id} to MongoDB: {e}")

@receiver(post_save, sender=FoodItem)
def sync_food_item_to_mongo(sender, instance, **kwargs):
    """
    Sync food item and picture to MongoDB Atlas on save.
    """
    try:
        db = get_mongo_db()
        if db is not None:
            rest_id = instance.category.restaurant_id if instance.category else None
            f_doc = {
                'food_item_id': instance.id,
                'category_id': instance.category_id,
                'restaurant_id': rest_id,
                'name': instance.name,
                'description': instance.description,
                'price': float(instance.price) if instance.price is not None else 0.0,
                'is_available': instance.is_available,
                'image_url': instance.image_url or (instance.image.url if instance.image else '')
            }
            db.food_items.update_one({'food_item_id': instance.id}, {'$set': f_doc}, upsert=True)

            if instance.image and hasattr(instance.image, 'file'):
                try:
                    save_image_mongo(instance.image.name, instance.image.file, metadata={'type': 'food_image'})
                except Exception:
                    pass
    except Exception as e:
        logger.warning(f"Failed to auto-sync food item #{instance.id} to MongoDB: {e}")

@receiver(post_save, sender=User)
def sync_user_avatar_to_mongo(sender, instance, **kwargs):
    """
    Mirror user profile avatar to MongoDB Atlas GridFS on save.
    """
    try:
        if instance.avatar and hasattr(instance.avatar, 'file'):
            try:
                save_image_mongo(instance.avatar.name, instance.avatar.file, metadata={'type': 'user_avatar', 'user_id': instance.id})
            except Exception:
                pass
    except Exception as e:
        logger.warning(f"Failed to auto-sync avatar for user #{instance.id} to MongoDB: {e}")
