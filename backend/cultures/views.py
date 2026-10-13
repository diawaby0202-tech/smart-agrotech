from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import Parcelle
from .serializers import ParcelleSerializer


class ParcelleViewSet(viewsets.ModelViewSet):
    """CRUD des parcelles de l'utilisateur connecté (RF-06, RF-07)."""
    serializer_class = ParcelleSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        qs = Parcelle.objects.filter(proprietaire=self.request.user)
        statut = self.request.query_params.get('statut')
        if statut:
            qs = qs.filter(statut=statut)
        return qs

    def perform_create(self, serializer):
        serializer.save(proprietaire=self.request.user)

    @action(detail=False, methods=['get'])
    def calendrier(self, request):
        """Parcelles non récoltées triées par date de récolte prévue (RF-08)."""
        qs = (
            self.get_queryset()
            .exclude(statut='recoltee')
            .exclude(date_recolte_prevue__isnull=True)
            .order_by('date_recolte_prevue')
        )
        return Response(self.get_serializer(qs, many=True).data)
