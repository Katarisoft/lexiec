import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/app_routes.dart';
import '../common/format.dart';
import '../common/view_state.dart';
import '../common/widgets/error_banner.dart';
import '../common/widgets/state_views.dart';
import 'assistant_controllers.dart';

Future<bool> confirmDeletion(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Eliminar consulta'),
      content: const Text(
        'Se eliminarán la pregunta, la respuesta y sus citas de tu historial. '
        '¿Continuar?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('consultation-delete-confirm'),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final HistoryController controller = Get.find();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi historial'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: controller.load,
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          switch (controller.state.value) {
            case ViewState.loading:
              return const LoadingView(message: 'Cargando historial…');
            case ViewState.error:
              return ErrorView(
                message: controller.failure.value!.message,
                onRetry: controller.load,
              );
            case ViewState.empty:
              return const EmptyView(
                icon: Icons.history,
                message: 'Aún no has hecho consultas. Tu historial es privado.',
              );
            case ViewState.data:
              final error = controller.actionError.value;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Solo tú puedes ver estas consultas.'),
                  const SizedBox(height: 8),
                  if (error != null) ErrorBanner(message: error),
                  for (final item in controller.items)
                    Card(
                      key: Key('history-${item.id}'),
                      child: ListTile(
                        title: Text(
                          item.question,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${item.area.name} · ${item.statusLabel} · '
                          '${formatDate(item.createdAt)}',
                        ),
                        onTap: () async {
                          await Get.toNamed<void>(
                            AppRoutes.consultation,
                            arguments: item.id,
                          );
                          controller.load();
                        },
                        trailing: IconButton(
                          key: Key('history-delete-${item.id}'),
                          tooltip: 'Eliminar',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            if (await confirmDeletion(context)) {
                              await controller.delete(item.id);
                            }
                          },
                        ),
                      ),
                    ),
                  if (controller.hasNext.value)
                    TextButton(
                      onPressed: controller.loadMore,
                      child: const Text('Ver más'),
                    ),
                ],
              );
          }
        }),
      ),
    );
  }
}
