from drf_spectacular.utils import OpenApiParameter, extend_schema
from rest_framework import mixins, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Alerte
from .serializers import AlerteSerializer
from .services import MeteoIndisponible, detecter_risques, generer_alertes, get_forecast, resumer_par_jour


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


    @action(detail=False, methods=['post'])
    def generer(self, request):
        """Génère maintenant les alertes météo et vaccination de l'utilisateur."""
        return Response({'creees': generer_alertes(request.user)})


class MeteoView(APIView):
    """Prévisions sur 5 jours + risques détectés (RF-13, RF-14). ?ville=Thiès"""
    permission_classes = [IsAuthenticated]

    @extend_schema(parameters=[
        OpenApiParameter('ville', str, description='Ville du Sénégal (défaut : Dakar)', default='Dakar'),
    ])
    def get(self, request):
        ville = request.query_params.get('ville', 'Dakar')
        try:
            resume = resumer_par_jour(get_forecast(ville))
        except MeteoIndisponible as e:
            return Response({'detail': str(e)}, status=503)
        risques = [{'niveau': n, 'titre': t, 'message': m} for n, t, m in detecter_risques(resume)]
        return Response({'ville': ville, 'previsions': resume, 'risques': risques})
