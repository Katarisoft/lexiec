import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../data/models/library_models.dart';
import '../modules/auth/auth_controller.dart';
import '../modules/auth/login_screen.dart';
import '../modules/auth/register_screen.dart';
import '../modules/auth/splash_screen.dart';
import '../modules/home/home_screen.dart';
import '../modules/library/library_controllers.dart';
import '../modules/library/topic_detail_screen.dart';
import '../modules/library/topic_list_screen.dart';
import 'app_routes.dart';

/// Redirige al login si se intenta abrir una ruta protegida sin sesión.
///
/// Es una protección de navegación; la autorización real la aplica el
/// backend en cada petición.
class AuthGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final auth = Get.find<AuthController>();
    if (!auth.isAuthenticated) {
      return const RouteSettings(name: AppRoutes.login);
    }
    return null;
  }
}

abstract class AppPages {
  static final pages = <GetPage<dynamic>>[
    GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
    GetPage(name: AppRoutes.login, page: () => const LoginScreen()),
    GetPage(name: AppRoutes.register, page: () => const RegisterScreen()),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeScreen(),
      middlewares: [AuthGuard()],
      binding: BindingsBuilder(
        () => Get.lazyPut(() => AreasController(Get.find())),
      ),
    ),
    GetPage(
      name: AppRoutes.topics,
      page: () => const TopicListScreen(),
      middlewares: [AuthGuard()],
      binding: BindingsBuilder(() {
        final area = Get.arguments;
        Get.put(
          TopicListController(
            Get.find(),
            area: area is AreaSummary ? area : null,
          ),
        );
      }),
    ),
    GetPage(
      name: AppRoutes.topic,
      page: () => const TopicDetailScreen(),
      middlewares: [AuthGuard()],
      binding: BindingsBuilder(() {
        Get.put(
          TopicDetailController(Get.find(), Get.find(), Get.arguments as int),
        );
      }),
    ),
  ];
}
