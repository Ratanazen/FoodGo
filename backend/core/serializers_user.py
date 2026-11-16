from rest_framework import serializers
from .models import User

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = [
            'id', 'username', 'email', 'first_name', 'last_name',
            'phone', 'phone_normalized', 'is_phone_verified', 'phone_verified_at',
            'role', 'avatar', 'avatar_url', 'is_staff', 'is_superuser',
        ]
        read_only_fields = [
            'id', 'username', 'phone_normalized', 'is_phone_verified',
            'phone_verified_at', 'is_staff', 'is_superuser',
        ]

    def validate_role(self, value):
        val = (value or '').strip().lower()
        user = self.instance
        if val == 'admin' and not (user and (user.is_staff or user.role == 'admin')):
            return user.role if user else 'customer'
        if val in ['customer', 'driver', 'restaurant_owner']:
            return val
        return user.role if user else 'customer'

    def validate_email(self, value):
        if not value:
            return value
        norm = value.strip().lower()
        qs = User.objects.filter(email__iexact=norm)
        if self.instance:
            qs = qs.exclude(pk=self.instance.pk)
        if qs.exists():
            raise serializers.ValidationError("An account with this email address already exists.")
        return norm

    def validate_phone(self, value):
        if not value:
            return value
        val = value.strip()
        from .sms_service import normalize_cambodia_phone
        norm, valid, err = normalize_cambodia_phone(val)
        if not valid:
            raise serializers.ValidationError(err)
        return val

    def update(self, instance, validated_data):
        new_role = validated_data.get('role')
        if 'phone' in validated_data:
            new_phone = validated_data.get('phone')
            if new_phone and new_phone != instance.phone:
                instance.is_phone_verified = False
                instance.phone_verified_at = None
            elif not new_phone:
                instance.is_phone_verified = False
                instance.phone_verified_at = None

        user = super().update(instance, validated_data)
        if new_role == 'driver':
            from .models import Driver
            Driver.objects.get_or_create(
                user=user,
                defaults={
                    'vehicle_type': 'Motorcycle',
                    'license_plate': 'PP-2026',
                    'is_online': True,
                    'is_approved': True,
                }
            )
        return user

