import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lexiec/core/config/app_config.dart';
import 'package:lexiec/core/errors/api_failure.dart';
import 'package:lexiec/core/network/api_client.dart';
import 'package:lexiec/data/models/auth_tokens.dart';
import 'package:lexiec/data/repositories/auth_repository.dart';
import 'package:lexiec/data/services/auth_service.dart';
import 'package:lexiec/modules/auth/auth_controller.dart';

import '../support/fake_http_adapter.dart';
import '../support/in_memory_token_storage.dart';

void main() {
  late InMemoryTokenStorage storage;
  late FakeHttpAdapter adapter;
  late AuthController controller;

  setUp(() {
    storage = InMemoryTokenStorage();
    adapter = FakeHttpAdapter((o) async => emptyResponse(200));
    late AuthController created;
    final client = ApiClient(
      config: const AppConfig(serverUrl: 'http://servidor.invalid'),
      tokenStorage: storage,
      onSessionExpired: () => created.handleSessionExpired(),
      adapter: adapter,
    );
    created = AuthController(
      AuthRepository(service: AuthService(client.dio), tokenStorage: storage),
    );
    controller = created;
  });

  FakeHandler loginServer() {
    return (options) async {
      if (options.path == 'auth/token/') {
        return jsonResponse(200, {'access': 'a1', 'refresh': 'r1'});
      }
      if (options.path == 'auth/me/') return jsonResponse(200, userJson());
      if (options.path == 'auth/logout/') return emptyResponse(204);
      return apiError(404, 'not_found');
    };
  }

  test('estado inicial desconocido', () {
    expect(controller.status.value, AuthStatus.unknown);
    expect(controller.user.value, isNull);
  });

  test('login correcto autentica y limpia errores', () async {
    controller.errorMessage.value = 'error anterior';
    adapter.handler = loginServer();

    final ok = await controller.login(
      email: 'persona.a@ejemplo.invalid',
      password: 'Clave-2026',
    );

    expect(ok, isTrue);
    expect(controller.isAuthenticated, isTrue);
    expect(controller.user.value!.email, 'persona.a@ejemplo.invalid');
    expect(controller.errorMessage.value, isNull);
    expect(controller.isSubmitting.value, isFalse);
  });

  test('login fallido muestra el mensaje y no autentica', () async {
    adapter.handler = (o) async => apiError(
      401,
      'no_active_account',
      message: 'Correo o contraseña incorrectos.',
    );
    final ok = await controller.login(email: 'x@e.invalid', password: 'mala');

    expect(ok, isFalse);
    expect(controller.isAuthenticated, isFalse);
    expect(controller.errorMessage.value, 'Correo o contraseña incorrectos.');
    expect(controller.lastFailure.value!.kind, FailureKind.unauthorized);
  });

  test('registro con errores de campo los expone por campo', () async {
    adapter.handler = (o) async => apiError(
      400,
      'validation_error',
      details: {
        'password': ['La contraseña es demasiado común.'],
      },
    );
    final ok = await controller.register(
      email: 'x@e.invalid',
      password: 'password123',
    );
    expect(ok, isFalse);
    expect(controller.fieldErrors['password'], [
      'La contraseña es demasiado común.',
    ]);
  });

  test('ignora un segundo envío mientras el primero está en curso', () async {
    final gate = Completer<void>();
    final base = loginServer();
    adapter.handler = (options) async {
      await gate.future;
      return base(options);
    };

    final first = controller.login(email: 'a@e.invalid', password: 'Clave-1');
    final second = await controller.login(
      email: 'a@e.invalid',
      password: 'Clave-1',
    );
    expect(second, isFalse);
    expect(controller.isSubmitting.value, isTrue);

    gate.complete();
    expect(await first, isTrue);
    expect(adapter.countPath('auth/token/'), 1);
  });

  test('logout limpia el estado sensible aunque falle la red', () async {
    adapter.handler = loginServer();
    await controller.login(email: 'a@e.invalid', password: 'Clave-1');

    adapter.handler = (options) async => networkError(options);
    await controller.logout();

    expect(controller.user.value, isNull);
    expect(controller.status.value, AuthStatus.unauthenticated);
    expect(storage.tokens, isNull);
  });

  test('restoreSession sin red deja reintentar sin borrar tokens', () async {
    storage.tokens = const AuthTokens(access: 'a1', refresh: 'r1');
    adapter.handler = (options) async => networkError(options);

    await controller.restoreSession();

    expect(controller.status.value, AuthStatus.unknown);
    expect(controller.lastFailure.value!.isRetryable, isTrue);
    expect(storage.tokens, isNotNull);
  });

  test('restoreSession con sesión válida autentica', () async {
    storage.tokens = const AuthTokens(access: 'a1', refresh: 'r1');
    adapter.handler = loginServer();
    await controller.restoreSession();
    expect(controller.isAuthenticated, isTrue);
  });

  test('una sesión expirada en el servidor cierra la sesión local', () async {
    adapter.handler = loginServer();
    await controller.login(email: 'a@e.invalid', password: 'Clave-1');

    adapter.handler = (options) async {
      if (options.path == 'auth/token/refresh/') {
        return apiError(401, 'token_not_valid');
      }
      return apiError(401, 'token_not_valid');
    };
    await controller.restoreSession();

    expect(controller.status.value, AuthStatus.unauthenticated);
    expect(controller.user.value, isNull);
    expect(storage.tokens, isNull);
  });
}
