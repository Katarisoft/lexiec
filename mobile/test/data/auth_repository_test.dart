import 'package:flutter_test/flutter_test.dart';
import 'package:lexiec/core/config/app_config.dart';
import 'package:lexiec/core/errors/api_failure.dart';
import 'package:lexiec/core/network/api_client.dart';
import 'package:lexiec/data/models/auth_tokens.dart';
import 'package:lexiec/data/repositories/auth_repository.dart';
import 'package:lexiec/data/services/auth_service.dart';

import '../support/fake_http_adapter.dart';
import '../support/in_memory_token_storage.dart';

void main() {
  late InMemoryTokenStorage storage;
  late FakeHttpAdapter adapter;
  late AuthRepository repository;

  setUp(() {
    storage = InMemoryTokenStorage();
    adapter = FakeHttpAdapter((o) async => emptyResponse(200));
    final client = ApiClient(
      config: const AppConfig(serverUrl: 'http://servidor.invalid'),
      tokenStorage: storage,
      onSessionExpired: () {},
      adapter: adapter,
    );
    repository = AuthRepository(
      service: AuthService(client.dio),
      tokenStorage: storage,
    );
  });

  FakeHandler happyServer() {
    return (options) async {
      switch (options.path) {
        case 'auth/token/':
          return jsonResponse(200, {'access': 'a1', 'refresh': 'r1'});
        case 'auth/register/':
          return jsonResponse(201, userJson());
        case 'auth/me/':
          return jsonResponse(200, userJson());
        case 'auth/logout/':
          return emptyResponse(204);
      }
      return apiError(404, 'not_found');
    };
  }

  test('login guarda tokens y devuelve el perfil', () async {
    adapter.handler = happyServer();
    final user = await repository.login(
      email: ' persona.a@ejemplo.invalid ',
      password: 'Clave-2026',
    );

    expect(user.email, 'persona.a@ejemplo.invalid');
    expect(storage.tokens!.access, 'a1');
    final loginRequest = adapter.requests.first;
    expect(loginRequest.data, {
      'email': 'persona.a@ejemplo.invalid',
      'password': 'Clave-2026',
    });
  });

  test('login con credenciales incorrectas no guarda tokens', () async {
    adapter.handler = (o) async => apiError(
      401,
      'no_active_account',
      message: 'Correo o contraseña incorrectos.',
    );
    await expectLater(
      repository.login(email: 'x@ejemplo.invalid', password: 'mala'),
      throwsA(
        isA<ApiFailure>()
            .having((f) => f.kind, 'kind', FailureKind.unauthorized)
            .having((f) => f.message, 'message', contains('incorrectos')),
      ),
    );
    expect(storage.tokens, isNull);
  });

  test('si falla el perfil tras el login no quedan tokens huérfanos', () async {
    adapter.handler = (options) async {
      if (options.path == 'auth/token/') {
        return jsonResponse(200, {'access': 'a1', 'refresh': 'r1'});
      }
      return networkError(options);
    };
    await expectLater(
      repository.login(email: 'x@ejemplo.invalid', password: 'Clave-2026'),
      throwsA(isA<ApiFailure>()),
    );
    expect(storage.tokens, isNull);
  });

  test('registro con errores de validación expone errores por campo', () async {
    adapter.handler = (o) async => apiError(
      400,
      'validation_error',
      details: {
        'email': ['Ya existe una cuenta con este correo.'],
      },
    );
    await expectLater(
      repository.register(email: 'x@ejemplo.invalid', password: 'Clave-2026'),
      throwsA(
        isA<ApiFailure>().having((f) => f.fieldErrors['email'], 'email', [
          'Ya existe una cuenta con este correo.',
        ]),
      ),
    );
    expect(storage.tokens, isNull);
  });

  test('registro inicia sesión con la nueva cuenta', () async {
    adapter.handler = happyServer();
    final user = await repository.register(
      email: 'persona.a@ejemplo.invalid',
      password: 'Clave-2026',
      displayName: 'Ana',
    );
    expect(user.id, 1);
    expect(storage.tokens, isNotNull);
    expect(adapter.requests.first.data, containsPair('display_name', 'Ana'));
  });

  test('logout borra tokens locales aunque falle la red', () async {
    storage.tokens = const AuthTokens(access: 'a1', refresh: 'r1');
    adapter.handler = (options) async => networkError(options);
    await repository.logout();
    expect(storage.tokens, isNull);
  });

  test('logout envía el refresh al servidor', () async {
    storage.tokens = const AuthTokens(access: 'a1', refresh: 'r1');
    adapter.handler = happyServer();
    await repository.logout();
    final request = adapter.requests.singleWhere(
      (r) => r.path == 'auth/logout/',
    );
    expect(request.data, {'refresh': 'r1'});
    expect(storage.tokens, isNull);
  });

  group('restoreSession', () {
    test('sin tokens devuelve null sin llamar al servidor', () async {
      expect(await repository.restoreSession(), isNull);
      expect(adapter.requests, isEmpty);
    });

    test('con tokens válidos devuelve el perfil', () async {
      storage.tokens = const AuthTokens(access: 'a1', refresh: 'r1');
      adapter.handler = happyServer();
      expect((await repository.restoreSession())!.id, 1);
    });

    test('sesión rechazada limpia tokens y devuelve null', () async {
      storage.tokens = const AuthTokens(access: 'a1', refresh: 'r1');
      adapter.handler = (o) async => apiError(401, 'token_not_valid');
      expect(await repository.restoreSession(), isNull);
      expect(storage.tokens, isNull);
    });

    test('sin red conserva tokens y propaga el error', () async {
      storage.tokens = const AuthTokens(access: 'a1', refresh: 'r1');
      adapter.handler = (options) async => networkError(options);
      await expectLater(
        repository.restoreSession(),
        throwsA(
          isA<ApiFailure>().having((f) => f.kind, 'kind', FailureKind.network),
        ),
      );
      expect(storage.tokens, isNotNull);
    });
  });
}
