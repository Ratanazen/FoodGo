"""
WSGI config for config project.

It exposes the WSGI callable as a module-level variable named ``application``.

For more information on this file, see
https://docs.djangoproject.com/en/6.1/howto/deployment/wsgi/
"""

import os
import sys
from pathlib import Path

# Ensure backend root is on sys.path for serverless deployment
CURRENT_DIR = Path(__file__).resolve().parent
BACKEND_DIR = CURRENT_DIR.parent
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

from django.core.wsgi import get_wsgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')

application = get_wsgi_application()
app = application

# Vercel serverless cold-start initialization
# Gated behind AUTO_MIGRATE to avoid 5-15s cold start penalty.
# Migrations should be run during deployment (start.sh / deploy hook), not on every cold start.
if 'VERCEL' in os.environ:
    try:
        from django.core.management import call_command
        from django.db import connection
        _tables = connection.introspection.table_names()
        if 'core_user' not in _tables:
            call_command('migrate', interactive=False)
            call_command('ensure_admin')
            call_command('seed_full_menu')
        else:
            from core.models import FoodItem
            if not FoodItem.objects.exists():
                call_command('ensure_admin')
                call_command('seed_full_menu')
            elif os.environ.get('AUTO_MIGRATE', 'false').lower() in ('true', '1', 'yes'):
                call_command('migrate', interactive=False)
                call_command('ensure_admin')
    except Exception as _e:
        print(f"Vercel auto-init note: {_e}")
