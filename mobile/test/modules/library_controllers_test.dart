import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiec/core/config/app_config.dart';
import 'package:lexiec/core/errors/api_failure.dart';
import 'package:lexiec/core/network/api_client.dart';
import 'package:lexiec/data/models/library_models.dart';
import 'package:lexiec/data/repositories/library_repository.dart';
import 'package:lexiec/data/services/library_service.dart';
import 'package:lexiec/modules/common/view_state.dart';
import 'package:lexiec/modules/library/library_controllers.dart';

import '../support/fake_http_adapter.dart';
import '../support/in_memory_token_storage.dart';
import '../support/library_fixtures.dart';

void main() {
  late FakeHttpAdapter adapter;
  late LibraryRepository repository;

  setUp(() {
    adapter = FakeHttpAdapter((o) async => emptyResponse(200));
    final client = ApiClient(
      config: const AppConfig(serverUrl: 'http://servidor.invalid'),
      tokenStorage: InMemoryTokenStorage(),
      onSessionExpired: () {},
      adapter: adapter,
    );
    repository = LibraryRepository(LibraryService(client.dio));
  });

  group('AreasController', () {
    test('pasa de carga a datos', () async {
      final gate = Completer<void>();
      adapter.handler = (o) async {
        await gate.future;
        return jsonResponse(200, [areaJson(1), areaJson(2)]);
      };
      final controller = AreasController(repository)..onInit();
      expect(controller.state.value, ViewState.loading);
      gate.complete();
      await pumpEventQueue();
      expect(controller.state.value, ViewState.data);
      expect(controller.areas.length, 2);
    });

    test('lista vacía es estado vacío, no error', () async {
      adapter.handler = (o) async => jsonResponse(200, []);
      final controller = AreasController(repository);
      await controller.load();
      expect(controller.state.value, ViewState.empty);
    });

    test('error y reintento', () async {
      adapter.handler = (options) async => networkError(options);
      final controller = AreasController(repository);
      await controller.load();
      expect(controller.state.value, ViewState.error);
      expect(controller.failure.value!.kind, FailureKind.network);

      adapter.handler = (o) async => jsonResponse(200, [areaJson(1)]);
      await controller.load();
      expect(controller.state.value, ViewState.data);
      expect(controller.failure.value, isNull);
    });
  });

  group('TopicListController', () {
    const area = AreaSummary(slug: 'area-1', name: 'Área ficticia 1');

    test('filtra por área y busca al enviar', () async {
      adapter.handler = (o) async => jsonResponse(200, topicPageJson([1, 2]));
      final controller = TopicListController(repository, area: area);
      await controller.load();
      expect(adapter.requests.last.queryParameters, {'area': 'area-1'});

      await controller.search('  plazos ');
      expect(adapter.requests.last.queryParameters, {
        'area': 'area-1',
        'search': 'plazos',
      });
      expect(controller.state.value, ViewState.data);
    });

    test('rechaza búsquedas demasiado largas sin llamar al servidor', () async {
      final controller = TopicListController(repository);
      await controller.search('x' * 101);
      expect(controller.searchError.value, isNotNull);
      expect(adapter.requests, isEmpty);
    });

    test('sin resultados de búsqueda es estado vacío', () async {
      adapter.handler = (o) async => jsonResponse(200, topicPageJson([]));
      final controller = TopicListController(repository);
      await controller.search('nada');
      expect(controller.state.value, ViewState.empty);
      expect(controller.query.value, 'nada');
    });

    test('carga más páginas y conserva lo cargado si falla', () async {
      adapter.handler = (o) async =>
          jsonResponse(200, topicPageJson([1, 2], count: 3, hasNext: true));
      final controller = TopicListController(repository);
      await controller.load();
      expect(controller.hasNext.value, isTrue);

      adapter.handler = (options) async => networkError(options);
      await controller.loadMore();
      expect(controller.topics.length, 2);
      expect(controller.loadMoreFailure.value, isNotNull);
      expect(controller.state.value, ViewState.data);

      adapter.handler = (o) async =>
          jsonResponse(200, topicPageJson([3], count: 3));
      await controller.loadMore();
      expect(controller.topics.map((t) => t.id), [1, 2, 3]);
      expect(controller.hasNext.value, isFalse);
      expect(adapter.requests.last.queryParameters['page'], 2);
    });

    test('un área inexistente (422) es error, no vacío', () async {
      adapter.handler = (o) async =>
          apiError(422, 'unknown_area', message: 'El área indicada no existe.');
      final controller = TopicListController(repository, area: area);
      await controller.load();
      expect(controller.state.value, ViewState.error);
      expect(controller.failure.value!.kind, FailureKind.unprocessable);
      expect(controller.failure.value!.message, 'El área indicada no existe.');
    });
  });

  group('TopicDetailController', () {
    test('carga la ficha con sus fuentes', () async {
      adapter.handler = (o) async => jsonResponse(200, topicDetailJson(3));
      final controller = TopicDetailController(repository, FakeLinkOpener(), 3);
      await controller.load();
      expect(adapter.requests.last.path, 'topics/3/');
      expect(
        controller.topic.value!.sources.single.document.validityLabel,
        'Vigencia no comprobada',
      );
    });

    test('ficha no disponible (404) es error', () async {
      adapter.handler = (o) async => apiError(404, 'not_found');
      final controller = TopicDetailController(repository, FakeLinkOpener(), 9);
      await controller.load();
      expect(controller.state.value, ViewState.error);
      expect(controller.failure.value!.kind, FailureKind.notFound);
    });

    test('informa si no se pudo abrir el enlace', () async {
      final opener = FakeLinkOpener(result: false);
      final controller = TopicDetailController(repository, opener, 3);
      await controller.openSource('https://ejemplo.invalid/doc');
      expect(opener.opened, ['https://ejemplo.invalid/doc']);
      expect(controller.linkError.value, isNotNull);

      opener.result = true;
      await controller.openSource('https://ejemplo.invalid/doc');
      expect(controller.linkError.value, isNull);
    });
  });

  test('el servicio no envía parámetros vacíos', () async {
    adapter.handler = (o) async => jsonResponse(200, topicPageJson([]));
    await repository.topics(search: '   ');
    expect(adapter.requests.last.queryParameters, isEmpty);
    expect(adapter.requests.last.method, 'GET');
    expect(adapter.requests.last.responseType, ResponseType.json);
  });
}
