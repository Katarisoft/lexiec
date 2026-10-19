import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Regla de arquitectura: las pantallas no hacen HTTP ni acceden a
/// almacenamiento directamente; pasan por controladores y repositorios.
void main() {
  test('ninguna pantalla importa clientes HTTP ni almacenamiento', () {
    final forbidden = [
      'package:dio/',
      'package:http/',
      'package:flutter_secure_storage/',
      'package:hive',
      '/data/services/',
      '/core/network/',
      '/core/security/',
    ];
    final screens = Directory('lib/modules')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('_screen.dart'))
        .toList();

    expect(screens, isNotEmpty);
    for (final screen in screens) {
      final imports = screen.readAsLinesSync().where(
        (line) => line.startsWith('import '),
      );
      for (final line in imports) {
        for (final pattern in forbidden) {
          expect(
            line.contains(pattern),
            isFalse,
            reason: '${screen.path} importa $pattern',
          );
        }
      }
    }
  });
}
