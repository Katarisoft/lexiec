import '../models/library_models.dart';
import '../models/local_library.dart';
import '../services/local_library_store.dart';

/// Favoritos y notas locales de la cuenta activa.
class LocalLibraryRepository {
  LocalLibraryRepository(this._store, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final LocalLibraryStore _store;
  final DateTime Function() _clock;

  static const noteMaxLength = 2000;

  Future<void> openFor(int userId) => _store.open(userId);
  Future<void> close() => _store.close();
  int? get openUserId => _store.openUserId;

  List<FavoriteTopic> favorites() => _store.favorites();
  List<TopicNote> notes() => _store.notes();

  /// Guarda una copia mínima de la ficha con la fecha de guardado.
  Future<FavoriteTopic> addFavorite(TopicDetail topic) async {
    final favorite = FavoriteTopic(
      topicId: topic.id,
      title: topic.title,
      areaName: topic.area.name,
      summary: topic.summary,
      savedAt: _clock(),
    );
    await _store.saveFavorite(favorite);
    return favorite;
  }

  Future<void> removeFavorite(int topicId) => _store.removeFavorite(topicId);

  /// Guarda la nota; un texto vacío la elimina. Devuelve `null` si se borró.
  Future<TopicNote?> saveNote(int topicId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      await _store.removeNote(topicId);
      return null;
    }
    final note = TopicNote(
      topicId: topicId,
      text: trimmed.length > noteMaxLength
          ? trimmed.substring(0, noteMaxLength)
          : trimmed,
      updatedAt: _clock(),
    );
    await _store.saveNote(note);
    return note;
  }

  Future<void> deleteAccountData() => _store.deleteOpenAccountData();
}
