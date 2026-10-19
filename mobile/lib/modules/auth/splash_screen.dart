import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/app_routes.dart';
import '../common/widgets/error_banner.dart';
import 'auth_controller.dart';

/// Comprueba la sesión guardada y dirige a inicio o al login.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthController _auth = Get.find();

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    await _auth.restoreSession();
    if (!mounted) return;
    switch (_auth.status.value) {
      case AuthStatus.authenticated:
        Get.offAllNamed<void>(AppRoutes.home);
      case AuthStatus.unauthenticated:
        Get.offAllNamed<void>(AppRoutes.login);
      case AuthStatus.unknown:
        // Error de red o servidor: se muestra con opción de reintentar.
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Obx(() {
              final failure = _auth.lastFailure.value;
              if (failure == null) {
                return const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Comprobando sesión…'),
                  ],
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ErrorBanner(message: failure.message, onRetry: _check),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Get.offAllNamed<void>(AppRoutes.login),
                    child: const Text('Ir a iniciar sesión'),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
