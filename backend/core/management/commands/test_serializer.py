from django.core.management.base import BaseCommand
from core.models import Shield
from core.serializers import ShieldSerializer

class Command(BaseCommand):
    help = 'Tests ShieldSerializer suggestion logic'

    def handle(self, *args, **options):
        # 1. Get Empty Shield
        empty = Shield.objects.filter(name='Empty Shield').first()
        if empty:
            s_empty = ShieldSerializer(empty)
            self.stdout.write(f"Empty Shield Suggestion: {s_empty.data.get('suggested_size')}")
        else:
            self.stdout.write("Empty Shield not found!")

        # 2. Get Main Shield (should be normal)
        main = Shield.objects.filter(name='Main Shield').first()
        if main:
            s_main = ShieldSerializer(main)
            self.stdout.write(f"Main Shield Suggestion: {s_main.data.get('suggested_size')}")

        # 3. Get Mega Shield
        mega = Shield.objects.filter(name='Mega Shield').first()
        if mega:
            s_mega = ShieldSerializer(mega)
            self.stdout.write(f"Mega Shield Suggestion: {s_mega.data.get('suggested_size')}")
