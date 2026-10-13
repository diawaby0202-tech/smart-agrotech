from rest_framework.permissions import BasePermission

from .models import RoleUtilisateur


class EstAdministrateur(BasePermission):
    """Autorise uniquement les utilisateurs avec le rôle administrateur."""

    def has_permission(self, request, view):
        user = request.user
        return bool(user and user.is_authenticated and user.role == RoleUtilisateur.ADMIN)
