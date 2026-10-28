import os
import io
import logging
from functools import lru_cache
from typing import Optional, Any, Dict, List, Tuple
from pathlib import Path

logger = logging.getLogger(__name__)

_client = None
_gridfs = None


def get_mongo_uri() -> Optional[str]:
    uri = os.environ.get('MONGODB_URI')
    if uri:
        return uri

    # Fallback to local .env file search if not already set in process environment
    base_dir = Path(__file__).resolve().parent.parent
    for candidate in [base_dir / '.env', base_dir.parent / '.env']:
        if candidate.exists():
            try:
                with open(candidate, 'r', encoding='utf-8') as f:
                    for line in f:
                        line = line.strip()
                        if line and not line.startswith('#') and line.startswith('MONGODB_URI='):
                            val = line.split('=', 1)[1].strip().strip('"').strip("'")
                            if val:
                                os.environ['MONGODB_URI'] = val
                                return val
            except Exception:
                pass
    return None


def get_mongo_db_name() -> str:
    return os.environ.get('MONGODB_DB_NAME', 'foodgo')


def get_mongo_client():
    global _client
    if _client is not None:
        return _client

    uri = get_mongo_uri()
    if not uri:
        logger.debug("MONGODB_URI is not configured in environment.")
        return None

    try:
        from pymongo import MongoClient
        _client = MongoClient(
            uri,
            serverSelectionTimeoutMS=5000,
            connectTimeoutMS=5000,
            socketTimeoutMS=int(os.environ.get('MONGO_SOCKET_TIMEOUT_MS', '10000')),
            maxPoolSize=int(os.environ.get('MONGO_MAX_POOL_SIZE', '10')),
            retryWrites=True,
            w='majority'
        )
        return _client
    except Exception as e:
        logger.error(f"Failed to initialize MongoDB client: {e}")
        return None


def get_mongo_db(db_name: Optional[str] = None):
    client = get_mongo_client()
    if client is None:
        return None
    target_db = db_name or get_mongo_db_name()
    return client[target_db]


def get_mongo_gridfs():
    """
    Get or create a GridFS instance on the default database.
    Used for storing and retrieving images and media files.
    """
    global _gridfs
    if _gridfs is not None:
        return _gridfs

    db = get_mongo_db()
    if db is None:
        return None

    try:
        import gridfs
        _gridfs = gridfs.GridFS(db)
        return _gridfs
    except Exception as e:
        logger.error(f"Failed to initialize GridFS: {e}")
        return None


def get_mongo_stats() -> Dict[str, Any]:
    """
    Return collection statistics and document counts in MongoDB Atlas.
    """
    db = get_mongo_db()
    if db is None:
        return {'available': False}

    try:
        colls = db.list_collection_names()
        stats = {
            'available': True,
            'database': get_mongo_db_name(),
            'counts': {
                'orders': db.orders.estimated_document_count() if 'orders' in colls else 0,
                'delivery_tokens': db.delivery_tokens.estimated_document_count() if 'delivery_tokens' in colls else 0,
                'delivery_events': db.delivery_events.estimated_document_count() if 'delivery_events' in colls else 0,
                'restaurants': db.restaurants.estimated_document_count() if 'restaurants' in colls else 0,
                'food_items': db.food_items.estimated_document_count() if 'food_items' in colls else 0,
                'users': db.users.estimated_document_count() if 'users' in colls else 0,
                'user_logins': db.user_logins.estimated_document_count() if 'user_logins' in colls else 0,
                'media_files': db['fs.files'].estimated_document_count() if 'fs.files' in colls else 0,
            }
        }
        return stats
    except Exception as e:
        logger.warning(f"get_mongo_stats error: {e}")
        return {'available': False, 'error': str(e)}


def check_mongo_connection() -> Dict[str, Any]:
    uri = get_mongo_uri()
    if not uri:
        return {
            'status': 'not_configured',
            'connected': False,
            'message': 'MONGODB_URI is not set in environment variables.'
        }

    client = get_mongo_client()
    if client is None:
        return {
            'status': 'error',
            'connected': False,
            'message': 'Failed to instantiate MongoDB client.'
        }

    try:
        client.admin.command('ping')
        db_name = get_mongo_db_name()
        stats = get_mongo_stats()
        return {
            'status': 'connected',
            'connected': True,
            'database': db_name,
            'message': 'MongoDB Atlas cluster connected successfully.',
            'stats': stats.get('counts', {})
        }
    except Exception as e:
        return {
            'status': 'error',
            'connected': False,
            'message': str(e)
        }


# ==============================================================================
# GridFS Image & Media Storage Helpers
# ==============================================================================

def save_image_mongo(filename: str, file_data: Any,
                     content_type: Optional[str] = None,
                     metadata: Optional[Dict[str, Any]] = None) -> Optional[str]:
    """
    Store or update an image/media file in MongoDB Atlas using GridFS.
    `file_data` can be bytes, bytearray, or a file-like object with a .read() method.
    Returns the string ObjectId of the saved file, or None on failure.
    """
    fs = get_mongo_gridfs()
    if fs is None:
        return None

    try:
        # Normalize data into bytes
        if hasattr(file_data, 'read'):
            if hasattr(file_data, 'seek'):
                file_data.seek(0)
            data_bytes = file_data.read()
        elif isinstance(file_data, (bytes, bytearray)):
            data_bytes = bytes(file_data)
        else:
            logger.warning(f"Unsupported file_data type for {filename}: {type(file_data)}")
            return None

        if not content_type:
            import mimetypes
            content_type, _ = mimetypes.guess_type(filename)
            content_type = content_type or 'application/octet-stream'

        # Clean existing files with this exact filename to avoid duplicate versions
        try:
            for existing in fs.find({'filename': filename}):
                fs.delete(existing._id)
        except Exception:
            pass

        from django.utils import timezone
        now = timezone.now().isoformat()
        meta = metadata or {}
        meta.setdefault('uploaded_at', now)
        meta.setdefault('size_bytes', len(data_bytes))

        file_id = fs.put(
            data_bytes,
            filename=filename,
            content_type=content_type,
            metadata=meta
        )
        return str(file_id)
    except Exception as e:
        logger.error(f"save_image_mongo failed for {filename}: {e}")
        return None


def get_image_mongo(filename_or_id: str) -> Optional[Dict[str, Any]]:
    """
    Retrieve an image file from MongoDB Atlas GridFS by filename or string ObjectId.
    Returns a dictionary containing content bytes, content_type, and metadata, or None.
    """
    fs = get_mongo_gridfs()
    if fs is None:
        return None

    try:
        grid_out = None
        # First attempt search by filename
        grid_out = fs.find_one({'filename': filename_or_id})

        # If not found, attempt search by ObjectId
        if grid_out is None:
            from bson.objectid import ObjectId
            if ObjectId.is_valid(filename_or_id):
                try:
                    grid_out = fs.get(ObjectId(filename_or_id))
                except Exception:
                    grid_out = None

        if grid_out is None:
            return None

        content = grid_out.read()
        content_type = getattr(grid_out, 'content_type', None) or 'application/octet-stream'
        metadata = getattr(grid_out, 'metadata', None) or {}

        return {
            'id': str(grid_out._id),
            'filename': grid_out.filename,
            'content': content,
            'content_type': content_type,
            'length': grid_out.length,
            'upload_date': grid_out.upload_date,
            'metadata': metadata
        }
    except Exception as e:
        logger.warning(f"get_image_mongo failed for {filename_or_id}: {e}")
        return None


def delete_image_mongo(filename_or_id: str) -> bool:
    """
    Delete a file from MongoDB Atlas GridFS by filename or string ObjectId.
    """
    fs = get_mongo_gridfs()
    if fs is None:
        return False

    try:
        deleted = False
        from bson.objectid import ObjectId
        if ObjectId.is_valid(filename_or_id):
            try:
                fs.delete(ObjectId(filename_or_id))
                deleted = True
            except Exception:
                pass

        for match in fs.find({'filename': filename_or_id}):
            fs.delete(match._id)
            deleted = True

        return deleted
    except Exception as e:
        logger.warning(f"delete_image_mongo failed for {filename_or_id}: {e}")
        return False


def list_images_mongo(limit: int = 50) -> List[Dict[str, Any]]:
    """
    List stored images and media files in MongoDB Atlas GridFS.
    """
    fs = get_mongo_gridfs()
    if fs is None:
        return []

    try:
        results = []
        for f in fs.find().sort('uploadDate', -1).limit(limit):
            results.append({
                'id': str(f._id),
                'filename': f.filename,
                'content_type': getattr(f, 'content_type', 'application/octet-stream'),
                'length': f.length,
                'upload_date': f.upload_date.isoformat() if hasattr(f.upload_date, 'isoformat') else str(f.upload_date),
                'metadata': getattr(f, 'metadata', {})
            })
        return results
    except Exception as e:
        logger.warning(f"list_images_mongo failed: {e}")
        return []


# ==============================================================================
# Document Archival & Syncing ("Other Data")
# ==============================================================================

def save_order_mongo(order_obj: Any) -> bool:
    """
    Save or mirror a full Order document to MongoDB Atlas orders collection.
    Accepts an Order Django model instance or an order dict.
    """
    db = get_mongo_db()
    if db is None:
        return False

    try:
        from django.utils import timezone
        now = timezone.now().isoformat()

        if hasattr(order_obj, 'id'):
            order_id = order_obj.id
            order_ref = getattr(order_obj, 'order_reference', f"#{order_id}")
            customer = getattr(order_obj, 'customer', None)
            restaurant = getattr(order_obj, 'restaurant', None)

            items_list = []
            if hasattr(order_obj, 'items'):
                for item in order_obj.items.all():
                    name = getattr(item, 'food_name_snapshot', '') or (item.food_item.name if getattr(item, 'food_item', None) else 'Item')
                    items_list.append({
                        'food_id': getattr(item, 'food_item_id', None),
                        'name': name,
                        'quantity': item.quantity,
                        'price': float(item.price) if getattr(item, 'price', None) is not None else 0.0
                    })

            driver_info = None
            if hasattr(order_obj, 'delivery') and order_obj.delivery and order_obj.delivery.driver:
                d = order_obj.delivery.driver
                driver_info = {
                    'driver_id': d.id,
                    'user_id': d.user_id,
                    'name': d.user.get_full_name() or d.user.username,
                    'phone': getattr(d.user, 'phone', ''),
                    'vehicle_type': d.vehicle_type
                }

            doc = {
                'order_id': order_id,
                'order_reference': order_ref,
                'customer': {
                    'id': customer.id if customer else None,
                    'username': customer.username if customer else 'Anonymous',
                    'email': customer.email if customer else '',
                    'phone': getattr(customer, 'phone', '') if customer else ''
                },
                'restaurant': {
                    'id': restaurant.id if restaurant else None,
                    'name': restaurant.name if restaurant else 'Unknown'
                },
                'status': getattr(order_obj, 'status', 'pending'),
                'payment_status': getattr(order_obj, 'payment_status', 'UNPAID'),
                'total_amount': float(order_obj.total_amount) if getattr(order_obj, 'total_amount', None) is not None else 0.0,
                'subtotal': float(order_obj.subtotal) if getattr(order_obj, 'subtotal', None) is not None else 0.0,
                'delivery_fee': float(order_obj.delivery_fee_charged) if getattr(order_obj, 'delivery_fee_charged', None) is not None else 0.0,
                'special_instructions': getattr(order_obj, 'special_instructions', ''),
                'items': items_list,
                'driver': driver_info,
                'created_at': order_obj.created_at.isoformat() if hasattr(order_obj, 'created_at') and order_obj.created_at else now,
                'updated_at': now
            }
        elif isinstance(order_obj, dict):
            doc = dict(order_obj)
            order_id = doc.get('order_id') or doc.get('id')
            if not order_id:
                return False
            doc['order_id'] = order_id
            doc.setdefault('updated_at', now)
        else:
            return False

        db.orders.update_one(
            {'order_id': order_id},
            {'$set': doc},
            upsert=True
        )
        return True
    except Exception as e:
        logger.warning(f"save_order_mongo failed for order {getattr(order_obj, 'id', None)}: {e}")
        return False


def get_order_mongo(order_id: int) -> Optional[Dict[str, Any]]:
    """
    Retrieve an order document from MongoDB Atlas by order_id.
    """
    db = get_mongo_db()
    if db is None:
        return None

    try:
        doc = db.orders.find_one({'order_id': order_id})
        if doc and '_id' in doc:
            doc['_id'] = str(doc['_id'])
        return doc
    except Exception as e:
        logger.warning(f"get_order_mongo failed for {order_id}: {e}")
        return None


def sync_catalog_to_mongo() -> Dict[str, int]:
    """
    Mirror restaurants, food categories, and food items from relational DB into MongoDB Atlas.
    """
    db = get_mongo_db()
    if db is None:
        return {'restaurants': 0, 'food_items': 0}

    counts = {'restaurants': 0, 'food_items': 0}
    try:
        from core.models import Restaurant, FoodItem

        # Sync Restaurants
        for r in Restaurant.objects.all():
            owner_email = r.owner.email if getattr(r, 'owner', None) and hasattr(r.owner, 'email') else ''
            logo_url = r.logo.url if getattr(r, 'logo', None) else ''
            banner_url = r.banner.url if getattr(r, 'banner', None) else ''
            r_doc = {
                'restaurant_id': r.id,
                'name': r.name,
                'address': r.address,
                'phone': r.phone,
                'email': owner_email,
                'logo_url': logo_url,
                'banner_url': banner_url,
                'rating': float(r.rating) if r.rating is not None else 0.0,
                'is_active': r.is_active,
                'delivery_fee': float(r.delivery_fee) if r.delivery_fee is not None else 0.0
            }
            db.restaurants.update_one({'restaurant_id': r.id}, {'$set': r_doc}, upsert=True)
            counts['restaurants'] += 1

        # Sync Food Items
        for item in FoodItem.objects.select_related('category').all():
            rest_id = item.category.restaurant_id if item.category else None
            f_doc = {
                'food_item_id': item.id,
                'category_id': item.category_id,
                'restaurant_id': rest_id,
                'name': item.name,
                'description': item.description,
                'price': float(item.price) if item.price is not None else 0.0,
                'is_available': item.is_available,
                'image_url': item.image_url or (item.image.url if item.image else '')
            }
            db.food_items.update_one({'food_item_id': item.id}, {'$set': f_doc}, upsert=True)
            counts['food_items'] += 1

        return counts
    except Exception as e:
        logger.error(f"sync_catalog_to_mongo error: {e}")
        return counts


def save_delivery_token_mongo(order_id: int, order_reference: str, token_hash: str,
                              driver_id: Optional[int], customer_id: Optional[int],
                              expires_at: Any, status: str = 'ACTIVE') -> bool:
    """
    Store or update delivery token hash and metadata in MongoDB Atlas.
    """
    db = get_mongo_db()
    if db is None:
        return False
    try:
        from django.utils import timezone
        now = timezone.now()
        exp_dt = expires_at if hasattr(expires_at, 'isoformat') else str(expires_at)
        db.delivery_tokens.update_one(
            {'order_id': order_id},
            {
                '$set': {
                    'order_id': order_id,
                    'order_reference': order_reference,
                    'token_hash': token_hash,
                    'driver_id': driver_id,
                    'customer_id': customer_id,
                    'status': status,
                    'expires_at': exp_dt,
                    'updated_at': now.isoformat()
                },
                '$setOnInsert': {
                    'created_at': now.isoformat(),
                    'rotation_count': 0
                }
            },
            upsert=True
        )
        # Also sync token status and hash to orders collection
        db.orders.update_one(
            {'order_id': order_id},
            {
                '$set': {
                    'delivery_token_hash': token_hash,
                    'delivery_token_status': status,
                    'delivery_token_expires_at': exp_dt,
                    'updated_at': now.isoformat()
                }
            },
            upsert=False
        )
        return True
    except Exception as e:
        logger.warning(f"save_delivery_token_mongo failed: {e}")
        return False


def confirm_delivery_token_mongo(order_id: int, token_hash: str, driver_id: Optional[int],
                                 confirmed_by_id: Optional[int], confirmed_by_role: str,
                                 completed_at: Any = None, notes: str = '') -> bool:
    """
    Atomically confirm delivery token in MongoDB Atlas.
    Returns True if token matched ACTIVE status and was marked USED.
    """
    db = get_mongo_db()
    if db is None:
        return True  # If MongoDB not configured, let relational DB guarantee atomicity
    try:
        from django.utils import timezone
        now = timezone.now()
        comp_time = completed_at.isoformat() if hasattr(completed_at, 'isoformat') else (completed_at or now.isoformat())

        res = db.delivery_tokens.update_one(
            {
                'order_id': order_id,
                'token_hash': token_hash,
                'status': 'ACTIVE'
            },
            {
                '$set': {
                    'status': 'USED',
                    'completed_at': comp_time,
                    'confirmed_by_id': confirmed_by_id,
                    'confirmed_by_role': confirmed_by_role,
                    'notes': notes,
                    'updated_at': now.isoformat()
                }
            }
        )

        # Update order collection status
        db.orders.update_one(
            {'order_id': order_id},
            {
                '$set': {
                    'status': 'delivered',
                    'delivery_status': 'delivered',
                    'delivery_token_status': 'USED',
                    'delivered_at': comp_time,
                    'delivered_by_driver_id': driver_id,
                    'updated_at': now.isoformat()
                }
            }
        )

        # Record audit event
        record_delivery_event_mongo(
            order_id=order_id,
            event_type='DELIVERY_CONFIRMED',
            actor_id=confirmed_by_id,
            actor_role=confirmed_by_role,
            metadata={
                'driver_id': driver_id,
                'token_hash': token_hash,
                'notes': notes,
                'completed_at': comp_time
            }
        )
        return res.matched_count > 0
    except Exception as e:
        logger.warning(f"confirm_delivery_token_mongo failed: {e}")
        return False


def record_delivery_event_mongo(order_id: int, event_type: str, actor_id: Optional[int],
                                actor_role: str, metadata: Optional[Dict[str, Any]] = None) -> bool:
    """
    Append delivery audit event to MongoDB Atlas delivery_events collection.
    """
    db = get_mongo_db()
    if db is None:
        return False
    try:
        from django.utils import timezone
        now = timezone.now()
        event_doc = {
            'order_id': order_id,
            'event_type': event_type,
            'actor_id': actor_id,
            'actor_role': actor_role,
            'metadata': metadata or {},
            'timestamp': now.isoformat()
        }
        db.delivery_events.insert_one(event_doc)
        return True
    except Exception as e:
        logger.warning(f"record_delivery_event_mongo failed: {e}")
        return False


# ==============================================================================
# User Accounts & Login Activity Helpers
# ==============================================================================

def save_user_mongo(user: Any) -> bool:
    """
    Save or update a user account in MongoDB Atlas `users` collection.
    Accepts a User model instance or a user dictionary.
    Safe against missing attributes and handles related addresses safely.
    """
    db = get_mongo_db()
    if db is None:
        return False

    try:
        from django.utils import timezone
        now = timezone.now()

        if hasattr(user, 'id'):
            # It's a Django User model instance
            avatar_url = getattr(user, 'avatar_url', None) or ''
            if not avatar_url and getattr(user, 'avatar', None):
                try:
                    avatar_url = user.avatar.url
                except Exception:
                    avatar_url = ''

            # Try to get default address
            default_address = None
            try:
                addr = user.addresses.filter(is_default=True).first() or user.addresses.first()
                if addr:
                    default_address = {
                        'id': addr.id,
                        'street': addr.street,
                        'city': addr.city,
                        'state': addr.state,
                        'label': addr.label,
                        'lat': float(addr.lat) if addr.lat is not None else None,
                        'lng': float(addr.lng) if addr.lng is not None else None,
                    }
            except Exception:
                pass

            user_doc = {
                'user_id': user.id,
                'username': user.username,
                'email': user.email or '',
                'first_name': user.first_name or '',
                'last_name': user.last_name or '',
                'full_name': f"{user.first_name or ''} {user.last_name or ''}".strip() or user.username,
                'role': getattr(user, 'role', 'customer'),
                'phone': getattr(user, 'phone', '') or '',
                'phone_normalized': getattr(user, 'phone_normalized', '') or '',
                'is_phone_verified': bool(getattr(user, 'is_phone_verified', False)),
                'phone_verified_at': user.phone_verified_at.isoformat() if getattr(user, 'phone_verified_at', None) else None,
                'avatar_url': avatar_url,
                'is_active': bool(user.is_active),
                'is_staff': bool(user.is_staff),
                'is_superuser': bool(user.is_superuser),
                'date_joined': user.date_joined.isoformat() if getattr(user, 'date_joined', None) else None,
                'last_login': user.last_login.isoformat() if getattr(user, 'last_login', None) else None,
                'updated_at': now.isoformat(),
            }
            if default_address:
                user_doc['default_address'] = default_address
            user_id = user.id
        elif isinstance(user, dict):
            user_id = user.get('user_id') or user.get('id')
            if not user_id:
                return False
            user_doc = dict(user)
            user_doc['user_id'] = user_id
            user_doc['updated_at'] = now.isoformat()
        else:
            return False

        # Upsert user document
        db.users.update_one(
            {'user_id': user_id},
            {
                '$set': user_doc,
                '$setOnInsert': {
                    'created_at': now.isoformat(),
                    'login_count': 0
                }
            },
            upsert=True
        )
        return True
    except Exception as e:
        logger.warning(f"save_user_mongo failed for user {getattr(user, 'id', user)}: {e}")
        return False


def get_user_mongo(user_id: int) -> Optional[Dict[str, Any]]:
    """Fetch user document from MongoDB Atlas `users` collection."""
    db = get_mongo_db()
    if db is None:
        return None
    try:
        doc = db.users.find_one({'user_id': user_id}, {'_id': 0})
        return doc
    except Exception as e:
        logger.warning(f"get_user_mongo failed for user #{user_id}: {e}")
        return None


def record_user_login_mongo(user: Any, login_method: str = 'jwt_password',
                            ip_address: Optional[str] = None,
                            user_agent: Optional[str] = None,
                            extra_data: Optional[Dict[str, Any]] = None) -> bool:
    """
    Record an authentication/login event in MongoDB Atlas `user_logins` collection
    and update login stats in `users` collection.
    """
    db = get_mongo_db()
    if db is None:
        return False

    try:
        from django.utils import timezone
        now = timezone.now()

        if hasattr(user, 'id'):
            user_id = user.id
            username = user.username
            email = getattr(user, 'email', '') or ''
            role = getattr(user, 'role', 'customer')
            phone = getattr(user, 'phone', '') or ''
        elif isinstance(user, dict):
            user_id = user.get('user_id') or user.get('id')
            username = user.get('username', '')
            email = user.get('email', '')
            role = user.get('role', 'customer')
            phone = user.get('phone', '')
        else:
            return False

        if not user_id:
            return False

        login_doc = {
            'user_id': user_id,
            'username': username,
            'email': email,
            'role': role,
            'phone': phone,
            'login_method': login_method,
            'ip_address': ip_address or '',
            'user_agent': user_agent or '',
            'timestamp': now.isoformat(),
            'status': 'SUCCESS',
            'extra_data': extra_data or {}
        }

        # 1. Append audit trail in user_logins
        db.user_logins.insert_one(login_doc)

        # 2. Update user doc with latest login info and increment login_count
        db.users.update_one(
            {'user_id': user_id},
            {
                '$set': {
                    'last_login_at': now.isoformat(),
                    'last_login_method': login_method,
                    'last_login_ip': ip_address or '',
                    'last_login_user_agent': user_agent or '',
                    'updated_at': now.isoformat(),
                },
                '$inc': {'login_count': 1}
            },
            upsert=True
        )

        return True
    except Exception as e:
        logger.warning(f"record_user_login_mongo failed for user {getattr(user, 'id', user)}: {e}")
        return False


def get_user_logins_mongo(user_id: int, limit: int = 20) -> List[Dict[str, Any]]:
    """Fetch recent login history for a user from MongoDB Atlas `user_logins` collection."""
    db = get_mongo_db()
    if db is None:
        return []
    try:
        cursor = db.user_logins.find(
            {'user_id': user_id},
            {'_id': 0}
        ).sort('timestamp', -1).limit(limit)
        return list(cursor)
    except Exception as e:
        logger.warning(f"get_user_logins_mongo failed for user #{user_id}: {e}")
        return []


def sync_all_users_to_mongo() -> Dict[str, Any]:
    """
    Backfill all PostgreSQL users to MongoDB Atlas `users` collection.
    Returns summary dict of total and successfully synced users.
    """
    db = get_mongo_db()
    if db is None:
        return {'total': 0, 'synced': 0, 'failed': 0, 'status': 'no_mongo'}

    try:
        from .models import User as UserModel
        users = UserModel.objects.all().prefetch_related('addresses')
        total = users.count()
        synced = 0
        failed = 0
        for u in users:
            if save_user_mongo(u):
                synced += 1
            else:
                failed += 1
        return {'total': total, 'synced': synced, 'failed': failed, 'status': 'success'}
    except Exception as e:
        logger.warning(f"sync_all_users_to_mongo failed: {e}")
        return {'total': 0, 'synced': 0, 'failed': 0, 'error': str(e)}


