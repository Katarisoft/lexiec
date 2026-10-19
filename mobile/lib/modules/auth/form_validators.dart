/// Validaciones locales mínimas; las reglas definitivas las aplica el backend.
abstract class FormValidators {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Ingresa tu correo.';
    if (!_emailPattern.hasMatch(text)) return 'Ingresa un correo válido.';
    return null;
  }

  static String? requiredPassword(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa tu contraseña.';
    return null;
  }

  static String? newPassword(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa una contraseña.';
    if (value.length < 8) return 'Usa al menos 8 caracteres.';
    return null;
  }

  static String? displayName(String? value) {
    final text = value?.trim() ?? '';
    if (text.length > 40) return 'Usa como máximo 40 caracteres.';
    if (text.contains('@')) return 'El alias no puede contener «@».';
    return null;
  }
}
