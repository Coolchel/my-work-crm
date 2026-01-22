from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Project, ShieldTemplate, LedTemplate, ShieldGroup, LedZone, CatalogCategory
from .serializers import ProjectSerializer, CatalogCategorySerializer

class CatalogCategoryViewSet(viewsets.ModelViewSet):
    queryset = CatalogCategory.objects.all()
    serializer_class = CatalogCategorySerializer


class ProjectViewSet(viewsets.ModelViewSet):
    queryset = Project.objects.all()
    serializer_class = ProjectSerializer

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
