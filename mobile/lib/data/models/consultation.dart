import 'library_models.dart';

/// Estados funcionales del asistente (`docs/API.md`, sección 5).
enum ConsultationState { answered, noSupport, error }

ConsultationState _state(String value) => switch (value) {
  'answered' => ConsultationState.answered,
  'no_support' => ConsultationState.noSupport,
  _ => ConsultationState.error,
};

class ConsultationSummary {
  const ConsultationSummary({
    required this.id,
    required this.area,
    required this.question,
    required this.state,
    required this.statusLabel,
    required this.createdAt,
  });

  factory ConsultationSummary.fromJson(Map<String, dynamic> json) =>
      ConsultationSummary(
        id: json['id'] as int,
        area: AreaSummary.fromJson(json['area'] as Map<String, dynamic>),
        question: json['question'] as String,
        state: _state(json['status'] as String),
        statusLabel: json['status_label'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  final int id;
  final AreaSummary area;
  final String question;
  final ConsultationState state;
  final String statusLabel;
  final DateTime createdAt;
}

/// Fuente oficial citada por una respuesta (no es un comentario ni una nota).
class Citation {
  const Citation({
    required this.locator,
    required this.documentTitle,
    required this.officialUrl,
    required this.quotedText,
  });

  factory Citation.fromJson(Map<String, dynamic> json) => Citation(
    locator: json['locator'] as String,
    documentTitle: json['document_title'] as String,
    officialUrl: json['official_url'] as String,
    quotedText: json['quoted_text'] as String,
  );

  final String locator;
  final String documentTitle;
  final String officialUrl;
  final String quotedText;
}

class ConsultationDetail extends ConsultationSummary {
  const ConsultationDetail({
    required super.id,
    required super.area,
    required super.question,
    required super.state,
    required super.statusLabel,
    required super.createdAt,
    required this.answer,
    required this.limitations,
    required this.errorCode,
    required this.citations,
  });

  factory ConsultationDetail.fromJson(Map<String, dynamic> json) {
    final summary = ConsultationSummary.fromJson(json);
    return ConsultationDetail(
      id: summary.id,
      area: summary.area,
      question: summary.question,
      state: summary.state,
      statusLabel: summary.statusLabel,
      createdAt: summary.createdAt,
      answer: (json['answer'] as String?) ?? '',
      limitations: (json['limitations'] as String?) ?? '',
      errorCode: (json['error_code'] as String?) ?? '',
      citations: [
        for (final item in (json['citations'] as List?) ?? const [])
          Citation.fromJson(item as Map<String, dynamic>),
      ],
    );
  }

  final String answer;
  final String limitations;
  final String errorCode;
  final List<Citation> citations;
}

class ConsultationPage {
  const ConsultationPage({
    required this.count,
    required this.results,
    required this.hasNext,
  });

  factory ConsultationPage.fromJson(Map<String, dynamic> json) =>
      ConsultationPage(
        count: json['count'] as int,
        results: [
          for (final item in json['results'] as List)
            ConsultationSummary.fromJson(item as Map<String, dynamic>),
        ],
        hasNext: json['next'] != null,
      );

  final int count;
  final List<ConsultationSummary> results;
  final bool hasNext;
}
