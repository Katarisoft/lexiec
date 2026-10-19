import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../common/format.dart';
import '../common/view_state.dart';
import '../common/widgets/academic_notice.dart';
import '../common/widgets/error_banner.dart';
import '../common/widgets/state_views.dart';
import 'assistant_controllers.dart';
import 'consultation_result_view.dart';
import 'history_screen.dart';

class ConsultationDetailScreen extends StatelessWidget {
  const ConsultationDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ConsultationDetailController controller = Get.find();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consulta'),
        actions: [
          IconButton(
            key: const Key('consultation-delete'),
            tooltip: 'Eliminar',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              if (await confirmDeletion(context) && await controller.delete()) {
                Get.back<void>();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          switch (controller.state.value) {
            case ViewState.loading:
            case ViewState.empty:
              return const LoadingView(message: 'Cargando consulta…');
            case ViewState.error:
              return ErrorView(
                message: controller.failure.value!.message,
                onRetry: controller.load,
              );
            case ViewState.data:
              final item = controller.consultation.value!;
              final error = controller.actionError.value;
              final text = Theme.of(context).textTheme;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (error != null) ErrorBanner(message: error),
                  Text(item.question, style: text.titleMedium),
                  Text(
                    '${item.area.name} · ${formatDate(item.createdAt)}',
                    style: text.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Respuesta guardada en tu historial; puede no reflejar '
                    'cambios posteriores en la colección.',
                    style: text.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  ConsultationResultView(consultation: item),
                  const SizedBox(height: 24),
                  const AcademicNotice(),
                ],
              );
          }
        }),
      ),
    );
  }
}
