from django.db import models
import re

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
    CURRENCY_CHOICES = [
        ('USD', 'USD'),
        ('BYN', 'BYN'),
    ]

    name = models.CharField(max_length=255, verbose_name="Название")
    category = models.ForeignKey(CatalogCategory, on_delete=models.SET_NULL, null=True, blank=True, verbose_name="Категория")
    unit = models.CharField(max_length=20, verbose_name="Ед. изм.")
    default_price = models.DecimalField(max_digits=10, decimal_places=2, default=0, verbose_name="Цена по умолчанию")
    default_currency = models.CharField(max_length=3, choices=CURRENCY_CHOICES, default='USD', verbose_name="Валюта по умолчанию")
    item_type = models.CharField(max_length=20, choices=TYPE_CHOICES, default='material', verbose_name="Тип")
    
    # Поле для поиска (lowercase), т.к. SQLite не умеет lowercase для кириллицы
    search_name = models.CharField(max_length=255, blank=True, verbose_name="Поиск (нижний регистр)")

    class Meta:
        verbose_name = "Элемент справочника"
        verbose_name_plural = "Справочник (Товары/Работы)"

    def save(self, *args, **kwargs):
        if self.name:
            self.search_name = self.name.lower()
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.name} ({self.default_price} {self.default_currency})"


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
        ('precalc', 'Предпросчет'),
        ('stage_1', 'Этап 1 (Черновой)'),
        ('stage_1_2', 'Этап 1+2 (Черновой)'),
        ('stage_2', 'Этап 2 (Черновой)'),
        ('stage_3', 'Этап 3 (Чистовой)'),
        ('extra', 'Доп. работы'),
        ('other', 'Другое'),
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

    work_notes = models.TextField(blank=True, verbose_name="Заметки по работам")
    material_notes = models.TextField(blank=True, verbose_name="Заметки по материалам")

    work_remarks = models.TextField(blank=True, verbose_name="Примечания по работам (для отчета)")
    material_remarks = models.TextField(blank=True, verbose_name="Примечания по материалам (для отчета)")

    # Настройки отображения
    markup_percent = models.DecimalField(max_digits=5, decimal_places=2, default=0, verbose_name="Наценка %")
    show_prices = models.BooleanField(default=False, verbose_name="Показывать цены?")

    class Meta:
        verbose_name = "Этап"
        verbose_name_plural = "Этапы"

    def __str__(self):
        return f"{self.get_title_display()} - {self.project.address}"

    def generate_client_report(self, item_type=None):
        """
        Генерация отчета для клиента.
        item_type: 'work' или 'material' (опционально)
        """
        lines = []
        total_usd = 0
        total_byn = 0
        
        # Получаем элементы
        qs = self.estimate_items.all()
        if item_type:
            qs = qs.filter(item_type=item_type)
            
        items = qs.order_by('pk')
        
        counter = 1
        
        # Секция основных работ
        for item in items:
            # Формируем строку
            prefix = f"{counter}) "
            counter += 1
            
            # Расчет стоимости позиции
            amount = item.client_amount
            currency_symbol = '$' if item.currency == 'USD' else ' руб'
            
            line = f"{prefix}{item.name} - {item.total_quantity} {item.unit} * {item.price_per_unit}{currency_symbol}"
            
            # Если есть наценка, то effective_price (цена для клиента) выше базовой.
            # effective_price = (base_price + markup) / qty
            effective_price = item.price_per_unit
            if item.markup_percent > 0 and item.total_quantity > 0:
                 total_markup = (item.total_quantity * item.price_per_unit) * (item.markup_percent / 100)
                 effective_price += (total_markup / item.total_quantity)
            
            # Округлим цену для отображения
            effective_price_str = f"{effective_price:.2f}".rstrip('0').rstrip('.')
            
            line += f" = {amount:.2f}{currency_symbol};"
            lines.append(line)
            
            if item.currency == 'USD':
                total_usd += amount
            else:
                total_byn += amount
                
        # Итоги
        total_line = f"\nИтого: {total_usd:.2f}$"
        if total_byn > 0:
            total_line += f" + {total_byn:.2f} руб;"
        else:
            total_line += ";"
            
        lines.append(total_line)
        return "\n".join(lines)

    def generate_employer_report(self, item_type=None):
        """
        Отчет для контрагента (только то, что через него).
        """
        lines = []
        employer_total_usd = 0
        employer_total_byn = 0
        
        # Фильтруем
        qs = self.estimate_items.filter(employer_quantity__gt=0)
        if item_type:
            qs = qs.filter(item_type=item_type)
            
        items = qs
        
        counter = 1
        lines.append("Отчет для контрагента:\n")
        
        for item in items:
            amount = item.employer_amount
            currency_symbol = '$' if item.currency == 'USD' else ' руб'
            
            line = f"{counter}) {item.name} - {item.employer_quantity} {item.unit} * {item.price_per_unit}{currency_symbol} = {amount:.2f}{currency_symbol};"
            lines.append(line)
            counter += 1
            
            if item.currency == 'USD':
                employer_total_usd += amount
            else:
                employer_total_byn += amount

        lines.append(f"\nИтого контрагент: {employer_total_usd:.2f}$ | {employer_total_byn:.2f} руб")
        
        # Считаем "Моя доля" по всему этапу (с учетом фильтра типа, если нужно, но обычно доля считается от всего)
        # Если просят "Копировать работы (расчет с контрагентом)", то наверное нужна доля только по работам.
        
        all_items_qs = self.estimate_items.all()
        if item_type:
            all_items_qs = all_items_qs.filter(item_type=item_type)
            
        client_total_usd = sum(i.client_amount for i in all_items_qs if i.currency == 'USD')
        client_total_byn = sum(i.client_amount for i in all_items_qs if i.currency == 'BYN')
        
        my_share_usd = client_total_usd - employer_total_usd
        my_share_byn = client_total_byn - employer_total_byn
        
        lines.append(f"Моя доля (Чистая): {my_share_usd:.2f}$ | {my_share_byn:.2f} руб")
        
        return "\n".join(lines)


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
    is_preliminary = models.BooleanField(default=False, verbose_name="Это предпросчет?")
    # is_extra удалено (теперь через отдельный этап)
    
    name = models.CharField(max_length=255, verbose_name="Наименование")
    
    # Объемы
    total_quantity = models.DecimalField(max_digits=10, decimal_places=2, default=0, verbose_name="Общий объем (для клиента)")
    employer_quantity = models.DecimalField(max_digits=10, decimal_places=2, default=0, verbose_name="Объем контрагента")
    
    unit = models.CharField(max_length=20, verbose_name="Ед. изм.")
    
    # Цена и Валюта
    price_per_unit = models.DecimalField(max_digits=12, decimal_places=2, default=0, verbose_name="Цена за единицу")
    currency = models.CharField(max_length=3, choices=CURRENCY_CHOICES, default='USD', verbose_name="Валюта")
    markup_percent = models.DecimalField(max_digits=5, decimal_places=2, default=0, verbose_name="Наценка %")

    # is_subcontractor удалено, заменено на contractor_quantity
    contractor_quantity = models.DecimalField(max_digits=10, decimal_places=2, default=0, verbose_name="Кол-во подрядчика")

    class Meta:
        verbose_name = "Пункт сметы"
        verbose_name_plural = "Пункты сметы"

    def __str__(self):
        return f"{self.name} ({self.total_quantity} {self.unit})"

    @property
    def client_amount(self):
        """
        Полная стоимость для клиента: (Объем * Цена) + Наценка.
        Наценка добавляется сверху к базовой стоимости.
        """
        from decimal import Decimal
        if self.price_per_unit is None:
            self.price_per_unit = Decimal(0)
            
        base_price = (self.total_quantity or Decimal(0)) * self.price_per_unit
        markup = self.markup_percent or Decimal(0)
        markup_value = base_price * (markup / Decimal(100))
        return float(base_price + markup_value)

    @property
    def employer_amount(self):
        """
        Доля контрагента: Объем контрагента * Цена
        Наценка контрагенту не идет (она - моя прибыль).
        """
        from decimal import Decimal
        if self.price_per_unit is None:
            self.price_per_unit = Decimal(0)
        return float((self.employer_quantity or Decimal(0)) * self.price_per_unit)

    @property
    def my_amount(self):
        """
        Моя доля: Клиентская сумма - Доля работодателя
        Включает мою работу + всю наценку на материалы.
        """
        return self.client_amount - self.employer_amount

    def save(self, *args, **kwargs):
        if self.catalog_item:
            if not self.name:
                self.name = self.catalog_item.name
            if not self.unit:
                self.unit = self.catalog_item.unit
            if not self.item_type:
                self.item_type = self.catalog_item.item_type
            if self.price_per_unit == 0:
                self.price_per_unit = self.catalog_item.default_price
            # При первом сохранении валюту тоже подтягиваем
            if not self.pk and not self.currency:
                self.currency = self.catalog_item.default_currency
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


class Shield(models.Model):
    """
    Щит (электрический, слаботочный, LED).
    """
    SHIELD_TYPE_CHOICES = [
        ('power', 'Силовой'),
        ('led', 'LED'),
        ('multimedia', 'Слаботочка'),
    ]
    MOUNTING_CHOICES = [
        ('internal', 'Внутренний (в нишу)'),
        ('external', 'Наружный (накладной)'),
    ]

    project = models.ForeignKey(Project, on_delete=models.CASCADE, related_name='shields', verbose_name="Проект")
    name = models.CharField(max_length=255, verbose_name="Название щита", default="Главный щит")
    shield_type = models.CharField(max_length=20, choices=SHIELD_TYPE_CHOICES, default='power', verbose_name="Тип щита")
    mounting = models.CharField(max_length=20, choices=MOUNTING_CHOICES, default='internal', verbose_name="Монтаж")

    # Специфичные поля для мультимедиа (теперь здесь, а не в Project)
    internet_lines_count = models.IntegerField(default=0, verbose_name="Кол-во интернет-линий")
    multimedia_notes = models.TextField(blank=True, verbose_name="Заметки по мультимедиа")

    class Meta:
        verbose_name = "Щит"
        verbose_name_plural = "Щиты"

    def __str__(self):
        return f"{self.name} ({self.get_shield_type_display()})"


class ShieldGroup(models.Model):
    """
    Группа внутри силового щита.
    """
    DEVICE_CHOICES = [
        ('circuit_breaker', 'Автоматический выключатель'),
        ('diff_breaker', 'Диф.автомат'),
        ('rcd', 'УЗО'),
        ('relay', 'Реле напряжения'),
        ('contactor', 'Контактор'),
        ('load_switch', 'Выключатель нагрузки'),
        ('other', 'Другое'),
    ]

    # Changed from 'project' to 'shield'
    shield = models.ForeignKey(Shield, on_delete=models.CASCADE, related_name='groups', verbose_name="Щит")
    
    device_type = models.CharField(max_length=20, choices=DEVICE_CHOICES, default='circuit_breaker', verbose_name="Тип устройства")
    rating = models.CharField(max_length=50, default='16A', verbose_name="Номинал")
    poles = models.CharField(max_length=50, default='1P', verbose_name="Полюса")
    
    # Old field kept for compatibility, auto-generated in save()
    device = models.CharField(max_length=255, verbose_name="Устройство (Авто)", blank=True)
    
    zone = models.CharField(max_length=255, verbose_name="Зона или потребитель", blank=True)
    modules_count = models.IntegerField(default=1, verbose_name="Кол-во модулей")
    catalog_item = models.ForeignKey(CatalogItem, on_delete=models.SET_NULL, null=True, blank=True, verbose_name="Товар (опционально)")

    class Meta:
        verbose_name = "Группа щита"
        verbose_name_plural = "Группы щита"

    def save(self, *args, **kwargs):
        # 1. Строгая нормализация поля 'poles' (Полюса)
        pole_digits = re.findall(r'\d+', str(self.poles))
        if pole_digits:
            pole_val = int(pole_digits[0])
            self.poles = f"{pole_val}P"
            self.modules_count = pole_val
        else:
            self.poles = "1P"
            self.modules_count = 1

        # 2. Строгая нормализация поля 'rating' (Номинал)
        rating_digits = re.findall(r'\d+', str(self.rating))
        if rating_digits:
             rating_val = int(rating_digits[0])
             self.rating = f"{rating_val}A"
        else:
             if not self.rating:
                 self.rating = ""
        
        # 3. Логика "Зона или потребитель"
        if not self.zone:
             self.zone = dict(self.DEVICE_CHOICES).get(self.device_type, self.device_type)

        # 4. Авто-генерация названия устройства
        d_display = dict(self.DEVICE_CHOICES).get(self.device_type, self.device_type)
        self.device = f"{d_display} {self.rating} {self.poles}".strip()

        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.device} - {self.zone} ({self.modules_count} mod)"


class LedZone(models.Model):
    """
    Зона LED подсветки (внутри LED щита).
    """
    # Changed from 'project' to 'shield'
    shield = models.ForeignKey(Shield, on_delete=models.CASCADE, related_name='led_zones', verbose_name="Щит")
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
