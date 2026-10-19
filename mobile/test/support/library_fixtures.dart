import 'package:lexiec/core/services/link_opener.dart';

/// Datos de prueba ficticios con la forma de `docs/API.md`.

Map<String, dynamic> areaJson(int id, {int topics = 2}) => {
  'id': id,
  'slug': 'area-$id',
  'name': 'Área ficticia $id',
  'description': '',
  'order': id,
  'published_topics': topics,
};

Map<String, dynamic> topicSummaryJson(int id, {String area = 'area-1'}) => {
  'id': id,
  'slug': 'ficha-$id',
  'title': 'Ficha ficticia $id',
  'area': {'slug': area, 'name': 'Área ficticia'},
  'summary': 'Resumen ficticio $id.',
};

Map<String, dynamic> topicPageJson(
  List<int> ids, {
  int? count,
  bool hasNext = false,
}) => {
  'count': count ?? ids.length,
  'next': hasNext ? 'http://servidor.invalid/api/v1/topics/?page=2' : null,
  'previous': null,
  'results': [for (final id in ids) topicSummaryJson(id)],
};

Map<String, dynamic> topicDetailJson(
  int id, {
  bool withSources = true,
  String validity = 'not_verified',
}) => {
  'id': id,
  'slug': 'ficha-$id',
  'title': 'Ficha ficticia $id',
  'area': {'slug': 'area-1', 'name': 'Área ficticia 1'},
  'summary': 'Explicación ficticia.',
  'search_terms': ['ficticio'],
  'reviewed_at': '2026-10-19T10:00:00Z',
  'updated_at': '2026-10-19T10:00:00Z',
  'sources': [
    if (withSources)
      {
        'id': 50,
        'locator': 'Art. ficticio 1',
        'text': 'Texto ficticio del fragmento.',
        'reviewed_at': '2026-10-18T10:00:00Z',
        'document': {
          'id': 7,
          'title': 'Documento ficticio',
          'institution': 'Institución ficticia',
          'official_url': 'https://ejemplo.invalid/doc',
          'publication_reference': 'Referencia ficticia',
          'publication_date': '2026-01-01',
          'version_label': 'Versión ficticia',
          'retrieved_at': '2026-10-16',
          'reviewed_at': '2026-10-18T10:00:00Z',
          'validity_status': validity,
          'validity_status_label': validity == 'not_verified'
              ? 'Vigencia no comprobada'
              : 'Vigencia comprobada',
          'validity_checked_at': validity == 'not_verified'
              ? null
              : '2026-10-17',
          'limitations': 'Limitación ficticia.',
        },
      },
  ],
};

class FakeLinkOpener implements LinkOpener {
  FakeLinkOpener({this.result = true});

  bool result;
  final List<String> opened = [];

  @override
  Future<bool> open(String url) async {
    opened.add(url);
    return result;
  }
}
