import re

with open('backend/core/views.py', 'r') as f:
    content = f.read()

# Add Review and Recommendations ViewSets
views_code = """
class ReviewViewSet(viewsets.ModelViewSet):
    queryset = Review.objects.all()
    serializer_class = ReviewSerializer
    permission_classes = [IsAuthenticatedOrReadOnly]

    def perform_create(self, serializer):
        order = serializer.validated_data['order']
        if order.customer != self.request.user:
            raise PermissionDenied("You can only review your own orders.")
        if order.status != 'delivered':
            raise ValidationError("You can only review delivered orders.")
        serializer.save()

class RecommendationViewSet(viewsets.ViewSet):
    permission_classes = [IsAuthenticated]

    @action(detail=False, methods=['get'])
    def for_you(self, request):
        # Phase 4: Big Data Recommendations (Lightweight Collaborative Filtering Mock)
        # Suggest food from restaurants the user hasn't ordered from yet, 
        # or highly rated foods in the categories they order most.
        user_orders = Order.objects.filter(customer=request.user).prefetch_related('items__food_item__category')
        favorite_categories = set()
        for order in user_orders:
            for item in order.items.all():
                favorite_categories.add(item.food_item.category.name)
        
        if favorite_categories:
            recommended_foods = FoodItem.objects.filter(category__name__in=favorite_categories, is_available=True).order_by('?')[:10]
        else:
            recommended_foods = FoodItem.objects.filter(is_available=True).order_by('?')[:10]
            
        serializer = FoodItemSerializer(recommended_foods, many=True, context={'request': request})
        return Response(serializer.data)
"""

if "class ReviewViewSet" not in content:
    content += "\n" + views_code
    with open('backend/core/views.py', 'w') as f:
        f.write(content)
