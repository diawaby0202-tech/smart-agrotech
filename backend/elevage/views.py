from datetime import timedelta

from django.utils import timezone
from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import Animal, SuiviSanitaire
from .serializers import AnimalSerializer, SuiviSanitaireSerializer


class AnimalViewSet(viewsets.ModelViewSet):
    """CRUD des animaux / lots de l'utilisateur connecté (RF-10)."""
    serializer_class = AnimalSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        qs = Animal.objects.filter(proprietaire=self.request.user)
        espece = self.request.query_params.get('espece')
        if espece:
            qs = qs.filter(espece__icontains=espece)
        return qs

    def perform_create(self, serializer):
        serializer.save(proprietaire=self.request.user)


class SuiviSanitaireViewSet(viewsets.ModelViewSet):
    """Interventions sanitaires (RF-11) et échéances à venir (RF-12)."""
    serializer_class = SuiviSanitaireSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        qs = SuiviSanitaire.objects.filter(animal__proprietaire=self.request.user)
        animal = self.request.query_params.get('animal')
        if animal:
            qs = qs.filter(animal_id=animal)
        return qs

    @action(detail=False, methods=['get'])
    def echeances(self, request):
        """Suivis dont l'échéance tombe dans les N prochains jours (défaut 14)."""
        try:
            jours = int(request.query_params.get('jours', 14))
        except ValueError:
            jours = 14
        today = timezone.localdate()
        qs = self.get_queryset().filter(
            prochaine_echeance__gte=today,
            prochaine_echeance__lte=today + timedelta(days=jours),
        ).order_by('prochaine_echeance')
        return Response(self.get_serializer(qs, many=True).data)
