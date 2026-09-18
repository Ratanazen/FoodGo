from pathlib import Path
from datetime import timedelta
import os

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = os.environ.get('DJANGO_SECRET_KEY', 'dev-only-change-me')
DEBUG = os.environ.get('DJANGO_DEBUG', 'True').lower() == 'true'
ALLOWED_HOSTS = [host.strip() for host in os.environ.get('DJANGO_ALLOWED_HOSTS', '127.0.0.1,localhost').split(',') if host.strip()]

INSTALLED_APPS = [
    'jazzmin',
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    
    'rest_framework',
    'corsheaders',
    'rest_framework_simplejwt',
    'django_filters',
    'core',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'corsheaders.middleware.CorsMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'config.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'config.wsgi.application'

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}

if os.environ.get('DATABASE_URL'):
    from urllib.parse import urlparse

    parsed_database_url = urlparse(os.environ['DATABASE_URL'])
    DATABASES['default'] = {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': parsed_database_url.path.removeprefix('/'),
        'USER': parsed_database_url.username,
        'PASSWORD': parsed_database_url.password,
        'HOST': parsed_database_url.hostname,
        'PORT': parsed_database_url.port,
    }

AUTH_USER_MODEL = 'core.User'

AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True

STATIC_URL = 'static/'
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

CORS_ALLOWED_ORIGINS = [
    origin.strip()
    for origin in os.environ.get('CORS_ALLOWED_ORIGINS', 'http://localhost:3000').split(',')
    if origin.strip()
]
CSRF_TRUSTED_ORIGINS = [
    origin.strip()
    for origin in os.environ.get('CSRF_TRUSTED_ORIGINS', '').split(',')
    if origin.strip()
]

if not DEBUG:
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True
    SECURE_SSL_REDIRECT = True
    SECURE_HSTS_SECONDS = 31536000
    SECURE_HSTS_INCLUDE_SUBDOMAINS = True
    SECURE_HSTS_PRELOAD = True
    SECURE_CONTENT_TYPE_NOSNIFF = True
    SECURE_REFERRER_POLICY = 'same-origin'
    X_FRAME_OPTIONS = 'DENY'

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ),
    'DEFAULT_PERMISSION_CLASSES': (
        'rest_framework.permissions.IsAuthenticated',
    ),
}

SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(days=1),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
    'AUTH_HEADER_TYPES': ('Bearer',),
}

AUTHENTICATION_BACKENDS = [
    'core.authentication.EmailAuthBackend',
    'django.contrib.auth.backends.ModelBackend',
]

JAZZMIN_SETTINGS = {
    "site_title": "FoodGo Admin",
    "site_header": "FoodGo",
    "site_brand": "🍔 FoodGo",
    "site_logo": None,
    "site_logo_classes": "img-circle",
    "site_icon": None,
    "welcome_sign": "Welcome back! FoodGo Admin Panel",
    "copyright": "FoodGo Ltd © 2026",
    "search_model": ["core.User", "core.Order", "core.Restaurant", "core.FoodItem"],
    "user_avatar": None,

    ############
    # Top Menu #
    ############
    "topmenu_links": [
        {"name": "🏠 Dashboard", "url": "admin:index", "permissions": ["auth.view_user"]},
        {"name": "👤 Users", "model": "core.User"},
        {"name": "📦 Orders", "model": "core.Order"},
        {"name": "🍽️ Restaurants", "model": "core.Restaurant"},
    ],

    #############
    # User Menu #
    #############
    "usermenu_links": [
        {"model": "core.user"},
    ],

    #############
    # Side Menu #
    #############
    "show_sidebar": True,
    "navigation_expanded": True,
    "hide_apps": ["auth"],
    "hide_models": [],
    "order_with_respect_to": [
        "core",
        "core.User", "core.Address", "core.Driver",
        "core.Restaurant", "core.RestaurantCategory", "core.FoodCategory", "core.FoodItem",
        "core.Order", "core.OrderItem", "core.Payment", "core.Delivery",
        "core.Cart", "core.CartItem", "core.Review", "core.Favorite",
        "core.Coupon", "core.Notification", "core.LiveItem",
    ],

    "icons": {
        "auth":                    "fas fa-users-cog",
        "auth.user":               "fas fa-user",
        "auth.Group":              "fas fa-users",
        "core.User":               "fas fa-user-circle",
        "core.Address":            "fas fa-map-marker-alt",
        "core.Driver":             "fas fa-motorcycle",
        "core.Favorite":           "fas fa-heart",
        "core.RestaurantCategory": "fas fa-tags",
        "core.Restaurant":         "fas fa-store",
        "core.FoodCategory":       "fas fa-list-alt",
        "core.FoodItem":           "fas fa-hamburger",
        "core.Order":              "fas fa-shopping-bag",
        "core.OrderItem":          "fas fa-receipt",
        "core.Payment":            "fas fa-credit-card",
        "core.Delivery":           "fas fa-truck",
        "core.Cart":               "fas fa-shopping-cart",
        "core.CartItem":           "fas fa-box",
        "core.Review":             "fas fa-star",
        "core.Coupon":             "fas fa-ticket-alt",
        "core.Notification":       "fas fa-bell",
        "core.LiveItem":           "fas fa-broadcast-tower",
    },
    "default_icon_parents": "fas fa-chevron-circle-right",
    "default_icon_children": "fas fa-circle",

    "related_modal_active": True,
    "custom_css": None,
    "custom_js": None,
    "use_google_fonts_cdn": True,

    # ✅ Enable the UI builder so you can tweak the theme live from the sidebar
    "show_ui_builder": True,
    "changeform_format": "horizontal_tabs",
    "changeform_format_overrides": {
        "auth.user": "collapsible",
        "auth.group": "vertical_tabs",
    },
}

JAZZMIN_UI_TWEAKS = {
    "navbar_small_text": False,
    "footer_small_text": False,
    "body_small_text": False,
    "brand_small_text": False,
    "brand_colour": "navbar-success",
    "accent": "accent-success",
    "navbar": "navbar-success navbar-dark",
    "no_navbar_border": True,
    "navbar_fixed": True,
    "layout_boxed": False,
    "footer_fixed": False,
    "sidebar_fixed": True,
    "sidebar": "sidebar-dark-success",
    "sidebar_nav_small_text": False,
    "sidebar_disable_expand": False,
    "sidebar_nav_child_indent": True,
    "sidebar_nav_compact_style": True,
    "sidebar_nav_legacy_style": False,
    "sidebar_nav_flat_style": True,
    "theme": "flatly",
    "dark_mode_theme": "darkly",
    "button_classes": {
        "primary":   "btn-outline-primary",
        "secondary": "btn-outline-secondary",
        "info":      "btn-outline-info",
        "warning":   "btn-warning",
        "danger":    "btn-danger",
        "success":   "btn-success",
    },
    "actions_sticky_top": True,
}
