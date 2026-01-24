from rest_framework import serializers
from .models import (
    Project, Stage, EstimateItem, ProjectFile,
    CatalogCategory, CatalogItem, EstimateTemplate, TemplateItem,
    ContractorNote, ShieldGroup, LedZone,
    ShieldTemplate, LedTemplate, ShieldTemplateItem, LedTemplateItem
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
    shield_groups = serializers.SerializerMethodField()
    led_zones = serializers.SerializerMethodField()
    led_shield_size = serializers.SerializerMethodField()

    class Meta:
        model = Project
        fields = '__all__'
        extra_kwargs = {
            'intercom_code': {'required': False, 'allow_blank': True},
            'client_info': {'required': False, 'allow_blank': True},
            'source': {'required': False, 'allow_blank': True},
            'notes': {'required': False, 'allow_blank': True},
        }

    def get_shield_groups(self, obj):
        return ShieldGroupSerializer(obj.shield_groups.all(), many=True).data

    def get_led_zones(self, obj):
        return LedZoneSerializer(obj.led_zones.all(), many=True).data

    def get_led_shield_size(self, obj):
        count = obj.led_zones.count()
        if count <= 0:
            return None
        if count <= 4:
            return "24 модуля"
        if count <= 8:
            return "36 модулей"
        if count <= 12:
            return "48 модулей"
        if count <= 17:
            return "60 модулей"
        return "Требуется инд. расчет"

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

class ShieldGroupSerializer(serializers.ModelSerializer):
    class Meta:
        model = ShieldGroup
        fields = '__all__'
        read_only_fields = ['modules_count', 'device'] # Computed fields should be read-only from API perspective? Or allow override?
        # User requested smart logic, usually implies computed. Let's make them read-only or just optional.
        # Actually user might want to manually override. Let's keep them writable but auto-calculated if missing/on save.
        # The save() method overrides modules_count based on other fields. So writing to it might be useless unless we add a check.
        # For now, let's leave it as is. save() overwrites it. So effectively read-only behavior for logic, but writable for API.
        extra_kwargs = {
            'device': {'required': False, 'read_only': True}, # Device string is auto-generated
            'modules_count': {'required': False, 'read_only': True}, # Auto-calculated
        }

class LedZoneSerializer(serializers.ModelSerializer):
    class Meta:
        model = LedZone
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
