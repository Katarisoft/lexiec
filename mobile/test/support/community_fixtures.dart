/// Comentarios ficticios con la forma de `docs/API.md`, sección 4.
Map<String, dynamic> commentJson(
  int id, {
  String text = 'Comentario ficticio.',
  String author = 'Persona B',
  bool mine = false,
  bool edited = false,
}) => {
  'id': id,
  'text': text,
  'author': {'display_name': author},
  'is_mine': mine,
  'created_at': '2026-10-19T10:00:00Z',
  'updated_at': '2026-10-19T10:00:00Z',
  'edited': edited,
};

Map<String, dynamic> commentPageJson(
  List<Map<String, dynamic>> items, {
  int? count,
  bool hasNext = false,
}) => {
  'count': count ?? items.length,
  'next': hasNext
      ? 'http://servidor.invalid/api/v1/topics/1/comments/?page=2'
      : null,
  'previous': null,
  'results': items,
};
