import '../../core/format.dart';

enum NiveauAlerte {
  info('info', 'Information'),
  attention('attention', 'Attention'),
  danger('danger', 'Danger');

  const NiveauAlerte(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static NiveauAlerte fromApi(Object? value) =>
      values.firstWhere((n) => n.apiValue == value, orElse: () => info);
}

enum TypeAlerte {
  meteo('meteo'),
  vaccination('vaccination'),
  culture('culture'),
  systeme('systeme');

  const TypeAlerte(this.apiValue);

  final String apiValue;

  static TypeAlerte fromApi(Object? value) =>
      values.firstWhere((t) => t.apiValue == value, orElse: () => systeme);
}

/// Alerte ou rappel créé par le système pour l'utilisateur (RF-14, RF-15).
class Alerte {
  const Alerte({
    required this.id,
    required this.type,
    required this.niveau,
    required this.titre,
    required this.message,
    this.zone = '',
    this.lue = false,
    required this.dateCreation,
  });

  final int id;
  final TypeAlerte type;
  final NiveauAlerte niveau;
  final String titre;
  final String message;
  final String zone;
  final bool lue;
  final DateTime dateCreation;

  factory Alerte.fromJson(Map<String, dynamic> json) => Alerte(
    id: json['id'] as int,
    type: TypeAlerte.fromApi(json['type']),
    niveau: NiveauAlerte.fromApi(json['niveau']),
    titre: json['titre'] as String? ?? '',
    message: json['message'] as String? ?? '',
    zone: json['zone'] as String? ?? '',
    lue: json['lue'] as bool? ?? false,
    dateCreation: parseDate(json['date_creation'])?.toLocal() ?? DateTime.now(),
  );

  Alerte marquerLue() => Alerte(
    id: id,
    type: type,
    niveau: niveau,
    titre: titre,
    message: message,
    zone: zone,
    lue: true,
    dateCreation: dateCreation,
  );
}

/// Prévision résumée d'une journée.
class JourMeteo {
  const JourMeteo({
    required this.date,
    required this.tempMin,
    required this.tempMax,
    required this.pluieMm,
    required this.ventMaxMs,
    required this.description,
  });

  final DateTime date;
  final double tempMin;
  final double tempMax;
  final double pluieMm;
  final double ventMaxMs;
  final String description;

  int get ventKmh => (ventMaxMs * 3.6).round();

  factory JourMeteo.fromJson(Map<String, dynamic> json) => JourMeteo(
    date: parseDate(json['date']) ?? DateTime.now(),
    tempMin: parseDouble(json['temp_min']),
    tempMax: parseDouble(json['temp_max']),
    pluieMm: parseDouble(json['pluie_mm']),
    ventMaxMs: parseDouble(json['vent_max_ms']),
    description: json['description'] as String? ?? '',
  );
}

/// Risque climatique détecté dans les prévisions (RF-14).
class RisqueMeteo {
  const RisqueMeteo({
    required this.niveau,
    required this.titre,
    required this.message,
  });

  final NiveauAlerte niveau;
  final String titre;
  final String message;

  factory RisqueMeteo.fromJson(Map<String, dynamic> json) => RisqueMeteo(
    niveau: NiveauAlerte.fromApi(json['niveau']),
    titre: json['titre'] as String? ?? '',
    message: json['message'] as String? ?? '',
  );
}

/// Prévisions sur 5 jours pour une ville (RF-13).
class Meteo {
  const Meteo({
    required this.ville,
    required this.previsions,
    required this.risques,
  });

  final String ville;
  final List<JourMeteo> previsions;
  final List<RisqueMeteo> risques;

  factory Meteo.fromJson(Map<String, dynamic> json) => Meteo(
    ville: json['ville'] as String? ?? '',
    previsions: [
      for (final item in json['previsions'] as List? ?? const [])
        JourMeteo.fromJson(Map<String, dynamic>.from(item as Map)),
    ],
    risques: [
      for (final item in json['risques'] as List? ?? const [])
        RisqueMeteo.fromJson(Map<String, dynamic>.from(item as Map)),
    ],
  );
}

/// Villes proposées pour la météo.
const villesSenegal = [
  'Dakar',
  'Thiès',
  'Saint-Louis',
  'Kaolack',
  'Ziguinchor',
  'Touba',
  'Tambacounda',
  'Kolda',
  'Louga',
  'Matam',
  'Fatick',
  'Kaffrine',
  'Diourbel',
  'Sédhiou',
  'Kédougou',
];
