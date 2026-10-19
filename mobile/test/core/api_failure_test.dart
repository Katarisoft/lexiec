import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiec/core/config/app_config.dart';
import 'package:lexiec/core/errors/api_failure.dart';
import 'package:lexiec/core/network/api_client.dart';

import '../support/fake_http_adapter.dart';
import '../support/in_memory_token_storage.dart';

void main() {
  late FakeHttpAdapter adapter;
  late Dio dio;

  setUp(() {
    adapter = FakeHttpAdapter((o) async => emptyResponse(200));
    dio = ApiClient(
      config: const AppConfig(serverUrl: 'http://servidor.invalid'),
      tokenStorage: InMemoryTokenStorage(),
      onSessionExpired: () {},
      adapter: adapter,
    ).dio;
  });

  Future<ApiFailure> failureFor(FakeHandler handler) async {
    adapter.handler = handler;
    try {
      await dio.get<dynamic>('areas/');
    } on DioException catch (error) {
      return ApiFailure.fromDio(error);
    }
    fail('Se esperaba un error');
  }

  test('400 conserva código, mensaje y errores por campo', () async {
    final failure = await failureFor(
      (o) async => apiError(
        400,
        'validation_error',
        message: 'La solicitud contiene datos inválidos.',
        details: {
          'email': ['Correo inválido.'],
          'password': ['Muy corta.', 'Muy común.'],
        },
      ),
    );
    expect(failure.kind, FailureKind.badRequest);
    expect(failure.code, 'validation_error');
    expect(failure.message, 'La solicitud contiene datos inválidos.');
    expect(failure.fieldErrors['password'], ['Muy corta.', 'Muy común.']);
    expect(failure.isRetryable, isFalse);
  });

  test('distingue 401, 403, 404, 422 y 429', () async {
    final cases = {
      401: FailureKind.unauthorized,
      403: FailureKind.forbidden,
      404: FailureKind.notFound,
      422: FailureKind.unprocessable,
      429: FailureKind.tooManyRequests,
    };
    for (final entry in cases.entries) {
      final failure = await failureFor(
        (o) async => apiError(entry.key, 'codigo_${entry.key}'),
      );
      expect(failure.kind, entry.value, reason: '${entry.key}');
      expect(failure.code, 'codigo_${entry.key}');
    }
  });

  test('429 expone el tiempo de espera', () async {
    final failure = await failureFor(
      (o) async => apiError(
        429,
        'throttled',
        details: {'retry_after_seconds': 42},
        headers: {
          'retry-after': ['42'],
        },
      ),
    );
    expect(failure.retryAfterSeconds, 42);
  });

  test('5xx usa un mensaje genérico y permite reintentar', () async {
    final failure = await failureFor(
      (o) async => apiError(500, 'server_error', message: 'detalle interno'),
    );
    expect(failure.kind, FailureKind.server);
    expect(failure.message, isNot(contains('detalle interno')));
    expect(failure.isRetryable, isTrue);
  });

  test('5xx sin cuerpo JSON también se clasifica', () async {
    final failure = await failureFor((o) async => emptyResponse(502));
    expect(failure.kind, FailureKind.server);
  });

  test('sin conexión y tiempo agotado son distintos y reintentables', () async {
    final network = await failureFor((o) async => networkError(o));
    expect(network.kind, FailureKind.network);
    expect(network.isRetryable, isTrue);

    final socket = ApiFailure.fromDio(
      DioException(
        requestOptions: RequestOptions(path: 'x'),
        error: const SocketException('sin red'),
      ),
    );
    expect(socket.kind, FailureKind.network);

    final timeout = ApiFailure.fromDio(
      DioException(
        requestOptions: RequestOptions(path: 'x'),
        type: DioExceptionType.receiveTimeout,
      ),
    );
    expect(timeout.kind, FailureKind.timeout);
    expect(timeout.message, isNot(network.message));
  });
}
