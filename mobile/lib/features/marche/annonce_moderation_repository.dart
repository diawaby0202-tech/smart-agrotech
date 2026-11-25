import '../../core/api_client.dart';
import 'annonce_moderation.dart';

abstract class AnnonceModerationRepository {
  Future<List<AnnonceModeration>> list({
    ModerationAnnonce? moderation,
    String recherche = '',
  });

  Future<void> masquer(int id);
  Future<void> restaurer(int id);
}

class ApiAnnonceModerationRepository implements AnnonceModerationRepository {
  ApiAnnonceModerationRepository(this._client);

  static const _path = '/admin/annonces/';
  final ApiClient _client;

  @override
  Future<List<AnnonceModeration>> list({
    ModerationAnnonce? moderation,
    String recherche = '',
  }) => _client.call(
    (dio) async => [
      for (final item
          in (await dio.get(
            _path,
            queryParameters: {
              if (moderation != null) 'moderation': moderation.apiValue,
              if (recherche.trim().isNotEmpty) 'q': recherche.trim(),
            },
          )).data as List)
        AnnonceModeration.fromJson(Map<String, dynamic>.from(item as Map)),
    ],
  );

  @override
  Future<void> masquer(int id) =>
      _client.call((dio) => dio.post('$_path$id/masquer/'));

  @override
  Future<void> restaurer(int id) =>
      _client.call((dio) => dio.post('$_path$id/restaurer/'));
}

class MockAnnonceModerationRepository implements AnnonceModerationRepository {
  @override
  Future<List<AnnonceModeration>> list({
    ModerationAnnonce? moderation,
    String recherche = '',
  }) async => [];

  @override
  Future<void> masquer(int id) async {}

  @override
  Future<void> restaurer(int id) async {}
}
