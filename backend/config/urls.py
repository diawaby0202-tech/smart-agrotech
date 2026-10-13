from django.contrib import admin
from django.urls import include, path
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('utilisateurs.urls')),
    path('api/', include('cultures.urls')),
    path('api/', include('elevage.urls')),
    path('api/', include('alertes.urls')),
    path('api/', include('marche.urls')),
    path('api/schema/', SpectacularAPIView.as_view(), name='schema'),
    path('api/docs/', SpectacularSwaggerView.as_view(url_name='schema'), name='docs'),
]
