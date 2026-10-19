import 'package:get/get.dart';

import '../core/config/app_config.dart';
import '../core/network/api_client.dart';
import '../core/security/token_storage.dart';
import '../core/services/link_opener.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/community_repository.dart';
import '../data/repositories/library_repository.dart';
import '../data/services/auth_service.dart';
import '../data/services/community_service.dart';
import '../data/services/library_service.dart';
import '../modules/auth/auth_controller.dart';
import 'app_routes.dart';

/// Dependencias compartidas de toda la app.
class InitialBinding extends Bindings {
  /// Los parámetros permiten inyectar dobles en pruebas.
  InitialBinding({this._tokenStorage, this._apiClient, this._linkOpener});

  final TokenStorage? _tokenStorage;
  final ApiClient? _apiClient;
  final LinkOpener? _linkOpener;

  @override
  void dependencies() {
    final storage = _tokenStorage ?? SecureTokenStorage();
    final client =
        _apiClient ??
        ApiClient(
          config: AppConfig.fromEnvironment(),
          tokenStorage: storage,
          onSessionExpired: () =>
              Get.find<AuthController>().handleSessionExpired(),
        );

    Get.put<TokenStorage>(storage, permanent: true);
    Get.put<ApiClient>(client, permanent: true);
    Get.put(AuthService(client.dio), permanent: true);
    Get.put(
      AuthRepository(service: Get.find(), tokenStorage: storage),
      permanent: true,
    );
    final auth = Get.put(AuthController(Get.find()), permanent: true);
    Get.put(LibraryRepository(LibraryService(client.dio)), permanent: true);
    Get.put(CommunityRepository(CommunityService(client.dio)), permanent: true);
    Get.put<LinkOpener>(
      _linkOpener ?? UrlLauncherLinkOpener(),
      permanent: true,
    );

    // Si la sesión termina (logout o expiración) se vuelve al login.
    ever<AuthStatus>(auth.status, (status) {
      if (status == AuthStatus.unauthenticated &&
          AppRoutes.protected.contains(Get.currentRoute)) {
        Get.offAllNamed<void>(AppRoutes.login);
      }
    });
  }
}
