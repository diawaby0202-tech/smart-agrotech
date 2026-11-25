from io import BytesIO
import tempfile
from datetime import date, timedelta

from django.contrib.auth import get_user_model
from django.core.files.uploadedfile import SimpleUploadedFile
from django.core.management import call_command
from rest_framework.test import APITestCase
from django.test import TestCase
from PIL import Image

from elevage.models import Animal, SuiviSanitaire

from .models import Parcelle

User = get_user_model()


def creer(email):
    return User.objects.create_user(email=email, password='Passw0rd!x', nom='N', prenom='P')


class ParcelleTests(APITestCase):
    def setUp(self):
        self.u1 = creer('a@x.com')
        self.u2 = creer('b@x.com')
        self.url = '/api/parcelles/'
        self.data = {'nom': 'Champ 1', 'culture': 'Mil', 'superficie': '2.5'}

    def test_auth_requise(self):
        self.assertEqual(self.client.get(self.url).status_code, 401)

    def test_creation_assigne_proprietaire(self):
        self.client.force_authenticate(self.u1)
        r = self.client.post(self.url, self.data)
        self.assertEqual(r.status_code, 201)
        self.assertEqual(Parcelle.objects.get().proprietaire, self.u1)

    def test_creation_avec_photo(self):
        image = BytesIO()
        Image.new('RGB', (2, 2), 'green').save(image, 'PNG')
        photo = SimpleUploadedFile('parcelle.png', image.getvalue(), content_type='image/png')
        self.client.force_authenticate(self.u1)

        with tempfile.TemporaryDirectory() as media_root:
            with self.settings(MEDIA_ROOT=media_root):
                response = self.client.post(
                    self.url, {**self.data, 'image': photo}, format='multipart'
                )
                self.assertEqual(response.status_code, 201)
                self.assertIn('/media/parcelles/', response.json()['image'])
                self.assertTrue(Parcelle.objects.get().image)

    def test_isolation_entre_utilisateurs(self):
        Parcelle.objects.create(proprietaire=self.u1, nom='x', culture='y', superficie=1)
        self.client.force_authenticate(self.u2)
        self.assertEqual(len(self.client.get(self.url).json()), 0)
        p = Parcelle.objects.get()
        self.assertEqual(self.client.get(f'{self.url}{p.id}/').status_code, 404)
        self.assertEqual(self.client.delete(f'{self.url}{p.id}/').status_code, 404)

    def test_superficie_invalide(self):
        self.client.force_authenticate(self.u1)
        r = self.client.post(self.url, {**self.data, 'superficie': '0'})
        self.assertEqual(r.status_code, 400)

    def test_dates_incoherentes(self):
        self.client.force_authenticate(self.u1)
        r = self.client.post(self.url, {**self.data, 'date_semis': '2026-06-10',
                                        'date_recolte_prevue': '2026-06-01'})
        self.assertEqual(r.status_code, 400)

    def test_maj_statut(self):
        self.client.force_authenticate(self.u1)
        pid = self.client.post(self.url, self.data).json()['id']
        r = self.client.patch(f'{self.url}{pid}/', {'statut': 'semee'})
        self.assertEqual(r.json()['statut'], 'semee')

    def test_calendrier(self):
        today = date.today()
        for nom, d, st in [('b', today + timedelta(days=30), 'semee'),
                           ('a', today + timedelta(days=10), 'croissance'),
                           ('c', today + timedelta(days=5), 'recoltee'),
                           ('d', None, 'semee')]:
            Parcelle.objects.create(proprietaire=self.u1, nom=nom, culture='m', superficie=1,
                                    date_recolte_prevue=d, statut=st)
        self.client.force_authenticate(self.u1)
        noms = [p['nom'] for p in self.client.get(self.url + 'calendrier/').json()]
        self.assertEqual(noms, ['a', 'b'])


class DonneesExempleTests(TestCase):
    def test_ajoute_des_fiches_avec_photos_associees_et_sans_doublons(self):
        user = creer('exemples@x.com')

        call_command('ajouter_donnees_exemple', email=user.email)
        call_command('ajouter_donnees_exemple', email=user.email)

        self.assertEqual(Parcelle.objects.filter(proprietaire=user).count(), 3)
        cultures = set(
            Parcelle.objects.filter(proprietaire=user).values_list('culture', flat=True)
        )
        self.assertEqual(cultures, {'Arachide', 'Mil', 'Maïs'})
        self.assertEqual(Animal.objects.filter(proprietaire=user).count(), 3)
        self.assertEqual(
            SuiviSanitaire.objects.filter(animal__proprietaire=user).count(), 2
        )
