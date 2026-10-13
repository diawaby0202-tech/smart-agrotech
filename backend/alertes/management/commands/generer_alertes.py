from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand

from alertes.services import generer_alertes


class Command(BaseCommand):
    help = "Génère les alertes météo et vaccination pour tous les utilisateurs validés."

    def handle(self, *args, **options):
        total = 0
        for user in get_user_model().objects.filter(statut='valide'):
            total += generer_alertes(user)
        self.stdout.write(self.style.SUCCESS(f'{total} alerte(s) créée(s).'))
