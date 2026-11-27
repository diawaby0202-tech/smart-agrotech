from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import PermissionDenied, ValidationError
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from django.db import transaction
from django.utils import timezone

from .models import Annonce, Commande, Moderation, StatutCommande
from .permissions import EstVendeurOuLectureSeule
from .serializers import AnnonceSerializer, CommandeSerializer


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

    def perform_destroy(self, instance):
        if instance.commandes.exists():
            raise ValidationError(
                'Cette annonce a des commandes et ne peut pas être supprimée.'
            )
        instance.delete()

    @action(detail=False, methods=['get'])
    def mes_annonces(self, request):
        qs = self.get_queryset().filter(vendeur=request.user)
        return Response(self.get_serializer(qs, many=True).data)


class CommandeViewSet(viewsets.ModelViewSet):
    serializer_class = CommandeSerializer
    permission_classes = [IsAuthenticated]
    http_method_names = ['get', 'post', 'head', 'options']

    def get_queryset(self):
        user = self.request.user
        qs = Commande.objects.select_related('acheteur', 'annonce', 'annonce__vendeur')
        now = timezone.now()
        qs.filter(
            statut=StatutCommande.A_PAYER,
            date_expiration__lte=now,
        ).update(statut=StatutCommande.EXPIREE)
        if user.role == 'acheteur':
            return qs.filter(acheteur=user)
        if user.role == 'producteur':
            return qs.filter(annonce__vendeur=user)
        return qs.none()

    def create(self, request, *args, **kwargs):
        if request.user.role != 'acheteur':
            raise PermissionDenied('Seuls les acheteurs peuvent commander.')
        return super().create(request, *args, **kwargs)

    @action(detail=True, methods=['post'])
    def signaler_paiement(self, request, pk=None):
        commande = self.get_object()
        if commande.acheteur_id != request.user.id:
            raise PermissionDenied('Cette commande ne vous appartient pas.')
        if commande.statut != StatutCommande.A_PAYER:
            raise ValidationError('Cette commande ne peut plus recevoir de paiement.')
        if commande.date_expiration <= timezone.now():
            commande.statut = StatutCommande.EXPIREE
            commande.save(update_fields=['statut'])
            raise ValidationError('Le délai de paiement de cette commande est dépassé.')
        commande.statut = StatutCommande.PAIEMENT_SIGNALE
        commande.save(update_fields=['statut'])
        return Response(self.get_serializer(commande).data)

    @action(detail=True, methods=['post'])
    def confirmer(self, request, pk=None):
        with transaction.atomic():
            commande = self.get_queryset().select_for_update().get(pk=pk)
            if commande.annonce.vendeur_id != request.user.id:
                raise PermissionDenied('Seul le vendeur peut confirmer le paiement.')
            if commande.statut != StatutCommande.PAIEMENT_SIGNALE:
                raise ValidationError('L’acheteur n’a pas encore signalé le paiement.')
            annonce = Annonce.objects.select_for_update().get(pk=commande.annonce_id)
            if annonce.stock is None or commande.quantite > annonce.stock:
                raise ValidationError('Le stock ne permet plus de confirmer cette commande.')
            annonce.stock -= commande.quantite
            if annonce.stock == 0:
                annonce.statut = Annonce.StatutAnnonce.VENDUE
            annonce.save(update_fields=['stock', 'statut'])
            commande.statut = StatutCommande.CONFIRMEE
            commande.save(update_fields=['statut'])
        return Response(self.get_serializer(commande).data)
