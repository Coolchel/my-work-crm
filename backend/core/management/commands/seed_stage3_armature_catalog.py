from django.core.management.base import BaseCommand

from core.models import CatalogCategory, CatalogItem


class Command(BaseCommand):
    help = 'Seed stage 3 armature material catalog items with mapping keys'

    TARGET_ITEMS = [
        ('вкл 1кл', 'arm_switch_1g'),
        ('вкл 2кл', 'arm_switch_2g'),
        ('вкл 1кл проходной', 'arm_switch_1g_pass'),
        ('вкл 2кл проходной', 'arm_switch_2g_pass'),
        ('вкл 1кл перекрестный', 'arm_switch_1g_cross'),
        ('вкл 2кл перекрестный', 'arm_switch_2g_cross'),
        ('розетка', 'arm_socket'),
        ('розетка с влагозащитой', 'arm_socket_ip'),
        ('розетка LANx1', 'arm_socket_lan_1'),
        ('розетка LANx2', 'arm_socket_lan_2'),
        ('розетка TV', 'arm_socket_tv'),
        ('розетка TEL', 'arm_socket_tel'),
        ('вывод кабеля', 'arm_cable_output'),
        ('рамка 1х', 'arm_frame_1x'),
        ('рамка 2х', 'arm_frame_2x'),
        ('рамка 3х', 'arm_frame_3x'),
        ('рамка 4х', 'arm_frame_4x'),
        ('рамка 5х', 'arm_frame_5x'),
    ]

    def handle(self, *args, **kwargs):
        category, _ = CatalogCategory.objects.get_or_create(
            slug='stage-3-armature',
            defaults={
                'name': 'Арматура (Этап 3)',
                'labor_coefficient': 1.0,
            },
        )

        if category.name != 'Арматура (Этап 3)':
            category.name = 'Арматура (Этап 3)'
            category.save(update_fields=['name'])

        created_count = 0
        updated_count = 0

        for name, mapping_key in self.TARGET_ITEMS:
            item = CatalogItem.objects.filter(
                item_type='material',
                mapping_key=mapping_key,
            ).first()

            if item is None:
                item = CatalogItem.objects.filter(
                    item_type='material',
                    name=name,
                ).first()

            if item is None:
                CatalogItem.objects.create(
                    category=category,
                    name=name,
                    unit='шт',
                    default_price=0,
                    default_currency='USD',
                    item_type='material',
                    mapping_key=mapping_key,
                )
                created_count += 1
                continue

            changed = False
            if item.category_id != category.id:
                item.category = category
                changed = True
            if item.unit != 'шт':
                item.unit = 'шт'
                changed = True
            if item.item_type != 'material':
                item.item_type = 'material'
                changed = True
            if item.mapping_key != mapping_key:
                item.mapping_key = mapping_key
                changed = True

            if changed:
                item.save(
                    update_fields=[
                        'category',
                        'unit',
                        'item_type',
                        'mapping_key',
                    ],
                )
                updated_count += 1

        self.stdout.write(
            self.style.SUCCESS(
                f'Stage 3 armature catalog seeded: created={created_count}, updated={updated_count}',
            ),
        )
