import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lexiec/core/config/app_config.dart';
import 'package:lexiec/core/network/api_client.dart';
import 'package:lexiec/data/models/consultation.dart';
import 'package:lexiec/data/repositories/assistant_repository.dart';
import 'package:lexiec/data/repositories/library_repository.dart';
import 'package:lexiec/data/services/assistant_service.dart';
import 'package:lexiec/data/services/library_service.dart';
import 'package:lexiec/modules/assistant/assistant_controllers.dart';
import 'package:lexiec/modules/common/view_state.dart';

import '../support/assistant_fixtures.dart';
import '../support/fake_http_adapter.dart';
import '../support/in_memory_token_storage.dart';
import '../support/library_fixtures.dart';

void main() {
  late FakeHttpAdapter adapter;
  late AssistantRepository assistant;
  late LibraryRepository library;
  late int idCounter;

  setUp(() {
    idCounter = 0;
    adapter = FakeHttpAdapter((options) async {
      if (options.path == 'areas/') {
        return jsonResponse(200, [areaJson(1)]);
      }
      return jsonResponse(201, consultationJson(1));
    });
    final client = ApiClient(
      config: const AppConfig(serverUrl: 'http://servidor.invalid'),
      tokenStorage: InMemoryTokenStorage(),
      onSessionExpired: () {},
      adapter: adapter,
    );
    assistant = AssistantRepository(AssistantService(client.dio));
    library = LibraryRepository(LibraryService(client.dio));
  });

  Future<AssistantController> ready() async {
    final controller = AssistantController(
      library,
      assistant,
      requestIdFactory: () => 'id-${++idCounter}',
    );
    await controller.loadAreas();
    controller.selectArea(controller.areas.single);
    controller.acceptedNotice.value = true;
    return controller;
  }

  Iterable<Map<dynamic, dynamic>> askBodies() => adapter.requests
      .where((r) => r.path == 'consultations/' && r.method == 'POST')
      .map((r) => r.data as Map);

  group('validación previa (sin llamar al servidor)', () {
    test(
      'exige área, pregunta, longitud y aviso de datos personales',
      () async {
        final controller = AssistantController(library, assistant);
        await controller.loadAreas();

        await controller.send('¿Pregunta?');
        expect(controller.formError.value, 'Elige un área.');

        controller.selectArea(controller.areas.single);
        await controller.send('   ');
        expect(controller.formError.value, 'Escribe tu pregunta.');

        await controller.send('x' * 1001);
        expect(controller.formError.value, contains('1000'));

        await controller.send('¿Pregunta?');
        expect(controller.formError.value, contains('datos personales'));
        expect(askBodies(), isEmpty);
      },
    );
  });

  test('envía área, pregunta e identificador y muestra la respuesta', () async {
    final controller = await ready();
    await controller.send('  ¿Pregunta ficticia?  ');
    expect(askBodies().single, {
      'area': 'area-1',
      'question': '¿Pregunta ficticia?',
      'client_request_id': 'id-1',
    });
    expect(controller.result.value!.state, ConsultationState.answered);
    expect(
      controller.result.value!.citations.single.locator,
      'Art. ficticio 1',
    );
  });

  test('una consulta nueva tras una correcta usa otro identificador', () async {
    final controller = await ready();
    await controller.send('¿Primera?');
    await controller.send('¿Segunda?');
    expect(askBodies().map((b) => b['client_request_id']), ['id-1', 'id-2']);
  });

  test(
    'sin red: estado incierto, sin reenvío automático y reintento con el mismo id',
    () async {
      final controller = await ready();
      adapter.handler = (options) async => options.path == 'consultations/'
          ? networkError(options)
          : jsonResponse(200, []);
      await controller.send('¿Pregunta?');

      expect(controller.uncertain.value, isTrue);
      expect(askBodies().length, 1);
      expect(
        controller.failureMessage(controller.failure.value!),
        contains('no se cobrará dos veces'),
      );

      adapter.handler = (o) async => jsonResponse(200, consultationJson(1));
      await controller.retry();
      expect(askBodies().map((b) => b['client_request_id']), ['id-1', 'id-1']);
      expect(controller.result.value, isNotNull);
      expect(controller.uncertain.value, isFalse);
    },
  );

  test(
    'cambiar la pregunta tras un fallo genera un identificador nuevo',
    () async {
      final controller = await ready();
      adapter.handler = (options) async => networkError(options);
      await controller.send('¿Pregunta A?');
      await controller.send('¿Pregunta B?');
      expect(askBodies().map((b) => b['client_request_id']), ['id-1', 'id-2']);
    },
  );

  test('ignora pulsaciones repetidas mientras consulta', () async {
    final controller = await ready();
    final gate = Completer<void>();
    adapter.handler = (options) async {
      await gate.future;
      return jsonResponse(201, consultationJson(1));
    };
    final first = controller.send('¿Pregunta?');
    await controller.send('¿Pregunta?');
    gate.complete();
    await first;
    expect(askBodies().length, 1);
  });

  test(
    'límites y no disponibilidad tienen mensajes propios y no son inciertos',
    () async {
      final controller = await ready();
      final cases = {
        () => apiError(429, 'user_quota_exceeded'): 'límite diario',
        () => apiError(429, 'budget_exhausted'): 'límite de uso',
        () => apiError(503, 'assistant_unavailable'): 'no está disponible',
      };
      for (final entry in cases.entries) {
        adapter.handler = (o) async => entry.key();
        await controller.send('¿Pregunta?');
        expect(controller.uncertain.value, isFalse);
        expect(
          controller.failureMessage(controller.failure.value!),
          contains(entry.value),
        );
      }
    },
  );

  test(
    'conflicto de identificador genera uno nuevo en el siguiente envío',
    () async {
      final controller = await ready();
      adapter.handler = (o) async => apiError(409, 'request_id_conflict');
      await controller.send('¿Pregunta?');
      adapter.handler = (o) async => jsonResponse(201, consultationJson(1));
      await controller.send('¿Pregunta?');
      expect(askBodies().map((b) => b['client_request_id']), ['id-1', 'id-2']);
    },
  );

  test('sin respaldo y error técnico se distinguen', () async {
    final controller = await ready();
    adapter.handler = (o) async =>
        jsonResponse(201, consultationJson(2, status: 'no_support'));
    await controller.send('¿Pregunta?');
    expect(controller.result.value!.state, ConsultationState.noSupport);

    adapter.handler = (o) async => jsonResponse(
      201,
      consultationJson(3, status: 'error', errorCode: 'provider_timeout'),
    );
    await controller.send('¿Otra?');
    expect(controller.result.value!.state, ConsultationState.error);
    expect(controller.result.value!.errorCode, 'provider_timeout');
  });

  group('historial', () {
    test('lista, vacía y borra', () async {
      adapter.handler = (options) async {
        if (options.method == 'DELETE') return emptyResponse(204);
        return jsonResponse(
          200,
          consultationPageJson([consultationJson(1), consultationJson(2)]),
        );
      };
      final history = HistoryController(assistant);
      await history.load();
      expect(history.items.length, 2);

      expect(await history.delete(1), isTrue);
      expect(adapter.requests.last.path, 'consultations/1/');
      expect(history.items.map((i) => i.id), [2]);
      await history.delete(2);
      expect(history.state.value, ViewState.empty);
    });

    test('una consulta ajena o borrada (404) es error en el detalle', () async {
      adapter.handler = (o) async => apiError(404, 'not_found');
      final detail = ConsultationDetailController(assistant, 99);
      await detail.load();
      expect(detail.state.value, ViewState.error);
    });
  });
}
