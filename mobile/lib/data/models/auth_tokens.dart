/// Par de tokens JWT. `toString` no revela su contenido.
class AuthTokens {
  const AuthTokens({required this.access, required this.refresh});

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      access: json['access'] as String,
      refresh: json['refresh'] as String,
    );
  }

  final String access;
  final String refresh;

  @override
  String toString() => 'AuthTokens(***)';
}
