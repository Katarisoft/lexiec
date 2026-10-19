import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../security/token_storage.dart';
import 'auth_interceptor.dart';

/// Construye el cliente HTTP de la app.
///
/// Solo los servicios de `data/services` usan este cliente; las pantallas
/// nunca hacen HTTP. No se añade ningún interceptor de logs para no exponer
/// tokens ni contenido de las consultas.
class ApiClient {
  ApiClient({
    required AppConfig config,
    required TokenStorage tokenStorage,
    required void Function() onSessionExpired,
    HttpClientAdapter? adapter,
  }) {
    final options = BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    );

    final refreshClient = Dio(options);
    dio = Dio(options);
    if (adapter != null) {
      refreshClient.httpClientAdapter = adapter;
      dio.httpClientAdapter = adapter;
    }

    final interceptor = AuthInterceptor(
      tokenStorage: tokenStorage,
      refreshClient: refreshClient,
      onSessionExpired: onSessionExpired,
    )..client = dio;
    dio.interceptors.add(interceptor);
  }

  late final Dio dio;
}
