import random
import logging
import requests
import sys
from django.conf import settings
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenObtainPairView
from django.core.cache import cache
from .models import User

logger = logging.getLogger(__name__)


def _extract_request_meta(request):
    """Extract client IP address and user-agent string from request."""
    ip = request.META.get('HTTP_X_FORWARDED_FOR', request.META.get('REMOTE_ADDR'))
    if ip and ',' in ip:
        ip = ip.split(',')[0].strip()
    ua = request.META.get('HTTP_USER_AGENT', '')
    return ip, ua


class FoodGoTokenObtainPairView(TokenObtainPairView):
    """
    Subclass of SimpleJWT TokenObtainPairView that records login audit logs
    and syncs user state to MongoDB Atlas on successful authentication.
    """
    def post(self, request, *args, **kwargs):
        response = super().post(request, *args, **kwargs)
        if response.status_code == 200:
            try:
                from .mongodb import record_user_login_mongo
                from .signals import _run_async
                identifier = request.data.get('username') or request.data.get('email')
                if identifier:
                    user = (
                        User.objects.filter(username__iexact=identifier).first()
                        or User.objects.filter(email__iexact=identifier).first()
                        or User.objects.filter(phone=identifier).first()
                    )
                    if user:
                        from .serializers import UserSerializer
                        response.data['user'] = UserSerializer(user).data
                        ip, ua = _extract_request_meta(request)
                        _run_async(record_user_login_mongo, args=(user, 'jwt_password', ip, ua))
            except Exception as e:
                logger.warning(f"Failed to record JWT login to MongoDB: {e}")
        return response

from .phone_views import SendPhoneOTPView, VerifyPhoneOTPView

class RequestOTPView(SendPhoneOTPView):
    """Legacy alias routing to authoritative Cambodian Phone OTP challenge endpoint."""
    pass

class VerifyOTPView(VerifyPhoneOTPView):
    """Legacy alias routing to authoritative Cambodian Phone OTP verification endpoint."""
    pass




class GoogleLoginView(APIView):
    """
    Handles Google Account authentication.
    Validates Google ID Token and exchanges it for FoodGo JWT tokens.
    """
    permission_classes = [AllowAny]

    def post(self, request):
        id_token = request.data.get('id_token')
        if not id_token or not str(id_token).strip():
            return Response({'detail': 'id_token is required.'}, status=status.HTTP_400_BAD_REQUEST)

        email = request.data.get('email')
        name = request.data.get('name')
        avatar_url = request.data.get('avatar_url')

        user_email = None
        user_name = name or ''
        user_avatar = avatar_url or ''

        # 1. Verify with Google TokenInfo API if id_token provided
        if id_token.startswith('mock-') or id_token.startswith('google-token-') or id_token == 'test-google-token':
            is_test_runtime = getattr(settings, 'IS_TESTING', False) or ('test' in sys.argv and getattr(settings, 'IS_TESTING', True))
            if settings.DEBUG or is_test_runtime:
                # Sandbox & unit test mode only
                user_email = email or 'customer.google@gmail.com'
                user_name = name or 'Google User'
            else:
                return Response({'detail': 'Mock Google tokens are only allowed in debug mode.'}, status=status.HTTP_401_UNAUTHORIZED)
        else:
            try:
                resp = requests.get(
                    f"https://oauth2.googleapis.com/tokeninfo?id_token={id_token}",
                    timeout=5
                )
                if resp.status_code == 200:
                    payload = resp.json()
                    user_email = payload.get('email')
                    if not user_email:
                        return Response({'detail': 'Email could not be determined from Google account.'}, status=status.HTTP_400_BAD_REQUEST)
                    user_name = payload.get('name', '') or user_name
                    if not user_avatar:
                        user_avatar = payload.get('picture', '')
                else:
                    return Response({'detail': 'Invalid Google ID token.'}, status=status.HTTP_401_UNAUTHORIZED)
            except Exception:
                return Response({'detail': 'Failed to verify Google ID token.'}, status=status.HTTP_401_UNAUTHORIZED)

        if not user_email:
            return Response({'detail': 'Email could not be determined from Google account.'}, status=status.HTTP_400_BAD_REQUEST)

        # 2. Get or create user by email
        user = User.objects.filter(email=user_email).first()
        is_new_user = False

        if not user:
            base_username = user_email.split('@')[0]
            candidate_username = base_username
            counter = 1
            while User.objects.filter(username=candidate_username).exists():
                candidate_username = f"{base_username}_{counter}"
                counter += 1

            first_name = user_name.split()[0] if user_name else ''
            last_name = ' '.join(user_name.split()[1:]) if user_name and len(user_name.split()) > 1 else ''

            user = User.objects.create_user(
                username=candidate_username,
                email=user_email,
                first_name=first_name,
                last_name=last_name,
                role='customer',
                avatar_url=user_avatar or None,
            )
            is_new_user = True
        else:
            updated_fields = []
            if not user.first_name and user_name:
                user.first_name = user_name.split()[0]
                updated_fields.append('first_name')
            if not user.avatar_url and user_avatar:
                user.avatar_url = user_avatar
                updated_fields.append('avatar_url')
            if updated_fields:
                user.save(update_fields=updated_fields)

        # 3. Issue FoodGo JWT tokens
        refresh = RefreshToken.for_user(user)

        # Record Google OAuth login event to MongoDB Atlas (non-blocking)
        try:
            from .mongodb import record_user_login_mongo
            from .signals import _run_async
            ip, ua = _extract_request_meta(request)
            _run_async(record_user_login_mongo, args=(user, 'google_oauth', ip, ua))
        except Exception:
            pass

        user_photo = user.avatar_url or (user.avatar.url if user.avatar else None)

        return Response({
            'refresh': str(refresh),
            'access': str(refresh.access_token),
            'is_new_user': is_new_user,
            'user': {
                'id': user.id,
                'username': user.username,
                'email': user.email,
                'first_name': user.first_name,
                'last_name': user.last_name,
                'role': user.role,
                'phone': user.phone,
                'avatar_url': user_photo,
            }
        })


class ChangePasswordView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        user = request.user
        old_password = request.data.get('old_password')
        new_password = request.data.get('new_password')
        if not old_password or not new_password:
            return Response({'detail': 'Both old_password and new_password are required.'}, status=status.HTTP_400_BAD_REQUEST)
        if not user.check_password(old_password):
            return Response({'detail': 'Incorrect current password.'}, status=status.HTTP_400_BAD_REQUEST)
        if len(new_password) < 6:
            return Response({'detail': 'New password must be at least 6 characters.'}, status=status.HTTP_400_BAD_REQUEST)
        user.set_password(new_password)
        user.save()
        return Response({'message': 'Password updated successfully.'})


class LogoutView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        refresh_token = request.data.get('refresh')
        if refresh_token:
            try:
                token = RefreshToken(refresh_token)
                token.blacklist()
            except Exception:
                pass
        return Response({'message': 'Logged out successfully.'}, status=status.HTTP_200_OK)


class DeleteAccountView(APIView):
    permission_classes = [IsAuthenticated]

    def delete(self, request):
        user = request.user
        user.is_active = False
        user.username = f"deleted_{user.id}_{user.username}"
        user.email = f"deleted_{user.id}_{user.email}"
        user.save()
        return Response({'message': 'Account deactivated successfully.'}, status=status.HTTP_200_OK)

    def post(self, request):
        return self.delete(request)

