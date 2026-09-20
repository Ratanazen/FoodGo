import re
with open('backend/core/views.py', 'r') as f:
    content = f.read()

user_view_code = """
from .serializers_user import UserSerializer

class UserMeView(generics.RetrieveUpdateAPIView):
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]

    def get_object(self):
        return self.request.user
"""

content = content.replace('class UserRegistrationView', user_view_code + '\nclass UserRegistrationView')

with open('backend/core/views.py', 'w') as f:
    f.write(content)

with open('backend/core/urls.py', 'r') as f:
    urls_content = f.read()

urls_content = urls_content.replace(
    "path('register/', UserRegistrationView.as_view(), name='register'),",
    "path('register/', UserRegistrationView.as_view(), name='register'),\n    path('me/', UserMeView.as_view(), name='user-me'),"
)

with open('backend/core/urls.py', 'w') as f:
    f.write(urls_content)

print("Backend patched")
