from rest_framework.routers import DefaultRouter

from .admin_views import AnnonceModerationViewSet
from .views import AnnonceViewSet, CommandeViewSet

router = DefaultRouter()
router.register('annonces', AnnonceViewSet, basename='annonce')
router.register('commandes', CommandeViewSet, basename='commande')
router.register('admin/annonces', AnnonceModerationViewSet, basename='admin-annonce')
urlpatterns = router.urls
