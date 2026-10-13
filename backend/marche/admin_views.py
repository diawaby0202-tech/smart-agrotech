from rest_framework import mixins, serializers, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from utilisateurs.permissions import EstAdministrateur

from .models import Annonce, Moderation


class AnnonceModerationSerializer(serializers.ModelSerializer):
    vendeur_email = serializers.EmailField(source='vendeur.email', read_only=True)

    class Meta:
        model = Annonce
        fields = [
            'id', 'titre', 'description', 'categorie', 'prix', 'zone', 'statut',
            'moderation', 'vendeur_email', 'date_creation',
        ]
        read_only_fields = [f for f in fields if f != 'moderation']


class AnnonceModerationViewSet(
    mixins.ListModelMixin, mixins.RetrieveModelMixin, mixins.UpdateModelMixin,
    mixins.DestroyModelMixin, viewsets.GenericViewSet,
):
    """/api/admin/annonces/ : modération des annonces par l'administrateur (RF-22).

    Filtres : ?moderation= ?categorie= ?q= ?vendeur=<id>
    """
    serializer_class = AnnonceModerationSerializer
    permission_classes = [EstAdministrateur]
    http_method_names = ['get', 'patch', 'post', 'delete', 'head', 'options']  # post = masquer/restaurer

    def get_queryset(self):
        qs = Annonce.objects.select_related('vendeur')
        p = self.request.query_params
        if p.get('moderation'):
            qs = qs.filter(moderation=p['moderation'])
        if p.get('categorie'):
            qs = qs.filter(categorie=p['categorie'])
        if p.get('q'):
            qs = qs.filter(titre__icontains=p['q'])
        if p.get('vendeur', '').isdigit():
            qs = qs.filter(vendeur_id=int(p['vendeur']))
        return qs

    @action(detail=True, methods=['post'])
    def masquer(self, request, pk=None):
        """Masque l'annonce du marché (reste visible ici, restaurable)."""
        annonce = self.get_object()
        annonce.moderation = Moderation.SUPPRIMEE
        annonce.save(update_fields=['moderation'])
        return Response(self.get_serializer(annonce).data)

    @action(detail=True, methods=['post'])
    def restaurer(self, request, pk=None):
        annonce = self.get_object()
        annonce.moderation = Moderation.APPROUVEE
        annonce.save(update_fields=['moderation'])
        return Response(self.get_serializer(annonce).data)
