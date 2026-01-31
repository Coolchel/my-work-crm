from django.core.management.base import BaseCommand
from core.models import CatalogCategory, CatalogItem, Project, Shield, ShieldGroup, Stage

class Command(BaseCommand):
    help = 'Seeds data for Full Automation verification'

    def handle(self, *args, **options):
        self.stdout.write("Seeding Full Automation Data...")
        
        # 1. Create Categories
        cat_mat, _ = CatalogCategory.objects.get_or_create(name="Автоматика", slug="avtomatika")
        cat_work, _ = CatalogCategory.objects.get_or_create(name="Установка Щит", slug="install_shield")

        # 2. Create Works
        work_1p, _ = CatalogItem.objects.get_or_create(
            name="Монтаж 1P устройства",
            defaults={'category': cat_work, 'item_type': 'work', 'unit': 'шт', 'default_price': 5.00}
        )
        work_2p, _ = CatalogItem.objects.get_or_create(
            name="Монтаж 2P устройства",
            defaults={'category': cat_work, 'item_type': 'work', 'unit': 'шт', 'default_price': 8.00}
        )
        work_3p4p, _ = CatalogItem.objects.get_or_create(
            name="Монтаж 3P/4P устройства",
            defaults={'category': cat_work, 'item_type': 'work', 'unit': 'шт', 'default_price': 12.00}
        )
        work_shield, _ = CatalogItem.objects.get_or_create(
            name="Монтаж корпуса щита",
            defaults={'category': cat_work, 'item_type': 'work', 'unit': 'шт', 'default_price': 50.00}
        )

        # 3. Create Materials with mapping and links
        
        # 3.1. Breaker 1P
        CatalogItem.objects.update_or_create(
            mapping_key="shield_circuit_breaker_1P",
            defaults={
                'name': "Автоматический выключатель 1P",
                'category': cat_mat,
                'item_type': 'material',
                'unit': 'шт',
                'default_price': 3.50,
                'related_work_item': work_1p
            }
        )

        # 3.2. Diff Breaker 2P
        CatalogItem.objects.update_or_create(
            mapping_key="shield_diff_breaker_2P",
            defaults={
                'name': "Диф.автомат 2P",
                'category': cat_mat,
                'item_type': 'material',
                'unit': 'шт',
                'default_price': 20.00,
                'related_work_item': work_2p
            }
        )

        # 3.3. RCD 2P
        CatalogItem.objects.update_or_create(
            mapping_key="shield_rcd_2P",
            defaults={
                'name': "УЗО 2P",
                'category': cat_mat,
                'item_type': 'material',
                'unit': 'шт',
                'default_price': 25.00,
                'related_work_item': work_2p
            }
        )

        # 3.4. Voltage Relay 2P
        CatalogItem.objects.update_or_create(
            mapping_key="shield_relay_2P",
            defaults={
                'name': "Реле напряжения 2P",
                'category': cat_mat,
                'item_type': 'material',
                'unit': 'шт',
                'default_price': 30.00,
                'related_work_item': work_2p
            }
        )

        # 3.5. Load Switch 3P
        CatalogItem.objects.update_or_create(
            mapping_key="shield_load_switch_3P",
            defaults={
                'name': "Выключатель нагрузки 3P",
                'category': cat_mat,
                'item_type': 'material',
                'unit': 'шт',
                'default_price': 15.00,
                'related_work_item': work_3p4p
            }
        )

        # 3.6. Enclosure 24
        CatalogItem.objects.update_or_create(
            mapping_key="shield_enclosure_24",
            defaults={
                'name': "Щит встраиваемый 24 модуля",
                'category': cat_mat,
                'item_type': 'material',
                'unit': 'шт',
                'default_price': 50.00,
                'related_work_item': work_shield
            }
        )
        
        # --- 3.7 Shield Enclosures (Standardized Naming) ---
        # Format: Щит [Type] [Size] [Mounting]
        # Type: силовой / слаботочный
        # Size: на X модулей
        # Mounting: (встройка) / (наружный)
        
        enclosure_configs = [
            # Power (Силовой)
            (24, 'shield_enclosure', 'internal', "Щит силовой на 24 модуля (встройка)", 50.00),
            (24, 'shield_enclosure', 'external', "Щит силовой на 24 модуля (наружный)", 55.00),
            (36, 'shield_enclosure', 'internal', "Щит силовой на 36 модулей (встройка)", 70.00),
            (36, 'shield_enclosure', 'external', "Щит силовой на 36 модулей (наружный)", 75.00),
            (48, 'shield_enclosure', 'internal', "Щит силовой на 48 модулей (встройка)", 90.00),
            (48, 'shield_enclosure', 'external', "Щит силовой на 48 модулей (наружный)", 95.00),
            
            # Media (Слаботочный)
            (24, 'shield_media_enclosure', 'internal', "Щит слаботочный на 24 модуля (встройка)", 60.00),
            (24, 'shield_media_enclosure', 'external', "Щит слаботочный на 24 модуля (наружный)", 65.00),
            (36, 'shield_media_enclosure', 'internal', "Щит слаботочный на 36 модулей (встройка)", 80.00),
            (36, 'shield_media_enclosure', 'external', "Щит слаботочный на 36 модулей (наружный)", 85.00),
            (48, 'shield_media_enclosure', 'internal', "Щит слаботочный на 48 модулей (встройка)", 100.00),
            (48, 'shield_media_enclosure', 'external', "Щит слаботочный на 48 модулей (наружный)", 105.00),
        ]
        
        for size, base_key, mounting, name, price in enclosure_configs:
            key = f"{base_key}_{size}_{mounting}"
            CatalogItem.objects.update_or_create(
                mapping_key=key,
                defaults={
                    'name': name,
                    'category': cat_mat,
                    'item_type': 'material',
                    'unit': 'шт',
                    'default_price': price,
                    'related_work_item': work_shield
                }
            )

        # 3.7.X Enclosure 18 Internal (Legacy/Specific request)
        CatalogItem.objects.update_or_create(
            mapping_key="shield_enclosure_18_internal",
            defaults={
                'name': "Щит встраиваемый 18 модулей",
                'category': cat_mat,
                'item_type': 'material',
                'unit': 'шт',
                'default_price': 40.00,
                'related_work_item': work_shield
            }
        )

        self.stdout.write("Catalog Items updated/created.")

        # 4. Create Project and Shield for Test
        project, _ = Project.objects.get_or_create(
            address="Full Automation Test",
            defaults={'client_info': "Auto Tester"}
        )
        stage, _ = Stage.objects.get_or_create(
            project=project,
            title='stage_1',
            defaults={'status': 'plan'}
        )
        # Clear existing shields to avoid lookup errors and duplicates
        Shield.objects.filter(project=project).delete()
        
        # Re-create Main Shield
        shield = Shield.objects.create(
            project=project,
            shield_type='power',
            name='Main Shield'
        )
        
        # 5. Populate Shield with diverse items
        
        # 5.1. Breakers 1P 16A (x2)
        ShieldGroup.objects.create(shield=shield, device_type='circuit_breaker', rating='16A', poles='1P', zone='Light', modules_count=1)
        ShieldGroup.objects.create(shield=shield, device_type='circuit_breaker', rating='16A', poles='1P', zone='Socket', modules_count=1)
        
        # 5.2. Diff 2P 16A (x1)
        ShieldGroup.objects.create(shield=shield, device_type='diff_breaker', rating='16A', poles='2P', zone='Wet Area', modules_count=2)
        
        # 5.3. RCD 2P 40A (x1)
        ShieldGroup.objects.create(shield=shield, device_type='rcd', rating='40A', poles='2P', zone='Input RCD', modules_count=2)
        
        # 5.4. Relay 2P 63A (x1)
        ShieldGroup.objects.create(shield=shield, device_type='relay', rating='63A', poles='2P', zone='Input Protection', modules_count=2)
        
        # 5.5. Load Switch 3P 63A (x1)
        ShieldGroup.objects.create(shield=shield, device_type='load_switch', rating='63A', poles='3P', zone='Main Switch', modules_count=3)

        # Total modules: 1+1+2+2+2+3 = 11 modules. 
        # Should pick matching enclosure -> 12 modules? 
        # But we only seeded 18 and 24.
        # Let's add 12 to catalog just in case, or force higher modules count.
        # Let's add more params to force 18 modules (need 13+ modules).
        # Add another 3P switch
        ShieldGroup.objects.create(shield=shield, device_type='load_switch', rating='32A', poles='3P', zone='Backup', modules_count=3)
        # Total: 14 modules -> Should pick 18.
        
        # 5.6. MISSING ITEM TEST
        # Add a device that definitely doesn't exist in catalog to instructions
        ShieldGroup.objects.create(
            shield=shield,
            device_type='other',
            rating='Unknown',
            poles='1P',
            zone='Mystery Zone',
            modules_count=1
        )

        self.stdout.write(f"Project ID: {project.id}, Stage ID: {stage.id}")
        self.stdout.write("Shield populated with 14 modules + 1 Mystery item (15 total).")
        self.stdout.write("Expect: Enclosure 18 (fits 15) and ONE 'Warning' line in estimate.")
        
        # 9. Create Mega Shield (> 144 modules)
        mega_shield = Shield.objects.create(
            project=project,
            shield_type='power',
            name='Mega Shield'
        )
        ShieldGroup.objects.create(
            shield=mega_shield,
            device_type='rx_switch', # Dummy
            rating='1000A',
            poles='150P', # Hack to force 150 modules (model auto-calcs from poles)
            zone='Factory',
            # modules_count=150 # Ignored by save() logic
        )
        self.stdout.write("Created 'Mega Shield' with 150 modules (via 150P). Expect: Warning Individual Calculation.")
        
        # 10. Create Empty Shield (0 modules)
        empty_shield = Shield.objects.create(
            project=project,
            shield_type='power',
            name='Empty Shield'
        )
        self.stdout.write("Created 'Empty Shield' (0 modules). Expect: No enclosure line for this shield.")
        
        # 11. Create Multimedia Shield 1 (6 lines -> 36 mod)
        media_shield = Shield.objects.create(
             project=project,
             shield_type='multimedia',
             name='Media Shield 1',
             internet_lines_count=6 # > 4 -> 36 modules
        )
        
        # 12. Create Multimedia Shield 2 (External, 4 lines -> 24 mod)
        media_shield_2 = Shield.objects.create(
             project=project,
             shield_type='multimedia',
             name='Media Shield 2',
             internet_lines_count=4, # <= 4 -> 24 modules
             mounting='external'
        )
        self.stdout.write("Created 'Media Shield 1' (36 mod, Auto-Internal) and 'Media Shield 2' (24 mod, External). Expect: Media Shield 36 (Встр) and Media Shield 24 (Навесной).")
