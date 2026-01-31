from django.contrib import admin
from .models import (
    Project, Stage, EstimateItem, ProjectFile, 
    CatalogCategory, CatalogItem, EstimateTemplate, TemplateItem,
    ContractorNote, ShieldGroup, LedZone,
    ShieldTemplate, ShieldTemplateItem, LedTemplate, LedTemplateItem,
    Shield
)

class ProjectFileInline(admin.TabularInline):
    model = ProjectFile
    extra = 1
    verbose_name = "Файл"
    verbose_name_plural = "Файлы"

class EstimateItemInline(admin.TabularInline):
    model = EstimateItem
    extra = 1
    verbose_name = "Пункт сметы"
    verbose_name_plural = "Пункты сметы"
    autocomplete_fields = ['catalog_item']
    fields = ('name', 'catalog_item', 'item_type', 'total_quantity', 'employer_quantity', 'unit', 'price_per_unit', 'currency', 'markup_percent', 'is_preliminary')

class StageInline(admin.TabularInline):
    model = Stage
    extra = 0
    show_change_link = True
    verbose_name = "Этап"
    verbose_name_plural = "Этапы"

class TemplateItemInline(admin.TabularInline):
    model = TemplateItem
    extra = 1
    autocomplete_fields = ['catalog_item']
    verbose_name = "Позиция шаблона"
    verbose_name_plural = "Позиции шаблона"

class ShieldGroupInline(admin.TabularInline):
    model = ShieldGroup
    extra = 1
    verbose_name = "Группа щита"
    verbose_name_plural = "Конфигурация щита"
    autocomplete_fields = ['catalog_item']

class LedZoneInline(admin.TabularInline):
    model = LedZone
    extra = 1
    verbose_name = "Зона LED"
    verbose_name_plural = "Конфигурация LED"
    autocomplete_fields = ['catalog_item']

class ShieldTemplateItemInline(admin.TabularInline):
    model = ShieldTemplateItem
    extra = 1
    autocomplete_fields = ['catalog_item']

class LedTemplateItemInline(admin.TabularInline):
    model = LedTemplateItem
    extra = 1
    autocomplete_fields = ['catalog_item']

@admin.register(Shield)
class ShieldAdmin(admin.ModelAdmin):
    list_display = ('name', 'project', 'shield_type', 'mounting')
    list_filter = ('shield_type', 'mounting')
    search_fields = ('name', 'project__address')
    inlines = [ShieldGroupInline, LedZoneInline]

@admin.register(CatalogCategory)
class CatalogCategoryAdmin(admin.ModelAdmin):
    list_display = ('name', 'slug', 'labor_coefficient')
    prepopulated_fields = {'slug': ('name',)}

@admin.register(CatalogItem)
class CatalogItemAdmin(admin.ModelAdmin):
    list_display = ('name', 'category', 'item_type', 'default_price', 'default_currency', 'unit', 'mapping_key')
    list_filter = ('category', 'item_type')
    search_fields = ('name', 'mapping_key')
    autocomplete_fields = ['related_work_item']

@admin.register(EstimateTemplate)
class EstimateTemplateAdmin(admin.ModelAdmin):
    list_display = ('name', 'description')
    inlines = [TemplateItemInline]

@admin.register(Project)
class ProjectAdmin(admin.ModelAdmin):
    list_display = ('address', 'object_type', 'status', 'created_at')
    list_filter = ('object_type', 'status', 'created_at')
    search_fields = ('address', 'client_info')
    inlines = [StageInline, ProjectFileInline]
    fieldsets = (
        ('Основная информация', {
            'fields': ('address', 'object_type', 'client_info', 'source', 'status')
        }),
        ('Детали объекта', {
            'fields': ('entrance', 'floor', 'intercom_code')
        }),
        ('Дополнительно', {
            'fields': ('notes', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    readonly_fields = ('created_at', 'updated_at')

@admin.register(Stage)
class StageAdmin(admin.ModelAdmin):
    list_display = ('title', 'project', 'status', 'is_paid')
    list_filter = ('status', 'is_paid')
    search_fields = ('project__address',)
    inlines = [EstimateItemInline]
    autocomplete_fields = ['project']

@admin.register(EstimateItem)
class EstimateItemAdmin(admin.ModelAdmin):
    list_display = ('name', 'stage', 'item_type', 'total_quantity', 'employer_quantity', 'unit', 'price_per_unit', 'currency', 'markup_percent', 'client_amount_display', 'my_amount_display')
    list_filter = ('item_type', 'is_preliminary', 'currency')
    search_fields = ('name', 'stage__project__address')
    autocomplete_fields = ['catalog_item']
    readonly_fields = ('client_amount_display', 'employer_amount_display', 'my_amount_display')
    
    def client_amount_display(self, obj):
        return f"{obj.client_amount} {obj.currency}"
    client_amount_display.short_description = "Итого (Клиент)"

    def employer_amount_display(self, obj):
        return f"{obj.employer_amount} {obj.currency}"
    employer_amount_display.short_description = "Сумма (Контрагент)"

    def my_amount_display(self, obj):
        return f"{obj.my_amount} {obj.currency}"
    my_amount_display.short_description = "Моя доля"

@admin.register(ProjectFile)
class ProjectFileAdmin(admin.ModelAdmin):
    list_display = ('description', 'project', 'file')

@admin.register(ContractorNote)
class ContractorNoteAdmin(admin.ModelAdmin):
    list_display = ('title', 'amount', 'currency', 'date', 'is_paid')
    list_filter = ('currency', 'is_paid', 'date')
    search_fields = ('title', 'description')

@admin.register(ShieldTemplate)
class ShieldTemplateAdmin(admin.ModelAdmin):
    list_display = ('name',)
    inlines = [ShieldTemplateItemInline]

@admin.register(LedTemplate)
class LedTemplateAdmin(admin.ModelAdmin):
    list_display = ('name',)
    inlines = [LedTemplateItemInline]


# --- New Template System ---

from .models import (
    WorkTemplate, WorkTemplateItem,
    MaterialTemplate, MaterialTemplateItem,
    PowerShieldTemplate, PowerShieldTemplateItem,
    MultimediaTemplate, MultimediaTemplateItem
)

class WorkTemplateItemInline(admin.TabularInline):
    model = WorkTemplateItem
    extra = 1
    autocomplete_fields = ['catalog_item']

@admin.register(WorkTemplate)
class WorkTemplateAdmin(admin.ModelAdmin):
    list_display = ('name', 'description')
    inlines = [WorkTemplateItemInline]

class MaterialTemplateItemInline(admin.TabularInline):
    model = MaterialTemplateItem
    extra = 1
    autocomplete_fields = ['catalog_item']

@admin.register(MaterialTemplate)
class MaterialTemplateAdmin(admin.ModelAdmin):
    list_display = ('name', 'description')
    inlines = [MaterialTemplateItemInline]

class PowerShieldTemplateItemInline(admin.TabularInline):
    model = PowerShieldTemplateItem
    extra = 1
    autocomplete_fields = ['catalog_item']

@admin.register(PowerShieldTemplate)
class PowerShieldTemplateAdmin(admin.ModelAdmin):
    list_display = ('name', 'description')
    inlines = [PowerShieldTemplateItemInline]

class MultimediaTemplateItemInline(admin.TabularInline):
    model = MultimediaTemplateItem
    extra = 1
    autocomplete_fields = ['catalog_item']

@admin.register(MultimediaTemplate)
class MultimediaTemplateAdmin(admin.ModelAdmin):
    list_display = ('name', 'description')
    inlines = [MultimediaTemplateItemInline]
