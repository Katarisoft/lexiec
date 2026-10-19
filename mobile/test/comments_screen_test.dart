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

import 'support/community_fixtures.dart';
import 'support/fake_http_adapter.dart';
import 'support/in_memory_local_store.dart';
import 'support/in_memory_token_storage.dart';
import 'support/library_fixtures.dart';
import 'widget_test.dart' show settle;

void main() {
  late FakeHttpAdapter adapter;
  late List<Map<String, dynamic>> serverComments;
  late FakeHandler? commentsOverride;
  var nextId = 100;

  setUp(() {
    serverComments = [
      commentJson(1, text: 'Comentario de otra cuenta.', author: 'Persona B'),
      commentJson(2, text: 'Mi comentario.', author: 'Persona A', mine: true),
    ];
    commentsOverride = null;
    adapter = FakeHttpAdapter((options) async {
      final path = options.path;
      if (path == 'auth/me/') return jsonResponse(200, userJson());
      if (path == 'areas/') return jsonResponse(200, [areaJson(1)]);
      if (path == 'topics/1/') return jsonResponse(200, topicDetailJson(1));
      if (path == 'topics/1/comments/') {
        if (commentsOverride != null) return commentsOverride!(options);
        if (options.method == 'POST') {
          final text = (options.data as Map)['text'] as String;
          final created = commentJson(
            nextId++,
            text: text,
            author: 'Persona A',
            mine: true,
          );
          serverComments.insert(0, created);
          return jsonResponse(201, created);
        }
        return jsonResponse(200, commentPageJson(serverComments));
      }
      if (path.startsWith('comments/')) {
        final id = int.parse(path.split('/')[1]);
        if (options.method == 'DELETE') {
          serverComments.removeWhere((c) => c['id'] == id);
          return emptyResponse(204);
        }
        final text = (options.data as Map)['text'] as String;
        return jsonResponse(
          200,
          commentJson(
            id,
            text: text,
            author: 'Persona A',
            mine: true,
            edited: true,
          ),
        );
      }
      return apiError(404, 'not_found');
    });
  });

  tearDown(Get.reset);

  Future<void> openTopic(WidgetTester tester) async {
    final storage = InMemoryTokenStorage(
      const AuthTokens(access: 'a', refresh: 'r'),
    );
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
    Get.toNamed<void>(AppRoutes.topic, arguments: 1);
    await settle(tester);
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
  }

  testWidgets('muestra comentarios, aviso y acciones solo en los propios', (
    tester,
  ) async {
    await openTopic(tester);
    await scrollTo(tester, find.byKey(const Key('comment-2')));

    expect(find.textContaining('no fuentes normativas'), findsOneWidget);
    expect(find.text('Comentario de otra cuenta.'), findsOneWidget);
    expect(find.byKey(const Key('comment-menu-1')), findsNothing);
    expect(find.byKey(const Key('comment-menu-2')), findsOneWidget);
  });

  testWidgets('publica un comentario y limpia el campo', (tester) async {
    await openTopic(tester);
    await scrollTo(tester, find.byKey(const Key('comment-publish')));
    await tester.enterText(
      find.byKey(const Key('comment-draft')),
      'Nuevo comentario.',
    );
    await tester.tap(find.byKey(const Key('comment-publish')));
    await settle(tester);

    expect(find.text('Nuevo comentario.'), findsOneWidget);
    final field = tester.widget<TextField>(
      find.byKey(const Key('comment-draft')),
    );
    expect(field.controller!.text, isEmpty);
  });

  testWidgets('si falla la publicación conserva el texto', (tester) async {
    await openTopic(tester);
    commentsOverride = (options) async => options.method == 'POST'
        ? networkError(options)
        : jsonResponse(200, commentPageJson(serverComments));
    await scrollTo(tester, find.byKey(const Key('comment-publish')));
    await tester.enterText(
      find.byKey(const Key('comment-draft')),
      'Texto a conservar.',
    );
    await tester.tap(find.byKey(const Key('comment-publish')));
    await settle(tester);

    expect(find.textContaining('No hay conexión'), findsOneWidget);
    final field = tester.widget<TextField>(
      find.byKey(const Key('comment-draft')),
    );
    expect(field.controller!.text, 'Texto a conservar.');
  });

  testWidgets('no publica un comentario vacío', (tester) async {
    await openTopic(tester);
    await scrollTo(tester, find.byKey(const Key('comment-publish')));
    final before = adapter.requests.length;
    await tester.tap(find.byKey(const Key('comment-publish')));
    await settle(tester);
    expect(find.text('Escribe un comentario.'), findsOneWidget);
    expect(adapter.requests.length, before);

    // El aviso desaparece al volver a escribir.
    await tester.enterText(find.byKey(const Key('comment-draft')), 'H');
    await settle(tester);
    expect(find.text('Escribe un comentario.'), findsNothing);
  });

  testWidgets('edita un comentario propio', (tester) async {
    await openTopic(tester);
    await scrollTo(tester, find.byKey(const Key('comment-menu-2')));
    await tester.tap(find.byKey(const Key('comment-menu-2')));
    await settle(tester);
    await tester.tap(find.text('Editar'));
    await settle(tester);
    await tester.enterText(
      find.byKey(const Key('comment-edit-field')),
      'Texto editado.',
    );
    await tester.tap(find.byKey(const Key('comment-edit-save')));
    await settle(tester);

    expect(find.text('Texto editado.'), findsOneWidget);
    expect(find.textContaining('editado'), findsWidgets);
  });

  testWidgets('borrar pide confirmación y cancelar no borra', (tester) async {
    await openTopic(tester);
    await scrollTo(tester, find.byKey(const Key('comment-menu-2')));

    await tester.tap(find.byKey(const Key('comment-menu-2')));
    await settle(tester);
    await tester.tap(find.text('Eliminar'));
    await settle(tester);
    expect(find.text('Eliminar comentario'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await settle(tester);
    expect(find.text('Mi comentario.'), findsOneWidget);
    expect(adapter.requests.where((r) => r.method == 'DELETE'), isEmpty);

    await tester.tap(find.byKey(const Key('comment-menu-2')));
    await settle(tester);
    await tester.tap(find.text('Eliminar'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('comment-delete-confirm')));
    await settle(tester);
    expect(find.text('Mi comentario.'), findsNothing);
  });

  testWidgets('recargar muestra comentarios nuevos de otra cuenta', (
    tester,
  ) async {
    await openTopic(tester);
    serverComments.insert(0, commentJson(50, text: 'Publicado por B ahora.'));
    await scrollTo(tester, find.byKey(const Key('comments-reload')));
    await tester.tap(find.byKey(const Key('comments-reload')));
    await settle(tester);
    expect(find.text('Publicado por B ahora.'), findsOneWidget);
  });
}
