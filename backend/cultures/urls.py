from rest_framework.routers import DefaultRouter

from .views import ParcelleViewSet, RecolteViewSet

router = DefaultRouter()
router.register('parcelles', ParcelleViewSet, basename='parcelle')
router.register('recoltes', RecolteViewSet, basename='recolte')
urlpatterns = router.urls
