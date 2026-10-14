enum UserRole {
  producteur('producteur', 'Agriculteur / Éleveur'),
  acheteur('acheteur', 'Acheteur'),

  /// Compte créé avec `createsuperuser` côté backend. Il se connecte comme les
  /// autres ; l'espace d'administration reste sur le site web.
  admin('admin', 'Administrateur');

  const UserRole(this.apiValue, this.label);

  final String apiValue;
  final String label;

  /// Rôles proposés à l'inscription : on ne s'inscrit pas administrateur.
  static const inscription = [producteur, acheteur];

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
    this.statut = '',
    this.dateInscription,
  });

  final int id;
  final String nom;
  final String prenom;
  final String email;
  final String telephone;
  final UserRole role;

  /// Statut du compte : `valide`, `en_attente`, `refuse`, `suspendu`.
  final String statut;
  final DateTime? dateInscription;

  String get nomComplet => '$prenom $nom';

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as int,
    nom: json['nom'] as String? ?? '',
    prenom: json['prenom'] as String? ?? '',
    email: json['email'] as String,
    telephone: json['telephone'] as String? ?? '',
    role: UserRole.fromApi(json['role'] as String?),
    statut: json['statut'] as String? ?? '',
    dateInscription: DateTime.tryParse('${json['date_inscription'] ?? ''}'),
  );

  User copyWith({String? nom, String? prenom, String? telephone}) => User(
    id: id,
    nom: nom ?? this.nom,
    prenom: prenom ?? this.prenom,
    email: email,
    telephone: telephone ?? this.telephone,
    role: role,
    statut: statut,
    dateInscription: dateInscription,
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
