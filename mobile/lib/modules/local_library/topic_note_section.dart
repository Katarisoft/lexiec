import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/repositories/local_library_repository.dart';
import '../common/format.dart';
import 'local_library_controller.dart';

/// Nota personal sobre una ficha, guardada solo en este dispositivo.
class TopicNoteSection extends StatefulWidget {
  const TopicNoteSection({super.key, required this.topicId});

  final int topicId;

  @override
  State<TopicNoteSection> createState() => _TopicNoteSectionState();
}

class _TopicNoteSectionState extends State<TopicNoteSection> {
  final LocalLibraryController _local = Get.find();
  late final _text = TextEditingController(
    text: _local.noteFor(widget.topicId)?.text ?? '',
  );
  bool _saving = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await _local.saveNote(widget.topicId, _text.text);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Mi nota', style: text.titleMedium),
        Text(
          'Se guarda solo en este dispositivo y para tu cuenta. No está cifrada: '
          'no escribas datos personales ni información sensible.',
          style: text.bodySmall,
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('note-field'),
          controller: _text,
          minLines: 2,
          maxLines: 6,
          maxLength: LocalLibraryRepository.noteMaxLength,
          decoration: const InputDecoration(labelText: 'Nota personal'),
        ),
        Row(
          children: [
            Expanded(
              child: Obx(() {
                final note = _local.notes[widget.topicId];
                return Text(
                  note == null
                      ? 'Sin nota guardada.'
                      : 'Guardada el ${formatDate(note.updatedAt)}',
                  style: text.bodySmall,
                );
              }),
            ),
            TextButton(
              key: const Key('note-save'),
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Guardando…' : 'Guardar nota'),
            ),
          ],
        ),
      ],
    );
  }
}
