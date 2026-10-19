import '../models/library_models.dart';
import '../services/library_service.dart';

/// Acceso a la biblioteca publicada. Punto de extensión para la caché
/// local de E12 (favoritos con copia guardada).
class LibraryRepository {
  LibraryRepository(this._service);

  final LibraryService _service;

  Future<List<LegalArea>> areas() => _service.areas();

  Future<TopicPage> topics({String? area, String? search, int page = 1}) =>
      _service.topics(area: area, search: search?.trim(), page: page);

  Future<TopicDetail> topic(int id) => _service.topic(id);
}
