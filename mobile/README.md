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

## Ce que l'app attend de l'API (à valider avec le backend)

Les chemins viennent du README principal. Le format des données ci-dessous est une **hypothèse** côté mobile tant que le contrat Swagger n'existe pas :

| Appel | Corps envoyé | Réponse attendue |
|---|---|---|
| `POST /api/auth/register/` | `nom`, `prenom`, `email`, `telephone`, `password`, `role` (`producteur` ou `acheteur`) | 201 |
| `POST /api/auth/login/` | `email`, `password` | `{ "access": "...", "refresh": "..." }` |
| `POST /api/auth/refresh/` | `refresh` | `{ "access": "..." }` |
| `GET /api/users/me/` | — (en-tête `Authorization: Bearer <access>`) | `id`, `nom`, `prenom`, `email`, `telephone`, `role` |

Erreurs de validation au format Django REST Framework : `{ "email": ["Message"] }` ou `{ "detail": "Message" }`.
