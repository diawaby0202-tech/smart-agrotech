from django.conf import settings
from django.db import models


class TypeAlerte(models.TextChoices):
    METEO = 'meteo', 'Météo'
    VACCINATION = 'vaccination', 'Vaccination'
    CULTURE = 'culture', 'Culture'
    SYSTEME = 'systeme', 'Système'


class NiveauAlerte(models.TextChoices):
    INFO = 'info', 'Information'
    ATTENTION = 'attention', 'Attention'
    DANGER = 'danger', 'Danger'


class Alerte(models.Model):
    utilisateur = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='alertes'
    )
    type = models.CharField(max_length=20, choices=TypeAlerte.choices, default=TypeAlerte.SYSTEME)
    niveau = models.CharField(max_length=20, choices=NiveauAlerte.choices, default=NiveauAlerte.INFO)
    titre = models.CharField(max_length=150)
    message = models.TextField()
    zone = models.CharField(max_length=100, blank=True)
    lue = models.BooleanField(default=False)
    date_creation = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-date_creation']

    def __str__(self):
        return f'[{self.niveau}] {self.titre}'
