import '../../core/format.dart';

enum CategorieAnnonce {
  cereales('cereales', 'Céréales'),
  legumes('legumes', 'Légumes'),
  fruits('fruits', 'Fruits'),
  betail('betail', 'Bétail'),
  intrants('intrants', 'Intrants / matériel'),
  autre('autre', 'Autre');

  const CategorieAnnonce(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static CategorieAnnonce fromApi(Object? value) =>
      values.firstWhere((c) => c.apiValue == value, orElse: () => autre);
}

enum StatutAnnonce {
  disponible('disponible', 'Disponible'),
  vendue('vendue', 'Vendue'),
  retiree('retiree', 'Retirée');

  const StatutAnnonce(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static StatutAnnonce fromApi(Object? value) =>
      values.firstWhere((s) => s.apiValue == value, orElse: () => disponible);
}

/// Annonce de vente sur le marché agricole (RF-16).
class Annonce {
  const Annonce({
    this.id,
    required this.titre,
    this.description = '',
    required this.categorie,
    required this.prix,
    this.quantite = '',
    this.zone = '',
    this.photoUrl = '',
    this.statut = StatutAnnonce.disponible,
    this.vendeurNom = '',
    this.vendeurTelephone = '',
    this.estProprietaire = false,
    this.dateCreation,
  });

  final int? id;
  final String titre;
  final String description;
  final CategorieAnnonce categorie;

  /// En FCFA.
  final int prix;

  /// Texte libre : « 50 kg », « 3 têtes ».
  final String quantite;
  final String zone;

  /// Adresse de la photo : image envoyée au serveur, sinon lien externe.
  final String photoUrl;
  final StatutAnnonce statut;
  final String vendeurNom;
  final String vendeurTelephone;

  /// `true` si l'annonce appartient à l'utilisateur connecté (RF-19).
  final bool estProprietaire;
  final DateTime? dateCreation;

  factory Annonce.fromJson(Map<String, dynamic> json) {
    final image = json['image'] as String? ?? '';
    return Annonce(
      id: json['id'] as int?,
      titre: json['titre'] as String? ?? '',
      description: json['description'] as String? ?? '',
      categorie: CategorieAnnonce.fromApi(json['categorie']),
      prix: parseDouble(json['prix']).round(),
      quantite: json['quantite'] as String? ?? '',
      zone: json['zone'] as String? ?? '',
      photoUrl: image.isNotEmpty ? image : json['photo'] as String? ?? '',
      statut: StatutAnnonce.fromApi(json['statut']),
      vendeurNom: json['vendeur_nom'] as String? ?? '',
      vendeurTelephone: json['vendeur_telephone'] as String? ?? '',
      estProprietaire: json['est_proprietaire'] as bool? ?? false,
      dateCreation: parseDate(json['date_creation'])?.toLocal(),
    );
  }

  /// Champs modifiables par le vendeur. La photo est envoyée à part.
  Map<String, dynamic> toJson() => {
    'titre': titre,
    'description': description,
    'categorie': categorie.apiValue,
    'prix': prix,
    'quantite': quantite,
    'zone': zone,
    'statut': statut.apiValue,
  };

  Annonce copyWith({
    int? id,
    String? photoUrl,
    String? vendeurNom,
    String? vendeurTelephone,
    bool? estProprietaire,
    DateTime? dateCreation,
  }) => Annonce(
    id: id ?? this.id,
    titre: titre,
    description: description,
    categorie: categorie,
    prix: prix,
    quantite: quantite,
    zone: zone,
    photoUrl: photoUrl ?? this.photoUrl,
    statut: statut,
    vendeurNom: vendeurNom ?? this.vendeurNom,
    vendeurTelephone: vendeurTelephone ?? this.vendeurTelephone,
    estProprietaire: estProprietaire ?? this.estProprietaire,
    dateCreation: dateCreation ?? this.dateCreation,
  );
}

/// Critères de recherche du marché (RF-17).
class FiltreAnnonces {
  const FiltreAnnonces({
    this.recherche = '',
    this.categorie,
    this.zone = '',
    this.prixMin,
    this.prixMax,
  });

  final String recherche;
  final CategorieAnnonce? categorie;
  final String zone;
  final int? prixMin;
  final int? prixMax;

  bool get aDesCriteresAvances =>
      zone.isNotEmpty || prixMin != null || prixMax != null;

  Map<String, dynamic> toQuery() => {
    'statut': StatutAnnonce.disponible.apiValue,
    if (recherche.isNotEmpty) 'q': recherche,
    if (categorie != null) 'categorie': categorie!.apiValue,
    if (zone.isNotEmpty) 'zone': zone,
    if (prixMin != null) 'prix_min': prixMin,
    if (prixMax != null) 'prix_max': prixMax,
  };

  bool accepte(Annonce annonce) =>
      annonce.statut == StatutAnnonce.disponible &&
      annonce.titre.toLowerCase().contains(recherche.toLowerCase()) &&
      (categorie == null || annonce.categorie == categorie) &&
      annonce.zone.toLowerCase().contains(zone.toLowerCase()) &&
      (prixMin == null || annonce.prix >= prixMin!) &&
      (prixMax == null || annonce.prix <= prixMax!);
}
