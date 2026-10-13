from django.urls import include, path
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenBlacklistView, TokenRefreshView

from .views import (
    AdminUtilisateurViewSet,
    ConnexionView,
    InscriptionView,
    ProfilView,
    StatistiquesView,
)

router = DefaultRouter()
router.register('admin/users', AdminUtilisateurViewSet, basename='admin-users')

urlpatterns = [
    path('auth/register/', InscriptionView.as_view(), name='register'),
    path('auth/login/', ConnexionView.as_view(), name='login'),
    path('auth/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('auth/logout/', TokenBlacklistView.as_view(), name='logout'),
    path('users/me/', ProfilView.as_view(), name='me'),
    path('admin/stats/', StatistiquesView.as_view(), name='admin-stats'),
    path('', include(router.urls)),
]
