from rest_framework import serializers

from .models import Parcelle


class ParcelleSerializer(serializers.ModelSerializer):
    class Meta:
        model = Parcelle
        fields = [
            'id', 'nom', 'culture', 'superficie', 'localisation', 'date_semis',
            'date_recolte_prevue', 'statut', 'notes', 'date_creation',
        ]
        read_only_fields = ['id', 'date_creation']

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
