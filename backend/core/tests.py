import os
import shutil
import tempfile
from decimal import Decimal

from django.conf import settings
from django.contrib.auth import get_user_model
from django.core.files.uploadedfile import SimpleUploadedFile
from rest_framework import status
from rest_framework.test import APITestCase
from core.models import FinanceSettings
from core.models import Project, ProjectFile
from core.models import Stage, CatalogCategory, CatalogItem, EstimateItem


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


class ProjectFileValidationTests(APITestCase):
    def setUp(self):
        self.user_password = 'StrongPass123!'
        self.user = get_user_model().objects.create_user(
            username='project_file_user',
            email='project_file_user@example.com',
            password=self.user_password,
        )
        self.project = Project.objects.create(
            address='Test address',
            client_info='Test client',
            source='Test source',
        )

        self._old_media_root = settings.MEDIA_ROOT
        self._temp_media_root = tempfile.mkdtemp(prefix='project_file_tests_')
        settings.MEDIA_ROOT = self._temp_media_root

    def tearDown(self):
        settings.MEDIA_ROOT = self._old_media_root
        shutil.rmtree(self._temp_media_root, ignore_errors=True)

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

    def _upload_file(self, name='test.txt', content=b'content'):
        upload = SimpleUploadedFile(name=name, content=content, content_type='text/plain')
        return self.client.post(
            '/api/project-files/',
            {'project': self.project.id, 'file': upload, 'description': 'desc', 'category': 'PROJECT'},
            format='multipart',
        )

    def test_create_project_file_under_limit_success(self):
        self._authenticate()

        response = self._upload_file(name='under_limit.txt', content=b'ok')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(ProjectFile.objects.filter(project=self.project).count(), 1)

    def test_create_13th_file_returns_400(self):
        self._authenticate()

        for i in range(12):
            response = self._upload_file(name=f'file_{i}.txt', content=b'ok')
            self.assertEqual(response.status_code, status.HTTP_201_CREATED)

        thirteenth_response = self._upload_file(name='file_13.txt', content=b'overflow')
        self.assertEqual(thirteenth_response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('project', thirteenth_response.data)

    def test_create_file_over_20mb_returns_400(self):
        self._authenticate()
        too_large_content = b'a' * ((20 * 1024 * 1024) + 1)

        response = self._upload_file(name='too_large.bin', content=too_large_content)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('file', response.data)

    def test_delete_file_removes_record_and_physical_file(self):
        self._authenticate()
        create_response = self._upload_file(name='to_delete.txt', content=b'delete me')
        self.assertEqual(create_response.status_code, status.HTTP_201_CREATED)

        file_id = create_response.data['id']
        file_record = ProjectFile.objects.get(pk=file_id)
        file_path = file_record.file.path
        self.assertTrue(os.path.exists(file_path))

        delete_response = self.client.delete(f'/api/project-files/{file_id}/')
        self.assertEqual(delete_response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(ProjectFile.objects.filter(pk=file_id).exists())
        self.assertFalse(os.path.exists(file_path))

    def test_patch_metadata_without_new_file_does_not_trigger_size_check(self):
        self._authenticate()
        create_response = self._upload_file(name='patch_meta.txt', content=b'patch')
        self.assertEqual(create_response.status_code, status.HTTP_201_CREATED)

        file_id = create_response.data['id']
        patch_response = self.client.patch(
            f'/api/project-files/{file_id}/',
            {'description': 'updated metadata only'},
            format='json',
        )

        self.assertEqual(patch_response.status_code, status.HTTP_200_OK)
        self.assertEqual(patch_response.data['description'], 'updated metadata only')


class StageAtomicOperationsTests(APITestCase):
    def setUp(self):
        self.user_password = 'StrongPass123!'
        self.user = get_user_model().objects.create_user(
            username='stage_atomic_user',
            email='stage_atomic_user@example.com',
            password=self.user_password,
        )
        self.project = Project.objects.create(
            address='Atomic project',
            client_info='Atomic client',
            source='Atomic source',
        )
        self.precalc_stage = Stage.objects.create(project=self.project, title='precalc')
        self.stage_1 = Stage.objects.create(project=self.project, title='stage_1')
        self.stage_3 = Stage.objects.create(project=self.project, title='stage_3')

        self.material_category = CatalogCategory.objects.create(
            name='Materials',
            slug='materials',
        )
        self.work_category = CatalogCategory.objects.create(
            name='Works',
            slug='works',
        )
        self.material_catalog = CatalogItem.objects.create(
            name='Armature Material',
            category=self.material_category,
            unit='pcs',
            default_price=Decimal('10.00'),
            default_currency='USD',
            item_type='material',
        )
        self.work_catalog = CatalogItem.objects.create(
            name='Work Item',
            category=self.work_category,
            unit='pcs',
            default_price=Decimal('5.00'),
            default_currency='USD',
            item_type='work',
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

    def test_import_from_precalc_section_success_replaces_target(self):
        self._authenticate()

        EstimateItem.objects.create(
            stage=self.precalc_stage,
            item_type='work',
            name='Precalc Work 1',
            unit='pcs',
            total_quantity=Decimal('2'),
            price_per_unit=Decimal('20'),
            currency='USD',
            employer_quantity=Decimal('1'),
        )
        EstimateItem.objects.create(
            stage=self.precalc_stage,
            item_type='work',
            name='Precalc Work 2',
            unit='pcs',
            total_quantity=Decimal('3'),
            price_per_unit=Decimal('30'),
            currency='USD',
            employer_quantity=Decimal('0'),
        )
        EstimateItem.objects.create(
            stage=self.stage_1,
            item_type='work',
            name='Old Work',
            unit='pcs',
            total_quantity=Decimal('1'),
            price_per_unit=Decimal('99'),
            currency='USD',
            employer_quantity=Decimal('0'),
        )

        response = self.client.post(
            f'/api/stages/{self.stage_1.id}/import_from_precalc_section/',
            {'item_type': 'work'},
            format='json',
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['deleted'], 1)
        self.assertEqual(response.data['created'], 2)

        names = list(
            EstimateItem.objects.filter(stage=self.stage_1, item_type='work')
            .order_by('name')
            .values_list('name', flat=True)
        )
        self.assertEqual(names, ['Precalc Work 1', 'Precalc Work 2'])

    def test_apply_stage3_armature_rollback_on_mid_error(self):
        self._authenticate()

        EstimateItem.objects.create(
            stage=self.stage_3,
            item_type='material',
            name='Old Material',
            unit='pcs',
            total_quantity=Decimal('5'),
            price_per_unit=Decimal('7'),
            currency='USD',
            employer_quantity=Decimal('0'),
        )

        response = self.client.post(
            f'/api/stages/{self.stage_3.id}/apply_stage3_armature/',
            [
                {'catalog_item': self.material_catalog.id, 'quantity': 2},
                {'catalog_item': self.material_catalog.id, 'quantity': 'bad-number'},
            ],
            format='json',
        )

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('error', response.data)

        stage_material_names = list(
            EstimateItem.objects.filter(stage=self.stage_3, item_type='material')
            .order_by('name')
            .values_list('name', flat=True)
        )
        self.assertEqual(stage_material_names, ['Old Material'])

    def test_apply_stage3_armature_restricted_for_non_stage3(self):
        self._authenticate()

        response = self.client.post(
            f'/api/stages/{self.stage_1.id}/apply_stage3_armature/',
            [{'catalog_item': self.material_catalog.id, 'quantity': 1}],
            format='json',
        )

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('error', response.data)

    def test_apply_stage3_armature_restricted_for_non_material_catalog_item(self):
        self._authenticate()

        response = self.client.post(
            f'/api/stages/{self.stage_3.id}/apply_stage3_armature/',
            [{'catalog_item': self.work_catalog.id, 'quantity': 1}],
            format='json',
        )

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('error', response.data)

    def test_import_from_precalc_section_restricted_for_non_transfer_stage(self):
        self._authenticate()

        response = self.client.post(
            f'/api/stages/{self.stage_3.id}/import_from_precalc_section/',
            {'item_type': 'material'},
            format='json',
        )

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('error', response.data)
