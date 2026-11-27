from django.conf import settings
from django.db import models
from django.utils import timezone


class StatutParcelle(models.TextChoices):
    PREPARATION = 'preparation', 'En préparation'
    SEMEE = 'semee', 'Semée'
    CROISSANCE = 'croissance', 'En croissance'
    RECOLTEE = 'recoltee', 'Récoltée'


class Parcelle(models.Model):
    proprietaire = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='parcelles'
    )
    nom = models.CharField(max_length=100)
    culture = models.CharField(max_length=100)
    superficie = models.DecimalField(max_digits=8, decimal_places=2, help_text='En hectares')
    prix_indicatif = models.PositiveIntegerField(
        null=True, blank=True, help_text='En FCFA par kilogramme'
    )
    localisation = models.CharField(max_length=150, blank=True)
    date_semis = models.DateField(null=True, blank=True)
    date_recolte_prevue = models.DateField(null=True, blank=True)
    statut = models.CharField(
        max_length=20, choices=StatutParcelle.choices, default=StatutParcelle.PREPARATION
    )
    notes = models.TextField(blank=True)
    image = models.ImageField(upload_to='parcelles/', blank=True, null=True)
    date_creation = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-date_creation']

    def __str__(self):
        return f'{self.nom} ({self.culture})'


class UniteRecolte(models.TextChoices):
    KILOGRAMME = 'kg', 'Kilogrammes'
    TONNE = 'tonne', 'Tonnes'
    SAC = 'sac', 'Sacs'
    CAISSE = 'caisse', 'Caisses'


class Recolte(models.Model):
    parcelle = models.ForeignKey(
        Parcelle, on_delete=models.CASCADE, related_name='recoltes'
    )
    date = models.DateField(default=timezone.localdate)
    quantite = models.DecimalField(max_digits=12, decimal_places=2)
    unite = models.CharField(
        max_length=10, choices=UniteRecolte.choices, default=UniteRecolte.KILOGRAMME
    )
    notes = models.TextField(blank=True)
    date_creation = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-date', '-id']

    def __str__(self):
        return f'{self.parcelle.nom} — {self.quantite} {self.unite}'
