from rest_framework.routers import DefaultRouter

from .admin_views import AnnonceModerationViewSet
from .views import AnnonceViewSet

router = DefaultRouter()
router.register('annonces', AnnonceViewSet, basename='annonce')
router.register('admin/annonces', AnnonceModerationViewSet, basename='admin-annonce')
urlpatterns = router.urls
