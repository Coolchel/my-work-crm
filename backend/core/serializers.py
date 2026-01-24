from rest_framework import serializers
from .models import (
    Project, Stage, EstimateItem, ProjectFile,
    CatalogCategory, CatalogItem, EstimateTemplate, TemplateItem,
    ContractorNote, ShieldGroup, LedZone,
    ShieldTemplate, LedTemplate, ShieldTemplateItem, LedTemplateItem,
    Shield
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

class ShieldGroupSerializer(serializers.ModelSerializer):
    class Meta:
        model = ShieldGroup
        fields = '__all__'
        read_only_fields = ['modules_count', 'device']
        extra_kwargs = {
            'device': {'required': False, 'read_only': True},
            'modules_count': {'required': False, 'read_only': True},
        }

class LedZoneSerializer(serializers.ModelSerializer):
    class Meta:
        model = LedZone
        fields = '__all__'

class ShieldSerializer(serializers.ModelSerializer):
    groups = ShieldGroupSerializer(many=True, read_only=True)
    led_zones = LedZoneSerializer(many=True, read_only=True)
    
    suggested_size = serializers.SerializerMethodField()

    class Meta:
        model = Shield
        fields = '__all__'
    
    def get_suggested_size(self, obj):
        # Calculate size based on type
        if obj.shield_type == 'power':
            modules = sum(g.modules_count for g in obj.groups.all())
            sizes = [1, 2, 4, 6, 8, 12, 18, 24, 36, 48, 60, 72, 96, 108, 144]
            for size in sizes:
                if modules <= size:
                    return f"{size} модулей"
            return f"{modules} модулей (инд. заказ)"
        elif obj.shield_type == 'led':
            count = obj.led_zones.count()
            if count <= 0: return None
            if count <= 4: return "24 модуля"
            if count <= 8: return "36 модулей"
            if count <= 12: return "48 модулей"
            if count <= 17: return "60 модулей"
            return "Требуется инд. расчет"
        elif obj.shield_type == 'multimedia':
            if obj.internet_lines_count <= 8:
                return "Mistral 12M"
            if obj.internet_lines_count <= 24:
                return "Mistral 48M"
            return "Требуется инд. расчет"
        return None

class ProjectSerializer(serializers.ModelSerializer):
    stages = StageSerializer(many=True, read_only=True)
    files = ProjectFileSerializer(many=True, read_only=True)
    shields = ShieldSerializer(many=True, read_only=True)

    class Meta:
        model = Project
        fields = '__all__'
        extra_kwargs = {
            'intercom_code': {'required': False, 'allow_blank': True},
            'client_info': {'required': False, 'allow_blank': True},
            'source': {'required': False, 'allow_blank': True},
            'notes': {'required': False, 'allow_blank': True},
        }

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

class ShieldTemplateitemSerializer(serializers.ModelSerializer):
    class Meta:
        model = ShieldTemplateItem
        fields = '__all__'

class LedTemplateItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = LedTemplateItem
        fields = '__all__'

class ShieldTemplateSerializer(serializers.ModelSerializer):
    items = ShieldTemplateitemSerializer(many=True, read_only=True)

    class Meta:
        model = ShieldTemplate
        fields = ['id', 'name', 'description', 'items']

class LedTemplateSerializer(serializers.ModelSerializer):
    items = LedTemplateItemSerializer(many=True, read_only=True)

    class Meta:
        model = LedTemplate
        fields = ['id', 'name', 'description', 'items']
