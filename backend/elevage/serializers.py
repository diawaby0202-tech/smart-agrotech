from rest_framework import serializers

from utilisateurs.models import RoleUtilisateur

from .models import Animal, SuiviReproduction, SuiviSanitaire


class AnimalSerializer(serializers.ModelSerializer):
    class Meta:
        model = Animal
        fields = [
            'id', 'espece', 'race', 'identifiant', 'effectif',
            'date_naissance', 'notes', 'image', 'date_creation',
        ]
        read_only_fields = ['id', 'date_creation']

    def validate_image(self, value):
        if value.size > 5 * 1024 * 1024:
            raise serializers.ValidationError('La photo ne peut pas dépasser 5 Mo.')
        return value

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
        user = self.context['request'].user
        if (
            user.role != RoleUtilisateur.ADMIN
            and animal.proprietaire_id != user.id
        ):
            raise serializers.ValidationError("Cet animal ne vous appartient pas.")
        return animal

    def validate(self, data):
        date = data.get('date', getattr(self.instance, 'date', None))
        ech = data.get('prochaine_echeance', getattr(self.instance, 'prochaine_echeance', None))
        if date and ech and ech < date:
            raise serializers.ValidationError("L'échéance doit être après la date du suivi.")
        return data


class SuiviReproductionSerializer(serializers.ModelSerializer):
    class Meta:
        model = SuiviReproduction
        fields = [
            'id', 'animal', 'date_saillie', 'mise_bas_prevue',
            'mise_bas_reelle', 'nombre_petits', 'notes', 'date_creation',
        ]
        read_only_fields = ['id', 'date_creation']

    def validate_animal(self, animal):
        user = self.context['request'].user
        if (
            user.role != RoleUtilisateur.ADMIN
            and animal.proprietaire_id != user.id
        ):
            raise serializers.ValidationError("Cet animal ne vous appartient pas.")
        return animal

    def validate(self, data):
        saillie = data.get(
            'date_saillie', getattr(self.instance, 'date_saillie', None)
        )
        prevue = data.get(
            'mise_bas_prevue', getattr(self.instance, 'mise_bas_prevue', None)
        )
        reelle = data.get(
            'mise_bas_reelle', getattr(self.instance, 'mise_bas_reelle', None)
        )
        if not any((saillie, prevue, reelle)):
            raise serializers.ValidationError(
                'Renseignez au moins une date de reproduction.'
            )
        if saillie and prevue and prevue < saillie:
            raise serializers.ValidationError(
                'La mise bas prévue doit suivre la date de saillie.'
            )
        if saillie and reelle and reelle < saillie:
            raise serializers.ValidationError(
                'La mise bas réelle doit suivre la date de saillie.'
            )
        return data
