import '../features/alertes/alertes_repository.dart';
import '../features/auth/auth_provider.dart';
import '../features/auth/auth_repository.dart';
import '../features/auth/mock_auth_repository.dart';
import '../features/cultures/parcelle_repository.dart';
import '../features/elevage/elevage_repository.dart';
import '../features/marche/annonce_repository.dart';
import 'api_client.dart';
import 'notification_service.dart';
import 'token_storage.dart';

/// Tous les services de l'application, créés une seule fois au démarrage.
///
/// En mode démo ([useMock]), chaque dépôt renvoie des données fictives ; sinon
/// il appelle l'API Django.
class AppServices {
  AppServices({
    required this.auth,
    required this.parcelles,
    required this.elevage,
    required this.alertes,
    required this.annonces,
    required this.rappels,
  });

  factory AppServices.create({
    required TokenStorage storage,
    required bool useMock,
    required Notifier notifier,
    Duration mockDelay = const Duration(milliseconds: 600),
  }) {
    final client = ApiClient(storage: storage);
    final AuthRepository authRepository = useMock
        ? MockAuthRepository(storage, delay: mockDelay)
        : ApiAuthRepository(client, storage);
    final auth = AuthProvider(authRepository);
    client.onSessionExpired = auth.onSessionExpired;

    final AlertesRepository alertes = useMock
        ? MockAlertesRepository()
        : ApiAlertesRepository(client);

    return AppServices(
      auth: auth,
      parcelles: useMock
          ? MockParcelleRepository()
          : ApiParcelleRepository(client),
      elevage: useMock ? MockElevageRepository() : ApiElevageRepository(client),
      alertes: alertes,
      annonces: useMock
          ? MockAnnonceRepository()
          : ApiAnnonceRepository(client),
      rappels: RappelService(alertes, notifier),
    );
  }

  final AuthProvider auth;
  final ParcelleRepository parcelles;
  final ElevageRepository elevage;
  final AlertesRepository alertes;
  final AnnonceRepository annonces;
  final RappelService rappels;
}
