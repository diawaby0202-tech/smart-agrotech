from rest_framework import serializers

from .models import Parcelle


class ParcelleSerializer(serializers.ModelSerializer):
    class Meta:
        model = Parcelle
        fields = [
            'id', 'nom', 'culture', 'superficie', 'localisation', 'date_semis',
            'date_recolte_prevue', 'statut', 'notes', 'image', 'date_creation',
        ]
        read_only_fields = ['id', 'date_creation']

    def validate_image(self, value):
        if value.size > 5 * 1024 * 1024:
            raise serializers.ValidationError('La photo ne peut pas dépasser 5 Mo.')
        return value

    def validate(self, data):
        semis = data.get('date_semis', getattr(self.instance, 'date_semis', None))
        recolte = data.get('date_recolte_prevue', getattr(self.instance, 'date_recolte_prevue', None))
        if semis and recolte and recolte < semis:
            raise serializers.ValidationError(
                'La date de récolte doit être après la date de semis.'
            )
        return data

    def validate_superficie(self, value):
        if value <= 0:
            raise serializers.ValidationError('La superficie doit être positive.')
        return value
