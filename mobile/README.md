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
├── app.dart                   MaterialApp, thème
├── core/
│   ├── config.dart            USE_MOCK, API_BASE_URL
│   ├── api_client.dart        Client HTTP (Dio) + token JWT + refresh
│   ├── api_exception.dart     Erreurs de l'API lisibles par l'utilisateur
│   ├── token_storage.dart     Stockage chiffré des tokens
│   └── router.dart            Routes (go_router) + redirection selon la connexion
└── features/
    ├── auth/                  Connexion, inscription, état de session
    └── home/                  Barre d'onglets, accueil, écrans provisoires
```

Chaque module à venir (cultures, élevage, météo, marché) aura son dossier dans `features/`, avec un dépôt « mock » et un dépôt « API » derrière la même interface, comme `auth/`.

## Appels à l'API utilisés par l'app

Vérifiés avec le code du backend (app `utilisateurs`, fusionnée dans `main`) :

| Appel | Corps envoyé | Réponse |
|---|---|---|
| `POST /api/auth/register/` | `nom`, `prenom`, `email`, `telephone`, `password` (8 caractères min.), `role` (`producteur` ou `acheteur`) | 201 |
| `POST /api/auth/login/` | `email`, `password` | `{ "access": "...", "refresh": "..." }` |
| `POST /api/auth/refresh/` | `refresh` | `{ "access": "..." }` |
| `GET /api/users/me/` | — (en-tête `Authorization: Bearer <access>`) | `id`, `nom`, `prenom`, `email`, `telephone`, `role`, `statut`, `date_inscription` |

Les erreurs de validation (`{ "email": ["Message"] }`) sont affichées sous le champ concerné, les erreurs générales (`{ "detail": "Message" }`) sous le formulaire.

### Émulateur Android et `ALLOWED_HOSTS`

Django refuse (erreur 400) les requêtes envoyées à `10.0.2.2` tant que cette adresse n'est pas dans `ALLOWED_HOSTS` (`backend/config/settings.py`). En attendant, on peut rediriger le port de l'émulateur vers le PC et utiliser `localhost` :

```bash
adb reverse tcp:8000 tcp:8000
flutter run --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=http://localhost:8000/api
```
