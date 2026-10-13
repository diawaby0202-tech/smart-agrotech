import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stockage des tokens JWT (access + refresh).
abstract class TokenStorage {
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();
  Future<void> save({required String access, String? refresh});
  Future<void> clear();
}

/// Stockage chiffré sur l'appareil (Keystore Android / Keychain iOS).
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage([this._storage = const FlutterSecureStorage()]);

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readAccessToken() => _storage.read(key: _accessKey);

  @override
  Future<String?> readRefreshToken() => _storage.read(key: _refreshKey);

  @override
  Future<void> save({required String access, String? refresh}) async {
    await _storage.write(key: _accessKey, value: access);
    if (refresh != null) {
      await _storage.write(key: _refreshKey, value: refresh);
    }
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}

/// Stockage en mémoire, utilisé dans les tests.
class InMemoryTokenStorage implements TokenStorage {
  String? access;
  String? refresh;

  @override
  Future<String?> readAccessToken() async => access;

  @override
  Future<String?> readRefreshToken() async => refresh;

  @override
  Future<void> save({required String access, String? refresh}) async {
    this.access = access;
    if (refresh != null) this.refresh = refresh;
  }

  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
  }
}
