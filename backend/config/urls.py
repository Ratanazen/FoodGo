from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from django.shortcuts import render, redirect

def api_root(request):
    return render(request, 'core/api_root.html')

def profile_redirect(request):
    if request.user.is_authenticated and (request.user.is_staff or request.user.is_superuser):
        return redirect('/admin/')
    return redirect('/')

from core.views import HealthCheckView, HealthLiveView, HealthReadyView, MongoHealthCheckView, MongoImageView

urlpatterns = [
    path('', api_root, name='api-root'),
    path('health/live', HealthLiveView.as_view(), name='health-live-no-slash'),
    path('health/live/', HealthLiveView.as_view(), name='health-live'),
    path('health/ready', HealthReadyView.as_view(), name='health-ready-no-slash'),
    path('health/ready/', HealthReadyView.as_view(), name='health-ready'),
    path('health/mongodb', MongoHealthCheckView.as_view(), name='health-mongodb-no-slash'),
    path('health/mongodb/', MongoHealthCheckView.as_view(), name='health-mongodb'),
    path('health/', HealthCheckView.as_view(), name='root-health'),
    path('healthz/', HealthCheckView.as_view(), name='root-healthz'),
    path('accounts/profile/', profile_redirect, name='profile-redirect'),
    path('accounts/login/', lambda request: redirect('/admin/login/'), name='accounts-login-redirect'),
    path('media/mongo/<path:filename>', MongoImageView.as_view(), name='root_mongo_image'),
    path('api/health/', HealthCheckView.as_view(), name='root-api-health'),
    path('api/health', HealthCheckView.as_view(), name='root-api-health-no-slash'),
    path('admin/', admin.site.urls),
    path('api/', include('core.urls')),
    path('api/token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('api/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
