from rest_framework import viewsets, status, filters, mixins
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from decimal import Decimal, InvalidOperation
from django.db.models import Case, Count, DecimalField, ExpressionWrapper, F, Q, Sum, Value, When
from django.db.models.functions import Coalesce, TruncDate, TruncMonth
from django.db import transaction
from django.db.utils import OperationalError, ProgrammingError
from .models import (
    Project, Stage, ShieldGroup, LedZone, CatalogCategory, CatalogItem, DirectorySection, DirectoryEntry,
    Shield, EstimateItem, WorkTemplate, MaterialTemplate, PowerShieldTemplate, LedShieldTemplate,
    FinanceSettings, ProjectFile
)
from .serializers import (
    ProjectSerializer, StageSerializer, CatalogCategorySerializer, CatalogItemSerializer, DirectorySectionSerializer, DirectoryEntrySerializer,
    ShieldGroupSerializer, LedZoneSerializer, ShieldSerializer, EstimateItemSerializer,
    WorkTemplateSerializer, MaterialTemplateSerializer, 
    PowerShieldTemplateSerializer, LedShieldTemplateSerializer,
    FinanceSettingsSerializer, ProjectFileSerializer
)
from .services import TemplateService


DIRECTORY_SECTION_DEFINITIONS = [
    {
        'code': 'project_status',
        'name': 'Статусы проекта',
        'description': 'Варианты состояния проекта.'
    },
    {
        'code': 'object_type',
        'name': 'Типы объектов',
        'description': 'Варианты типа объекта проекта.'
    },
    {
        'code': 'stage_title',
        'name': 'Название этапа',
        'description': 'Варианты названий этапов.'
    },
    {
        'code': 'stage_status',
        'name': 'Статус этапа',
        'description': 'Состояния этапа выполнения.'
    },
    {
        'code': 'catalog_item_type',
        'name': 'Тип позиции каталога',
        'description': 'Работа или материал.'
    },
    {
        'code': 'currency',
        'name': 'Валюты',
        'description': 'Поддерживаемые валюты.'
    },
    {
        'code': 'estimate_item_type',
        'name': 'Тип позиции сметы',
        'description': 'Типы позиций сметы.'
    },
    {
        'code': 'shield_type',
        'name': 'Типы щитов',
        'description': 'Типы инженерных щитов.'
    },
    {
        'code': 'shield_mounting',
        'name': 'Типы монтажа щитов',
        'description': 'Способ монтажа щита.'
    },
    {
        'code': 'shield_device_type',
        'name': 'Типы устройств щита',
        'description': 'Устройства внутри силового щита.'
    },
    {
        'code': 'project_file_category',
        'name': 'Категории файлов проекта',
        'description': 'Категории файлов в проекте.'
    },
]




def _is_directory_table_error(error):
    error_text = str(error).lower()
    return (
        'core_directorysection' in error_text
        or 'core_directoryentry' in error_text
        or 'no such table' in error_text
        or 'does not exist' in error_text
    )

def _directory_tables_not_ready_response():
    return Response(
        {
            'error': 'Directory tables are not ready. Please run migrations.',
        },
        status=status.HTTP_503_SERVICE_UNAVAILABLE,
    )

def _bootstrap_directory_from_choices():
    mapping = [
        ('project_status', Project.STATUS_CHOICES),
        ('object_type', Project.OBJECT_TYPE_CHOICES),
        ('stage_title', Stage.TITLE_CHOICES),
        ('stage_status', Stage.STATUS_CHOICES),
        ('catalog_item_type', CatalogItem.TYPE_CHOICES),
        ('currency', CatalogItem.CURRENCY_CHOICES),
        ('estimate_item_type', EstimateItem.TYPE_CHOICES),
        ('shield_type', Shield.SHIELD_TYPE_CHOICES),
        ('shield_mounting', Shield.MOUNTING_CHOICES),
        ('shield_device_type', ShieldGroup.DEVICE_CHOICES),
        ('project_file_category', ProjectFile.CATEGORY_CHOICES),
    ]

    created_sections = 0
    created_entries = 0

    for section_def in DIRECTORY_SECTION_DEFINITIONS:
        section, is_created = DirectorySection.objects.get_or_create(
            code=section_def['code'],
            defaults={
                'name': section_def['name'],
                'description': section_def['description'],
            },
        )
        if is_created:
            created_sections += 1

        section.name = section_def['name']
        section.description = section_def['description']
        section.save(update_fields=['name', 'description'])

    for section_code, choices in mapping:
        section = DirectorySection.objects.get(code=section_code)
        for index, (code, name) in enumerate(choices):
            _, is_created = DirectoryEntry.objects.update_or_create(
                section=section,
                code=code,
                defaults={
                    'name': name,
                    'sort_order': index,
                    'is_active': True,
                },
            )
            if is_created:
                created_entries += 1

    return {
        'created_sections': created_sections,
        'created_entries': created_entries,
        'total_sections': DirectorySection.objects.count(),
        'total_entries': DirectoryEntry.objects.count(),
    }

class AuthenticatedModelViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]


class AuthenticatedViewSet(viewsets.ViewSet):
    permission_classes = [IsAuthenticated]


class ProjectFileViewSet(AuthenticatedModelViewSet):
    queryset = ProjectFile.objects.all()
    serializer_class = ProjectFileSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['project', 'category']

    def perform_destroy(self, instance):
        # Физическое удаление файла с диска
        if instance.file:
            instance.file.delete(save=False)
        instance.delete()


class CatalogCategoryViewSet(AuthenticatedModelViewSet):
    queryset = CatalogCategory.objects.all()
    serializer_class = CatalogCategorySerializer


class CatalogItemViewSet(AuthenticatedModelViewSet):
    queryset = CatalogItem.objects.all()
    serializer_class = CatalogItemSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['category', 'item_type']
    
    def get_queryset(self):
        qs = super().get_queryset()
        search_query = self.request.query_params.get('search')
        if search_query:
            qs = qs.filter(search_name__contains=search_query.lower())
        return qs


class DirectorySectionViewSet(AuthenticatedModelViewSet):
    queryset = DirectorySection.objects.prefetch_related('entries').all()
    serializer_class = DirectorySectionSerializer

    def _handle_directory_db_error(self, error):
        if _is_directory_table_error(error):
            return _directory_tables_not_ready_response()
        raise error

    def retrieve(self, request, *args, **kwargs):
        try:
            return super().retrieve(request, *args, **kwargs)
        except (OperationalError, ProgrammingError) as error:
            return self._handle_directory_db_error(error)

    def list(self, request, *args, **kwargs):
        try:
            return super().list(request, *args, **kwargs)
        except (OperationalError, ProgrammingError) as error:
            if _is_directory_table_error(error):
                return Response([])
            raise

    def create(self, request, *args, **kwargs):
        try:
            return super().create(request, *args, **kwargs)
        except (OperationalError, ProgrammingError) as error:
            return self._handle_directory_db_error(error)

    def update(self, request, *args, **kwargs):
        try:
            return super().update(request, *args, **kwargs)
        except (OperationalError, ProgrammingError) as error:
            return self._handle_directory_db_error(error)

    def partial_update(self, request, *args, **kwargs):
        try:
            return super().partial_update(request, *args, **kwargs)
        except (OperationalError, ProgrammingError) as error:
            return self._handle_directory_db_error(error)

    def destroy(self, request, *args, **kwargs):
        try:
            return super().destroy(request, *args, **kwargs)
        except (OperationalError, ProgrammingError) as error:
            return self._handle_directory_db_error(error)

    @action(detail=False, methods=['post'])
    def bootstrap(self, request):
        try:
            result = _bootstrap_directory_from_choices()
            return Response(result)
        except (OperationalError, ProgrammingError) as error:
            if _is_directory_table_error(error):
                response = _directory_tables_not_ready_response()
                response.data['details'] = str(error)
                return response
            raise


class DirectoryEntryViewSet(AuthenticatedModelViewSet):
    queryset = DirectoryEntry.objects.select_related('section').all()
    serializer_class = DirectoryEntrySerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['section', 'is_active']

    def _handle_directory_db_error(self, error):
        if _is_directory_table_error(error):
            return _directory_tables_not_ready_response()
        raise error

    def retrieve(self, request, *args, **kwargs):
        try:
            return super().retrieve(request, *args, **kwargs)
        except (OperationalError, ProgrammingError) as error:
            return self._handle_directory_db_error(error)

    def list(self, request, *args, **kwargs):
        try:
            return super().list(request, *args, **kwargs)
        except (OperationalError, ProgrammingError) as error:
            if _is_directory_table_error(error):
                return Response([])
            raise

    def create(self, request, *args, **kwargs):
        try:
            return super().create(request, *args, **kwargs)
        except (OperationalError, ProgrammingError) as error:
            return self._handle_directory_db_error(error)

    def update(self, request, *args, **kwargs):
        try:
            return super().update(request, *args, **kwargs)
        except (OperationalError, ProgrammingError) as error:
            return self._handle_directory_db_error(error)

    def partial_update(self, request, *args, **kwargs):
        try:
            return super().partial_update(request, *args, **kwargs)
        except (OperationalError, ProgrammingError) as error:
            return self._handle_directory_db_error(error)

    def destroy(self, request, *args, **kwargs):
        try:
            return super().destroy(request, *args, **kwargs)
        except (OperationalError, ProgrammingError) as error:
            return self._handle_directory_db_error(error)


class ShieldViewSet(AuthenticatedModelViewSet):
    queryset = Shield.objects.all()
    serializer_class = ShieldSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['project']

    @action(detail=True, methods=['post'])
    def apply_powershield_template(self, request, pk=None):
        shield = self.get_object()
        template_id = request.data.get('template_id')
        if not template_id: return Response({'error': 'template_id is required'}, status=400)
        
        result = TemplateService.apply_powershield_template(shield.id, template_id)
        if result.get("status") == "error": return Response(result, status=400)
        return Response(result)

    @action(detail=True, methods=['post'])
    def apply_led_shield_template(self, request, pk=None):
        shield = self.get_object()
        template_id = request.data.get('template_id')
        if not template_id: return Response({'error': 'template_id is required'}, status=400)
        
        result = TemplateService.apply_led_shield_template(shield.id, template_id)
        if result.get("status") == "error": return Response(result, status=400)
        return Response(result)
    



class ShieldGroupViewSet(AuthenticatedModelViewSet):
    queryset = ShieldGroup.objects.all()
    serializer_class = ShieldGroupSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['shield', 'shield__project']


class LedZoneViewSet(AuthenticatedModelViewSet):
    queryset = LedZone.objects.all()
    serializer_class = LedZoneSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['shield', 'shield__project']





class ProjectViewSet(AuthenticatedModelViewSet):
    queryset = Project.objects.all().order_by('-created_at').prefetch_related('files')
    serializer_class = ProjectSerializer
    filter_backends = [filters.SearchFilter]
    search_fields = ['address', 'intercom_code', 'client_info', 'source']

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        self.perform_create(serializer)
        headers = self.get_success_headers(serializer.data)
        return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)

    def perform_create(self, serializer):
        project = serializer.save()
        
        # Автоматическое создание дефолтных щитов
        Shield.objects.create(project=project, name='Силовой щит', shield_type='power')
        Shield.objects.create(project=project, name='LED щит', shield_type='led')
        Shield.objects.create(project=project, name='Слаботочка', shield_type='multimedia')
        
        init_stages = self.request.data.get('init_stages', [])
        
        if isinstance(init_stages, list):
            stages_to_create = []
            for stage_code in init_stages:
                if any(stage_code == choice[0] for choice in Stage.TITLE_CHOICES):
                    stages_to_create.append(Stage(
                        project=project,
                        title=stage_code,
                        status='plan'
                    ))
            
            if stages_to_create:
                Stage.objects.bulk_create(stages_to_create)
    
    @action(detail=False, methods=['get'])
    def unpaid_projects(self, request):
        """
        Возвращает проекты с неоплаченными этапами (кроме «Предпросчет»).
        Вычисляет суммы «Наши» для каждого этапа и проекта.
        """
        from django.db.models import Prefetch
        
        # Получаем неоплаченные этапы (кроме precalc)
        unpaid_stages_prefetch = Prefetch(
            'stages',
            queryset=Stage.objects.filter(is_paid=False).exclude(title='precalc'),
            to_attr='unpaid_stages_list'
        )
        
        # Проекты с хотя бы одним неоплаченным этапом (кроме precalc)
        projects = Project.objects.filter(
            stages__is_paid=False
        ).distinct().prefetch_related(
            unpaid_stages_prefetch,
            'stages__estimate_items'
        ).order_by('-created_at')
        
        # Формируем ответ
        result = {
            'total_usd': 0.0,
            'total_byn': 0.0,
            'projects': []
        }
        
        for project in projects:
            project_data = {
                'id': project.id,
                'address': project.address,
                'source': project.source,
                'status': project.status,
                'total_usd': 0.0,
                'total_byn': 0.0,
                'stages': []
            }
            
            unpaid_stages = getattr(project, 'unpaid_stages_list', [])
            
            for stage in unpaid_stages:
                stage_usd = 0.0
                stage_byn = 0.0
                stage_external_usd = 0.0
                stage_external_byn = 0.0
                
                for item in stage.estimate_items.all():
                    if item.currency == 'USD':
                        stage_usd += item.my_amount
                        stage_external_usd += item.employer_amount
                    else:
                        stage_byn += item.my_amount
                        stage_external_byn += item.employer_amount
                
                stage_data = {
                    'id': stage.id,
                    'title': stage.title,
                    'title_display': stage.get_title_display(),
                    'our_amount_usd': round(stage_usd, 2),
                    'our_amount_byn': round(stage_byn, 2),
                    'external_amount_usd': round(stage_external_usd, 2),
                    'external_amount_byn': round(stage_external_byn, 2),
                    'updated_at': stage.updated_at.isoformat() if hasattr(stage, 'updated_at') and stage.updated_at else None,
                }
                project_data['stages'].append(stage_data)
                project_data['total_usd'] += stage_usd
                project_data['total_byn'] += stage_byn
            
            # Округляем итоги проекта
            project_data['total_usd'] = round(project_data['total_usd'], 2)
            project_data['total_byn'] = round(project_data['total_byn'], 2)
            
            if project_data['stages']:  # Добавляем только если есть неоплаченные этапы (без precalc)
                result['projects'].append(project_data)
                result['total_usd'] += project_data['total_usd']
                result['total_byn'] += project_data['total_byn']
        
        result['total_usd'] = round(result['total_usd'], 2)
        result['total_byn'] = round(result['total_byn'], 2)
        
        return Response(result)




class EstimateItemViewSet(AuthenticatedModelViewSet):
    queryset = EstimateItem.objects.all()
    serializer_class = EstimateItemSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['stage']
    search_fields = ['name', 'catalog_item__name']

    def perform_create(self, serializer):
        # Если data не содержит каких-то полей, берем их из catalog_item
        catalog_item = serializer.validated_data.get('catalog_item')
        
        # Подготовка данных для сохранения (если они не переданы явно)
        # Note: serializer.save() вызовет model.save(), где у нас уже есть логика.
        # Но здесь мы можем явно проставить значения, если validated_data пустые.
        # Однако, validated_data уже очищены.
        
        # Просто вызываем save, так как логика enrichment уже перенесена в Model.save() 
        # и усилена (default=0).
        # Но пользователь просил добавить проверку здесь.
        
        instance = serializer.save()
        
        # Если вдруг цена осталась 0, а есть catalog_item - обновим (повторно, для гарантии)
        if instance.catalog_item and instance.price_per_unit == 0:
            instance.price_per_unit = instance.catalog_item.default_price
            instance.save()

class StageViewSet(AuthenticatedModelViewSet):
    queryset = Stage.objects.all()
    serializer_class = StageSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['project']

    @action(detail=True, methods=['post'])
    def apply_work_template(self, request, pk=None):
        stage = self.get_object()
        template_id = request.data.get('template_id')
        if not template_id: return Response({'error': 'template_id is required'}, status=400)
        
        result = TemplateService.apply_work_template(stage.id, template_id)
        if result.get("status") == "error": return Response(result, status=400)
        return Response(result)

    @action(detail=True, methods=['post'])
    def apply_material_template(self, request, pk=None):
        stage = self.get_object()
        template_id = request.data.get('template_id')
        if not template_id: return Response({'error': 'template_id is required'}, status=400)
        
        result = TemplateService.apply_material_template(stage.id, template_id)
        if result.get("status") == "error": return Response(result, status=400)
        return Response(result)



    @action(detail=True, methods=['post'])
    def import_from_shields(self, request, pk=None):
        stage = self.get_object()
        from .services import EstimateAutomationService
        result = EstimateAutomationService.import_shield_to_materials(stage.project.id, stage.id)
        
        if result.get("status") == "error":
            return Response(result, status=status.HTTP_400_BAD_REQUEST)
            
        return Response(result)

    @action(detail=True, methods=['post'])
    def calculate_works(self, request, pk=None):
        stage = self.get_object()
        from .services import EstimateAutomationService
        result = EstimateAutomationService.calculate_works_from_materials(stage.id)
        
        if result.get("status") == "error":
             return Response(result, status=status.HTTP_400_BAD_REQUEST)
             
        return Response(result)

    @action(detail=True, methods=['post'])
    def import_from_precalc_section(self, request, pk=None):
        stage = self.get_object()
        allowed_target_titles = {'stage_1', 'stage_2', 'stage_1_2'}

        if stage.title not in allowed_target_titles:
            return Response(
                {'error': 'Import from precalc is allowed only for stage_1, stage_2, stage_1_2.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        item_type = request.data.get('item_type')
        if item_type not in {'work', 'material'}:
            return Response(
                {'error': 'item_type must be "work" or "material".'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        source_stage = Stage.objects.filter(project=stage.project, title='precalc').first()
        if not source_stage:
            return Response(
                {'error': 'Precalc stage not found in this project.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        source_items = list(
            EstimateItem.objects.filter(stage=source_stage, item_type=item_type).order_by('id')
        )

        with transaction.atomic():
            deleted_count, _ = EstimateItem.objects.filter(stage=stage, item_type=item_type).delete()

            created_count = 0
            for source_item in source_items:
                EstimateItem.objects.create(
                    stage=stage,
                    item_type=source_item.item_type,
                    name=source_item.name,
                    unit=source_item.unit,
                    price_per_unit=source_item.price_per_unit,
                    currency=source_item.currency,
                    total_quantity=source_item.total_quantity,
                    employer_quantity=source_item.employer_quantity,
                )
                created_count += 1

        return Response(
            {
                'status': 'success',
                'deleted': deleted_count,
                'created': created_count,
                'item_type': item_type,
            }
        )

    @action(detail=True, methods=['post'])
    def apply_stage3_armature(self, request, pk=None):
        stage = self.get_object()

        if stage.title != 'stage_3':
            return Response(
                {'error': 'Stage 3 armature operation is allowed only for stage_3.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if not isinstance(request.data, list):
            return Response(
                {'error': 'Request body must be a list of rows.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            with transaction.atomic():
                deleted_count, _ = EstimateItem.objects.filter(
                    stage=stage, item_type='material'
                ).delete()

                created_count = 0
                for index, row in enumerate(request.data, start=1):
                    if not isinstance(row, dict):
                        raise ValueError(f'Row #{index} must be an object.')

                    catalog_item_id = row.get('catalog_item')
                    if not catalog_item_id:
                        raise ValueError(f'Row #{index}: catalog_item is required.')

                    try:
                        catalog_item = CatalogItem.objects.get(id=catalog_item_id, item_type='material')
                    except CatalogItem.DoesNotExist as error:
                        raise ValueError(f'Row #{index}: material catalog item not found.') from error

                    raw_quantity = row.get('quantity')
                    try:
                        quantity = Decimal(str(raw_quantity))
                    except (InvalidOperation, TypeError) as error:
                        raise ValueError(f'Row #{index}: quantity must be a number.') from error

                    if quantity <= 0:
                        raise ValueError(f'Row #{index}: quantity must be greater than 0.')

                    EstimateItem.objects.create(
                        stage=stage,
                        catalog_item=catalog_item,
                        item_type='material',
                        name=catalog_item.name,
                        unit=catalog_item.unit,
                        price_per_unit=catalog_item.default_price,
                        currency=catalog_item.default_currency,
                        total_quantity=quantity,
                        employer_quantity=Decimal('0'),
                    )
                    created_count += 1
        except ValueError as error:
            return Response({'error': str(error)}, status=status.HTTP_400_BAD_REQUEST)

        return Response(
            {
                'status': 'success',
                'deleted': deleted_count,
                'created': created_count,
                'item_type': 'material',
            }
        )

    @action(detail=True, methods=['get'])
    def get_report(self, request, pk=None):
        stage = self.get_object()
        report_type = request.query_params.get('type') # 'work', 'material' or None
        
        client_report = stage.generate_client_report(item_type=report_type)
        employer_report = stage.generate_employer_report(item_type=report_type)
        
        return Response({
            'client_report': client_report,
            'employer_report': employer_report
        })

# --- New Template ViewSets ---

from .models import WorkTemplate, MaterialTemplate, PowerShieldTemplate, LedShieldTemplate

class WorkTemplateViewSet(AuthenticatedModelViewSet):
    queryset = WorkTemplate.objects.all()
    serializer_class = WorkTemplateSerializer

    @action(detail=False, methods=['post'])
    def create_from_stage(self, request):
        stage_id = request.data.get('stage_id')
        name = request.data.get('name')
        description = request.data.get('description', '')
        
        if not stage_id or not name:
            return Response({'error': 'stage_id and name are required'}, status=400)
            
        result = TemplateService.create_work_template_from_stage(stage_id, name, description)
        if result.get("status") == "error": return Response(result, status=400)
        return Response(result)

class MaterialTemplateViewSet(AuthenticatedModelViewSet):
    queryset = MaterialTemplate.objects.all()
    serializer_class = MaterialTemplateSerializer

    @action(detail=False, methods=['post'])
    def create_from_stage(self, request):
        stage_id = request.data.get('stage_id')
        name = request.data.get('name')
        description = request.data.get('description', '')
        
        if not stage_id or not name:
            return Response({'error': 'stage_id and name are required'}, status=400)
            
        result = TemplateService.create_material_template_from_stage(stage_id, name, description)
        if result.get("status") == "error": return Response(result, status=400)
        return Response(result)

class PowerShieldTemplateViewSet(AuthenticatedModelViewSet):
    queryset = PowerShieldTemplate.objects.all()
    serializer_class = PowerShieldTemplateSerializer  

    @action(detail=False, methods=['post'])
    def create_from_shield(self, request):
        shield_id = request.data.get('shield_id')
        name = request.data.get('name')
        description = request.data.get('description', '')
        
        if not shield_id or not name:
            return Response({'error': 'shield_id and name are required'}, status=400)
            
        result = TemplateService.create_powershield_template_from_shield(shield_id, name, description)
        if result.get("status") == "error": return Response(result, status=400)
        return Response(result)

class LedShieldTemplateViewSet(AuthenticatedModelViewSet):
    queryset = LedShieldTemplate.objects.all()
    serializer_class = LedShieldTemplateSerializer

    @action(detail=False, methods=['post'])
    def create_from_shield(self, request):
        shield_id = request.data.get('shield_id')
        name = request.data.get('name')
        description = request.data.get('description', '')
        
        if not shield_id or not name:
            return Response({'error': 'shield_id and name are required'}, status=400)
            
        result = TemplateService.create_ledshield_template_from_shield(shield_id, name, description)
        if result.get("status") == "error": return Response(result, status=400)
        return Response(result)


class FinanceSettingsViewSet(
    AuthenticatedViewSet,
    mixins.ListModelMixin,
    mixins.RetrieveModelMixin,
    mixins.UpdateModelMixin,
    viewsets.GenericViewSet,
):
    """
    ViewSet для глобальных финансовых настроек.
    Singleton модель - всегда одна запись с id=1.
    """

    serializer_class = FinanceSettingsSerializer

    def get_queryset(self):
        finance_settings = FinanceSettings.load()
        return FinanceSettings.objects.filter(pk=finance_settings.pk)


class StatisticsViewSet(AuthenticatedViewSet):
    """
    ViewSet для получения статистики по проекту.
    """
    _AGGREGATE_FIELD = DecimalField(max_digits=22, decimal_places=4)
    _ZERO = Value(Decimal('0.00'), output_field=_AGGREGATE_FIELD)

    def _client_amount_expression(self, prefix=''):
        quantity = F(f'{prefix}total_quantity')
        unit_price = F(f'{prefix}price_per_unit')
        markup = F(f'{prefix}markup_percent')

        return ExpressionWrapper(
            quantity * unit_price * (Value(Decimal('1.00')) + (markup * Value(Decimal('0.01')))),
            output_field=self._AGGREGATE_FIELD,
        )

    @staticmethod
    def _round_amount(value):
        return round(float(value or 0), 2)

    def list(self, request):
        from django.utils import timezone

        period = request.query_params.get('period', 'all')
        start_date = None
        end_date = timezone.now()

        if period == 'month':
            start_date = end_date.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        elif period == 'year':
            start_date = end_date.replace(month=1, day=1, hour=0, minute=0, second=0, microsecond=0)

        item_filters = ~Q(stage__title='precalc')
        project_stage_filters = ~Q(stages__title='precalc')
        if start_date:
            item_filters &= Q(stage__created_at__gte=start_date)
            project_stage_filters &= Q(stages__created_at__gte=start_date)

        item_amount_expr = self._client_amount_expression()
        project_item_amount_expr = self._client_amount_expression(prefix='stages__estimate_items__')

        total_amounts = EstimateItem.objects.filter(item_filters).aggregate(
            usd=Coalesce(
                Sum(
                    Case(
                        When(currency='USD', then=item_amount_expr),
                        default=self._ZERO,
                        output_field=self._AGGREGATE_FIELD,
                    )
                ),
                self._ZERO,
            ),
            byn=Coalesce(
                Sum(
                    Case(
                        When(currency='BYN', then=item_amount_expr),
                        default=self._ZERO,
                        output_field=self._AGGREGATE_FIELD,
                    )
                ),
                self._ZERO,
            ),
        )

        projects_qs = Project.objects.all()
        if start_date:
            projects_qs = projects_qs.filter(created_at__gte=start_date)

        sources_rows = projects_qs.values('source').annotate(
            count=Count('id', distinct=True),
            usd=Coalesce(
                Sum(
                    Case(
                        When(
                            project_stage_filters & Q(stages__estimate_items__currency='USD'),
                            then=project_item_amount_expr,
                        ),
                        default=self._ZERO,
                        output_field=self._AGGREGATE_FIELD,
                    )
                ),
                self._ZERO,
            ),
            byn=Coalesce(
                Sum(
                    Case(
                        When(
                            project_stage_filters & Q(stages__estimate_items__currency='BYN'),
                            then=project_item_amount_expr,
                        ),
                        default=self._ZERO,
                        output_field=self._AGGREGATE_FIELD,
                    )
                ),
                self._ZERO,
            ),
        )

        object_type_rows = projects_qs.values('object_type').annotate(
            count=Count('id', distinct=True),
            usd=Coalesce(
                Sum(
                    Case(
                        When(
                            project_stage_filters & Q(stages__estimate_items__currency='USD'),
                            then=project_item_amount_expr,
                        ),
                        default=self._ZERO,
                        output_field=self._AGGREGATE_FIELD,
                    )
                ),
                self._ZERO,
            ),
            byn=Coalesce(
                Sum(
                    Case(
                        When(
                            project_stage_filters & Q(stages__estimate_items__currency='BYN'),
                            then=project_item_amount_expr,
                        ),
                        default=self._ZERO,
                        output_field=self._AGGREGATE_FIELD,
                    )
                ),
                self._ZERO,
            ),
        )

        is_monthly_grouping = period in ['year', 'all']
        trunc = TruncMonth('stage__created_at') if is_monthly_grouping else TruncDate('stage__created_at')

        dynamics_rows = (
            EstimateItem.objects.filter(item_filters)
            .annotate(period_date=trunc)
            .values('period_date')
            .annotate(
                usd=Coalesce(
                    Sum(
                        Case(
                            When(currency='USD', then=item_amount_expr),
                            default=self._ZERO,
                            output_field=self._AGGREGATE_FIELD,
                        )
                    ),
                    self._ZERO,
                ),
                byn=Coalesce(
                    Sum(
                        Case(
                            When(currency='BYN', then=item_amount_expr),
                            default=self._ZERO,
                            output_field=self._AGGREGATE_FIELD,
                        )
                    ),
                    self._ZERO,
                ),
            )
            .order_by('period_date')
        )

        dynamics_list = [
            {
                'date': row['period_date'].strftime('%Y-%m' if is_monthly_grouping else '%Y-%m-%d'),
                'usd': self._round_amount(row['usd']),
                'byn': self._round_amount(row['byn']),
            }
            for row in dynamics_rows
        ]

        sources_list = [
            {
                'name': row['source'] or 'Не указан',
                'count': row['count'],
                'usd': self._round_amount(row['usd']),
                'byn': self._round_amount(row['byn']),
            }
            for row in sources_rows
        ]

        type_labels = dict(Project.OBJECT_TYPE_CHOICES)
        object_types_list = [
            {
                'name': type_labels.get(row['object_type'], row['object_type']),
                'count': row['count'],
                'usd': self._round_amount(row['usd']),
                'byn': self._round_amount(row['byn']),
            }
            for row in object_type_rows
        ]

        return Response({
            'finances': {
                'usd': self._round_amount(total_amounts['usd']),
                'byn': self._round_amount(total_amounts['byn']),
            },
            'sources': sources_list,
            'object_types': object_types_list,
            'work_dynamics': dynamics_list,
        })
