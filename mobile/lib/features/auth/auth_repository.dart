import 'package:dio/dio.dart';

import '../../core/api_client.dart';
import '../../core/api_exception.dart';
import '../../core/token_storage.dart';
import 'user.dart';

abstract class AuthRepository {
  Future<User> login(String email, String password);

  /// Crée le compte. L'utilisateur se connecte ensuite depuis l'écran de
  /// connexion.
  Future<void> register(RegisterData data);

  /// Retourne l'utilisateur si un token valide est déjà enregistré.
  Future<User?> restoreSession();

  /// Modifie le prénom, le nom et le téléphone (RF-05).
  Future<User> updateProfile({
    required String prenom,
    required String nom,
    required String telephone,
  });

  Future<void> logout();
}

/// Implémentation branchée sur l'API Django (voir README, « Convention de l'API »).
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._client, this._storage);

  final ApiClient _client;
  final TokenStorage _storage;

  @override
  Future<User> login(String email, String password) async {
    try {
      final response = await _client.dio.post(
        ApiClient.loginPath,
        data: {'email': email, 'password': password},
      );
      final data = response.data as Map;
      await _storage.save(
        access: data['access'] as String,
        refresh: data['refresh'] as String?,
      );
      return await _fetchProfile();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> register(RegisterData data) async {
    try {
      await _client.dio.post(ApiClient.registerPath, data: data.toJson());
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<User?> restoreSession() async {
    if (await _storage.readAccessToken() == null) return null;
    try {
      return await _fetchProfile();
    } on DioException {
      return null;
    }
  }

  @override
  Future<void> logout() async {
    // Invalide le refresh token côté serveur ; la déconnexion locale a lieu
    // même si le serveur est injoignable.
    final refresh = await _storage.readRefreshToken();
    if (refresh != null) {
      try {
        await _client.dio.post(
          ApiClient.logoutPath,
          data: {'refresh': refresh},
        );
      } on DioException {
        // Ignoré : le token expirera de lui-même.
      }
    }
    await _storage.clear();
  }

  @override
  Future<User> updateProfile({
    required String prenom,
    required String nom,
    required String telephone,
  }) => _client.call((dio) async {
    final response = await dio.patch(
      '/users/me/',
      data: {'prenom': prenom, 'nom': nom, 'telephone': telephone},
    );
    return User.fromJson(Map<String, dynamic>.from(response.data as Map));
  });

  Future<User> _fetchProfile() async {
    final response = await _client.dio.get('/users/me/');
    return User.fromJson(Map<String, dynamic>.from(response.data as Map));
  }
}
