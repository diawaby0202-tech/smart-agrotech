import '../../core/format.dart';

/// Un animal seul (effectif 1) ou un lot d'animaux (RF-10).
class Animal {
  const Animal({
    this.id,
    required this.espece,
    this.race = '',
    this.identifiant = '',
    this.effectif = 1,
    this.dateNaissance,
    this.notes = '',
    this.image,
  });

  final int? id;
  final String espece;
  final String race;

  /// Numéro de boucle ou nom du lot.
  final String identifiant;
  final int effectif;
  final DateTime? dateNaissance;
  final String notes;
  final String? image;

  bool get estLot => effectif > 1;

  String get titre =>
      [espece, if (identifiant.isNotEmpty) identifiant].join(' ');

  factory Animal.fromJson(Map<String, dynamic> json) => Animal(
    id: json['id'] as int?,
    espece: json['espece'] as String? ?? '',
    race: json['race'] as String? ?? '',
    identifiant: json['identifiant'] as String? ?? '',
    effectif: json['effectif'] as int? ?? 1,
    dateNaissance: parseDate(json['date_naissance']),
    notes: json['notes'] as String? ?? '',
    image: json['image'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'espece': espece,
    'race': race,
    'identifiant': identifiant,
    'effectif': effectif,
    'date_naissance': toApiDate(dateNaissance),
    'notes': notes,
  };

  Animal copyWith({int? id, String? image}) => Animal(
    id: id ?? this.id,
    espece: espece,
    race: race,
    identifiant: identifiant,
    effectif: effectif,
    dateNaissance: dateNaissance,
    notes: notes,
    image: image ?? this.image,
  );
}

enum TypeSuivi {
  vaccination('vaccination', 'Vaccination'),
  traitement('traitement', 'Traitement'),
  visite('visite', 'Visite vétérinaire');

  const TypeSuivi(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static TypeSuivi fromApi(Object? value) => values.firstWhere(
    (type) => type.apiValue == value,
    orElse: () => vaccination,
  );
}

/// Intervention sanitaire sur un animal (RF-11).
class SuiviSanitaire {
  const SuiviSanitaire({
    this.id,
    required this.animalId,
    required this.type,
    required this.date,
    this.description = '',
    this.prochaineEcheance,
  });

  final int? id;
  final int animalId;
  final TypeSuivi type;
  final DateTime date;
  final String description;

  /// Date du prochain rappel (RF-12).
  final DateTime? prochaineEcheance;

  factory SuiviSanitaire.fromJson(Map<String, dynamic> json) => SuiviSanitaire(
    id: json['id'] as int?,
    animalId: json['animal'] as int,
    type: TypeSuivi.fromApi(json['type']),
    date: parseDate(json['date']) ?? DateTime.now(),
    description: json['description'] as String? ?? '',
    prochaineEcheance: parseDate(json['prochaine_echeance']),
  );

  Map<String, dynamic> toJson() => {
    'animal': animalId,
    'type': type.apiValue,
    'date': toApiDate(date),
    'description': description,
    'prochaine_echeance': toApiDate(prochaineEcheance),
  };

  SuiviSanitaire copyWith({int? id}) => SuiviSanitaire(
    id: id ?? this.id,
    animalId: animalId,
    type: type,
    date: date,
    description: description,
    prochaineEcheance: prochaineEcheance,
  );
}

class SuiviReproduction {
  const SuiviReproduction({
    this.id,
    required this.animalId,
    this.dateSaillie,
    this.miseBasPrevue,
    this.miseBasReelle,
    this.nombrePetits,
    this.notes = '',
  });

  final int? id;
  final int animalId;
  final DateTime? dateSaillie;
  final DateTime? miseBasPrevue;
  final DateTime? miseBasReelle;
  final int? nombrePetits;
  final String notes;

  factory SuiviReproduction.fromJson(Map<String, dynamic> json) =>
      SuiviReproduction(
        id: json['id'] as int?,
        animalId: json['animal'] as int,
        dateSaillie: parseDate(json['date_saillie']),
        miseBasPrevue: parseDate(json['mise_bas_prevue']),
        miseBasReelle: parseDate(json['mise_bas_reelle']),
        nombrePetits: json['nombre_petits'] as int?,
        notes: json['notes'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
    'animal': animalId,
    'date_saillie': toApiDate(dateSaillie),
    'mise_bas_prevue': toApiDate(miseBasPrevue),
    'mise_bas_reelle': toApiDate(miseBasReelle),
    'nombre_petits': nombrePetits,
    'notes': notes,
  };

  SuiviReproduction copyWith({int? id}) => SuiviReproduction(
    id: id ?? this.id,
    animalId: animalId,
    dateSaillie: dateSaillie,
    miseBasPrevue: miseBasPrevue,
    miseBasReelle: miseBasReelle,
    nombrePetits: nombrePetits,
    notes: notes,
  );
}
