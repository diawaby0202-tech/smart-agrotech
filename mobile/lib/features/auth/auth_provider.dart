import 'package:flutter/foundation.dart';

import 'auth_repository.dart';
import 'user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// État de connexion de l'application. Le routeur l'écoute pour rediriger
/// vers l'écran de connexion ou vers l'accueil.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repository);

  final AuthRepository _repository;

  AuthStatus _status = AuthStatus.unknown;
  User? _user;

  AuthStatus get status => _status;
  User? get user => _user;

  /// À appeler au démarrage : reconnecte l'utilisateur si un token existe.
  Future<void> restoreSession() async {
    User? user;
    try {
      user = await _repository.restoreSession();
    } catch (_) {
      user = null;
    }
    _setUser(user);
  }

  Future<void> login(String email, String password) async {
    _setUser(await _repository.login(email.trim(), password));
  }

  Future<void> register(RegisterData data) async {
    _setUser(await _repository.register(data));
  }

  Future<void> logout() async {
    await _repository.logout();
    _setUser(null);
  }

  /// Appelé par le client HTTP quand le token ne peut plus être renouvelé.
  void onSessionExpired() => _setUser(null);

  void _setUser(User? user) {
    _user = user;
    _status = user == null
        ? AuthStatus.unauthenticated
        : AuthStatus.authenticated;
    notifyListeners();
  }
}
