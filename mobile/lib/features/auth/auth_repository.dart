import 'package:dio/dio.dart';

import '../../core/api_client.dart';
import '../../core/api_exception.dart';
import '../../core/token_storage.dart';
import 'user.dart';

abstract class AuthRepository {
  Future<User> login(String email, String password);

  /// Crée le compte puis connecte l'utilisateur.
  Future<User> register(RegisterData data);

  /// Retourne l'utilisateur si un token valide est déjà enregistré.
  Future<User?> restoreSession();

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
  Future<User> register(RegisterData data) async {
    try {
      await _client.dio.post(ApiClient.registerPath, data: data.toJson());
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
    try {
      return await login(data.email, data.password);
    } on ApiException catch (e) {
      // Le backend refuse la connexion tant que l'administrateur n'a pas
      // validé le compte (RF-03, réglage VALIDATION_INSCRIPTION_REQUISE).
      if (e.statusCode != 401) rethrow;
      throw ApiException(
        'Compte créé. Il doit être validé par un administrateur avant la '
        'première connexion.',
        statusCode: 401,
      );
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
  Future<void> logout() => _storage.clear();

  Future<User> _fetchProfile() async {
    final response = await _client.dio.get('/users/me/');
    return User.fromJson(Map<String, dynamic>.from(response.data as Map));
  }
}
