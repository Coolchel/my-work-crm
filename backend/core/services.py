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
        
        # Helper to create/replace items
        def create_or_replace(name, quantity, catalog_item=None, price=None, currency='USD', unit='шт'):
            nonlocal created_count, updated_count

            # Defaults if catalog_item provided
            if catalog_item:
                if not name: name = catalog_item.name
                if price is None: price = catalog_item.default_price
                if not unit: unit = catalog_item.unit
                if not currency: currency = catalog_item.default_currency

            # Fallbacks
            if price is None: price = Decimal('0.00')

            filter_kwargs = {
                'stage': stage,
                'item_type': 'material',
            }
            if catalog_item:
                filter_kwargs['catalog_item'] = catalog_item
                # If we have a catalog item, we want to replace ALL items with this catalog item
                # regardless of name (as names might be slightly different or custom)
                # But to be safe and strictly follow "if found - replace", we filter by catalog_item.
            else:
                 # If no catalog item, match by name exactly
                filter_kwargs['name'] = name
                filter_kwargs['catalog_item__isnull'] = True

            # Find existing items to replace
            existing_items = EstimateItem.objects.filter(**filter_kwargs)
            
            if existing_items.exists():
                # DELETE all existing matching items
                existing_items.delete()
                updated_count += 1 # Count as update/replacement
            else:
                created_count += 1

            # CREATE new item with full quantity
            EstimateItem.objects.create(
                stage=stage,
                catalog_item=catalog_item,
                name=name,
                item_type='material',
                unit=unit,
                total_quantity=quantity,
                price_per_unit=price,
                currency=currency,
                markup_percent=stage.markup_percent
            )

        # --- 1. Aggregation of Shield Groups (Circuit Breakers, etc) ---
        shields = Shield.objects.filter(project_id=project_id, shield_type='power')
        aggregated_items = {}
        
        for shield in shields:
            groups = shield.groups.all()
            for group in groups:
                key = (group.device_type, group.poles, group.rating)
                if key not in aggregated_items:
                    aggregated_items[key] = 0
                aggregated_items[key] += group.quantity

        for (device_type, poles, rating), quantity in aggregated_items.items():
            mapping_key = f"shield_{device_type}_{poles}"
            catalog_item = CatalogItem.objects.filter(mapping_key=mapping_key).first()
            
            final_name = ""
            if catalog_item:
                final_name = catalog_item.name
                if rating: final_name = f"{final_name} {rating}"
            else:
                final_name = f"ВНИМАНИЕ: Не найден в каталоге! ({device_type} {poles} {rating})"
            
            create_or_replace(name=final_name, quantity=quantity, catalog_item=catalog_item)
                
        # --- 2. Logic for Enclosures (Shields) ---
        
        standard_sizes = [2, 4, 6, 8, 12, 24, 36, 48, 60, 72, 96, 120, 144]

        # Structure: (size, mounting) -> count
        power_enclosure_requirements = {} 
        media_enclosure_requirements = {} 

        # Iterate ALL shields and calculate per-shield requirements
        all_shields = Shield.objects.filter(project_id=project_id)
        
        # User Rule: If any shield exists, clear ALL old shield enclosures from estimate first
        if all_shields.exists():
            # 1. Delete by Catalog Mapping Key (Standard Enclosures)
            EstimateItem.objects.filter(
                stage=stage,
                item_type='material',
                catalog_item__mapping_key__startswith='shield_enclosure_'
            ).delete()
            EstimateItem.objects.filter(
                stage=stage,
                item_type='material',
                catalog_item__mapping_key__startswith='shield_media_enclosure_'
            ).delete()
            
            # 2. Delete Specific Warnings / Custom Items (No Catalog Item)
            # We match by name patterns used below
            warning_patterns = [
                "ВНИМАНИЕ: Индивидуальный расчет щита",
                "ВНИМАНИЕ: Индивидуальный расчет слаботочного щита",
                "ВНИМАНИЕ: Индивидуальный расчет щита LED",
                "Переместить трансформаторы LED",
                "ВНИМАНИЕ: Не найден корпус в каталоге!",
                "ВНИМАНИЕ: Не найден слаботочный корпус!"
            ]
            for pattern in warning_patterns:
                EstimateItem.objects.filter(
                    stage=stage,
                    item_type='material',
                    name__startswith=pattern
                ).delete()
        
        for shield in all_shields:
            shield_size = None
            is_media = False
            mounting = shield.mounting # 'internal' or 'external'
            
            if shield.shield_type == 'power':
                # --- Power Logic ---
                total_modules = sum(g.modules_count * g.quantity for g in shield.groups.all())
                if total_modules == 0: continue
                
                if total_modules > 144:
                     create_or_replace(
                         name=f"ВНИМАНИЕ: Индивидуальный расчет щита (превышен предел 144 мод, факт: {total_modules})",
                         quantity=1,
                         price=Decimal('0.00')
                     )
                     continue
                
                shield_size = next((s for s in standard_sizes if total_modules <= s), standard_sizes[-1])
                is_media = False

            elif shield.shield_type == 'led':
                # --- LED Logic ---
                drivers = sum(z.quantity for z in shield.led_zones.all())
                if drivers == 0: continue
                
                is_media = True
                if drivers <= 2:
                    create_or_replace(
                        name=f"Переместить трансформаторы LED в слаботочный щит (из {shield.name})",
                        quantity=1,
                        price=Decimal('0.00')
                    )
                    continue
                elif drivers > 15:
                    create_or_replace(
                        name=f"ВНИМАНИЕ: Индивидуальный расчет щита LED (более 15 блоков, {shield.name})",
                        quantity=1,
                        price=Decimal('0.00')
                    )
                    continue
                else:
                    if 3 <= drivers <= 4: shield_size = 24
                    elif 5 <= drivers <= 9: shield_size = 36
                    elif 10 <= drivers <= 12: shield_size = 48
                    elif 13 <= drivers <= 15: shield_size = 60

            elif shield.shield_type == 'multimedia':
                # --- Multimedia Logic ---
                lines = shield.internet_lines_count
                is_media = True
                if lines > 10:
                    create_or_replace(
                        name=f"ВНИМАНИЕ: Индивидуальный расчет слаботочного щита (> 10 линий, {shield.name})",
                        quantity=1,
                        price=Decimal('0.00')
                    )
                    continue
                else:
                    shield_size = 36 if (5 <= lines <= 10) else 24

            # --- Add to Requirements ---
            if shield_size:
                # Key is now tuple (size, mounting)
                key = (shield_size, mounting)
                if is_media:
                    media_enclosure_requirements[key] = media_enclosure_requirements.get(key, 0) + 1
                else:
                    power_enclosure_requirements[key] = power_enclosure_requirements.get(key, 0) + 1

        # --- 3. Process Enclosures (Two Passes) ---
        
        # Pass 3.1: Power Enclosures
        for (size, mounting), count in power_enclosure_requirements.items():
            enclosure_key = f"shield_enclosure_{size}_{mounting}"
            catalog_enclosure = CatalogItem.objects.filter(mapping_key=enclosure_key).first()
            
            final_name = ""
            if catalog_enclosure:
                final_name = catalog_enclosure.name
            else:
                mount_str = "Встр." if mounting == 'internal' else "Накл."
                final_name = f"ВНИМАНИЕ: Не найден корпус в каталоге! ({size} мод, {mount_str})"
            
            create_or_replace(name=final_name, quantity=count, catalog_item=catalog_enclosure)

        # Pass 3.2: Media Enclosures
        for (size, mounting), count in media_enclosure_requirements.items():
            enclosure_key = f"shield_media_enclosure_{size}_{mounting}"
            catalog_enclosure = CatalogItem.objects.filter(mapping_key=enclosure_key).first()
            
            final_name = ""
            if catalog_enclosure:
                final_name = catalog_enclosure.name
            else:
                mount_str = "Встр." if mounting == 'internal' else "Накл."
                final_name = f"ВНИМАНИЕ: Не найден слаботочный корпус! ({size} мод, {mount_str})"
            
            create_or_replace(name=final_name, quantity=count, catalog_item=catalog_enclosure)

        return {
            "status": "success", 
            "created": created_count, 
            "updated": updated_count
        }

    @staticmethod
    def calculate_works_from_materials(stage_id):
        """
        Scans all Materials in the stage.
        Generates Works based on two strategies:
        1. Aggregation: Materials with 'aggregation_key' are summed up and mapped to a single Work item.
        2. Direct (1-to-1): Materials without 'aggregation_key' but with 'related_work_item' generate individual Work items.
        
        UPDATED LOGIC: 
        - Replaces existing works instead of updating/merging.
        - Deletes old matches, creates new ones.
        """
        try:
            stage = Stage.objects.get(id=stage_id)
        except Stage.DoesNotExist:
            return {"status": "error", "message": "Stage not found"}
            
        materials = EstimateItem.objects.filter(stage=stage, item_type='material')
        
        created_count = 0
        updated_count = 0
        
        # 1. Aggregation Dictionary: { aggregation_key: total_quantity }
        aggregation_map = {}
        
        # 1.1 Also collect direct 1-to-1 mappings that act like aggregation (unique per Work CatalogItem)
        # We will treat 1-to-1 also as "Aggregation by Work Catalog Item" essentially.
        # So we can unify the creation logic.
        
        # Map: mapping_key (or Work CatalogItem ID) -> quantity
        works_to_create = {} # Key: Work CatalogItem (obj), Value: Quantity
        
        for mat in materials:
            if not mat.catalog_item:
                continue
                
            cat_item = mat.catalog_item
            qty = mat.total_quantity
            
            # Case A: Aggregation Key
            if cat_item.aggregation_key:
                agg_key = cat_item.aggregation_key
                if agg_key not in aggregation_map:
                    aggregation_map[agg_key] = 0
                aggregation_map[agg_key] += qty
                
            # Case B: Direct 1-to-1
            elif cat_item.related_work_item:
                work_cat = cat_item.related_work_item
                if work_cat not in works_to_create:
                    works_to_create[work_cat] = 0
                works_to_create[work_cat] += qty

        # 2. Process Aggregated Items (Convert to Work Catalog Items)
        for agg_key, total_qty in aggregation_map.items():
            # Find Work CatalogItem by mapping_key == agg_key
            work_cat = CatalogItem.objects.filter(mapping_key=agg_key, item_type='work').first()
            
            if work_cat:
                if work_cat not in works_to_create:
                    works_to_create[work_cat] = 0
                works_to_create[work_cat] += total_qty
            else:
                # Warning if work item not found for key
                # Special handling for "Not Found" case - we can't easily aggregate by object
                # So handle immediately
                final_name = f"ВНИМАНИЕ: Не найдена работа для ключа '{agg_key}'"
                
                # Check existance by Name
                existing = EstimateItem.objects.filter(stage=stage, name=final_name, item_type='work')
                if existing.exists():
                    existing.delete()
                    updated_count += 1
                else:
                    created_count += 1

                EstimateItem.objects.create(
                    stage=stage,
                    name=final_name,
                    item_type='work',
                    unit='?',
                    total_quantity=total_qty,
                    price_per_unit=Decimal(0),
                    markup_percent=stage.markup_percent
                )

        # 3. Create/Replace Works from aggregated list
        for work_cat, total_qty in works_to_create.items():
            # Find existing works with this catalog item
            existing = EstimateItem.objects.filter(
                stage=stage,
                catalog_item=work_cat,
                item_type='work'
            )
            
            if existing.exists():
                existing.delete()
                updated_count += 1
            else:
                created_count += 1
            
            EstimateItem.objects.create(
                stage=stage,
                catalog_item=work_cat,
                name=work_cat.name,
                item_type='work',
                unit=work_cat.unit,
                total_quantity=total_qty,
                price_per_unit=work_cat.default_price,
                currency=work_cat.default_currency,
                markup_percent=stage.markup_percent
            )
                
        return {
            "status": "success", 
            "created": created_count, 
            "updated": updated_count
        }

class TemplateService:
    @staticmethod
    def apply_work_template(stage_id, template_id):
        from .models import WorkTemplate, EstimateItem
        
        try:
            stage = Stage.objects.get(id=stage_id)
            template = WorkTemplate.objects.get(id=template_id)
        except (Stage.DoesNotExist, WorkTemplate.DoesNotExist):
            return {"status": "error", "message": "Stage or Template not found"}

        # CLEAR Existing Works
        EstimateItem.objects.filter(stage=stage, item_type='work').delete()

        created_count = 0
        
        for item in template.items.all():
            EstimateItem.objects.create(
                stage=stage,
                catalog_item=item.catalog_item, 
                item_type='work',
                total_quantity=item.quantity,
                markup_percent=stage.markup_percent
            )
            created_count += 1
        
        return {"status": "success", "created": created_count, "updated": 0}

    @staticmethod
    def apply_material_template(stage_id, template_id):
        from .models import MaterialTemplate, EstimateItem

        try:
            stage = Stage.objects.get(id=stage_id)
            template = MaterialTemplate.objects.get(id=template_id)
        except (Stage.DoesNotExist, MaterialTemplate.DoesNotExist):
            return {"status": "error", "message": "Stage or Template not found"}

        # CLEAR Existing Materials
        EstimateItem.objects.filter(stage=stage, item_type='material').delete()

        created_count = 0
        
        for item in template.items.all():
            EstimateItem.objects.create(
                stage=stage,
                catalog_item=item.catalog_item,
                item_type='material',
                total_quantity=item.quantity,
                markup_percent=stage.markup_percent
            )
            created_count += 1
        
        return {"status": "success", "created": created_count, "updated": 0}

    @staticmethod
    def apply_powershield_template(shield_id, template_id):
        from .models import PowerShieldTemplate, ShieldGroup

        try:
            shield = Shield.objects.get(id=shield_id)
            template = PowerShieldTemplate.objects.get(id=template_id)
        except (Shield.DoesNotExist, PowerShieldTemplate.DoesNotExist):
            return {"status": "error", "message": "Shield or Template not found"}

        # CLEAR Existing Groups
        ShieldGroup.objects.filter(shield=shield).delete()

        created_count = 0

        for item in template.items.all():
            ShieldGroup.objects.create(
                shield=shield,
                device_type=item.device_type,
                rating=item.rating,
                poles=item.poles,
                quantity=item.quantity,
                catalog_item=item.catalog_item
            )
            created_count += 1
        
        return {"status": "success", "created": created_count}

    @staticmethod
    def apply_led_shield_template(shield_id, template_id):
        from .models import LedShieldTemplate, LedZone

        try:
            shield = Shield.objects.get(id=shield_id)
            template = LedShieldTemplate.objects.get(id=template_id)
        except (Shield.DoesNotExist, LedShieldTemplate.DoesNotExist):
            return {"status": "error", "message": "Shield or Template not found"}

        # CLEAR Existing Zones
        LedZone.objects.filter(shield=shield).delete()

        created_count = 0
        
        for item in template.items.all():
            LedZone.objects.create(
                shield=shield,
                transformer=item.transformer,
                zone=item.zone,
                quantity=item.quantity,
                catalog_item=item.catalog_item
            )
            created_count += 1
        
        return {"status": "success", "created": created_count, "updated": 0}

    @staticmethod
    def create_work_template_from_stage(stage_id, name, description=""):
        from .models import WorkTemplate, WorkTemplateItem, EstimateItem
        
        try:
            stage = Stage.objects.get(id=stage_id)
        except Stage.DoesNotExist:
            return {"status": "error", "message": "Stage not found"}

        # Create Template
        template = WorkTemplate.objects.create(name=name, description=description)
        
        # Copy Items
        items = EstimateItem.objects.filter(stage=stage, item_type='work')
        count = 0
        for item in items:
            if not item.catalog_item: continue # Skip custom items without catalog link? Or create without?
            # Ideally we only template catalog items to keep link.
            
            WorkTemplateItem.objects.create(
                template=template,
                catalog_item=item.catalog_item,
                quantity=item.total_quantity
            )
            count += 1
            
        return {"status": "success", "template_id": template.id, "count": count}

    @staticmethod
    def create_material_template_from_stage(stage_id, name, description=""):
        from .models import MaterialTemplate, MaterialTemplateItem, EstimateItem
        
        try:
            stage = Stage.objects.get(id=stage_id)
        except Stage.DoesNotExist:
            return {"status": "error", "message": "Stage not found"}

        template = MaterialTemplate.objects.create(name=name, description=description)
        
        items = EstimateItem.objects.filter(stage=stage, item_type='material')
        count = 0
        for item in items:
            if not item.catalog_item: continue
            
            MaterialTemplateItem.objects.create(
                template=template,
                catalog_item=item.catalog_item,
                quantity=item.total_quantity
            )
            count += 1
            
        return {"status": "success", "template_id": template.id, "count": count}

    @staticmethod
    def create_powershield_template_from_shield(shield_id, name, description=""):
        from .models import PowerShieldTemplate, PowerShieldTemplateItem, ShieldGroup
        
        try:
            shield = Shield.objects.get(id=shield_id)
        except Shield.DoesNotExist:
            return {"status": "error", "message": "Shield not found"}

        template = PowerShieldTemplate.objects.create(name=name, description=description)
        
        groups = shield.groups.all()
        count = 0
        for group in groups:
            PowerShieldTemplateItem.objects.create(
                template=template,
                device_type=group.device_type,
                rating=group.rating,
                poles=group.poles,
                quantity=group.quantity,
                catalog_item=group.catalog_item
            )
            count += 1
            
        return {"status": "success", "template_id": template.id, "count": count}

    @staticmethod
    def create_ledshield_template_from_shield(shield_id, name, description=""):
        from .models import LedShieldTemplate, LedShieldTemplateItem
        
        try:
            shield = Shield.objects.get(id=shield_id)
        except Shield.DoesNotExist:
            return {"status": "error", "message": "Shield not found"}

        template = LedShieldTemplate.objects.create(name=name, description=description)
        
        zones = shield.led_zones.all()
        count = 0
        for zone in zones:
            LedShieldTemplateItem.objects.create(
                template=template,
                transformer=zone.transformer,
                zone=zone.zone,
                quantity=zone.quantity,
                catalog_item=zone.catalog_item
            )
            count += 1
            
        return {"status": "success", "template_id": template.id, "count": count}
