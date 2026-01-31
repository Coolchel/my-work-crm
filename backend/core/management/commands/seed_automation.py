from django.core.management.base import BaseCommand
from core.models import CatalogCategory, CatalogItem, Project, Shield, ShieldGroup, Stage

class Command(BaseCommand):
    help = 'Seeds data for Automation verification'

    def handle(self, *args, **options):
        self.stdout.write("Seeding Automation Data...")
        
        # 1. Create Categories
        cat_mat, _ = CatalogCategory.objects.get_or_create(name="Автоматика", slug="avtomatika")
        cat_work, _ = CatalogCategory.objects.get_or_create(name="Установка Щит", slug="install_shield")

        # 2. Create Work Item: "Install Breaker"
        work_breaker, _ = CatalogItem.objects.get_or_create(
            name="Установка однополюсного автомата",
            defaults={
                'category': cat_work,
                'item_type': 'work',
                'unit': 'шт',
                'default_price': 5.00,
                'default_currency': 'USD'
            }
        )
        
        # 2b. Create Work Item: "Mount Shield 24"
        work_mount_shield, _ = CatalogItem.objects.get_or_create(
            name="Монтаж щита встраиваемого (до 24 мод)",
            defaults={
                'category': cat_work,
                'item_type': 'work',
                'unit': 'шт',
                'default_price': 25.00,
                'default_currency': 'USD'
            }
        )

        # 3. Create Material Item: "Breaker 1P" with mapping and relation
        mat_breaker, created = CatalogItem.objects.get_or_create(
            mapping_key="shield_circuit_breaker_1P",
            defaults={
                'name': "Автоматический выключатель 1P",
                'category': cat_mat,
                'item_type': 'material',
                'unit': 'шт',
                'default_price': 3.50,
                'default_currency': 'USD',
                'related_work_item': work_breaker
            }
        )
        if not created:
             mat_breaker.related_work_item = work_breaker
             mat_breaker.save()
             
        # 4. Create Enclosure (Shield Box) 24 modules
        mat_shield_24, created_sh = CatalogItem.objects.get_or_create(
            mapping_key="shield_enclosure_24",
            defaults={
                'name': "Щит встраиваемый 24 модуля (Hager)",
                'category': cat_mat,
                'item_type': 'material',
                'unit': 'шт',
                'default_price': 50.00,
                'default_currency': 'USD',
                'related_work_item': work_mount_shield
            }
        )
        if not created_sh:
            mat_shield_24.related_work_item = work_mount_shield
            mat_shield_24.save()
            
        # 4b. Create Enclosure Size 4 (for small test case)
        mat_shield_4, created_sh4 = CatalogItem.objects.get_or_create(
            mapping_key="shield_enclosure_4",
            defaults={
                'name': "Щит пластиковый 4 модуля",
                'category': cat_mat,
                'item_type': 'material',
                'unit': 'шт',
                'default_price': 10.00,
                'default_currency': 'USD',
                'related_work_item': work_mount_shield
            }
        )
        if not created_sh4:
            mat_shield_4.related_work_item = work_mount_shield
            mat_shield_4.save()
        if not created_sh4:
            mat_shield_4.related_work_item = work_mount_shield
            mat_shield_4.save()

        # 5. Create Work Item: "Mount RCD"
        work_mount_rcd, _ = CatalogItem.objects.get_or_create(
            name="Монтаж УЗО (2P)",
            defaults={
                'category': cat_work,
                'item_type': 'work',
                'unit': 'шт',
                'default_price': 8.00,
                'default_currency': 'USD'
            }
        )

        # 6. Create Material Item: "RCD 2P"
        # Logic usage: shield_{device_type}_{poles} -> shield_rcd_2P
        mat_rcd_2p, created_rcd = CatalogItem.objects.get_or_create(
            mapping_key="shield_rcd_2P",
            defaults={
                'name': "УЗО 2P (Diff)",
                'category': cat_mat,
                'item_type': 'material',
                'unit': 'шт',
                'default_price': 25.00,
                'default_currency': 'USD',
                'related_work_item': work_mount_rcd
            }
        )
        if not created_rcd:
            mat_rcd_2p.related_work_item = work_mount_rcd
            mat_rcd_2p.save()
        if not created_rcd:
            mat_rcd_2p.related_work_item = work_mount_rcd
            mat_rcd_2p.save()
            
        # 7. Create Material Item: "Shield 18 modules"
        mat_shield_18, created_sh18 = CatalogItem.objects.get_or_create(
            mapping_key="shield_enclosure_18",
            defaults={
                'name': "Щит встраиваемый 18 модулей (Hager)",
                'category': cat_mat,
                'item_type': 'material',
                'unit': 'шт',
                'default_price': 35.00,
                'default_currency': 'USD',
                'related_work_item': work_mount_shield
            }
        )
        if not created_sh18:
            mat_shield_18.related_work_item = work_mount_shield
            mat_shield_18.save()

        # 8. Create Large Group to force > 12 modules logic (Test for 18)
        # We add to the SAME shield "ГРЩ Тест"
        # Existing modules: 1+1+2 = 4. 
        # We need 14 total. So we need +10 modules.
        shield = Shield.objects.filter(name='ГРЩ Тест').first()
        if shield:
            ShieldGroup.objects.create(
                shield=shield,
                device_type='relay', # Just a placeholder type
                rating='Unknown',
                poles='4P',
                zone='Big Test Device',
                modules_count=10
            )
             
        self.stdout.write(f"Catalog Items created: {mat_breaker} -> {work_breaker}")

        # 5. Create Test Project
        project, _ = Project.objects.get_or_create(
            address="Тест Автоматизации",
            defaults={'client_info': "Auto Tester"}
        )
        
        # 6. Create Stage
        stage, _ = Stage.objects.get_or_create(
            project=project,
            title='stage_1',
            defaults={'status': 'plan'}
        )
        
        # 7. Create Power Shield
        shield, _ = Shield.objects.get_or_create(
            project=project,
            shield_type='power',
            defaults={'name': 'ГРЩ Тест'}
        )
        
        # 8. Create Shield Group (Circuit Breaker 16A 1P) -> Should match our key
        # We need 2 of them to test aggregation
        ShieldGroup.objects.create(
            shield=shield,
            device_type='circuit_breaker',
            rating='16A',
            poles='1P',
            zone='Свет кухня',
            modules_count=1
        )
        ShieldGroup.objects.create(
            shield=shield,
            device_type='circuit_breaker',
            rating='16A',
            poles='1P',
            zone='Свет спальня',
            modules_count=1
        )
        
        # 9. Create RCD (Diff) - for which we didn't create catalog item, to test skip/fallback
        ShieldGroup.objects.create(
            shield=shield,
            device_type='rcd',
            rating='40A',
            poles='2P',
            zone='Ввод',
            modules_count=2
        )
        
        self.stdout.write("Created Project with Shield Groups.")
        self.stdout.write(f"Project ID: {project.id}, Stage ID: {stage.id}")
        self.stdout.write("You can now open the app, go to this project, and test Import.")
