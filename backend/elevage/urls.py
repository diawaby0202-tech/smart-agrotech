from rest_framework.routers import DefaultRouter

from .views import AnimalViewSet, SuiviSanitaireViewSet

router = DefaultRouter()
router.register('animaux', AnimalViewSet, basename='animal')
router.register('suivis-sanitaires', SuiviSanitaireViewSet, basename='suivi-sanitaire')
urlpatterns = router.urls
