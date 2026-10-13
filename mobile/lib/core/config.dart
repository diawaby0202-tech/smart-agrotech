/// Configuration de l'application, surchargeable au lancement avec
/// `--dart-define` (voir mobile/README.md).
class AppConfig {
  /// Tant que le backend n'est pas prêt, l'app tourne avec des données fictives.
  /// Passer `--dart-define=USE_MOCK=false` pour utiliser la vraie API.
  static const bool useMock = bool.fromEnvironment(
    'USE_MOCK',
    defaultValue: true,
  );

  /// `10.0.2.2` correspond au `localhost` du PC vu depuis l'émulateur Android.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );
}
