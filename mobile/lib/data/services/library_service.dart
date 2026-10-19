import 'package:dio/dio.dart';

import '../../core/errors/api_failure.dart';
import '../models/library_models.dart';

/// Llamadas HTTP de la biblioteca. Convierte errores en [ApiFailure].
class LibraryService {
  LibraryService(this._dio);

  final Dio _dio;

  Future<List<LegalArea>> areas() {
    return _call(() async {
      final response = await _dio.get<List<dynamic>>('areas/');
      return [
        for (final item in response.data!)
          LegalArea.fromJson(item as Map<String, dynamic>),
      ];
    });
  }

  Future<TopicPage> topics({String? area, String? search, int page = 1}) {
    return _call(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        'topics/',
        queryParameters: {
          'area': ?area,
          if (search != null && search.isNotEmpty) 'search': search,
          if (page > 1) 'page': page,
        },
      );
      return TopicPage.fromJson(response.data!);
    });
  }

  Future<TopicDetail> topic(int id) {
    return _call(() async {
      final response = await _dio.get<Map<String, dynamic>>('topics/$id/');
      return TopicDetail.fromJson(response.data!);
    });
  }

  Future<T> _call<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    }
  }
}
