"""
WSGI config for config project.

It exposes the WSGI callable as a module-level variable named ``application``.

For more information on this file, see
https://docs.djangoproject.com/en/6.1/howto/deployment/wsgi/
"""

import os

from django.core.wsgi import get_wsgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')

application = get_wsgi_application()
app = application

# Vercel serverless cold-start initialization
if 'VERCEL' in os.environ and not os.environ.get('DATABASE_URL'):
    try:
        from django.core.management import call_command
        from django.db import connection
        _tables = connection.introspection.table_names()
        if 'core_user' not in _tables:
            call_command('migrate', interactive=False)
            call_command('ensure_admin')
            call_command('seed_full_menu')
        else:
            call_command('ensure_admin')
    except Exception as _e:
        print(f"Vercel auto-init note: {_e}")
