import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/design.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../alertes/alertes_repository.dart';
import '../auth/auth_provider.dart';
import '../auth/profil_screen.dart';
import '../auth/user.dart';
import '../cultures/parcelle_repository.dart';
import '../elevage/elevage_repository.dart';
import '../marche/annonce.dart';
import '../marche/annonce_repository.dart';
import 'menu.dart';

typedef _DashboardCounts = ({
  int? parcelles,
  int? tetes,
  int alertes,
  int annonces,
});

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _countsKey = GlobalKey<AsyncViewState<_DashboardCounts>>();

  static String _salutation() {
    final heure = DateTime.now().hour;
    if (heure < 12) return 'Bonjour';
    if (heure < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  Future<_DashboardCounts> _chargerCompteurs() async {
    final role = context.read<AuthProvider>().user?.role;
    final alertesFuture = context.read<AlertesRepository>().alertes().then(
      (items) => items.where((alerte) => !alerte.lue).length,
    );
    final annoncesFuture = context
        .read<AnnonceRepository>()
        .list(const FiltreAnnonces())
        .then((items) => items.length);

    if (role == UserRole.acheteur) {
      final counts = await Future.wait<int>([alertesFuture, annoncesFuture]);
      return (
        parcelles: null,
        tetes: null,
        alertes: counts[0],
        annonces: counts[1],
      );
    }

    final counts = await Future.wait<int>([
      context.read<ParcelleRepository>().list().then((items) => items.length),
      context.read<ElevageRepository>().animaux().then(
        (items) =>
            items.fold<int>(0, (total, animal) => total + animal.effectif),
      ),
      alertesFuture,
      annoncesFuture,
    ]);
    return (
      parcelles: counts[0],
      tetes: counts[1],
      alertes: counts[2],
      annonces: counts[3],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final role = user?.role ?? UserRole.producteur;
    final producteur = role == UserRole.producteur;
    final accesComplet = role != UserRole.acheteur;
    final theme = Theme.of(context);
    final prenom = user?.prenom ?? '';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        leading: accesComplet
            ? IconButton(
                key: const Key('dashboard-accueil'),
                tooltip: 'Accueil',
                icon: const Icon(Icons.home_outlined),
                onPressed: () => context.go('/'),
              )
            : null,
        title: const NomMarque(),
        actions: [
          if (accesComplet)
            IconButton(
              key: const Key('profil'),
              tooltip: 'Mon profil',
              icon: const Icon(Icons.account_circle_outlined),
              onPressed: () => _ouvrirProfil(context),
            ),
          IconButton(
            key: const Key('logout'),
            tooltip: 'Déconnexion',
            icon: const Icon(Icons.logout),
            onPressed: auth.logout,
          ),
        ],
      ),
      body: AsyncView<_DashboardCounts>(
        key: _countsKey,
        load: _chargerCompteurs,
        builder: (context, counts) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Etiquette(
                role.label,
                fond: Couleurs.vert100,
                couleur: Couleurs.vert700,
              ),
            ),
            const SizedBox(height: 12),
            BandeauModule(
              titre: '${_salutation()}${prenom.isEmpty ? '' : ', $prenom'}',
              texte: switch (role) {
                UserRole.producteur =>
                  'Vos parcelles, votre élevage et vos ventes, au même endroit.',
                UserRole.admin =>
                  'Accédez aux cultures, à l’élevage, aux alertes et au marché.',
                UserRole.acheteur =>
                  'Retrouvez les produits du marché et les alertes de votre zone.',
              },
            ),
            const SizedBox(height: 24),
            Text(
              producteur
                  ? 'Mon activité'
                  : role == UserRole.admin
                  ? 'Gestion de l’application'
                  : 'Mon espace',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Couleurs.vert900,
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 600 ? 4 : 2;
                final modules = accesComplet
                    ? [
                        _ModuleDashboard(
                          keyName: 'dashboard-cultures',
                          icone: Icons.grass,
                          titre: producteur ? 'Mes parcelles' : 'Parcelles',
                          valeur: '${counts.parcelles}',
                          detail: _pluriel(counts.parcelles ?? 0, 'parcelle'),
                          route: '/cultures',
                          couleur: Couleurs.vert700,
                        ),
                        _ModuleDashboard(
                          keyName: 'dashboard-elevage',
                          icone: Icons.pets_outlined,
                          titre: producteur ? 'Mon élevage' : 'Élevage',
                          valeur: '${counts.tetes}',
                          detail: _pluriel(counts.tetes ?? 0, 'tête'),
                          route: '/elevage',
                          couleur: Couleurs.or600,
                        ),
                        _ModuleDashboard(
                          keyName: 'dashboard-meteo',
                          icone: Icons.cloud_outlined,
                          titre: 'Météo & alertes',
                          valeur: '${counts.alertes}',
                          detail: _pluriel(counts.alertes, 'alerte'),
                          route: '/meteo',
                          couleur: Couleurs.ciel700,
                        ),
                        _ModuleDashboard(
                          keyName: 'dashboard-marche',
                          icone: Icons.storefront_outlined,
                          titre: 'Marché',
                          valeur: '${counts.annonces}',
                          detail: _pluriel(counts.annonces, 'annonce'),
                          route: '/marche',
                          couleur: Couleurs.vert600,
                        ),
                      ]
                    : [
                        _ModuleDashboard(
                          keyName: 'dashboard-meteo',
                          icone: Icons.notifications_active_outlined,
                          titre: 'Alertes',
                          valeur: '${counts.alertes}',
                          detail: _pluriel(counts.alertes, 'alerte'),
                          route: '/meteo',
                          couleur: Couleurs.ciel700,
                        ),
                        _ModuleDashboard(
                          keyName: 'dashboard-marche',
                          icone: Icons.storefront_outlined,
                          titre: 'Marché',
                          valeur: '${counts.annonces}',
                          detail: _pluriel(counts.annonces, 'annonce'),
                          route: '/marche',
                          couleur: Couleurs.vert600,
                        ),
                      ];

                return GridView.count(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 4,
                  childAspectRatio: columns == 2 ? 1.18 : 1.05,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (final module in modules)
                      _CarteCompteur(module: module),
                  ],
                );
              },
            ),
            if (role == UserRole.admin) ...[
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  key: const Key('dashboard-moderation-annonces'),
                  leading: const CircleAvatar(
                    backgroundColor: Couleurs.vert100,
                    foregroundColor: Couleurs.vert700,
                    child: Icon(Icons.fact_check_outlined),
                  ),
                  title: const Text('Modération des annonces'),
                  subtitle: const Text(
                    'Approuver, masquer ou restaurer une annonce',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/admin/annonces'),
                ),
              ),
            ],
            if (accesComplet) ...[
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  key: const Key('dashboard-profil'),
                  leading: const CircleAvatar(
                    backgroundColor: Couleurs.vert100,
                    foregroundColor: Couleurs.vert700,
                    child: Icon(Icons.person_outline),
                  ),
                  title: const Text('Mon profil'),
                  subtitle: const Text(
                    'Mes coordonnées et informations de compte',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _ouvrirProfil(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _pluriel(int nombre, String nom) =>
      '$nombre $nom${nombre == 1 ? '' : 's'}';

  static void _ouvrirProfil(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const ProfilScreen()));
}

class _ModuleDashboard {
  const _ModuleDashboard({
    required this.keyName,
    required this.icone,
    required this.titre,
    required this.valeur,
    required this.detail,
    required this.route,
    required this.couleur,
  });

  final String keyName;
  final IconData icone;
  final String titre;
  final String valeur;
  final String detail;
  final String route;
  final Color couleur;
}

class _CarteCompteur extends StatelessWidget {
  const _CarteCompteur({required this.module});

  final _ModuleDashboard module;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      key: Key(module.keyName),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(module.route),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(module.icone, color: module.couleur, size: 25),
              const Spacer(),
              Text(
                module.valeur,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Couleurs.vert900,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(module.titre, style: theme.textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(
                module.detail,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Couleurs.ardoise500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
