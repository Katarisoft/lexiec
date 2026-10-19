import 'package:lexiec/core/security/token_storage.dart';
import 'package:lexiec/data/models/auth_tokens.dart';

/// Almacenamiento de tokens en memoria, solo para pruebas.
class InMemoryTokenStorage implements TokenStorage {
  InMemoryTokenStorage([this.tokens]);

  AuthTokens? tokens;
  int clearCount = 0;

  @override
  Future<AuthTokens?> read() async => tokens;

  @override
  Future<void> save(AuthTokens value) async => tokens = value;

  @override
  Future<void> clear() async {
    tokens = null;
    clearCount++;
  }
}
