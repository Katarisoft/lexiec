import 'package:url_launcher/url_launcher.dart';

/// Abre enlaces oficiales fuera de la app.
abstract class LinkOpener {
  /// Devuelve `false` si el enlace no es válido o no se pudo abrir.
  Future<bool> open(String url);
}

/// Solo abre URL https en el navegador externo; nunca otros esquemas.
class UrlLauncherLinkOpener implements LinkOpener {
  @override
  Future<bool> open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Exception {
      return false;
    }
  }
}
