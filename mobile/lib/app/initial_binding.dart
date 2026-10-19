import 'package:get/get.dart';

import '../core/config/app_config.dart';
import '../core/network/api_client.dart';
import '../core/security/token_storage.dart';
import '../core/services/link_opener.dart';
import '../data/repositories/assistant_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/community_repository.dart';
import '../data/repositories/library_repository.dart';
import '../data/repositories/local_library_repository.dart';
import '../data/services/assistant_service.dart';
import '../data/services/auth_service.dart';
import '../data/services/community_service.dart';
import '../data/services/library_service.dart';
import '../data/services/local_library_store.dart';
import '../modules/auth/auth_controller.dart';
import '../modules/local_library/local_library_controller.dart';
import 'app_routes.dart';

/// Dependencias compartidas de toda la app.
class InitialBinding extends Bindings {
  /// Los parámetros permiten inyectar dobles en pruebas.
  InitialBinding({
    this._tokenStorage,
    this._apiClient,
    this._linkOpener,
    this._localStore,
  });

  final TokenStorage? _tokenStorage;
  final ApiClient? _apiClient;
  final LinkOpener? _linkOpener;
  final LocalLibraryStore? _localStore;

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
    Get.put(AssistantRepository(AssistantService(client.dio)), permanent: true);
    Get.put(CommunityRepository(CommunityService(client.dio)), permanent: true);
    Get.put<LinkOpener>(
      _linkOpener ?? UrlLauncherLinkOpener(),
      permanent: true,
    );

    final local = Get.put(
      LocalLibraryController(
        LocalLibraryRepository(_localStore ?? HiveLocalLibraryStore()),
      ),
      permanent: true,
    );

    // Favoritos y notas siguen a la cuenta con sesión: se abren al entrar y
    // se cierran (sin borrarse) al salir, de modo que otra cuenta no los ve.
    ever(auth.user, (user) {
      if (user != null) {
        local.activateFor(user.id);
      } else {
        local.deactivate();
      }
    });

    // Si la sesión termina (logout o expiración) se vuelve al login.
    ever<AuthStatus>(auth.status, (status) {
      if (status == AuthStatus.unauthenticated &&
          AppRoutes.protected.contains(Get.currentRoute)) {
        Get.offAllNamed<void>(AppRoutes.login);
      }
    });
  }
}
