import os
import django
from django.db.models import Value
from django.db.models.functions import Lower

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'settings')
django.setup()

from core.models import CatalogItem, CatalogCategory

def test_cyrillic_search():
    # Setup
    cat, _ = CatalogCategory.objects.get_or_create(name='SearchTest', slug='search-test')
    # Name with Uppercase
    item, _ = CatalogItem.objects.get_or_create(
        name='Кабель Тест',
        defaults={'category': cat, 'default_price': 100, 'unit': 'm', 'item_type': 'material'}
    )
    
    print(f"Item in DB: '{item.name}'")
    
    # 1. Standard Django icontains (uses LIKE)
    query = 'кабель' # lowercase
    qs_standard = CatalogItem.objects.filter(name__icontains=query)
    print(f"Standard icontains('{query}') -> Found: {qs_standard.count()}")
    
    if qs_standard.count() == 0:
        print("FAIL: Standard icontains failed on Cyrillic case mismatch (Expected behavior for SQLite on specific builds)")
    else:
        print("PASS: Standard icontains worked.")

    # 2. Lower() annotation workaround
    qs_workaround = CatalogItem.objects.annotate(
        name_lower=Lower('name')
    ).filter(name_lower__contains=query.lower())
    
    print(f"Workaround Lower() -> Found: {qs_workaround.count()}")
    
    # Debug: see what Lower produced
    val = CatalogItem.objects.annotate(n_lower=Lower('name')).filter(name='Кабель Тест').values_list('n_lower', flat=True).first()
    print(f"DB Lower('Кабель Тест') = '{val}'")

    
    if qs_workaround.count() > 0:
        print("SUCCESS: Workaround finds the item.")
    
    # 3. Test new search_name field
    qs_new = CatalogItem.objects.filter(search_name__contains=query.lower())
    print(f"New search_name field ('{query}') -> Found: {qs_new.count()}")
    
    if qs_new.count() > 0:
        print("SUCCESS: New search_name logic works!")
    else:
        print("FAIL: New search_name logic failed (Did you run backfill?)")

if __name__ == '__main__':
    test_cyrillic_search()
