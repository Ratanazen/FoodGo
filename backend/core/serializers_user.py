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
        read_only_fields = ['id', 'username', 'role', 'phone_normalized', 'is_phone_verified', 'phone_verified_at']

