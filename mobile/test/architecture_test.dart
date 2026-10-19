import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Reglas de arquitectura:
/// - Pantallas y widgets no hacen HTTP ni acceden a almacenamiento: pasan por
///   controladores y repositorios.
/// - Los controladores tampoco usan clientes HTTP o almacenamiento directos.
void main() {
  const httpAndStorage = [
    'package:dio/',
    'package:http/',
    'package:flutter_secure_storage/',
    'package:hive',
    '/data/services/',
    '/core/network/',
    '/core/security/',
  ];
  const uiForbidden = ['package:url_launcher/', '/core/services/'];

  Iterable<File> moduleFiles() => Directory('lib/modules')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  Iterable<String> importsOf(File file) =>
      file.readAsLinesSync().where((line) => line.startsWith('import '));

  bool isController(File file) =>
      file.path.endsWith('controller.dart') ||
      file.path.endsWith('controllers.dart');

  test('ningún archivo de modules importa HTTP ni almacenamiento', () {
    final files = moduleFiles().toList();
    expect(files, isNotEmpty);
    for (final file in files) {
      for (final line in importsOf(file)) {
        for (final pattern in httpAndStorage) {
          expect(
            line.contains(pattern),
            isFalse,
            reason: '${file.path} importa $pattern',
          );
        }
      }
    }
  });

  test('pantallas y widgets no usan servicios de plataforma directamente', () {
    final widgets = moduleFiles().where((f) => !isController(f)).toList();
    expect(widgets.any((f) => f.path.endsWith('_screen.dart')), isTrue);
    for (final file in widgets) {
      for (final line in importsOf(file)) {
        for (final pattern in uiForbidden) {
          expect(
            line.contains(pattern),
            isFalse,
            reason: '${file.path} importa $pattern',
          );
        }
      }
    }
  });
}
