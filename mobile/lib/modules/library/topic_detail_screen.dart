import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/library_models.dart';
import '../common/format.dart';
import '../common/view_state.dart';
import '../common/widgets/academic_notice.dart';
import '../common/widgets/error_banner.dart';
import '../common/widgets/state_views.dart';
import '../community/comments_section.dart';
import '../local_library/local_library_controller.dart';
import '../local_library/topic_note_section.dart';
import 'library_controllers.dart';

class TopicDetailScreen extends StatelessWidget {
  const TopicDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TopicDetailController controller = Get.find();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ficha'),
        actions: [
          Obx(() {
            final LocalLibraryController local = Get.find();
            final topic = controller.topic.value;
            if (topic == null || !local.isReady.value) {
              return const SizedBox.shrink();
            }
            final saved = local.isFavorite(topic.id);
            return IconButton(
              key: const Key('favorite-toggle'),
              tooltip: saved ? 'Quitar de favoritos' : 'Guardar en favoritos',
              icon: Icon(saved ? Icons.star : Icons.star_border),
              onPressed: () => local.toggleFavorite(topic),
            );
          }),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          switch (controller.state.value) {
            case ViewState.loading:
            case ViewState.empty:
              return const LoadingView(message: 'Cargando ficha…');
            case ViewState.error:
              return ErrorView(
                message: controller.failure.value!.message,
                onRetry: controller.load,
              );
            case ViewState.data:
              return _TopicBody(
                topic: controller.topic.value!,
                controller: controller,
              );
          }
        }),
      ),
    );
  }
}

class _TopicBody extends StatelessWidget {
  const _TopicBody({required this.topic, required this.controller});

  final TopicDetail topic;
  final TopicDetailController controller;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(topic.title, style: text.headlineSmall),
        const SizedBox(height: 8),
        Wrap(children: [Chip(label: Text(topic.area.name))]),
        const SizedBox(height: 8),
        Text(topic.summary, style: text.bodyLarge),
        const SizedBox(height: 4),
        Text(
          'Ficha revisada el ${formatDate(topic.reviewedAt)}',
          style: text.bodySmall,
        ),
        const SizedBox(height: 24),
        Text('Fuentes oficiales', style: text.titleMedium),
        const SizedBox(height: 8),
        if (topic.sources.isEmpty)
          const _Warning(
            key: Key('no-sources'),
            text:
                'Esta ficha no tiene fuentes publicadas visibles. No la uses como '
                'respaldo hasta que se revisen sus fuentes.',
          )
        else
          for (final source in topic.sources)
            _SourceCard(source: source, controller: controller),
        const SizedBox(height: 24),
        TopicNoteSection(topicId: topic.id),
        const SizedBox(height: 24),
        const CommentsSection(),
        const SizedBox(height: 24),
        const AcademicNotice(),
      ],
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.source, required this.controller});

  final TopicSource source;
  final TopicDetailController controller;

  @override
  Widget build(BuildContext context) {
    final document = source.document;
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(source.locator, style: text.titleSmall),
            Text(document.title, style: text.bodyMedium),
            const SizedBox(height: 4),
            _Field('Institución', document.institution),
            if (document.publicationReference.isNotEmpty)
              _Field('Publicación', document.publicationReference),
            if (document.versionLabel.isNotEmpty)
              _Field('Versión', document.versionLabel),
            _Field('Consultado', formatDate(document.retrievedAt)),
            _Field('Revisado', formatDate(source.reviewedAt)),
            const SizedBox(height: 8),
            if (!document.isValidityVerified)
              _Warning(text: document.validityLabel)
            else
              _Field(
                'Vigencia',
                '${document.validityLabel} (${formatDate(document.validityCheckedAt)})',
              ),
            if (document.limitations.isNotEmpty) ...[
              const SizedBox(height: 8),
              _Warning(text: document.limitations),
            ],
            const SizedBox(height: 8),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Ver fragmento'),
              children: [SelectableText(source.text)],
            ),
            SelectableText(document.officialUrl, style: text.bodySmall),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                key: Key('open-source-${source.id}'),
                onPressed: () => controller.openSource(document.officialUrl),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Abrir fuente oficial'),
              ),
            ),
            Obx(() {
              final error = controller.linkError.value;
              final failed = controller.failedUrl.value == document.officialUrl;
              return error != null && failed
                  ? ErrorBanner(message: error)
                  : const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}

class _Warning extends StatelessWidget {
  const _Warning({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: scheme.onTertiaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: scheme.onTertiaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}
