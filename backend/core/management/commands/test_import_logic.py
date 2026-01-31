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
