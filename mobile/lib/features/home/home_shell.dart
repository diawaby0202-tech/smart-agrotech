import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
      _shell.goBranch(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_menuOuvert && _shell.currentIndex == 0,
      onPopInvokedWithResult: _retour,
      child: Scaffold(
        key: menuKey,
        drawer: MenuPrincipal(navigationShell: _shell),
        onDrawerChanged: (ouvert) => setState(() => _menuOuvert = ouvert),
        body: _shell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _shell.currentIndex,
          onDestinationSelected: (index) => _shell.goBranch(
            index,
            // Retaper sur l'onglet courant ramène à sa racine.
            initialLocation: index == _shell.currentIndex,
          ),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Accueil',
            ),
            NavigationDestination(
              icon: Icon(Icons.grass_outlined),
              selectedIcon: Icon(Icons.grass),
              label: 'Cultures',
            ),
            NavigationDestination(
              icon: Icon(Icons.pets_outlined),
              selectedIcon: Icon(Icons.pets),
              label: 'Élevage',
            ),
            NavigationDestination(
              icon: Icon(Icons.cloud_outlined),
              selectedIcon: Icon(Icons.cloud),
              label: 'Météo',
            ),
            NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront),
              label: 'Marché',
            ),
          ],
        ),
      ),
    );
  }
}
