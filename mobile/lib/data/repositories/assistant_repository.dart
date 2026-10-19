import '../models/consultation.dart';
import '../services/assistant_service.dart';

/// El historial es privado y vive en el servidor: no se guarda en el
/// dispositivo (ni en Hive) para que otra cuenta nunca lo vea.
class AssistantRepository {
  AssistantRepository(this._service);

  final AssistantService _service;

  Future<ConsultationDetail> ask({
    required String areaSlug,
    required String question,
    required String requestId,
  }) => _service.ask(
    areaSlug: areaSlug,
    question: question.trim(),
    requestId: requestId,
  );

  Future<ConsultationPage> history({int page = 1}) =>
      _service.history(page: page);

  Future<ConsultationDetail> detail(int id) => _service.detail(id);

  Future<void> delete(int id) => _service.delete(id);
}
