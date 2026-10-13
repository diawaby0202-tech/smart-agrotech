from rest_framework.permissions import SAFE_METHODS, BasePermission


class EstVendeurOuLectureSeule(BasePermission):
    """Tout le monde lit ; seul le vendeur modifie/supprime (RF-19)."""

    def has_object_permission(self, request, view, obj):
        return request.method in SAFE_METHODS or obj.vendeur_id == request.user.id
