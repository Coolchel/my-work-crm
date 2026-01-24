from django.core.management.base import BaseCommand
from core.models import CatalogCategory, CatalogItem

class Command(BaseCommand):
    help = 'Seeds the database with initial catalog data'

    def handle(self, *args, **kwargs):
        self.stdout.write('Seeding data...')

        # Categories
        cat_breakers, _ = CatalogCategory.objects.get_or_create(
            name='Автоматика', 
            defaults={'slug': 'automation', 'labor_coefficient': 1.0}
        )
        cat_cables, _ = CatalogCategory.objects.get_or_create(
            name='Кабель', 
            defaults={'slug': 'cables', 'labor_coefficient': 1.2}
        )
        cat_consumables, _ = CatalogCategory.objects.get_or_create(
            name='Расходники', 
            defaults={'slug': 'consumables', 'labor_coefficient': 1.0}
        )
        cat_light, _ = CatalogCategory.objects.get_or_create(
            name='Освещение', 
            defaults={'slug': 'lighting', 'labor_coefficient': 1.5}
        )

        # Items - Breakers
        items = [
            {'category': cat_breakers, 'name': 'Автомат 1P 16A', 'default_price': 450.0, 'unit': 'шт'},
            {'category': cat_breakers, 'name': 'Автомат 1P 10A', 'default_price': 450.0, 'unit': 'шт'},
            {'category': cat_breakers, 'name': 'УЗО 2P 40A 30mA', 'default_price': 3500.0, 'unit': 'шт'},
            {'category': cat_breakers, 'name': 'Диф. автомат 1P+N 16A 30mA', 'default_price': 2800.0, 'unit': 'шт'},
            
            {'category': cat_cables, 'name': 'ВВГнг-LS 3x1.5', 'default_price': 85.0, 'unit': 'м'},
            {'category': cat_cables, 'name': 'ВВГнг-LS 3x2.5', 'default_price': 120.0, 'unit': 'м'},
            {'category': cat_cables, 'name': 'UTP 5e (Витая пара)', 'default_price': 45.0, 'unit': 'м'},

            {'category': cat_light, 'name': 'Лента 24V 9.6W/m 4000K', 'default_price': 650.0, 'unit': 'м'},
            {'category': cat_light, 'name': 'Блок питания 24V 100W', 'default_price': 2500.0, 'unit': 'шт'},
        ]

        for item_data in items:
            CatalogItem.objects.get_or_create(
                name=item_data['name'],
                defaults=item_data
            )

        self.stdout.write(self.style.SUCCESS('Successfully seeded catalog data'))
