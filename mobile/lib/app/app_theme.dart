import 'package:flutter/material.dart';

/// Tema de LexiEC: sobrio, legible y con contraste suficiente.
class AppTheme {
  const AppTheme._();

  static const Color _seed = Color(0xFF1F3A68);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: _seed);
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      ),
    );
  }
}
