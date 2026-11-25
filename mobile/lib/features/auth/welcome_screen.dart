import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/design.dart';
import '../../core/theme.dart';
import '../home/menu.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const _services = [
    (
      titre: 'Cultures',
      texte: 'Suivez vos parcelles, du semis à la récolte.',
      image: 'assets/img/culture-arachide.jpg',
      icone: Icons.grass,
    ),
    (
      titre: 'Élevage',
      texte: 'Gardez un œil sur vos animaux et leurs soins.',
      image: 'assets/img/elevage-bovin.jpg',
      icone: Icons.pets_outlined,
    ),
    (
      titre: 'Marché',
      texte: 'Achetez et vendez des produits locaux.',
      image: 'assets/img/marche-tomates.jpg',
      icone: Icons.storefront_outlined,
    ),
    (
      titre: 'Météo',
      texte: 'Préparez vos activités grâce aux prévisions.',
      image: 'assets/img/meteo.jpg',
      icone: Icons.cloud_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Couleurs.ardoise50,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  const Expanded(child: NomMarque(taille: 34)),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Couleurs.vert50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'SÉNÉGAL',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Couleurs.vert700,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _HeroAccueil(
              theme: theme,
              onLogin: () => context.push('/connexion'),
              onRegister: () => context.push('/inscription'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Une ferme bien accompagnée',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Couleurs.vert900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Les bons outils pour avancer chaque jour, à votre rythme.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Couleurs.ardoise500,
                    ),
                  ),
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 600 ? 4 : 2;
                      return GridView.count(
                        crossAxisCount: columns,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: columns == 2 ? 0.88 : 0.8,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          for (final service in _services)
                            _CarteService(
                              titre: service.titre,
                              texte: service.texte,
                              image: service.image,
                              icone: service.icone,
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Couleurs.vert900,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cultivons l’avenir, ensemble.',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Créez votre espace pour retrouver vos cultures, votre '
                      'élevage, les alertes et le marché.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: const Key('welcome-register-bottom'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Couleurs.or500,
                          foregroundColor: Couleurs.vert900,
                          minimumSize: const Size.fromHeight(52),
                        ),
                        onPressed: () => context.push('/inscription'),
                        child: const Text('Créer mon compte'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        key: const Key('welcome-login-bottom'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                          minimumSize: const Size.fromHeight(52),
                        ),
                        onPressed: () => context.push('/connexion'),
                        child: const Text('J’ai déjà un compte'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Text(
                'Smart AgroTech · Au service de celles et ceux qui cultivent.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Couleurs.ardoise500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroAccueil extends StatelessWidget {
  const _HeroAccueil({
    required this.theme,
    required this.onLogin,
    required this.onRegister,
  });

  final ThemeData theme;
  final VoidCallback onLogin;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      child: SizedBox(
        height: 410,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ImageSource('assets/img/hero.jpg'),
            const ColoredBox(color: Color(0x59000000)),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x0014281B), Color(0xE814281B)],
                  stops: [0.2, 1],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Couleurs.or500,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      'SMART AGROTECH SÉNÉGAL',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Couleurs.vert900,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'L’agriculture, notre avenir.',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Des outils simples pour cultiver, élever et vendre '
                    'plus sereinement.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          key: const Key('welcome-register'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Couleurs.or500,
                            foregroundColor: Couleurs.vert900,
                            minimumSize: const Size.fromHeight(50),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          onPressed: onRegister,
                          child: const Text('S’inscrire'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          key: const Key('welcome-login'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                            minimumSize: const Size.fromHeight(50),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          onPressed: onLogin,
                          child: const Text('Se connecter'),
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
    );
  }
}

class _CarteService extends StatelessWidget {
  const _CarteService({
    required this.titre,
    required this.texte,
    required this.image,
    required this.icone,
  });

  final String titre;
  final String texte;
  final String image;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: ImageSource(image)),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icone, color: Couleurs.vert700, size: 20),
                const SizedBox(height: 5),
                Text(titre, style: theme.textTheme.titleSmall),
                const SizedBox(height: 3),
                Text(
                  texte,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Couleurs.ardoise500,
                    height: 1.25,
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
