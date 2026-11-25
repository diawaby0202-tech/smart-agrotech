import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/design.dart';
import '../../core/notification_service.dart';
import '../../core/theme.dart';
import 'menu.dart';

/// Page d'accueil : grande photo d'en-tête, les quatre modules en images et
/// les publics visés.
class AccueilScreen extends StatelessWidget {
  const AccueilScreen({super.key});

  static const _modules = [
    (
      titre: 'Mes cultures',
      texte: 'Parcelles, semis, récoltes',
      route: '/cultures',
      image: 'assets/img/culture-pasteque.jpg',
    ),
    (
      titre: 'Mon élevage',
      texte: 'Fiches des bêtes et soins',
      route: '/elevage',
      image: 'assets/img/elevage-volaille.jpg',
    ),
    (
      titre: 'La météo',
      texte: 'Prévisions et alertes',
      route: '/meteo',
      image: 'assets/img/meteo-arc-en-ciel.jpg',
    ),
    (
      titre: 'Le marché',
      texte: 'Acheter et vendre',
      route: '/marche',
      image: 'assets/img/culture-carotte.jpg',
    ),
  ];

  static const _conseils = [
    (
      titre: 'Conseils pour les cultures',
      texte:
          'Choisissez des semences adaptées à votre zone et préparez le sol '
          'avant les premières pluies.',
      image: 'assets/img/culture-mais-utilisateur.jpg',
      action: 'Suivre mes cultures',
      route: '/cultures',
    ),
    (
      titre: 'Conseils pour l’élevage',
      texte:
          'De l’eau propre, une alimentation régulière et un suivi sanitaire '
          'aident à préserver la santé du troupeau.',
      image: 'assets/img/elevage-volaille.jpg',
      action: 'Suivre mon élevage',
      route: '/elevage',
    ),
    (
      titre: 'Conseils météo',
      texte:
          'Consultez les prévisions locales avant les semis et les travaux '
          'aux champs, puis tenez compte des alertes.',
      image: 'assets/img/meteo-arc-en-ciel.jpg',
      action: 'Voir la météo',
      route: '/meteo',
    ),
  ];

  static const _publics = [
    (
      titre: 'Agriculteurs et éleveurs',
      texte:
          'Suivre ses parcelles et son troupeau, ne plus oublier un vaccin, '
          'vendre sa récolte.',
      image: 'assets/img/agriculteur-eleveur.jpg',
    ),
    (
      titre: 'Acheteurs',
      texte:
          'Trouver des produits locaux et appeler directement le producteur.',
      image: 'assets/img/acheteur.jpg',
    ),
    (
      titre: 'Structures d’appui',
      texte: 'ONG et services techniques : suivre les activités de leur zone.',
      image: 'assets/img/structures-appui.jpg',
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
                const _TitreSection('Par où commencer ?'),
                const SizedBox(height: 12),
                for (var i = 0; i < _modules.length; i += 2) ...[
                  if (i > 0) const SizedBox(height: 12),
                  Row(
                    children: [
                      for (final (j, module)
                          in _modules.sublist(i, i + 2).indexed) ...[
                        if (j > 0) const SizedBox(width: 12),
                        Expanded(
                          child: _TuileModule(
                            titre: module.titre,
                            texte: module.texte,
                            image: module.image,
                            badgeAlertes: module.route == '/meteo',
                            onTap: () => context.go(module.route),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                const SizedBox(height: 32),
                const _TitreSection(
                  'Conseils du terrain',
                  texte:
                      'Quelques repères pratiques pour vos cultures, votre '
                      'élevage et vos activités.',
                ),
                const SizedBox(height: 12),
                for (final conseil in _conseils) ...[
                  _CarteConseil(
                    titre: conseil.titre,
                    texte: conseil.texte,
                    image: conseil.image,
                    action: conseil.action,
                    onTap: () => context.go(conseil.route),
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 32),
                const _TitreSection(
                  'Pour qui ?',
                  texte:
                      'Du producteur à l’acheteur, chacun y trouve son compte.',
                ),
                const SizedBox(height: 12),
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
                            titre: public.titre,
                            texte: public.texte,
                            image: public.image,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  key: const Key('accueil-tableau-de-bord'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  onPressed: () => context.push('/tableau-de-bord'),
                  icon: const Icon(Icons.space_dashboard_outlined),
                  label: const Text('Voir mon tableau de bord'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Affiche agricole mise en avant, avec le texte et l'action sur la photo.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
          child: SizedBox(
            key: const Key('accueil-hero'),
            height: 360,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ImageSource('assets/img/hero.jpg', fit: BoxFit.cover),
                const ColoredBox(color: Color(0x59000000)),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x0014281B), Color(0xE614281B)],
                      stops: [0.25, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Vos champs, vos bêtes et vos ventes, au même endroit.',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Notez vos semis, suivez les soins du troupeau, '
                        'surveillez la pluie et vendez au marché.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                      ),
                      const SizedBox(height: 14),
                      FilledButton(
                        key: const Key('accueil-cultures'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Couleurs.or500,
                          foregroundColor: Couleurs.vert900,
                        ),
                        onPressed: () => context.go('/cultures'),
                        child: const Text('Voir mes parcelles'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TitreSection extends StatelessWidget {
  const _TitreSection(this.titre, {this.texte});

  final String titre;
  final String? texte;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titre, style: theme.textTheme.headlineSmall),
        if (texte != null) ...[
          const SizedBox(height: 4),
          Text(
            texte!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Couleurs.ardoise500,
            ),
          ),
        ],
      ],
    );
  }
}

/// Tuile photo d'un module, avec son nom écrit sur l'image.
class _TuileModule extends StatelessWidget {
  const _TuileModule({
    required this.titre,
    required this.texte,
    required this.image,
    required this.badgeAlertes,
    required this.onTap,
  });

  final String titre;
  final String texte;
  final String image;

  /// Affiche le nombre d'alertes non lues sur la tuile.
  final bool badgeAlertes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AspectRatio(
      aspectRatio: 0.95,
      child: Material(
        color: Couleurs.vert900,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ImageSource(image),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x0014281B), Color(0xD914281B)],
                    stops: [0.35, 1],
                  ),
                ),
              ),
              if (badgeAlertes)
                Positioned(
                  top: 10,
                  right: 10,
                  child: ValueListenableBuilder<int>(
                    valueListenable: context.read<RappelService>().nonLues,
                    builder: (context, nonLues, _) => nonLues == 0
                        ? const SizedBox.shrink()
                        : Etiquette(
                            '$nonLues alerte${nonLues > 1 ? 's' : ''}',
                            fond: Couleurs.or500,
                            couleur: Couleurs.encre,
                          ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      titre,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      texte,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
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

class _CartePublic extends StatelessWidget {
  const _CartePublic({
    required this.titre,
    required this.texte,
    required this.image,
  });

  final String titre;
  final String texte;
  final String image;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 230,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 130, child: ImageSource(image)),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titre,
                    style: theme.textTheme.titleMedium?.copyWith(
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

class _CarteConseil extends StatelessWidget {
  const _CarteConseil({
    required this.titre,
    required this.texte,
    required this.image,
    required this.action,
    required this.onTap,
  });

  final String titre;
  final String texte;
  final String image;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 150, child: ImageSource(image, fit: BoxFit.cover)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titre,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Couleurs.vert900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  texte,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Couleurs.ardoise700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: Text(action),
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
