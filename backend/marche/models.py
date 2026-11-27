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


class UniteAnnonce(models.TextChoices):
    KG = 'kg', 'kg'
    TONNE = 'tonne', 'tonne'
    SAC = 'sac', 'sac'
    CAISSE = 'caisse', 'caisse'
    TETE = 'tete', 'tête'
    PIECE = 'piece', 'pièce'


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
    stock = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    unite = models.CharField(max_length=10, choices=UniteAnnonce.choices, blank=True)
    zone = models.CharField(max_length=100, blank=True)
    photo = models.URLField(blank=True, help_text='Lien externe (optionnel)')
    image = models.ImageField(upload_to='annonces/', blank=True, null=True)
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


class StatutCommande(models.TextChoices):
    A_PAYER = 'a_payer', 'À payer'
    PAIEMENT_SIGNALE = 'paiement_signale', 'Paiement signalé'
    CONFIRMEE = 'confirmee', 'Confirmée'
    EXPIREE = 'expiree', 'Expirée'
    REFUSEE = 'refusee', 'Refusée'


class MoyenPaiement(models.TextChoices):
    WAVE = 'wave', 'Wave'
    ORANGE_MONEY = 'orange_money', 'Orange Money'


class Commande(models.Model):
    acheteur = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='commandes'
    )
    annonce = models.ForeignKey(
        Annonce, on_delete=models.PROTECT, related_name='commandes'
    )
    annonce_titre = models.CharField(max_length=150, blank=True, default='')
    annonce_unite = models.CharField(max_length=10, blank=True, default='')
    quantite = models.DecimalField(max_digits=12, decimal_places=2)
    prix_unitaire = models.DecimalField(max_digits=12, decimal_places=0)
    total = models.DecimalField(max_digits=14, decimal_places=0)
    moyen_paiement = models.CharField(max_length=20, choices=MoyenPaiement.choices)
    telephone_paiement = models.CharField(max_length=20)
    statut = models.CharField(
        max_length=24, choices=StatutCommande.choices, default=StatutCommande.A_PAYER
    )
    date_expiration = models.DateTimeField()
    date_creation = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-date_creation']

    def __str__(self):
        return f'Commande #{self.pk} — {self.annonce.titre}'
