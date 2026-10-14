import 'package:flutter/material.dart';

import 'theme.dart';

/// Éléments visuels repris du site web : logo, bandeau de module, étiquettes,
/// encadrés et cartes avec photo.

/// Carré vert dégradé avec la pousse 🌱, logo du site web.
class LogoMarque extends StatelessWidget {
  const LogoMarque({super.key, this.taille = 64});

  final double taille;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: taille,
      height: taille,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: Couleurs.degradeMarque,
        borderRadius: BorderRadius.circular(taille * 0.28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4016A34A),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Text('🌱', style: TextStyle(fontSize: taille * 0.5)),
    );
  }
}

/// Logo « SmartAgroTech » et accroche du site, au-dessus des formulaires de
/// connexion et d'inscription.
class EnteteMarque extends StatelessWidget {
  const EnteteMarque({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const vert = TextStyle(color: Couleurs.vert600);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const LogoMarque(taille: 40),
            const SizedBox(width: 10),
            Text.rich(
              const TextSpan(
                children: [
                  TextSpan(text: 'Smart'),
                  TextSpan(text: 'AgroTech', style: vert),
                ],
              ),
              style: theme.textTheme.titleLarge,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text.rich(
          const TextSpan(
            children: [
              TextSpan(text: "L'agriculture sénégalaise, "),
              TextSpan(text: 'plus intelligente', style: vert),
              TextSpan(text: '.'),
            ],
          ),
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
      ],
    );
  }
}

/// Carte blanche arrondie qui contient un formulaire d'authentification.
class CarteFormulaire extends StatelessWidget {
  const CarteFormulaire({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Couleurs.ardoise200),
        boxShadow: ombreCarte,
      ),
      child: child,
    );
  }
}

/// Bandeau vert en tête de chaque module, comme `BandeauApercu` sur le site.
class BandeauModule extends StatelessWidget {
  const BandeauModule({
    super.key,
    required this.icone,
    required this.titre,
    required this.texte,
  });

  final String icone;
  final String titre;
  final String texte;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: Couleurs.degradeMarque,
        borderRadius: BorderRadius.circular(20),
        boxShadow: ombreCarte,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(icone, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titre,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  texte,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
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

/// Pastille colorée (statut, niveau d'alerte, catégorie).
class Etiquette extends StatelessWidget {
  const Etiquette(
    this.texte, {
    super.key,
    this.fond = Couleurs.vert600,
    this.couleur = Colors.white,
  });

  final String texte;
  final Color fond;
  final Color couleur;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        texte,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: couleur,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Encadré coloré (rappel de récolte, prochain soin…).
class Encadre extends StatelessWidget {
  const Encadre({
    super.key,
    required this.icone,
    required this.texte,
    this.fond = Couleurs.or100,
    this.couleur = Couleurs.or600,
  });

  final String icone;
  final String texte;
  final Color fond;
  final Color couleur;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: couleur.withValues(alpha: 0.25)),
      ),
      child: Text(
        '$icone  $texte',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: couleur,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Image locale (`assets/…`) ou distante (`http…`).
class ImageSource extends StatelessWidget {
  const ImageSource(this.source, {super.key, this.fit = BoxFit.cover});

  final String source;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    const vide = ColoredBox(color: Couleurs.ardoise100);
    if (source.startsWith('http')) {
      return Image.network(source, fit: fit, errorBuilder: (_, _, _) => vide);
    }
    return Image.asset(source, fit: fit, errorBuilder: (_, _, _) => vide);
  }
}

/// Carte avec une photo en haut, comme les cartes de parcelles, d'animaux et
/// d'annonces du site.
class CartePhoto extends StatelessWidget {
  const CartePhoto({
    super.key,
    required this.image,
    required this.children,
    this.badgeHaut,
    this.badgeBas,
    this.onTap,
  });

  final String image;
  final Widget? badgeHaut;
  final Widget? badgeBas;
  final List<Widget> children;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 150,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ImageSource(image),
                  if (badgeHaut != null)
                    Positioned(top: 10, left: 10, child: badgeHaut!),
                  if (badgeBas != null)
                    Positioned(bottom: 10, left: 10, child: badgeBas!),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ligne « emoji + texte » des cartes.
class LigneInfo extends StatelessWidget {
  const LigneInfo(this.emoji, this.texte, {super.key});

  final String emoji;
  final String texte;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        '$emoji  $texte',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: Couleurs.ardoise500),
      ),
    );
  }
}

/// Case de chiffre clé (Parcelles suivies, Surface totale…).
class CaseStat extends StatelessWidget {
  const CaseStat({super.key, required this.valeur, required this.libelle});

  final String valeur;
  final String libelle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Couleurs.ardoise200),
      ),
      child: Column(
        children: [
          Text(
            valeur,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              color: Couleurs.vert700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            libelle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Couleurs.ardoise500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Petit bouton secondaire des cartes (Modifier, + Soin…).
class BoutonCarte extends StatelessWidget {
  const BoutonCarte(
    this.label, {
    super.key,
    required this.onPressed,
    this.danger = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    if (danger) {
      return FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: Couleurs.danger,
          minimumSize: const Size(0, 38),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
        onPressed: onPressed,
        child: Text(label),
      );
    }
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 38),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
