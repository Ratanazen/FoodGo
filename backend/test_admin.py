import os
import django
from django.test import Client

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

c = Client(HTTP_HOST='127.0.0.1')
from django.contrib.auth import get_user_model
User = get_user_model()
su = User.objects.filter(is_superuser=True).first()
if su:
    c.force_login(su)
response = c.get('/admin/')
with open("admin_output.html", "wb") as f:
    f.write(response.content)
