from django.conf import settings
from django.db import models


class Animal(models.Model):
    proprietaire = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='animaux'
    )
    espece = models.CharField(max_length=50)
    race = models.CharField(max_length=100, blank=True)
    identifiant = models.CharField(max_length=50, blank=True, help_text='Numéro de boucle ou nom du lot')
    effectif = models.PositiveIntegerField(default=1, help_text='1 = animal seul, >1 = lot')
    date_naissance = models.DateField(null=True, blank=True)
    notes = models.TextField(blank=True)
    image = models.ImageField(upload_to='animaux/', blank=True, null=True)
    date_creation = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-date_creation']

    def __str__(self):
        return f'{self.espece} {self.identifiant}'.strip()


class TypeSuivi(models.TextChoices):
    VACCINATION = 'vaccination', 'Vaccination'
    TRAITEMENT = 'traitement', 'Traitement'
    VISITE = 'visite', 'Visite vétérinaire'


class SuiviSanitaire(models.Model):
    animal = models.ForeignKey(Animal, on_delete=models.CASCADE, related_name='suivis')
    type = models.CharField(max_length=20, choices=TypeSuivi.choices)
    date = models.DateField()
    description = models.TextField(blank=True)
    prochaine_echeance = models.DateField(null=True, blank=True)

    class Meta:
        ordering = ['-date']

    def __str__(self):
        return f'{self.type} - {self.animal}'


class SuiviReproduction(models.Model):
    animal = models.ForeignKey(
        Animal, on_delete=models.CASCADE, related_name='suivis_reproduction'
    )
    date_saillie = models.DateField(null=True, blank=True)
    mise_bas_prevue = models.DateField(null=True, blank=True)
    mise_bas_reelle = models.DateField(null=True, blank=True)
    nombre_petits = models.PositiveIntegerField(null=True, blank=True)
    notes = models.TextField(blank=True)
    date_creation = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-date_saillie', '-id']

    def __str__(self):
        return f'Reproduction — {self.animal}'
