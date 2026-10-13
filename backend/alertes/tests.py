from django.contrib.auth import get_user_model
from rest_framework.test import APITestCase

from .models import Alerte

User = get_user_model()


def creer(email):
    return User.objects.create_user(email=email, password='Passw0rd!x', nom='N', prenom='P')


class AlerteTests(APITestCase):
    def setUp(self):
        self.u1 = creer('a@x.com')
        self.u2 = creer('b@x.com')
        self.a1 = Alerte.objects.create(utilisateur=self.u1, titre='Pluie', message='Fortes pluies',
                                        type='meteo', niveau='danger')
        Alerte.objects.create(utilisateur=self.u1, titre='Vaccin', message='m', lue=True)
        Alerte.objects.create(utilisateur=self.u2, titre='Autre', message='m')

    def test_auth_requise(self):
        self.assertEqual(self.client.get('/api/alertes/').status_code, 401)

    def test_historique_personnel(self):
        self.client.force_authenticate(self.u1)
        self.assertEqual(len(self.client.get('/api/alertes/').json()), 2)

    def test_filtre_non_lues(self):
        self.client.force_authenticate(self.u1)
        r = self.client.get('/api/alertes/?lue=false').json()
        self.assertEqual([a['titre'] for a in r], ['Pluie'])

    def test_creation_interdite(self):
        self.client.force_authenticate(self.u1)
        r = self.client.post('/api/alertes/', {'titre': 'x', 'message': 'y'})
        self.assertEqual(r.status_code, 405)

    def test_marquer_lue(self):
        self.client.force_authenticate(self.u1)
        r = self.client.post(f'/api/alertes/{self.a1.id}/marquer_lue/')
        self.assertTrue(r.json()['lue'])

    def test_marquer_alerte_d_autrui(self):
        self.client.force_authenticate(self.u2)
        r = self.client.post(f'/api/alertes/{self.a1.id}/marquer_lue/')
        self.assertEqual(r.status_code, 404)

    def test_tout_marquer_lu(self):
        self.client.force_authenticate(self.u1)
        r = self.client.post('/api/alertes/tout_marquer_lu/')
        self.assertEqual(r.json()['mises_a_jour'], 1)


# ---------- Météo et génération automatique ----------
from datetime import date, timedelta
from unittest.mock import patch

from django.core.management import call_command

from cultures.models import Parcelle
from elevage.models import Animal, SuiviSanitaire
from . import services


def fausse_reponse(temp=30, pluie=0.0, vent=3.0, jour='2026-07-01'):
    return {'list': [
        {'dt_txt': f'{jour} 12:00:00', 'main': {'temp': temp},
         'wind': {'speed': vent}, 'rain': {'3h': pluie},
         'weather': [{'description': 'ciel dégagé'}]},
        {'dt_txt': f'{jour} 15:00:00', 'main': {'temp': temp - 5},
         'wind': {'speed': vent}, 'rain': {'3h': pluie},
         'weather': [{'description': 'ciel dégagé'}]},
    ]}


class ServicesMeteoTests(APITestCase):
    def test_resume_par_jour(self):
        r = services.resumer_par_jour(fausse_reponse(temp=35, pluie=5))
        self.assertEqual(len(r), 1)
        self.assertEqual(r[0]['temp_max'], 35)
        self.assertEqual(r[0]['temp_min'], 30)
        self.assertEqual(r[0]['pluie_mm'], 10)

    def test_aucun_risque_par_temps_calme(self):
        self.assertEqual(services.detecter_risques(services.resumer_par_jour(fausse_reponse())), [])

    def test_risque_pluie(self):
        r = services.detecter_risques(services.resumer_par_jour(fausse_reponse(pluie=15)))
        self.assertEqual(r[0][0], 'danger')

    def test_risque_chaleur_niveaux(self):
        r = services.detecter_risques(services.resumer_par_jour(fausse_reponse(temp=38)))
        self.assertEqual(r[0][0], 'attention')
        r = services.detecter_risques(services.resumer_par_jour(fausse_reponse(temp=41)))
        self.assertEqual(r[0][0], 'danger')

    def test_risque_vent(self):
        r = services.detecter_risques(services.resumer_par_jour(fausse_reponse(vent=18)))
        self.assertEqual(r[0][1].startswith('Vent fort'), True)

    def test_sans_cle_api(self):
        with self.settings(WEATHER_API_KEY=''):
            with self.assertRaises(services.MeteoIndisponible):
                services.get_forecast('Dakar')


class MeteoEndpointTests(APITestCase):
    def setUp(self):
        self.u = creer('m@x.com')

    def test_auth_requise(self):
        self.assertEqual(self.client.get('/api/meteo/').status_code, 401)

    @patch('alertes.views.get_forecast')
    def test_previsions_et_risques(self, mock):
        mock.return_value = fausse_reponse(temp=41)
        self.client.force_authenticate(self.u)
        r = self.client.get('/api/meteo/?ville=Thiès')
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.json()['ville'], 'Thiès')
        self.assertEqual(len(r.json()['previsions']), 1)
        self.assertEqual(r.json()['risques'][0]['niveau'], 'danger')
        mock.assert_called_with('Thiès')

    @patch('alertes.views.get_forecast', side_effect=services.MeteoIndisponible('KO'))
    def test_service_indisponible(self, _):
        self.client.force_authenticate(self.u)
        self.assertEqual(self.client.get('/api/meteo/').status_code, 503)


class GenerationAlertesTests(APITestCase):
    def setUp(self):
        self.u = creer('g@x.com')
        Parcelle.objects.create(proprietaire=self.u, nom='P', culture='Mil', superficie=1,
                                localisation='Thiès')
        animal = Animal.objects.create(proprietaire=self.u, espece='Bovin')
        today = date.today()
        SuiviSanitaire.objects.create(animal=animal, type='vaccination', date=today,
                                      prochaine_echeance=today + timedelta(days=2))
        SuiviSanitaire.objects.create(animal=animal, type='visite', date=today,
                                      prochaine_echeance=today + timedelta(days=60))

    @patch('alertes.services.get_forecast')
    def test_genere_meteo_et_vaccination(self, mock):
        mock.return_value = fausse_reponse(temp=41)
        n = services.generer_alertes(self.u)
        self.assertEqual(n, 2)
        self.assertEqual(Alerte.objects.filter(utilisateur=self.u, type='meteo').count(), 1)
        self.assertEqual(Alerte.objects.filter(utilisateur=self.u, type='vaccination').count(), 1)

    @patch('alertes.services.get_forecast')
    def test_pas_de_doublon(self, mock):
        mock.return_value = fausse_reponse(temp=41)
        services.generer_alertes(self.u)
        self.assertEqual(services.generer_alertes(self.u), 0)

    @patch('alertes.services.get_forecast', side_effect=services.MeteoIndisponible('KO'))
    def test_meteo_en_panne_garde_vaccination(self, _):
        self.assertEqual(services.generer_alertes(self.u), 1)

    @patch('alertes.services.get_forecast')
    def test_endpoint_generer(self, mock):
        mock.return_value = fausse_reponse()
        self.client.force_authenticate(self.u)
        r = self.client.post('/api/alertes/generer/')
        self.assertEqual(r.json()['creees'], 1)

    @patch('alertes.services.get_forecast')
    def test_commande(self, mock):
        mock.return_value = fausse_reponse()
        User.objects.filter(pk=self.u.pk).update(statut='valide')
        call_command('generer_alertes')
        self.assertEqual(Alerte.objects.count(), 1)
