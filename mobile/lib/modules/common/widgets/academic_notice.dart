import 'package:flutter/material.dart';

/// Aviso de alcance de la guía (sección 4.3).
const String academicNotice =
    'Herramienta académica de consulta documental. Puede contener errores y '
    'no sustituye la revisión de un profesional. Las respuestas se limitan a '
    'la colección disponible.';

class AcademicNotice extends StatelessWidget {
  const AcademicNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      academicNotice,
      style: Theme.of(context).textTheme.bodySmall,
      textAlign: TextAlign.center,
    );
  }
}
