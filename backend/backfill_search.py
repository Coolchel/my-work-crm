# backfill_search.py
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'settings')
django.setup()

from core.models import CatalogItem

def run():
    items = CatalogItem.objects.all()
    count = 0
    for item in items:
        # Trigger the save() method which now populates search_name
        item.save()
        count += 1
    print(f"Updated {count} items.")

if __name__ == '__main__':
    run()
