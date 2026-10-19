import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lexiec/app/app_routes.dart';
import 'package:lexiec/app/initial_binding.dart';
import 'package:lexiec/core/config/app_config.dart';
import 'package:lexiec/core/network/api_client.dart';
import 'package:lexiec/main.dart';
import 'package:lexiec/modules/auth/auth_controller.dart';

import 'support/community_fixtures.dart';
import 'support/fake_http_adapter.dart';
import 'support/in_memory_local_store.dart';
import 'support/in_memory_token_storage.dart';
import 'support/library_fixtures.dart';
import 'widget_test.dart' show settle;

/// Favoritos y notas separados por cuenta a través de login/logout reales.
void main() {
  late FakeHttpAdapter adapter;

  setUp(() {
    adapter = FakeHttpAdapter((options) async {
      final auth = options.headers['Authorization'] as String?;
      switch (options.path) {
        case 'auth/token/':
          final email = (options.data as Map)['email'] as String;
          final who = email.startsWith('a') ? 'a' : 'b';
          return jsonResponse(200, {'access': who, 'refresh': 'r-$who'});
        case 'auth/me/':
          return auth == 'Bearer a'
              ? jsonResponse(200, userJson(id: 1, email: 'a@ejemplo.invalid'))
              : jsonResponse(200, userJson(id: 2, email: 'b@ejemplo.invalid'));
        case 'auth/logout/':
          return emptyResponse(204);
        case 'areas/':
          return jsonResponse(200, [areaJson(1)]);
        case 'topics/1/':
          return jsonResponse(200, topicDetailJson(1));
        case 'topics/1/comments/':
          return jsonResponse(200, commentPageJson([]));
      }
      return apiError(404, 'not_found');
    });
  });

  tearDown(Get.reset);

  Future<void> start(WidgetTester tester) async {
    final storage = InMemoryTokenStorage();
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
          linkOpener: FakeLinkOpener(),
        ),
      ),
    );
    await settle(tester);
  }

  Future<void> loginAs(WidgetTester tester, String email) async {
    // En testWidgets el reloj es simulado: hay que bombear frames para que
    // terminen las peticiones antes de esperar el resultado.
    final pending = Get.find<AuthController>().login(
      email: email,
      password: 'Clave-1',
    );
    await settle(tester);
    expect(await pending, isTrue);
    Get.offAllNamed<void>(AppRoutes.home);
    await settle(tester);
  }

  Future<void> logout(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('logout')));
    await settle(tester);
  }

  testWidgets('A guarda favorito y nota; B no los ve; A los recupera', (
    tester,
  ) async {
    await start(tester);
    await loginAs(tester, 'a@ejemplo.invalid');

    Get.toNamed<void>(AppRoutes.topic, arguments: 1);
    await settle(tester);
    await tester.tap(find.byKey(const Key('favorite-toggle')));
    await settle(tester);
    expect(find.byIcon(Icons.star), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('note-save')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byKey(const Key('note-field')), 'Nota de A.');
    // El toque simulado no alcanza el botón en esta prueba (ver nota E12);
    // se invoca su acción para comprobar persistencia y aislamiento. La
    // pulsación real se verifica en el dispositivo.
    tester.widget<TextButton>(find.byKey(const Key('note-save'))).onPressed!();
    await settle(tester);
    expect(find.textContaining('Guardada el'), findsOneWidget);

    Get.back<void>();
    await settle(tester);
    await tester.tap(find.byKey(const Key('favorites')));
    await settle(tester);
    expect(find.text('Ficha ficticia 1'), findsOneWidget);
    expect(find.textContaining('Copia guardada el'), findsOneWidget);
    expect(find.text('Mi nota: Nota de A.'), findsOneWidget);
    Get.back<void>();
    await settle(tester);

    await logout(tester);
    await loginAs(tester, 'b@ejemplo.invalid');
    await tester.tap(find.byKey(const Key('favorites')));
    await settle(tester);
    expect(find.text('Ficha ficticia 1'), findsNothing);
    expect(find.textContaining('Aún no tienes favoritos'), findsOneWidget);
    Get.back<void>();
    await settle(tester);

    await logout(tester);
    await loginAs(tester, 'a@ejemplo.invalid');
    await tester.tap(find.byKey(const Key('favorites')));
    await settle(tester);
    expect(find.text('Ficha ficticia 1'), findsOneWidget);
    expect(find.text('Mi nota: Nota de A.'), findsOneWidget);
  });

  testWidgets('borrar datos locales pide confirmación', (tester) async {
    await start(tester);
    await loginAs(tester, 'a@ejemplo.invalid');
    Get.toNamed<void>(AppRoutes.topic, arguments: 1);
    await settle(tester);
    await tester.tap(find.byKey(const Key('favorite-toggle')));
    await settle(tester);
    Get.back<void>();
    await settle(tester);

    await tester.tap(find.byKey(const Key('favorites')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('delete-local')));
    await settle(tester);
    await tester.tap(find.text('Cancelar'));
    await settle(tester);
    expect(find.text('Ficha ficticia 1'), findsOneWidget);

    await tester.tap(find.byKey(const Key('delete-local')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('delete-local-confirm')));
    await settle(tester);
    expect(find.textContaining('Aún no tienes favoritos'), findsOneWidget);
  });
}
