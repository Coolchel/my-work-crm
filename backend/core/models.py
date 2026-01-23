from django.db import models

class CatalogCategory(models.Model):
    """
    Категория справочника (например, 'Кабели', 'Розетки').
    Используется для группировки товаров и работ.
    """
    name = models.CharField(max_length=100, verbose_name="Название категории")
    slug = models.SlugField(unique=True, allow_unicode=True, verbose_name="Уникальный код (slug)")
    labor_coefficient = models.FloatField(default=1.0, verbose_name="Коэффициент сложности")

    class Meta:
        verbose_name = "Категория справочника"
        verbose_name_plural = "Категории справочника"

    def __str__(self):
        return self.name


class CatalogItem(models.Model):
    """
    Элемент справочника (товар или вид работы).
    Хранит базовую стоимость и единицы измерения для быстрого добавления в смету.
    """
    TYPE_CHOICES = [
        ('work', 'Работа'),
        ('material', 'Материал'),
    ]

    name = models.CharField(max_length=255, verbose_name="Название")
    category = models.ForeignKey(CatalogCategory, on_delete=models.SET_NULL, null=True, blank=True, verbose_name="Категория")
    unit = models.CharField(max_length=20, verbose_name="Ед. изм.")
    default_price = models.DecimalField(max_digits=10, decimal_places=2, default=0, verbose_name="Цена по умолчанию")
    item_type = models.CharField(max_length=20, choices=TYPE_CHOICES, default='material', verbose_name="Тип")

    class Meta:
        verbose_name = "Элемент справочника"
        verbose_name_plural = "Справочник (Товары/Работы)"

    def __str__(self):
        return f"{self.name} ({self.default_price} р.)"


class EstimateTemplate(models.Model):
    """
    Шаблон сметы. Позволяет создавать наборы работ/материалов (например, 'Электрика 1-комн. квартира').
    """
    name = models.CharField(max_length=255, verbose_name="Название шаблона")
    description = models.TextField(blank=True, verbose_name="Описание")

    class Meta:
        verbose_name = "Шаблон сметы"
        verbose_name_plural = "Шаблоны смет"

    def __str__(self):
        return self.name


class TemplateItem(models.Model):
    """
    Позиция внутри шаблона. Ссылается на элемент справочника.
    """
    template = models.ForeignKey(EstimateTemplate, on_delete=models.CASCADE, related_name='items', verbose_name="Шаблон")
    catalog_item = models.ForeignKey(CatalogItem, on_delete=models.CASCADE, verbose_name="Элемент справочника")
    default_quantity = models.DecimalField(max_digits=10, decimal_places=2, default=1, verbose_name="Кол-во по умолчанию")

    class Meta:
        verbose_name = "Позиция шаблона"
        verbose_name_plural = "Позиции шаблона"

    def __str__(self):
        return f"{self.catalog_item.name} -> {self.template.name}"


class Project(models.Model):
    STATUS_CHOICES = [
        ('new', 'Новый'),
        ('calculating', 'Предпросчет'),
        ('stage1_done', 'Этап 1 готов'),
        ('stage2_done', 'Этап 2 готов'),
        ('stage3_done', 'Этап 3 готов'),
        ('completed', 'Завершен'),
    ]
    
    OBJECT_TYPE_CHOICES = [
        ('new_building', 'Новостройка'),
        ('secondary', 'Вторичка'),
        ('cottage', 'Коттедж'),
        ('office', 'Офис'),
        ('other', 'Другое'),
    ]

    address = models.CharField(max_length=255, verbose_name="Адрес объекта")
    object_type = models.CharField(max_length=20, choices=OBJECT_TYPE_CHOICES, default='new_building', verbose_name="Тип объекта")
    
    entrance = models.CharField(max_length=10, blank=True, verbose_name="Подъезд")
    floor = models.IntegerField(null=True, blank=True, verbose_name="Этаж")
    intercom_code = models.CharField(max_length=20, blank=True, verbose_name="Код домофона")

    client_info = models.TextField(verbose_name="Контактные данные")
    source = models.CharField(max_length=100, verbose_name="Источник объекта")
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='new', verbose_name="Статус")
    notes = models.TextField(blank=True, verbose_name="Заметки")
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="Дата создания")
    updated_at = models.DateTimeField(auto_now=True, verbose_name="Дата обновления")

    class Meta:
        verbose_name = "Проект"
        verbose_name_plural = "Проекты"

    def __str__(self):
        return self.address


class Stage(models.Model):
    TITLE_CHOICES = [
        ('stage_1', 'Этап 1 (Черновой)'),
        ('stage_2', 'Этап 2 (Черновой)'),
        ('stage_3', 'Этап 3 (Чистовой)'),
        ('extra', 'Доп. работы'),
    ]
    STATUS_CHOICES = [
        ('plan', 'План'),
        ('in_progress', 'В процессе'),
        ('completed', 'Завершен'),
    ]

    project = models.ForeignKey(Project, on_delete=models.CASCADE, related_name='stages', verbose_name="Проект")
    title = models.CharField(max_length=50, choices=TITLE_CHOICES, verbose_name="Название этапа")
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='plan', verbose_name="Состояние")
    is_paid = models.BooleanField(default=False, verbose_name="Оплачено")
    started_at = models.DateField(null=True, blank=True, verbose_name="Дата начала")
    ended_at = models.DateField(null=True, blank=True, verbose_name="Дата конца")

    class Meta:
        verbose_name = "Этап"
        verbose_name_plural = "Этапы"

    def __str__(self):
        return f"{self.get_title_display()} - {self.project.address}"


class EstimateItem(models.Model):
    TYPE_CHOICES = [
        ('work', 'Работа'),
        ('material', 'Материал'),
    ]
    CURRENCY_CHOICES = [
        ('USD', 'USD'),
        ('BYN', 'BYN'),
    ]

    stage = models.ForeignKey(Stage, on_delete=models.CASCADE, related_name='estimate_items', verbose_name="Этап")
    catalog_item = models.ForeignKey(CatalogItem, on_delete=models.SET_NULL, null=True, blank=True, verbose_name="Из каталога")

    item_type = models.CharField(max_length=20, choices=TYPE_CHOICES, verbose_name="Тип")
    is_preliminary = models.BooleanField(default=False, verbose_name="Это предпросчет?")
    
    name = models.CharField(max_length=255, verbose_name="Наименование")
    quantity = models.DecimalField(max_digits=10, decimal_places=2, verbose_name="Количество")
    unit = models.CharField(max_length=20, verbose_name="Ед. изм.")
    price_per_unit = models.DecimalField(max_digits=12, decimal_places=2, verbose_name="Цена за единицу", blank=True, null=True)
    
    currency = models.CharField(max_length=3, choices=CURRENCY_CHOICES, default='USD', verbose_name="Валюта")
    # is_subcontractor удалено, заменено на contractor_quantity
    contractor_quantity = models.DecimalField(max_digits=10, decimal_places=2, default=0, verbose_name="Кол-во подрядчика")

    class Meta:
        verbose_name = "Пункт сметы"
        verbose_name_plural = "Пункты сметы"

    def __str__(self):
        return self.name

    def save(self, *args, **kwargs):
        if self.catalog_item:
            if not self.name:
                self.name = self.catalog_item.name
            if not self.unit:
                self.unit = self.catalog_item.unit
            if not self.item_type:
                self.item_type = self.catalog_item.item_type
            if self.price_per_unit is None:
                self.price_per_unit = self.catalog_item.default_price
        super().save(*args, **kwargs)


class ProjectFile(models.Model):
    project = models.ForeignKey(Project, on_delete=models.CASCADE, related_name='files', verbose_name="Проект")
    file = models.FileField(upload_to='project_files/', verbose_name="Файл")
    description = models.CharField(max_length=255, blank=True, verbose_name="Описание")

    class Meta:
        verbose_name = "Файл проекта"
        verbose_name_plural = "Файлы проектов"

    def __str__(self):
        return self.description or str(self.file)


class ContractorNote(models.Model):
    """
    Записи подрядчика (для раздела 'Итоговые сметы ч.2').
    """
    CURRENCY_CHOICES = [
        ('USD', 'USD'),
        ('BYN', 'BYN'),
    ]

    title = models.CharField(max_length=255, verbose_name="Заголовок/Объект")
    amount = models.DecimalField(max_digits=12, decimal_places=2, verbose_name="Сумма")
    currency = models.CharField(max_length=3, choices=CURRENCY_CHOICES, default='USD', verbose_name="Валюта")
    description = models.TextField(blank=True, verbose_name="Описание")
    date = models.DateField(auto_now_add=True, verbose_name="Дата")
    is_paid = models.BooleanField(default=False, verbose_name="Оплачено")

    class Meta:
        verbose_name = "Запись подрядчика"
        verbose_name_plural = "Записи подрядчика"

    def __str__(self):
        return f"{self.title} - {self.amount} {self.currency}"


class ShieldGroup(models.Model):
    """
    Группа щита.
    """
    project = models.ForeignKey(Project, on_delete=models.CASCADE, related_name='shield_groups', verbose_name="Проект")
    device = models.CharField(max_length=255, verbose_name="Устройство/Номинал")
    zone = models.CharField(max_length=255, verbose_name="Зона/Потребитель")
    catalog_item = models.ForeignKey(CatalogItem, on_delete=models.SET_NULL, null=True, blank=True, verbose_name="Товар (опционально)")

    class Meta:
        verbose_name = "Группа щита"
        verbose_name_plural = "Группы щита"

    def __str__(self):
        return f"{self.device} - {self.zone}"


class LedZone(models.Model):
    """
    Зона LED подсветки.
    """
    project = models.ForeignKey(Project, on_delete=models.CASCADE, related_name='led_zones', verbose_name="Проект")
    transformer = models.CharField(max_length=255, verbose_name="Трансформатор/Блок")
    zone = models.CharField(max_length=255, verbose_name="Место установки/Лента")
    catalog_item = models.ForeignKey(CatalogItem, on_delete=models.SET_NULL, null=True, blank=True, verbose_name="Товар (опционально)")

    class Meta:
        verbose_name = "Зона LED"
        verbose_name_plural = "Зоны LED"

    def __str__(self):
        return f"{self.transformer} - {self.zone}"


class ShieldTemplate(models.Model):
    """
    Шаблон щита.
    """
    name = models.CharField(max_length=255, verbose_name="Название шаблона")
    description = models.TextField(blank=True, verbose_name="Описание")

    class Meta:
        verbose_name = "Шаблон щита"
        verbose_name_plural = "Шаблоны щитов"

    def __str__(self):
        return self.name


class ShieldTemplateItem(models.Model):
    """
    Пункт шаблона щита.
    """
    template = models.ForeignKey(ShieldTemplate, on_delete=models.CASCADE, related_name='items', verbose_name="Шаблон")
    device = models.CharField(max_length=255, verbose_name="Устройство/Номинал")
    zone = models.CharField(max_length=255, verbose_name="Зона/Потребитель")
    catalog_item = models.ForeignKey(CatalogItem, on_delete=models.SET_NULL, null=True, blank=True, verbose_name="Товар (опционально)")

    class Meta:
        verbose_name = "Пункт шаблона щита"
        verbose_name_plural = "Пункты шаблона щита"

    def __str__(self):
        return f"{self.device} - {self.zone}"


class LedTemplate(models.Model):
    """
    Шаблон LED.
    """
    name = models.CharField(max_length=255, verbose_name="Название шаблона")
    description = models.TextField(blank=True, verbose_name="Описание")

    class Meta:
        verbose_name = "Шаблон LED"
        verbose_name_plural = "Шаблоны LED"

    def __str__(self):
        return self.name


class LedTemplateItem(models.Model):
    """
    Пункт шаблона LED.
    """
    template = models.ForeignKey(LedTemplate, on_delete=models.CASCADE, related_name='items', verbose_name="Шаблон")
    transformer = models.CharField(max_length=255, verbose_name="Трансформатор/Блок")
    zone = models.CharField(max_length=255, verbose_name="Место установки/Лента")
    catalog_item = models.ForeignKey(CatalogItem, on_delete=models.SET_NULL, null=True, blank=True, verbose_name="Товар (опционально)")

    class Meta:
        verbose_name = "Пункт шаблона LED"
        verbose_name_plural = "Пункты шаблона LED"

    def __str__(self):
        return f"{self.transformer} - {self.zone}"

