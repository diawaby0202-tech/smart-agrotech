import '../../core/api_exception.dart';
import '../../core/token_storage.dart';
import 'auth_repository.dart';
import 'user.dart';

/// Authentification fictive, utilisée tant que le backend n'est pas prêt.
///
/// Les comptes vivent en mémoire : ceux créés depuis l'écran d'inscription
/// disparaissent au redémarrage de l'app. Le compte de démonstration
/// ([demoEmail] / [demoPassword]) est toujours disponible.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository(
    this._storage, {
    this.delay = const Duration(milliseconds: 600),
  });

  static const demoEmail = 'demo@agrotech.sn';
  static const demoPassword = 'demo1234';
  static const _tokenPrefix = 'mock-token-';

  final TokenStorage _storage;

  /// Latence simulée du réseau.
  final Duration delay;

  final List<_MockAccount> _accounts = [
    _MockAccount(
      const User(
        id: 1,
        nom: 'Diop',
        prenom: 'Awa',
        email: demoEmail,
        telephone: '771234567',
        role: UserRole.producteur,
      ),
      demoPassword,
    ),
  ];

  @override
  Future<User> login(String email, String password) async {
    await Future<void>.delayed(delay);
    final account = _find(email);
    if (account == null || account.password != password) {
      throw ApiException('Email ou mot de passe incorrect.', statusCode: 401);
    }
    await _storage.save(
      access: '$_tokenPrefix${account.user.email}',
      refresh: 'mock-refresh',
    );
    return account.user;
  }

  @override
  Future<User> register(RegisterData data) async {
    await Future<void>.delayed(delay);
    if (_find(data.email) != null) {
      const message = 'Un compte existe déjà avec cet email.';
      throw ApiException(
        message,
        statusCode: 400,
        fieldErrors: {'email': message},
      );
    }
    _accounts.add(
      _MockAccount(
        User(
          id: _accounts.length + 1,
          nom: data.nom,
          prenom: data.prenom,
          email: data.email,
          telephone: data.telephone,
          role: data.role,
        ),
        data.password,
      ),
    );
    return login(data.email, data.password);
  }

  @override
  Future<User?> restoreSession() async {
    final token = await _storage.readAccessToken();
    if (token == null || !token.startsWith(_tokenPrefix)) return null;
    return _find(token.substring(_tokenPrefix.length))?.user;
  }

  @override
  Future<void> logout() => _storage.clear();

  _MockAccount? _find(String email) {
    final normalized = email.trim().toLowerCase();
    for (final account in _accounts) {
      if (account.user.email.toLowerCase() == normalized) return account;
    }
    return null;
  }
}

class _MockAccount {
  _MockAccount(this.user, this.password);

  final User user;
  final String password;
}
