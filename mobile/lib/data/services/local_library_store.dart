import 'package:hive_ce/hive_ce.dart';

import '../models/local_library.dart';

/// Almacén local de favoritos y notas de UNA cuenta a la vez.
///
/// Hive no es almacenamiento seguro: aquí nunca se guardan tokens ni
/// conversaciones jurídicas, solo copias mínimas de fichas y notas.
abstract class LocalLibraryStore {
  /// Abre las cajas de [userId]. Cierra antes las de otra cuenta.
  Future<void> open(int userId);

  /// Cierra las cajas sin borrar los datos del disco.
  Future<void> close();

  int? get openUserId;

  List<FavoriteTopic> favorites();
  Future<void> saveFavorite(FavoriteTopic favorite);
  Future<void> removeFavorite(int topicId);

  List<TopicNote> notes();
  Future<void> saveNote(TopicNote note);
  Future<void> removeNote(int topicId);

  /// Borra del disco los datos locales de la cuenta abierta.
  Future<void> deleteOpenAccountData();
}

/// Implementación con Hive: una caja de favoritos y otra de notas por
/// cuenta (`lexiec_favorites_u<id>`, `lexiec_notes_u<id>`).
class HiveLocalLibraryStore implements LocalLibraryStore {
  Box<Map<dynamic, dynamic>>? _favorites;
  Box<Map<dynamic, dynamic>>? _notes;
  int? _userId;

  static String favoritesBox(int userId) => 'lexiec_favorites_u$userId';
  static String notesBox(int userId) => 'lexiec_notes_u$userId';

  @override
  int? get openUserId => _userId;

  @override
  Future<void> open(int userId) async {
    if (_userId == userId && _favorites != null) return;
    await close();
    _favorites = await Hive.openBox<Map<dynamic, dynamic>>(
      favoritesBox(userId),
    );
    _notes = await Hive.openBox<Map<dynamic, dynamic>>(notesBox(userId));
    _userId = userId;
  }

  @override
  Future<void> close() async {
    await _favorites?.close();
    await _notes?.close();
    _favorites = null;
    _notes = null;
    _userId = null;
  }

  Box<Map<dynamic, dynamic>> get _favoritesBox =>
      _favorites ?? (throw StateError('No hay cuenta abierta'));
  Box<Map<dynamic, dynamic>> get _notesBox =>
      _notes ?? (throw StateError('No hay cuenta abierta'));

  @override
  List<FavoriteTopic> favorites() {
    final items = _favoritesBox.values.map(FavoriteTopic.fromMap).toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return items;
  }

  @override
  Future<void> saveFavorite(FavoriteTopic favorite) =>
      _favoritesBox.put(favorite.topicId, favorite.toMap());

  @override
  Future<void> removeFavorite(int topicId) => _favoritesBox.delete(topicId);

  @override
  List<TopicNote> notes() => _notesBox.values.map(TopicNote.fromMap).toList();

  @override
  Future<void> saveNote(TopicNote note) =>
      _notesBox.put(note.topicId, note.toMap());

  @override
  Future<void> removeNote(int topicId) => _notesBox.delete(topicId);

  @override
  Future<void> deleteOpenAccountData() async {
    final favorites = _favoritesBox;
    final notes = _notesBox;
    await favorites.deleteFromDisk();
    await notes.deleteFromDisk();
    _favorites = null;
    _notes = null;
    _userId = null;
  }
}
