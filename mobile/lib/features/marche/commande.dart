import '../../core/format.dart';

enum MoyenPaiement { wave, orangeMoney }

enum StatutCommande {
  aPayer('a_payer', 'À payer'),
  paiementSignale('paiement_signale', 'Paiement signalé'),
  confirmee('confirmee', 'Confirmée'),
  expiree('expiree', 'Expirée'),
  refusee('refusee', 'Refusée');

  const StatutCommande(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static StatutCommande fromApi(Object? value) => values.firstWhere(
    (status) => status.apiValue == value,
    orElse: () => aPayer,
  );
}

class Commande {
  const Commande({
    required this.id,
    required this.annonceId,
    required this.annonceTitre,
    required this.annonceUnite,
    required this.acheteurNom,
    required this.vendeurNom,
    required this.quantite,
    required this.prixUnitaire,
    required this.total,
    required this.moyenPaiement,
    required this.telephonePaiement,
    required this.statut,
    required this.dateExpiration,
    required this.dateCreation,
  });

  final int id;
  final int annonceId;
  final String annonceTitre;
  final String annonceUnite;
  final String acheteurNom;
  final String vendeurNom;
  final double quantite;
  final int prixUnitaire;
  final int total;
  final MoyenPaiement moyenPaiement;
  final String telephonePaiement;
  final StatutCommande statut;
  final DateTime dateExpiration;
  final DateTime dateCreation;

  factory Commande.fromJson(Map<String, dynamic> json) => Commande(
    id: json['id'] as int,
    annonceId: json['annonce'] as int,
    annonceTitre: json['annonce_titre'] as String? ?? '',
    annonceUnite: json['annonce_unite'] as String? ?? '',
    acheteurNom: json['acheteur_nom'] as String? ?? '',
    vendeurNom: json['vendeur_nom'] as String? ?? '',
    quantite: parseDouble(json['quantite']),
    prixUnitaire: parseDouble(json['prix_unitaire']).round(),
    total: parseDouble(json['total']).round(),
    moyenPaiement: json['moyen_paiement'] == 'orange_money'
        ? MoyenPaiement.orangeMoney
        : MoyenPaiement.wave,
    telephonePaiement: json['telephone_paiement'] as String? ?? '',
    statut: StatutCommande.fromApi(json['statut']),
    dateExpiration: DateTime.parse(json['date_expiration'] as String),
    dateCreation: DateTime.parse(json['date_creation'] as String),
  );
}
