from django.core.management.base import BaseCommand
from core.models import Project, Stage, EstimateItem
from django.utils import timezone
import random
from datetime import datetime, timedelta

class Command(BaseCommand):
    help = 'Generates test data for statistics (Work Dynamics)'

    def handle(self, *args, **options):
        self.stdout.write("Generating test data...")

        # 1. Ensure a test project exists
        project, created = Project.objects.get_or_create(
            address="Test Statistics Address", # Changed from title to address
            defaults={
                'source': 'Instagram',
                'object_type': 'new_building', # Valid choice
                'client_info': 'Test Client Info',
                'notes': 'Generated for stats testing'
            }
        )
        
        if created:
             self.stdout.write(f"Created project: {project.address}")
        
        # Base Dates for 2026, 2025, 2024
        
        # 2024
        self.create_stage_with_items(project, datetime(2024, 1, 10, 10, 0), 1000, 0)
        self.create_stage_with_items(project, datetime(2024, 5, 20, 10, 0), 1500, 200)
        self.create_stage_with_items(project, datetime(2024, 9, 15, 10, 0), 2000, 0)

        # 2025
        self.create_stage_with_items(project, datetime(2025, 3, 10, 10, 0), 1200, 0)
        self.create_stage_with_items(project, datetime(2025, 6, 20, 10, 0), 1800, 100)
        self.create_stage_with_items(project, datetime(2025, 11, 15, 10, 0), 500, 0)

        # 2026 (Detailed)
        # Jan
        self.create_stage_with_items(project, datetime(2026, 1, 15, 10, 0), 500, 100)
        self.create_stage_with_items(project, datetime(2026, 1, 20, 10, 0), 1200, 0)
        
        # Feb (Daily)
        self.create_stage_with_items(project, datetime(2026, 2, 1, 10, 0), 300, 50)
        self.create_stage_with_items(project, datetime(2026, 2, 3, 14, 0), 450, 0)
        self.create_stage_with_items(project, datetime(2026, 2, 5, 11, 0), 800, 200)
        self.create_stage_with_items(project, datetime(2026, 2, 7, 16, 0), 150, 0)
        self.create_stage_with_items(project, datetime(2026, 2, 8, 0, 0), 600, 100)

        # March-Dec 2026 (Future/Predicted or just spread)
        self.create_stage_with_items(project, datetime(2026, 3, 10, 10, 0), 1100, 0)
        self.create_stage_with_items(project, datetime(2026, 4, 15, 10, 0), 900, 0)
        self.create_stage_with_items(project, datetime(2026, 5, 20, 10, 0), 2200, 0)
        self.create_stage_with_items(project, datetime(2026, 8, 12, 10, 0), 1300, 0)
        self.create_stage_with_items(project, datetime(2026, 10, 5, 10, 0), 1750, 0)
        self.create_stage_with_items(project, datetime(2026, 12, 25, 10, 0), 3000, 500)
        
        self.stdout.write(self.style.SUCCESS("Successfully generated test data."))

    def create_stage_with_items(self, project, date, usd_amount, byn_amount):
        # Make timezone aware
        date_aware = timezone.make_aware(date)
        
        stage = Stage.objects.create(
            project=project,
            title='other', # Valid choice
            status='completed',
            is_paid=True,
            # created_at/updated_at are auto fields
        )
        
        # Manually update created_at to simulate past dates
        Stage.objects.filter(pk=stage.pk).update(
            created_at=date_aware,
            updated_at=date_aware
        )
        
        # Add USD Item
        if usd_amount > 0:
            EstimateItem.objects.create(
                stage=stage,
                name="Work USD",
                unit="шт",
                total_quantity=1,
                price_per_unit=usd_amount,
                currency='USD'
            )
            
        # Add BYN Item
        if byn_amount > 0:
            EstimateItem.objects.create(
                stage=stage,
                name="Work BYN",
                unit="шт",
                total_quantity=1,
                price_per_unit=byn_amount,
                currency='BYN'
            )
            
        self.stdout.write(f"Created stage for {date.strftime('%Y-%m-%d')} with {usd_amount} USD")
