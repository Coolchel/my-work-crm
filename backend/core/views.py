from rest_framework import viewsets, status
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Project, Stage, ShieldTemplate, LedTemplate, ShieldGroup, LedZone, CatalogCategory, CatalogItem, Shield
from .serializers import (
    ProjectSerializer, StageSerializer, CatalogCategorySerializer, CatalogItemSerializer, 
    ShieldGroupSerializer, LedZoneSerializer, ShieldTemplateSerializer, LedTemplateSerializer,
    ShieldSerializer
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


class StageViewSet(viewsets.ModelViewSet):
    queryset = Stage.objects.all()
    serializer_class = StageSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['project']
