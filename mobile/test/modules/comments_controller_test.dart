import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lexiec/core/config/app_config.dart';
import 'package:lexiec/core/network/api_client.dart';
import 'package:lexiec/data/repositories/community_repository.dart';
import 'package:lexiec/data/services/community_service.dart';
import 'package:lexiec/modules/common/view_state.dart';
import 'package:lexiec/modules/community/comments_controller.dart';

import '../support/community_fixtures.dart';
import '../support/fake_http_adapter.dart';
import '../support/in_memory_token_storage.dart';

void main() {
  late FakeHttpAdapter adapter;
  late CommentsController controller;

  setUp(() {
    adapter = FakeHttpAdapter(
      (o) async => jsonResponse(200, commentPageJson([])),
    );
    final client = ApiClient(
      config: const AppConfig(serverUrl: 'http://servidor.invalid'),
      tokenStorage: InMemoryTokenStorage(),
      onSessionExpired: () {},
      adapter: adapter,
    );
    controller = CommentsController(
      CommunityRepository(CommunityService(client.dio)),
      1,
    );
  });

  test('carga vacía y luego datos tras recargar', () async {
    await controller.load();
    expect(controller.state.value, ViewState.empty);

    // Otra cuenta publicó: se ve al recargar (sin tiempo real).
    adapter.handler = (o) async =>
        jsonResponse(200, commentPageJson([commentJson(1)]));
    await controller.load();
    expect(controller.state.value, ViewState.data);
    expect(controller.comments.single.authorName, 'Persona B');
    expect(controller.comments.single.isMine, isFalse);
  });

  test('publica, envía solo el texto y lo añade arriba', () async {
    await controller.load();
    adapter.handler = (o) async =>
        jsonResponse(201, commentJson(5, text: 'Hola', mine: true));

    expect(await controller.post('  Hola  '), isTrue);
    final request = adapter.requests.last;
    expect(request.method, 'POST');
    expect(request.path, 'topics/1/comments/');
    expect(request.data, {'text': 'Hola'});
    expect(controller.comments.first.id, 5);
    expect(controller.state.value, ViewState.data);
  });

  test('valida texto vacío y demasiado largo sin llamar al servidor', () async {
    await controller.load();
    final before = adapter.requests.length;
    expect(await controller.post('   '), isFalse);
    expect(controller.postError.value, 'Escribe un comentario.');
    expect(await controller.post('x' * 1001), isFalse);
    expect(adapter.requests.length, before);
  });

  test('si falla la publicación informa y no añade nada', () async {
    await controller.load();
    adapter.handler = (options) async => networkError(options);
    expect(await controller.post('Hola'), isFalse);
    expect(controller.postError.value, contains('No hay conexión'));
    expect(controller.comments, isEmpty);
    expect(controller.isPosting.value, isFalse);
  });

  test('ignora pulsaciones repetidas mientras publica', () async {
    await controller.load();
    final gate = Completer<void>();
    adapter.handler = (o) async {
      await gate.future;
      return jsonResponse(201, commentJson(5, mine: true));
    };
    final first = controller.post('Hola');
    expect(await controller.post('Hola'), isFalse);
    gate.complete();
    expect(await first, isTrue);
    expect(adapter.countPath('topics/1/comments/'), 2); // carga + 1 envío
  });

  test('edita y reemplaza el comentario', () async {
    adapter.handler = (o) async =>
        jsonResponse(200, commentPageJson([commentJson(5, mine: true)]));
    await controller.load();
    adapter.handler = (o) async => jsonResponse(
      200,
      commentJson(5, text: 'Editado', mine: true, edited: true),
    );

    expect(await controller.edit(5, 'Editado'), isNull);
    expect(adapter.requests.last.method, 'PATCH');
    expect(adapter.requests.last.path, 'comments/5/');
    expect(controller.comments.single.text, 'Editado');
    expect(controller.comments.single.edited, isTrue);
  });

  test('403 al editar o borrar algo ajeno muestra el motivo', () async {
    adapter.handler = (o) async =>
        jsonResponse(200, commentPageJson([commentJson(7)]));
    await controller.load();
    adapter.handler = (o) async => apiError(
      403,
      'permission_denied',
      message: 'No tienes permiso para realizar esta acción.',
    );

    expect(await controller.edit(7, 'Intento'), contains('permiso'));
    expect(await controller.remove(7), isFalse);
    expect(controller.actionError.value, contains('permiso'));
    expect(controller.comments.single.text, 'Comentario ficticio.');
  });

  test('borra y pasa a vacío al quitar el último', () async {
    adapter.handler = (o) async =>
        jsonResponse(200, commentPageJson([commentJson(5, mine: true)]));
    await controller.load();
    adapter.handler = (o) async => emptyResponse(204);

    expect(await controller.remove(5), isTrue);
    expect(adapter.requests.last.method, 'DELETE');
    expect(controller.comments, isEmpty);
    expect(controller.state.value, ViewState.empty);
  });

  test('ficha no publicada (404) es error con reintento', () async {
    adapter.handler = (o) async => apiError(404, 'not_found');
    await controller.load();
    expect(controller.state.value, ViewState.error);
  });

  test('ver más añade la página siguiente sin duplicar', () async {
    adapter.handler = (o) async => jsonResponse(
      200,
      commentPageJson(
        [commentJson(2), commentJson(1)],
        count: 3,
        hasNext: true,
      ),
    );
    await controller.load();
    adapter.handler = (o) async =>
        jsonResponse(200, commentPageJson([commentJson(1), commentJson(0)]));
    await controller.loadMore();
    expect(controller.comments.map((c) => c.id), [2, 1, 0]);
    expect(adapter.requests.last.queryParameters['page'], 2);
  });
}
