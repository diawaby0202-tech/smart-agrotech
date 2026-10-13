from rest_framework import serializers

from .models import Annonce


class AnnonceSerializer(serializers.ModelSerializer):
    vendeur_nom = serializers.SerializerMethodField()
    vendeur_telephone = serializers.CharField(source='vendeur.telephone', read_only=True)
    est_proprietaire = serializers.SerializerMethodField()

    class Meta:
        model = Annonce
        fields = [
            'id', 'titre', 'description', 'categorie', 'prix', 'quantite', 'zone',
            'photo', 'statut', 'moderation', 'vendeur_nom', 'vendeur_telephone',
            'est_proprietaire', 'date_creation',
        ]
        read_only_fields = ['id', 'moderation', 'date_creation']

    def get_vendeur_nom(self, obj):
        return f'{obj.vendeur.prenom} {obj.vendeur.nom}'.strip()

    def get_est_proprietaire(self, obj):
        request = self.context.get('request')
        return bool(request and obj.vendeur_id == request.user.id)

    def validate_prix(self, value):
        if value < 0:
            raise serializers.ValidationError('Le prix ne peut pas être négatif.')
        return value
