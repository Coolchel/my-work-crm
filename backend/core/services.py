from decimal import Decimal
from django.db.models import Sum
from .models import (
    Project, Stage, Shield, ShieldGroup, LedZone, CatalogItem, EstimateItem
)

class EstimateAutomationService:
    @staticmethod
    def import_shield_to_materials(project_id, stage_id):
        """
        Scanning ShieldGroups and LedZones to create EstimateItems (Materials).
        Also calculates required Enclosures (Shields) based on module count.
        """
        try:
            stage = Stage.objects.get(id=stage_id, project_id=project_id)
        except Stage.DoesNotExist:
            return {"status": "error", "message": "Stage not found"}

        created_count = 0
        updated_count = 0
        
        # 1. Aggregation of Shield Groups (Circuit Breakers, RCDs, etc)
        # We need to group by (device_type, poles, rating)
        # But since ShieldGroup doesn't have a direct 'group by' in ORM easily for constructed fields,
        # we will iterate and aggregate in python or use existing fields.
        # ShieldGroup has: device_type, rating, poles. Perfect.
        
        shields = Shield.objects.filter(project_id=project_id, shield_type='power')
        
        # Dictionary to store aggregated data: key -> quantity
        # key = (device_type, poles, rating)
        aggregated_items = {}
        
        for shield in shields:
            groups = shield.groups.all()
            for group in groups:
                # Key for aggregation
                key = (group.device_type, group.poles, group.rating)
                
                # Check for catalog item override in group? 
                # Currently logic says: search via Key.
                # If group has manual catalog_item, we might want to use it? 
                # LOGIC.md section 4.1 says: Group by 3 attributes -> Search Catalog.
                
                if key not in aggregated_items:
                    aggregated_items[key] = 0
                
                # Assuming 1 group = 1 device physically (often true for modular devices)
                # But 'group' can represent multiple? No, usually 1 row = 1 device in this app logic (1P, 16A).
                # Actually, check logic. ShieldGroup usually is "Kitchen Sockets, 16A, 1P". It is ONE breaker.
                aggregated_items[key] += 1

        # Process Aggregated Items
        for (device_type, poles, rating), quantity in aggregated_items.items():
            # Form search key: shield_{device_type}_{poles}
            mapping_key = f"shield_{device_type}_{poles}"
            
            catalog_item = CatalogItem.objects.filter(mapping_key=mapping_key).first()
            if not catalog_item:
                continue
                
            # Name Construction
            final_name = catalog_item.name
            if rating:
                final_name = f"{final_name} {rating}"
                
            # Merge Logic: Search by CatalogItem (Best) or Name (Fallback)
            est_item = EstimateItem.objects.filter(
                stage=stage, 
                catalog_item=catalog_item,
                item_type='material'
            ).first()
            
            if est_item:
                # Update existing
                est_item.total_quantity = quantity
                # We update name only if it was auto-generated or empty? 
                # Let's keep existing name to respect user edits, unless it's generic?
                # User said: "Update total_quantity".
                est_item.save()
                updated_count += 1
            else:
                EstimateItem.objects.create(
                    stage=stage,
                    catalog_item=catalog_item,
                    name=final_name,
                    item_type='material',
                    unit=catalog_item.unit,
                    total_quantity=quantity,
                    price_per_unit=catalog_item.default_price,
                    currency=catalog_item.default_currency,
                    markup_percent=stage.markup_percent
                )
                created_count += 1
                
        # 2. Logic for Enclosures (Shields)
        # We calculate modules per shield, select best standard size, and aggregate by size.
        enclosure_requirements = {} # size -> count
        standard_sizes = [2, 4, 6, 8, 12, 18, 24, 36, 48, 60, 72, 96, 120, 144]
        
        for shield in shields:
            total_modules = sum(g.modules_count for g in shield.groups.all())
            if total_modules == 0:
                continue

            # Find standard size
            standard_sizes = [2, 4, 6, 8, 12, 18, 24, 36, 48, 60, 72, 96, 120, 144]
            selected_size = None
            for size in standard_sizes:
                if total_modules <= size:
                    selected_size = size
                    break
            
            # If bigger than max, take max or skip? Take max.
            # Debugging
            if not selected_size and total_modules > 0:
                 print(f"DEBUG: Could not match size for modules={total_modules}, taking max.")
                 selected_size = standard_sizes[-1]
            elif selected_size:
                 print(f"DEBUG: Modules={total_modules} -> Selected Size={selected_size}")

            if selected_size:
                if selected_size not in enclosure_requirements:
                    enclosure_requirements[selected_size] = 0
                enclosure_requirements[selected_size] += 1
                
        # Process Enclosures
        for size, count in enclosure_requirements.items():
            enclosure_key = f"shield_enclosure_{size}"
            
            # Try to find specific size
            catalog_enclosure = CatalogItem.objects.filter(mapping_key=enclosure_key).first()
            
            if not catalog_enclosure:
                print(f"DEBUG: Missing Catalog Item for key: {enclosure_key}")
            
            # Fallback: if not found, maybe find next available size?
            # For now, strict match to encourage proper catalog setup.
            
            if catalog_enclosure:
                est_item = EstimateItem.objects.filter(
                    stage=stage,
                    catalog_item=catalog_enclosure,
                    item_type='material'
                ).first()
                
                if est_item:
                    est_item.total_quantity = count
                    est_item.save()
                    updated_count += 1
                else:
                    EstimateItem.objects.create(
                        stage=stage,
                        catalog_item=catalog_enclosure,
                        name=catalog_enclosure.name,
                        item_type='material',
                        unit=catalog_enclosure.unit,
                        total_quantity=count,
                        price_per_unit=catalog_enclosure.default_price,
                        currency=catalog_enclosure.default_currency
                    )
                    created_count += 1

        return {
            "status": "success", 
            "created": created_count, 
            "updated": updated_count
        }

    @staticmethod
    def calculate_works_from_materials(stage_id):
        """
        Scans all Materials in the stage.
        If Material has a 'related_work_item', create/update corresponding Work item.
        """
        try:
            stage = Stage.objects.get(id=stage_id)
        except Stage.DoesNotExist:
            return {"status": "error", "message": "Stage not found"}
            
        materials = EstimateItem.objects.filter(stage=stage, item_type='material')
        
        created_count = 0
        updated_count = 0
        
        for mat in materials:
            # Check if linked catalog item has related work
            if not mat.catalog_item or not mat.catalog_item.related_work_item:
                continue
                
            related_work_catalog = mat.catalog_item.related_work_item
            
            # Logic: 
            # Quantity = Material Quantity
            # Name = RelatedWorkCatalog Name (or we can append details? No, standard name usually)
            
            # Find or Create Work Item
            work_item = EstimateItem.objects.filter(
                stage=stage,
                catalog_item=related_work_catalog,
                item_type='work'
            ).first()
            
            if work_item:
                # Update quantity? 
                # Section 5.1 in LOGIC.md says: Logic duplication handling.
                # If exists -> Propose update or create new. 
                # For automation, let's Accumulate or Replace?
                # Logic: "100m cable -> 100m work".
                # If we have multiple cables (Cable 3x1.5 (100m) and Cable 3x2.5 (50m))
                # And both map to "Installation of Cable", we should SUM them.
                
                # BUT here we are iterating materials. 
                # If we just set "total_quantity = mat.total_quantity", we overwrite previous loop iteration.
                # We need to AGGREGATE works first.
                pass
                
        # Better approach: Aggregate Works first
        works_aggregation = {} # CatalogItem(Work) -> Total Quantity
        
        for mat in materials:
            if mat.catalog_item and mat.catalog_item.related_work_item:
                work_cat = mat.catalog_item.related_work_item
                qty = mat.total_quantity
                
                if work_cat not in works_aggregation:
                    works_aggregation[work_cat] = 0
                works_aggregation[work_cat] += qty
                
        # Now apply to DB
        for work_cat, total_qty in works_aggregation.items():
            work_item = EstimateItem.objects.filter(
                stage=stage,
                catalog_item=work_cat,
                item_type='work'
            ).first()
            
            if work_item:
                # Update existing quantity
                work_item.total_quantity = total_qty
                work_item.save()
                updated_count += 1
            else:
                EstimateItem.objects.create(
                    stage=stage,
                    catalog_item=work_cat,
                    name=work_cat.name,
                    item_type='work',
                    unit=work_cat.unit,
                    total_quantity=total_qty,
                    price_per_unit=work_cat.default_price,
                    currency=work_cat.default_currency
                )
                created_count += 1
                
        return {
            "status": "success", 
            "created": created_count, 
            "updated": updated_count
        }
