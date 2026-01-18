from rest_framework import serializers
from .models import (
    Project, Stage, EstimateItem, ProjectFile,
    CatalogCategory, CatalogItem, EstimateTemplate, TemplateItem,
    ContractorNote
)

class ProjectFileSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProjectFile
        fields = ['id', 'file', 'description']

class EstimateItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = EstimateItem
        fields = '__all__'

class StageSerializer(serializers.ModelSerializer):
    estimate_items = EstimateItemSerializer(many=True, read_only=True)

    class Meta:
        model = Stage
        fields = '__all__'

class ProjectSerializer(serializers.ModelSerializer):
    stages = StageSerializer(many=True, read_only=True)
    files = ProjectFileSerializer(many=True, read_only=True)

    class Meta:
        model = Project
        fields = '__all__'

class CatalogCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = CatalogCategory
        fields = '__all__'

class CatalogItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = CatalogItem
        fields = '__all__'

class TemplateItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = TemplateItem
        fields = '__all__'

class EstimateTemplateSerializer(serializers.ModelSerializer):
    items = TemplateItemSerializer(many=True, read_only=True)

    class Meta:
        model = EstimateTemplate
        fields = '__all__'

class ContractorNoteSerializer(serializers.ModelSerializer):
    class Meta:
        model = ContractorNote
        fields = '__all__'
