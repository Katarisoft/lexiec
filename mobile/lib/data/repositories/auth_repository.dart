import '../../core/errors/api_failure.dart';
import '../../core/security/token_storage.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';

/// Coordina el servicio de autenticación y el almacenamiento seguro.
class AuthRepository {
  AuthRepository({required this._service, required this._tokenStorage});

  final AuthService _service;
  final TokenStorage _tokenStorage;

  Future<UserProfile> login({
    required String email,
    required String password,
  }) async {
    final tokens = await _service.login(
      email: email.trim(),
      password: password,
    );
    await _tokenStorage.save(tokens);
    try {
      return await _service.me();
    } on ApiFailure {
      // Sin perfil no hay sesión utilizable: no se dejan tokens huérfanos.
      await _tokenStorage.clear();
      rethrow;
    }
  }

  /// Registra la cuenta e inicia sesión con ella.
  Future<UserProfile> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    await _service.register(
      email: email.trim(),
      password: password,
      displayName: displayName,
    );
    return login(email: email, password: password);
  }

  /// Recupera la sesión guardada. Devuelve `null` si no hay sesión válida.
  ///
  /// Un fallo de red no borra la sesión: se propaga para poder reintentar.
  Future<UserProfile?> restoreSession() async {
    final tokens = await _tokenStorage.read();
    if (tokens == null) return null;
    try {
      return await _service.me();
    } on ApiFailure catch (failure) {
      if (failure.kind == FailureKind.unauthorized) {
        await _tokenStorage.clear();
        return null;
      }
      rethrow;
    }
  }

  /// Cierra la sesión: invalida el refresh en el servidor si es posible y
  /// borra siempre los tokens locales, aunque falle la red.
  Future<void> logout() async {
    final tokens = await _tokenStorage.read();
    try {
      if (tokens != null) await _service.logout(tokens.refresh);
    } on ApiFailure {
      // El cierre local no depende del servidor.
    } finally {
      await _tokenStorage.clear();
    }
  }
}
