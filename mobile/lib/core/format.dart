/// Conversions entre les valeurs de l'API et leur affichage.
library;

String _deux(int n) => n.toString().padLeft(2, '0');

/// Date au format attendu par l'API : `2026-10-14`.
String? toApiDate(DateTime? date) => date == null
    ? null
    : '${date.year}-${_deux(date.month)}-${_deux(date.day)}';

DateTime? parseDate(Object? value) =>
    value == null ? null : DateTime.tryParse(value.toString());

/// Date affichée à l'utilisateur : `14/10/2026`.
String formatDate(DateTime? date) =>
    date == null ? '—' : '${_deux(date.day)}/${_deux(date.month)}/${date.year}';

/// DRF renvoie les nombres décimaux sous forme de texte (`"2.50"`).
double parseDouble(Object? value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

String formatNombre(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString().replaceAll('.', ',');

/// Prix en FCFA avec séparateur de milliers : `15 000 FCFA`.
String formatPrix(int prix) {
  final chiffres = prix.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < chiffres.length; i++) {
    if (i > 0 && (chiffres.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(chiffres[i]);
  }
  return '$buffer FCFA';
}

/// Nombre de jours entre aujourd'hui et [date] (négatif si la date est passée).
int joursRestants(DateTime date) {
  final now = DateTime.now();
  return DateTime(
    date.year,
    date.month,
    date.day,
  ).difference(DateTime(now.year, now.month, now.day)).inDays;
}

String formatEcheance(DateTime date) {
  final jours = joursRestants(date);
  if (jours == 0) return "Aujourd'hui";
  if (jours == 1) return 'Demain';
  if (jours > 1) return 'Dans $jours jours';
  return 'En retard de ${-jours} jour${jours == -1 ? '' : 's'}';
}
