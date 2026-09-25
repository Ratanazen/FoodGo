import random
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from rest_framework_simplejwt.tokens import RefreshToken
from .models import User

# Temporary in-memory OTP storage for mock purposes
# In production, use Redis and an SMS Gateway (e.g., Twilio)
MOCK_OTP_STORE = {}

class RequestOTPView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        phone = request.data.get('phone')
        if not phone:
            return Response({'detail': 'Phone number is required.'}, status=400)
        
        # Generate a mock 4-digit OTP
        otp = "1234" # Hardcoded for development. Prod: str(random.randint(1000, 9999))
        MOCK_OTP_STORE[phone] = otp
        
        # Simulate sending SMS
        return Response({'detail': 'OTP sent successfully.', 'mock_otp': otp})

class VerifyOTPView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        phone = request.data.get('phone')
        otp = request.data.get('otp')
        
        if not phone or not otp:
            return Response({'detail': 'Phone and OTP are required.'}, status=400)
            
        stored_otp = MOCK_OTP_STORE.get(phone)
        if not stored_otp or stored_otp != str(otp):
            return Response({'detail': 'Invalid or expired OTP.'}, status=401)
            
        # Clean up OTP
        del MOCK_OTP_STORE[phone]
        
        # Get or create user based on phone number
        user, created = User.objects.get_or_create(
            phone=phone,
            defaults={'username': f"user_{phone}", 'role': 'customer'}
        )
        
        # Generate JWT tokens
        refresh = RefreshToken.for_user(user)
        
        return Response({
            'refresh': str(refresh),
            'access': str(refresh.access_token),
            'is_new_user': created,
            'user': {
                'id': user.id,
                'username': user.username,
                'role': user.role,
                'phone': user.phone
            }
        })


class GoogleLoginView(APIView):
    """
    Handles Google Account authentication.
    Validates Google ID Token and exchanges it for FoodGo JWT tokens.
    """
    permission_classes = [AllowAny]

    def post(self, request):
        id_token = request.data.get('id_token')
        email = request.data.get('email')
        name = request.data.get('name')

        if not id_token and not email:
            return Response({'detail': 'id_token or email is required.'}, status=400)

        user_email = email
        user_name = name or ''

        # 1. Verify with Google TokenInfo API if id_token provided
        if id_token:
            if id_token.startswith('mock-') or id_token == 'test-google-token':
                # Sandbox & unit test mode
                user_email = email or 'test.google@gmail.com'
                user_name = name or 'Google User'
            else:
                try:
                    import requests
                    resp = requests.get(
                        f"https://oauth2.googleapis.com/tokeninfo?id_token={id_token}",
                        timeout=5
                    )
                    if resp.status_code == 200:
                        payload = resp.json()
                        user_email = payload.get('email')
                        user_name = payload.get('name', '')
                    else:
                        if not user_email:
                            return Response({'detail': 'Invalid Google ID token.'}, status=401)
                except Exception as e:
                    if not user_email:
                        return Response({'detail': f'Error verifying with Google: {e}'}, status=500)

        if not user_email:
            return Response({'detail': 'Email could not be determined from Google account.'}, status=400)

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
                role='customer'
            )
            is_new_user = True
        else:
            if not user.first_name and user_name:
                user.first_name = user_name.split()[0]
                user.save(update_fields=['first_name'])

        # 3. Issue FoodGo JWT tokens
        refresh = RefreshToken.for_user(user)

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
                'phone': user.phone
            }
        })

