import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lexiec/app/app_routes.dart';
import 'package:lexiec/app/initial_binding.dart';
import 'package:lexiec/core/config/app_config.dart';
import 'package:lexiec/core/network/api_client.dart';
import 'package:lexiec/main.dart';
import 'package:lexiec/modules/auth/auth_controller.dart';

import 'support/assistant_fixtures.dart';
import 'support/fake_http_adapter.dart';
import 'support/in_memory_local_store.dart';
import 'support/in_memory_token_storage.dart';
import 'support/library_fixtures.dart';
import 'widget_test.dart' show settle;

/// Servidor simulado: el historial depende de la cuenta (token a/b).
void main() {
  late FakeHttpAdapter adapter;
  late Map<String, List<Map<String, dynamic>>> historyByUser;
  late Map<String, dynamic> nextAnswer;

  setUp(() {
    historyByUser = {
      'a': [consultationJson(1, question: '¿Consulta privada de A?')],
      'b': [consultationJson(2, question: '¿Consulta privada de B?')],
    };
    nextAnswer = consultationJson(10, question: '¿Nueva pregunta?');
    adapter = FakeHttpAdapter((options) async {
      final auth = options.headers['Authorization'] as String?;
      final who = auth == 'Bearer b' ? 'b' : 'a';
      switch (options.path) {
        case 'auth/token/':
          final email = (options.data as Map)['email'] as String;
          final user = email.startsWith('b') ? 'b' : 'a';
          return jsonResponse(200, {'access': user, 'refresh': 'r-$user'});
        case 'auth/me/':
          return jsonResponse(
            200,
            userJson(id: who == 'a' ? 1 : 2, email: '$who@ejemplo.invalid'),
          );
        case 'auth/logout/':
          return emptyResponse(204);
        case 'areas/':
          return jsonResponse(200, [areaJson(1)]);
        case 'consultations/':
          if (options.method == 'POST') {
            historyByUser[who]!.insert(0, nextAnswer);
            return jsonResponse(201, nextAnswer);
          }
          return jsonResponse(200, consultationPageJson(historyByUser[who]!));
      }
      final match = RegExp(r'^consultations/(\d+)/$').firstMatch(options.path);
      if (match != null) {
        final id = int.parse(match.group(1)!);
        final own = historyByUser[who]!.where((c) => c['id'] == id);
        if (own.isEmpty) return apiError(404, 'not_found');
        if (options.method == 'DELETE') {
          historyByUser[who]!.removeWhere((c) => c['id'] == id);
          return emptyResponse(204);
        }
        return jsonResponse(200, own.first);
      }
      return apiError(404, 'not_found');
    });
  });

  tearDown(Get.reset);

  Future<void> loginAs(WidgetTester tester, String who) async {
    final pending = Get.find<AuthController>().login(
      email: '$who@ejemplo.invalid',
      password: 'Clave-1',
    );
    await settle(tester);
    await pending;
    Get.offAllNamed<void>(AppRoutes.home);
    await settle(tester);
  }

  Future<void> startAs(WidgetTester tester, String who) async {
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
    await loginAs(tester, who);
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await settle(tester);
  }

  testWidgets('pregunta con aviso previo, respuesta y fuentes citadas', (
    tester,
  ) async {
    await startAs(tester, 'a');
    await tester.tap(find.byKey(const Key('open-assistant')));
    await settle(tester);

    expect(find.textContaining('colección revisada'), findsOneWidget);
    await tester.tap(find.text('Área ficticia 1'));
    await settle(tester);
    await tester.enterText(
      find.byKey(const Key('question-field')),
      '¿Nueva pregunta?',
    );

    // Sin aceptar el aviso no se envía.
    await tapVisible(tester, find.byKey(const Key('ask-button')));
    expect(find.textContaining('datos personales'), findsWidgets);
    expect(
      adapter.requests.where(
        (r) => r.method == 'POST' && r.path == 'consultations/',
      ),
      isEmpty,
    );

    await tapVisible(tester, find.byKey(const Key('notice-checkbox')));
    await tapVisible(tester, find.byKey(const Key('ask-button')));

    expect(find.byKey(const Key('result-answered')), findsOneWidget);
    expect(find.text('Fuentes oficiales citadas'), findsOneWidget);
    expect(find.text('Art. ficticio 1'), findsOneWidget);
    expect(find.textContaining('Fuente oficial ·'), findsOneWidget);
  });

  testWidgets('sin respaldo se muestra distinto de un error técnico', (
    tester,
  ) async {
    nextAnswer = consultationJson(11, status: 'no_support');
    await startAs(tester, 'a');
    Get.toNamed<void>(AppRoutes.assistant);
    await settle(tester);
    await tester.tap(find.text('Área ficticia 1'));
    await tester.enterText(find.byKey(const Key('question-field')), '¿Algo?');
    await tapVisible(tester, find.byKey(const Key('notice-checkbox')));
    await tapVisible(tester, find.byKey(const Key('ask-button')));

    expect(find.byKey(const Key('result-no-support')), findsOneWidget);
    expect(
      find.textContaining('no significa que no exista una norma'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('result-error')), findsNothing);
  });

  testWidgets('historial privado: ver detalle y borrar con confirmación', (
    tester,
  ) async {
    await startAs(tester, 'a');
    await tester.tap(find.byKey(const Key('open-history-home')));
    await settle(tester);
    expect(find.text('¿Consulta privada de A?'), findsOneWidget);
    expect(find.text('¿Consulta privada de B?'), findsNothing);

    await tester.tap(find.text('¿Consulta privada de A?'));
    await settle(tester);
    expect(find.byKey(const Key('result-answered')), findsOneWidget);

    await tester.tap(find.byKey(const Key('consultation-delete')));
    await settle(tester);
    await tester.tap(find.text('Cancelar'));
    await settle(tester);
    expect(adapter.requests.where((r) => r.method == 'DELETE'), isEmpty);

    await tester.tap(find.byKey(const Key('consultation-delete')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('consultation-delete-confirm')));
    await settle(tester);
    expect(adapter.requests.where((r) => r.method == 'DELETE').length, 1);
    expect(find.textContaining('Aún no has hecho consultas'), findsOneWidget);
  });

  testWidgets('tras cerrar sesión, otra cuenta no ve datos de la anterior', (
    tester,
  ) async {
    await startAs(tester, 'a');
    Get.toNamed<void>(AppRoutes.assistant);
    await settle(tester);
    await tester.tap(find.text('Área ficticia 1'));
    await tester.enterText(
      find.byKey(const Key('question-field')),
      '¿Nueva pregunta?',
    );
    await tapVisible(tester, find.byKey(const Key('notice-checkbox')));
    await tapVisible(tester, find.byKey(const Key('ask-button')));
    expect(find.byKey(const Key('result-answered')), findsOneWidget);

    Get.back<void>();
    await settle(tester);
    await tester.tap(find.byKey(const Key('logout')));
    await settle(tester);
    await loginAs(tester, 'b');

    await tester.tap(find.byKey(const Key('open-assistant')));
    await settle(tester);
    expect(find.byKey(const Key('result-answered')), findsNothing);
    final field = tester.widget<TextField>(
      find.byKey(const Key('question-field')),
    );
    expect(field.controller!.text, isEmpty);

    Get.toNamed<void>(AppRoutes.history);
    await settle(tester);
    expect(find.text('¿Consulta privada de B?'), findsOneWidget);
    expect(find.text('¿Consulta privada de A?'), findsNothing);
    expect(find.text('¿Nueva pregunta?'), findsNothing);
  });
}
