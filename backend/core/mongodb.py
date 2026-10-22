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
