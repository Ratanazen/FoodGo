from rest_framework import permissions

class IsAdminOrStaff(permissions.BasePermission):
    """
    Allows access only to authenticated admin users, superusers, or staff members.
    """
    def has_permission(self, request, view):
        user = request.user
        return bool(
            user and
            user.is_authenticated and
            (user.is_staff or user.is_superuser or getattr(user, 'role', '') == 'admin')
        )

class IsDriverUser(permissions.BasePermission):
    """
    Allows access only to authenticated driver accounts.
    """
    def has_permission(self, request, view):
        user = request.user
        return bool(
            user and
            user.is_authenticated and
            (hasattr(user, 'driver_profile') or getattr(user, 'role', '') == 'driver' or user.is_staff)
        )

class IsRestaurantOwnerUser(permissions.BasePermission):
    """
    Allows access only to authenticated restaurant owners.
    """
    def has_permission(self, request, view):
        user = request.user
        return bool(
            user and
            user.is_authenticated and
            (getattr(user, 'role', '') == 'restaurant_owner' or user.is_staff)
        )
