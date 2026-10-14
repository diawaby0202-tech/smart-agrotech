import 'package:dio/dio.dart';

import 'api_exception.dart';
import 'config.dart';
import 'token_storage.dart';

/// Client HTTP de l'application.
///
/// - ajoute l'en-tête `Authorization: Bearer <token>` à chaque requête ;
/// - sur un 401, tente de renouveler le token via `/auth/refresh/` puis rejoue
///   la requête une fois ;
/// - si le renouvellement échoue, vide les tokens et prévient l'application
///   ([onSessionExpired]) pour renvoyer l'utilisateur à l'écran de connexion.
class ApiClient {
  ApiClient({required this._storage, Dio? dio, this.onSessionExpired})
    : dio = dio ?? Dio() {
    this.dio.options
      ..baseUrl = this.dio.options.baseUrl.isEmpty
          ? AppConfig.apiBaseUrl
          : this.dio.options.baseUrl
      ..connectTimeout = const Duration(seconds: 10)
      ..receiveTimeout = const Duration(seconds: 15)
      ..headers['Accept'] = 'application/json';

    this.dio.interceptors.add(
      QueuedInterceptorsWrapper(onRequest: _onRequest, onError: _onError),
    );
  }

  static const loginPath = '/auth/login/';
  static const registerPath = '/auth/register/';
  static const refreshPath = '/auth/refresh/';
  static const logoutPath = '/auth/logout/';
  static const _publicPaths = {
    loginPath,
    registerPath,
    refreshPath,
    logoutPath,
  };
  static const _retriedKey = 'retried';

  final Dio dio;
  final TokenStorage _storage;

  /// Appelé quand la session ne peut plus être renouvelée.
  void Function()? onSessionExpired;

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_publicPaths.contains(options.path)) {
      final token = await _storage.readAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final options = error.requestOptions;
    final isUnauthorized = error.response?.statusCode == 401;
    final alreadyRetried = options.extra[_retriedKey] == true;

    if (!isUnauthorized ||
        alreadyRetried ||
        _publicPaths.contains(options.path)) {
      return handler.next(error);
    }

    final newToken = await _refreshAccessToken();
    if (newToken == null) {
      await _storage.clear();
      onSessionExpired?.call();
      return handler.next(error);
    }

    try {
      options.extra[_retriedKey] = true;
      options.headers['Authorization'] = 'Bearer $newToken';
      handler.resolve(await _bareDio().fetch(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<String?> _refreshAccessToken() async {
    final refresh = await _storage.readRefreshToken();
    if (refresh == null) return null;
    try {
      final response = await _bareDio().post(
        refreshPath,
        data: {'refresh': refresh},
      );
      final data = response.data as Map;
      final access = data['access'] as String;
      await _storage.save(access: access, refresh: data['refresh'] as String?);
      return access;
    } on DioException {
      return null;
    }
  }

  /// Exécute un appel et convertit les erreurs réseau en [ApiException].
  Future<T> call<T>(Future<T> Function(Dio dio) request) async {
    try {
      return await request(dio);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Dio sans intercepteur, pour ne pas reboucler sur [_onError].
  Dio _bareDio() => Dio(dio.options)..httpClientAdapter = dio.httpClientAdapter;
}
