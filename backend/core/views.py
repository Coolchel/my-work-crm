from rest_framework import viewsets, status, filters
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import (
    Project, Stage, ShieldGroup, LedZone, CatalogCategory, CatalogItem, 
    Shield, EstimateItem, WorkTemplate, MaterialTemplate, PowerShieldTemplate, LedShieldTemplate,
    FinanceSettings, ProjectFile
)
from .serializers import (
    ProjectSerializer, StageSerializer, CatalogCategorySerializer, CatalogItemSerializer, 
    ShieldGroupSerializer, LedZoneSerializer, ShieldSerializer, EstimateItemSerializer,
    WorkTemplateSerializer, MaterialTemplateSerializer, 
    PowerShieldTemplateSerializer, LedShieldTemplateSerializer,
    FinanceSettingsSerializer, ProjectFileSerializer
)
from .services import TemplateService

class ProjectFileViewSet(viewsets.ModelViewSet):
    queryset = ProjectFile.objects.all()
    serializer_class = ProjectFileSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['project', 'category']

    def perform_destroy(self, instance):
        # Физическое удаление файла с диска
        if instance.file:
            instance.file.delete(save=False)
        instance.delete()


class CatalogCategoryViewSet(viewsets.ModelViewSet):
    queryset = CatalogCategory.objects.all()
    serializer_class = CatalogCategorySerializer


class CatalogItemViewSet(viewsets.ModelViewSet):
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


class ShieldViewSet(viewsets.ModelViewSet):
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
    



class ShieldGroupViewSet(viewsets.ModelViewSet):
    queryset = ShieldGroup.objects.all()
    serializer_class = ShieldGroupSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['shield', 'shield__project']


class LedZoneViewSet(viewsets.ModelViewSet):
    queryset = LedZone.objects.all()
    serializer_class = LedZoneSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['shield', 'shield__project']





class ProjectViewSet(viewsets.ModelViewSet):
    queryset = Project.objects.all().order_by('-created_at').prefetch_related('files')
    serializer_class = ProjectSerializer

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




class EstimateItemViewSet(viewsets.ModelViewSet):
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

class StageViewSet(viewsets.ModelViewSet):
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

class WorkTemplateViewSet(viewsets.ModelViewSet):
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

class MaterialTemplateViewSet(viewsets.ModelViewSet):
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

class PowerShieldTemplateViewSet(viewsets.ModelViewSet):
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

class LedShieldTemplateViewSet(viewsets.ModelViewSet):
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


class FinanceSettingsViewSet(viewsets.ViewSet):
    """
    ViewSet для глобальных финансовых настроек.
    Singleton модель - всегда одна запись.
    """
    
    def list(self, request):
        """Получить финансовые настройки"""
        finance_settings = FinanceSettings.load()
        serializer = FinanceSettingsSerializer(finance_settings)
        return Response(serializer.data)
    
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class StatisticsViewSet(viewsets.ViewSet):
    """
    ViewSet для получения статистики по проекту.
    """
    def list(self, request):
        from django.utils import timezone
        import datetime

        # 0. Фильтрация по времени (Time Filter)
        period = request.query_params.get('period', 'all')  # 'month', 'year', 'all'
        
        # Определяем диапазон дат
        start_date = None
        end_date = timezone.now()

        if period == 'month':
            start_date = end_date.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        elif period == 'year':
            start_date = end_date.replace(month=1, day=1, hour=0, minute=0, second=0, microsecond=0)
        
        # Базовый QuerySet для этапов (исключая предпросчет)
        stages_qs = Stage.objects.exclude(title='precalc')
        
        # Фильтруем этапы:
        if start_date:
            stages_qs = stages_qs.filter(updated_at__gte=start_date)

        # 1. Pipeline (Воронка)
        # Оплачено - этапы с is_paid=True
        # Ожидает оплаты - этапы с is_paid=False и status='completed'
        # В работе - УБРАНО из статистики по требованию

        paid_usd = 0.0
        paid_byn = 0.0
        pending_usd = 0.0
        pending_byn = 0.0

        # Получаем этапы, попавшие в выборку
        for stage in stages_qs:
            # Считаем суммы для этапа
            usd = 0.0
            byn = 0.0
            for item in stage.estimate_items.all():
                if item.currency == 'USD':
                    usd += item.client_amount
                else:
                    byn += item.client_amount
            
            if stage.is_paid:
                paid_usd += usd
                paid_byn += byn
            elif stage.status == 'completed':
                if not stage.is_paid: # Доп проверка
                    pending_usd += usd
                    pending_byn += byn

        # 2. Источники (Sources) & 3. Типы объектов (Object Types)
        
        projects_qs = Project.objects.all()
        if start_date:
            # Считаем проект активным, если он был обновлен в этот период
            projects_qs = projects_qs.filter(updated_at__gte=start_date)

        sources_data = {}
        types_data = {}
        type_labels = dict(Project.OBJECT_TYPE_CHOICES)

        for project in projects_qs:
            # --- Sources ---
            src = project.source or "Не указан"
            if src not in sources_data:
                sources_data[src] = {'count': 0, 'usd': 0.0, 'byn': 0.0}
            
            sources_data[src]['count'] += 1
            
            # --- Types ---
            obj_type = project.object_type
            label = type_labels.get(obj_type, obj_type)
            if label not in types_data:
                types_data[label] = {'count': 0, 'usd': 0.0, 'byn': 0.0}
            types_data[label]['count'] += 1

            # Считаем общую сумму проекта (только по этапам, попавшим в период)
            project_stages = stages_qs.filter(project=project)
            
            for stage in project_stages:
                for item in stage.estimate_items.all():
                    if item.currency == 'USD':
                        sources_data[src]['usd'] += item.client_amount
                        types_data[label]['usd'] += item.client_amount
                    else:
                        sources_data[src]['byn'] += item.client_amount
                        types_data[label]['byn'] += item.client_amount

        # 4. Динамика работ (Work Dynamics)
        # Агрегация по created_at (когда работа была зафиксирована)
        
        dynamics_data = {} # "YYYY-MM-DD" -> {usd, byn}
        
        # Используем stages_qs, который уже отфильтрован по дате (start_date) при необходимости
        # Но для динамики нам, возможно, нужны более старые данные если period='all',
        # хотя stages_qs уже учитывает start_date.
        
        # Для 'all' и 'year' группируем по месяцам ("YYYY-MM"), для 'month' по дням ("YYYY-MM-DD")
        is_monthly_grouping = period in ['year', 'all']

        for stage in stages_qs:
            # Определяем ключ даты
            date_key = ""
            if is_monthly_grouping:
                date_key = stage.created_at.strftime("%Y-%m") # Group by Month
            else:
                date_key = stage.created_at.strftime("%Y-%m-%d") # Group by Day

            if date_key not in dynamics_data:
                dynamics_data[date_key] = {'usd': 0.0, 'byn': 0.0}

            # Суммируем предметы
            for item in stage.estimate_items.all():
                if item.currency == 'USD':
                    dynamics_data[date_key]['usd'] += item.client_amount
                else:
                    dynamics_data[date_key]['byn'] += item.client_amount

        # Преобразуем в список и сортируем
        dynamics_list = []
        for k, v in dynamics_data.items():
            # print(f"DEBUG DATE KEY: '{k}'") # Debug
            dynamics_list.append({
                'date': k,
                'usd': round(v['usd'], 2),
                'byn': round(v['byn'], 2)
            })
        
        dynamics_list.sort(key=lambda x: x['date'])

        return Response({
            'pipeline': {
                'paid': {'usd': round(paid_usd, 2), 'byn': round(paid_byn, 2)},
                'pending': {'usd': round(pending_usd, 2), 'byn': round(pending_byn, 2)},
            },
            'sources': [
                {'name': k, 'count': v['count'], 'usd': round(v['usd'], 2), 'byn': round(v['byn'], 2)}
                for k, v in sources_data.items()
            ],
            'object_types': [
                {'name': k, 'count': v['count'], 'usd': round(v['usd'], 2), 'byn': round(v['byn'], 2)}
                for k, v in types_data.items()
            ],
            'work_dynamics': dynamics_list
        })
