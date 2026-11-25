import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'theme.dart';

/// Éléments visuels communs : logo, en-tête de module, étiquettes, encadrés
/// et cartes avec photo. Couleurs unies et icônes plutôt que dégradés et
/// emojis.

/// Logo de l'app : une feuille sur un carré vert uni.
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
        color: Couleurs.vert700,
        borderRadius: BorderRadius.circular(taille * 0.26),
      ),
      child: Icon(Icons.eco, color: Couleurs.or100, size: taille * 0.56),
    );
  }
}

/// Carte blanche qui contient un formulaire d'authentification.
class CarteFormulaire extends StatelessWidget {
  const CarteFormulaire({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4E8DF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100F2417),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Titre en tête de chaque module, posé directement sur le fond de la page.
class BandeauModule extends StatelessWidget {
  const BandeauModule({
    super.key,
    required this.titre,
    required this.texte,
    this.image,
  });

  final String titre;
  final String texte;
  final String? image;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (image != null) {
      return Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 128,
          child: Row(
            children: [
              SizedBox(
                width: 112,
                child: ImageSource(image!, fit: BoxFit.cover),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        titre,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Couleurs.vert900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        texte,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Couleurs.ardoise500,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titre, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
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

/// Pastille colorée (statut, niveau d'alerte, catégorie).
class Etiquette extends StatelessWidget {
  const Etiquette(
    this.texte, {
    super.key,
    this.fond = Couleurs.vert700,
    this.couleur = Colors.white,
  });

  final String texte;
  final Color fond;
  final Color couleur;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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

/// Encadré coloré (rappel de récolte, prochain soin…), avec un filet de
/// couleur à gauche.
class Encadre extends StatelessWidget {
  const Encadre({
    super.key,
    required this.icone,
    required this.texte,
    this.fond = Couleurs.or100,
    this.couleur = Couleurs.or600,
  });

  final IconData icone;
  final String texte;
  final Color fond;
  final Color couleur;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 18, color: couleur),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texte,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: couleur,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
    if (source.startsWith('assets/')) {
      return Image.asset(source, fit: fit, errorBuilder: (_, _, _) => vide);
    }
    return Image.file(File(source), fit: fit, errorBuilder: (_, _, _) => vide);
  }
}

/// Sélection et aperçu d'une photo choisie pour une fiche.
class PhotoField extends StatelessWidget {
  const PhotoField({
    super.key,
    required this.buttonKey,
    required this.label,
    required this.onChoose,
    this.image,
    this.preview,
  });

  final Key buttonKey;
  final String label;
  final VoidCallback onChoose;
  final String? image;
  final Uint8List? preview;

  @override
  Widget build(BuildContext context) {
    final hasImage = preview != null || (image?.isNotEmpty ?? false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 170,
            child: preview != null
                ? Image.memory(preview!, fit: BoxFit.cover)
                : hasImage
                ? ImageSource(image!, fit: BoxFit.cover)
                : const ColoredBox(
                    color: Couleurs.ardoise100,
                    child: Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 44,
                      color: Couleurs.ardoise500,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: buttonKey,
          onPressed: onChoose,
          icon: const Icon(Icons.photo_library_outlined),
          label: Text(hasImage ? 'Changer la photo' : 'Choisir une photo'),
        ),
      ],
    );
  }
}

/// Carte avec une photo en haut (parcelles, animaux, annonces).
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
      margin: const EdgeInsets.only(bottom: 16),
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

/// Ligne « icône + texte » des cartes.
class LigneInfo extends StatelessWidget {
  const LigneInfo(this.icone, this.texte, {super.key});

  final IconData icone;
  final String texte;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icone, size: 16, color: Couleurs.ardoise400),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texte,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Couleurs.ardoise500),
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F2417),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: Couleurs.ardoise200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            valeur,
            style: theme.textTheme.titleLarge?.copyWith(
              color: Couleurs.vert700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            libelle,
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
          minimumSize: const Size(0, 42),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
        onPressed: onPressed,
        child: Text(label),
      );
    }
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 42),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
