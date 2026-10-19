import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/comment.dart';
import '../common/format.dart';
import '../common/view_state.dart';
import '../common/widgets/error_banner.dart';
import 'comments_controller.dart';

/// Comentarios de la comunidad bajo el detalle de una ficha.
class CommentsSection extends StatefulWidget {
  const CommentsSection({super.key});

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  final CommentsController _controller = Get.find();
  final _draft = TextEditingController();

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final ok = await _controller.post(_draft.text);
    // Solo se borra el texto si se publicó; si falla, se conserva.
    if (ok) _draft.clear();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Comentarios de la comunidad',
                style: text.titleMedium,
              ),
            ),
            IconButton(
              key: const Key('comments-reload'),
              tooltip: 'Actualizar comentarios',
              icon: const Icon(Icons.refresh),
              onPressed: _controller.load,
            ),
          ],
        ),
        Text(
          'Son opiniones de otras personas usuarias, no fuentes normativas. '
          'No publiques datos personales ni detalles de casos reales.',
          style: text.bodySmall,
        ),
        const SizedBox(height: 12),
        Obx(() {
          final posting = _controller.isPosting.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const Key('comment-draft'),
                controller: _draft,
                enabled: !posting,
                minLines: 2,
                maxLines: 5,
                maxLength: CommentsController.maxLength,
                onChanged: (_) => _controller.clearPostError(),
                decoration: InputDecoration(
                  labelText: 'Escribe un comentario',
                  errorText: _controller.postError.value,
                  errorMaxLines: 3,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  key: const Key('comment-publish'),
                  onPressed: posting ? null : _publish,
                  icon: posting
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(posting ? 'Publicando…' : 'Publicar'),
                ),
              ),
            ],
          );
        }),
        const SizedBox(height: 12),
        Obx(() {
          final error = _controller.actionError.value;
          return error == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ErrorBanner(message: error),
                );
        }),
        Obx(_list),
      ],
    );
  }

  Widget _list() {
    switch (_controller.state.value) {
      case ViewState.loading:
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        );
      case ViewState.error:
        return ErrorBanner(
          message: _controller.failure.value!.message,
          onRetry: _controller.load,
        );
      case ViewState.empty:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text('Aún no hay comentarios. Puedes escribir el primero.'),
        );
      case ViewState.data:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final comment in _controller.comments)
              _CommentTile(comment: comment, controller: _controller),
            if (_controller.hasNext.value)
              Center(
                child: _controller.isLoadingMore.value
                    ? const CircularProgressIndicator()
                    : TextButton(
                        key: const Key('comments-more'),
                        onPressed: _controller.loadMore,
                        child: const Text('Ver más comentarios'),
                      ),
              ),
          ],
        );
    }
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment, required this.controller});

  final Comment comment;
  final CommentsController controller;

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar comentario'),
        content: const Text('Se eliminará de forma definitiva. ¿Continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('comment-delete-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await controller.remove(comment.id);
  }

  Future<void> _edit(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => _EditCommentDialog(
        initialText: comment.text,
        onSubmit: (text) => controller.edit(comment.id, text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final edited = comment.edited ? ' · editado' : '';
    return Card(
      key: Key('comment-${comment.id}'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${comment.authorName} · ${formatDate(comment.createdAt)}$edited',
                    style: text.labelMedium,
                  ),
                ),
                // Acciones ocultas en comentarios ajenos solo por UX: el
                // servidor rechaza igualmente ediciones de otras cuentas.
                if (comment.isMine)
                  Obx(
                    () => controller.busyIds.contains(comment.id)
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : PopupMenuButton<String>(
                            key: Key('comment-menu-${comment.id}'),
                            tooltip: 'Acciones',
                            onSelected: (action) => action == 'edit'
                                ? _edit(context)
                                : _confirmDelete(context),
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Editar'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Eliminar'),
                              ),
                            ],
                          ),
                  ),
              ],
            ),
            Text(comment.text),
          ],
        ),
      ),
    );
  }
}

/// Diálogo de edición: se mantiene abierto con el texto si falla el guardado.
class _EditCommentDialog extends StatefulWidget {
  const _EditCommentDialog({required this.initialText, required this.onSubmit});

  final String initialText;
  final Future<String?> Function(String text) onSubmit;

  @override
  State<_EditCommentDialog> createState() => _EditCommentDialogState();
}

class _EditCommentDialogState extends State<_EditCommentDialog> {
  late final _text = TextEditingController(text: widget.initialText);
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.onSubmit(_text.text);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar comentario'),
      content: TextField(
        key: const Key('comment-edit-field'),
        controller: _text,
        enabled: !_saving,
        minLines: 2,
        maxLines: 6,
        maxLength: CommentsController.maxLength,
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
        decoration: InputDecoration(errorText: _error, errorMaxLines: 3),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('comment-edit-save'),
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Guardando…' : 'Guardar'),
        ),
      ],
    );
  }
}
