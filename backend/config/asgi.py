import os
import sys
from pathlib import Path

# Ensure backend root is on sys.path for serverless deployment
CURRENT_DIR = Path(__file__).resolve().parent
BACKEND_DIR = CURRENT_DIR.parent
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

from django.core.asgi import get_asgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django_asgi_app = get_asgi_application()

from channels.routing import ProtocolTypeRouter, URLRouter
from channels.auth import AuthMiddlewareStack
import core.routing

application = ProtocolTypeRouter({
    "http": django_asgi_app,
    "websocket": AuthMiddlewareStack(
        URLRouter(
            core.routing.websocket_urlpatterns
        )
    ),
})
app = application

# Vercel serverless cold-start initialization
if 'VERCEL' in os.environ:
    try:
        from django.core.management import call_command
        from django.db import connection
        _tables = connection.introspection.table_names()
        if 'core_user' not in _tables:
            call_command('migrate', interactive=False)
            call_command('ensure_admin')
            call_command('seed_full_menu')
        elif os.environ.get('AUTO_MIGRATE', 'false').lower() in ('true', '1', 'yes'):
            call_command('migrate', interactive=False)
            call_command('ensure_admin')

    except Exception as _e:
        print(f"Vercel auto-init note: {_e}")

