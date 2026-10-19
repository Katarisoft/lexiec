import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiec/core/config/app_config.dart';
import 'package:lexiec/core/network/api_client.dart';
import 'package:lexiec/data/models/auth_tokens.dart';

import '../support/fake_http_adapter.dart';
import '../support/in_memory_token_storage.dart';

const refreshPath = 'auth/token/refresh/';

/// Devuelve el error de [future] o `null` si termina bien.
Future<Object?> errorOf(Future<dynamic> future) async {
  try {
    await future;
    return null;
  } catch (error) {
    return error;
  }
}

void main() {
  late InMemoryTokenStorage storage;
  late FakeHttpAdapter adapter;
  late Dio dio;
  late int expiredCount;

  setUp(() {
    storage = InMemoryTokenStorage(
      const AuthTokens(access: 'access-viejo', refresh: 'refresh-1'),
    );
    expiredCount = 0;
    adapter = FakeHttpAdapter((o) async => emptyResponse(200));
    dio = ApiClient(
      config: const AppConfig(serverUrl: 'http://servidor.invalid'),
      tokenStorage: storage,
      onSessionExpired: () => expiredCount++,
      adapter: adapter,
    ).dio;
  });

  String? authOf(RequestOptions options) =>
      options.headers['Authorization'] as String?;

  /// Servidor simulado: acepta solo `access-nuevo` y renueva `refresh-1`.
  FakeHandler server({
    Future<void>? refreshGate,
    bool rejectRefresh = false,
    bool refreshOffline = false,
  }) {
    return (options) async {
      if (options.path == refreshPath) {
        if (refreshGate != null) await refreshGate;
        if (refreshOffline) networkError(options);
        if (rejectRefresh) return apiError(401, 'token_not_valid');
        return jsonResponse(200, {
          'access': 'access-nuevo',
          'refresh': 'refresh-2',
        });
      }
      if (authOf(options) == 'Bearer access-nuevo') {
        return jsonResponse(200, {'ok': options.path});
      }
      return apiError(401, 'token_not_valid');
    };
  }

  test('añade el access token a las peticiones protegidas', () async {
    adapter.handler = (o) async => jsonResponse(200, {});
    await dio.get<dynamic>('areas/');
    expect(authOf(adapter.requests.single), 'Bearer access-viejo');
  });

  test('no envía token a login, registro ni renovación', () async {
    adapter.handler = (o) async =>
        jsonResponse(200, {'access': 'a', 'refresh': 'r'});
    await dio.post<dynamic>('auth/token/', data: {});
    await dio.post<dynamic>('auth/register/', data: {});
    for (final request in adapter.requests) {
      expect(authOf(request), isNull);
    }
  });

  test('un 401 renueva una vez, guarda los tokens y reintenta', () async {
    adapter.handler = server();
    final response = await dio.get<dynamic>('auth/me/');

    expect(response.data, {'ok': 'auth/me/'});
    expect(adapter.countPath(refreshPath), 1);
    expect(storage.tokens!.access, 'access-nuevo');
    expect(storage.tokens!.refresh, 'refresh-2');
    expect(expiredCount, 0);
  });

  test('varios 401 simultáneos comparten una sola renovación', () async {
    final gate = Completer<void>();
    adapter.handler = server(refreshGate: gate.future);

    final pending = Future.wait([
      dio.get<dynamic>('areas/'),
      dio.get<dynamic>('topics/'),
      dio.get<dynamic>('auth/me/'),
    ]);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    gate.complete();
    final responses = await pending;

    expect(adapter.countPath(refreshPath), 1);
    expect(responses.map((r) => r.statusCode), everyElement(200));
  });

  test(
    'si la renovación es rechazada borra la sesión y avisa una vez',
    () async {
      adapter.handler = server(rejectRefresh: true);

      final results = await Future.wait([
        errorOf(dio.get<dynamic>('areas/')),
        errorOf(dio.get<dynamic>('topics/')),
      ]);

      for (final error in results) {
        expect(error, isA<DioException>());
        expect((error as DioException).response?.statusCode, 401);
      }
      expect(adapter.countPath(refreshPath), 1);
      expect(storage.tokens, isNull);
      expect(expiredCount, 1);
    },
  );

  test('un segundo 401 tras reintentar no provoca otra renovación', () async {
    adapter.handler = (options) async {
      if (options.path == refreshPath) {
        return jsonResponse(200, {'access': 'otro', 'refresh': 'refresh-2'});
      }
      return apiError(401, 'token_not_valid');
    };

    await expectLater(
      dio.get<dynamic>('auth/me/'),
      throwsA(isA<DioException>()),
    );
    expect(adapter.countPath(refreshPath), 1);
    expect(adapter.countPath('auth/me/'), 2);
  });

  test('un 401 del login no intenta renovar', () async {
    adapter.handler = (o) async => apiError(401, 'no_active_account');
    await expectLater(
      dio.post<dynamic>('auth/token/', data: {}),
      throwsA(isA<DioException>()),
    );
    expect(adapter.countPath(refreshPath), 0);
    expect(storage.tokens, isNotNull);
  });

  test('sin red durante la renovación conserva la sesión', () async {
    adapter.handler = server(refreshOffline: true);
    final error = await errorOf(dio.get<dynamic>('auth/me/'));

    expect((error! as DioException).type, DioExceptionType.connectionError);
    expect(storage.tokens, isNotNull);
    expect(expiredCount, 0);
  });

  test('si otra petición ya renovó, reintenta sin renovar de nuevo', () async {
    // La petición sale con el token viejo y, al volver, ya hay uno nuevo.
    adapter.handler = (options) async {
      if (options.path == refreshPath) fail('No debe renovar');
      if (authOf(options) == 'Bearer access-viejo') {
        storage.tokens = const AuthTokens(
          access: 'access-nuevo',
          refresh: 'refresh-2',
        );
        return apiError(401, 'token_not_valid');
      }
      return jsonResponse(200, {'ok': true});
    };

    final response = await dio.get<dynamic>('areas/');
    expect(response.statusCode, 200);
    expect(adapter.countPath(refreshPath), 0);
  });
}
