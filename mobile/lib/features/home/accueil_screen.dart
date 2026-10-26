import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/design.dart';
import '../../core/notification_service.dart';
import '../../core/theme.dart';
import 'menu.dart';

/// Page d'accueil, sur le modèle de la page d'accueil du site : photo
/// d'en-tête, chiffres clés, les quatre modules en images, les publics visés
/// et un appel à l'action.
class AccueilScreen extends StatelessWidget {
  const AccueilScreen({super.key});

  static const _modules = [
    (
      icone: '🌾',
      titre: 'Cultures & récoltes',
      texte:
          'Enregistrez vos parcelles, suivez leur évolution (semis, '
          'croissance, récolte) et anticipez vos récoltes.',
      route: '/cultures',
      image: 'assets/img/culture-arachide.jpg',
    ),
    (
      icone: '🐄',
      titre: 'Élevage',
      texte:
          'Tenez à jour la fiche de chaque animal, consignez les soins et '
          'recevez des rappels de vaccination.',
      route: '/elevage',
      image: 'assets/img/elevage.jpg',
    ),
    (
      icone: '⛅',
      titre: 'Alertes météo',
      texte:
          'Consultez les prévisions de votre zone et soyez alerté des risques '
          'climatiques en amont.',
      route: '/meteo',
      image: 'assets/img/meteo.jpg',
    ),
    (
      icone: '🛒',
      titre: 'Marché agricole',
      texte:
          'Publiez vos annonces, trouvez des produits locaux et contactez '
          'directement les vendeurs.',
      route: '/marche',
      image: 'assets/img/marche.jpg',
    ),
  ];

  static const _statistiques = [
    (valeur: '4', libelle: 'Modules intégrés'),
    (valeur: '3', libelle: 'Profils utilisateurs'),
    (valeur: '24/7', libelle: 'Accès web & mobile'),
    (valeur: '100%', libelle: 'Adapté au terrain'),
  ];

  static const _publics = [
    (
      icone: '🧑‍🌾',
      titre: 'Agriculteurs & éleveurs',
      texte:
          'Suivi des parcelles et du bétail, rappels d’intervention et '
          'publication d’annonces.',
      image: 'assets/img/culture-mil.jpg',
    ),
    (
      icone: '🛒',
      titre: 'Acheteurs',
      texte:
          'Recherche de produits locaux et mise en relation directe avec les '
          'producteurs.',
      image: 'assets/img/marche-tomates.jpg',
    ),
    (
      icone: '🏛️',
      titre: 'Structures d’appui',
      texte:
          'ONG et services techniques : supervision et suivi des activités de '
          'leur zone.',
      image: 'assets/img/cultures.jpg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BarreMarque(),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const _Hero(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _BandeauStats(statistiques: _statistiques),
                const SizedBox(height: 28),
                const _TitreSection(
                  titre: 'Une plateforme, quatre modules',
                  texte:
                      'Tout ce dont vous avez besoin pour piloter votre '
                      'exploitation agricole au quotidien, réuni dans une '
                      'interface simple et accessible.',
                ),
                const SizedBox(height: 16),
                for (final module in _modules)
                  _CarteModule(
                    icone: module.icone,
                    titre: module.titre,
                    texte: module.texte,
                    image: module.image,
                    badgeAlertes: module.route == '/meteo',
                    onTap: () => context.go(module.route),
                  ),
                const SizedBox(height: 16),
                const _TitreSection(
                  titre: 'Pour qui ?',
                  texte:
                      'Une solution pensée pour toute la chaîne agricole '
                      'sénégalaise, du producteur à l’acheteur.',
                ),
                const SizedBox(height: 16),
                // Hauteur calculée d'après la carte la plus haute : le texte
                // ne déborde pas, même avec une grande taille de police.
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final (index, public) in _publics.indexed) ...[
                          if (index > 0) const SizedBox(width: 12),
                          _CartePublic(
                            icone: public.icone,
                            titre: public.titre,
                            texte: public.texte,
                            image: public.image,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const _AppelAction(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Grande photo avec le titre de la plateforme, comme l'en-tête du site.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 360,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ImageSource('assets/img/hero.jpg'),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x330F2E1C), Color(0xE60F2E1C)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Etiquette(
                  '🌱 La plateforme de l’agriculture sénégalaise',
                  fond: Colors.white,
                  couleur: Couleurs.vert700,
                ),
                const SizedBox(height: 12),
                Text.rich(
                  const TextSpan(
                    children: [
                      TextSpan(
                        text:
                            'Gérez vos cultures, votre bétail et vos ventes, ',
                      ),
                      TextSpan(
                        text: 'depuis un seul endroit',
                        style: TextStyle(color: Couleurs.vert400),
                      ),
                      TextSpan(text: '.'),
                    ],
                  ),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Suivez vos activités, anticipez les risques climatiques et '
                  'accédez à un marché en ligne local.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: ombreCarte,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🌾', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Suivi en temps réel',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Couleurs.encre,
                            ),
                          ),
                          Text(
                            'Parcelles, bétail, météo & marché',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Couleurs.ardoise500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BandeauStats extends StatelessWidget {
  const _BandeauStats({required this.statistiques});

  final List<({String valeur, String libelle})> statistiques;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        gradient: Couleurs.degradeMarque,
        borderRadius: BorderRadius.circular(20),
        boxShadow: ombreCarte,
      ),
      child: Row(
        children: [
          for (final stat in statistiques)
            Expanded(
              child: Column(
                children: [
                  Text(
                    stat.valeur,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stat.libelle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TitreSection extends StatelessWidget {
  const _TitreSection({required this.titre, required this.texte});

  final String titre;
  final String texte;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titre, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(
          texte,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Couleurs.ardoise500,
          ),
        ),
      ],
    );
  }
}

/// Carte d'un module : photo, emoji, description et lien « Découvrir ».
class _CarteModule extends StatelessWidget {
  const _CarteModule({
    required this.icone,
    required this.titre,
    required this.texte,
    required this.image,
    required this.badgeAlertes,
    required this.onTap,
  });

  final String icone;
  final String titre;
  final String texte;
  final String image;

  /// Affiche le nombre d'alertes non lues sur l'emoji.
  final bool badgeAlertes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget pastille = Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: ombreCarte,
      ),
      child: Text(icone, style: const TextStyle(fontSize: 24)),
    );
    if (badgeAlertes) {
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

    return CartePhoto(
      image: image,
      onTap: onTap,
      badgeBas: pastille,
      children: [
        Text(titre, style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          texte,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Couleurs.ardoise500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Découvrir →',
          style: theme.textTheme.labelLarge?.copyWith(
            color: Couleurs.vert600,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _CartePublic extends StatelessWidget {
  const _CartePublic({
    required this.icone,
    required this.titre,
    required this.texte,
    required this.image,
  });

  final String icone;
  final String titre;
  final String texte;
  final String image;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 240,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 140,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ImageSource(image),
                  Positioned(
                    left: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(icone, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titre,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Couleurs.encre,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    texte,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Couleurs.ardoise500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bloc final « Prêt à moderniser votre exploitation ? ».
class _AppelAction extends StatelessWidget {
  const _AppelAction();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: Couleurs.degradeMarque,
        borderRadius: BorderRadius.circular(24),
        boxShadow: ombreCarte,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Prêt à moderniser votre exploitation ?',
            style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Accédez à tous vos outils de suivi agricole, où que vous soyez, '
            'depuis votre téléphone ou votre ordinateur.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('accueil-marche'),
            style: FilledButton.styleFrom(
              backgroundColor: Couleurs.or500,
              foregroundColor: Colors.white,
            ),
            onPressed: () => context.go('/marche'),
            child: const Text('Explorer le marché'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white),
              minimumSize: const Size.fromHeight(50),
            ),
            onPressed: () => context.push('/tableau-de-bord'),
            child: const Text('Mon tableau de bord'),
          ),
        ],
      ),
    );
  }
}
