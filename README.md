# Smart AgroTech Sénégal

Plateforme web et mobile dédiée à l'agriculture, à l'élevage et à la protection de l'environnement au Sénégal : suivi des cultures, gestion du bétail, alertes météo et marché agricole en ligne.

Projet réalisé pour Monsieur Mandiang (voir le cahier des charges).

## Architecture

Un backend unique expose une API REST, consommée par deux clients (web et mobile).

```
smart-agrotech/
├── backend/    API Django + Django REST Framework + PostgreSQL
├── frontend/   Application web React (Vite)
├── mobile/     Application mobile Flutter
└── docs/       Cahier des charges, maquettes, contrat d'API
```

| Composant | Technologie |
|---|---|
| Backend | Django, Django REST Framework |
| Base de données | PostgreSQL |
| Authentification | JWT (djangorestframework-simplejwt) |
| Documentation API | drf-spectacular (Swagger / OpenAPI) |
| Frontend web | React.js (Vite) |
| Mobile | Flutter (Dart) |
| Service météo | OpenWeatherMap (ou équivalent) |

## Équipe

| Membre | Rôle | Dossier |
|---|---|---|
| El Hadji Cheikhou Omar Faye | Backend | `backend/` |
| Daouda Dieng | Backend | `backend/` |
| Aby Diaw | Frontend React | `frontend/` |
| Aldiouma Alassane Wane | Mobile Flutter | `mobile/` |

## Installation

### Backend

Prérequis : Python 3.11+, PostgreSQL.

```bash
cd backend
python -m venv venv
source venv/bin/activate        # Windows : venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env            # puis renseigner les valeurs
python manage.py migrate
python manage.py runserver
```

API disponible sur `http://localhost:8000`. Documentation Swagger sur `http://localhost:8000/api/docs/`.

### Frontend (React)

Prérequis : Node.js 18+.

```bash
cd frontend
npm install
cp .env.example .env            # VITE_API_URL=http://localhost:8000/api
npm run dev
```

### Mobile (Flutter)

Prérequis : Flutter SDK, Android Studio (émulateur) ou un téléphone Android.

```bash
cd mobile
flutter pub get
flutter run
```

Sur l'émulateur Android, l'API locale est accessible via `http://10.0.2.2:8000`.

## Variables d'environnement

Ne jamais envoyer de fichier `.env` sur GitHub. Chaque dossier fournit un `.env.example` à copier.

Exemple pour `backend/.env.example` :

```
SECRET_KEY=change-me
DEBUG=True
DB_NAME=smart_agrotech
DB_USER=postgres
DB_PASSWORD=
DB_HOST=localhost
DB_PORT=5432
WEATHER_API_KEY=
```

## Règles de travail avec Git

- Personne ne pousse directement sur `main`.
- Une branche par tâche : `feature/nom-court`, `fix/nom-court`.
- Un commit = une idée, avec un message clair (ex. : `feat: ajout du modèle Parcelle`).
- Pull Request vers `main`, relue par au moins une autre personne avant fusion.
- Avant de commencer : `git pull origin main`.
- Une Pull Request par tâche (Issue), avec `Closes #numéro` dans la description.

## Convention de l'API

- Préfixe : `/api/`
- Format : JSON
- Authentification : en-tête `Authorization: Bearer <token>`
- Endpoints principaux (à valider ensemble avant de coder) :

| Ressource | Endpoint |
|---|---|
| Inscription / connexion | `/api/auth/register/`, `/api/auth/login/`, `/api/auth/refresh/` |
| Profil | `/api/users/me/` |
| Parcelles | `/api/parcelles/` |
| Animaux | `/api/animaux/` |
| Suivi sanitaire | `/api/suivis-sanitaires/` |
| Alertes et météo | `/api/alertes/`, `/api/meteo/` |
| Annonces | `/api/annonces/` |
| Administration | `/api/admin/users/`, `/api/admin/stats/` |

Le contrat complet sera généré automatiquement par drf-spectacular et fait foi pour le web et le mobile.

## Planning

1. Analyse et conception
2. Mise en place technique
3. Développement des modules (cultures, élevage, alertes météo, marché)
4. Intégration et tests
5. Finalisation (documentation, soutenance, déploiement de démonstration)
