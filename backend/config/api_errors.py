"""Formato común de errores de la API.

Toda respuesta de error bajo /api/ tiene la forma:

    {"error": {"code": "<código estable>", "message": "<texto en español>",
               "details": {...}}}

`details` solo aparece cuando aporta información útil (errores por campo o
tiempo de espera). Nunca incluye trazas, configuración ni datos internos.
"""

from django.core.exceptions import PermissionDenied as DjangoPermissionDenied
from django.http import Http404, JsonResponse
from django.views.defaults import page_not_found, server_error
from rest_framework import exceptions, status
from rest_framework.views import exception_handler as drf_exception_handler

MESSAGES = {
    'validation_error': 'La solicitud contiene datos inválidos.',
    'parse_error': 'El cuerpo de la solicitud no es JSON válido.',
    'not_authenticated': 'Se requiere iniciar sesión.',
    'authentication_failed': 'No se pudo verificar la identidad.',
    'token_not_valid': 'La sesión no es válida o ha expirado.',
    'no_active_account': 'Correo o contraseña incorrectos.',
    'permission_denied': 'No tienes permiso para realizar esta acción.',
    'not_found': 'El recurso solicitado no existe o no está disponible.',
    'method_not_allowed': 'Método no permitido.',
    'not_acceptable': 'Formato de respuesta no admitido.',
    'unsupported_media_type': 'Tipo de contenido no admitido.',
    'throttled': 'Demasiadas solicitudes. Inténtalo más tarde.',
    'server_error': 'Error interno del servicio. Inténtalo más tarde.',
}


class SemanticValidationError(exceptions.APIException):
    """Petición bien formada pero semánticamente inválida (422)."""

    status_code = status.HTTP_422_UNPROCESSABLE_ENTITY
    default_code = 'unprocessable'
    default_detail = 'La solicitud no se puede procesar.'


def error_body(code, message, details=None):
    body = {'code': code, 'message': message}
    if details:
        body['details'] = details
    return {'error': body}


def _code_for(exc):
    if isinstance(exc, exceptions.ValidationError):
        return 'validation_error'
    detail = exc.detail
    # SimpleJWT devuelve un diccionario con su propio código.
    if isinstance(detail, dict) and 'code' in detail:
        return str(detail['code'])
    codes = exc.get_codes()
    if isinstance(codes, str):
        return codes
    return exc.default_code


def api_exception_handler(exc, context):
    if isinstance(exc, Http404):
        exc = exceptions.NotFound()
    elif isinstance(exc, DjangoPermissionDenied):
        exc = exceptions.PermissionDenied()

    response = drf_exception_handler(exc, context)
    if response is None:
        # Error no controlado: lo atiende handler500 sin exponer detalles.
        return None

    code = _code_for(exc)
    details = None
    if isinstance(exc, exceptions.ValidationError):
        data = exc.detail
        details = data if isinstance(data, dict) else {'non_field_errors': data}
        message = MESSAGES['validation_error']
    elif isinstance(exc, exceptions.Throttled):
        message = MESSAGES['throttled']
        if exc.wait is not None:
            details = {'retry_after_seconds': int(exc.wait)}
    elif code in MESSAGES:
        message = MESSAGES[code]
    else:
        message = str(exc.detail)

    response.data = error_body(code, message, details)
    return response


def _is_api(request):
    return request.path.startswith('/api/')


def handler404(request, exception):
    if _is_api(request):
        return JsonResponse(error_body('not_found', MESSAGES['not_found']), status=404)
    return page_not_found(request, exception)


def handler500(request):
    if _is_api(request):
        return JsonResponse(error_body('server_error', MESSAGES['server_error']), status=500)
    return server_error(request)
