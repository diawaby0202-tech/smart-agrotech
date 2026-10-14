import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/alertes/alertes_models.dart';
import '../features/alertes/alertes_repository.dart';

/// Affiche une notification sur le téléphone.
abstract class Notifier {
  Future<void> show({
    required int id,
    required String title,
    required String body,
  });
}

/// Notifications système (Android / iOS).
class LocalNotifier implements Notifier {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> _init() async {
    if (_ready) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    // Android 13+ : l'utilisateur doit autoriser les notifications.
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    _ready = true;
  }

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    await _init();
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'rappels',
          'Rappels et alertes',
          channelDescription:
              'Alertes météo, récoltes proches et échéances sanitaires',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}

/// Ne fait rien (web, tests).
class NoopNotifier implements Notifier {
  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {}
}

/// Rappels et alertes (RF-27).
///
/// À chaque synchronisation, demande au serveur de générer les alertes du
/// jour puis notifie celles qui sont nouvelles et non lues. La synchronisation
/// a lieu quand l'app est ouverte : sans service de push côté serveur, aucune
/// notification n'arrive quand l'app est fermée.
class RappelService {
  RappelService(this._repository, this._notifier);

  static const _lastIdKey = 'derniere_alerte_notifiee';

  final AlertesRepository _repository;
  final Notifier _notifier;

  /// Nombre d'alertes non lues, pour la pastille de l'accueil.
  final ValueNotifier<int> nonLues = ValueNotifier(0);

  /// Renvoie le nombre de notifications affichées.
  Future<int> synchroniser() async {
    try {
      await _repository.generer();
    } catch (_) {
      // La génération est facultative : on affiche quand même l'existant.
    }

    final List<Alerte> alertes;
    try {
      alertes = await _repository.alertes();
    } catch (_) {
      return 0;
    }

    final nouvelles = alertes.where((a) => !a.lue).toList();
    nonLues.value = nouvelles.length;

    final prefs = await SharedPreferences.getInstance();
    final dernierId = prefs.getInt(_lastIdKey) ?? 0;
    final aNotifier = nouvelles.where((a) => a.id > dernierId).toList();
    for (final alerte in aNotifier) {
      await _notifier.show(
        id: alerte.id,
        title: alerte.titre,
        body: alerte.message,
      );
    }
    if (aNotifier.isNotEmpty) {
      final maxId = aNotifier.map((a) => a.id).reduce((a, b) => a > b ? a : b);
      await prefs.setInt(_lastIdKey, maxId);
    }
    return aNotifier.length;
  }

  /// À la déconnexion : le prochain utilisateur repart de zéro.
  Future<void> reinitialiser() async {
    nonLues.value = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastIdKey);
  }
}
