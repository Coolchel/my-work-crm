import os
import django
from django.conf import settings

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from core.models import Project, LedZone
from core.serializers import ProjectSerializer

def run():
    print("Creating verification project...")
    p = Project.objects.create(address="Test High-Tech", object_type="office")
    
    print(f"Checking default values:")
    print(f"Internet Lines: {p.internet_lines_count} (Expected 0)")
    print(f"Multimedia Notes: '{p.multimedia_notes}' (Expected '')")
    print(f"Suggested Shield: '{p.suggested_internet_shield}' (Expected '')")
    
    # Check 1 zone
    LedZone.objects.create(project=p, transformer="T1", zone="Z1")
    s = ProjectSerializer(p).data
    print(f"1 Zone -> Shield Size: {s['led_shield_size']} (Expected '24 модуля')")
    
    # Check 5 zones (add 4 more)
    for i in range(4):
        LedZone.objects.create(project=p, transformer=f"T{i+2}", zone=f"Z{i+2}")
    s = ProjectSerializer(p).data
    print(f"5 Zones -> Shield Size: {s['led_shield_size']} (Expected '36 модулей')")
    
    # Check 9 zones (add 4 more)
    for i in range(4):
        LedZone.objects.create(project=p, transformer=f"T{i+6}", zone=f"Z{i+6}")
    s = ProjectSerializer(p).data
    print(f"9 Zones -> Shield Size: {s['led_shield_size']} (Expected '48 модулей')")

    # Check 13 zones (add 4 more)
    for i in range(4):
        LedZone.objects.create(project=p, transformer=f"T{i+10}", zone=f"Z{i+10}")
    s = ProjectSerializer(p).data
    print(f"13 Zones -> Shield Size: {s['led_shield_size']} (Expected '60 модулей')")

    # Check 18 zones (add 5 more)
    for i in range(5):
        LedZone.objects.create(project=p, transformer=f"T{i+14}", zone=f"Z{i+14}")
    s = ProjectSerializer(p).data
    print(f"18 Zones -> Shield Size: {s['led_shield_size']} (Expected 'Требуется инд. расчет')")

    print("\nCleaning up...")
    p.delete()
    print("Done.")

if __name__ == '__main__':
    run()
