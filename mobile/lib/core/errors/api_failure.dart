import 'dart:io';

import 'package:dio/dio.dart';

/// Categorías de error que la interfaz trata de forma distinta.
enum FailureKind {
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  unprocessable,
  tooManyRequests,
  server,
  network,
  timeout,
  cancelled,
  unknown,
}

/// Error de la API traducido al contrato de `docs/API.md`.
class ApiFailure implements Exception {
  const ApiFailure({
    required this.kind,
    required this.message,
    this.code,
    this.statusCode,
    this.fieldErrors = const {},
    this.retryAfterSeconds,
  });

  final FailureKind kind;

  /// Código estable del backend (`error.code`), si existe.
  final String? code;
  final int? statusCode;

  /// Mensaje en español apto para mostrar.
  final String message;

  /// Errores por campo de un 400 de validación.
  final Map<String, List<String>> fieldErrors;
  final int? retryAfterSeconds;

  static const _networkMessage =
      'No hay conexión con el servidor. Revisa tu conexión e inténtalo de nuevo.';
  static const _timeoutMessage =
      'El servidor tardó demasiado en responder. Inténtalo de nuevo.';
  static const _serverMessage =
      'El servicio no está disponible en este momento. Inténtalo más tarde.';
  static const _unknownMessage = 'Ocurrió un error inesperado.';

  factory ApiFailure.fromDio(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const ApiFailure(
          kind: FailureKind.timeout,
          message: _timeoutMessage,
        );
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        return const ApiFailure(
          kind: FailureKind.network,
          message: _networkMessage,
        );
      case DioExceptionType.cancel:
        return const ApiFailure(
          kind: FailureKind.cancelled,
          message: 'Solicitud cancelada.',
        );
      case DioExceptionType.badResponse:
        return ApiFailure._fromResponse(error.response!);
      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          return const ApiFailure(
            kind: FailureKind.network,
            message: _networkMessage,
          );
        }
        return const ApiFailure(
          kind: FailureKind.unknown,
          message: _unknownMessage,
        );
    }
  }

  factory ApiFailure._fromResponse(Response<dynamic> response) {
    final status = response.statusCode ?? 0;
    final kind = _kindForStatus(status);

    String? code;
    String? message;
    var fieldErrors = const <String, List<String>>{};
    int? retryAfter;

    final body = response.data;
    if (body is Map && body['error'] is Map) {
      final error = body['error'] as Map;
      code = error['code'] as String?;
      message = error['message'] as String?;
      final details = error['details'];
      if (details is Map) {
        fieldErrors = {
          for (final entry in details.entries)
            if (entry.value is List)
              entry.key.toString(): [
                for (final item in entry.value as List) item.toString(),
              ],
        };
        final wait = details['retry_after_seconds'];
        if (wait is int) retryAfter = wait;
      }
    }
    retryAfter ??= int.tryParse(response.headers.value('retry-after') ?? '');

    // En 5xx nunca se muestra texto del servidor.
    if (kind == FailureKind.server || message == null || message.isEmpty) {
      message = _defaultMessage(kind);
    }

    return ApiFailure(
      kind: kind,
      code: code,
      statusCode: status,
      message: message,
      fieldErrors: fieldErrors,
      retryAfterSeconds: retryAfter,
    );
  }

  static FailureKind _kindForStatus(int status) {
    if (status >= 500) return FailureKind.server;
    return switch (status) {
      400 => FailureKind.badRequest,
      401 => FailureKind.unauthorized,
      403 => FailureKind.forbidden,
      404 => FailureKind.notFound,
      422 => FailureKind.unprocessable,
      429 => FailureKind.tooManyRequests,
      _ => FailureKind.unknown,
    };
  }

  static String _defaultMessage(FailureKind kind) {
    return switch (kind) {
      FailureKind.badRequest => 'La solicitud contiene datos inválidos.',
      FailureKind.unauthorized => 'Tu sesión no es válida. Inicia sesión.',
      FailureKind.forbidden => 'No tienes permiso para realizar esta acción.',
      FailureKind.notFound => 'El contenido no está disponible.',
      FailureKind.unprocessable => 'La solicitud no se puede procesar.',
      FailureKind.tooManyRequests =>
        'Demasiadas solicitudes. Inténtalo más tarde.',
      FailureKind.server => _serverMessage,
      FailureKind.network => _networkMessage,
      FailureKind.timeout => _timeoutMessage,
      FailureKind.cancelled => 'Solicitud cancelada.',
      FailureKind.unknown => _unknownMessage,
    };
  }

  /// Errores en los que tiene sentido ofrecer «Reintentar».
  bool get isRetryable =>
      kind == FailureKind.network ||
      kind == FailureKind.timeout ||
      kind == FailureKind.server;

  @override
  String toString() => 'ApiFailure($kind, $code, $statusCode)';
}
