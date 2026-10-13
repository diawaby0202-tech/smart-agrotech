from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import Annonce, Moderation
from .permissions import EstVendeurOuLectureSeule
from .serializers import AnnonceSerializer


class AnnonceViewSet(viewsets.ModelViewSet):
    """Marché agricole : publication, recherche et filtres (RF-16 à RF-19).

    Filtres : ?categorie= ?zone= ?prix_min= ?prix_max= ?q= ?statut=
    """
    serializer_class = AnnonceSerializer
    permission_classes = [IsAuthenticated, EstVendeurOuLectureSeule]

    def get_queryset(self):
        qs = Annonce.objects.select_related('vendeur').filter(moderation=Moderation.APPROUVEE)
        p = self.request.query_params
        if p.get('categorie'):
            qs = qs.filter(categorie=p['categorie'])
        if p.get('zone'):
            qs = qs.filter(zone__icontains=p['zone'])
        if p.get('statut'):
            qs = qs.filter(statut=p['statut'])
        if p.get('q'):
            qs = qs.filter(titre__icontains=p['q'])
        try:
            if p.get('prix_min'):
                qs = qs.filter(prix__gte=int(p['prix_min']))
            if p.get('prix_max'):
                qs = qs.filter(prix__lte=int(p['prix_max']))
        except ValueError:
            pass
        return qs

    def perform_create(self, serializer):
        serializer.save(vendeur=self.request.user)

    @action(detail=False, methods=['get'])
    def mes_annonces(self, request):
        qs = self.get_queryset().filter(vendeur=request.user)
        return Response(self.get_serializer(qs, many=True).data)
