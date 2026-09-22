import re

with open('backend/core/urls.py', 'r') as f:
    content = f.read()

imports = "from .auth_views import RequestOTPView, VerifyOTPView\n"

if "RequestOTPView" not in content:
    content = imports + content
    content = content.replace("urlpatterns = [", "urlpatterns = [\n    path('auth/phone-login/request/', RequestOTPView.as_view(), name='otp_request'),\n    path('auth/phone-login/verify/', VerifyOTPView.as_view(), name='otp_verify'),")
    with open('backend/core/urls.py', 'w') as f:
        f.write(content)
