import 'package:get/get.dart';

import '../../core/errors/api_failure.dart';
import '../../data/models/comment.dart';
import '../../data/repositories/community_repository.dart';
import '../common/view_state.dart';

/// Comentarios de una ficha. Sin tiempo real: se actualiza con recarga.
class CommentsController extends GetxController {
  CommentsController(this._repository, this.topicId);

  final CommunityRepository _repository;
  final int topicId;

  static const maxLength = 1000;

  final state = ViewState.loading.obs;
  final comments = <Comment>[].obs;
  final total = 0.obs;
  final hasNext = false.obs;
  final isLoadingMore = false.obs;
  final failure = Rxn<ApiFailure>();

  /// Envío de un comentario nuevo en curso (evita duplicados).
  final isPosting = false.obs;
  final postError = RxnString();

  /// Ids con edición o borrado en curso.
  final busyIds = <int>{}.obs;

  /// Error de la última edición o borrado.
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
    actionError.value = null;
    _page = 1;
    try {
      final page = await _repository.comments(topicId);
      comments.assignAll(page.results);
      total.value = page.count;
      hasNext.value = page.hasNext;
      state.value = page.results.isEmpty ? ViewState.empty : ViewState.data;
    } on ApiFailure catch (error) {
      failure.value = error;
      state.value = ViewState.error;
    }
  }

  Future<void> loadMore() async {
    if (!hasNext.value || isLoadingMore.value) return;
    isLoadingMore.value = true;
    try {
      final page = await _repository.comments(topicId, page: _page + 1);
      _page += 1;
      final known = comments.map((c) => c.id).toSet();
      comments.addAll(page.results.where((c) => !known.contains(c.id)));
      hasNext.value = page.hasNext;
    } on ApiFailure catch (error) {
      actionError.value = error.message;
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Borra el aviso del campo en cuanto la persona vuelve a escribir.
  void clearPostError() {
    if (postError.value != null) postError.value = null;
  }

  /// Valida localmente; devuelve el mensaje de error o `null`.
  static String? validate(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 'Escribe un comentario.';
    if (trimmed.length > maxLength) {
      return 'Usa como máximo $maxLength caracteres.';
    }
    return null;
  }

  /// Publica un comentario. Devuelve `true` si se publicó; si falla, la
  /// pantalla conserva el texto para reintentar conscientemente.
  Future<bool> post(String text) async {
    if (isPosting.value) return false;
    final invalid = validate(text);
    if (invalid != null) {
      postError.value = invalid;
      return false;
    }
    isPosting.value = true;
    postError.value = null;
    try {
      final created = await _repository.publish(topicId, text);
      comments.insert(0, created);
      total.value += 1;
      state.value = ViewState.data;
      return true;
    } on ApiFailure catch (error) {
      postError.value = _messageFor(error);
      return false;
    } finally {
      isPosting.value = false;
    }
  }

  /// Edita un comentario propio. Devuelve el mensaje de error o `null`.
  Future<String?> edit(int commentId, String text) async {
    final invalid = validate(text);
    if (invalid != null) return invalid;
    if (busyIds.contains(commentId)) return null;
    busyIds.add(commentId);
    actionError.value = null;
    try {
      final updated = await _repository.edit(commentId, text);
      final index = comments.indexWhere((c) => c.id == commentId);
      if (index >= 0) comments[index] = updated;
      return null;
    } on ApiFailure catch (error) {
      return _messageFor(error);
    } finally {
      busyIds.remove(commentId);
    }
  }

  /// Elimina un comentario propio (tras confirmación en la interfaz).
  Future<bool> remove(int commentId) async {
    if (busyIds.contains(commentId)) return false;
    busyIds.add(commentId);
    actionError.value = null;
    try {
      await _repository.remove(commentId);
      comments.removeWhere((c) => c.id == commentId);
      total.value = total.value > 0 ? total.value - 1 : 0;
      if (comments.isEmpty) state.value = ViewState.empty;
      return true;
    } on ApiFailure catch (error) {
      actionError.value = _messageFor(error);
      return false;
    } finally {
      busyIds.remove(commentId);
    }
  }

  String _messageFor(ApiFailure error) {
    final textErrors = error.fieldErrors['text'];
    if (textErrors != null && textErrors.isNotEmpty) return textErrors.first;
    return error.message;
  }
}
