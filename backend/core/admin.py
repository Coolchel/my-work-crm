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
    fields = ('name', 'catalog_item', 'item_type', 'quantity', 'contractor_quantity', 'unit', 'price_per_unit', 'currency', 'is_preliminary')

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
    list_display = ('name', 'category', 'item_type', 'default_price', 'unit')
    list_filter = ('category', 'item_type')
    search_fields = ('name',)

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
    list_display = ('name', 'stage', 'item_type', 'quantity', 'contractor_quantity', 'unit', 'price_per_unit', 'currency', 'total_price')
    list_filter = ('item_type', 'is_preliminary', 'currency')
    search_fields = ('name', 'stage__project__address')
    autocomplete_fields = ['catalog_item']
    
    def total_price(self, obj):
        if obj.quantity and obj.price_per_unit:
            return f"{obj.quantity * obj.price_per_unit} {obj.currency}"
        return 0
    total_price.short_description = "Итого"

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
