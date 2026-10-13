from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.db import models


class RoleUtilisateur(models.TextChoices):
    PRODUCTEUR = 'producteur', 'Agriculteur / Éleveur'
    ACHETEUR = 'acheteur', 'Acheteur'
    ADMIN = 'admin', 'Administrateur'


class StatutCompte(models.TextChoices):
    EN_ATTENTE = 'en_attente', 'En attente de validation'
    VALIDE = 'valide', 'Validé'
    REFUSE = 'refuse', 'Refusé'
    SUSPENDU = 'suspendu', 'Suspendu'


class UtilisateurManager(BaseUserManager):
    use_in_migrations = True

    def _create_user(self, email, password, **extra_fields):
        if not email:
            raise ValueError("L'email est obligatoire")
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_user(self, email, password=None, **extra_fields):
        extra_fields.setdefault('role', RoleUtilisateur.PRODUCTEUR)
        return self._create_user(email, password, **extra_fields)

    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('role', RoleUtilisateur.ADMIN)
        extra_fields.setdefault('statut', StatutCompte.VALIDE)
        return self._create_user(email, password, **extra_fields)


class Utilisateur(AbstractBaseUser, PermissionsMixin):
    email = models.EmailField(unique=True)
    nom = models.CharField(max_length=100)
    prenom = models.CharField(max_length=100)
    telephone = models.CharField(max_length=20, blank=True)
    role = models.CharField(
        max_length=20, choices=RoleUtilisateur.choices, default=RoleUtilisateur.PRODUCTEUR
    )
    statut = models.CharField(
        max_length=20, choices=StatutCompte.choices, default=StatutCompte.VALIDE
    )
    is_staff = models.BooleanField(default=False)
    date_inscription = models.DateTimeField(auto_now_add=True)

    objects = UtilisateurManager()

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['nom', 'prenom']

    class Meta:
        ordering = ['-date_inscription']

    @property
    def is_active(self):
        # Seuls les comptes validés peuvent se connecter.
        return self.statut == StatutCompte.VALIDE

    def __str__(self):
        return f'{self.prenom} {self.nom} ({self.email})'
