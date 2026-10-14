# Smart AgroTech — application mobile (Flutter)

Application mobile de la plateforme Smart AgroTech Sénégal. Elle consomme la même API REST que le site web.

## Lancer l'application

Prérequis : Flutter SDK (3.44+), un émulateur Android ou un téléphone.

```bash
cd mobile
flutter pub get
flutter run
```

Par défaut l'app tourne en **mode démo** (données fictives, aucun backend nécessaire).
Compte de démonstration : `demo@agrotech.sn` / `demo1234`. Les comptes créés depuis l'écran d'inscription restent en mémoire jusqu'au redémarrage de l'app.

### Brancher la vraie API

```bash
flutter run --dart-define=USE_MOCK=false
```

| Variable | Valeur par défaut | Rôle |
|---|---|---|
| `USE_MOCK` | `true` | `false` pour appeler l'API Django |
| `API_BASE_URL` | `http://10.0.2.2:8000/api` | URL de l'API (`10.0.2.2` = `localhost` du PC vu depuis l'émulateur Android) |

Sur un vrai téléphone, remplacer par l'adresse IP du PC sur le réseau local :
`--dart-define=API_BASE_URL=http://192.168.1.20:8000/api`.

## Tests

```bash
flutter analyze
flutter test
```

## Organisation du code

```
lib/
├── main.dart                  Point d'entrée : choisit mock ou API
├── app.dart                   MaterialApp, thème, synchronisation des rappels
├── core/
│   ├── config.dart            USE_MOCK, API_BASE_URL
│   ├── services.dart          Crée les dépôts (mock ou API) au démarrage
│   ├── api_client.dart        Client HTTP (Dio) + token JWT + refresh
│   ├── api_exception.dart     Erreurs de l'API lisibles par l'utilisateur
│   ├── token_storage.dart     Stockage chiffré des tokens
│   ├── notification_service.dart  Notifications de rappel et d'alerte
│   ├── router.dart            Routes (go_router) + redirection selon la connexion
│   ├── format.dart            Dates, nombres et prix (API ↔ affichage)
│   └── widgets.dart           Widgets partagés (chargement, formulaire, date)
└── features/
    ├── auth/                  Connexion, inscription, état de session
    ├── home/                  Barre d'onglets, accueil
    ├── cultures/              Parcelles, étapes, calendrier des récoltes
    ├── elevage/               Animaux / lots, suivi sanitaire, échéances
    ├── alertes/               Prévisions météo, risques, historique des alertes
    └── marche/                Annonces : recherche, publication, contact vendeur
```

Chaque module a un dépôt « mock » (données fictives) et un dépôt « API » derrière la même interface : les écrans ne savent pas lequel est utilisé.

## Appels à l'API utilisés par l'app

Vérifiés contre le backend en fonctionnement (`main`). Toutes les requêtes hors authentification portent l'en-tête `Authorization: Bearer <access>`.

| Module | Appels |
|---|---|
| Authentification | `POST /api/auth/register/`, `POST /api/auth/login/`, `POST /api/auth/refresh/`, `POST /api/auth/logout/`, `GET /api/users/me/` |
| Cultures | `GET` `POST /api/parcelles/`, `PATCH` `DELETE /api/parcelles/{id}/`, `GET /api/parcelles/calendrier/` |
| Élevage | `GET` `POST /api/animaux/`, `PATCH` `DELETE /api/animaux/{id}/`, `GET /api/suivis-sanitaires/?animal=`, `POST /api/suivis-sanitaires/`, `DELETE /api/suivis-sanitaires/{id}/`, `GET /api/suivis-sanitaires/echeances/?jours=` |
| Météo et alertes | `GET /api/meteo/?ville=`, `GET /api/alertes/`, `POST /api/alertes/generer/`, `POST /api/alertes/{id}/marquer_lue/`, `POST /api/alertes/tout_marquer_lu/` |
| Marché | `GET /api/annonces/?q=&categorie=&zone=&prix_min=&prix_max=&statut=`, `GET /api/annonces/mes_annonces/`, `POST /api/annonces/`, `PATCH` `DELETE /api/annonces/{id}/` |

Les erreurs de validation (`{ "email": ["Message"] }`) sont affichées sous le champ concerné, les erreurs générales (`{ "detail": "Message" }`) sous le formulaire.

### Météo

Les prévisions viennent d'OpenWeatherMap via le backend. Sans `WEATHER_API_KEY` dans `backend/.env`, l'API répond 503 et l'onglet Prévisions affiche « Météo indisponible pour le moment. ». Les rappels de récolte et de vaccination fonctionnent sans cette clé.

### Notifications de rappel (RF-27)

À la connexion et à chaque ouverture de l'onglet Alertes, l'app demande au serveur de générer les alertes du jour (`/api/alertes/generer/`) puis affiche une notification pour chaque nouvelle alerte non lue. Limite connue : le backend n'a pas de service de push, donc aucune notification n'arrive tant que l'app est fermée.

### Photos des annonces

La photo est choisie dans la galerie et envoyée dans le champ `image` (multipart). Cet envoi n'a pas encore été testé sur un téléphone.

### Émulateur Android et `ALLOWED_HOSTS`

Django refuse (erreur 400) les requêtes envoyées à `10.0.2.2` tant que cette adresse n'est pas dans `ALLOWED_HOSTS` (`backend/config/settings.py`). En attendant, on peut rediriger le port de l'émulateur vers le PC et utiliser `localhost` :

```bash
adb reverse tcp:8000 tcp:8000
flutter run --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=http://localhost:8000/api
```
