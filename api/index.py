"""
Vercel Serverless Function entrypoint for FoodGo Django REST backend.
Standard zero-config entrypoint recognized automatically by Vercel Python runtime.
"""
import os
import sys
from pathlib import Path

# Resolve repository root and backend directory into sys.path
ROOT_DIR = Path(__file__).resolve().parent.parent
BACKEND_DIR = ROOT_DIR / 'backend'

for _path in [str(BACKEND_DIR), str(ROOT_DIR)]:
    if _path not in sys.path:
        sys.path.insert(0, _path)

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')

from config.wsgi import application, app

# Expose WSGI handler for Vercel Serverless Function
handler = app
