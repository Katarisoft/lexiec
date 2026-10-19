import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/app_routes.dart';
import '../common/view_state.dart';
import '../common/widgets/academic_notice.dart';
import '../common/widgets/error_banner.dart';
import '../common/widgets/state_views.dart';
import 'assistant_controllers.dart';
import 'consultation_result_view.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final AssistantController _controller = Get.find();
  final _question = TextEditingController();

  @override
  void dispose() {
    _question.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistente'),
        actions: [
          IconButton(
            key: const Key('open-history'),
            tooltip: 'Mi historial',
            icon: const Icon(Icons.history),
            onPressed: () => Get.toNamed<void>(AppRoutes.history),
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          switch (_controller.areasState.value) {
            case ViewState.loading:
              return const LoadingView(message: 'Cargando áreas…');
            case ViewState.error:
              return ErrorView(
                message: _controller.failure.value!.message,
                onRetry: _controller.loadAreas,
              );
            case ViewState.empty:
              return const EmptyView(message: 'Aún no hay áreas disponibles.');
            case ViewState.data:
              return _form(context);
          }
        }),
      ),
    );
  }

  Widget _form(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final sending = _controller.isSending.value;
    final failure = _controller.failure.value;
    final result = _controller.result.value;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Responde solo con la colección revisada de LexiEC y cita sus fuentes. '
          'Si no hay respaldo suficiente, te lo dirá en lugar de suponer.',
          style: text.bodyMedium,
        ),
        const SizedBox(height: 12),
        Text('Área', style: text.titleSmall),
        Wrap(
          spacing: 8,
          children: [
            for (final area in _controller.areas)
              ChoiceChip(
                label: Text(area.name),
                selected: _controller.selectedArea.value?.slug == area.slug,
                onSelected: sending
                    ? null
                    : (_) => _controller.selectArea(area),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('question-field'),
          controller: _question,
          enabled: !sending,
          minLines: 3,
          maxLines: 6,
          maxLength: questionMaxLength,
          decoration: const InputDecoration(
            labelText: 'Tu pregunta',
            helperText: 'Describe la situación de forma general.',
          ),
        ),
        CheckboxListTile(
          key: const Key('notice-checkbox'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _controller.acceptedNotice.value,
          onChanged: sending
              ? null
              : (value) => _controller.acceptedNotice.value = value ?? false,
          title: const Text(
            'No incluyo nombres, números de identificación, expedientes ni otros '
            'datos personales.',
          ),
        ),
        if (_controller.formError.value != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _controller.formError.value!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        FilledButton.icon(
          key: const Key('ask-button'),
          onPressed: sending ? null : () => _controller.send(_question.text),
          icon: sending
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
          label: Text(sending ? 'Consultando…' : 'Consultar'),
        ),
        const SizedBox(height: 16),
        if (failure != null)
          ErrorBanner(
            message: _controller.failureMessage(failure),
            onRetry: _controller.uncertain.value ? _controller.retry : null,
          ),
        if (result != null) ConsultationResultView(consultation: result),
        const SizedBox(height: 24),
        const AcademicNotice(),
      ],
    );
  }
}
