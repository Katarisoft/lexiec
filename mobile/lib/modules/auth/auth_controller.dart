import 'package:get/get.dart';

import '../../core/errors/api_failure.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Estado compartido de la sesión.
class AuthController extends GetxController {
  AuthController(this._repository);

  final AuthRepository _repository;

  final status = AuthStatus.unknown.obs;
  final user = Rxn<UserProfile>();
  final isSubmitting = false.obs;

  /// Error general del último intento (red, servidor, credenciales).
  final errorMessage = RxnString();

  /// Errores por campo devueltos por la API (400 de validación).
  final fieldErrors = <String, List<String>>{}.obs;

  /// Último fallo, para que la interfaz decida si ofrece «Reintentar».
  final lastFailure = Rxn<ApiFailure>();

  bool get isAuthenticated => status.value == AuthStatus.authenticated;

  Future<void> restoreSession() async {
    _clearErrors();
    try {
      final restored = await _repository.restoreSession();
      _setSession(restored);
    } on ApiFailure catch (failure) {
      // Sin red no se puede validar la sesión: se informa y se permite
      // reintentar sin borrar los tokens.
      _setFailure(failure);
      status.value = AuthStatus.unknown;
    }
  }

  Future<bool> login({required String email, required String password}) {
    return _submit(() => _repository.login(email: email, password: password));
  }

  Future<bool> register({
    required String email,
    required String password,
    String? displayName,
  }) {
    return _submit(
      () => _repository.register(
        email: email,
        password: password,
        displayName: displayName,
      ),
    );
  }

  Future<void> logout() async {
    await _repository.logout();
    _clearSensitiveState();
  }

  /// Llamado por el cliente HTTP cuando la renovación es rechazada.
  void handleSessionExpired() {
    _clearSensitiveState();
    errorMessage.value = 'Tu sesión ha expirado. Inicia sesión de nuevo.';
  }

  void clearErrors() => _clearErrors();

  Future<bool> _submit(Future<UserProfile> Function() action) async {
    // Evita envíos duplicados por pulsaciones repetidas.
    if (isSubmitting.value) return false;
    isSubmitting.value = true;
    _clearErrors();
    try {
      _setSession(await action());
      return true;
    } on ApiFailure catch (failure) {
      _setFailure(failure);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  void _setSession(UserProfile? profile) {
    user.value = profile;
    status.value = profile == null
        ? AuthStatus.unauthenticated
        : AuthStatus.authenticated;
  }

  void _setFailure(ApiFailure failure) {
    lastFailure.value = failure;
    errorMessage.value = failure.message;
    fieldErrors.assignAll(failure.fieldErrors);
  }

  void _clearErrors() {
    errorMessage.value = null;
    lastFailure.value = null;
    fieldErrors.clear();
  }

  void _clearSensitiveState() {
    user.value = null;
    status.value = AuthStatus.unauthenticated;
    isSubmitting.value = false;
    _clearErrors();
  }
}
