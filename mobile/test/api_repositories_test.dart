import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_agrotech/core/api_client.dart';
import 'package:smart_agrotech/core/api_exception.dart';
import 'package:smart_agrotech/core/token_storage.dart';
import 'package:smart_agrotech/features/alertes/alertes_models.dart';
import 'package:smart_agrotech/features/alertes/alertes_repository.dart';
import 'package:smart_agrotech/features/cultures/parcelle.dart';
import 'package:smart_agrotech/features/cultures/parcelle_repository.dart';
import 'package:smart_agrotech/features/elevage/elevage_repository.dart';
import 'package:smart_agrotech/features/marche/annonce.dart';
import 'package:smart_agrotech/features/marche/annonce_repository.dart';

import 'api_client_test.dart' show FakeAdapter;

/// Vérifie que les dépôts envoient et lisent le format exact de l'API Django.
void main() {
  late FakeAdapter adapter;

  ApiClient client((int, Object) Function(RequestOptions) handler) {
    adapter = FakeAdapter(handler);
    final dio = Dio(BaseOptions(baseUrl: 'http://test/api'))
      ..httpClientAdapter = adapter;
    return ApiClient(storage: InMemoryTokenStorage()..access = 'abc', dio: dio);
  }

  Object? corps() => adapter.requests.last.data;

  test('parcelles : lecture des décimaux et des dates', () async {
    final repository = ApiParcelleRepository(
      client(
        (_) => (
          200,
          [
            {
              'id': 7,
              'nom': 'Champ nord',
              'culture': 'Arachide',
              'superficie': '2.50',
              'localisation': 'Thiès',
              'date_semis': '2026-07-01',
              'date_recolte_prevue': null,
              'statut': 'croissance',
              'notes': '',
              'date_creation': '2026-10-13T17:00:00Z',
            },
          ],
        ),
      ),
    );

    final parcelle = (await repository.list()).single;

    expect(parcelle.superficie, 2.5);
    expect(parcelle.dateSemis, DateTime(2026, 7, 1));
    expect(parcelle.dateRecoltePrevue, isNull);
    expect(parcelle.statut, StatutParcelle.croissance);
  });

  test('parcelles : format envoyé à la création', () async {
    final repository = ApiParcelleRepository(
      client((options) => (201, {...options.data as Map, 'id': 1})),
    );

    await repository.create(
      Parcelle(
        nom: 'Bas-fond',
        culture: 'Mil',
        superficie: 1.5,
        dateSemis: DateTime(2026, 6, 15),
      ),
    );

    expect(adapter.requests.last.path, '/parcelles/');
    expect(corps(), {
      'nom': 'Bas-fond',
      'culture': 'Mil',
      'superficie': '1.50',
      'localisation': '',
      'date_semis': '2026-06-15',
      'date_recolte_prevue': null,
      'statut': 'preparation',
      'notes': '',
    });
  });

  test('parcelles : erreur de validation du serveur', () async {
    final repository = ApiParcelleRepository(
      client(
        (_) => (
          400,
          {
            'non_field_errors': [
              'La date de récolte doit être après la date de semis.',
            ],
          },
        ),
      ),
    );

    await expectLater(
      repository.create(const Parcelle(nom: 'A', culture: 'B', superficie: 1)),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          'La date de récolte doit être après la date de semis.',
        ),
      ),
    );
  });

  test('élevage : échéances et suivis d\'un animal', () async {
    final repository = ApiElevageRepository(
      client(
        (_) => (
          200,
          [
            {
              'id': 3,
              'animal': 5,
              'type': 'vaccination',
              'date': '2026-10-01',
              'description': 'Rappel',
              'prochaine_echeance': '2026-10-20',
            },
          ],
        ),
      ),
    );

    final echeance = (await repository.echeances(jours: 14)).single;
    expect(adapter.requests.last.path, '/suivis-sanitaires/echeances/');
    expect(adapter.requests.last.queryParameters, {'jours': 14});
    expect(echeance.animalId, 5);
    expect(echeance.prochaineEcheance, DateTime(2026, 10, 20));

    await repository.suivis(5);
    expect(adapter.requests.last.queryParameters, {'animal': 5});
  });

  test('météo : prévisions et service indisponible', () async {
    final ok = ApiAlertesRepository(
      client(
        (_) => (
          200,
          {
            'ville': 'Thiès',
            'previsions': [
              {
                'date': '2026-10-14',
                'temp_min': 24.1,
                'temp_max': 38,
                'pluie_mm': 0.0,
                'vent_max_ms': 5.0,
                'description': 'ciel dégagé',
              },
            ],
            'risques': [
              {
                'niveau': 'attention',
                'titre': 'Forte chaleur le 2026-10-14',
                'message': "Jusqu'à 38 °C prévus.",
              },
            ],
          },
        ),
      ),
    );

    final meteo = await ok.meteo('Thiès');
    expect(adapter.requests.last.queryParameters, {'ville': 'Thiès'});
    expect(meteo.previsions.single.tempMax, 38);
    expect(meteo.previsions.single.ventKmh, 18);
    expect(meteo.risques.single.niveau, NiveauAlerte.attention);

    final ko = ApiAlertesRepository(
      client((_) => (503, {'detail': 'Clé WEATHER_API_KEY non configurée.'})),
    );
    await expectLater(
      ko.meteo('Dakar'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          'Clé WEATHER_API_KEY non configurée.',
        ),
      ),
    );
  });

  test('alertes : génération et marquage comme lue', () async {
    final repository = ApiAlertesRepository(
      client(
        (options) => options.path.endsWith('generer/')
            ? (200, {'creees': 2})
            : (200, <String, Object>{}),
      ),
    );

    expect(await repository.generer(), 2);
    await repository.marquerLue(9);
    expect(adapter.requests.last.path, '/alertes/9/marquer_lue/');
    expect(adapter.requests.last.method, 'POST');
  });

  test('marché : filtres envoyés et lecture d\'une annonce', () async {
    final repository = ApiAnnonceRepository(
      client(
        (_) => (
          200,
          [
            {
              'id': 4,
              'titre': 'Tomates',
              'description': '',
              'categorie': 'legumes',
              'prix': '8000',
              'quantite': '20 kg',
              'zone': 'Dakar',
              'photo': 'https://exemple.sn/tomates.jpg',
              'image': null,
              'statut': 'disponible',
              'moderation': 'approuvee',
              'vendeur_nom': 'Awa Diop',
              'vendeur_telephone': '771234567',
              'est_proprietaire': false,
              'date_creation': '2026-10-13T17:00:00Z',
            },
          ],
        ),
      ),
    );

    final annonce = (await repository.list(
      const FiltreAnnonces(
        recherche: 'tomate',
        categorie: CategorieAnnonce.legumes,
        zone: 'Dakar',
        prixMax: 10000,
      ),
    )).single;

    expect(adapter.requests.last.queryParameters, {
      'statut': 'disponible',
      'q': 'tomate',
      'categorie': 'legumes',
      'zone': 'Dakar',
      'prix_max': 10000,
    });
    expect(annonce.prix, 8000);
    expect(annonce.photoUrl, 'https://exemple.sn/tomates.jpg');
    expect(annonce.vendeurTelephone, '771234567');
  });

  test('le corps des requêtes est du JSON valide', () async {
    final repository = ApiAnnonceRepository(
      client((options) => (201, {...options.data as Map, 'id': 1})),
    );

    await repository.create(
      const Annonce(
        titre: 'Oignons',
        categorie: CategorieAnnonce.legumes,
        prix: 15000,
      ),
    );

    expect(jsonDecode(jsonEncode(corps())), {
      'titre': 'Oignons',
      'description': '',
      'categorie': 'legumes',
      'prix': 15000,
      'quantite': '',
      'zone': '',
      'statut': 'disponible',
    });
  });
}
