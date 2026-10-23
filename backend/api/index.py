"""
Vercel Serverless Function entrypoint for FoodGo Django REST backend (backend root).
"""
import os
import sys
from pathlib import Path

BACKEND_DIR = Path(__file__).resolve().parent.parent
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')

from config.wsgi import application, app

# Expose WSGI handler for Vercel Serverless Function
handler = app
