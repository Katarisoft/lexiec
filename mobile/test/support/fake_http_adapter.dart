import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

typedef FakeHandler = Future<ResponseBody> Function(RequestOptions options);

/// Adaptador HTTP de pruebas: responde con [handler] y registra peticiones.
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter(this.handler);

  FakeHandler handler;
  final List<RequestOptions> requests = [];

  int countPath(String path) => requests.where((r) => r.path == path).length;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(
  int status,
  Object? body, {
  Map<String, List<String>> headers = const {},
}) {
  return ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
      ...headers,
    },
  );
}

ResponseBody emptyResponse(int status) => ResponseBody.fromString('', status);

ResponseBody apiError(
  int status,
  String code, {
  String message = 'Mensaje del servidor.',
  Map<String, Object?>? details,
  Map<String, List<String>> headers = const {},
}) {
  return jsonResponse(status, {
    'error': {'code': code, 'message': message, 'details': ?details},
  }, headers: headers);
}

Never networkError(RequestOptions options) {
  throw DioException(
    requestOptions: options,
    type: DioExceptionType.connectionError,
  );
}

Map<String, dynamic> userJson({
  int id = 1,
  String email = 'persona.a@ejemplo.invalid',
}) {
  return {
    'id': id,
    'email': email,
    'display_name': '',
    'date_joined': '2026-10-19T10:00:00Z',
  };
}
