import re

with open('backend/core/views.py', 'r') as f:
    content = f.read()

# Add my_restaurant action
my_restaurant_code = """
    @action(detail=False, methods=['get'])
    def my_restaurant(self, request):
        if request.user.role != 'restaurant_owner':
            return Response({'detail': 'Not a restaurant owner'}, status=403)
        restaurant = Restaurant.objects.filter(owner=request.user).first()
        if not restaurant:
            return Response({'detail': 'Restaurant not found'}, status=404)
        serializer = self.get_serializer(restaurant)
        return Response(serializer.data)
"""

if "def my_restaurant" not in content:
    content = content.replace(
        "def perform_create(self, serializer):",
        my_restaurant_code + "\n    def perform_create(self, serializer):"
    )
    # Ensure @action and Response are imported (they are in OrderViewSet already, but just in case)
    if "from rest_framework.decorators import action" not in content:
        content = "from rest_framework.decorators import action\nfrom rest_framework.response import Response\n" + content
    
    with open('backend/core/views.py', 'w') as f:
        f.write(content)
    print("Patched RestaurantViewSet")
else:
    print("Already patched")
