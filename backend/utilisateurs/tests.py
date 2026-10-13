from rest_framework import status
from rest_framework.test import APITestCase

from .models import RoleUtilisateur, StatutCompte, Utilisateur

DONNEES = {
    'email': 'awa@mail.com',
    'nom': 'Ndiaye',
    'prenom': 'Awa',
    'telephone': '770000000',
    'role': 'producteur',
    'password': 'MotDePasse2026!',
}


class AuthentificationTests(APITestCase):
    def test_inscription(self):
        reponse = self.client.post('/api/auth/register/', DONNEES)
        self.assertEqual(reponse.status_code, status.HTTP_201_CREATED)
        self.assertNotIn('password', reponse.data)
        self.assertTrue(Utilisateur.objects.filter(email='awa@mail.com').exists())

    def test_inscription_refuse_role_admin(self):
        reponse = self.client.post('/api/auth/register/', {**DONNEES, 'role': 'admin'})
        self.assertEqual(reponse.status_code, status.HTTP_400_BAD_REQUEST)

    def test_connexion_et_profil(self):
        self.client.post('/api/auth/register/', DONNEES)
        reponse = self.client.post(
            '/api/auth/login/', {'email': DONNEES['email'], 'password': DONNEES['password']}
        )
        self.assertEqual(reponse.status_code, status.HTTP_200_OK)
        self.assertIn('access', reponse.data)
        self.assertIn('refresh', reponse.data)

        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {reponse.data['access']}")
        profil = self.client.get('/api/users/me/')
        self.assertEqual(profil.status_code, status.HTTP_200_OK)
        self.assertEqual(profil.data['email'], DONNEES['email'])

        modif = self.client.patch('/api/users/me/', {'telephone': '781111111'})
        self.assertEqual(modif.status_code, status.HTTP_200_OK)
        self.assertEqual(modif.data['telephone'], '781111111')

    def test_profil_sans_token(self):
        self.assertEqual(self.client.get('/api/users/me/').status_code, status.HTTP_401_UNAUTHORIZED)

    def test_mauvais_mot_de_passe(self):
        self.client.post('/api/auth/register/', DONNEES)
        reponse = self.client.post('/api/auth/login/', {'email': DONNEES['email'], 'password': 'faux'})
        self.assertEqual(reponse.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_role_non_modifiable_par_le_profil(self):
        self.client.post('/api/auth/register/', DONNEES)
        token = self.client.post(
            '/api/auth/login/', {'email': DONNEES['email'], 'password': DONNEES['password']}
        ).data['access']
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        self.client.patch('/api/users/me/', {'role': 'admin'})
        self.assertEqual(Utilisateur.objects.get(email=DONNEES['email']).role, 'producteur')


class AdministrationTests(APITestCase):
    def setUp(self):
        self.admin = Utilisateur.objects.create_superuser(
            email='admin@mail.com', password='AdminPass2026!', nom='Admin', prenom='Super'
        )
        self.simple = Utilisateur.objects.create_user(
            email='user@mail.com', password='UserPass2026!', nom='User', prenom='Simple',
            statut=StatutCompte.EN_ATTENTE,
        )

    def _connecter(self, email, mot_de_passe):
        reponse = self.client.post('/api/auth/login/', {'email': email, 'password': mot_de_passe})
        if reponse.status_code == 200:
            self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {reponse.data['access']}")
        return reponse

    def test_compte_en_attente_ne_peut_pas_se_connecter(self):
        reponse = self._connecter('user@mail.com', 'UserPass2026!')
        self.assertEqual(reponse.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_liste_reservee_a_ladmin(self):
        self.simple.statut = StatutCompte.VALIDE
        self.simple.save()
        self._connecter('user@mail.com', 'UserPass2026!')
        self.assertEqual(self.client.get('/api/admin/users/').status_code, status.HTTP_403_FORBIDDEN)

    def test_admin_valide_un_compte(self):
        self._connecter('admin@mail.com', 'AdminPass2026!')
        liste = self.client.get('/api/admin/users/?statut=en_attente')
        self.assertEqual(liste.status_code, status.HTTP_200_OK)
        reponse = self.client.patch(f'/api/admin/users/{self.simple.id}/', {'statut': 'valide'})
        self.assertEqual(reponse.status_code, status.HTTP_200_OK)
        self.simple.refresh_from_db()
        self.assertEqual(self.simple.statut, StatutCompte.VALIDE)

    def test_admin_ne_peut_pas_se_supprimer(self):
        self._connecter('admin@mail.com', 'AdminPass2026!')
        reponse = self.client.delete(f'/api/admin/users/{self.admin.id}/')
        self.assertEqual(reponse.status_code, status.HTTP_403_FORBIDDEN)

    def test_admin_supprime_un_compte(self):
        self._connecter('admin@mail.com', 'AdminPass2026!')
        reponse = self.client.delete(f'/api/admin/users/{self.simple.id}/')
        self.assertEqual(reponse.status_code, status.HTTP_204_NO_CONTENT)


class StatistiquesTests(APITestCase):
    def setUp(self):
        self.admin = Utilisateur.objects.create_superuser(
            email='admin@mail.com', password='AdminPass2026!', nom='Admin', prenom='Super'
        )
        Utilisateur.objects.create_user(
            email='p1@mail.com', password='Pass2026!x', nom='P', prenom='Un', role='producteur'
        )
        Utilisateur.objects.create_user(
            email='a1@mail.com', password='Pass2026!x', nom='A', prenom='Un', role='acheteur',
            statut=StatutCompte.EN_ATTENTE,
        )

    def _connecter(self, email, mot_de_passe):
        reponse = self.client.post('/api/auth/login/', {'email': email, 'password': mot_de_passe})
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {reponse.data['access']}")

    def test_statistiques_pour_ladmin(self):
        self._connecter('admin@mail.com', 'AdminPass2026!')
        reponse = self.client.get('/api/admin/stats/')
        self.assertEqual(reponse.status_code, status.HTTP_200_OK)
        self.assertEqual(reponse.data['total_utilisateurs'], 3)
        self.assertEqual(reponse.data['par_role']['producteur'], 1)
        self.assertEqual(reponse.data['par_role']['acheteur'], 1)
        self.assertEqual(reponse.data['par_role']['admin'], 1)
        self.assertEqual(reponse.data['par_statut']['en_attente'], 1)
        self.assertEqual(reponse.data['par_statut']['suspendu'], 0)
        self.assertEqual(reponse.data['nouveaux_30_jours'], 3)

    def test_statistiques_interdites_aux_non_admins(self):
        self._connecter('p1@mail.com', 'Pass2026!x')
        self.assertEqual(self.client.get('/api/admin/stats/').status_code, status.HTTP_403_FORBIDDEN)

    def test_statistiques_sans_connexion(self):
        self.assertEqual(self.client.get('/api/admin/stats/').status_code, status.HTTP_401_UNAUTHORIZED)
