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

const _mois = [
  'janvier',
  'février',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août',
  'septembre',
  'octobre',
  'novembre',
  'décembre',
];

/// Date en toutes lettres, comme sur le site : `26 juillet 2026`.
String formatDateLongue(DateTime? date, {bool annee = true}) {
  if (date == null) return 'Non renseignée';
  final texte = '${date.day} ${_mois[date.month - 1]}';
  return annee ? '$texte ${date.year}' : texte;
}

/// Date courte : `19 oct.`
String formatDateCourte(DateTime date) {
  final mois = _mois[date.month - 1];
  return '${date.day} ${mois.length > 4 ? '${mois.substring(0, 3)}.' : mois}';
}

const _jours = [
  'Lundi',
  'Mardi',
  'Mercredi',
  'Jeudi',
  'Vendredi',
  'Samedi',
  'Dimanche',
];

/// « Aujourd'hui », « Demain », puis le nom du jour.
String nomJour(DateTime date) {
  final ecart = joursRestants(date);
  if (ecart == 0) return "Aujourd'hui";
  if (ecart == 1) return 'Demain';
  return _jours[date.weekday - 1];
}

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

/// Numéro lisible : `771234567` devient `77 123 45 67`.
String formatTelephone(String numero) {
  var chiffres = numero.replaceAll(RegExp(r'[^0-9+]'), '');
  var prefixe = '';
  if (chiffres.startsWith('+221')) {
    prefixe = '+221 ';
    chiffres = chiffres.substring(4);
  } else if (chiffres.startsWith('221') && chiffres.length == 12) {
    prefixe = '+221 ';
    chiffres = chiffres.substring(3);
  }
  if (chiffres.length != 9) return numero;
  return '$prefixe${chiffres.substring(0, 2)} ${chiffres.substring(2, 5)} '
      '${chiffres.substring(5, 7)} ${chiffres.substring(7)}';
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
