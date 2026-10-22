from django.contrib.auth import get_user_model
from django.contrib.auth.backends import ModelBackend

User = get_user_model()

class EmailAuthBackend(ModelBackend):
    def authenticate(self, request, username=None, password=None, **kwargs):
        # Allow authentication with email or username (case-insensitive)
        identifier = kwargs.get('email') or username
        if not identifier or not password:
            return None

        identifier = identifier.strip()
        user = None

        # 1. If identifier contains '@', prioritize email lookup
        if '@' in identifier:
            user = User.objects.filter(email__iexact=identifier).first()

        # 2. Try username lookup (case-insensitive)
        if not user:
            user = User.objects.filter(username__iexact=identifier).first()

        # 3. Fallback: try email lookup in case user provided an email without '@' check
        if not user:
            user = User.objects.filter(email__iexact=identifier).first()

        # 4. Try phone lookup (raw phone, normalized phone, or digits)
        if not user:
            from django.db.models import Q
            from .sms_service import normalize_cambodia_phone
            norm, valid, _ = normalize_cambodia_phone(identifier)
            phone_query = Q(phone=identifier)
            if valid and norm:
                phone_query |= Q(phone_normalized=norm) | Q(phone=norm)
            clean_digits = ''.join(c for c in identifier if c.isdigit() or c == '+')
            if clean_digits and clean_digits != identifier:
                phone_query |= Q(phone=clean_digits)
            user = User.objects.filter(phone_query).first()

        if user and user.check_password(password) and self.user_can_authenticate(user):
            return user
        return None
