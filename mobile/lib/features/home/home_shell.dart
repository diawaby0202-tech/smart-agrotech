import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/auth_provider.dart';
import '../auth/user.dart';
import 'menu.dart';

/// Coquille de l'app connectée : menu latéral, barre de navigation du bas avec
/// un onglet par module. Chaque onglet garde son propre historique.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  bool _menuOuvert = false;

  StatefulNavigationShell get _shell => widget.navigationShell;

  /// Bouton Retour d'Android : ferme d'abord le menu, puis revient à
  /// l'Accueil ; il ne quitte l'app que depuis l'Accueil.
  void _retour(bool dejaFait, Object? _) {
    if (dejaFait) return;
    if (_menuOuvert) {
      menuKey.currentState?.closeDrawer();
    } else if (_shell.currentIndex != 0) {
      final role = context.read<AuthProvider>().user?.role;
      final roleLimite = role == UserRole.acheteur;
      final brancheAccueil = roleLimite && _shell.currentIndex == 4 ? 3 : 0;
      _shell.goBranch(brancheAccueil);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().user?.role;
    final destinations = role == UserRole.acheteur
        ? const [
            (
              branche: 3,
              icone: Icons.cloud_outlined,
              selectionnee: Icons.cloud,
              label: 'Alertes',
            ),
            (
              branche: 4,
              icone: Icons.storefront_outlined,
              selectionnee: Icons.storefront,
              label: 'Marché',
            ),
          ]
        : const [
            (
              branche: 0,
              icone: Icons.home_outlined,
              selectionnee: Icons.home,
              label: 'Accueil',
            ),
            (
              branche: 1,
              icone: Icons.grass_outlined,
              selectionnee: Icons.grass,
              label: 'Cultures',
            ),
            (
              branche: 2,
              icone: Icons.pets_outlined,
              selectionnee: Icons.pets,
              label: 'Élevage',
            ),
            (
              branche: 3,
              icone: Icons.cloud_outlined,
              selectionnee: Icons.cloud,
              label: 'Météo',
            ),
            (
              branche: 4,
              icone: Icons.storefront_outlined,
              selectionnee: Icons.storefront,
              label: 'Marché',
            ),
          ];
    final selectedIndex = destinations.indexWhere(
      (destination) => destination.branche == _shell.currentIndex,
    );

    return PopScope(
      canPop: !_menuOuvert && _shell.currentIndex == 0,
      onPopInvokedWithResult: _retour,
      child: Scaffold(
        key: menuKey,
        drawer: MenuPrincipal(navigationShell: _shell),
        onDrawerChanged: (ouvert) => setState(() => _menuOuvert = ouvert),
        body: _shell,
        bottomNavigationBar: selectedIndex < 0
            ? null
            : NavigationBar(
                selectedIndex: selectedIndex,
                onDestinationSelected: (index) {
                  final branch = destinations[index].branche;
                  _shell.goBranch(
                    branch,
                    initialLocation: branch == _shell.currentIndex,
                  );
                },
                destinations: [
                  for (final destination in destinations)
                    NavigationDestination(
                      icon: Icon(destination.icone),
                      selectedIcon: Icon(destination.selectionnee),
                      label: destination.label,
                    ),
                ],
              ),
      ),
    );
  }
}
