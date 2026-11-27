import '../../core/api_client.dart';
import '../../core/api_exception.dart';
import 'annonce.dart';
import 'annonce_repository.dart';
import 'commande.dart';

abstract class CommandeRepository {
  Future<List<Commande>> list();
  Future<Commande> create({
    required int annonceId,
    required double quantite,
    required MoyenPaiement moyenPaiement,
  });
  Future<Commande> signalerPaiement(int id);
  Future<Commande> confirmer(int id);
}

class ApiCommandeRepository implements CommandeRepository {
  ApiCommandeRepository(this._client);

  static const _path = '/commandes/';
  final ApiClient _client;

  Commande _parse(Object? data) =>
      Commande.fromJson(Map<String, dynamic>.from(data as Map));

  List<Commande> _parseList(Object? data) => [
    for (final item in data as List) _parse(item),
  ];

  @override
  Future<List<Commande>> list() =>
      _client.call((dio) async => _parseList((await dio.get(_path)).data));

  @override
  Future<Commande> create({
    required int annonceId,
    required double quantite,
    required MoyenPaiement moyenPaiement,
  }) => _client.call((dio) async {
    final response = await dio.post(
      _path,
      data: {
        'annonce': annonceId,
        'quantite': quantite.toString(),
        'moyen_paiement': moyenPaiement == MoyenPaiement.wave
            ? 'wave'
            : 'orange_money',
      },
    );
    return _parse(response.data);
  });

  @override
  Future<Commande> signalerPaiement(int id) => _client.call(
    (dio) async => _parse(
      (await dio.post('$_path$id/signaler_paiement/')).data,
    ),
  );

  @override
  Future<Commande> confirmer(int id) => _client.call(
    (dio) async => _parse((await dio.post('$_path$id/confirmer/')).data),
  );
}

class MockCommandeRepository implements CommandeRepository {
  MockCommandeRepository(this._annonces);

  final AnnonceRepository _annonces;
  final List<Commande> _commandes = [];
  int _nextId = 1;

  @override
  Future<List<Commande>> list() async => List.unmodifiable(_commandes);

  @override
  Future<Commande> create({
    required int annonceId,
    required double quantite,
    required MoyenPaiement moyenPaiement,
  }) async {
    final annonce = (await _annonces.list(const FiltreAnnonces())).firstWhere(
      (item) => item.id == annonceId,
      orElse: () => throw ApiException('Annonce introuvable.'),
    );
    if (annonce.stock == null ||
        annonce.unite == null ||
        annonce.statut != StatutAnnonce.disponible) {
      throw ApiException('Cette annonce ne peut pas être commandée.');
    }
    if (quantite <= 0 || quantite > annonce.stock!) {
      throw ApiException('Stock insuffisant.');
    }
    if (annonce.vendeurTelephone.isEmpty) {
      throw ApiException('Le vendeur doit renseigner son téléphone.');
    }
    final order = Commande(
      id: _nextId++,
      annonceId: annonceId,
      annonceTitre: annonce.titre,
      annonceUnite: annonce.unite!.apiValue,
      acheteurNom: 'Acheteur',
      vendeurNom: annonce.vendeurNom,
      quantite: quantite,
      prixUnitaire: annonce.prix,
      total: (annonce.prix * quantite).round(),
      moyenPaiement: moyenPaiement,
      telephonePaiement: annonce.vendeurTelephone,
      statut: StatutCommande.aPayer,
      dateExpiration: DateTime.now().add(const Duration(minutes: 30)),
      dateCreation: DateTime.now(),
    );
    _commandes.insert(0, order);
    return order;
  }

  @override
  Future<Commande> signalerPaiement(int id) async {
    final index = _commandes.indexWhere((item) => item.id == id);
    if (index < 0) throw ApiException('Commande introuvable.');
    final order = _commandes[index];
    if (order.statut != StatutCommande.aPayer) {
      throw ApiException('Cette commande ne peut plus recevoir de paiement.');
    }
    return _commandes[index] = Commande(
      id: order.id,
      annonceId: order.annonceId,
      annonceTitre: order.annonceTitre,
      annonceUnite: order.annonceUnite,
      acheteurNom: order.acheteurNom,
      vendeurNom: order.vendeurNom,
      quantite: order.quantite,
      prixUnitaire: order.prixUnitaire,
      total: order.total,
      moyenPaiement: order.moyenPaiement,
      telephonePaiement: order.telephonePaiement,
      statut: StatutCommande.paiementSignale,
      dateExpiration: order.dateExpiration,
      dateCreation: order.dateCreation,
    );
  }

  @override
  Future<Commande> confirmer(int id) async {
    final index = _commandes.indexWhere((item) => item.id == id);
    if (index < 0) throw ApiException('Commande introuvable.');
    final order = _commandes[index];
    if (order.statut != StatutCommande.paiementSignale) {
      throw ApiException('Paiement non signalé.');
    }
    return _commandes[index] = Commande(
      id: order.id,
      annonceId: order.annonceId,
      annonceTitre: order.annonceTitre,
      annonceUnite: order.annonceUnite,
      acheteurNom: order.acheteurNom,
      vendeurNom: order.vendeurNom,
      quantite: order.quantite,
      prixUnitaire: order.prixUnitaire,
      total: order.total,
      moyenPaiement: order.moyenPaiement,
      telephonePaiement: order.telephonePaiement,
      statut: StatutCommande.confirmee,
      dateExpiration: order.dateExpiration,
      dateCreation: order.dateCreation,
    );
  }
}
