import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/design.dart';
import '../../core/theme.dart';
import '../auth/auth_provider.dart';
import '../auth/profil_screen.dart';
import '../auth/user.dart';

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
    final role = context.watch<AuthProvider>().user?.role;
    final roleLimite = role == UserRole.acheteur;
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
        if (!roleLimite)
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

/// Logo et nom « Smart AgroTech ».
class NomMarque extends StatelessWidget {
  const NomMarque({super.key, this.taille = 32, this.clair = false});

  final double taille;

  /// Texte clair, sur fond vert foncé.
  final bool clair;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleLarge?.copyWith(
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
            child: Text('Smart AgroTech', style: style),
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
    (branche: 0, icone: Icons.home_outlined, label: 'Accueil'),
    (branche: 1, icone: Icons.grass, label: 'Cultures'),
    (branche: 2, icone: Icons.pets_outlined, label: 'Élevage'),
    (branche: 3, icone: Icons.cloud_outlined, label: 'Alertes météo'),
    (branche: 4, icone: Icons.storefront_outlined, label: 'Marché'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final roleLimite = user?.role == UserRole.acheteur;
    final ongletsVisibles = onglets.where(
      (onglet) => !roleLimite || onglet.branche >= 3,
    );

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
              color: Couleurs.vert800,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const NomMarque(taille: 36, clair: true),
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
                      '${user.role.label}\n${user.email}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            for (final onglet in ongletsVisibles)
              _LienMenu(
                key: Key('menu-onglet-${onglet.branche}'),
                icone: onglet.icone,
                label: onglet.label,
                actif: navigationShell.currentIndex == onglet.branche,
                onTap: () =>
                    fermerPuis(() => navigationShell.goBranch(onglet.branche)),
              ),
            const Divider(indent: 16, endIndent: 16),
            if (!roleLimite)
              _LienMenu(
                key: const Key('menu-tableau-de-bord'),
                icone: Icons.space_dashboard_outlined,
                label: 'Tableau de bord',
                onTap: () => fermerPuis(() => context.push('/tableau-de-bord')),
              ),
            if (!roleLimite)
              _LienMenu(
                key: const Key('menu-profil'),
                icone: Icons.person_outline,
                label: 'Mon profil',
                onTap: () => fermerPuis(() => ouvrirProfil(context)),
              ),
            const Divider(indent: 16, endIndent: 16),
            _LienMenu(
              key: const Key('menu-deconnexion'),
              icone: Icons.logout,
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
    required this.icone,
    required this.label,
    required this.onTap,
    this.actif = false,
    this.couleur,
  });

  final IconData icone;
  final String label;
  final VoidCallback onTap;
  final bool actif;
  final Color? couleur;

  @override
  Widget build(BuildContext context) {
    final teinte = couleur ?? (actif ? Couleurs.vert700 : Couleurs.encre);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
      child: ListTile(
        onTap: onTap,
        selected: actif,
        selectedTileColor: Couleurs.vert50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        leading: Icon(
          icone,
          color: couleur ?? (actif ? Couleurs.vert700 : Couleurs.ardoise500),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: actif ? FontWeight.w700 : FontWeight.w600,
            color: teinte,
          ),
        ),
      ),
    );
  }
}
