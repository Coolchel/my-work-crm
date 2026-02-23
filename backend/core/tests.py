from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.test import APITestCase
from core.models import FinanceSettings


class ApiAccessControlTests(APITestCase):
    def setUp(self):
        self.user_password = 'StrongPass123!'
        self.user = get_user_model().objects.create_user(
            username='api_user',
            email='api_user@example.com',
            password=self.user_password,
        )

    def _get_access_token(self):
        response = self.client.post(
            '/api/auth/token/',
            {
                'username': self.user.username,
                'password': self.user_password,
            },
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('access', response.data)
        self.assertIn('refresh', response.data)
        return response.data['access']

    def test_unauthenticated_cannot_access_projects_list(self):
        response = self.client.get('/api/projects/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_unauthenticated_cannot_access_stages_list(self):
        response = self.client.get('/api/stages/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_unauthenticated_cannot_access_directory_sections(self):
        response = self.client.get('/api/directory-sections/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_unauthenticated_can_get_token(self):
        response = self.client.post(
            '/api/auth/token/',
            {
                'username': self.user.username,
                'password': self.user_password,
            },
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('access', response.data)
        self.assertIn('refresh', response.data)

    def test_authenticated_can_access_projects_list(self):
        access_token = self._get_access_token()
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {access_token}')

        response = self.client.get('/api/projects/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_unauthenticated_cannot_access_finance(self):
        response = self.client.get('/api/finance/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_authenticated_can_access_auth_me(self):
        access_token = self._get_access_token()
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {access_token}')

        response = self.client.get('/api/auth/me/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['username'], self.user.username)


class FinanceSettingsApiTests(APITestCase):
    def setUp(self):
        self.user_password = 'StrongPass123!'
        self.user = get_user_model().objects.create_user(
            username='finance_user',
            email='finance_user@example.com',
            password=self.user_password,
        )

    def _authenticate(self):
        token_response = self.client.post(
            '/api/auth/token/',
            {
                'username': self.user.username,
                'password': self.user_password,
            },
            format='json',
        )
        self.assertEqual(token_response.status_code, status.HTTP_200_OK)
        access = token_response.data['access']
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {access}')

    def test_finance_unauthenticated_requests_return_401(self):
        list_response = self.client.get('/api/finance/')
        detail_response = self.client.get('/api/finance/1/')
        patch_response = self.client.patch(
            '/api/finance/1/',
            {'financial_notes': 'unauthorized'},
            format='json',
        )

        self.assertEqual(list_response.status_code, status.HTTP_401_UNAUTHORIZED)
        self.assertEqual(detail_response.status_code, status.HTTP_401_UNAUTHORIZED)
        self.assertEqual(patch_response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_finance_list_returns_settings(self):
        self._authenticate()

        response = self.client.get('/api/finance/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIsInstance(response.data, list)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]['id'], 1)

    def test_finance_detail_returns_settings(self):
        self._authenticate()

        response = self.client.get('/api/finance/1/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['id'], 1)

    def test_finance_patch_updates_financial_notes_and_persists(self):
        self._authenticate()
        new_notes = 'Updated financial notes from PATCH'

        patch_response = self.client.patch(
            '/api/finance/1/',
            {'financial_notes': new_notes},
            format='json',
        )
        self.assertEqual(patch_response.status_code, status.HTTP_200_OK)
        self.assertEqual(patch_response.data['financial_notes'], new_notes)

        db_settings = FinanceSettings.load()
        self.assertEqual(db_settings.financial_notes, new_notes)

        get_response = self.client.get('/api/finance/1/')
        self.assertEqual(get_response.status_code, status.HTTP_200_OK)
        self.assertEqual(get_response.data['financial_notes'], new_notes)
