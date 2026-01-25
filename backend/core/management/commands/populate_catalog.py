from django.core.management.base import BaseCommand
from core.models import CatalogItem, CatalogCategory

class Command(BaseCommand):
    help = 'Populates the catalog with test data'

    def handle(self, *args, **kwargs):
        # Create or get categories
        cat_work, _ = CatalogCategory.objects.get_or_create(name='Черновые работы', slug='rough-works')
        cat_mat, _ = CatalogCategory.objects.get_or_create(name='Черновые материалы', slug='rough-materials')

        # Works
        works = [
            {"name": "Монтаж подрозетника", "price": 1.0, "unit": "шт", "type": "work"},
            {"name": "Штроба (бетон)", "price": 1.5, "unit": "м", "type": "work"},
            {"name": "Штроба (кирпич)", "price": 1.0, "unit": "м", "type": "work"},
            {"name": "Монтаж кабеля", "price": 0.4, "unit": "м", "type": "work"},
            {"name": "Установка автомата", "price": 2.5, "unit": "шт", "type": "work"},
        ]

        for item in works:
            CatalogItem.objects.get_or_create(
                name=item["name"],
                defaults={
                    "category": cat_work,
                    "default_price": item["price"],
                    "unit": item["unit"],
                    "item_type": item["type"],
                    "default_currency": "USD"
                }
            )
            self.stdout.write(f"Created/Updated work: {item['name']}")

        # Materials
        materials = [
            {"name": "Кабель ВВГнг-ls 3x1.5", "price": 0.5, "unit": "м", "type": "material"},
            {"name": "Кабель ВВГнг-ls 3x2.5", "price": 0.8, "unit": "м", "type": "material"},
            {"name": "Подрозетник Schneider (глубокий)", "price": 0.3, "unit": "шт", "type": "material"},
            {"name": "Дюбель-хомут", "price": 0.05, "unit": "шт", "type": "material"},
            {"name": "Автомат 16A Schneider", "price": 3.0, "unit": "шт", "type": "material"},
        ]

        for item in materials:
            CatalogItem.objects.get_or_create(
                name=item["name"],
                defaults={
                    "category": cat_mat,
                    "default_price": item["price"],
                    "unit": item["unit"],
                    "item_type": item["type"],
                    "default_currency": "USD"
                }
            )
            self.stdout.write(f"Created/Updated material: {item['name']}")
