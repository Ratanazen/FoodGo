from rest_framework import serializers
from .models import User

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = [
            'id', 'username', 'email', 'first_name', 'last_name',
            'phone', 'phone_normalized', 'is_phone_verified', 'phone_verified_at',
            'role', 'avatar', 'avatar_url',
        ]
        read_only_fields = ['id', 'username', 'phone_normalized', 'is_phone_verified', 'phone_verified_at']

    def validate_role(self, value):
        val = (value or '').strip().lower()
        user = self.instance
        if val == 'admin' and not (user and (user.is_staff or user.role == 'admin')):
            return user.role if user else 'customer'
        if val in ['customer', 'driver', 'restaurant_owner']:
            return val
        return user.role if user else 'customer'

    def update(self, instance, validated_data):
        new_role = validated_data.get('role')
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

