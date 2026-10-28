from unittest.mock import patch, MagicMock
from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient
from rest_framework import status

from core.models import User, Address, PhoneOTPChallenge
from core.mongodb import (
    save_user_mongo,
    get_user_mongo,
    record_user_login_mongo,
    get_user_logins_mongo,
    sync_all_users_to_mongo,
    get_mongo_stats,
)


class MongoUserSyncTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            username='mongouser',
            email='mongouser@example.com',
            password='StrongPassword123!',
            first_name='Mongo',
            last_name='Tester',
            role='customer',
            phone='+85512345678',
            is_phone_verified=True,
            phone_verified_at=timezone.now()
        )
        self.address = Address.objects.create(
            user=self.user,
            street='Street 240',
            city='Phnom Penh',
            state='Phnom Penh',
            zip_code='12000',
            label='home',
            is_default=True
        )

    @patch('core.mongodb.get_mongo_db')
    def test_save_user_mongo_success(self, mock_get_db):
        mock_db = MagicMock()
        mock_get_db.return_value = mock_db

        success = save_user_mongo(self.user)
        self.assertTrue(success)
        mock_db.users.update_one.assert_called_once()
        args, kwargs = mock_db.users.update_one.call_args
        filter_query = args[0]
        update_doc = args[1]

        self.assertEqual(filter_query, {'user_id': self.user.id})
        self.assertIn('$set', update_doc)
        set_fields = update_doc['$set']
        self.assertEqual(set_fields['username'], 'mongouser')
        self.assertEqual(set_fields['email'], 'mongouser@example.com')
        self.assertEqual(set_fields['role'], 'customer')
        self.assertEqual(set_fields['full_name'], 'Mongo Tester')
        self.assertTrue(set_fields['is_phone_verified'])
        self.assertIn('default_address', set_fields)
        self.assertEqual(set_fields['default_address']['street'], 'Street 240')

    @patch('core.mongodb.get_mongo_db')
    def test_save_user_mongo_dict(self, mock_get_db):
        mock_db = MagicMock()
        mock_get_db.return_value = mock_db

        user_dict = {
            'user_id': 999,
            'username': 'dictuser',
            'email': 'dict@example.com',
            'role': 'driver',
        }
        success = save_user_mongo(user_dict)
        self.assertTrue(success)
        mock_db.users.update_one.assert_called_once()

    @patch('core.mongodb.get_mongo_db')
    def test_save_user_mongo_when_mongo_offline(self, mock_get_db):
        mock_get_db.return_value = None
        success = save_user_mongo(self.user)
        self.assertFalse(success)

    @patch('core.mongodb.get_mongo_db')
    def test_get_user_mongo(self, mock_get_db):
        mock_db = MagicMock()
        mock_db.users.find_one.return_value = {
            'user_id': self.user.id,
            'username': 'mongouser',
            'email': 'mongouser@example.com'
        }
        mock_get_db.return_value = mock_db

        doc = get_user_mongo(self.user.id)
        self.assertIsNotNone(doc)
        self.assertEqual(doc['user_id'], self.user.id)
        self.assertEqual(doc['username'], 'mongouser')

    @patch('core.mongodb.get_mongo_db')
    def test_record_user_login_mongo(self, mock_get_db):
        mock_db = MagicMock()
        mock_get_db.return_value = mock_db

        success = record_user_login_mongo(
            user=self.user,
            login_method='jwt_password',
            ip_address='192.168.1.100',
            user_agent='FoodGoMobileApp/2.0'
        )
        self.assertTrue(success)

        # Verified login record inserted
        mock_db.user_logins.insert_one.assert_called_once()
        login_insert = mock_db.user_logins.insert_one.call_args[0][0]
        self.assertEqual(login_insert['user_id'], self.user.id)
        self.assertEqual(login_insert['login_method'], 'jwt_password')
        self.assertEqual(login_insert['ip_address'], '192.168.1.100')
        self.assertEqual(login_insert['user_agent'], 'FoodGoMobileApp/2.0')

        # Verified user record updated with login count increment
        mock_db.users.update_one.assert_called_once()
        user_update = mock_db.users.update_one.call_args[0][1]
        self.assertEqual(user_update['$set']['last_login_method'], 'jwt_password')
        self.assertEqual(user_update['$set']['last_login_ip'], '192.168.1.100')
        self.assertEqual(user_update['$inc']['login_count'], 1)

    @patch('core.mongodb.get_mongo_db')
    def test_get_user_logins_mongo(self, mock_get_db):
        mock_db = MagicMock()
        mock_cursor = MagicMock()
        mock_cursor.sort.return_value = mock_cursor
        mock_cursor.limit.return_value = [
            {'user_id': self.user.id, 'login_method': 'jwt_password', 'timestamp': '2026-10-28T12:00:00'},
            {'user_id': self.user.id, 'login_method': 'phone_otp', 'timestamp': '2026-10-28T10:00:00'},
        ]
        mock_db.user_logins.find.return_value = mock_cursor
        mock_get_db.return_value = mock_db

        history = get_user_logins_mongo(self.user.id, limit=5)
        self.assertEqual(len(history), 2)
        self.assertEqual(history[0]['login_method'], 'jwt_password')
        self.assertEqual(history[1]['login_method'], 'phone_otp')

    @patch('core.mongodb.get_mongo_db')
    def test_sync_all_users_to_mongo(self, mock_get_db):
        mock_db = MagicMock()
        mock_get_db.return_value = mock_db

        res = sync_all_users_to_mongo()
        self.assertGreaterEqual(res.get('total', 0), 1)
        self.assertGreaterEqual(res.get('synced', 0), 1)
        self.assertEqual(res.get('status'), 'success')

    @patch('core.mongodb.get_mongo_db')
    def test_get_mongo_stats_includes_users_and_logins(self, mock_get_db):
        mock_db = MagicMock()
        mock_db.list_collection_names.return_value = ['orders', 'restaurants', 'food_items', 'users', 'user_logins']
        mock_db.users.estimated_document_count.return_value = 42
        mock_db.user_logins.estimated_document_count.return_value = 150
        mock_get_db.return_value = mock_db

        stats = get_mongo_stats()
        self.assertTrue(stats.get('available'))
        counts = stats.get('counts', {})
        self.assertIn('users', counts)
        self.assertIn('user_logins', counts)
        self.assertEqual(counts['users'], 42)
        self.assertEqual(counts['user_logins'], 150)

    @patch('core.signals._run_async')
    def test_jwt_login_triggers_mongo_record(self, mock_run_async):
        response = self.client.post('/api/token/', {
            'username': 'mongouser',
            'password': 'StrongPassword123!'
        })
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('access', response.data)
        self.assertIn('refresh', response.data)
        mock_run_async.assert_called()

    @patch('core.signals._run_async')
    def test_google_login_triggers_mongo_record(self, mock_run_async):
        response = self.client.post('/api/auth/google/', {
            'id_token': 'mock-google-token-test',
            'email': 'mongouser@example.com',
            'name': 'Mongo Tester'
        })
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        mock_run_async.assert_called()

    @patch('core.signals._run_async')
    def test_phone_verify_login_triggers_mongo_record(self, mock_run_async):
        from core.sms_service import hash_otp, generate_salt
        salt = generate_salt()
        hashed = hash_otp("123456", salt)
        challenge = PhoneOTPChallenge.objects.create(
            phone_raw='+85512345678',
            phone_normalized='+85512345678',
            purpose='phone_login',
            hashed_otp=hashed,
            salt=salt,
            expires_at=timezone.now() + timezone.timedelta(minutes=5),
            resend_available_at=timezone.now() + timezone.timedelta(minutes=1),
        )

        response = self.client.post('/api/auth/phone/verify-otp/', {
            'phone': '+85512345678',
            'otp': '123456',
            'purpose': 'phone_login'
        })
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('access', response.data)
        mock_run_async.assert_called()
