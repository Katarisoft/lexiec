/// Consultas ficticias con la forma de `docs/API.md`, sección 5.
Map<String, dynamic> consultationJson(
  int id, {
  String status = 'answered',
  String question = '¿Pregunta ficticia?',
  String errorCode = '',
}) => {
  'id': id,
  'area': {'slug': 'area-1', 'name': 'Área ficticia 1'},
  'question': question,
  'status': status,
  'status_label': switch (status) {
    'answered' => 'Respondida con respaldo',
    'no_support' => 'Sin respaldo suficiente',
    _ => 'Error técnico',
  },
  'created_at': '2026-10-19T10:00:00Z',
  'answer': status == 'answered' ? 'Respuesta ficticia citada.' : '',
  'limitations': status == 'answered' ? 'Limitación ficticia.' : '',
  'error_code': errorCode,
  'citations': [
    if (status == 'answered')
      {
        'fragment': 7,
        'locator': 'Art. ficticio 1',
        'document_title': 'Documento ficticio',
        'official_url': 'https://ejemplo.invalid/doc',
        'quoted_text': 'Texto ficticio citado.',
      },
  ],
};

Map<String, dynamic> consultationPageJson(List<Map<String, dynamic>> items) => {
  'count': items.length,
  'next': null,
  'previous': null,
  'results': items,
};
