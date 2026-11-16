import logging
from django.conf import settings
from django.db import transaction
from django.utils import timezone
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework_simplejwt.tokens import RefreshToken

from .models import User, PhoneOTPChallenge
from .sms_service import (
    normalize_cambodia_phone,
    mask_phone,
    generate_secure_otp,
    generate_salt,
    hash_otp,
    verify_otp_hash,
    get_sms_provider,
)

logger = logging.getLogger(__name__)


def dispatch_phone_otp(user, phone_normalized, raw_phone, purpose, ip_address=None):
    """
    Central helper to validate rate limits, generate salted HMAC OTP,
    dispatch via SMS gateway, and record PhoneOTPChallenge.
    Returns (success: bool, response_dict: dict, status_code: int).
    """
    now = timezone.now()
    cooldown_seconds = getattr(settings, 'OTP_RESEND_COOLDOWN_SECONDS', 60)
    expiry_seconds = getattr(settings, 'OTP_EXPIRY_SECONDS', 300)
    otp_length = getattr(settings, 'OTP_LENGTH', 6)
    max_hourly_requests = getattr(settings, 'OTP_RATE_LIMIT_PER_HOUR', 5)

    # 1. Check if phone is already claimed by another verified user for verification requests
    if user and user.is_authenticated and purpose in ('customer_verification', 'driver_verification', 'phone_change'):
        collision = User.objects.filter(
            phone_normalized=phone_normalized,
            is_phone_verified=True
        ).exclude(id=user.id).first()
        if collision:
            return False, {
                'error': 'This phone number is already verified with another account.'
            }, status.HTTP_409_CONFLICT

    # 2. Check Cooldown on most recent challenge for this phone
    recent_challenge = PhoneOTPChallenge.objects.filter(
        phone_normalized=phone_normalized,
        is_consumed=False
    ).order_by('-created_at').first()

    if recent_challenge and now < recent_challenge.resend_available_at:
        wait_seconds = int((recent_challenge.resend_available_at - now).total_seconds())
        return False, {
            'error': f'Please wait {max(1, wait_seconds)} seconds before requesting a new verification code.',
            'cooldown_seconds': max(1, wait_seconds),
        }, status.HTTP_429_TOO_MANY_REQUESTS

    # 3. Check Hourly Rate Limit
    one_hour_ago = now - timezone.timedelta(hours=1)
    hourly_count = PhoneOTPChallenge.objects.filter(
        phone_normalized=phone_normalized,
        created_at__gte=one_hour_ago
    ).count()
    if hourly_count >= max_hourly_requests:
        return False, {
            'error': 'Hourly OTP request limit exceeded for this phone number. Please try again later.',
        }, status.HTTP_429_TOO_MANY_REQUESTS

    # 4. Generate cryptographically secure OTP & HMAC-SHA256 hash
    otp = generate_secure_otp(length=otp_length)
    salt = generate_salt()
    hashed = hash_otp(otp, salt)

    # 5. Dispatch via configured SMS Gateway
    provider = get_sms_provider()
    success, msg_id, meta = provider.send_otp(phone_normalized, otp, purpose=purpose)

    if not success:
        err_detail = meta.get('error', 'Unable to deliver SMS message via gateway.')
        return False, {
            'error': f'SMS delivery failed: {err_detail}',
            'provider': provider.name,
        }, status.HTTP_502_BAD_GATEWAY

    # 6. Save Challenge to Database (Plain OTP is never stored!)
    resend_at = now + timezone.timedelta(seconds=cooldown_seconds)
    expires_at = now + timezone.timedelta(seconds=expiry_seconds)

    challenge = PhoneOTPChallenge.objects.create(
        user=user if user and user.is_authenticated else None,
        phone_raw=raw_phone,
        phone_normalized=phone_normalized,
        purpose=purpose,
        hashed_otp=hashed,
        salt=salt,
        expires_at=expires_at,
        resend_available_at=resend_at,
        ip_address=ip_address,
        provider_name=provider.name,
        provider_message_id=msg_id,
    )

    return True, {
        'status': 'SUCCESS',
        'message': 'Verification code dispatched successfully via SMS.',
        'phone_masked': mask_phone(phone_normalized),
        'cooldown_seconds': cooldown_seconds,
        'expires_in_seconds': expiry_seconds,
        'challenge_id': challenge.id,
    }, status.HTTP_200_OK


class SendPhoneOTPView(APIView):
    """
    Endpoint: POST /api/auth/phone/send-otp/
    Dispatches a cryptographically secure, short-lived SMS OTP to a Cambodian +855 mobile number.
    Enforces 60-second resend cooldowns and rate limits (max 5 requests/hr per number).
    """
    permission_classes = [AllowAny]

    def post(self, request):
        raw_phone = request.data.get('phone', '').strip()
        purpose = request.data.get('purpose', 'customer_verification')

        valid_purposes = [c[0] for c in PhoneOTPChallenge.PURPOSE_CHOICES]
        if purpose not in valid_purposes:
            purpose = 'customer_verification'

        phone_normalized, is_valid, err_msg = normalize_cambodia_phone(raw_phone)
        if not is_valid:
            return Response({'error': err_msg}, status=status.HTTP_400_BAD_REQUEST)

        ip = request.META.get('REMOTE_ADDR')
        ok, res_data, code = dispatch_phone_otp(
            user=request.user,
            phone_normalized=phone_normalized,
            raw_phone=raw_phone,
            purpose=purpose,
            ip_address=ip
        )
        return Response(res_data, status=code)


class VerifyPhoneOTPView(APIView):
    """
    Endpoint: POST /api/auth/phone/verify-otp/
    Verifies a submitted OTP code against the active challenge using constant-time HMAC comparison.
    Atomically consumes valid challenges and updates the user's phone verification status.
    """
    permission_classes = [AllowAny]

    def post(self, request):
        raw_phone = request.data.get('phone', '').strip()
        otp = str(request.data.get('otp', '')).strip()
        purpose = request.data.get('purpose', '')

        if not raw_phone or not otp:
            return Response({'error': 'Both phone number and OTP code are required.'}, status=status.HTTP_400_BAD_REQUEST)

        phone_normalized, is_valid, err_msg = normalize_cambodia_phone(raw_phone)
        if not is_valid:
            return Response({'error': err_msg}, status=status.HTTP_400_BAD_REQUEST)

        now = timezone.now()

        with transaction.atomic():
            # Lock the challenge row to prevent concurrent race conditions
            query = PhoneOTPChallenge.objects.select_for_update().filter(
                phone_normalized=phone_normalized,
                is_consumed=False
            )
            if purpose:
                query = query.filter(purpose=purpose)

            challenge = query.order_by('-created_at').first()

            if not challenge:
                return Response({
                    'error': 'No active verification request found for this phone number. Please request a code.'
                }, status=status.HTTP_400_BAD_REQUEST)

            # Check expiration
            if challenge.is_expired():
                return Response({
                    'error': 'This verification code has expired. Please request a new code.'
                }, status=status.HTTP_400_BAD_REQUEST)

            # Check attempt limits
            if challenge.attempts >= challenge.max_attempts:
                challenge.is_consumed = True
                challenge.save(update_fields=['is_consumed'])
                return Response({
                    'error': 'Maximum verification attempts exceeded. Please request a new code.'
                }, status=status.HTTP_400_BAD_REQUEST)

            # Increment attempt counter
            challenge.attempts += 1

            # Validate OTP code using constant-time HMAC verification
            is_correct = verify_otp_hash(otp, challenge.salt, challenge.hashed_otp)
            if not is_correct:
                challenge.save(update_fields=['attempts'])
                remaining = max(0, challenge.max_attempts - challenge.attempts)
                return Response({
                    'error': f'Invalid verification code. {remaining} attempt(s) remaining.',
                    'attempts_remaining': remaining,
                }, status=status.HTTP_400_BAD_REQUEST)

            # Successfully verified: atomically consume challenge
            challenge.is_consumed = True
            challenge.consumed_at = now
            challenge.save(update_fields=['attempts', 'is_consumed', 'consumed_at'])

            # Determine target user to mark verified
            target_user = None
            if request.user.is_authenticated:
                target_user = request.user
            elif challenge.user:
                target_user = challenge.user
            else:
                target_user = User.objects.filter(phone_normalized=phone_normalized).first()
                if not target_user:
                    target_user = User.objects.filter(phone=raw_phone).first()
                if not target_user and challenge.purpose == 'phone_login':
                    # Create new customer account for phone login
                    from .models import Wallet
                    base_username = f"user_{phone_normalized.replace('+', '')}"
                    candidate = base_username
                    suffix = 1
                    while User.objects.filter(username__iexact=candidate).exists():
                        candidate = f"{base_username}_{suffix}"
                        suffix += 1
                    target_user = User.objects.create_user(
                        username=candidate,
                        phone=phone_normalized,
                        role='customer'
                    )
                    Wallet.objects.get_or_create(user=target_user)

            if target_user:
                target_user.phone = phone_normalized
                target_user.phone_normalized = phone_normalized
                target_user.is_phone_verified = True
                target_user.phone_verified_at = now
                target_user.save(update_fields=['phone', 'phone_normalized', 'is_phone_verified', 'phone_verified_at'])

            response_data = {
                'status': 'SUCCESS',
                'message': 'Phone number verified successfully.',
                'phone_normalized': phone_normalized,
                'is_phone_verified': True,
                'verified_at': now.isoformat(),
            }

            # If purpose is phone_login, issue JWT tokens
            if challenge.purpose == 'phone_login' and target_user:
                refresh = RefreshToken.for_user(target_user)
                response_data['access'] = str(refresh.access_token)
                response_data['refresh'] = str(refresh)
                response_data['user'] = {
                    'id': target_user.id,
                    'username': target_user.username,
                    'email': target_user.email,
                    'role': target_user.role,
                    'phone': target_user.phone,
                    'is_phone_verified': True,
                }

                # Record phone OTP login event to MongoDB Atlas (non-blocking)
                try:
                    from .mongodb import record_user_login_mongo
                    from .signals import _run_async
                    ip = request.META.get('HTTP_X_FORWARDED_FOR', request.META.get('REMOTE_ADDR'))
                    if ip and ',' in ip:
                        ip = ip.split(',')[0].strip()
                    ua = request.META.get('HTTP_USER_AGENT', '')
                    _run_async(record_user_login_mongo, args=(target_user, 'phone_otp', ip, ua))
                except Exception:
                    pass

            return Response(response_data, status=status.HTTP_200_OK)


class PhoneStatusView(APIView):
    """
    Endpoint: GET /api/auth/phone/status/
    Returns the authenticated user's current phone number and verification status.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        phone = user.phone_normalized or user.phone or ''
        return Response({
            'phone': phone,
            'phone_masked': mask_phone(phone),
            'is_phone_verified': user.is_phone_verified,
            'phone_verified_at': user.phone_verified_at.isoformat() if user.phone_verified_at else None,
            'role': user.role,
            'can_change_phone': True,
        }, status=status.HTTP_200_OK)


class ChangePhoneView(APIView):
    """
    Endpoint: POST /api/auth/phone/change/
    Requests a phone number change for an authenticated user.
    Enforces collision checks and dispatches OTP to the new phone number.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        new_phone_raw = request.data.get('new_phone', '').strip()
        if not new_phone_raw:
            return Response({'error': 'New phone number is required.'}, status=status.HTTP_400_BAD_REQUEST)

        new_phone_normalized, is_valid, err_msg = normalize_cambodia_phone(new_phone_raw)
        if not is_valid:
            return Response({'error': err_msg}, status=status.HTTP_400_BAD_REQUEST)

        user = request.user
        if user.phone_normalized == new_phone_normalized:
            return Response({'error': 'New phone number is identical to your current phone number.'}, status=status.HTTP_400_BAD_REQUEST)

        # Check if already verified with another user
        collision = User.objects.filter(
            phone_normalized=new_phone_normalized,
            is_phone_verified=True
        ).exclude(id=user.id).first()
        if collision:
            return Response({'error': 'This phone number is already verified with another account.'}, status=status.HTTP_409_CONFLICT)

        ip = request.META.get('REMOTE_ADDR')
        ok, res_data, code = dispatch_phone_otp(
            user=user,
            phone_normalized=new_phone_normalized,
            raw_phone=new_phone_raw,
            purpose='phone_change',
            ip_address=ip
        )
        return Response(res_data, status=code)
