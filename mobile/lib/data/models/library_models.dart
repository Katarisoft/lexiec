/// DTO de la biblioteca (`docs/API.md`, sección 3).
library;

class LegalArea {
  const LegalArea({
    required this.id,
    required this.slug,
    required this.name,
    required this.description,
    required this.publishedTopics,
  });

  factory LegalArea.fromJson(Map<String, dynamic> json) => LegalArea(
    id: json['id'] as int,
    slug: json['slug'] as String,
    name: json['name'] as String,
    description: (json['description'] as String?) ?? '',
    publishedTopics: (json['published_topics'] as int?) ?? 0,
  );

  final int id;
  final String slug;
  final String name;
  final String description;
  final int publishedTopics;
}

class AreaSummary {
  const AreaSummary({required this.slug, required this.name});

  factory AreaSummary.fromJson(Map<String, dynamic> json) =>
      AreaSummary(slug: json['slug'] as String, name: json['name'] as String);

  final String slug;
  final String name;
}

class TopicSummary {
  const TopicSummary({
    required this.id,
    required this.slug,
    required this.title,
    required this.area,
    required this.summary,
  });

  factory TopicSummary.fromJson(Map<String, dynamic> json) => TopicSummary(
    id: json['id'] as int,
    slug: json['slug'] as String,
    title: json['title'] as String,
    area: AreaSummary.fromJson(json['area'] as Map<String, dynamic>),
    summary: (json['summary'] as String?) ?? '',
  );

  final int id;
  final String slug;
  final String title;
  final AreaSummary area;
  final String summary;
}

class TopicPage {
  const TopicPage({
    required this.count,
    required this.results,
    required this.hasNext,
  });

  factory TopicPage.fromJson(Map<String, dynamic> json) => TopicPage(
    count: json['count'] as int,
    results: [
      for (final item in json['results'] as List)
        TopicSummary.fromJson(item as Map<String, dynamic>),
    ],
    hasNext: json['next'] != null,
  );

  final int count;
  final List<TopicSummary> results;
  final bool hasNext;
}

DateTime? _date(Object? value) =>
    value == null ? null : DateTime.parse(value as String);

class SourceDocument {
  const SourceDocument({
    required this.id,
    required this.title,
    required this.institution,
    required this.officialUrl,
    required this.publicationReference,
    required this.publicationDate,
    required this.versionLabel,
    required this.retrievedAt,
    required this.reviewedAt,
    required this.validityStatus,
    required this.validityLabel,
    required this.validityCheckedAt,
    required this.limitations,
  });

  factory SourceDocument.fromJson(Map<String, dynamic> json) => SourceDocument(
    id: json['id'] as int,
    title: json['title'] as String,
    institution: json['institution'] as String,
    officialUrl: json['official_url'] as String,
    publicationReference: (json['publication_reference'] as String?) ?? '',
    publicationDate: _date(json['publication_date']),
    versionLabel: (json['version_label'] as String?) ?? '',
    retrievedAt: _date(json['retrieved_at']),
    reviewedAt: _date(json['reviewed_at']),
    validityStatus: json['validity_status'] as String,
    validityLabel: json['validity_status_label'] as String,
    validityCheckedAt: _date(json['validity_checked_at']),
    limitations: (json['limitations'] as String?) ?? '',
  );

  final int id;
  final String title;
  final String institution;
  final String officialUrl;
  final String publicationReference;
  final DateTime? publicationDate;
  final String versionLabel;
  final DateTime? retrievedAt;
  final DateTime? reviewedAt;
  final String validityStatus;
  final String validityLabel;
  final DateTime? validityCheckedAt;
  final String limitations;

  bool get isValidityVerified => validityStatus == 'verified_current';
}

class TopicSource {
  const TopicSource({
    required this.id,
    required this.locator,
    required this.text,
    required this.reviewedAt,
    required this.document,
  });

  factory TopicSource.fromJson(Map<String, dynamic> json) => TopicSource(
    id: json['id'] as int,
    locator: json['locator'] as String,
    text: json['text'] as String,
    reviewedAt: _date(json['reviewed_at']),
    document: SourceDocument.fromJson(json['document'] as Map<String, dynamic>),
  );

  final int id;
  final String locator;
  final String text;
  final DateTime? reviewedAt;
  final SourceDocument document;
}

class TopicDetail {
  const TopicDetail({
    required this.id,
    required this.title,
    required this.area,
    required this.summary,
    required this.reviewedAt,
    required this.sources,
  });

  factory TopicDetail.fromJson(Map<String, dynamic> json) => TopicDetail(
    id: json['id'] as int,
    title: json['title'] as String,
    area: AreaSummary.fromJson(json['area'] as Map<String, dynamic>),
    summary: (json['summary'] as String?) ?? '',
    reviewedAt: _date(json['reviewed_at']),
    sources: [
      for (final item in json['sources'] as List)
        TopicSource.fromJson(item as Map<String, dynamic>),
    ],
  );

  final int id;
  final String title;
  final AreaSummary area;
  final String summary;
  final DateTime? reviewedAt;
  final List<TopicSource> sources;
}
