import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'app/app_pages.dart';
import 'app/app_routes.dart';
import 'app/app_theme.dart';
import 'app/initial_binding.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Favoritos y notas locales (no se guardan tokens en Hive).
  await Hive.initFlutter('lexiec');
  runApp(LexiEcApp(binding: InitialBinding()));
}

class LexiEcApp extends StatelessWidget {
  const LexiEcApp({super.key, required this.binding});

  final Bindings binding;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'LexiEC',
      theme: AppTheme.light(),
      initialBinding: binding,
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
      debugShowCheckedModeBanner: false,
    );
  }
}
