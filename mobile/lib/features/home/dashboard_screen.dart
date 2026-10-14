import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/notification_service.dart';
import '../auth/auth_provider.dart';

/// Accueil de l'utilisateur connecté : raccourcis vers les modules.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const _modules = [
    (
      icon: Icons.grass,
      titre: 'Cultures',
      description: 'Parcelles, étapes et calendrier des récoltes',
      route: '/cultures',
    ),
    (
      icon: Icons.pets,
      titre: 'Élevage',
      description: 'Animaux, vaccinations et traitements',
      route: '/elevage',
    ),
    (
      icon: Icons.cloud,
      titre: 'Météo et alertes',
      description: 'Prévisions locales et risques climatiques',
      route: '/meteo',
    ),
    (
      icon: Icons.storefront,
      titre: 'Marché',
      description: 'Annonces de produits agricoles et d\'élevage',
      route: '/marche',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart AgroTech'),
        actions: [
          IconButton(
            key: const Key('logout'),
            tooltip: 'Se déconnecter',
            icon: const Icon(Icons.logout),
            onPressed: auth.logout,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Bonjour ${user?.prenom ?? ''}',
            style: theme.textTheme.headlineSmall,
          ),
          if (user != null)
            Text(user.role.label, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          for (final module in _modules)
            Card(
              child: ListTile(
                leading: Icon(module.icon, color: theme.colorScheme.primary),
                title: Text(module.titre),
                subtitle: Text(module.description),
                trailing: module.route == '/meteo'
                    ? ValueListenableBuilder<int>(
                        valueListenable: context.read<RappelService>().nonLues,
                        builder: (context, nonLues, child) => Badge(
                          isLabelVisible: nonLues > 0,
                          label: Text('$nonLues'),
                          child: child,
                        ),
                        child: const Icon(Icons.chevron_right),
                      )
                    : const Icon(Icons.chevron_right),
                onTap: () => context.go(module.route),
              ),
            ),
        ],
      ),
    );
  }
}
