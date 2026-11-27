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

from .models import Parcelle, Recolte

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

    def test_prix_indicatif_est_enregistre(self):
        self.client.force_authenticate(self.u1)
        r = self.client.post(self.url, {**self.data, 'prix_indicatif': 900})
        self.assertEqual(r.status_code, 201)
        self.assertEqual(r.json()['prix_indicatif'], 900)
        self.assertEqual(Parcelle.objects.get().prix_indicatif, 900)

    def test_prix_indicatif_doit_etre_positif(self):
        self.client.force_authenticate(self.u1)
        r = self.client.post(self.url, {**self.data, 'prix_indicatif': 0})
        self.assertEqual(r.status_code, 400)
        self.assertIn('prix_indicatif', r.json())

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

    def test_admin_voit_les_parcelles_de_tous_les_producteurs(self):
        Parcelle.objects.create(proprietaire=self.u1, nom='Champ A', culture='Mil', superficie=1)
        Parcelle.objects.create(proprietaire=self.u2, nom='Champ B', culture='Riz', superficie=2)
        admin = User.objects.create_superuser(
            email='admin@x.com', password='Passw0rd!x', nom='Admin', prenom='A'
        )
        self.client.force_authenticate(admin)

        response = self.client.get(self.url)

        self.assertEqual(
            {parcelle['nom'] for parcelle in response.json()},
            {'Champ A', 'Champ B'},
        )

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


class RecolteTests(APITestCase):
    def setUp(self):
        self.u1 = creer('recolte-a@x.com')
        self.u2 = creer('recolte-b@x.com')
        self.parcelle = Parcelle.objects.create(
            proprietaire=self.u1,
            nom='Champ 1',
            culture='Mil',
            superficie=2,
        )
        self.url = '/api/recoltes/'
        self.data = {
            'parcelle': self.parcelle.id,
            'date': '2026-10-14',
            'quantite': '125.50',
            'unite': 'kg',
            'notes': 'Première récolte',
        }

    def test_auth_requise(self):
        self.assertEqual(self.client.get(self.url).status_code, 401)

    def test_creation_et_filtre_par_parcelle(self):
        self.client.force_authenticate(self.u1)
        response = self.client.post(self.url, self.data)

        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.json()['quantite'], '125.50')
        self.assertEqual(
            len(self.client.get(f'{self.url}?parcelle={self.parcelle.id}').json()),
            1,
        )

    def test_refuse_parcelle_d_un_autre_utilisateur(self):
        self.client.force_authenticate(self.u2)

        response = self.client.post(self.url, self.data)

        self.assertEqual(response.status_code, 400)
        self.assertEqual(Recolte.objects.count(), 0)

    def test_admin_voit_les_recoltes_de_tous_les_producteurs(self):
        autre_parcelle = Parcelle.objects.create(
            proprietaire=self.u2, nom='Champ 2', culture='Riz', superficie=1
        )
        Recolte.objects.create(
            parcelle=self.parcelle, date=date.today(), quantite=10, unite='kg'
        )
        Recolte.objects.create(
            parcelle=autre_parcelle, date=date.today(), quantite=20, unite='kg'
        )
        admin = User.objects.create_superuser(
            email='admin-recolte@x.com',
            password='Passw0rd!x',
            nom='Admin',
            prenom='A',
        )
        self.client.force_authenticate(admin)

        response = self.client.get(self.url)

        self.assertEqual(len(response.json()), 2)
        response = self.client.post(
            self.url,
            {
                'parcelle': autre_parcelle.id,
                'date': date.today().isoformat(),
                'quantite': '5',
                'unite': 'kg',
            },
        )
        self.assertEqual(response.status_code, 201)

    def test_quantite_invalide(self):
        self.client.force_authenticate(self.u1)

        response = self.client.post(
            self.url, {**self.data, 'quantite': '0'}
        )

        self.assertEqual(response.status_code, 400)


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
