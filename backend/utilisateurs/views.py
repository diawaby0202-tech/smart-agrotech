from datetime import timedelta

from django.db.models import Count
from django.utils import timezone
from drf_spectacular.utils import extend_schema
from rest_framework import permissions, serializers, viewsets
from rest_framework.exceptions import PermissionDenied
from rest_framework.generics import CreateAPIView, RetrieveUpdateAPIView
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.views import TokenObtainPairView

from .models import RoleUtilisateur, StatutCompte, Utilisateur
from .permissions import EstAdministrateur
from .serializers import (
    AdminUtilisateurSerializer,
    ConnexionSerializer,
    InscriptionSerializer,
    ProfilSerializer,
)


class InscriptionView(CreateAPIView):
    """POST /api/auth/register/ : créer un compte."""

    serializer_class = InscriptionSerializer
    permission_classes = [permissions.AllowAny]


class ConnexionView(TokenObtainPairView):
    """POST /api/auth/login/ : obtenir les tokens JWT (access et refresh)."""

    serializer_class = ConnexionSerializer


class ProfilView(RetrieveUpdateAPIView):
    """GET / PATCH /api/users/me/ : consulter ou modifier son profil."""

    serializer_class = ProfilSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        return self.request.user


class AdminUtilisateurViewSet(viewsets.ModelViewSet):
    """/api/admin/users/ : liste, validation, modification, suspension et suppression."""

    serializer_class = AdminUtilisateurSerializer
    permission_classes = [EstAdministrateur]
    http_method_names = ['get', 'patch', 'delete', 'head', 'options']

    def get_queryset(self):
        queryset = Utilisateur.objects.all()
        role = self.request.query_params.get('role')
        statut = self.request.query_params.get('statut')
        if role:
            queryset = queryset.filter(role=role)
        if statut:
            queryset = queryset.filter(statut=statut)
        return queryset

    def perform_destroy(self, instance):
        if instance == self.request.user:
            raise PermissionDenied('Vous ne pouvez pas supprimer votre propre compte.')
        instance.delete()


class StatistiquesSerializer(serializers.Serializer):
    """Format de la réponse de /api/admin/stats/ (utilisé pour la documentation)."""

    total_utilisateurs = serializers.IntegerField()
    par_role = serializers.DictField(child=serializers.IntegerField())
    par_statut = serializers.DictField(child=serializers.IntegerField())
    nouveaux_30_jours = serializers.IntegerField()


class StatistiquesView(APIView):
    """GET /api/admin/stats/ : statistiques globales de la plateforme (RF-23)."""

    permission_classes = [EstAdministrateur]

    @extend_schema(responses=StatistiquesSerializer)
    def get(self, request):
        utilisateurs = Utilisateur.objects.all().order_by()

        par_role = {role: 0 for role in RoleUtilisateur.values}
        par_role.update(dict(utilisateurs.values_list('role').annotate(n=Count('id'))))

        par_statut = {statut: 0 for statut in StatutCompte.values}
        par_statut.update(dict(utilisateurs.values_list('statut').annotate(n=Count('id'))))

        depuis = timezone.now() - timedelta(days=30)

        return Response({
            'total_utilisateurs': utilisateurs.count(),
            'par_role': par_role,
            'par_statut': par_statut,
            'nouveaux_30_jours': utilisateurs.filter(date_inscription__gte=depuis).count(),
        })
