from datetime import timedelta

from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand, CommandError
from django.db import transaction
from django.utils import timezone

from elevage.models import Animal, SuiviSanitaire, TypeSuivi

from cultures.models import Parcelle, StatutParcelle


class Command(BaseCommand):
    help = (
        "Ajoute des parcelles et animaux d'exemple au compte indiqué. "
        "Les fiches existantes ne sont pas modifiées."
    )

    def add_arguments(self, parser):
        parser.add_argument(
            "--email",
            required=True,
            help="Adresse e-mail du compte qui recevra les fiches d'exemple.",
        )

    @transaction.atomic
    def handle(self, *args, **options):
        email = options["email"].strip()
        try:
            user = get_user_model().objects.get(email__iexact=email)
        except get_user_model().DoesNotExist as error:
            raise CommandError(f"Aucun compte trouvé pour {email}.") from error

        today = timezone.localdate()
        parcelles = (
            {
                "nom": "Exemple — Champ d'arachide à Thiès",
                "culture": "Arachide",
                "superficie": "2.50",
                "localisation": "Thiès",
                "date_semis": today - timedelta(days=65),
                "date_recolte_prevue": today + timedelta(days=35),
                "statut": StatutParcelle.CROISSANCE,
                "notes": "Fiche d'exemple à adapter à votre exploitation.",
            },
            {
                "nom": "Exemple — Champ de mil à Kaolack",
                "culture": "Mil",
                "superficie": "1.80",
                "localisation": "Kaolack",
                "date_semis": today - timedelta(days=40),
                "date_recolte_prevue": today + timedelta(days=55),
                "statut": StatutParcelle.SEMEE,
                "notes": "Fiche d'exemple à adapter à votre exploitation.",
            },
            {
                "nom": "Exemple — Parcelle de maïs à Saint-Louis",
                "culture": "Maïs",
                "superficie": "1.20",
                "localisation": "Saint-Louis",
                "date_semis": today - timedelta(days=20),
                "date_recolte_prevue": today + timedelta(days=75),
                "statut": StatutParcelle.CROISSANCE,
                "notes": "Fiche d'exemple à adapter à votre exploitation.",
            },
        )
        animaux = (
            {
                "espece": "Vache",
                "race": "Gobra",
                "identifiant": "EXEMPLE-BOVIN-0142",
                "effectif": 1,
                "date_naissance": today - timedelta(days=365 * 4),
                "notes": "Fiche d'exemple à adapter à votre élevage.",
            },
            {
                "espece": "Mouton",
                "race": "Ladoum",
                "identifiant": "EXEMPLE-LOT-OVIN",
                "effectif": 12,
                "notes": "Fiche d'exemple à adapter à votre élevage.",
            },
            {
                "espece": "Chèvre",
                "race": "Chèvre du Sahel",
                "identifiant": "EXEMPLE-LOT-CAPRIN",
                "effectif": 6,
                "notes": "Fiche d'exemple à adapter à votre élevage.",
            },
        )

        parcelles_creees = 0
        animaux_crees = 0
        for parcelle in parcelles:
            _, created = Parcelle.objects.get_or_create(
                proprietaire=user,
                nom=parcelle["nom"],
                defaults=parcelle,
            )
            parcelles_creees += created

        animaux_par_identifiant = {}
        for animal_data in animaux:
            animal, created = Animal.objects.get_or_create(
                proprietaire=user,
                identifiant=animal_data["identifiant"],
                defaults=animal_data,
            )
            animaux_crees += created
            animaux_par_identifiant[animal_data["identifiant"]] = animal

        suivis = (
            (
                "EXEMPLE-BOVIN-0142",
                TypeSuivi.VACCINATION,
                today - timedelta(days=7),
                "Exemple de vaccination préventive.",
                today + timedelta(days=23),
            ),
            (
                "EXEMPLE-LOT-OVIN",
                TypeSuivi.TRAITEMENT,
                today - timedelta(days=14),
                "Exemple de suivi antiparasitaire.",
                today + timedelta(days=16),
            ),
        )
        suivis_crees = 0
        for identifiant, type_suivi, date_suivi, description, echeance in suivis:
            _, created = SuiviSanitaire.objects.get_or_create(
                animal=animaux_par_identifiant[identifiant],
                type=type_suivi,
                description=description,
                defaults={
                    "date": date_suivi,
                    "description": description,
                    "prochaine_echeance": echeance,
                },
            )
            suivis_crees += created

        self.stdout.write(
            self.style.SUCCESS(
                f"Exemples pour {user.email} : "
                f"{parcelles_creees} parcelle(s), {animaux_crees} animal/animaux "
                f"et {suivis_crees} suivi(s) ajouté(s)."
            )
        )
