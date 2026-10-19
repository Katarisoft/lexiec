import 'package:flutter/material.dart';

import '../../data/models/consultation.dart';

/// Resultado de una consulta. Los tres estados se ven distintos:
/// respuesta con fuentes, sin respaldo suficiente y error técnico.
class ConsultationResultView extends StatelessWidget {
  const ConsultationResultView({super.key, required this.consultation});

  final ConsultationDetail consultation;

  @override
  Widget build(BuildContext context) {
    return switch (consultation.state) {
      ConsultationState.answered => _Answered(consultation: consultation),
      ConsultationState.noSupport => _Notice(
        key: const Key('result-no-support'),
        icon: Icons.search_off,
        title: 'Sin respaldo suficiente en la colección',
        body:
            'No encontramos fragmentos revisados que respalden una respuesta. '
            'Esto no significa que no exista una norma aplicable: puede estar '
            'fuera de la colección disponible. Consulta a un profesional si lo necesitas.'
            '${consultation.limitations.isEmpty ? '' : '\n\n${consultation.limitations}'}',
      ),
      ConsultationState.error => _Notice(
        key: const Key('result-error'),
        icon: Icons.error_outline,
        title: 'Error técnico',
        body:
            'No se pudo generar una respuesta (código: ${consultation.errorCode}). '
            'No es una conclusión sobre tu pregunta; puedes intentarlo más tarde.',
        isError: true,
      ),
    };
  }
}

class _Answered extends StatelessWidget {
  const _Answered({required this.consultation});

  final ConsultationDetail consultation;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      key: const Key('result-answered'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Respuesta', style: text.titleMedium),
        const SizedBox(height: 4),
        SelectableText(consultation.answer),
        if (consultation.limitations.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(consultation.limitations, style: text.bodySmall),
        ],
        const SizedBox(height: 16),
        Text('Fuentes oficiales citadas', style: text.titleMedium),
        const SizedBox(height: 4),
        for (final citation in consultation.citations)
          Card(
            child: ExpansionTile(
              leading: const Icon(Icons.gavel),
              title: Text(citation.locator),
              subtitle: Text(
                'Fuente oficial · ${citation.documentTitle}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              children: [
                SelectableText(citation.quotedText),
                const SizedBox(height: 4),
                SelectableText(citation.officialUrl, style: text.bodySmall),
              ],
            ),
          ),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.isError = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = isError
        ? scheme.errorContainer
        : scheme.secondaryContainer;
    final foreground = isError
        ? scheme.onErrorContainer
        : scheme.onSecondaryContainer;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(body, style: TextStyle(color: foreground)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
