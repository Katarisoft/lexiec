"""Comprobación de salud para Docker y el proxy.

Solo indica si el servicio puede atender (incluida la base de datos). No
expone versiones, configuración ni detalles del error.
"""

from django.db import DatabaseError, connection
from rest_framework.decorators import api_view, authentication_classes, permission_classes, throttle_classes
from rest_framework.response import Response

from config.api_errors import error_body


@api_view(['GET'])
@authentication_classes([])
@permission_classes([])
@throttle_classes([])
def health(request):
    try:
        with connection.cursor() as cursor:
            cursor.execute('SELECT 1')
    except DatabaseError:
        return Response(
            error_body('service_unavailable', 'Servicio no disponible.'), status=503
        )
    return Response({'status': 'ok'})
