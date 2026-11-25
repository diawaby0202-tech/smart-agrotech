import 'package:dio/dio.dart';

import '../../core/api_client.dart';
import '../../core/api_exception.dart';
import 'annonce.dart';

abstract class AnnonceRepository {
  /// Annonces disponibles correspondant au filtre (RF-17).
  Future<List<Annonce>> list(FiltreAnnonces filtre);

  /// Annonces de l'utilisateur connecté, tous statuts confondus (RF-19).
  Future<List<Annonce>> mesAnnonces();

  /// [imagePath] : chemin d'une photo choisie sur le téléphone (facultatif).
  Future<Annonce> create(Annonce annonce, {String? imagePath});
  Future<Annonce> update(Annonce annonce, {String? imagePath});
  Future<void> delete(int id);
}

class ApiAnnonceRepository implements AnnonceRepository {
  ApiAnnonceRepository(this._client);

  static const _path = '/annonces/';
  final ApiClient _client;

  Annonce _one(Object? data) =>
      Annonce.fromJson(Map<String, dynamic>.from(data as Map));

  List<Annonce> _many(Object? data) => [
    for (final item in data as List) _one(item),
  ];

  /// JSON simple, ou formulaire multipart quand une photo est jointe.
  Future<Object> _body(Annonce annonce, String? imagePath) async {
    if (imagePath == null) return annonce.toJson();
    return FormData.fromMap({
      ...annonce.toJson(),
      'image': await MultipartFile.fromFile(imagePath),
    });
  }

  @override
  Future<List<Annonce>> list(FiltreAnnonces filtre) => _client.call(
    (dio) async =>
        _many((await dio.get(_path, queryParameters: filtre.toQuery())).data),
  );

  @override
  Future<List<Annonce>> mesAnnonces() => _client.call(
    (dio) async => _many((await dio.get('${_path}mes_annonces/')).data),
  );

  @override
  Future<Annonce> create(Annonce annonce, {String? imagePath}) => _client.call(
    (dio) async => _one(
      (await dio.post(_path, data: await _body(annonce, imagePath))).data,
    ),
  );

  @override
  Future<Annonce> update(Annonce annonce, {String? imagePath}) => _client.call(
    (dio) async => _one(
      (await dio.patch(
        '$_path${annonce.id}/',
        data: await _body(annonce, imagePath),
      )).data,
    ),
  );

  @override
  Future<void> delete(int id) =>
      _client.call((dio) => dio.delete('$_path$id/'));
}

/// Données en mémoire (mode démo). Les photos ne sont pas conservées.
class MockAnnonceRepository implements AnnonceRepository {
  final List<Annonce> _annonces = [];
  int _nextId = 1;

  @override
  Future<List<Annonce>> list(FiltreAnnonces filtre) async =>
      _annonces.where(filtre.accepte).toList();

  @override
  Future<List<Annonce>> mesAnnonces() async =>
      _annonces.where((a) => a.estProprietaire).toList();

  @override
  Future<Annonce> create(Annonce annonce, {String? imagePath}) async {
    if (annonce.prix < 0) {
      const message = 'Le prix ne peut pas être négatif.';
      throw ApiException(message, fieldErrors: {'prix': message});
    }
    final created = annonce.copyWith(
      id: _nextId++,
      vendeurNom: 'Awa Diop',
      vendeurTelephone: '771234567',
      estProprietaire: true,
      dateCreation: DateTime.now(),
    );
    _annonces.insert(0, created);
    return created;
  }

  @override
  Future<Annonce> update(Annonce annonce, {String? imagePath}) async {
    final index = _annonces.indexWhere((a) => a.id == annonce.id);
    if (index == -1) throw ApiException('Annonce introuvable.');
    _annonces[index] = annonce;
    return annonce;
  }

  @override
  Future<void> delete(int id) async => _annonces.removeWhere((a) => a.id == id);
}
