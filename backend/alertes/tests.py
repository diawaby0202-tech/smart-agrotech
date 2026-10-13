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
