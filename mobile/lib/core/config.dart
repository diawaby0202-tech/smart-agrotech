/// Configuration de l'application, surchargeable au lancement avec
/// `--dart-define` (voir mobile/README.md).
class AppConfig {
  /// L'application utilise le backend Django par défaut.
  /// Passer `--dart-define=USE_MOCK=true` pour utiliser les données fictives.
  static const bool useMock = bool.fromEnvironment(
    'USE_MOCK',
    defaultValue: false,
  );

  /// `10.0.2.2` correspond au `localhost` du PC vu depuis l'émulateur Android.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );
}
