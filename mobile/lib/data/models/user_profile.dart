/// Perfil de la cuenta autenticada (`GET /api/v1/auth/me/`).
class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.dateJoined,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      email: json['email'] as String,
      displayName: (json['display_name'] as String?) ?? '',
      dateJoined: DateTime.parse(json['date_joined'] as String),
    );
  }

  final int id;
  final String email;
  final String displayName;
  final DateTime dateJoined;

  /// Nombre a mostrar en la propia sesión.
  String get visibleName => displayName.isNotEmpty ? displayName : email;
}
