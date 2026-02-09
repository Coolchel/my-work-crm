from rest_framework import serializers
from .models import (
    Project, Stage, EstimateItem, ProjectFile,
    CatalogCategory, CatalogItem, ContractorNote, 
    ShieldGroup, LedZone, Shield,
    WorkTemplate, WorkTemplateItem,
    MaterialTemplate, MaterialTemplateItem,
    PowerShieldTemplate, PowerShieldTemplateItem,
    LedShieldTemplate, LedShieldTemplateItem,
    FinanceSettings
)

class ProjectFileSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProjectFile
        fields = ['id', 'project', 'file', 'description', 'category', 'original_name']

    def create(self, validated_data):
        file_obj = validated_data.get('file')
        if file_obj and not validated_data.get('original_name'):
            # Берем имя из объекта загруженного файла (MultipartFile.filename из фронтенда)
            validated_data['original_name'] = file_obj.name
        return super().create(validated_data)

class EstimateItemSerializer(serializers.ModelSerializer):
    client_amount = serializers.ReadOnlyField()
    employer_amount = serializers.ReadOnlyField()
    my_amount = serializers.ReadOnlyField()
    category_name = serializers.ReadOnlyField(source='catalog_item.category.name')

    class Meta:
        model = EstimateItem
        fields = '__all__'
        extra_kwargs = {
            'name': {'required': False, 'allow_blank': True},
            'unit': {'required': False, 'allow_blank': True},
            'item_type': {'required': False, 'allow_blank': True},
            'price_per_unit': {'required': False},
            'currency': {'required': False},
            'total_quantity': {'required': False}, # Default is 0, so should be fine, but explicit is better
        }

class StageSerializer(serializers.ModelSerializer):
    estimate_items = EstimateItemSerializer(many=True, read_only=True)
    
    # Вычисляемые поля для финансового монитора
    our_amount_usd = serializers.SerializerMethodField()
    our_amount_byn = serializers.SerializerMethodField()
    title_display = serializers.SerializerMethodField()

    class Meta:
        model = Stage
        fields = '__all__'
        extra_kwargs = {
            'work_notes': {'required': False, 'allow_blank': True},
            'material_notes': {'required': False, 'allow_blank': True},
            'work_remarks': {'required': False, 'allow_blank': True},
            'material_remarks': {'required': False, 'allow_blank': True},
            'markup_percent': {'required': False},
            'show_prices': {'required': False},
        }
    
    def get_our_amount_usd(self, obj):
        """Сумма «Наши» в USD: (client_amount - employer_amount) для позиций с currency=USD"""
        total = 0.0
        for item in obj.estimate_items.filter(currency='USD'):
            total += item.my_amount
        return round(total, 2)
    
    def get_our_amount_byn(self, obj):
        """Сумма «Наши» в BYN: (client_amount - employer_amount) для позиций с currency=BYN"""
        total = 0.0
        for item in obj.estimate_items.filter(currency='BYN'):
            total += item.my_amount
        return round(total, 2)
    
    def get_title_display(self, obj):
        """Человекочитаемое название этапа"""
        return obj.get_title_display()

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
            if modules == 0:
                return "0 модулей"
            sizes = [1, 2, 4, 6, 8, 12, 24, 36, 48, 60, 72, 96, 108, 144]
            for size in sizes:
                if modules <= size:
                    return f"{size} модулей"
            return f"{modules} модулей (инд. заказ)"
        elif obj.shield_type == 'led':
            count = obj.led_zones.count()
            if count <= 0: return None
            if count <= 2: return "Переместить в слаботочный щит"
            if count <= 4: return "24 модуля"
            if count <= 9: return "36 модулей"
            if count <= 12: return "48 модулей"
            if count <= 15: return "60 модулей"
            return "Требуется инд. расчет"
        elif obj.shield_type == 'multimedia':
            if obj.internet_lines_count <= 4:
                return "24 модуля"
            if obj.internet_lines_count <= 10:
                return "36 модулей"
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



class ContractorNoteSerializer(serializers.ModelSerializer):
    class Meta:
        model = ContractorNote
        fields = '__all__'



# --- New Template System Serializers ---



class WorkTemplateItemSerializer(serializers.ModelSerializer):
    catalog_item_name = serializers.ReadOnlyField(source='catalog_item.name')
    class Meta:
        model = WorkTemplateItem
        fields = '__all__'

class WorkTemplateSerializer(serializers.ModelSerializer):
    items = WorkTemplateItemSerializer(many=True, read_only=True)
    class Meta:
        model = WorkTemplate
        fields = '__all__'

class MaterialTemplateItemSerializer(serializers.ModelSerializer):
    catalog_item_name = serializers.ReadOnlyField(source='catalog_item.name')
    class Meta:
        model = MaterialTemplateItem
        fields = '__all__'

class MaterialTemplateSerializer(serializers.ModelSerializer):
    items = MaterialTemplateItemSerializer(many=True, read_only=True)
    class Meta:
        model = MaterialTemplate
        fields = '__all__'

class PowerShieldTemplateItemSerializer(serializers.ModelSerializer):
    catalog_item_name = serializers.ReadOnlyField(source='catalog_item.name')
    class Meta:
        model = PowerShieldTemplateItem
        fields = '__all__'

class PowerShieldTemplateSerializer(serializers.ModelSerializer):
    items = PowerShieldTemplateItemSerializer(many=True, read_only=True)
    class Meta:
        model = PowerShieldTemplate
        fields = '__all__'

class LedShieldTemplateItemSerializer(serializers.ModelSerializer):
    catalog_item_name = serializers.ReadOnlyField(source='catalog_item.name')
    class Meta:
        model = LedShieldTemplateItem
        fields = '__all__'

class LedShieldTemplateSerializer(serializers.ModelSerializer):
    items = LedShieldTemplateItemSerializer(many=True, read_only=True)
    class Meta:
        model = LedShieldTemplate
        fields = '__all__'


class FinanceSettingsSerializer(serializers.ModelSerializer):
    class Meta:
        model = FinanceSettings
        fields = '__all__'
