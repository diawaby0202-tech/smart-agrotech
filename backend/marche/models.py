from django.conf import settings
from django.db import models


class CategorieAnnonce(models.TextChoices):
    CEREALES = 'cereales', 'Céréales'
    LEGUMES = 'legumes', 'Légumes'
    FRUITS = 'fruits', 'Fruits'
    BETAIL = 'betail', 'Bétail'
    INTRANTS = 'intrants', 'Intrants / matériel'
    AUTRE = 'autre', 'Autre'


class StatutAnnonce(models.TextChoices):
    DISPONIBLE = 'disponible', 'Disponible'
    VENDUE = 'vendue', 'Vendue'
    RETIREE = 'retiree', 'Retirée'


class Moderation(models.TextChoices):
    APPROUVEE = 'approuvee', 'Approuvée'
    SUPPRIMEE = 'supprimee', 'Supprimée par un administrateur'


class Annonce(models.Model):
    vendeur = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='annonces'
    )
    titre = models.CharField(max_length=150)
    description = models.TextField(blank=True)
    categorie = models.CharField(max_length=20, choices=CategorieAnnonce.choices)
    prix = models.DecimalField(max_digits=12, decimal_places=0, help_text='En FCFA')
    quantite = models.CharField(max_length=50, blank=True, help_text='Ex : 50 kg, 3 têtes')
    zone = models.CharField(max_length=100, blank=True)
    photo = models.URLField(blank=True)
    statut = models.CharField(
        max_length=20, choices=StatutAnnonce.choices, default=StatutAnnonce.DISPONIBLE
    )
    moderation = models.CharField(
        max_length=20, choices=Moderation.choices, default=Moderation.APPROUVEE
    )
    date_creation = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-date_creation']

    def __str__(self):
        return self.titre
