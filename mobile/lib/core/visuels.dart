/// Photos et icônes associées aux données. Les photos suivent les mêmes règles
/// que le site web (`frontend/src/pages/*.jsx`), pour que les deux affichent
/// la même image.
library;

import 'package:flutter/material.dart';

typedef Visuel = ({String image});

const _dossier = 'assets/img';

Visuel visuelCulture(String nom) {
  final n = nom.toLowerCase();
  if (n.contains('mil')) return (image: '$_dossier/culture-mil.jpg');
  if (n.contains('arachide')) return (image: '$_dossier/culture-arachide.jpg');
  if (n.contains('maïs') || n.contains('mais')) {
    return (image: '$_dossier/culture-mais.jpg');
  }
  return (image: '$_dossier/cultures.jpg');
}

Visuel visuelEspece(String espece) {
  final e = espece.toLowerCase();
  if (['bov', 'vache', 'boeuf', 'bœuf', 'taureau'].any(e.contains)) {
    return (image: '$_dossier/elevage-bovin.jpg');
  }
  if (['cap', 'chèvre', 'chevre', 'bouc'].any(e.contains)) {
    return (image: '$_dossier/elevage-ovin.jpg');
  }
  if (['ovin', 'mouton', 'brebis', 'bélier', 'belier'].any(e.contains)) {
    return (image: '$_dossier/elevage-ovin.jpg');
  }
  if (['poulet', 'poule', 'volaille'].any(e.contains)) {
    return (image: '$_dossier/elevage-volaille.jpg');
  }
  return (image: '$_dossier/elevage-bovin.jpg');
}

/// Image par défaut d'une annonce sans photo, selon sa catégorie.
Visuel visuelCategorie(String categorie) => switch (categorie) {
  'cereales' => (image: '$_dossier/culture-mil.jpg'),
  'legumes' => (image: '$_dossier/marche-tomates.jpg'),
  'fruits' => (image: '$_dossier/marche-oignons.jpg'),
  'betail' => (image: '$_dossier/elevage-bovin.jpg'),
  _ => (image: '$_dossier/marche.jpg'),
};

const imageMeteo = '$_dossier/meteo-arc-en-ciel.jpg';

IconData iconeMeteo(String description) {
  final d = description.toLowerCase();
  if (d.contains('orage')) return Icons.thunderstorm_outlined;
  if (['pluie', 'averse', 'bruine'].any(d.contains)) {
    return Icons.water_drop_outlined;
  }
  if (['nuage', 'couvert', 'brume'].any(d.contains)) {
    return Icons.cloud_outlined;
  }
  if (['dégagé', 'clair', 'soleil'].any(d.contains)) {
    return Icons.wb_sunny_outlined;
  }
  return Icons.wb_cloudy_outlined;
}

IconData iconeTypeAlerte(String type) => switch (type) {
  'meteo' => Icons.thunderstorm_outlined,
  'vaccination' => Icons.vaccines_outlined,
  'culture' => Icons.grass,
  _ => Icons.notifications_none,
};
