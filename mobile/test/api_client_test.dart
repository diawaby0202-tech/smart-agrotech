import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_agrotech/core/api_client.dart';
import 'package:smart_agrotech/core/token_storage.dart';

/// Faux serveur : répond selon le chemin et garde la trace des requêtes.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  final (int, Object) Function(RequestOptions options) handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final (status, body) = handler(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late InMemoryTokenStorage storage;

  ApiClient buildClient(FakeAdapter adapter, {void Function()? onExpired}) {
    final dio = Dio(BaseOptions(baseUrl: 'http://test/api'))
      ..httpClientAdapter = adapter;
    return ApiClient(storage: storage, dio: dio, onSessionExpired: onExpired);
  }

  setUp(() => storage = InMemoryTokenStorage());

  test('ajoute le token JWT aux requêtes protégées', () async {
    storage.access = 'abc';
    final adapter = FakeAdapter((_) => (200, {'ok': true}));

    await buildClient(adapter).dio.get('/parcelles/');

    expect(adapter.requests.single.headers['Authorization'], 'Bearer abc');
  });

  test('n\'envoie pas le token sur la connexion', () async {
    storage.access = 'abc';
    final adapter = FakeAdapter((_) => (200, {'access': 'x'}));

    await buildClient(adapter).dio.post(ApiClient.loginPath, data: {});

    expect(adapter.requests.single.headers['Authorization'], isNull);
  });

  test('renouvelle le token sur un 401 puis rejoue la requête', () async {
    storage
      ..access = 'expire'
      ..refresh = 'refresh-ok';
    final adapter = FakeAdapter((options) {
      if (options.path == ApiClient.refreshPath) {
        return (200, {'access': 'nouveau'});
      }
      return options.headers['Authorization'] == 'Bearer nouveau'
          ? (200, {'ok': true})
          : (401, {'detail': 'Token expiré'});
    });

    final response = await buildClient(adapter).dio.get('/parcelles/');

    expect(response.data, {'ok': true});
    expect(storage.access, 'nouveau');
    expect(storage.refresh, 'refresh-ok');
    expect(adapter.requests.map((r) => r.path), [
      '/parcelles/',
      ApiClient.refreshPath,
      '/parcelles/',
    ]);
  });

  test('déconnecte si le renouvellement échoue', () async {
    storage
      ..access = 'expire'
      ..refresh = 'refresh-expire';
    var expired = false;
    final adapter = FakeAdapter((_) => (401, {'detail': 'Token invalide'}));
    final client = buildClient(adapter, onExpired: () => expired = true);

    await expectLater(
      client.dio.get('/parcelles/'),
      throwsA(isA<DioException>()),
    );

    expect(expired, isTrue);
    expect(storage.access, isNull);
    expect(storage.refresh, isNull);
  });
}
