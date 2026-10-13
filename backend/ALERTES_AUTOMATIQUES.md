# Alertes automatiques

Les alertes (météo, vaccination, rappels de culture) sont créées par la commande :

    python manage.py generer_alertes

Elle ne crée jamais deux fois la même alerte le même jour. Les applications web et mobile
peuvent aussi la déclencher pour l'utilisateur connecté : `POST /api/alertes/generer/`.

## La lancer chaque jour automatiquement

Sur un serveur Linux (cron), tous les jours à 6 h :

    0 6 * * * cd /chemin/backend && /chemin/venv/bin/python manage.py generer_alertes

Sous Windows : Planificateur de tâches, action « Démarrer un programme »,
programme `venv\Scripts\python.exe`, arguments `manage.py generer_alertes`,
dossier de départ `backend`.
