import time
import logging

from django.middleware.csrf import get_token

logger = logging.getLogger(__name__)


class RequestTimingMiddleware:
    """
    Measures request processing time and adds X-Response-Time header (in milliseconds).
    Logs slow requests (>2s) for performance monitoring and alerting.
    """
    SLOW_REQUEST_THRESHOLD_MS = 2000

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        start_time = time.monotonic()
        response = self.get_response(request)
        elapsed_ms = (time.monotonic() - start_time) * 1000.0

        response['X-Response-Time'] = f'{elapsed_ms:.0f}ms'

        if elapsed_ms > self.SLOW_REQUEST_THRESHOLD_MS:
            logger.warning(
                'Slow request: %s %s took %.0fms (user=%s)',
                request.method, request.path, elapsed_ms,
                getattr(request.user, 'username', 'anonymous') if hasattr(request, 'user') else 'unknown'
            )

        return response


class AdminNoCacheMiddleware:
    """
    Ensures admin pages (especially login and dashboard) are never cached
    by browsers, proxies, or CDNs, which prevents stale CSRF tokens from causing
    'CSRF token from POST incorrect' 403 errors.
    """
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        # Ensure fresh CSRF cookie exists when accessing admin login
        if request.path.startswith('/admin/login') and request.method == 'GET':
            get_token(request)

        response = self.get_response(request)

        if request.path.startswith('/admin/'):
            response['Cache-Control'] = 'no-cache, no-store, must-revalidate, private, max-age=0'
            response['Pragma'] = 'no-cache'
            response['Expires'] = '0'

        return response
