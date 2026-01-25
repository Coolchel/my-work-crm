import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'settings')
django.setup()

from core.models import Project, Stage, EstimateItem, CatalogItem, Shield, ShieldGroup, CatalogCategory
from rest_framework.test import APIRequestFactory
from core.views import StageViewSet

def test_calculations():
    print("Testing Calculations...")
    # 1. Setup Data
    cat, _ = CatalogCategory.objects.get_or_create(name="Test Cat", slug="test-cat")
    item, _ = CatalogItem.objects.get_or_create(
        name="Cable", 
        category=cat, 
        defaults={'default_price': 100, 'default_currency': 'USD', 'unit': 'm', 'item_type': 'material'}
    )
    
    project = Project.objects.create(address="Test Addr")
    stage = Stage.objects.create(project=project, title="stage_1")
    
    # 2. Create EstimateItem
    est_item = EstimateItem.objects.create(
        stage=stage,
        catalog_item=item,
        total_quantity=10,
        employer_quantity=2,
        markup_percent=10,
        currency='USD'
    )
    
    # Refresh to ensure properties are calculated (though they are Python props)
    est_item.refresh_from_db()
    
    # Logic:
    # price = 100
    # total_qty = 10 -> base = 1000
    # markup = 10% of 1000 = 100
    # client_amount = 1100
    # employer_share = 2 * 100 = 200
    # my_amount = 1100 - 200 = 900
    
    print(f"Client Amount: {est_item.client_amount} (Expected 1100.0)")
    print(f"Employer Amount: {est_item.employer_amount} (Expected 200.0)")
    print(f"My Amount: {est_item.my_amount} (Expected 900.0)")
    
    assert est_item.client_amount == 1100.0
    assert est_item.employer_amount == 200.0
    assert est_item.my_amount == 900.0
    print("Calculations OK")

def test_import_logic():
    print("\nTesting Import Logic...")
    project = Project.objects.create(address="Shield Test")
    stage = Stage.objects.create(project=project, title="stage_1")
    
    # Create Shield and Group
    shield = Shield.objects.create(project=project, name="P1", shield_type='power')
    ShieldGroup.objects.create(shield=shield, device_type='circuit_breaker', rating='16A', poles='1P', modules_count=1)
    
    # Call ViewSet action logic manually or via factory
    factory = APIRequestFactory()
    view = StageViewSet.as_view({'post': 'import_from_shields'})
    request = factory.post(f'/api/stages/{stage.id}/import_from_shields/')
    response = view(request, pk=stage.id)
    
    print(f"Response: {response.status_code} {response.data}")
    
    # Verify items created
    items = EstimateItem.objects.filter(stage=stage)
    print(f"Created items: {items.count()}")
    for i in items:
        print(f"- {i.name} ({i.item_type})")
        
    assert items.count() >= 1
    assert "Установка" in items[0].name
    print("Import Logic OK")

def test_reports():
    print("\nTesting Reports...")
    project = Project.objects.create(address="Report Test")
    stage = Stage.objects.create(project=project, title="stage_1")
    
    # 1. Normal Item
    EstimateItem.objects.create(
        stage=stage, name="Work 1", item_type='work', unit='pcs', 
        total_quantity=2, price_per_unit=100, currency='USD'
    )
    # 2. Extra Item
    EstimateItem.objects.create(
        stage=stage, name="Extra 1", item_type='work', unit='pcs', 
        total_quantity=1, price_per_unit=50, currency='USD', is_extra=True
    )
    # 3. Employer Item
    EstimateItem.objects.create(
        stage=stage, name="Emp Work", item_type='work', unit='pcs', 
        total_quantity=5, employer_quantity=5, price_per_unit=10, currency='USD'
    )
    
    client_report = stage.generate_client_report()
    employer_report = stage.generate_employer_report()
    
    print("--- Client Report ---")
    print(client_report)
    print("---------------------")
    
    assert "1) Work 1 - 2.00 pcs * 100.00$ = 200.00$;" in client_report
    assert "+ Extra 1 - 1.00 pcs * 50.00$ = 50.00$;" in client_report
    assert "Итого: 300.00$" in client_report
    
    print("--- Employer Report ---")
    print(employer_report)
    print("-----------------------")
    
    assert "1) Emp Work - 5.00 pcs * 10.00$ = 50.00$;" in employer_report
    assert "Моя доля (Чистая): 250.00$" in employer_report # 300 - 50 = 250
    
    print("Reports OK")

if __name__ == "__main__":
    try:
        test_calculations()
        test_import_logic()
        test_reports()
        print("\nALL TESTS PASSED")
    except Exception as e:
        print(f"\nTEST FAILED: {e}")
        import traceback
        traceback.print_exc()
