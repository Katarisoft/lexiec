/// Datos guardados solo en este dispositivo, separados por cuenta.
library;

/// Copia mínima de una ficha marcada como favorita.
class FavoriteTopic {
  const FavoriteTopic({
    required this.topicId,
    required this.title,
    required this.areaName,
    required this.summary,
    required this.savedAt,
  });

  factory FavoriteTopic.fromMap(Map<dynamic, dynamic> map) => FavoriteTopic(
    topicId: map['topicId'] as int,
    title: map['title'] as String,
    areaName: map['areaName'] as String,
    summary: map['summary'] as String,
    savedAt: DateTime.parse(map['savedAt'] as String),
  );

  final int topicId;
  final String title;
  final String areaName;
  final String summary;

  /// Fecha de la copia: el contenido puede haber cambiado en el servidor.
  final DateTime savedAt;

  Map<String, Object> toMap() => {
    'topicId': topicId,
    'title': title,
    'areaName': areaName,
    'summary': summary,
    'savedAt': savedAt.toIso8601String(),
  };
}

/// Nota personal sobre una ficha. No está cifrada.
class TopicNote {
  const TopicNote({
    required this.topicId,
    required this.text,
    required this.updatedAt,
  });

  factory TopicNote.fromMap(Map<dynamic, dynamic> map) => TopicNote(
    topicId: map['topicId'] as int,
    text: map['text'] as String,
    updatedAt: DateTime.parse(map['updatedAt'] as String),
  );

  final int topicId;
  final String text;
  final DateTime updatedAt;

  Map<String, Object> toMap() => {
    'topicId': topicId,
    'text': text,
    'updatedAt': updatedAt.toIso8601String(),
  };
}
