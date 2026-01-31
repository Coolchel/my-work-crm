from rest_framework import viewsets, status, filters
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Project, Stage, ShieldTemplate, LedTemplate, ShieldGroup, LedZone, CatalogCategory, CatalogItem, Shield, EstimateTemplate, EstimateItem
from .serializers import (
    ProjectSerializer, StageSerializer, CatalogCategorySerializer, CatalogItemSerializer, 
    ShieldGroupSerializer, LedZoneSerializer, ShieldTemplateSerializer, LedTemplateSerializer,
    ShieldSerializer, EstimateItemSerializer, EstimateTemplateSerializer,
    WorkTemplateSerializer, MaterialTemplateSerializer, 
    PowerShieldTemplateSerializer, MultimediaTemplateSerializer
)
from .services import TemplateService

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
    def apply_multimedia_template(self, request, pk=None):
        shield = self.get_object()
        template_id = request.data.get('template_id')
        if not template_id: return Response({'error': 'template_id is required'}, status=400)
        
        result = TemplateService.apply_multimedia_template(shield.id, template_id)
        if result.get("status") == "error": return Response(result, status=400)
        return Response(result)
    
    @action(detail=True, methods=['post'])
    def apply_shield_template(self, request, pk=None):
        shield = self.get_object()
        template_id = request.data.get('template_id')
        
        if not template_id:
            return Response({'error': 'template_id is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            template = ShieldTemplate.objects.get(id=template_id)
        except ShieldTemplate.DoesNotExist:
            return Response({'error': 'Template not found'}, status=status.HTTP_404_NOT_FOUND)
            
        # Копируем элементы шаблона в щит
        items_to_create = []
        for item in template.items.all():
            items_to_create.append(ShieldGroup(
                shield=shield,
                device=item.device,
                zone=item.zone,
                catalog_item=item.catalog_item
            ))
        
        ShieldGroup.objects.bulk_create(items_to_create)
        return Response({'status': 'Shield template applied', 'added_count': len(items_to_create)})

    @action(detail=True, methods=['post'])
    def apply_led_template(self, request, pk=None):
        shield = self.get_object()
        template_id = request.data.get('template_id')
        
        if not template_id:
            return Response({'error': 'template_id is required'}, status=status.HTTP_400_BAD_REQUEST)
            
        try:
            template = LedTemplate.objects.get(id=template_id)
        except LedTemplate.DoesNotExist:
            return Response({'error': 'Template not found'}, status=status.HTTP_404_NOT_FOUND)
            
        # Копируем элементы шаблона в щит
        items_to_create = []
        for item in template.items.all():
            items_to_create.append(LedZone(
                shield=shield,
                transformer=item.transformer,
                zone=item.zone,
                catalog_item=item.catalog_item
            ))
            
        LedZone.objects.bulk_create(items_to_create)
        return Response({'status': 'LED template applied', 'added_count': len(items_to_create)})


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


class ShieldTemplateViewSet(viewsets.ModelViewSet):
    queryset = ShieldTemplate.objects.all()
    serializer_class = ShieldTemplateSerializer


class LedTemplateViewSet(viewsets.ModelViewSet):
    queryset = LedTemplate.objects.all()
    serializer_class = LedTemplateSerializer


class ProjectViewSet(viewsets.ModelViewSet):
    queryset = Project.objects.all().order_by('-created_at')
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


class EstimateTemplateViewSet(viewsets.ModelViewSet):
    queryset = EstimateTemplate.objects.all()
    serializer_class = EstimateTemplateSerializer

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
    def apply_template(self, request, pk=None):
        stage = self.get_object()
        template_id = request.data.get('template_id')
        
        if not template_id:
            return Response({'error': 'template_id is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            template = EstimateTemplate.objects.get(id=template_id)
        except EstimateTemplate.DoesNotExist:
            return Response({'error': 'Template not found'}, status=status.HTTP_404_NOT_FOUND)
            
        items_to_create = []
        created_count = 0
        updated_count = 0
        
        for item in template.items.all():
            # Check if exists
            est_item = EstimateItem.objects.filter(
                stage=stage,
                catalog_item=item.catalog_item,
                item_type=item.catalog_item.item_type
            ).first()
            
            if est_item:
                # Update quantity (Additive for templates)
                est_item.total_quantity += item.default_quantity
                est_item.save()
                updated_count += 1
            else:
                EstimateItem.objects.create(
                    stage=stage,
                    catalog_item=item.catalog_item,
                    name=item.catalog_item.name,
                    item_type=item.catalog_item.item_type,
                    unit=item.catalog_item.unit,
                    total_quantity=item.default_quantity,
                    price_per_unit=item.catalog_item.default_price,
                    currency=item.catalog_item.default_currency,
                    employer_quantity=0,
                    markup_percent=0
                )
                created_count += 1
            
        return Response({
            'status': 'Template applied', 
            'created': created_count, 
            'updated': updated_count
        })

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

from .models import WorkTemplate, MaterialTemplate, PowerShieldTemplate, MultimediaTemplate

class WorkTemplateViewSet(viewsets.ModelViewSet):
    queryset = WorkTemplate.objects.all()
    serializer_class = WorkTemplateSerializer

class MaterialTemplateViewSet(viewsets.ModelViewSet):
    queryset = MaterialTemplate.objects.all()
    serializer_class = MaterialTemplateSerializer

class PowerShieldTemplateViewSet(viewsets.ModelViewSet):
    queryset = PowerShieldTemplate.objects.all()
    serializer_class = PowerShieldTemplateSerializer

class MultimediaTemplateViewSet(viewsets.ModelViewSet):
    queryset = MultimediaTemplate.objects.all()
    serializer_class = MultimediaTemplateSerializer
