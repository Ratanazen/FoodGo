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
