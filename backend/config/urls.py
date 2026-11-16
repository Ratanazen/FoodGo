from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from django.shortcuts import render, redirect

def api_root(request):
    return render(request, 'core/api_root.html')

def items_portal(request):
    from rest_framework_simplejwt.tokens import AccessToken
    portal_token = ''
    portal_username = ''
    if request.user.is_authenticated and request.user.is_staff:
        portal_token = str(AccessToken.for_user(request.user))
        portal_username = request.user.username
    resp = render(request, 'core/items_portal.html', {
        'portal_token': portal_token,
        'portal_username': portal_username,
    })
    resp['Cache-Control'] = 'no-cache, no-store, must-revalidate, private, max-age=0'
    resp['CDN-Cache-Control'] = 'no-store'
    resp['Vercel-CDN-Cache-Control'] = 'no-store'
    return resp

def profile_redirect(request):
    if request.user.is_authenticated and (request.user.is_staff or request.user.is_superuser):
        return redirect('/admin/')
    return redirect('/')

from core.views import HealthCheckView, HealthLiveView, HealthReadyView, MongoHealthCheckView, MongoImageView
from core.auth_views import FoodGoTokenObtainPairView

urlpatterns = [
    path('', api_root, name='api-root'),
    path('items-portal/', admin.site.admin_view(items_portal), name='items-portal'),
    path('items-portal', admin.site.admin_view(items_portal), name='items-portal-no-slash'),
    path('portal/items/', admin.site.admin_view(items_portal), name='portal-items'),
    path('portal/items', admin.site.admin_view(items_portal), name='portal-items-no-slash'),
    path('admin/items-portal/', admin.site.admin_view(items_portal), name='admin-items-portal'),
    path('health/live', HealthLiveView.as_view(), name='health-live-no-slash'),
    path('health/live/', HealthLiveView.as_view(), name='health-live'),
    path('health/ready', HealthReadyView.as_view(), name='health-ready-no-slash'),
    path('health/ready/', HealthReadyView.as_view(), name='health-ready'),
    path('health/mongodb', MongoHealthCheckView.as_view(), name='health-mongodb-no-slash'),
    path('health/mongodb/', MongoHealthCheckView.as_view(), name='health-mongodb'),
    path('health', HealthCheckView.as_view(), name='root-health-no-slash'),
    path('health/', HealthCheckView.as_view(), name='root-health'),
    path('healthz', HealthCheckView.as_view(), name='root-healthz-no-slash'),
    path('healthz/', HealthCheckView.as_view(), name='root-healthz'),
    path('accounts/profile/', profile_redirect, name='profile-redirect'),
    path('accounts/login/', lambda request: redirect('/admin/login/'), name='accounts-login-redirect'),
    path('media/mongo/<path:filename>', MongoImageView.as_view(), name='root_mongo_image'),
    path('api/health/', HealthCheckView.as_view(), name='root-api-health'),
    path('api/health', HealthCheckView.as_view(), name='root-api-health-no-slash'),
    path('api/healthz/', HealthCheckView.as_view(), name='root-api-healthz'),
    path('api/healthz', HealthCheckView.as_view(), name='root-api-healthz-no-slash'),
    path('admin/', admin.site.urls),
    path('api/', include('core.urls')),
    path('api/token/', FoodGoTokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('api/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
