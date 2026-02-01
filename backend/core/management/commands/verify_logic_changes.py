from django.core.management.base import BaseCommand
from core.models import (
    Project, Stage, Shield, ShieldGroup, EstimateItem, 
    CatalogItem, WorkTemplate, WorkTemplateItem,
    MaterialTemplate, MaterialTemplateItem,
    PowerShieldTemplate, PowerShieldTemplateItem
)
from core.services import EstimateAutomationService, TemplateService
from decimal import Decimal

class Command(BaseCommand):
    help = 'Verify logic changes for Import, Calc, and Templates'

    def handle(self, *args, **kwargs):
        self.stdout.write(self.style.WARNING('Starting Logic Verification...'))
        
        # 1. SETUP
        # Clean up previous test data
        Project.objects.filter(address="TEST_LOGIC_PROJECT").delete()
        CatalogItem.objects.filter(name__startswith="TEST_").delete()
        WorkTemplate.objects.filter(name="TEST_WORK_TPL").delete()
        MaterialTemplate.objects.filter(name="TEST_MAT_TPL").delete()
        PowerShieldTemplate.objects.filter(name="TEST_SHIELD_TPL").delete()

        # Create Project & Stage
        project = Project.objects.create(address="TEST_LOGIC_PROJECT", client_info="Tester")
        stage = Stage.objects.create(project=project, title="stage_1", markup_percent=10.0)
        self.stdout.write(f"Created Project ID: {project.id}, Stage ID: {stage.id}")

        # Create Dummy Catalog Items
        cat_mat_1 = CatalogItem.objects.create(name="TEST_Mat_1", default_price=100, item_type='material', unit='шт')
        cat_mat_agg = CatalogItem.objects.create(name="TEST_Mat_Agg", default_price=50, item_type='material', aggregation_key="agg_key_1", unit='m')
        cat_work_1 = CatalogItem.objects.create(name="TEST_Work_1", default_price=200, item_type='work', mapping_key="agg_key_1", unit='job')
        
        # ---------------------------------------------------------
        # TEST 1: Template Application (Clearing Logic)
        # ---------------------------------------------------------
        self.stdout.write(self.style.SUCCESS('\n--- Test 1: Templates (Clear before Apply) ---'))
        
        # Create "Old" Items that should be deleted
        EstimateItem.objects.create(stage=stage, item_type='work', name="Old Work To Delete", total_quantity=10)
        EstimateItem.objects.create(stage=stage, item_type='material', name="Old Material To Delete", total_quantity=5)
        
        # Create Template
        tpl = WorkTemplate.objects.create(name="TEST_WORK_TPL")
        WorkTemplateItem.objects.create(template=tpl, catalog_item=cat_work_1, quantity=3)
        
        # Apply Template
        TemplateService.apply_work_template(stage.id, tpl.id)
        
        # Verify
        works_count = EstimateItem.objects.filter(stage=stage, item_type='work').count()
        old_work_exists = EstimateItem.objects.filter(stage=stage, name="Old Work To Delete").exists()
        new_work = EstimateItem.objects.filter(stage=stage, catalog_item=cat_work_1).first()
        
        if works_count == 1 and not old_work_exists and new_work and new_work.total_quantity == 3:
            self.stdout.write(self.style.SUCCESS("PASS: Work Template cleared old items and applied new."))
        else:
            self.stdout.write(self.style.ERROR(f"FAIL: Work Template logic incorrect. Count: {works_count}, Old Exists: {old_work_exists}"))

        # ---------------------------------------------------------
        # TEST 2: Import from Shields (Replacement Logic)
        # ---------------------------------------------------------
        self.stdout.write(self.style.SUCCESS('\n--- Test 2: Import from Shields (Replace Logic) ---'))
        
        # Setup Shield
        shield = Shield.objects.create(project=project, name="Test Shield", shield_type='power')
        # Add group to shield
        # Need a catalog item for the group matching mapping key or just custom?
        # Service logic: mapping_key = f"shield_{device_type}_{poles}" => "shield_breaker_1P"
        # Let's make a catalog item for it
        cat_breaker = CatalogItem.objects.create(name="TEST_Breaker", mapping_key="shield_breaker_1P", item_type='material')
        ShieldGroup.objects.create(shield=shield, device_type='breaker', poles=1, rating=16, quantity=5)
        
        # Create "Existing" item in Material that should be REPLACED
        # Note: Name matching or Catalog matching. Let's try Catalog matching first, as that's preferred.
        # But wait, logic first looks by Aggregation from Shield, then finds CatalogItem, then Replace.
        # So we need an item in Estimate that MATCHES the CatalogItem "TEST_Breaker".
        
        old_item = EstimateItem.objects.create(
            stage=stage, 
            item_type='material', 
            catalog_item=cat_breaker, 
            name="Old Version Breaker", 
            total_quantity=999 # Wrong quantity
        )
        old_item_id = old_item.id
        
        # Run Import
        res = EstimateAutomationService.import_shield_to_materials(project.id, stage.id)
        
        # Verify
        # Should have found "shield_breaker_1" -> cat_breaker.
        # Should have found existing EstimateItem with cat_breaker.
        # Should have deleted it and created new one with quantity 5.
        
        new_item = EstimateItem.objects.filter(stage=stage, catalog_item=cat_breaker).first()
        
        if not new_item:
             self.stdout.write(self.style.ERROR("FAIL: Imported item not found."))
        elif new_item.id == old_item_id:
             self.stdout.write(self.style.ERROR("FAIL: Item ID is same (Updated instead of Replaced?)"))
        elif new_item.total_quantity != 5:
             self.stdout.write(self.style.ERROR(f"FAIL: Quantity is {new_item.total_quantity}, expected 5"))
        else:
             self.stdout.write(self.style.SUCCESS("PASS: Import replaced existing item correctly."))

        # ---------------------------------------------------------
        # TEST 3: Calculate Works (Replacement Logic)
        # ---------------------------------------------------------
        self.stdout.write(self.style.SUCCESS('\n--- Test 3: Calculate Works (Replace Logic) ---'))
        
        # Setup Material for aggregation
        # We need a material that has aggregation_key="agg_key_1"
        # We created 'cat_mat_agg' with "agg_key_1"
        # And 'cat_work_1' with mapping_key="agg_key_1"
        
        # Create Material in Estimate
        EstimateItem.objects.create(stage=stage, item_type='material', catalog_item=cat_mat_agg, total_quantity=50)
        
        # Create "Existing" Work that should be replaced
        old_work = EstimateItem.objects.create(
            stage=stage, 
            item_type='work', 
            catalog_item=cat_work_1, 
            total_quantity=100 # Wrong quantity
        )
        old_work_id = old_work.id
        
        # Run Calc
        EstimateAutomationService.calculate_works_from_materials(stage.id)
        
        # Verify
        new_work = EstimateItem.objects.filter(stage=stage, catalog_item=cat_work_1).first()
        
        if not new_work:
            self.stdout.write(self.style.ERROR("FAIL: Calculated work not found."))
        elif new_work.id == old_work_id:
            self.stdout.write(self.style.ERROR("FAIL: Work ID is same (Updated instead of Replaced?)"))
        elif new_work.total_quantity != 50: # Unit was 'm' and 'job', but simplified logic is usually direct sum or 1-to-1. Logic sums quantity.
            self.stdout.write(self.style.ERROR(f"FAIL: Quantity is {new_work.total_quantity}, expected 50"))
        else:
            self.stdout.write(self.style.SUCCESS("PASS: Calculation replaced existing work correctly."))

        # Cleanup
        Project.objects.filter(address="TEST_LOGIC_PROJECT").delete()
        CatalogItem.objects.filter(name__startswith="TEST_").delete()
        WorkTemplate.objects.filter(name="TEST_WORK_TPL").delete()
        self.stdout.write(self.style.SUCCESS('\nVerification Complete.'))
