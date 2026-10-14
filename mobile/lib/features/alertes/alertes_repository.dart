import '../../core/api_client.dart';
import 'alertes_models.dart';

abstract class AlertesRepository {
  /// Prévisions sur 5 jours et risques détectés pour [ville].
  Future<Meteo> meteo(String ville);

  /// Historique des alertes, de la plus récente à la plus ancienne.
  Future<List<Alerte>> alertes();

  Future<void> marquerLue(int id);
  Future<void> toutMarquerLu();

  /// Demande au serveur de créer les alertes du jour (météo des parcelles,
  /// récoltes proches, vaccinations à venir). Renvoie le nombre créé.
  Future<int> generer();
}

class ApiAlertesRepository implements AlertesRepository {
  ApiAlertesRepository(this._client);

  static const _path = '/alertes/';
  final ApiClient _client;

  @override
  Future<Meteo> meteo(String ville) => _client.call((dio) async {
    final response = await dio.get(
      '/meteo/',
      queryParameters: {'ville': ville},
    );
    return Meteo.fromJson(Map<String, dynamic>.from(response.data as Map));
  });

  @override
  Future<List<Alerte>> alertes() => _client.call(
    (dio) async => [
      for (final item in (await dio.get(_path)).data as List)
        Alerte.fromJson(Map<String, dynamic>.from(item as Map)),
    ],
  );

  @override
  Future<void> marquerLue(int id) =>
      _client.call((dio) => dio.post('$_path$id/marquer_lue/'));

  @override
  Future<void> toutMarquerLu() =>
      _client.call((dio) => dio.post('${_path}tout_marquer_lu/'));

  @override
  Future<int> generer() => _client.call((dio) async {
    final response = await dio.post('${_path}generer/');
    return (response.data as Map)['creees'] as int? ?? 0;
  });
}

/// Données fictives en mémoire (mode démo).
class MockAlertesRepository implements AlertesRepository {
  MockAlertesRepository() {
    final now = DateTime.now();
    _alertes.addAll([
      Alerte(
        id: 3,
        type: TypeAlerte.vaccination,
        niveau: NiveauAlerte.attention,
        titre: 'Traitement à prévoir — Mouton Lot Tabaski',
        message: 'Échéance de traitement dans 2 jours.',
        dateCreation: now.subtract(const Duration(hours: 1)),
      ),
      Alerte(
        id: 2,
        type: TypeAlerte.culture,
        niveau: NiveauAlerte.info,
        titre: 'Récolte proche : Champ nord',
        message: 'Récolte de Arachide prévue dans 5 jours.',
        zone: 'Thiès',
        dateCreation: now.subtract(const Duration(hours: 3)),
      ),
      Alerte(
        id: 1,
        type: TypeAlerte.meteo,
        niveau: NiveauAlerte.danger,
        titre: 'Fortes pluies (Thiès)',
        message: "28 mm de pluie prévus. Risque d'inondation des parcelles.",
        zone: 'Thiès',
        lue: true,
        dateCreation: now.subtract(const Duration(days: 2)),
      ),
    ]);
  }

  final List<Alerte> _alertes = [];

  @override
  Future<Meteo> meteo(String ville) async {
    final today = DateTime.now();
    const jours = [
      (31.0, 24.0, 0.0, 5.0, 'ciel dégagé'),
      (33.0, 25.0, 0.0, 6.5, 'peu nuageux'),
      (38.0, 27.0, 0.0, 7.0, 'ensoleillé'),
      (30.0, 24.0, 24.5, 9.0, 'pluie modérée'),
      (29.0, 23.0, 3.0, 16.0, 'nuageux'),
    ];
    return Meteo(
      ville: ville,
      previsions: [
        for (final (index, jour) in jours.indexed)
          JourMeteo(
            date: today.add(Duration(days: index)),
            tempMax: jour.$1,
            tempMin: jour.$2,
            pluieMm: jour.$3,
            ventMaxMs: jour.$4,
            description: jour.$5,
          ),
      ],
      risques: const [
        RisqueMeteo(
          niveau: NiveauAlerte.attention,
          titre: 'Forte chaleur dans 2 jours',
          message: "Jusqu'à 38 °C prévus.",
        ),
        RisqueMeteo(
          niveau: NiveauAlerte.danger,
          titre: 'Fortes pluies dans 3 jours',
          message:
              "24,5 mm de pluie prévus. Risque d'inondation des parcelles.",
        ),
      ],
    );
  }

  @override
  Future<List<Alerte>> alertes() async => List.of(_alertes);

  @override
  Future<void> marquerLue(int id) async {
    final index = _alertes.indexWhere((a) => a.id == id);
    if (index != -1) _alertes[index] = _alertes[index].marquerLue();
  }

  @override
  Future<void> toutMarquerLu() async {
    for (var i = 0; i < _alertes.length; i++) {
      _alertes[i] = _alertes[i].marquerLue();
    }
  }

  @override
  Future<int> generer() async => 0;
}
