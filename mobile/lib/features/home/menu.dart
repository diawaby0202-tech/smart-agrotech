import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/design.dart';
import '../../core/theme.dart';
import '../auth/auth_provider.dart';
import '../auth/profil_screen.dart';

/// Clé de l'écran principal, pour ouvrir le menu depuis n'importe quel onglet.
final menuKey = GlobalKey<ScaffoldState>();

void ouvrirProfil(BuildContext context) => Navigator.of(
  context,
  rootNavigator: true,
).push(MaterialPageRoute<void>(builder: (_) => const ProfilScreen()));

/// Barre du haut de chaque onglet, comme l'en-tête du site : bouton menu,
/// logo SmartAgroTech et accès au profil.
class BarreMarque extends StatelessWidget implements PreferredSizeWidget {
  const BarreMarque({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: 0,
      leading: IconButton(
        key: const Key('menu'),
        tooltip: 'Ouvrir le menu',
        icon: const Icon(Icons.menu),
        onPressed: () => menuKey.currentState?.openDrawer(),
      ),
      title: const NomMarque(),
      actions: [
        IconButton(
          key: const Key('profil'),
          tooltip: 'Mon profil',
          icon: const Icon(Icons.account_circle_outlined),
          onPressed: () => ouvrirProfil(context),
        ),
      ],
    );
  }
}

/// Logo et nom « SmartAgroTech », comme l'en-tête du site.
class NomMarque extends StatelessWidget {
  const NomMarque({super.key, this.taille = 34, this.clair = false});

  final double taille;

  /// Texte blanc, sur fond vert.
  final bool clair;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.4,
      color: clair ? Colors.white : Couleurs.encre,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LogoMarque(taille: taille),
        const SizedBox(width: 10),
        // Réduit le texte plutôt que de déborder sur les petits écrans.
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Smart', style: style),
                clair
                    ? Text(
                        'AgroTech',
                        style: style?.copyWith(color: Couleurs.vert100),
                      )
                    : TexteDegrade('AgroTech', style: style),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Menu latéral, avec les mêmes liens que l'en-tête du site.
class MenuPrincipal extends StatelessWidget {
  const MenuPrincipal({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const onglets = [
    (emoji: '🏠', label: 'Accueil'),
    (emoji: '🌾', label: 'Cultures'),
    (emoji: '🐄', label: 'Élevage'),
    (emoji: '⛅', label: 'Alertes météo'),
    (emoji: '🛒', label: 'Marché'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    void fermerPuis(VoidCallback action) {
      Navigator.of(context).pop();
      action();
    }

    return Drawer(
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.of(context).padding.top + 20,
                20,
                20,
              ),
              decoration: const BoxDecoration(gradient: Couleurs.degradeMarque),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const NomMarque(taille: 40, clair: true),
                  const SizedBox(height: 16),
                  if (user != null) ...[
                    Text(
                      user.nomComplet,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${user.role.label} · ${user.email}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            for (final (index, onglet) in onglets.indexed)
              _LienMenu(
                key: Key('menu-onglet-$index'),
                emoji: onglet.emoji,
                label: onglet.label,
                actif: navigationShell.currentIndex == index,
                onTap: () => fermerPuis(() => navigationShell.goBranch(index)),
              ),
            const Divider(indent: 16, endIndent: 16),
            _LienMenu(
              key: const Key('menu-tableau-de-bord'),
              emoji: '📊',
              label: 'Tableau de bord',
              onTap: () => fermerPuis(() => context.push('/tableau-de-bord')),
            ),
            _LienMenu(
              key: const Key('menu-profil'),
              emoji: '👤',
              label: 'Mon profil',
              onTap: () => fermerPuis(() => ouvrirProfil(context)),
            ),
            const Divider(indent: 16, endIndent: 16),
            _LienMenu(
              key: const Key('menu-deconnexion'),
              emoji: '🚪',
              label: 'Déconnexion',
              couleur: Couleurs.danger,
              onTap: () => fermerPuis(auth.logout),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _LienMenu extends StatelessWidget {
  const _LienMenu({
    super.key,
    required this.emoji,
    required this.label,
    required this.onTap,
    this.actif = false,
    this.couleur,
  });

  final String emoji;
  final String label;
  final VoidCallback onTap;
  final bool actif;
  final Color? couleur;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        onTap: onTap,
        selected: actif,
        selectedTileColor: Couleurs.vert100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Text(emoji, style: const TextStyle(fontSize: 22)),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: couleur ?? (actif ? Couleurs.vert700 : Couleurs.encre),
          ),
        ),
      ),
    );
  }
}
