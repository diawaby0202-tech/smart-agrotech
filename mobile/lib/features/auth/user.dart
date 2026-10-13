/// Rôles proposés à l'inscription sur mobile. Le rôle administrateur est
/// réservé à la version web.
enum UserRole {
  producteur('producteur', 'Agriculteur / Éleveur'),
  acheteur('acheteur', 'Acheteur');

  const UserRole(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static UserRole fromApi(String? value) => UserRole.values.firstWhere(
    (role) => role.apiValue == value,
    orElse: () => UserRole.producteur,
  );
}

class User {
  const User({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.telephone,
    required this.role,
  });

  final int id;
  final String nom;
  final String prenom;
  final String email;
  final String telephone;
  final UserRole role;

  String get nomComplet => '$prenom $nom';

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as int,
    nom: json['nom'] as String? ?? '',
    prenom: json['prenom'] as String? ?? '',
    email: json['email'] as String,
    telephone: json['telephone'] as String? ?? '',
    role: UserRole.fromApi(json['role'] as String?),
  );
}

/// Données du formulaire d'inscription (RF-01).
class RegisterData {
  const RegisterData({
    required this.nom,
    required this.prenom,
    required this.email,
    required this.telephone,
    required this.password,
    required this.role,
  });

  final String nom;
  final String prenom;
  final String email;
  final String telephone;
  final String password;
  final UserRole role;

  Map<String, dynamic> toJson() => {
    'nom': nom,
    'prenom': prenom,
    'email': email,
    'telephone': telephone,
    'password': password,
    'role': role.apiValue,
  };
}
