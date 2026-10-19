import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/app_routes.dart';
import '../common/view_state.dart';
import '../common/widgets/error_banner.dart';
import '../common/widgets/state_views.dart';
import 'library_controllers.dart';

class TopicListScreen extends StatefulWidget {
  const TopicListScreen({super.key});

  @override
  State<TopicListScreen> createState() => _TopicListScreenState();
}

class _TopicListScreenState extends State<TopicListScreen> {
  final TopicListController _controller = Get.find();
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final area = _controller.area;
    return Scaffold(
      appBar: AppBar(title: Text(area?.name ?? 'Todas las fichas')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Obx(
                () => TextField(
                  key: const Key('topic-search'),
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  maxLength: TopicListController.maxSearchLength + 1,
                  decoration: InputDecoration(
                    labelText: 'Buscar ficha',
                    counterText: '',
                    errorText: _controller.searchError.value,
                    suffixIcon: IconButton(
                      key: const Key('topic-search-submit'),
                      tooltip: 'Buscar',
                      icon: const Icon(Icons.search),
                      onPressed: () => _controller.search(_search.text),
                    ),
                  ),
                  onSubmitted: _controller.search,
                ),
              ),
            ),
            Expanded(child: Obx(_body)),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    switch (_controller.state.value) {
      case ViewState.loading:
        return const LoadingView(message: 'Cargando fichas…');
      case ViewState.error:
        return ErrorView(
          message: _controller.failure.value!.message,
          onRetry: _controller.load,
        );
      case ViewState.empty:
        final query = _controller.query.value;
        return EmptyView(
          icon: Icons.search_off,
          message: query.isEmpty
              ? 'Todavía no hay fichas publicadas aquí.'
              : 'No hay fichas que coincidan con «$query».',
        );
      case ViewState.data:
        return _list();
    }
  }

  Widget _list() {
    final topics = _controller.topics;
    return RefreshIndicator(
      onRefresh: _controller.load,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: topics.length + 1,
        itemBuilder: (context, index) {
          if (index == topics.length) return _footer();
          final topic = topics[index];
          return Card(
            child: ListTile(
              title: Text(topic.title),
              subtitle: Text(
                topic.summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  Get.toNamed<void>(AppRoutes.topic, arguments: topic.id),
            ),
          );
        },
      ),
    );
  }

  Widget _footer() {
    final failure = _controller.loadMoreFailure.value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(
            '${_controller.topics.length} de ${_controller.total.value} fichas',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (failure != null) ...[
            const SizedBox(height: 8),
            ErrorBanner(
              message: failure.message,
              onRetry: _controller.loadMore,
            ),
          ] else if (_controller.hasNext.value) ...[
            const SizedBox(height: 8),
            _controller.isLoadingMore.value
                ? const CircularProgressIndicator()
                : OutlinedButton(
                    key: const Key('load-more'),
                    onPressed: _controller.loadMore,
                    child: const Text('Cargar más'),
                  ),
          ],
        ],
      ),
    );
  }
}
