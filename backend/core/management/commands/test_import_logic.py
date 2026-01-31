from django.core.management.base import BaseCommand
from core.models import Project, Stage
from core.services import EstimateAutomationService

class Command(BaseCommand):
    help = 'Runs import logic to test debugging'

    def handle(self, *args, **options):
        # Find our test project
        project = Project.objects.filter(client_info="Auto Tester").last()
        if not project:
            self.stdout.write("Test Project not found!")
            return
            
        stage = Stage.objects.filter(project=project, title='stage_1').first()
        if not stage:
            self.stdout.write("Test Stage not found!")
            return

        self.stdout.write(f"Running Import for Project {project.id}, Stage {stage.id}...")
        result = EstimateAutomationService.import_shield_to_materials(project.id, stage.id)
        self.stdout.write(f"Result: {result}")
        
        from core.models import EstimateItem, Shield
        
        # Debug Shields
        shields = Shield.objects.filter(project=project, shield_type='power')
        for s in shields:
             mods = sum(g.modules_count for g in s.groups.all())
             self.stdout.write(f"Shield '{s.name}': {mods} modules")

        items = EstimateItem.objects.filter(stage=stage, item_type='material')
        for item in items:
             self.stdout.write(f"- {item.name}: {item.total_quantity} {item.unit}")
             
        # Check specifically for warning
        warn = items.filter(name__startswith="ВНИМАНИЕ: Индивидуальный").first()
        if warn:
             self.stdout.write(f"SUCCESS: Found Warning Item: {warn.name}")
        else:
             self.stdout.write("FAILURE: Warning Item NOT FOUND")
