import '../../core/format.dart';

/// Étapes d'une culture (RF-07), mêmes valeurs que le backend.
enum StatutParcelle {
  preparation('preparation', 'En préparation'),
  semee('semee', 'Semée'),
  croissance('croissance', 'En croissance'),
  recoltee('recoltee', 'Récoltée');

  const StatutParcelle(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static StatutParcelle fromApi(Object? value) => values.firstWhere(
    (statut) => statut.apiValue == value,
    orElse: () => preparation,
  );
}

class Parcelle {
  const Parcelle({
    this.id,
    required this.nom,
    required this.culture,
    required this.superficie,
    this.localisation = '',
    this.dateSemis,
    this.dateRecoltePrevue,
    this.statut = StatutParcelle.preparation,
    this.notes = '',
  });

  /// `null` tant que la parcelle n'est pas enregistrée.
  final int? id;
  final String nom;
  final String culture;

  /// En hectares.
  final double superficie;
  final String localisation;
  final DateTime? dateSemis;
  final DateTime? dateRecoltePrevue;
  final StatutParcelle statut;
  final String notes;

  factory Parcelle.fromJson(Map<String, dynamic> json) => Parcelle(
    id: json['id'] as int?,
    nom: json['nom'] as String? ?? '',
    culture: json['culture'] as String? ?? '',
    superficie: parseDouble(json['superficie']),
    localisation: json['localisation'] as String? ?? '',
    dateSemis: parseDate(json['date_semis']),
    dateRecoltePrevue: parseDate(json['date_recolte_prevue']),
    statut: StatutParcelle.fromApi(json['statut']),
    notes: json['notes'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'nom': nom,
    'culture': culture,
    'superficie': superficie.toStringAsFixed(2),
    'localisation': localisation,
    'date_semis': toApiDate(dateSemis),
    'date_recolte_prevue': toApiDate(dateRecoltePrevue),
    'statut': statut.apiValue,
    'notes': notes,
  };

  Parcelle copyWith({int? id, StatutParcelle? statut}) => Parcelle(
    id: id ?? this.id,
    nom: nom,
    culture: culture,
    superficie: superficie,
    localisation: localisation,
    dateSemis: dateSemis,
    dateRecoltePrevue: dateRecoltePrevue,
    statut: statut ?? this.statut,
    notes: notes,
  );
}
