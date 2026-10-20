from decimal import Decimal
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from core.models import User

class AuthenticationTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            username='testcustomer',
            email='customer@example.com',
            password='Password123!',
            first_name='Test',
            last_name='Customer',
            role='customer',
            phone='+85512345678'
        )
        self.token_url = reverse('token_obtain_pair')
        self.refresh_url = reverse('token_refresh')
        self.register_url = reverse('register')
        self.me_url = reverse('user-me')
        self.logout_url = reverse('auth_logout')
        self.change_password_url = reverse('change_password')

    def test_login_with_username_success(self):
        payload = {
            'username': 'testcustomer',
            'password': 'Password123!'
        }
        res = self.client.post(self.token_url, payload, format='json')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertIn('access', res.data)
        self.assertIn('refresh', res.data)

    def test_login_with_email_case_insensitive_success(self):
        # EmailAuthBackend allows logging in via email with case-insensitivity
        payload = {
            'username': 'CUSTOMER@EXAMPLE.COM',
            'password': 'Password123!'
        }
        res = self.client.post(self.token_url, payload, format='json')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertIn('access', res.data)
        self.assertIn('refresh', res.data)

    def test_login_invalid_password_returns_401(self):
        payload = {
            'username': 'testcustomer',
            'password': 'WrongPassword999'
        }
        res = self.client.post(self.token_url, payload, format='json')
        self.assertEqual(res.status_code, status.HTTP_401_UNAUTHORIZED)
        self.assertIn('detail', res.data)

    def test_login_unknown_user_returns_401(self):
        payload = {
            'username': 'nonexistent_user',
            'password': 'Password123!'
        }
        res = self.client.post(self.token_url, payload, format='json')
        self.assertEqual(res.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_login_missing_fields_returns_400(self):
        res = self.client.post(self.token_url, {'username': 'testcustomer'}, format='json')
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)

    def test_registration_success(self):
        payload = {
            'username': 'newuser123',
            'email': 'newuser@example.com',
            'password': 'SecurePassword456',
            'first_name': 'New',
            'last_name': 'User',
            'phone': '+85598765432'
        }
        res = self.client.post(self.register_url, payload, format='json')
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data['username'], 'newuser123')
        self.assertEqual(res.data['email'], 'newuser@example.com')
        # Ensure role defaults to 'customer'
        new_user = User.objects.get(username='newuser123')
        self.assertEqual(new_user.role, 'customer')

    def test_registration_duplicate_username_rejected(self):
        payload = {
            'username': 'TESTCUSTOMER', # case-insensitive duplicate
            'email': 'different_email@example.com',
            'password': 'SecurePassword456'
        }
        res = self.client.post(self.register_url, payload, format='json')
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('username', res.data)

    def test_registration_duplicate_email_rejected(self):
        payload = {
            'username': 'completely_new_username',
            'email': 'CUSTOMER@EXAMPLE.COM', # case-insensitive duplicate
            'password': 'SecurePassword456'
        }
        res = self.client.post(self.register_url, payload, format='json')
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('email', res.data)

    def test_registration_username_with_spaces_rejected(self):
        payload = {
            'username': 'Alice Smith',
            'email': 'alice.smith@example.com',
            'password': 'SecurePassword456'
        }
        res = self.client.post(self.register_url, payload, format='json')
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('username', res.data)

    def test_registration_short_password_rejected(self):
        payload = {
            'username': 'validusername',
            'email': 'valid@example.com',
            'password': '123'
        }
        res = self.client.post(self.register_url, payload, format='json')
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('password', res.data)

    def test_token_refresh_lifecycle(self):
        login_res = self.client.post(self.token_url, {'username': 'testcustomer', 'password': 'Password123!'}, format='json')
        refresh_token = login_res.data['refresh']

        refresh_res = self.client.post(self.refresh_url, {'refresh': refresh_token}, format='json')
        self.assertEqual(refresh_res.status_code, status.HTTP_200_OK)
        self.assertIn('access', refresh_res.data)

    def test_user_me_profile_retrieval(self):
        # Anonymous fails
        anon_res = self.client.get(self.me_url)
        self.assertEqual(anon_res.status_code, status.HTTP_401_UNAUTHORIZED)

        # Authenticated succeeds
        self.client.force_authenticate(user=self.user)
        auth_res = self.client.get(self.me_url)
        self.assertEqual(auth_res.status_code, status.HTTP_200_OK)
        self.assertEqual(auth_res.data['username'], 'testcustomer')
        self.assertEqual(auth_res.data['role'], 'customer')

    def test_user_cannot_escalate_role_via_profile_update(self):
        self.client.force_authenticate(user=self.user)
        update_res = self.client.patch(self.me_url, {'role': 'admin'}, format='json')
        self.assertEqual(update_res.status_code, status.HTTP_200_OK)
        self.user.refresh_from_db()
        # Role must remain customer (role is read-only)
        self.assertEqual(self.user.role, 'customer')

    def test_logout_endpoint(self):
        self.client.force_authenticate(user=self.user)
        login_res = self.client.post(self.token_url, {'username': 'testcustomer', 'password': 'Password123!'}, format='json')
        refresh_token = login_res.data['refresh']

        logout_res = self.client.post(self.logout_url, {'refresh': refresh_token}, format='json')
        self.assertEqual(logout_res.status_code, status.HTTP_200_OK)

    def test_change_password_endpoint(self):
        self.client.force_authenticate(user=self.user)
        # 1. Wrong old password fails
        bad_res = self.client.post(self.change_password_url, {'old_password': 'wrong', 'new_password': 'BrandNewPass123'}, format='json')
        self.assertEqual(bad_res.status_code, status.HTTP_400_BAD_REQUEST)

        # 2. Correct old password succeeds
        good_res = self.client.post(self.change_password_url, {'old_password': 'Password123!', 'new_password': 'BrandNewPass123'}, format='json')
        self.assertEqual(good_res.status_code, status.HTTP_200_OK)

        # 3. New password works for subsequent login
        self.client.logout()
        login_res = self.client.post(self.token_url, {'username': 'testcustomer', 'password': 'BrandNewPass123'}, format='json')
        self.assertEqual(login_res.status_code, status.HTTP_200_OK)
