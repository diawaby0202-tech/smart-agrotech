import '../../core/format.dart';
import 'annonce.dart';

enum ModerationAnnonce {
  approuvee('approuvee', 'Approuvée'),
  supprimee('supprimee', 'Masquée');

  const ModerationAnnonce(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static ModerationAnnonce fromApi(Object? value) => values.firstWhere(
    (moderation) => moderation.apiValue == value,
    orElse: () => approuvee,
  );
}

class AnnonceModeration {
  const AnnonceModeration({
    required this.id,
    required this.titre,
    required this.description,
    required this.categorie,
    required this.prix,
    required this.zone,
    required this.statut,
    required this.moderation,
    required this.vendeurEmail,
    required this.dateCreation,
  });

  final int id;
  final String titre;
  final String description;
  final CategorieAnnonce categorie;
  final int prix;
  final String zone;
  final StatutAnnonce statut;
  final ModerationAnnonce moderation;
  final String vendeurEmail;
  final DateTime? dateCreation;

  factory AnnonceModeration.fromJson(Map<String, dynamic> json) =>
      AnnonceModeration(
        id: json['id'] as int,
        titre: json['titre'] as String? ?? '',
        description: json['description'] as String? ?? '',
        categorie: CategorieAnnonce.fromApi(json['categorie']),
        prix: parseDouble(json['prix']).round(),
        zone: json['zone'] as String? ?? '',
        statut: StatutAnnonce.fromApi(json['statut']),
        moderation: ModerationAnnonce.fromApi(json['moderation']),
        vendeurEmail: json['vendeur_email'] as String? ?? '',
        dateCreation: parseDate(json['date_creation'])?.toLocal(),
      );
}
