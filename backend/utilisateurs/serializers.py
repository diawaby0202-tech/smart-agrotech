from django.conf import settings
from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

from .models import RoleUtilisateur, StatutCompte, Utilisateur


class InscriptionSerializer(serializers.ModelSerializer):
    """Création d'un compte (RF-01)."""

    password = serializers.CharField(write_only=True, min_length=8, style={'input_type': 'password'})
    role = serializers.ChoiceField(
        choices=[RoleUtilisateur.PRODUCTEUR, RoleUtilisateur.ACHETEUR],
        default=RoleUtilisateur.PRODUCTEUR,
    )

    class Meta:
        model = Utilisateur
        fields = ['id', 'email', 'nom', 'prenom', 'telephone', 'role', 'password']

    def validate_password(self, value):
        validate_password(value)
        return value

    def create(self, validated_data):
        # Si la validation par l'administrateur est activée (RF-03),
        # le compte reste en attente jusqu'à sa validation.
        if getattr(settings, 'VALIDATION_INSCRIPTION_REQUISE', False):
            validated_data['statut'] = StatutCompte.EN_ATTENTE
        return Utilisateur.objects.create_user(**validated_data)


class ProfilSerializer(serializers.ModelSerializer):
    """Lecture et modification de son propre profil (RF-05)."""

    class Meta:
        model = Utilisateur
        fields = ['id', 'email', 'nom', 'prenom', 'telephone', 'role', 'statut', 'date_inscription']
        read_only_fields = ['id', 'role', 'statut', 'date_inscription']


class AdminUtilisateurSerializer(serializers.ModelSerializer):
    """Gestion des comptes par l'administrateur (RF-03, RF-20, RF-21)."""

    class Meta:
        model = Utilisateur
        fields = ['id', 'email', 'nom', 'prenom', 'telephone', 'role', 'statut', 'date_inscription']
        read_only_fields = ['id', 'date_inscription']


class ConnexionSerializer(TokenObtainPairSerializer):
    default_error_messages = {
        'no_active_account': 'Email ou mot de passe incorrect, ou compte non validé.',
    }
