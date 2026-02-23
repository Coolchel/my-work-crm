from unittest.mock import patch

from django.contrib.auth import get_user_model
from django.db.utils import OperationalError
from rest_framework import status
from rest_framework.test import APITestCase

from core.models import Project, Stage


class ApiContractBase(APITestCase):
    def setUp(self):
        self.user_password = 'StrongPass123!'
        self.user = get_user_model().objects.create_user(
            username='contract_user',
            email='contract_user@example.com',
            password=self.user_password,
        )

    def authenticate(self):
        token_response = self.client.post(
            '/api/auth/token/',
            {
                'username': self.user.username,
                'password': self.user_password,
            },
            format='json',
        )
        self.assertEqual(token_response.status_code, status.HTTP_200_OK)
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {token_response.data['access']}",
        )


class AuthRequiredContractsTests(ApiContractBase):
    def test_business_endpoints_require_auth(self):
        endpoints = [
            '/api/projects/',
            '/api/stages/',
            '/api/statistics/',
            '/api/directory-sections/',
        ]

        for endpoint in endpoints:
            response = self.client.get(endpoint)
            self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_business_endpoints_available_with_auth(self):
        self.authenticate()
        Project.objects.create(address='Contract address', client_info='Client', source='Source')

        responses = {
            '/api/projects/': self.client.get('/api/projects/'),
            '/api/stages/': self.client.get('/api/stages/'),
            '/api/statistics/': self.client.get('/api/statistics/'),
            '/api/directory-sections/': self.client.get('/api/directory-sections/'),
        }

        self.assertEqual(responses['/api/projects/'].status_code, status.HTTP_200_OK)
        self.assertEqual(responses['/api/stages/'].status_code, status.HTTP_200_OK)
        self.assertEqual(responses['/api/statistics/'].status_code, status.HTTP_200_OK)
        self.assertEqual(responses['/api/directory-sections/'].status_code, status.HTTP_200_OK)


class FinanceSingletonContractsTests(ApiContractBase):
    def test_finance_singleton_contract(self):
        self.authenticate()

        list_response = self.client.get('/api/finance/')
        self.assertEqual(list_response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(list_response.data), 1)
        self.assertEqual(list_response.data[0]['id'], 1)

        detail_response = self.client.get('/api/finance/1/')
        self.assertEqual(detail_response.status_code, status.HTTP_200_OK)
        self.assertEqual(detail_response.data['id'], 1)

        patch_response = self.client.patch(
            '/api/finance/1/',
            {'financial_notes': 'contract update'},
            format='json',
        )
        self.assertEqual(patch_response.status_code, status.HTTP_200_OK)
        self.assertEqual(patch_response.data['financial_notes'], 'contract update')


class DirectoryContractsTests(ApiContractBase):
    def test_directory_sections_not_ready_returns_empty_list(self):
        self.authenticate()
        with patch(
            'core.views.DirectorySectionViewSet.get_queryset',
            side_effect=OperationalError('no such table: core_directorysection'),
        ):
            response = self.client.get('/api/directory-sections/')

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data, [])

    def test_directory_bootstrap_not_ready_returns_503(self):
        self.authenticate()
        with patch(
            'core.views._bootstrap_directory_from_choices',
            side_effect=OperationalError('no such table: core_directorysection'),
        ):
            response = self.client.post('/api/directory-sections/bootstrap/')

        self.assertEqual(response.status_code, status.HTTP_503_SERVICE_UNAVAILABLE)
        self.assertIn('error', response.data)

    def test_directory_bootstrap_happy_path(self):
        self.authenticate()
        with patch(
            'core.views._bootstrap_directory_from_choices',
            return_value={
                'created_sections': 2,
                'created_entries': 5,
                'total_sections': 3,
                'total_entries': 8,
            },
        ):
            response = self.client.post('/api/directory-sections/bootstrap/')

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['created_sections'], 2)
        self.assertEqual(response.data['total_entries'], 8)


class StageAutomationContractsTests(ApiContractBase):
    def setUp(self):
        super().setUp()
        self.project = Project.objects.create(
            address='Automation address',
            client_info='Automation client',
            source='Automation source',
        )
        self.stage = Stage.objects.create(project=self.project, title='stage_2')

    def test_import_from_shields_happy_path(self):
        self.authenticate()
        with patch(
            'core.services.EstimateAutomationService.import_shield_to_materials',
            return_value={'status': 'ok', 'created': 4},
        ) as mocked:
            response = self.client.post(f'/api/stages/{self.stage.id}/import_from_shields/')

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['created'], 4)
        mocked.assert_called_once_with(self.project.id, self.stage.id)

    def test_import_from_shields_error_path(self):
        self.authenticate()
        with patch(
            'core.services.EstimateAutomationService.import_shield_to_materials',
            return_value={'status': 'error', 'error': 'no shield data'},
        ):
            response = self.client.post(f'/api/stages/{self.stage.id}/import_from_shields/')

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(response.data['status'], 'error')

    def test_calculate_works_happy_path(self):
        self.authenticate()
        with patch(
            'core.services.EstimateAutomationService.calculate_works_from_materials',
            return_value={'status': 'ok', 'created': 3, 'replaced': 2},
        ) as mocked:
            response = self.client.post(f'/api/stages/{self.stage.id}/calculate_works/')

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['created'], 3)
        mocked.assert_called_once_with(self.stage.id)

    def test_calculate_works_error_path(self):
        self.authenticate()
        with patch(
            'core.services.EstimateAutomationService.calculate_works_from_materials',
            return_value={'status': 'error', 'error': 'no mappings'},
        ):
            response = self.client.post(f'/api/stages/{self.stage.id}/calculate_works/')

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(response.data['status'], 'error')
