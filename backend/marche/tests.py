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


class ModerationAdminTests(APITestCase):
    def setUp(self):
        self.admin = User.objects.create_user(email='adm@x.com', password='Passw0rd!x', nom='A',
                                              prenom='B', role='admin')
        self.vendeur = creer('v@x.com')
        self.a = Annonce.objects.create(vendeur=self.vendeur, titre='Mil', categorie='cereales',
                                        prix=1000)
        self.b = Annonce.objects.create(vendeur=self.vendeur, titre='Faux produit',
                                        categorie='autre', prix=5)
        self.url = '/api/admin/annonces/'

    def test_refuse_aux_non_admins(self):
        self.assertEqual(self.client.get(self.url).status_code, 401)
        self.client.force_authenticate(self.vendeur)
        self.assertEqual(self.client.get(self.url).status_code, 403)
        self.assertEqual(self.client.post(f'{self.url}{self.a.id}/masquer/').status_code, 403)

    def test_liste_complete_pour_admin(self):
        Annonce.objects.filter(pk=self.b.pk).update(moderation='supprimee')
        self.client.force_authenticate(self.admin)
        r = self.client.get(self.url).json()
        self.assertEqual(len(r), 2)
        self.assertIn('vendeur_email', r[0])

    def test_filtres(self):
        Annonce.objects.filter(pk=self.b.pk).update(moderation='supprimee')
        self.client.force_authenticate(self.admin)
        self.assertEqual(len(self.client.get(self.url + '?moderation=supprimee').json()), 1)
        self.assertEqual(len(self.client.get(self.url + '?q=faux').json()), 1)
        self.assertEqual(len(self.client.get(self.url + f'?vendeur={self.vendeur.id}').json()), 2)

    def test_masquer_retire_du_marche(self):
        self.client.force_authenticate(self.admin)
        r = self.client.post(f'{self.url}{self.b.id}/masquer/')
        self.assertEqual(r.json()['moderation'], 'supprimee')
        self.client.force_authenticate(self.vendeur)
        titres = [a['titre'] for a in self.client.get('/api/annonces/').json()]
        self.assertEqual(titres, ['Mil'])

    def test_restaurer(self):
        Annonce.objects.filter(pk=self.b.pk).update(moderation='supprimee')
        self.client.force_authenticate(self.admin)
        r = self.client.post(f'{self.url}{self.b.id}/restaurer/')
        self.assertEqual(r.json()['moderation'], 'approuvee')

    def test_patch_moderation_seulement(self):
        self.client.force_authenticate(self.admin)
        r = self.client.patch(f'{self.url}{self.a.id}/', {'moderation': 'supprimee', 'prix': 1})
        self.assertEqual(r.status_code, 200)
        self.a.refresh_from_db()
        self.assertEqual(self.a.moderation, 'supprimee')
        self.assertEqual(self.a.prix, 1000)

    def test_suppression_definitive(self):
        self.client.force_authenticate(self.admin)
        self.assertEqual(self.client.delete(f'{self.url}{self.b.id}/').status_code, 204)
        self.assertFalse(Annonce.objects.filter(pk=self.b.pk).exists())

    def test_pas_de_creation_ni_put(self):
        self.client.force_authenticate(self.admin)
        self.assertEqual(self.client.post(self.url, {'titre': 'x'}).status_code, 405)
        self.assertEqual(self.client.put(f'{self.url}{self.a.id}/', {}).status_code, 405)


# ---------- Photo des annonces (RF-16) ----------
import shutil
import tempfile
from io import BytesIO

from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import override_settings
from PIL import Image

_MEDIA = tempfile.mkdtemp()


def faux_png(taille=(10, 10), nom='photo.png'):
    buf = BytesIO()
    Image.new('RGB', taille, 'green').save(buf, 'PNG')
    return SimpleUploadedFile(nom, buf.getvalue(), content_type='image/png')


@override_settings(MEDIA_ROOT=_MEDIA)
class PhotoAnnonceTests(APITestCase):
    @classmethod
    def tearDownClass(cls):
        super().tearDownClass()
        shutil.rmtree(_MEDIA, ignore_errors=True)

    def setUp(self):
        self.u = creer('p@x.com')
        self.client.force_authenticate(self.u)

    def test_publication_avec_photo(self):
        r = self.client.post('/api/annonces/', {
            'titre': 'Tomates', 'categorie': 'legumes', 'prix': 3000, 'image': faux_png()},
            format='multipart')
        self.assertEqual(r.status_code, 201)
        self.assertIn('/media/annonces/', r.json()['image'])
        self.assertTrue(Annonce.objects.get().image)

    def test_publication_sans_photo(self):
        r = self.client.post('/api/annonces/', {
            'titre': 'Tomates', 'categorie': 'legumes', 'prix': 3000}, format='json')
        self.assertEqual(r.status_code, 201)
        self.assertIsNone(r.json()['image'])

    def test_fichier_non_image_refuse(self):
        faux = SimpleUploadedFile('a.png', b'pas une image', content_type='image/png')
        r = self.client.post('/api/annonces/', {
            'titre': 'x', 'categorie': 'autre', 'prix': 1, 'image': faux}, format='multipart')
        self.assertEqual(r.status_code, 400)

    def test_image_trop_lourde_refusee(self):
        gros = SimpleUploadedFile('gros.png', faux_png().read() + b'0' * (5 * 1024 * 1024),
                                  content_type='image/png')
        r = self.client.post('/api/annonces/', {
            'titre': 'x', 'categorie': 'autre', 'prix': 1, 'image': gros}, format='multipart')
        self.assertEqual(r.status_code, 400)
