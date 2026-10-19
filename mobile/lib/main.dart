import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/app_pages.dart';
import 'app/app_routes.dart';
import 'app/app_theme.dart';
import 'app/initial_binding.dart';

void main() {
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
