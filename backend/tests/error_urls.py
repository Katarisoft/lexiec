"""URLconf exclusiva de pruebas para provocar 403 y 500.

No se incluye en config.urls: estos endpoints no existen en producción.
"""

from django.urls import path
from rest_framework.permissions import IsAdminUser
from rest_framework.response import Response
from rest_framework.views import APIView


class AdminOnlyView(APIView):
    permission_classes = [IsAdminUser]

    def get(self, request):
        return Response({'ok': True})


class BrokenView(APIView):
    permission_classes = []
    authentication_classes = []

    def get(self, request):
        raise RuntimeError('detalle interno que no debe salir: SECRET_KEY=x')


urlpatterns = [
    path('api/v1/test/admin-only/', AdminOnlyView.as_view()),
    path('api/v1/test/broken/', BrokenView.as_view()),
]

handler404 = 'config.api_errors.handler404'
handler500 = 'config.api_errors.handler500'
