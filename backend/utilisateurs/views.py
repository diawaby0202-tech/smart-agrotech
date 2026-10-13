from rest_framework import permissions, viewsets
from rest_framework.exceptions import PermissionDenied
from rest_framework.generics import CreateAPIView, RetrieveUpdateAPIView
from rest_framework_simplejwt.views import TokenObtainPairView

from .models import Utilisateur
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
