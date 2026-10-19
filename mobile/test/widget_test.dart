import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lexiec/app/app_routes.dart';
import 'package:lexiec/app/initial_binding.dart';
import 'package:lexiec/core/config/app_config.dart';
import 'package:lexiec/core/network/api_client.dart';
import 'package:lexiec/data/models/auth_tokens.dart';
import 'package:lexiec/main.dart';
import 'package:lexiec/modules/auth/auth_controller.dart';
import 'package:lexiec/modules/common/widgets/academic_notice.dart';

import 'support/fake_http_adapter.dart';
import 'support/in_memory_local_store.dart';
import 'support/in_memory_token_storage.dart';

void main() {
  late InMemoryTokenStorage storage;
  late FakeHttpAdapter adapter;

  setUp(() {
    storage = InMemoryTokenStorage();
    adapter = FakeHttpAdapter(happyServer());
  });

  tearDown(Get.reset);

  Future<void> startApp(WidgetTester tester) async {
    final client = ApiClient(
      config: const AppConfig(serverUrl: 'http://servidor.invalid'),
      tokenStorage: storage,
      onSessionExpired: () => Get.find<AuthController>().handleSessionExpired(),
      adapter: adapter,
    );
    await tester.pumpWidget(
      LexiEcApp(
        binding: InitialBinding(
          localStore: InMemoryLocalLibraryStore(),
          tokenStorage: storage,
          apiClient: client,
        ),
      ),
    );
    await settle(tester);
  }

  Future<void> fillLogin(
    WidgetTester tester,
    String email,
    String password,
  ) async {
    await tester.enterText(find.byKey(const Key('login-email')), email);
    await tester.enterText(find.byKey(const Key('login-password')), password);
    await tester.tap(find.byKey(const Key('login-submit')));
    await settle(tester);
  }

  testWidgets('sin sesión guardada abre el login con el aviso académico', (
    tester,
  ) async {
    await startApp(tester);
    expect(Get.currentRoute, AppRoutes.login);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text(academicNotice), findsOneWidget);
    expect(adapter.requests, isEmpty);
  });

  testWidgets('valida el formulario sin llamar al servidor', (tester) async {
    await startApp(tester);
    await tester.tap(find.byKey(const Key('login-submit')));
    await settle(tester);
    expect(find.text('Ingresa tu correo.'), findsOneWidget);
    expect(find.text('Ingresa tu contraseña.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('login-email')),
      'no-es-correo',
    );
    await tester.tap(find.byKey(const Key('login-submit')));
    await settle(tester);
    expect(find.text('Ingresa un correo válido.'), findsOneWidget);
    expect(adapter.requests, isEmpty);
  });

  testWidgets(
    'credenciales incorrectas muestran el error y conservan la entrada',
    (tester) async {
      adapter.handler = (o) async => apiError(
        401,
        'no_active_account',
        message: 'Correo o contraseña incorrectos.',
      );
      await startApp(tester);
      await fillLogin(tester, 'persona.a@ejemplo.invalid', 'incorrecta');

      expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
      expect(Get.currentRoute, AppRoutes.login);
      expect(find.text('persona.a@ejemplo.invalid'), findsOneWidget);
      expect(storage.tokens, isNull);
    },
  );

  testWidgets('sin conexión muestra un mensaje distinto', (tester) async {
    adapter.handler = (options) async => networkError(options);
    await startApp(tester);
    await fillLogin(tester, 'persona.a@ejemplo.invalid', 'Clave-2026');
    expect(
      find.textContaining('No hay conexión con el servidor'),
      findsOneWidget,
    );
  });

  testWidgets('login correcto lleva al inicio y logout vuelve al login', (
    tester,
  ) async {
    await startApp(tester);
    await fillLogin(tester, 'persona.a@ejemplo.invalid', 'Clave-2026');

    expect(Get.currentRoute, AppRoutes.home);
    expect(find.text('Hola, persona.a@ejemplo.invalid'), findsOneWidget);
    expect(storage.tokens, isNotNull);

    await tester.tap(find.byKey(const Key('logout')));
    await settle(tester);

    expect(Get.currentRoute, AppRoutes.login);
    expect(storage.tokens, isNull);
    expect(adapter.countPath('auth/logout/'), 1);
    expect(Get.find<AuthController>().user.value, isNull);
  });

  testWidgets('el registro muestra los errores del servidor por campo', (
    tester,
  ) async {
    adapter.handler = (o) async => apiError(
      400,
      'validation_error',
      message: 'La solicitud contiene datos inválidos.',
      details: {
        'email': ['Ya existe una cuenta con este correo.'],
      },
    );
    await startApp(tester);
    await tester.tap(find.text('Crear una cuenta'));
    await settle(tester);

    await tester.enterText(
      find.byKey(const Key('register-email')),
      'persona.a@ejemplo.invalid',
    );
    await tester.enterText(
      find.byKey(const Key('register-password')),
      'Clave-2026',
    );
    await tester.tap(find.byKey(const Key('register-submit')));
    await settle(tester);

    expect(find.text('Ya existe una cuenta con este correo.'), findsOneWidget);
    expect(Get.currentRoute, AppRoutes.register);
  });

  testWidgets('el registro correcto inicia sesión', (tester) async {
    await startApp(tester);
    await tester.tap(find.text('Crear una cuenta'));
    await settle(tester);
    await tester.enterText(
      find.byKey(const Key('register-email')),
      'persona.a@ejemplo.invalid',
    );
    await tester.enterText(
      find.byKey(const Key('register-password')),
      'Clave-2026',
    );
    await tester.enterText(
      find.byKey(const Key('register-display-name')),
      'a@b',
    );
    await tester.tap(find.byKey(const Key('register-submit')));
    await settle(tester);
    expect(find.text('El alias no puede contener «@».'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('register-display-name')),
      'Ana',
    );
    await tester.tap(find.byKey(const Key('register-submit')));
    await settle(tester);
    expect(Get.currentRoute, AppRoutes.home);
  });

  testWidgets('con sesión guardada válida abre el inicio', (tester) async {
    storage.tokens = const AuthTokens(access: 'a1', refresh: 'r1');
    await startApp(tester);
    expect(Get.currentRoute, AppRoutes.home);
  });

  testWidgets('sin red al arrancar permite reintentar sin perder la sesión', (
    tester,
  ) async {
    storage.tokens = const AuthTokens(access: 'a1', refresh: 'r1');
    adapter.handler = (options) async => networkError(options);
    await startApp(tester);

    expect(find.text('Reintentar'), findsOneWidget);
    expect(storage.tokens, isNotNull);

    adapter.handler = happyServer();
    await tester.tap(find.text('Reintentar'));
    await settle(tester);
    expect(Get.currentRoute, AppRoutes.home);
  });

  testWidgets('la ruta protegida redirige al login sin sesión', (tester) async {
    await startApp(tester);
    Get.toNamed<void>(AppRoutes.home);
    await settle(tester);
    expect(Get.currentRoute, AppRoutes.login);
  });

  testWidgets('una sesión expirada devuelve al login con aviso', (
    tester,
  ) async {
    storage.tokens = const AuthTokens(access: 'a1', refresh: 'r1');
    await startApp(tester);
    expect(Get.currentRoute, AppRoutes.home);

    Get.find<AuthController>().handleSessionExpired();
    await settle(tester);
    expect(Get.currentRoute, AppRoutes.login);
    expect(
      find.text('Tu sesión ha expirado. Inicia sesión de nuevo.'),
      findsOneWidget,
    );
  });
}

/// Avanza el reloj sin esperar a que terminen animaciones infinitas.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

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
