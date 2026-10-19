import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/app_routes.dart';
import '../../data/models/library_models.dart';
import '../auth/auth_controller.dart';
import '../common/view_state.dart';
import '../common/widgets/academic_notice.dart';
import '../common/widgets/state_views.dart';
import '../library/library_controllers.dart';

/// Inicio protegido: áreas de la biblioteca.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController auth = Get.find();
    final AreasController areas = Get.find();
    return Scaffold(
      appBar: AppBar(
        title: const Text('LexiEC'),
        actions: [
          IconButton(
            key: const Key('favorites'),
            tooltip: 'Mis favoritos',
            icon: const Icon(Icons.star_outline),
            onPressed: () => Get.toNamed<void>(AppRoutes.favorites),
          ),
          IconButton(
            key: const Key('search-all'),
            tooltip: 'Buscar en todas las fichas',
            icon: const Icon(Icons.search),
            onPressed: () => Get.toNamed<void>(AppRoutes.topics),
          ),
          IconButton(
            key: const Key('logout'),
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              Get.offAllNamed<void>(AppRoutes.login);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Obx(
                () => Text(
                  'Hola, ${auth.user.value?.visibleName ?? ''}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      key: const Key('open-assistant'),
                      onPressed: () => Get.toNamed<void>(AppRoutes.assistant),
                      icon: const Icon(Icons.question_answer),
                      label: const Text('Preguntar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('open-history-home'),
                      onPressed: () => Get.toNamed<void>(AppRoutes.history),
                      icon: const Icon(Icons.history),
                      label: const Text('Mi historial'),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text('O elige un área para consultar sus fichas.'),
            ),
            Expanded(
              child: Obx(() {
                switch (areas.state.value) {
                  case ViewState.loading:
                    return const LoadingView(message: 'Cargando áreas…');
                  case ViewState.error:
                    return ErrorView(
                      message: areas.failure.value!.message,
                      onRetry: areas.load,
                    );
                  case ViewState.empty:
                    return const EmptyView(
                      message: 'Aún no hay áreas disponibles.',
                    );
                  case ViewState.data:
                    return RefreshIndicator(
                      onRefresh: areas.load,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          for (final area in areas.areas) _AreaTile(area: area),
                        ],
                      ),
                    );
                }
              }),
            ),
            const Padding(padding: EdgeInsets.all(16), child: AcademicNotice()),
          ],
        ),
      ),
    );
  }
}

class _AreaTile extends StatelessWidget {
  const _AreaTile({required this.area});

  final LegalArea area;

  @override
  Widget build(BuildContext context) {
    final count = area.publishedTopics;
    return Card(
      child: ListTile(
        title: Text(area.name),
        subtitle: Text(
          count == 1 ? '1 ficha publicada' : '$count fichas publicadas',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Get.toNamed<void>(
          AppRoutes.topics,
          arguments: AreaSummary(slug: area.slug, name: area.name),
        ),
      ),
    );
  }
}
