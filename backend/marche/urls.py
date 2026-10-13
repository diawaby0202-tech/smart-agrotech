from rest_framework.routers import DefaultRouter

from .views import AnnonceViewSet

router = DefaultRouter()
router.register('annonces', AnnonceViewSet, basename='annonce')
urlpatterns = router.urls
