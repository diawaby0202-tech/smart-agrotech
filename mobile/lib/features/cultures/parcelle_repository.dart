import '../../core/api_client.dart';
import '../../core/api_exception.dart';
import 'parcelle.dart';

abstract class ParcelleRepository {
  Future<List<Parcelle>> list();

  /// Parcelles non récoltées, triées par date de récolte prévue (RF-08).
  Future<List<Parcelle>> calendrier();

  Future<Parcelle> create(Parcelle parcelle);
  Future<Parcelle> update(Parcelle parcelle);
  Future<void> delete(int id);
}

class ApiParcelleRepository implements ParcelleRepository {
  ApiParcelleRepository(this._client);

  static const _path = '/parcelles/';
  final ApiClient _client;

  List<Parcelle> _parse(Object? data) => [
    for (final item in data as List)
      Parcelle.fromJson(Map<String, dynamic>.from(item as Map)),
  ];

  @override
  Future<List<Parcelle>> list() =>
      _client.call((dio) async => _parse((await dio.get(_path)).data));

  @override
  Future<List<Parcelle>> calendrier() => _client.call(
    (dio) async => _parse((await dio.get('${_path}calendrier/')).data),
  );

  @override
  Future<Parcelle> create(Parcelle parcelle) => _client.call((dio) async {
    final response = await dio.post(_path, data: parcelle.toJson());
    return Parcelle.fromJson(Map<String, dynamic>.from(response.data as Map));
  });

  @override
  Future<Parcelle> update(Parcelle parcelle) => _client.call((dio) async {
    final response = await dio.patch(
      '$_path${parcelle.id}/',
      data: parcelle.toJson(),
    );
    return Parcelle.fromJson(Map<String, dynamic>.from(response.data as Map));
  });

  @override
  Future<void> delete(int id) =>
      _client.call((dio) => dio.delete('$_path$id/'));
}

/// Données fictives en mémoire (mode démo).
class MockParcelleRepository implements ParcelleRepository {
  MockParcelleRepository() {
    final now = DateTime.now();
    _parcelles.addAll([
      Parcelle(
        id: 1,
        nom: 'Champ nord',
        culture: 'Arachide',
        superficie: 2.5,
        localisation: 'Thiès',
        dateSemis: now.subtract(const Duration(days: 80)),
        dateRecoltePrevue: now.add(const Duration(days: 5)),
        statut: StatutParcelle.croissance,
      ),
      Parcelle(
        id: 2,
        nom: 'Jardin maraîcher',
        culture: 'Tomate',
        superficie: 0.5,
        localisation: 'Dakar',
        dateSemis: now.subtract(const Duration(days: 20)),
        dateRecoltePrevue: now.add(const Duration(days: 45)),
        statut: StatutParcelle.semee,
      ),
      Parcelle(
        id: 3,
        nom: 'Parcelle du fleuve',
        culture: 'Riz',
        superficie: 4,
        localisation: 'Saint-Louis',
        statut: StatutParcelle.preparation,
      ),
    ]);
  }

  final List<Parcelle> _parcelles = [];
  int _nextId = 4;

  void _valider(Parcelle p) {
    if (p.superficie <= 0) {
      const message = 'La superficie doit être positive.';
      throw ApiException(message, fieldErrors: {'superficie': message});
    }
    final semis = p.dateSemis;
    final recolte = p.dateRecoltePrevue;
    if (semis != null && recolte != null && recolte.isBefore(semis)) {
      throw ApiException(
        'La date de récolte doit être après la date de semis.',
      );
    }
  }

  @override
  Future<List<Parcelle>> list() async => _parcelles.reversed.toList();

  @override
  Future<List<Parcelle>> calendrier() async =>
      _parcelles
          .where(
            (p) =>
                p.statut != StatutParcelle.recoltee &&
                p.dateRecoltePrevue != null,
          )
          .toList()
        ..sort((a, b) => a.dateRecoltePrevue!.compareTo(b.dateRecoltePrevue!));

  @override
  Future<Parcelle> create(Parcelle parcelle) async {
    _valider(parcelle);
    final created = parcelle.copyWith(id: _nextId++);
    _parcelles.add(created);
    return created;
  }

  @override
  Future<Parcelle> update(Parcelle parcelle) async {
    _valider(parcelle);
    final index = _parcelles.indexWhere((p) => p.id == parcelle.id);
    if (index == -1) throw ApiException('Parcelle introuvable.');
    _parcelles[index] = parcelle;
    return parcelle;
  }

  @override
  Future<void> delete(int id) async =>
      _parcelles.removeWhere((p) => p.id == id);
}
