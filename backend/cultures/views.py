from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from utilisateurs.models import RoleUtilisateur

from .models import Parcelle, Recolte
from .serializers import ParcelleSerializer, RecolteSerializer


class ParcelleViewSet(viewsets.ModelViewSet):
    """CRUD des parcelles de l'utilisateur connecté (RF-06, RF-07)."""
    serializer_class = ParcelleSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        qs = (
            Parcelle.objects.all()
            if self.request.user.role == RoleUtilisateur.ADMIN
            else Parcelle.objects.filter(proprietaire=self.request.user)
        )
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


class RecolteViewSet(viewsets.ModelViewSet):
    """Historique des récoltes des parcelles de l'utilisateur connecté."""
    serializer_class = RecolteSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        qs = Recolte.objects.select_related('parcelle')
        if self.request.user.role != RoleUtilisateur.ADMIN:
            qs = qs.filter(parcelle__proprietaire=self.request.user)
        parcelle = self.request.query_params.get('parcelle', '')
        if parcelle.isdigit():
            qs = qs.filter(parcelle_id=int(parcelle))
        return qs
