import 'package:dio/dio.dart';

/// Erreur lisible par l'utilisateur, construite à partir d'une réponse de l'API.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.fieldErrors = const {}});

  final String message;
  final int? statusCode;

  /// Erreurs de validation par champ, telles que renvoyées par Django REST
  /// Framework : `{"email": ["Cet email est déjà utilisé."]}`.
  final Map<String, String> fieldErrors;

  factory ApiException.fromDio(DioException e) {
    final response = e.response;
    if (response == null) {
      return ApiException(
        'Impossible de joindre le serveur. Vérifiez votre connexion.',
      );
    }

    final data = response.data;
    final fieldErrors = <String, String>{};
    String? message;

    if (data is Map) {
      for (final entry in data.entries) {
        final value = entry.value;
        final text = value is List ? value.join(' ') : value.toString();
        if (entry.key == 'detail' || entry.key == 'non_field_errors') {
          message = text;
        } else {
          fieldErrors[entry.key.toString()] = text;
        }
      }
    }

    message ??= fieldErrors.isNotEmpty
        ? fieldErrors.values.first
        : 'Une erreur est survenue (code ${response.statusCode}).';

    return ApiException(
      message,
      statusCode: response.statusCode,
      fieldErrors: fieldErrors,
    );
  }

  @override
  String toString() => message;
}
