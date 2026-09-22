import re

with open('backend/core/serializers.py', 'r') as f:
    content = f.read()

serializers = """
class ReviewSerializer(serializers.ModelSerializer):
    class Meta:
        model = Review
        fields = '__all__'
"""

if "class ReviewSerializer" not in content:
    content += "\n" + serializers
    with open('backend/core/serializers.py', 'w') as f:
        f.write(content)
