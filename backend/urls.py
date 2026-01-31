"""
URL configuration for backend project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/6.0/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from core.views import (
    ProjectViewSet, CatalogCategoryViewSet, CatalogItemViewSet, StageViewSet, 
    ShieldGroupViewSet, LedZoneViewSet, ShieldTemplateViewSet, LedTemplateViewSet, 
    ShieldViewSet, EstimateItemViewSet, EstimateTemplateViewSet,
    WorkTemplateViewSet, MaterialTemplateViewSet, PowerShieldTemplateViewSet, MultimediaTemplateViewSet
)

router = DefaultRouter()
router.register(r'projects', ProjectViewSet)
router.register(r'stages', StageViewSet)
router.register(r'shields', ShieldViewSet)
router.register(r'categories', CatalogCategoryViewSet, basename='category')
router.register(r'catalog-items', CatalogItemViewSet, basename='catalog-item')
router.register(r'estimate-items', EstimateItemViewSet, basename='estimate-item')
router.register(r'estimate-templates', EstimateTemplateViewSet, basename='estimate-template')
router.register(r'shield-groups', ShieldGroupViewSet, basename='shield-group')
router.register(r'led-zones', LedZoneViewSet, basename='led-zone')
router.register(r'shield-templates', ShieldTemplateViewSet, basename='shield-template')
router.register(r'led-templates', LedTemplateViewSet, basename='led-template')
router.register(r'work-templates', WorkTemplateViewSet, basename='work-template')
router.register(r'material-templates', MaterialTemplateViewSet, basename='material-template')
router.register(r'powershield-templates', PowerShieldTemplateViewSet, basename='powershield-template')
router.register(r'multimedia-templates', MultimediaTemplateViewSet, basename='multimedia-template')

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include(router.urls)),
]

