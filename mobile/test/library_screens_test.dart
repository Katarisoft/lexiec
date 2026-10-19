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

import 'support/fake_http_adapter.dart';
import 'support/in_memory_local_store.dart';
import 'support/in_memory_token_storage.dart';
import 'support/library_fixtures.dart';
import 'widget_test.dart' show settle;

void main() {
  late InMemoryTokenStorage storage;
  late FakeHttpAdapter adapter;
  late FakeLinkOpener opener;
  late Map<String, FakeHandler> routes;

  setUp(() {
    storage = InMemoryTokenStorage(
      const AuthTokens(access: 'a1', refresh: 'r1'),
    );
    opener = FakeLinkOpener();
    routes = {
      'auth/me/': (o) async => jsonResponse(200, userJson()),
      'areas/': (o) async => jsonResponse(200, [areaJson(1), areaJson(2)]),
      'topics/': (o) async => jsonResponse(200, topicPageJson([1, 2])),
      'topics/1/': (o) async => jsonResponse(200, topicDetailJson(1)),
      'topics/1/comments/': (o) async => jsonResponse(200, {
        'count': 0,
        'next': null,
        'previous': null,
        'results': <Object>[],
      }),
    };
    adapter = FakeHttpAdapter((options) async {
      final handler = routes[options.path];
      return handler == null ? apiError(404, 'not_found') : handler(options);
    });
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
          linkOpener: opener,
        ),
      ),
    );
    await settle(tester);
  }

  testWidgets('recorrido áreas → fichas → detalle con fuentes y regreso', (
    tester,
  ) async {
    await startApp(tester);
    expect(Get.currentRoute, AppRoutes.home);
    expect(find.text('Área ficticia 1'), findsOneWidget);
    expect(find.text('2 fichas publicadas'), findsNWidgets(2));

    await tester.tap(find.text('Área ficticia 1'));
    await settle(tester);
    expect(Get.currentRoute, AppRoutes.topics);
    expect(adapter.requests.last.queryParameters, {'area': 'area-1'});
    expect(find.text('Ficha ficticia 1'), findsOneWidget);

    await tester.tap(find.text('Ficha ficticia 1'));
    await settle(tester);
    expect(Get.currentRoute, AppRoutes.topic);
    expect(find.text('Art. ficticio 1'), findsOneWidget);
    expect(find.textContaining('Institución ficticia'), findsOneWidget);
    expect(find.text('Vigencia no comprobada'), findsOneWidget);
    expect(find.text('Limitación ficticia.'), findsOneWidget);
    expect(find.textContaining('Revisado'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('open-source-50')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('open-source-50')));
    await settle(tester);
    expect(opener.opened, ['https://ejemplo.invalid/doc']);

    Get.back<void>();
    await settle(tester);
    Get.back<void>();
    await settle(tester);
    expect(Get.currentRoute, AppRoutes.home);
  });

  testWidgets('si no se puede abrir el enlace se informa', (tester) async {
    opener.result = false;
    await startApp(tester);
    Get.toNamed<void>(AppRoutes.topic, arguments: 1);
    await settle(tester);
    await tester.ensureVisible(find.byKey(const Key('open-source-50')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('open-source-50')));
    await settle(tester);
    expect(
      find.textContaining('No se pudo abrir el enlace').hitTestable(),
      findsOneWidget,
    );
  });

  testWidgets('ficha sin fuentes visibles muestra advertencia', (tester) async {
    routes['topics/1/'] = (o) async =>
        jsonResponse(200, topicDetailJson(1, withSources: false));
    await startApp(tester);
    Get.toNamed<void>(AppRoutes.topic, arguments: 1);
    await settle(tester);
    expect(find.byKey(const Key('no-sources')), findsOneWidget);
  });

  testWidgets('áreas: error con reintento y vacío distinto', (tester) async {
    routes['areas/'] = (options) async => networkError(options);
    await startApp(tester);
    expect(
      find.textContaining('No hay conexión con el servidor'),
      findsOneWidget,
    );

    routes['areas/'] = (o) async => jsonResponse(200, []);
    await tester.tap(find.text('Reintentar'));
    await settle(tester);
    expect(find.text('Aún no hay áreas disponibles.'), findsOneWidget);
    expect(find.text('Reintentar'), findsNothing);
  });

  testWidgets('búsqueda sin resultados indica la consulta', (tester) async {
    await startApp(tester);
    routes['topics/'] = (o) async => jsonResponse(200, topicPageJson([]));
    await tester.tap(find.byKey(const Key('search-all')));
    await settle(tester);
    await tester.enterText(
      find.byKey(const Key('topic-search')),
      'inexistente',
    );
    await tester.tap(find.byKey(const Key('topic-search-submit')));
    await settle(tester);
    expect(
      find.text('No hay fichas que coincidan con «inexistente».'),
      findsOneWidget,
    );
    expect(adapter.requests.last.queryParameters, {'search': 'inexistente'});
  });

  testWidgets('cargar más añade fichas', (tester) async {
    routes['topics/'] = (options) async {
      final page = options.queryParameters['page'];
      return page == 2
          ? jsonResponse(200, topicPageJson([3], count: 3))
          : jsonResponse(200, topicPageJson([1, 2], count: 3, hasNext: true));
    };
    await startApp(tester);
    await tester.tap(find.byKey(const Key('search-all')));
    await settle(tester);
    expect(find.text('2 de 3 fichas'), findsOneWidget);

    await tester.tap(find.byKey(const Key('load-more')));
    await settle(tester);
    expect(find.text('Ficha ficticia 3'), findsOneWidget);
    expect(find.byKey(const Key('load-more')), findsNothing);
  });

  testWidgets('ficha no disponible muestra error, no vacío', (tester) async {
    await startApp(tester);
    Get.toNamed<void>(AppRoutes.topic, arguments: 99);
    await settle(tester);
    expect(find.text('El contenido no está disponible.'), findsNothing);
    expect(find.text('Mensaje del servidor.'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });
}
