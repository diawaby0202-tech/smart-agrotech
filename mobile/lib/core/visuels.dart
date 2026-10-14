/// Photos et emojis associés aux données, avec les mêmes règles que le site
/// web (`frontend/src/pages/*.jsx`), pour que les deux affichent la même image.
library;

typedef Visuel = ({String image, String emoji});

const _dossier = 'assets/img';

Visuel visuelCulture(String nom) {
  final n = nom.toLowerCase();
  if (n.contains('mil')) {
    return (image: '$_dossier/culture-mil.jpg', emoji: '🌾');
  }
  if (n.contains('arachide')) {
    return (image: '$_dossier/culture-arachide.jpg', emoji: '🥜');
  }
  if (n.contains('maïs') || n.contains('mais')) {
    return (image: '$_dossier/culture-mais.jpg', emoji: '🌽');
  }
  return (image: '$_dossier/cultures.jpg', emoji: '🌱');
}

Visuel visuelEspece(String espece) {
  final e = espece.toLowerCase();
  if (['bov', 'vache', 'boeuf', 'bœuf', 'taureau'].any(e.contains)) {
    return (image: '$_dossier/elevage-bovin.jpg', emoji: '🐄');
  }
  if (['cap', 'chèvre', 'chevre', 'bouc'].any(e.contains)) {
    return (image: '$_dossier/elevage-caprin.jpg', emoji: '🐐');
  }
  if (['ovin', 'mouton', 'brebis', 'bélier', 'belier'].any(e.contains)) {
    return (image: '$_dossier/elevage-ovin.jpg', emoji: '🐏');
  }
  return (image: '$_dossier/elevage.jpg', emoji: '🐾');
}

/// Image par défaut d'une annonce sans photo, selon sa catégorie.
Visuel visuelCategorie(String categorie) => switch (categorie) {
  'cereales' => (image: '$_dossier/culture-mil.jpg', emoji: '🌾'),
  'legumes' => (image: '$_dossier/marche-tomates.jpg', emoji: '🍅'),
  'fruits' => (image: '$_dossier/marche-oignons.jpg', emoji: '🍉'),
  'betail' => (image: '$_dossier/elevage-bovin.jpg', emoji: '🐄'),
  'intrants' => (image: '$_dossier/marche.jpg', emoji: '🧰'),
  _ => (image: '$_dossier/marche.jpg', emoji: '📦'),
};

const imageMeteo = '$_dossier/meteo.jpg';

String iconeMeteo(String description) {
  final d = description.toLowerCase();
  if (d.contains('orage')) return '⛈️';
  if (['pluie', 'averse', 'bruine'].any(d.contains)) return '🌦️';
  if (['nuage', 'couvert', 'brume'].any(d.contains)) return '☁️';
  if (['dégagé', 'clair', 'soleil'].any(d.contains)) return '☀️';
  return '🌤️';
}

String emojiTypeAlerte(String type) => switch (type) {
  'meteo' => '⛈️',
  'vaccination' => '💉',
  'culture' => '🌾',
  _ => '🔔',
};
