import os
import sys
import django
from decimal import Decimal

# Setup Django
sys.path.append(os.getcwd())
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'settings')
django.setup()

from core.models import CatalogItem, EstimateItem, Project, Stage, CatalogCategory
from core.services import EstimateAutomationService

def verify_aggregation():
    print("--- Starting Verification: Material Aggregation ---")
    
    # 1. Setup Data
    # Cleanup previous test data
    cleanup_keys = ['agg_test_cable', 'agg_test_mk1', 'agg_test_mk2', 'agg_test_mk3']
    CatalogItem.objects.filter(mapping_key__in=cleanup_keys).delete()
    CatalogItem.objects.filter(mapping_key='agg_test_cable').delete() # Work
    
    # Create or Get Project/Stage
    project, _ = Project.objects.get_or_create(address="Test Aggregation Project")
    stage, _ = Stage.objects.get_or_create(project=project, title='stage_1')
    
    # Clean Stage items
    EstimateItem.objects.filter(stage=stage).delete()
    
    # Create Catalog Items
    print("Creating Catalog Items...")
    
    # Work Item
    work_cat = CatalogItem.objects.create(
        name="Прокладка кабеля (TEST)",
        item_type='work',
        unit='m',
        default_price=Decimal('1.50'),
        mapping_key='agg_test_cable'
    )
    
    # Material Items with Aggregation Key
    mat1 = CatalogItem.objects.create(
        name="Кабель 3х1.5 (TEST)",
        item_type='material',
        unit='m',
        default_price=Decimal('0.50'),
        aggregation_key='agg_test_cable'
    )
    
    mat2 = CatalogItem.objects.create(
        name="Кабель 3х2.5 (TEST)",
        item_type='material',
        unit='m',
        default_price=Decimal('0.75'),
        aggregation_key='agg_test_cable'
    )
    
    mat3 = CatalogItem.objects.create(
        name="Кабель UTP (TEST)",
        item_type='material',
        unit='m',
        default_price=Decimal('0.30'),
        aggregation_key='agg_test_cable'
    )
    
    # Create Estimate Items (Materials)
    print("Adding Materials to Estimate...")
    EstimateItem.objects.create(stage=stage, catalog_item=mat1, total_quantity=100, item_type='material')
    EstimateItem.objects.create(stage=stage, catalog_item=mat2, total_quantity=50, item_type='material')
    EstimateItem.objects.create(stage=stage, catalog_item=mat3, total_quantity=100, item_type='material')
    
    # 2. Run Service
    print("Running Calculation Service...")
    result = EstimateAutomationService.calculate_works_from_materials(stage.id)
    print(f"Service Result: {result}")
    
    # 3. Verify Result
    work_item = EstimateItem.objects.filter(
        stage=stage,
        item_type='work',
        catalog_item=work_cat
    ).first()
    
    if work_item:
        print(f"Found Work Item: {work_item.name}")
        print(f"Quantity: {work_item.total_quantity}")
        
        expected = 250
        if work_item.total_quantity == expected:
            print("SUCCESS: Aggregation worked correctly! (100 + 50 + 100 = 250)")
        else:
            print(f"FAILURE: Expected {expected}, got {work_item.total_quantity}")
    else:
        print("FAILURE: Work Item not created!")
        
    # Cleanup
    # project.delete() # Optional, keep for inspection if needed

if __name__ == "__main__":
    verify_aggregation()
