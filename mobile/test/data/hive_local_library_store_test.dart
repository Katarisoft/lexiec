import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:lexiec/data/models/local_library.dart';
import 'package:lexiec/data/services/local_library_store.dart';

/// Pruebas con Hive real sobre un directorio temporal.
void main() {
  late Directory dir;
  late HiveLocalLibraryStore store;

  FavoriteTopic favorite(int id) => FavoriteTopic(
    topicId: id,
    title: 'Ficha ficticia $id',
    areaName: 'Área ficticia',
    summary: 'Resumen ficticio.',
    savedAt: DateTime.utc(2026, 10, 19, 10, id),
  );

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('lexiec_hive_test');
    Hive.init(dir.path);
    store = HiveLocalLibraryStore();
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test(
    'persiste tras cerrar y reabrir Hive (equivale a reiniciar la app)',
    () async {
      await store.open(1);
      await store.saveFavorite(favorite(10));
      await store.saveNote(
        TopicNote(
          topicId: 10,
          text: 'Nota ficticia.',
          updatedAt: DateTime.utc(2026),
        ),
      );
      await Hive.close();

      Hive.init(dir.path);
      final reopened = HiveLocalLibraryStore();
      await reopened.open(1);
      expect(reopened.favorites().single.title, 'Ficha ficticia 10');
      expect(reopened.notes().single.text, 'Nota ficticia.');
    },
  );

  test('otra cuenta nunca ve los datos y la primera los recupera', () async {
    await store.open(1);
    await store.saveFavorite(favorite(10));
    await store.close();

    await store.open(2);
    expect(store.favorites(), isEmpty);
    expect(store.notes(), isEmpty);
    await store.saveFavorite(favorite(20));
    await store.close();

    await store.open(1);
    expect(store.favorites().map((f) => f.topicId), [10]);
  });

  test('cerrar no borra; borrar solo afecta a la cuenta abierta', () async {
    await store.open(1);
    await store.saveFavorite(favorite(10));
    await store.close();
    expect(Hive.isBoxOpen(HiveLocalLibraryStore.favoritesBox(1)), isFalse);

    await store.open(2);
    await store.saveFavorite(favorite(20));
    await store.deleteOpenAccountData();
    expect(store.openUserId, isNull);

    await store.open(2);
    expect(store.favorites(), isEmpty);
    await store.open(1);
    expect(store.favorites().single.topicId, 10);
  });

  test('ordena favoritos del más reciente al más antiguo', () async {
    await store.open(1);
    await store.saveFavorite(favorite(1));
    await store.saveFavorite(favorite(3));
    await store.saveFavorite(favorite(2));
    expect(store.favorites().map((f) => f.topicId), [3, 2, 1]);
  });

  test('sin cuenta abierta no permite leer ni escribir', () async {
    expect(() => store.favorites(), throwsStateError);
  });
}
