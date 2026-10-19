"""Rutas del backend de LexiEC."""

from django.contrib import admin
from django.urls import include, path

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/v1/auth/', include('apps.accounts.urls')),
    path('api/v1/', include('apps.library.urls')),
    path('api/v1/', include('apps.community.urls')),
]

# Respuestas JSON sin detalles internos para rutas /api/ (solo con DEBUG=False).
handler404 = 'config.api_errors.handler404'
handler500 = 'config.api_errors.handler500'
