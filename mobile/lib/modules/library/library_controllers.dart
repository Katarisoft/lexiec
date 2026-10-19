import 'package:get/get.dart';

import '../../core/errors/api_failure.dart';
import '../../core/services/link_opener.dart';
import '../../data/models/library_models.dart';
import '../../data/repositories/library_repository.dart';
import '../common/view_state.dart';

/// Áreas jurídicas (pantalla de inicio).
class AreasController extends GetxController {
  AreasController(this._repository);

  final LibraryRepository _repository;

  final state = ViewState.loading.obs;
  final areas = <LegalArea>[].obs;
  final failure = Rxn<ApiFailure>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    state.value = ViewState.loading;
    failure.value = null;
    try {
      final result = await _repository.areas();
      areas.assignAll(result);
      state.value = result.isEmpty ? ViewState.empty : ViewState.data;
    } on ApiFailure catch (error) {
      failure.value = error;
      state.value = ViewState.error;
    }
  }
}

/// Listado paginado y buscable de fichas, opcionalmente de un área.
class TopicListController extends GetxController {
  TopicListController(this._repository, {this.area});

  final LibraryRepository _repository;
  final AreaSummary? area;

  static const maxSearchLength = 100;

  final state = ViewState.loading.obs;
  final topics = <TopicSummary>[].obs;
  final total = 0.obs;
  final hasNext = false.obs;
  final isLoadingMore = false.obs;
  final failure = Rxn<ApiFailure>();
  final loadMoreFailure = Rxn<ApiFailure>();
  final searchError = RxnString();
  final query = ''.obs;

  int _page = 1;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// Aplica una búsqueda explícita (al enviar, no al escribir).
  Future<void> search(String text) async {
    final trimmed = text.trim();
    if (trimmed.length > maxSearchLength) {
      searchError.value = 'Usa como máximo $maxSearchLength caracteres.';
      return;
    }
    searchError.value = null;
    query.value = trimmed;
    await load();
  }

  Future<void> load() async {
    state.value = ViewState.loading;
    failure.value = null;
    loadMoreFailure.value = null;
    _page = 1;
    try {
      final page = await _repository.topics(
        area: area?.slug,
        search: query.value,
      );
      topics.assignAll(page.results);
      total.value = page.count;
      hasNext.value = page.hasNext;
      state.value = page.results.isEmpty ? ViewState.empty : ViewState.data;
    } on ApiFailure catch (error) {
      topics.clear();
      failure.value = error;
      state.value = ViewState.error;
    }
  }

  Future<void> loadMore() async {
    if (!hasNext.value || isLoadingMore.value) return;
    isLoadingMore.value = true;
    loadMoreFailure.value = null;
    try {
      final page = await _repository.topics(
        area: area?.slug,
        search: query.value,
        page: _page + 1,
      );
      _page += 1;
      topics.addAll(page.results);
      hasNext.value = page.hasNext;
    } on ApiFailure catch (error) {
      // Se conservan las fichas ya cargadas; se puede reintentar.
      loadMoreFailure.value = error;
    } finally {
      isLoadingMore.value = false;
    }
  }
}

/// Detalle de una ficha con sus fuentes oficiales.
class TopicDetailController extends GetxController {
  TopicDetailController(this._repository, this._linkOpener, this.topicId);

  final LibraryRepository _repository;
  final LinkOpener _linkOpener;
  final int topicId;

  final state = ViewState.loading.obs;
  final topic = Rxn<TopicDetail>();
  final failure = Rxn<ApiFailure>();
  final linkError = RxnString();

  /// URL cuyo intento de apertura falló, para mostrar el aviso junto a ella.
  final failedUrl = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    state.value = ViewState.loading;
    failure.value = null;
    try {
      topic.value = await _repository.topic(topicId);
      state.value = ViewState.data;
    } on ApiFailure catch (error) {
      failure.value = error;
      state.value = ViewState.error;
    }
  }

  Future<void> openSource(String url) async {
    linkError.value = null;
    failedUrl.value = null;
    final opened = await _linkOpener.open(url);
    if (!opened) {
      failedUrl.value = url;
      linkError.value =
          'No se pudo abrir el enlace oficial. Puedes copiarlo y abrirlo en tu navegador.';
    }
  }
}
