import 'package:dio/dio.dart';

import '../../core/api_client.dart';
import '../../core/api_exception.dart';
import 'parcelle.dart';
import 'recolte.dart';

abstract class ParcelleRepository {
  Future<List<Parcelle>> list();

  /// Parcelles non récoltées, triées par date de récolte prévue (RF-08).
  Future<List<Parcelle>> calendrier();
  Future<List<Recolte>> recoltes(int parcelleId);
  Future<Recolte> createRecolte(Recolte recolte);
  Future<void> deleteRecolte(int id);

  Future<Parcelle> create(Parcelle parcelle, {String? imagePath});
  Future<Parcelle> update(Parcelle parcelle, {String? imagePath});
  Future<void> delete(int id);
}

class ApiParcelleRepository implements ParcelleRepository {
  ApiParcelleRepository(this._client);

  static const _path = '/parcelles/';
  static const _recoltesPath = '/recoltes/';
  final ApiClient _client;

  List<Parcelle> _parse(Object? data) => [
    for (final item in data as List)
      Parcelle.fromJson(Map<String, dynamic>.from(item as Map)),
  ];

  Future<Object> _body(Parcelle parcelle, String? imagePath) async {
    if (imagePath == null) return parcelle.toJson();
    return FormData.fromMap({
      ...parcelle.toJson(),
      'image': await MultipartFile.fromFile(imagePath),
    });
  }

  @override
  Future<List<Parcelle>> list() =>
      _client.call((dio) async => _parse((await dio.get(_path)).data));

  @override
  Future<List<Parcelle>> calendrier() => _client.call(
    (dio) async => _parse((await dio.get('${_path}calendrier/')).data),
  );

  @override
  Future<List<Recolte>> recoltes(int parcelleId) => _client.call(
    (dio) async => [
      for (final item
          in (await dio.get(
            _recoltesPath,
            queryParameters: {'parcelle': parcelleId},
          )).data as List)
        Recolte.fromJson(Map<String, dynamic>.from(item as Map)),
    ],
  );

  @override
  Future<Recolte> createRecolte(Recolte recolte) => _client.call(
    (dio) async => Recolte.fromJson(
      Map<String, dynamic>.from(
        (await dio.post(_recoltesPath, data: recolte.toJson())).data as Map,
      ),
    ),
  );

  @override
  Future<void> deleteRecolte(int id) =>
      _client.call((dio) => dio.delete('$_recoltesPath$id/'));

  @override
  Future<Parcelle> create(Parcelle parcelle, {String? imagePath}) =>
      _client.call((dio) async {
        final response = await dio.post(
          _path,
          data: await _body(parcelle, imagePath),
        );
        return Parcelle.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      });

  @override
  Future<Parcelle> update(Parcelle parcelle, {String? imagePath}) =>
      _client.call((dio) async {
        final response = await dio.patch(
          '$_path${parcelle.id}/',
          data: await _body(parcelle, imagePath),
        );
        return Parcelle.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
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
  final List<Recolte> _recoltes = [];
  int _nextId = 4;
  int _nextRecolteId = 1;

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
  Future<List<Recolte>> recoltes(int parcelleId) async =>
      _recoltes.where((recolte) => recolte.parcelleId == parcelleId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  @override
  Future<Recolte> createRecolte(Recolte recolte) async {
    if (recolte.quantite <= 0) {
      throw ApiException('La quantité récoltée doit être supérieure à zéro.');
    }
    final created = recolte.copyWith(id: _nextRecolteId++);
    _recoltes.add(created);
    return created;
  }

  @override
  Future<void> deleteRecolte(int id) async =>
      _recoltes.removeWhere((recolte) => recolte.id == id);

  @override
  Future<Parcelle> create(Parcelle parcelle, {String? imagePath}) async {
    _valider(parcelle);
    final created = parcelle.copyWith(id: _nextId++);
    _parcelles.add(created);
    return created;
  }

  @override
  Future<Parcelle> update(Parcelle parcelle, {String? imagePath}) async {
    _valider(parcelle);
    final index = _parcelles.indexWhere((p) => p.id == parcelle.id);
    if (index == -1) throw ApiException('Parcelle introuvable.');
    _parcelles[index] = parcelle;
    return parcelle;
  }

  @override
  Future<void> delete(int id) async {
    _parcelles.removeWhere((p) => p.id == id);
    _recoltes.removeWhere((recolte) => recolte.parcelleId == id);
  }
}
