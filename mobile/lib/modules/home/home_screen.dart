import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/app_routes.dart';
import '../auth/auth_controller.dart';
import '../common/widgets/academic_notice.dart';

/// Inicio protegido. La biblioteca se incorporará en E10.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController auth = Get.find();
    return Scaffold(
      appBar: AppBar(
        title: const Text('LexiEC'),
        actions: [
          IconButton(
            key: const Key('logout'),
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              Get.offAllNamed<void>(AppRoutes.login);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Obx(
                () => Text(
                  'Hola, ${auth.user.value?.visibleName ?? ''}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Consulta jurídica ecuatoriana con fuentes'),
              const Spacer(),
              const AcademicNotice(),
            ],
          ),
        ),
      ),
    );
  }
}
