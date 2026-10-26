import '../../core/api_client.dart';
import '../../core/api_exception.dart';
import '../../core/format.dart';
import 'elevage_models.dart';

abstract class ElevageRepository {
  Future<List<Animal>> animaux();
  Future<Animal> createAnimal(Animal animal);
  Future<Animal> updateAnimal(Animal animal);
  Future<void> deleteAnimal(int id);

  /// Historique sanitaire d'un animal, du plus récent au plus ancien.
  Future<List<SuiviSanitaire>> suivis(int animalId);

  /// Tous les suivis de l'utilisateur, pour calculer l'état de santé de
  /// chaque animal.
  Future<List<SuiviSanitaire>> tousLesSuivis();
  Future<SuiviSanitaire> createSuivi(SuiviSanitaire suivi);
  Future<void> deleteSuivi(int id);

  /// Suivis dont l'échéance tombe dans les [jours] prochains jours (RF-12).
  Future<List<SuiviSanitaire>> echeances({int jours = 30});
}

class ApiElevageRepository implements ElevageRepository {
  ApiElevageRepository(this._client);

  static const _animaux = '/animaux/';
  static const _suivis = '/suivis-sanitaires/';
  final ApiClient _client;

  Map<String, dynamic> _map(Object? data) =>
      Map<String, dynamic>.from(data as Map);

  List<SuiviSanitaire> _parseSuivis(Object? data) => [
    for (final item in data as List) SuiviSanitaire.fromJson(_map(item)),
  ];

  @override
  Future<List<Animal>> animaux() => _client.call(
    (dio) async => [
      for (final item in (await dio.get(_animaux)).data as List)
        Animal.fromJson(_map(item)),
    ],
  );

  @override
  Future<Animal> createAnimal(Animal animal) => _client.call(
    (dio) async => Animal.fromJson(
      _map((await dio.post(_animaux, data: animal.toJson())).data),
    ),
  );

  @override
  Future<Animal> updateAnimal(Animal animal) => _client.call(
    (dio) async => Animal.fromJson(
      _map(
        (await dio.patch('$_animaux${animal.id}/', data: animal.toJson())).data,
      ),
    ),
  );

  @override
  Future<void> deleteAnimal(int id) =>
      _client.call((dio) => dio.delete('$_animaux$id/'));

  @override
  Future<List<SuiviSanitaire>> suivis(int animalId) => _client.call(
    (dio) async => _parseSuivis(
      (await dio.get(_suivis, queryParameters: {'animal': animalId})).data,
    ),
  );

  @override
  Future<List<SuiviSanitaire>> tousLesSuivis() =>
      _client.call((dio) async => _parseSuivis((await dio.get(_suivis)).data));

  @override
  Future<SuiviSanitaire> createSuivi(SuiviSanitaire suivi) => _client.call(
    (dio) async => SuiviSanitaire.fromJson(
      _map((await dio.post(_suivis, data: suivi.toJson())).data),
    ),
  );

  @override
  Future<void> deleteSuivi(int id) =>
      _client.call((dio) => dio.delete('$_suivis$id/'));

  @override
  Future<List<SuiviSanitaire>> echeances({int jours = 30}) => _client.call(
    (dio) async => _parseSuivis(
      (await dio.get(
        '${_suivis}echeances/',
        queryParameters: {'jours': jours},
      )).data,
    ),
  );
}

/// Données fictives en mémoire (mode démo).
class MockElevageRepository implements ElevageRepository {
  MockElevageRepository() {
    final now = DateTime.now();
    _animaux.addAll([
      Animal(
        id: 1,
        espece: 'Vache',
        race: 'Gobra',
        identifiant: 'SN-0142',
        dateNaissance: DateTime(now.year - 4, 3, 12),
      ),
      const Animal(
        id: 2,
        espece: 'Mouton',
        race: 'Ladoum',
        identifiant: 'Lot Tabaski',
        effectif: 12,
      ),
      const Animal(
        id: 3,
        espece: 'Poulet',
        identifiant: 'Poulailler A',
        effectif: 150,
      ),
    ]);
    _suivis.addAll([
      SuiviSanitaire(
        id: 1,
        animalId: 1,
        type: TypeSuivi.vaccination,
        date: now.subtract(const Duration(days: 170)),
        description: 'Vaccin contre la péripneumonie',
        prochaineEcheance: now.add(const Duration(days: 10)),
      ),
      SuiviSanitaire(
        id: 2,
        animalId: 2,
        type: TypeSuivi.traitement,
        date: now.subtract(const Duration(days: 28)),
        description: 'Déparasitage',
        prochaineEcheance: now.add(const Duration(days: 2)),
      ),
      SuiviSanitaire(
        id: 3,
        animalId: 3,
        type: TypeSuivi.visite,
        date: now.subtract(const Duration(days: 5)),
        description: 'Contrôle vétérinaire du poulailler',
      ),
    ]);
  }

  final List<Animal> _animaux = [];
  final List<SuiviSanitaire> _suivis = [];
  int _nextAnimalId = 4;
  int _nextSuiviId = 4;

  @override
  Future<List<Animal>> animaux() async => _animaux.reversed.toList();

  @override
  Future<Animal> createAnimal(Animal animal) async {
    if (animal.effectif < 1) {
      const message = "L'effectif doit être au moins 1.";
      throw ApiException(message, fieldErrors: {'effectif': message});
    }
    final created = animal.copyWith(id: _nextAnimalId++);
    _animaux.add(created);
    return created;
  }

  @override
  Future<Animal> updateAnimal(Animal animal) async {
    final index = _animaux.indexWhere((a) => a.id == animal.id);
    if (index == -1) throw ApiException('Animal introuvable.');
    _animaux[index] = animal;
    return animal;
  }

  @override
  Future<void> deleteAnimal(int id) async {
    _animaux.removeWhere((a) => a.id == id);
    _suivis.removeWhere((s) => s.animalId == id);
  }

  @override
  Future<List<SuiviSanitaire>> suivis(int animalId) async =>
      _suivis.where((s) => s.animalId == animalId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  @override
  Future<List<SuiviSanitaire>> tousLesSuivis() async => List.of(_suivis);

  @override
  Future<SuiviSanitaire> createSuivi(SuiviSanitaire suivi) async {
    final echeance = suivi.prochaineEcheance;
    if (echeance != null && echeance.isBefore(suivi.date)) {
      throw ApiException("L'échéance doit être après la date du suivi.");
    }
    final created = suivi.copyWith(id: _nextSuiviId++);
    _suivis.add(created);
    return created;
  }

  @override
  Future<void> deleteSuivi(int id) async =>
      _suivis.removeWhere((s) => s.id == id);

  @override
  Future<List<SuiviSanitaire>> echeances({int jours = 30}) async =>
      _suivis.where((s) {
          final echeance = s.prochaineEcheance;
          if (echeance == null) return false;
          final reste = joursRestants(echeance);
          return reste >= 0 && reste <= jours;
        }).toList()
        ..sort((a, b) => a.prochaineEcheance!.compareTo(b.prochaineEcheance!));
}
