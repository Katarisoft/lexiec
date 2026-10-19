import 'package:lexiec/data/models/local_library.dart';
import 'package:lexiec/data/services/local_library_store.dart';

/// Almacén local en memoria con datos separados por cuenta (solo pruebas).
class InMemoryLocalLibraryStore implements LocalLibraryStore {
  final Map<int, Map<int, FavoriteTopic>> _favorites = {};
  final Map<int, Map<int, TopicNote>> _notes = {};
  int? _userId;

  @override
  int? get openUserId => _userId;

  @override
  Future<void> open(int userId) async => _userId = userId;

  @override
  Future<void> close() async => _userId = null;

  Map<int, FavoriteTopic> get _fav =>
      _favorites.putIfAbsent(_userId!, () => {});
  Map<int, TopicNote> get _note => _notes.putIfAbsent(_userId!, () => {});

  @override
  List<FavoriteTopic> favorites() =>
      _fav.values.toList()..sort((a, b) => b.savedAt.compareTo(a.savedAt));

  @override
  Future<void> saveFavorite(FavoriteTopic favorite) async =>
      _fav[favorite.topicId] = favorite;

  @override
  Future<void> removeFavorite(int topicId) async => _fav.remove(topicId);

  @override
  List<TopicNote> notes() => _note.values.toList();

  @override
  Future<void> saveNote(TopicNote note) async => _note[note.topicId] = note;

  @override
  Future<void> removeNote(int topicId) async => _note.remove(topicId);

  @override
  Future<void> deleteOpenAccountData() async {
    _favorites.remove(_userId);
    _notes.remove(_userId);
    _userId = null;
  }
}
