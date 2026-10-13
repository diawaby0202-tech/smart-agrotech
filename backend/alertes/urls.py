from rest_framework.routers import DefaultRouter

from django.urls import path

from .views import AlerteViewSet, MeteoView

router = DefaultRouter()
router.register('alertes', AlerteViewSet, basename='alerte')
urlpatterns = [path('meteo/', MeteoView.as_view(), name='meteo')] + router.urls
