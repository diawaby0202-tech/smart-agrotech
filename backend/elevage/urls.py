from rest_framework.routers import DefaultRouter

from .views import (
    AnimalViewSet,
    SuiviReproductionViewSet,
    SuiviSanitaireViewSet,
)

router = DefaultRouter()
router.register('animaux', AnimalViewSet, basename='animal')
router.register('suivis-sanitaires', SuiviSanitaireViewSet, basename='suivi-sanitaire')
router.register(
    'suivis-reproduction', SuiviReproductionViewSet, basename='suivi-reproduction'
)
urlpatterns = router.urls
