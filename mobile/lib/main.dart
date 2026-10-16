import 'package:flutter/material.dart';

void main() {
  runApp(const LexiEcApp());
}

/// Aviso de alcance que acompaña a la aplicación.
const String academicNotice =
    'Herramienta académica de consulta documental. Puede contener errores y '
    'no sustituye la revisión de un profesional. Las respuestas se limitan a '
    'la colección disponible.';

/// Aplicación provisional: la estructura definitiva de rutas, tema y
/// controladores se incorporará en entregas posteriores.
class LexiEcApp extends StatelessWidget {
  const LexiEcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LexiEC',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const PlaceholderHomeScreen(),
    );
  }
}

class PlaceholderHomeScreen extends StatelessWidget {
  const PlaceholderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('LexiEC', style: textTheme.headlineLarge),
                const SizedBox(height: 8),
                Text(
                  'Consulta jurídica ecuatoriana con fuentes',
                  style: textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Text(
                  academicNotice,
                  style: textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
