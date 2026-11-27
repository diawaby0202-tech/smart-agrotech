from rest_framework import serializers

from .models import (
    Annonce,
    Commande,
    MoyenPaiement,
    StatutAnnonce,
    StatutCommande,
)


class AnnonceSerializer(serializers.ModelSerializer):
    vendeur_nom = serializers.SerializerMethodField()
    vendeur_telephone = serializers.CharField(source='vendeur.telephone', read_only=True)
    est_proprietaire = serializers.SerializerMethodField()

    class Meta:
        model = Annonce
        fields = [
            'id', 'titre', 'description', 'categorie', 'prix', 'quantite', 'zone',
            'stock', 'unite', 'photo', 'image', 'statut', 'moderation',
            'vendeur_nom', 'vendeur_telephone', 'est_proprietaire', 'date_creation',
        ]
        read_only_fields = ['id', 'moderation', 'date_creation']

    def validate(self, data):
        stock = data.get('stock', getattr(self.instance, 'stock', None))
        unite = data.get('unite', getattr(self.instance, 'unite', ''))
        if (stock is None) != (not unite):
            raise serializers.ValidationError(
                'Le stock et son unité doivent être renseignés ensemble.'
            )
        if stock is not None and stock <= 0:
            raise serializers.ValidationError(
                {'stock': 'Le stock doit être supérieur à zéro.'}
            )
        return data

    def get_vendeur_nom(self, obj):
        return f'{obj.vendeur.prenom} {obj.vendeur.nom}'.strip()

    def get_est_proprietaire(self, obj):
        request = self.context.get('request')
        return bool(request and obj.vendeur_id == request.user.id)

    def validate_image(self, value):
        if value and value.size > 5 * 1024 * 1024:
            raise serializers.ValidationError("L'image ne doit pas dépasser 5 Mo.")
        return value

    def validate_prix(self, value):
        if value < 0:
            raise serializers.ValidationError('Le prix ne peut pas être négatif.')
        return value


class CommandeSerializer(serializers.ModelSerializer):
    acheteur_nom = serializers.SerializerMethodField()
    vendeur_nom = serializers.SerializerMethodField()

    class Meta:
        model = Commande
        fields = [
            'id', 'annonce', 'annonce_titre', 'annonce_unite', 'acheteur_nom',
            'vendeur_nom', 'quantite', 'prix_unitaire', 'total', 'moyen_paiement',
            'telephone_paiement', 'statut', 'date_expiration', 'date_creation',
        ]
        read_only_fields = [
            'id', 'annonce_titre', 'annonce_unite', 'acheteur_nom', 'vendeur_nom',
            'prix_unitaire', 'total', 'telephone_paiement', 'statut',
            'date_expiration', 'date_creation',
        ]

    def get_acheteur_nom(self, obj):
        return f'{obj.acheteur.prenom} {obj.acheteur.nom}'.strip()

    def get_vendeur_nom(self, obj):
        return f'{obj.annonce.vendeur.prenom} {obj.annonce.vendeur.nom}'.strip()

    def validate(self, data):
        annonce = data.get('annonce')
        request = self.context['request']
        if annonce is None:
            return data
        if annonce.vendeur_id == request.user.id:
            raise serializers.ValidationError(
                {'annonce': 'Vous ne pouvez pas commander votre propre annonce.'}
            )
        if annonce.statut != StatutAnnonce.DISPONIBLE:
            raise serializers.ValidationError(
                {'annonce': 'Cette annonce n’est plus disponible.'}
            )
        if annonce.stock is None or not annonce.unite:
            raise serializers.ValidationError(
                {'annonce': 'Le vendeur doit compléter le stock et son unité.'}
            )
        return data

    def validate_quantite(self, value):
        if value <= 0:
            raise serializers.ValidationError('La quantité doit être positive.')
        return value

    def validate_moyen_paiement(self, value):
        if value not in MoyenPaiement.values:
            raise serializers.ValidationError('Moyen de paiement non pris en charge.')
        return value

    def create(self, validated_data):
        from datetime import timedelta
        from decimal import Decimal

        from django.db import transaction
        from django.db.models import Sum
        from django.utils import timezone
        from rest_framework.exceptions import ValidationError

        with transaction.atomic():
            annonce = Annonce.objects.select_for_update().select_related(
                'vendeur'
            ).get(pk=validated_data['annonce'].pk)
            now = timezone.now()
            Commande.objects.filter(
                annonce=annonce,
                statut=StatutCommande.A_PAYER,
                date_expiration__lte=now,
            ).update(statut=StatutCommande.EXPIREE)
            if annonce.statut != StatutAnnonce.DISPONIBLE:
                raise ValidationError({'annonce': 'Cette annonce n’est plus disponible.'})
            if not annonce.vendeur.telephone:
                raise ValidationError(
                    {'annonce': 'Le vendeur doit renseigner son numéro de téléphone.'}
                )
            quantite = validated_data['quantite']
            reservee = Commande.objects.filter(
                annonce=annonce,
                statut__in=[
                    StatutCommande.A_PAYER,
                    StatutCommande.PAIEMENT_SIGNALE,
                ],
            ).aggregate(total=Sum('quantite'))['total'] or Decimal('0')
            if reservee + quantite > annonce.stock:
                raise ValidationError(
                    {'quantite': 'Le stock disponible est insuffisant.'}
                )
            prix_unitaire = annonce.prix
            validated_data.update(
                acheteur=self.context['request'].user,
                annonce=annonce,
                annonce_titre=annonce.titre,
                annonce_unite=annonce.unite,
                prix_unitaire=prix_unitaire,
                total=prix_unitaire * quantite,
                telephone_paiement=annonce.vendeur.telephone,
                statut=StatutCommande.A_PAYER,
                date_expiration=now + timedelta(minutes=30),
            )
            return super().create(validated_data)
