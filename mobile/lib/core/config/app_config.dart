/// Configuración pública de la app. No contiene secretos.
///
/// La URL del backend se indica al compilar:
/// `flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000`
/// Debe ser la raíz del servidor, sin `/api/v1/`.
class AppConfig {
  const AppConfig({required this.serverUrl});

  /// Emulador Android: el equipo anfitrión es 10.0.2.2.
  static const String defaultServerUrl = 'http://10.0.2.2:8000';

  factory AppConfig.fromEnvironment() {
    const value = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: defaultServerUrl,
    );
    return AppConfig(serverUrl: value);
  }

  final String serverUrl;

  /// Raíz de la API v1, siempre con una única barra final.
  String get apiBaseUrl {
    var root = serverUrl.trim();
    while (root.endsWith('/')) {
      root = root.substring(0, root.length - 1);
    }
    if (root.endsWith('/api/v1')) {
      root = root.substring(0, root.length - '/api/v1'.length);
    }
    return '$root/api/v1/';
  }

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 20);
}
