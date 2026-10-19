/// Comentario público de la comunidad (`docs/API.md`, sección 4).
///
/// Es una opinión de usuario: nunca es fuente normativa.
class Comment {
  const Comment({
    required this.id,
    required this.text,
    required this.authorName,
    required this.isMine,
    required this.createdAt,
    required this.edited,
  });

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
    id: json['id'] as int,
    text: json['text'] as String,
    authorName:
        (json['author'] as Map<String, dynamic>)['display_name'] as String,
    isMine: json['is_mine'] as bool,
    createdAt: DateTime.parse(json['created_at'] as String),
    edited: (json['edited'] as bool?) ?? false,
  );

  final int id;
  final String text;
  final String authorName;

  /// Solo para la interfaz; el permiso real lo comprueba el servidor.
  final bool isMine;
  final DateTime createdAt;
  final bool edited;
}

class CommentPage {
  const CommentPage({
    required this.count,
    required this.results,
    required this.hasNext,
  });

  factory CommentPage.fromJson(Map<String, dynamic> json) => CommentPage(
    count: json['count'] as int,
    results: [
      for (final item in json['results'] as List)
        Comment.fromJson(item as Map<String, dynamic>),
    ],
    hasNext: json['next'] != null,
  );

  final int count;
  final List<Comment> results;
  final bool hasNext;
}
