from rest_framework import serializers

from .models import Alerte


class AlerteSerializer(serializers.ModelSerializer):
    class Meta:
        model = Alerte
        fields = ['id', 'type', 'niveau', 'titre', 'message', 'zone', 'lue', 'date_creation']
        read_only_fields = fields
