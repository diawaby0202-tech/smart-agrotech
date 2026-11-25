import '../../core/format.dart';

enum UniteRecolte {
  kg('kg', 'kg'),
  tonne('tonne', 'tonnes'),
  sac('sac', 'sacs'),
  caisse('caisse', 'caisses');

  const UniteRecolte(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static UniteRecolte fromApi(Object? value) => values.firstWhere(
    (unite) => unite.apiValue == value,
    orElse: () => kg,
  );
}

class Recolte {
  const Recolte({
    this.id,
    required this.parcelleId,
    required this.date,
    required this.quantite,
    required this.unite,
    this.notes = '',
  });

  final int? id;
  final int parcelleId;
  final DateTime date;
  final double quantite;
  final UniteRecolte unite;
  final String notes;

  factory Recolte.fromJson(Map<String, dynamic> json) => Recolte(
    id: json['id'] as int?,
    parcelleId: json['parcelle'] as int,
    date: parseDate(json['date']) ?? DateTime.now(),
    quantite: parseDouble(json['quantite']),
    unite: UniteRecolte.fromApi(json['unite']),
    notes: json['notes'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'parcelle': parcelleId,
    'date': toApiDate(date),
    'quantite': quantite.toStringAsFixed(2),
    'unite': unite.apiValue,
    'notes': notes,
  };

  Recolte copyWith({int? id}) => Recolte(
    id: id ?? this.id,
    parcelleId: parcelleId,
    date: date,
    quantite: quantite,
    unite: unite,
    notes: notes,
  );
}
