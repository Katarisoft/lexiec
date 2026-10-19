import 'package:dio/dio.dart';

import '../../data/models/auth_tokens.dart';
import '../security/token_storage.dart';

/// Añade el access token y renueva la sesión una sola vez ante un 401.
///
/// - Varias peticiones que reciben 401 a la vez comparten una única
///   renovación.
/// - Cada petición se reintenta como máximo una vez; un segundo 401 no
///   provoca otra renovación (sin bucles).
/// - Si la renovación es rechazada, se borran los tokens y se avisa una
///   única vez con [onSessionExpired].
/// - Nunca registra tokens en logs.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this._tokenStorage,
    required this._refreshClient,
    required this._onSessionExpired,
  });

  final TokenStorage _tokenStorage;
  final Dio _refreshClient;
  final void Function() _onSessionExpired;

  /// Cliente principal, para reintentar la petición original.
  late Dio client;

  Future<_RefreshResult>? _refreshInFlight;

  static const _retriedKey = 'lexiec_auth_retried';
  static const refreshPath = 'auth/token/refresh/';

  /// Endpoints que no llevan access ni disparan renovación.
  static const _publicPaths = {'auth/register/', 'auth/token/', refreshPath};

  static bool isPublicPath(String path) => _publicPaths.contains(path);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!isPublicPath(options.path)) {
      final tokens = await _tokenStorage.read();
      if (tokens != null) {
        options.headers['Authorization'] = 'Bearer ${tokens.access}';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final canRefresh =
        err.response?.statusCode == 401 &&
        !isPublicPath(options.path) &&
        options.extra[_retriedKey] != true &&
        options.headers['Authorization'] != null;
    if (!canRefresh) {
      handler.next(err);
      return;
    }

    // Si otra petición ya renovó la sesión, basta con reintentar.
    final current = await _tokenStorage.read();
    final usedHeader = options.headers['Authorization'];
    String? access;
    if (current != null && usedHeader != 'Bearer ${current.access}') {
      access = current.access;
    } else {
      final result = await _refreshOnce();
      if (result.networkError != null) {
        handler.next(result.networkError!);
        return;
      }
      access = result.access;
    }

    if (access == null) {
      handler.next(err);
      return;
    }

    options.extra[_retriedKey] = true;
    options.headers['Authorization'] = 'Bearer $access';
    try {
      handler.resolve(await client.fetch<dynamic>(options));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<_RefreshResult> _refreshOnce() {
    return _refreshInFlight ??= _refresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<_RefreshResult> _refresh() async {
    final tokens = await _tokenStorage.read();
    if (tokens == null) {
      _expire();
      return const _RefreshResult();
    }
    try {
      final response = await _refreshClient.post<Map<String, dynamic>>(
        refreshPath,
        data: {'refresh': tokens.refresh},
      );
      final renewed = AuthTokens.fromJson(response.data!);
      await _tokenStorage.save(renewed);
      return _RefreshResult(access: renewed.access);
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (status == 401 || status == 400) {
        await _tokenStorage.clear();
        _expire();
        return const _RefreshResult();
      }
      // Fallo de red o del servidor: se conserva la sesión y se informa
      // del error real, sin forzar un cierre de sesión.
      return _RefreshResult(networkError: error);
    }
  }

  void _expire() => _onSessionExpired();
}

class _RefreshResult {
  const _RefreshResult({this.access, this.networkError});

  final String? access;
  final DioException? networkError;
}
