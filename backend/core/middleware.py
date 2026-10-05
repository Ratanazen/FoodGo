from django.middleware.csrf import get_token

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
