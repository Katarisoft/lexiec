import 'package:flutter_test/flutter_test.dart';
import 'package:lexiec/data/models/library_models.dart';
import 'package:lexiec/data/repositories/local_library_repository.dart';
import 'package:lexiec/modules/local_library/local_library_controller.dart';

import '../support/in_memory_local_store.dart';
import '../support/library_fixtures.dart';

void main() {
  late LocalLibraryController controller;
  final topic = TopicDetail.fromJson(topicDetailJson(1));

  setUp(() {
    controller = LocalLibraryController(
      LocalLibraryRepository(
        InMemoryLocalLibraryStore(),
        clock: () => DateTime.utc(2026, 10, 19, 12),
      ),
    );
  });

  test('guarda y quita favoritos con copia mínima y fecha', () async {
    await controller.activateFor(1);
    await controller.toggleFavorite(topic);
    final saved = controller.favorites.single;
    expect(saved.title, 'Ficha ficticia 1');
    expect(saved.areaName, 'Área ficticia 1');
    expect(saved.savedAt, DateTime.utc(2026, 10, 19, 12));
    expect(controller.isFavorite(1), isTrue);

    await controller.toggleFavorite(topic);
    expect(controller.favorites, isEmpty);
  });

  test('una nota vacía elimina la nota', () async {
    await controller.activateFor(1);
    await controller.saveNote(1, '  Nota ficticia  ');
    expect(controller.noteFor(1)!.text, 'Nota ficticia');
    await controller.saveNote(1, '   ');
    expect(controller.noteFor(1), isNull);
  });

  test('cambio de cuenta: B no ve datos de A y A los recupera', () async {
    await controller.activateFor(1);
    await controller.toggleFavorite(topic);
    await controller.saveNote(1, 'Nota de A');

    await controller.deactivate();
    expect(controller.favorites, isEmpty);
    expect(controller.notes, isEmpty);
    expect(controller.isReady.value, isFalse);

    await controller.activateFor(2);
    expect(controller.favorites, isEmpty);
    expect(controller.noteFor(1), isNull);
    await controller.deactivate();

    await controller.activateFor(1);
    expect(controller.isFavorite(1), isTrue);
    expect(controller.noteFor(1)!.text, 'Nota de A');
  });

  test(
    'borrar datos locales de la cuenta los elimina y sigue operativo',
    () async {
      await controller.activateFor(1);
      await controller.toggleFavorite(topic);
      await controller.deleteAccountData();
      expect(controller.favorites, isEmpty);
      expect(controller.isReady.value, isTrue);

      await controller.toggleFavorite(topic);
      expect(controller.isFavorite(1), isTrue);
    },
  );

  test('sin cuenta activa no guarda nada', () async {
    await controller.toggleFavorite(topic);
    await controller.saveNote(1, 'x');
    expect(controller.favorites, isEmpty);
    expect(controller.notes, isEmpty);
  });
}
