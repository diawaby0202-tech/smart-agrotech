from datetime import date, timedelta

from django.contrib.auth import get_user_model
from rest_framework.test import APITestCase

from .models import Animal, SuiviSanitaire

User = get_user_model()


def creer(email):
    return User.objects.create_user(email=email, password='Passw0rd!x', nom='N', prenom='P')


class ElevageTests(APITestCase):
    def setUp(self):
        self.u1 = creer('a@x.com')
        self.u2 = creer('b@x.com')
        self.animal = Animal.objects.create(proprietaire=self.u1, espece='Bovin', effectif=5)

    def test_auth_requise(self):
        self.assertEqual(self.client.get('/api/animaux/').status_code, 401)
        self.assertEqual(self.client.get('/api/suivis-sanitaires/').status_code, 401)

    def test_creation_animal(self):
        self.client.force_authenticate(self.u1)
        r = self.client.post('/api/animaux/', {'espece': 'Ovin', 'effectif': 10})
        self.assertEqual(r.status_code, 201)
        self.assertEqual(Animal.objects.get(id=r.json()['id']).proprietaire, self.u1)

    def test_effectif_invalide(self):
        self.client.force_authenticate(self.u1)
        r = self.client.post('/api/animaux/', {'espece': 'Ovin', 'effectif': 0})
        self.assertEqual(r.status_code, 400)

    def test_isolation_animaux(self):
        self.client.force_authenticate(self.u2)
        self.assertEqual(self.client.get('/api/animaux/').json(), [])
        self.assertEqual(self.client.get(f'/api/animaux/{self.animal.id}/').status_code, 404)

    def test_suivi_sur_animal_d_autrui_refuse(self):
        self.client.force_authenticate(self.u2)
        r = self.client.post('/api/suivis-sanitaires/', {
            'animal': self.animal.id, 'type': 'vaccination', 'date': '2026-01-01'})
        self.assertEqual(r.status_code, 400)

    def test_creation_suivi(self):
        self.client.force_authenticate(self.u1)
        r = self.client.post('/api/suivis-sanitaires/', {
            'animal': self.animal.id, 'type': 'vaccination', 'date': '2026-01-01',
            'prochaine_echeance': '2026-07-01'})
        self.assertEqual(r.status_code, 201)

    def test_echeance_avant_date_refusee(self):
        self.client.force_authenticate(self.u1)
        r = self.client.post('/api/suivis-sanitaires/', {
            'animal': self.animal.id, 'type': 'visite', 'date': '2026-05-01',
            'prochaine_echeance': '2026-04-01'})
        self.assertEqual(r.status_code, 400)

    def test_echeances_a_venir(self):
        today = date.today()
        for jours in (3, 10, 60):
            SuiviSanitaire.objects.create(animal=self.animal, type='vaccination', date=today,
                                          prochaine_echeance=today + timedelta(days=jours))
        self.client.force_authenticate(self.u1)
        r = self.client.get('/api/suivis-sanitaires/echeances/')
        self.assertEqual(len(r.json()), 2)
        r = self.client.get('/api/suivis-sanitaires/echeances/?jours=90')
        self.assertEqual(len(r.json()), 3)

    def test_filtre_par_animal(self):
        autre = Animal.objects.create(proprietaire=self.u1, espece='Ovin')
        for a in (self.animal, autre):
            SuiviSanitaire.objects.create(animal=a, type='visite', date=date.today())
        self.client.force_authenticate(self.u1)
        r = self.client.get(f'/api/suivis-sanitaires/?animal={autre.id}')
        self.assertEqual(len(r.json()), 1)
