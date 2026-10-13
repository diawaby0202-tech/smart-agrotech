from django.contrib.auth import get_user_model
from rest_framework.test import APITestCase

from .models import Annonce

User = get_user_model()


def creer(email):
    return User.objects.create_user(email=email, password='Passw0rd!x', nom='Diop', prenom='Moussa',
                                    telephone='770000000')


class AnnonceTests(APITestCase):
    def setUp(self):
        self.u1 = creer('a@x.com')
        self.u2 = creer('b@x.com')
        self.url = '/api/annonces/'
        Annonce.objects.create(vendeur=self.u1, titre='Mil 50kg', categorie='cereales',
                               prix=15000, zone='Thiès')
        Annonce.objects.create(vendeur=self.u2, titre='Oignons', categorie='legumes',
                               prix=8000, zone='Saint-Louis')
        Annonce.objects.create(vendeur=self.u2, titre='Mouton', categorie='betail',
                               prix=120000, zone='Thiès')

    def test_auth_requise(self):
        self.assertEqual(self.client.get(self.url).status_code, 401)

    def test_liste_publique_pour_connectes(self):
        self.client.force_authenticate(self.u1)
        self.assertEqual(len(self.client.get(self.url).json()), 3)

    def test_creation(self):
        self.client.force_authenticate(self.u1)
        r = self.client.post(self.url, {'titre': 'Arachide', 'categorie': 'cereales', 'prix': 20000})
        self.assertEqual(r.status_code, 201)
        self.assertEqual(Annonce.objects.get(id=r.json()['id']).vendeur, self.u1)
        self.assertEqual(r.json()['vendeur_telephone'], '770000000')

    def test_prix_negatif(self):
        self.client.force_authenticate(self.u1)
        r = self.client.post(self.url, {'titre': 'x', 'categorie': 'autre', 'prix': -5})
        self.assertEqual(r.status_code, 400)

    def test_filtres(self):
        self.client.force_authenticate(self.u1)
        g = lambda q: len(self.client.get(self.url + q).json())
        self.assertEqual(g('?categorie=legumes'), 1)
        self.assertEqual(g('?zone=thiès'), 2)
        self.assertEqual(g('?prix_min=10000&prix_max=50000'), 1)
        self.assertEqual(g('?q=mou'), 1)
        self.assertEqual(g('?prix_min=abc'), 3)

    def test_modification_par_autrui_interdite(self):
        a = Annonce.objects.get(titre='Oignons')
        self.client.force_authenticate(self.u1)
        self.assertEqual(self.client.patch(f'{self.url}{a.id}/', {'prix': 1}).status_code, 403)
        self.assertEqual(self.client.delete(f'{self.url}{a.id}/').status_code, 403)

    def test_modification_par_vendeur(self):
        a = Annonce.objects.get(titre='Oignons')
        self.client.force_authenticate(self.u2)
        r = self.client.patch(f'{self.url}{a.id}/', {'statut': 'vendue'})
        self.assertEqual(r.json()['statut'], 'vendue')
        self.assertEqual(self.client.delete(f'{self.url}{a.id}/').status_code, 204)

    def test_moderation_non_modifiable_par_vendeur(self):
        a = Annonce.objects.get(titre='Mil 50kg')
        self.client.force_authenticate(self.u1)
        self.client.patch(f'{self.url}{a.id}/', {'moderation': 'supprimee'})
        a.refresh_from_db()
        self.assertEqual(a.moderation, 'approuvee')

    def test_annonce_supprimee_par_admin_masquee(self):
        Annonce.objects.filter(titre='Mouton').update(moderation='supprimee')
        self.client.force_authenticate(self.u1)
        self.assertEqual(len(self.client.get(self.url).json()), 2)

    def test_mes_annonces(self):
        self.client.force_authenticate(self.u2)
        self.assertEqual(len(self.client.get(self.url + 'mes_annonces/').json()), 2)
