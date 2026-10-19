import 'package:dio/dio.dart';

import '../../core/errors/api_failure.dart';
import '../models/auth_tokens.dart';
import '../models/user_profile.dart';

/// Llamadas HTTP de autenticación. Convierte los errores en [ApiFailure].
class AuthService {
  AuthService(this._dio);

  final Dio _dio;

  Future<UserProfile> register({
    required String email,
    required String password,
    String? displayName,
  }) {
    return _call(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        'auth/register/',
        data: {
          'email': email,
          'password': password,
          if (displayName != null && displayName.trim().isNotEmpty)
            'display_name': displayName.trim(),
        },
      );
      return UserProfile.fromJson(response.data!);
    });
  }

  Future<AuthTokens> login({required String email, required String password}) {
    return _call(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        'auth/token/',
        data: {'email': email, 'password': password},
      );
      return AuthTokens.fromJson(response.data!);
    });
  }

  Future<UserProfile> me() {
    return _call(() async {
      final response = await _dio.get<Map<String, dynamic>>('auth/me/');
      return UserProfile.fromJson(response.data!);
    });
  }

  Future<void> logout(String refresh) {
    return _call(() async {
      await _dio.post<void>('auth/logout/', data: {'refresh': refresh});
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
