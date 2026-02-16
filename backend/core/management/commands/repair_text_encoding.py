from django.core.management.base import BaseCommand

from core.models import CatalogCategory, CatalogItem, DirectoryEntry, DirectorySection
from core.text_normalizer import normalize_possible_mojibake


class Command(BaseCommand):
    help = "Repairs mojibake in directory/catalog text fields."

    def add_arguments(self, parser):
        parser.add_argument(
            "--dry-run",
            action="store_true",
            help="Show what would be changed without saving.",
        )

    def handle(self, *args, **options):
        dry_run = options["dry_run"]

        updates = 0
        updates += self._repair_model(
            model=DirectorySection,
            fields=("name", "description"),
            dry_run=dry_run,
        )
        updates += self._repair_model(
            model=DirectoryEntry,
            fields=("name",),
            dry_run=dry_run,
        )
        updates += self._repair_model(
            model=CatalogCategory,
            fields=("name",),
            dry_run=dry_run,
        )
        updates += self._repair_model(
            model=CatalogItem,
            fields=("name", "unit"),
            dry_run=dry_run,
        )

        if dry_run:
            self.stdout.write(self.style.WARNING(f"Dry run complete. Changes found: {updates}"))
        else:
            self.stdout.write(self.style.SUCCESS(f"Repair complete. Updated fields: {updates}"))

    def _repair_model(self, model, fields: tuple[str, ...], dry_run: bool) -> int:
        updates_count = 0
        model_name = model.__name__

        for instance in model.objects.all():
            changed_fields = []

            for field_name in fields:
                original_value = getattr(instance, field_name, None)
                if not isinstance(original_value, str):
                    continue

                normalized_value = normalize_possible_mojibake(original_value)
                if normalized_value != original_value:
                    setattr(instance, field_name, normalized_value)
                    changed_fields.append(field_name)

            if changed_fields:
                updates_count += len(changed_fields)
                if dry_run:
                    self.stdout.write(
                        f"[DRY] {model_name}#{instance.pk}: {', '.join(changed_fields)}"
                    )
                else:
                    instance.save(update_fields=changed_fields)
                    self.stdout.write(
                        f"[OK] {model_name}#{instance.pk}: {', '.join(changed_fields)}"
                    )

        return updates_count
