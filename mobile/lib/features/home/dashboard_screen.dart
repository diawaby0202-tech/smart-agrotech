import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/design.dart';
import '../../core/notification_service.dart';
import '../../core/theme.dart';
import '../auth/auth_provider.dart';
import '../auth/user.dart';

/// Tableau de bord, comme la page « Tableau de bord » du site.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const _modulesProducteur = [
    (
      icone: '🌾',
      titre: 'Mes parcelles',
      texte: 'Suivre mes cultures et mes récoltes',
      route: '/cultures',
    ),
    (
      icone: '🐄',
      titre: 'Mon élevage',
      texte: 'Gérer mes animaux et leur santé',
      route: '/elevage',
    ),
    (
      icone: '⛅',
      titre: 'Alertes météo',
      texte: 'Prévisions et risques de ma zone',
      route: '/meteo',
    ),
    (
      icone: '🛒',
      titre: 'Marché',
      texte: 'Publier et consulter des annonces',
      route: '/marche',
    ),
  ];

  static const _modulesAcheteur = [
    (
      icone: '🛒',
      titre: 'Marché',
      texte: 'Rechercher des produits locaux',
      route: '/marche',
    ),
    (
      icone: '⛅',
      titre: 'Alertes météo',
      texte: 'Suivre la météo de ma région',
      route: '/meteo',
    ),
  ];

  static String _salutation() {
    final heure = DateTime.now().hour;
    if (heure < 12) return 'Bonjour';
    if (heure < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final theme = Theme.of(context);
    final modules = user?.role == UserRole.acheteur
        ? _modulesAcheteur
        : _modulesProducteur;
    final prenom = user?.prenom ?? '';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            const LogoMarque(taille: 34),
            const SizedBox(width: 10),
            Text.rich(
              const TextSpan(
                children: [
                  TextSpan(text: 'Smart'),
                  TextSpan(
                    text: 'AgroTech',
                    style: TextStyle(color: Couleurs.vert600),
                  ),
                ],
              ),
              style: theme.textTheme.titleLarge,
            ),
          ],
        ),
        actions: [
          IconButton(
            key: const Key('logout'),
            tooltip: 'Déconnexion',
            icon: const Icon(Icons.logout),
            onPressed: auth.logout,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (user != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Etiquette(
                user.role.label,
                fond: Couleurs.vert100,
                couleur: Couleurs.vert700,
              ),
            ),
          const SizedBox(height: 12),
          Text(
            '${_salutation()}${prenom.isEmpty ? '' : ', $prenom'} 👋',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Voici un aperçu de votre espace Smart AgroTech.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Couleurs.ardoise500,
            ),
          ),
          const SizedBox(height: 20),
          for (final module in modules)
            _CarteModule(
              icone: module.icone,
              titre: module.titre,
              texte: module.texte,
              badge: module.route == '/meteo',
              onTap: () => context.go(module.route),
            ),
        ],
      ),
    );
  }
}

class _CarteModule extends StatelessWidget {
  const _CarteModule({
    required this.icone,
    required this.titre,
    required this.texte,
    required this.badge,
    required this.onTap,
  });

  final String icone;
  final String titre;
  final String texte;

  /// Affiche le nombre d'alertes non lues.
  final bool badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget pastille = Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Couleurs.vert50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(icone, style: const TextStyle(fontSize: 26)),
    );
    if (badge) {
      pastille = ValueListenableBuilder<int>(
        valueListenable: context.read<RappelService>().nonLues,
        builder: (context, nonLues, child) => Badge(
          isLabelVisible: nonLues > 0,
          label: Text('$nonLues'),
          child: child,
        ),
        child: pastille,
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              pastille,
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titre, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      texte,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Couleurs.ardoise500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Accéder →',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Couleurs.vert600,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
