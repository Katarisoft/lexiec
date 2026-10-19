import 'package:dio/dio.dart';

import '../../core/errors/api_failure.dart';
import '../models/consultation.dart';

/// Llamadas HTTP del asistente y del historial privado.
class AssistantService {
  AssistantService(this._dio);

  final Dio _dio;

  /// Más que el timeout del proveedor en el servidor (30 s), para no dar por
  /// fallida una consulta que el servidor aún está resolviendo.
  static const askTimeout = Duration(seconds: 45);

  Future<ConsultationDetail> ask({
    required String areaSlug,
    required String question,
    required String requestId,
  }) {
    return _call(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        'consultations/',
        data: {
          'area': areaSlug,
          'question': question,
          'client_request_id': requestId,
        },
        options: Options(receiveTimeout: askTimeout),
      );
      return ConsultationDetail.fromJson(response.data!);
    });
  }

  Future<ConsultationPage> history({int page = 1}) {
    return _call(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        'consultations/',
        queryParameters: {if (page > 1) 'page': page},
      );
      return ConsultationPage.fromJson(response.data!);
    });
  }

  Future<ConsultationDetail> detail(int id) {
    return _call(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        'consultations/$id/',
      );
      return ConsultationDetail.fromJson(response.data!);
    });
  }

  Future<void> delete(int id) {
    return _call(() async {
      await _dio.delete<void>('consultations/$id/');
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
