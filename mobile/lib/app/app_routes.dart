/// Nombres de rutas de la app.
abstract class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';

  /// Argumento opcional: `AreaSummary` (sin él, todas las fichas).
  static const topics = '/topics';

  /// Argumento obligatorio: id (`int`) de la ficha.
  static const topic = '/topic';

  static const favorites = '/favorites';
  static const assistant = '/assistant';
  static const history = '/history';

  /// Argumento obligatorio: id (`int`) de la consulta.
  static const consultation = '/consultation';

  /// Rutas que exigen sesión.
  static const protected = {
    home,
    topics,
    topic,
    favorites,
    assistant,
    history,
    consultation,
  };
}
