import 'package:flutter_test/flutter_test.dart';
import 'package:lexiec/core/config/app_config.dart';

void main() {
  test('normaliza la raíz del servidor a /api/v1/ sin duplicarla', () {
    for (final url in [
      'http://10.0.2.2:8000',
      'http://10.0.2.2:8000/',
      'http://10.0.2.2:8000/api/v1',
      'http://10.0.2.2:8000/api/v1/',
      ' http://10.0.2.2:8000// ',
    ]) {
      expect(
        AppConfig(serverUrl: url).apiBaseUrl,
        'http://10.0.2.2:8000/api/v1/',
        reason: url,
      );
    }
  });

  test('el valor por defecto apunta al anfitrión del emulador', () {
    expect(
      AppConfig.fromEnvironment().apiBaseUrl,
      'http://10.0.2.2:8000/api/v1/',
    );
  });
}
