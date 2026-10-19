import 'package:get/get.dart';

import '../../data/models/library_models.dart';
import '../../data/models/local_library.dart';
import '../../data/repositories/local_library_repository.dart';

/// Estado compartido de favoritos y notas de la cuenta con sesión.
///
/// Al cerrar sesión se cierran las cajas y se vacía la memoria; los datos
/// permanecen en el dispositivo para esa cuenta hasta su borrado explícito.
class LocalLibraryController extends GetxController {
  LocalLibraryController(this._repository);

  final LocalLibraryRepository _repository;

  final favorites = <FavoriteTopic>[].obs;
  final notes = <int, TopicNote>{}.obs;
  final isReady = false.obs;
  final error = RxnString();

  Future<void> activateFor(int userId) async {
    error.value = null;
    try {
      await _repository.openFor(userId);
      favorites.assignAll(_repository.favorites());
      notes
        ..clear()
        ..addAll({for (final note in _repository.notes()) note.topicId: note});
      isReady.value = true;
    } on Object {
      _clearMemory();
      error.value =
          'No se pudieron cargar tus datos guardados en el dispositivo.';
    }
  }

  Future<void> deactivate() async {
    _clearMemory();
    await _repository.close();
  }

  bool isFavorite(int topicId) => favorites.any((f) => f.topicId == topicId);

  TopicNote? noteFor(int topicId) => notes[topicId];

  Future<void> toggleFavorite(TopicDetail topic) async {
    if (!isReady.value) return;
    if (isFavorite(topic.id)) {
      await _repository.removeFavorite(topic.id);
      favorites.removeWhere((f) => f.topicId == topic.id);
    } else {
      final saved = await _repository.addFavorite(topic);
      favorites.insert(0, saved);
    }
  }

  Future<void> removeFavorite(int topicId) async {
    if (!isReady.value) return;
    await _repository.removeFavorite(topicId);
    favorites.removeWhere((f) => f.topicId == topicId);
  }

  Future<void> saveNote(int topicId, String text) async {
    if (!isReady.value) return;
    final saved = await _repository.saveNote(topicId, text);
    if (saved == null) {
      notes.remove(topicId);
    } else {
      notes[topicId] = saved;
    }
  }

  /// Borra del dispositivo los favoritos y notas de la cuenta actual.
  Future<void> deleteAccountData() async {
    final userId = _repository.openUserId;
    if (userId == null) return;
    await _repository.deleteAccountData();
    _clearMemory();
    // Se reabre vacío para seguir usando la app con la misma cuenta.
    await activateFor(userId);
  }

  void _clearMemory() {
    favorites.clear();
    notes.clear();
    isReady.value = false;
  }
}
