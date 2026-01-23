from rest_framework import viewsets, status
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Project, Stage, ShieldTemplate, LedTemplate, ShieldGroup, LedZone, CatalogCategory, CatalogItem
from .serializers import ProjectSerializer, StageSerializer, CatalogCategorySerializer, CatalogItemSerializer

class CatalogCategoryViewSet(viewsets.ModelViewSet):
    queryset = CatalogCategory.objects.all()
    serializer_class = CatalogCategorySerializer


class CatalogItemViewSet(viewsets.ModelViewSet):
    queryset = CatalogItem.objects.all()
    serializer_class = CatalogItemSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['category']


class ProjectViewSet(viewsets.ModelViewSet):
    queryset = Project.objects.all().order_by('-created_at')
    serializer_class = ProjectSerializer

    def perform_create(self, serializer):
        """
        При создании проекта проверяем наличие 'init_stages'.
        Если список передан (например, ["stage_1", "stage_3"]),
        создаем соответствующие этапы для этого проекта.
        """
        # Сначала сохраняем сам проект
        project = serializer.save()
        
        # Извлекаем список этапов из запроса (это не поле модели, поэтому его нет в validated_data по умолчанию,
        # если не добавлено в сериализатор явно как write_only поле. Но проще взять из self.request.data)
        init_stages = self.request.data.get('init_stages', [])
        
        if isinstance(init_stages, list):
            stages_to_create = []
            for stage_code in init_stages:
                # Проверяем, что код этапа валиден (есть в TITLE_CHOICES)
                # Можно добавить валидацию, но для простоты создаем как есть, если код совпадает.
                # Project.TITLE_CHOICES - это в Stage модели.
                if any(stage_code == choice[0] for choice in Stage.TITLE_CHOICES):
                    stages_to_create.append(Stage(
                        project=project,
                        title=stage_code,
                        status='plan' # Начальный статус
                    ))
            
            if stages_to_create:
                Stage.objects.bulk_create(stages_to_create)


class StageViewSet(viewsets.ModelViewSet):
    """
    ViewSet для управления этапами.
    Позволяет фильтровать этапы по id проекта: /api/stages/?project=1
    """
    queryset = Stage.objects.all()
    serializer_class = StageSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['project']


    @action(detail=True, methods=['post'])
    def apply_shield_template(self, request, pk=None):
        project = self.get_object()
        template_id = request.data.get('template_id')
        
        if not template_id:
            return Response({'error': 'template_id is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            template = ShieldTemplate.objects.get(id=template_id)
        except ShieldTemplate.DoesNotExist:
            return Response({'error': 'Template not found'}, status=status.HTTP_404_NOT_FOUND)
            
        # Copy items
        items_to_create = []
        for item in template.items.all():
            items_to_create.append(ShieldGroup(
                project=project,
                device=item.device,
                zone=item.zone,
                catalog_item=item.catalog_item
            ))
        
        ShieldGroup.objects.bulk_create(items_to_create)
        return Response({'status': 'Shield template applied', 'added_count': len(items_to_create)})

    @action(detail=True, methods=['post'])
    def apply_led_template(self, request, pk=None):
        project = self.get_object()
        template_id = request.data.get('template_id')
        
        if not template_id:
            return Response({'error': 'template_id is required'}, status=status.HTTP_400_BAD_REQUEST)
            
        try:
            template = LedTemplate.objects.get(id=template_id)
        except LedTemplate.DoesNotExist:
            return Response({'error': 'Template not found'}, status=status.HTTP_404_NOT_FOUND)
            
        # Copy items
        items_to_create = []
        for item in template.items.all():
            items_to_create.append(LedZone(
                project=project,
                transformer=item.transformer,
                zone=item.zone,
                catalog_item=item.catalog_item
            ))
            
        LedZone.objects.bulk_create(items_to_create)
        return Response({'status': 'LED template applied', 'added_count': len(items_to_create)})
