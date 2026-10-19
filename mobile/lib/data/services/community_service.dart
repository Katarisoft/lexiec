import 'package:dio/dio.dart';

import '../../core/errors/api_failure.dart';
import '../models/comment.dart';

/// Llamadas HTTP de comentarios. El autor lo asigna el servidor.
class CommunityService {
  CommunityService(this._dio);

  final Dio _dio;

  Future<CommentPage> list(int topicId, {int page = 1}) {
    return _call(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        'topics/$topicId/comments/',
        queryParameters: {if (page > 1) 'page': page},
      );
      return CommentPage.fromJson(response.data!);
    });
  }

  Future<Comment> create(int topicId, String text) {
    return _call(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        'topics/$topicId/comments/',
        data: {'text': text},
      );
      return Comment.fromJson(response.data!);
    });
  }

  Future<Comment> update(int commentId, String text) {
    return _call(() async {
      final response = await _dio.patch<Map<String, dynamic>>(
        'comments/$commentId/',
        data: {'text': text},
      );
      return Comment.fromJson(response.data!);
    });
  }

  Future<void> delete(int commentId) {
    return _call(() async {
      await _dio.delete<void>('comments/$commentId/');
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
