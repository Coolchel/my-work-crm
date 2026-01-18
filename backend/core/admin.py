from django.contrib import admin
from .models import Project, Stage, EstimateItem, ProjectFile

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

class StageInline(admin.TabularInline):
    model = Stage
    extra = 0
    show_change_link = True
    verbose_name = "Этап"
    verbose_name_plural = "Этапы"

@admin.register(Project)
class ProjectAdmin(admin.ModelAdmin):
    list_display = ('address', 'status', 'created_at')
    list_filter = ('status', 'created_at')
    search_fields = ('address', 'client_info')
    inlines = [StageInline, ProjectFileInline]
    fieldsets = (
        ('Основная информация', {
            'fields': ('address', 'client_info', 'source', 'status')
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
    list_display = ('name', 'stage', 'item_type', 'quantity', 'unit', 'price_per_unit', 'total_price')
    list_filter = ('item_type', 'is_preliminary')
    search_fields = ('name', 'stage__project__address')
    
    def total_price(self, obj):
        if obj.quantity and obj.price_per_unit:
            return obj.quantity * obj.price_per_unit
        return 0
    total_price.short_description = "Итого"

@admin.register(ProjectFile)
class ProjectFileAdmin(admin.ModelAdmin):
    list_display = ('description', 'project', 'file')

