import os
import logging
from functools import lru_cache
from typing import Optional, Any, Dict

logger = logging.getLogger(__name__)

_client = None

def get_mongo_uri() -> Optional[str]:
    return os.environ.get('MONGODB_URI')

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
        return {
            'status': 'connected',
            'connected': True,
            'database': db_name,
            'message': 'MongoDB Atlas cluster connected successfully.'
        }
    except Exception as e:
        return {
            'status': 'error',
            'connected': False,
            'message': str(e)
        }


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

