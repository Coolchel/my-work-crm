from rest_framework import viewsets, status
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Project, Stage, ShieldTemplate, LedTemplate, ShieldGroup, LedZone, CatalogCategory, CatalogItem, Shield, EstimateTemplate, EstimateItem
from .serializers import (
    ProjectSerializer, StageSerializer, CatalogCategorySerializer, CatalogItemSerializer, 
    ShieldGroupSerializer, LedZoneSerializer, ShieldTemplateSerializer, LedTemplateSerializer,
    ShieldSerializer, EstimateItemSerializer, EstimateTemplateSerializer
)

class CatalogCategoryViewSet(viewsets.ModelViewSet):
    queryset = CatalogCategory.objects.all()
    serializer_class = CatalogCategorySerializer


class CatalogItemViewSet(viewsets.ModelViewSet):
    queryset = CatalogItem.objects.all()
    serializer_class = CatalogItemSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['category']


class ShieldViewSet(viewsets.ModelViewSet):
    queryset = Shield.objects.all()
    serializer_class = ShieldSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['project']
    
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

class StageViewSet(viewsets.ModelViewSet):
    queryset = Stage.objects.all()
    serializer_class = StageSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['project']

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
        for item in template.items.all():
            items_to_create.append(EstimateItem(
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
            ))
            
        EstimateItem.objects.bulk_create(items_to_create)
        return Response({'status': 'Template applied', 'added_count': len(items_to_create)})

    @action(detail=True, methods=['post'])
    def import_from_shields(self, request, pk=None):
        stage = self.get_object()
        project = stage.project
        
        added_count = 0
        items_to_create = []

        # 1. Импорт из Силовых щитов (ShieldGroup)
        power_shields = Shield.objects.filter(project=project, shield_type='power')
        for shield in power_shields:
            for group in shield.groups.all():
                # Создаем работу по установке устройства
                # Пытаемся найти подходящую работу в справочнике или создаем generic
                # Логика: "Установка {device}"
                work_name = f"Установка: {group.device}"
                
                # Создаем EstimateItem (Работа)
                items_to_create.append(EstimateItem(
                    stage=stage,
                    name=work_name,
                    item_type='work',
                    unit='шт',
                    total_quantity=1, # 1 шт на группу
                    price_per_unit=0, # Цену нужно заполнить или брать из справочника
                    currency='USD'
                ))
                
                # Если у группы указан товар (материал), добавляем и его
                if group.catalog_item:
                    items_to_create.append(EstimateItem(
                        stage=stage,
                        catalog_item=group.catalog_item, # save() подтянет поля
                        total_quantity=1
                    ))
        
        # 2. Импорт из LED щитов (LedZone)
        led_shields = Shield.objects.filter(project=project, shield_type='led')
        for shield in led_shields:
            for zone in shield.led_zones.all():
                # Установка трансформатора
                items_to_create.append(EstimateItem(
                    stage=stage,
                    name=f"Монтаж LED зоны: {zone.transformer}",
                    item_type='work',
                    unit='шт',
                    total_quantity=1,
                    price_per_unit=0,
                    currency='USD'
                ))

        # Сохраняем (bulk_create не вызовет save(), поэтому поля из catalog_item не подтянутся автоматически
        # для items, созданных с catalog_item. Придется итерировать или вызывать save/подготавливать вручную)
        # Для надежности используем цикл с save() или подготовим данные полнее.
        # Выше я использовал bulk_create для template, но там я вручную заполнил поля.
        # Здесь для catalog_item лучше заполнить вручную.
        
        # Исправляем items с catalog_item
        final_items = []
        for item in items_to_create:
            if item.catalog_item and not item.name:
                item.name = item.catalog_item.name
                item.unit = item.catalog_item.unit
                item.item_type = item.catalog_item.item_type
                if item.price_per_unit is None or item.price_per_unit == 0:
                    item.price_per_unit = item.catalog_item.default_price
                if not item.currency:
                    item.currency = item.catalog_item.default_currency
            
            final_items.append(item)

        EstimateItem.objects.bulk_create(final_items)
        
        return Response({'status': 'Imported from shields', 'added_count': len(final_items)})

    @action(detail=True, methods=['get'])
    def get_report(self, request, pk=None):
        stage = self.get_object()
        client_report = stage.generate_client_report()
        employer_report = stage.generate_employer_report()
        return Response({
            'client_report': client_report,
            'employer_report': employer_report
        })
