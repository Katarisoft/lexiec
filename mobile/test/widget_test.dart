import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lexiec/main.dart';

void main() {
  testWidgets('muestra el nombre, el descriptor y el aviso académico', (
    tester,
  ) async {
    await tester.pumpWidget(const LexiEcApp());

    expect(find.text('LexiEC'), findsOneWidget);
    expect(
      find.text('Consulta jurídica ecuatoriana con fuentes'),
      findsOneWidget,
    );
    expect(find.text(academicNotice), findsOneWidget);
  });

  testWidgets('el aviso indica que no sustituye a un profesional', (
    tester,
  ) async {
    await tester.pumpWidget(const LexiEcApp());

    final notice = tester.widget<Text>(find.text(academicNotice));
    expect(notice.data, contains('no sustituye la revisión de un profesional'));
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).title,
      'LexiEC',
    );
  });
}
