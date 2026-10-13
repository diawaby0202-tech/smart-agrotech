from rest_framework import serializers

from .models import Animal, SuiviSanitaire


class AnimalSerializer(serializers.ModelSerializer):
    class Meta:
        model = Animal
        fields = [
            'id', 'espece', 'race', 'identifiant', 'effectif',
            'date_naissance', 'notes', 'date_creation',
        ]
        read_only_fields = ['id', 'date_creation']

    def validate_effectif(self, value):
        if value < 1:
            raise serializers.ValidationError("L'effectif doit être au moins 1.")
        return value


class SuiviSanitaireSerializer(serializers.ModelSerializer):
    class Meta:
        model = SuiviSanitaire
        fields = ['id', 'animal', 'type', 'date', 'description', 'prochaine_echeance']
        read_only_fields = ['id']

    def validate_animal(self, animal):
        if animal.proprietaire != self.context['request'].user:
            raise serializers.ValidationError("Cet animal ne vous appartient pas.")
        return animal

    def validate(self, data):
        date = data.get('date', getattr(self.instance, 'date', None))
        ech = data.get('prochaine_echeance', getattr(self.instance, 'prochaine_echeance', None))
        if date and ech and ech < date:
            raise serializers.ValidationError("L'échéance doit être après la date du suivi.")
        return data
