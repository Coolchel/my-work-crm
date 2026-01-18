from django.db import models

class Project(models.Model):
    STATUS_CHOICES = [
        ('precalculation', 'Предпросчет'),
        ('in_progress', 'В работе'),
        ('pause', 'Пауза'),
        ('completed', 'Завершен'),
    ]

    address = models.CharField(max_length=255, verbose_name="Адрес объекта")
    client_info = models.TextField(verbose_name="Контактные данные")
    source = models.CharField(max_length=100, verbose_name="Источник объекта")
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='precalculation', verbose_name="Статус")
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
        ('stage_2', 'Этап 2 (Подрозетники/Щиты)'),
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

    stage = models.ForeignKey(Stage, on_delete=models.CASCADE, related_name='estimate_items', verbose_name="Этап")
    item_type = models.CharField(max_length=20, choices=TYPE_CHOICES, verbose_name="Тип")
    is_preliminary = models.BooleanField(default=False, verbose_name="Это предпросчет?")
    name = models.CharField(max_length=255, verbose_name="Наименование")
    quantity = models.DecimalField(max_digits=10, decimal_places=2, verbose_name="Количество")
    unit = models.CharField(max_length=20, verbose_name="Ед. изм.")
    price_per_unit = models.DecimalField(max_digits=12, decimal_places=2, verbose_name="Цена за единицу")

    class Meta:
        verbose_name = "Пункт сметы"
        verbose_name_plural = "Пункты сметы"

    def __str__(self):
        return self.name

class ProjectFile(models.Model):
    project = models.ForeignKey(Project, on_delete=models.CASCADE, related_name='files', verbose_name="Проект")
    file = models.FileField(upload_to='project_files/', verbose_name="Файл")
    description = models.CharField(max_length=255, blank=True, verbose_name="Описание")

    class Meta:
        verbose_name = "Файл проекта"
        verbose_name_plural = "Файлы проектов"

    def __str__(self):
        return self.description or str(self.file)
