/// Validateurs des formulaires d'inscription et de connexion.
class Validators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _telephone = RegExp(r'^(\+?221)?[0-9]{9}$');

  static String? required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Champ obligatoire' : null;

  static String? email(String? value) {
    final missing = required(value);
    if (missing != null) return missing;
    return _email.hasMatch(value!.trim()) ? null : 'Adresse email invalide';
  }

  static String? telephone(String? value) {
    final missing = required(value);
    if (missing != null) return missing;
    final digits = value!.replaceAll(RegExp(r'[\s.-]'), '');
    return _telephone.hasMatch(digits)
        ? null
        : 'Numéro invalide (ex. : 77 123 45 67)';
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Champ obligatoire';
    return value.length < 8 ? 'Au moins 8 caractères' : null;
  }
}
