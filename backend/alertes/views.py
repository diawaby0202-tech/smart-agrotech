from rest_framework import mixins, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import Alerte
from .serializers import AlerteSerializer


class AlerteViewSet(mixins.ListModelMixin, mixins.RetrieveModelMixin, viewsets.GenericViewSet):
    """Historique des alertes de l'utilisateur connecté (RF-15).
    Les alertes sont créées par le système (météo, échéances), pas par l'utilisateur."""
    serializer_class = AlerteSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        qs = Alerte.objects.filter(utilisateur=self.request.user)
        lue = self.request.query_params.get('lue')
        if lue in ('true', 'false'):
            qs = qs.filter(lue=(lue == 'true'))
        return qs

    @action(detail=True, methods=['post'])
    def marquer_lue(self, request, pk=None):
        alerte = self.get_object()
        alerte.lue = True
        alerte.save(update_fields=['lue'])
        return Response(self.get_serializer(alerte).data)

    @action(detail=False, methods=['post'])
    def tout_marquer_lu(self, request):
        n = self.get_queryset().filter(lue=False).update(lue=True)
        return Response({'mises_a_jour': n})
