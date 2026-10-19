import 'package:get/get.dart';

import '../../core/errors/api_failure.dart';
import '../../core/utils/request_id.dart';
import '../../data/models/consultation.dart';
import '../../data/models/library_models.dart';
import '../../data/repositories/assistant_repository.dart';
import '../../data/repositories/library_repository.dart';
import '../common/view_state.dart';

const questionMaxLength = 1000;

/// Formulario del asistente. Envío solo explícito y sin reenvíos automáticos.
class AssistantController extends GetxController {
  AssistantController(
    this._library,
    this._assistant, {
    String Function()? requestIdFactory,
  }) : _newRequestId = requestIdFactory ?? newRequestId;

  final LibraryRepository _library;
  final AssistantRepository _assistant;
  final String Function() _newRequestId;

  final areasState = ViewState.loading.obs;
  final areas = <LegalArea>[].obs;
  final selectedArea = Rxn<LegalArea>();
  final acceptedNotice = false.obs;
  final isSending = false.obs;
  final result = Rxn<ConsultationDetail>();
  final failure = Rxn<ApiFailure>();
  final formError = RxnString();

  /// La última petición falló sin saber si el servidor la procesó.
  final uncertain = false.obs;

  String? _pendingRequestId;
  String? _pendingKey;
  String _lastQuestion = '';

  @override
  void onInit() {
    super.onInit();
    loadAreas();
  }

  Future<void> loadAreas() async {
    areasState.value = ViewState.loading;
    try {
      final loaded = await _library.areas();
      areas.assignAll(loaded);
      areasState.value = loaded.isEmpty ? ViewState.empty : ViewState.data;
    } on ApiFailure catch (error) {
      failure.value = error;
      areasState.value = ViewState.error;
    }
  }

  String? validate(String question) {
    final text = question.trim();
    if (selectedArea.value == null) return 'Elige un área.';
    if (text.isEmpty) return 'Escribe tu pregunta.';
    if (text.length > questionMaxLength) {
      return 'Usa como máximo $questionMaxLength caracteres.';
    }
    if (!acceptedNotice.value) {
      return 'Confirma que no incluyes datos personales.';
    }
    return null;
  }

  /// Envía la pregunta. Reutiliza el identificador si es un reintento de la
  /// misma pregunta y área, para que el servidor no la cobre dos veces.
  Future<void> send(String question) async {
    if (isSending.value) return;
    final invalid = validate(question);
    formError.value = invalid;
    if (invalid != null) return;

    final text = question.trim();
    final key = '${selectedArea.value!.slug}|$text';
    if (_pendingKey != key || _pendingRequestId == null) {
      _pendingKey = key;
      _pendingRequestId = _newRequestId();
    }
    _lastQuestion = text;

    isSending.value = true;
    failure.value = null;
    uncertain.value = false;
    try {
      result.value = await _assistant.ask(
        areaSlug: selectedArea.value!.slug,
        question: text,
        requestId: _pendingRequestId!,
      );
      // Consulta registrada: la próxima pregunta lleva un identificador nuevo.
      _pendingRequestId = null;
      _pendingKey = null;
    } on ApiFailure catch (error) {
      failure.value = error;
      // Red, tiempo agotado o 5xx: el servidor pudo procesarla. No se
      // reenvía solo; si la persona reintenta, se usa el mismo identificador.
      // `assistant_unavailable` (503) es un fallo cerrado ANTES de llamar al
      // proveedor: no hay cobro posible, así que no es incierto.
      uncertain.value =
          error.isRetryable && error.code != 'assistant_unavailable';
      if (error.code == 'request_id_conflict') _pendingRequestId = null;
    } finally {
      isSending.value = false;
    }
  }

  /// Reintento consciente tras un fallo incierto, con el mismo identificador.
  Future<void> retry() => send(_lastQuestion);

  void selectArea(LegalArea area) {
    selectedArea.value = area;
    formError.value = null;
  }

  void clearResult() {
    result.value = null;
    failure.value = null;
    uncertain.value = false;
  }

  /// Mensaje claro según el tipo de fallo (sin respaldo ≠ error técnico).
  String failureMessage(ApiFailure error) {
    return switch (error.code) {
      'user_quota_exceeded' =>
        'Alcanzaste el límite diario de consultas. Inténtalo mañana.',
      'budget_exhausted' =>
        'El asistente alcanzó su límite de uso. La biblioteca sigue disponible.',
      'assistant_unavailable' =>
        'El asistente no está disponible en este momento. La biblioteca sigue disponible.',
      _ when uncertain.value =>
        '${error.message} Es posible que la consulta se haya registrado: '
            'revisa tu historial o reintenta (no se cobrará dos veces).',
      _ => error.message,
    };
  }
}

/// Historial privado de la cuenta (solo servidor, sin copia local).
class HistoryController extends GetxController {
  HistoryController(this._assistant);

  final AssistantRepository _assistant;

  final state = ViewState.loading.obs;
  final items = <ConsultationSummary>[].obs;
  final hasNext = false.obs;
  final failure = Rxn<ApiFailure>();
  final actionError = RxnString();
  int _page = 1;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    state.value = ViewState.loading;
    failure.value = null;
    _page = 1;
    try {
      final page = await _assistant.history();
      items.assignAll(page.results);
      hasNext.value = page.hasNext;
      state.value = page.results.isEmpty ? ViewState.empty : ViewState.data;
    } on ApiFailure catch (error) {
      failure.value = error;
      state.value = ViewState.error;
    }
  }

  Future<void> loadMore() async {
    if (!hasNext.value) return;
    try {
      final page = await _assistant.history(page: _page + 1);
      _page += 1;
      items.addAll(page.results);
      hasNext.value = page.hasNext;
    } on ApiFailure catch (error) {
      actionError.value = error.message;
    }
  }

  /// Borra la consulta (tras confirmación en la interfaz).
  Future<bool> delete(int id) async {
    actionError.value = null;
    try {
      await _assistant.delete(id);
      items.removeWhere((item) => item.id == id);
      if (items.isEmpty) state.value = ViewState.empty;
      return true;
    } on ApiFailure catch (error) {
      actionError.value = error.message;
      return false;
    }
  }
}

/// Detalle de una consulta del historial.
class ConsultationDetailController extends GetxController {
  ConsultationDetailController(this._assistant, this.consultationId);

  final AssistantRepository _assistant;
  final int consultationId;

  final state = ViewState.loading.obs;
  final consultation = Rxn<ConsultationDetail>();
  final failure = Rxn<ApiFailure>();
  final actionError = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    state.value = ViewState.loading;
    failure.value = null;
    try {
      consultation.value = await _assistant.detail(consultationId);
      state.value = ViewState.data;
    } on ApiFailure catch (error) {
      failure.value = error;
      state.value = ViewState.error;
    }
  }

  Future<bool> delete() async {
    actionError.value = null;
    try {
      await _assistant.delete(consultationId);
      return true;
    } on ApiFailure catch (error) {
      actionError.value = error.message;
      return false;
    }
  }
}
