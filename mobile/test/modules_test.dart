import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_agrotech/features/marche/annonce_form_screen.dart';

import 'helpers.dart';

void main() {
  testWidgets('accueil : modules et salutation comme sur le site', (
    tester,
  ) async {
    await pumpApp(tester);
    await loginDemo(tester);

    expect(find.textContaining('depuis un seul endroit'), findsOneWidget);
    expect(
      find.textContaining('Gérez vos cultures, votre bétail'),
      findsOneWidget,
    );
    await voir(tester, find.text('Une plateforme, quatre modules'));
    await voir(tester, find.text('Cultures & récoltes'));

    // « Découvrir » ouvre l'onglet du module.
    await tester.tap(find.text('Cultures & récoltes'));
    await tester.pumpAndSettle();
    expect(find.text('Suivi des cultures'), findsOneWidget);
  });

  testWidgets('menu : mêmes liens que l\'en-tête du site', (tester) async {
    await pumpApp(tester);
    await loginDemo(tester);

    await ouvrirMenu(tester);
    for (final lien in [
      'Accueil',
      'Cultures',
      'Élevage',
      'Alertes météo',
      'Marché',
      'Tableau de bord',
      'Mon profil',
      'Déconnexion',
    ]) {
      expect(
        find.descendant(of: find.byType(Drawer), matching: find.text(lien)),
        findsOneWidget,
      );
    }

    // Un lien du menu change d'onglet.
    await tester.tap(find.byKey(const Key('menu-onglet-2')));
    await tester.pumpAndSettle();
    expect(find.text('Gestion de l’élevage'), findsOneWidget);

    // Le tableau de bord reste accessible depuis le menu.
    await ouvrirMenu(tester);
    await appuyer(tester, const Key('menu-tableau-de-bord'));
    expect(find.text('Mes parcelles'), findsOneWidget);
    expect(find.text('Mon élevage'), findsOneWidget);
  });

  testWidgets('cultures : statistiques, carte et ajout d\'une parcelle', (
    tester,
  ) async {
    await pumpApp(tester);
    await loginDemo(tester);
    await ouvrirOnglet(tester, 'Cultures');

    expect(find.text('Suivi des cultures'), findsOneWidget);
    expect(find.text('Parcelles suivies'), findsOneWidget);
    expect(find.text('7 ha'), findsOneWidget);

    await voir(tester, find.text('Champ nord · Arachide'));
    expect(
      find.textContaining('Récolte prévue dans 5 jour(s)'),
      findsOneWidget,
    );

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('parcelle-nom')), 'Bas-fond');
    await tester.enterText(find.byKey(const Key('parcelle-culture')), 'Mil');
    await tester.enterText(find.byKey(const Key('parcelle-superficie')), '1,5');
    await appuyer(tester, const Key('parcelle-submit'));

    expect(find.text('8,5 ha'), findsOneWidget);
    await voir(tester, find.text('Bas-fond · Mil'));
  });

  testWidgets('cultures : la superficie doit être un nombre positif', (
    tester,
  ) async {
    await pumpApp(tester);
    await loginDemo(tester);
    await ouvrirOnglet(tester, 'Cultures');

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('parcelle-nom')), 'Test');
    await tester.enterText(find.byKey(const Key('parcelle-culture')), 'Mil');
    await tester.enterText(find.byKey(const Key('parcelle-superficie')), '0');
    await appuyer(tester, const Key('parcelle-submit'));

    expect(find.text('Nombre positif attendu'), findsOneWidget);
  });

  testWidgets('élevage : état de santé et prochain soin', (tester) async {
    await pumpApp(tester);
    await loginDemo(tester);
    await ouvrirOnglet(tester, 'Élevage');

    expect(find.text('Gestion de l’élevage'), findsOneWidget);
    // Traitement du lot dans 2 jours : à surveiller.
    await voir(tester, find.text('Lot Tabaski (12 têtes)'));
    expect(find.textContaining('Traitement —'), findsOneWidget);
    expect(find.textContaining('(dans 2 j)'), findsOneWidget);
  });

  testWidgets('élevage : fiche d\'un animal et ajout d\'un suivi sanitaire', (
    tester,
  ) async {
    await pumpApp(tester);
    await loginDemo(tester);
    await ouvrirOnglet(tester, 'Élevage');

    await voir(tester, find.text('SN-0142'));
    await tester.tap(find.text('SN-0142'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Vaccin contre la péripneumonie'),
      findsOneWidget,
    );

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('suivi-description')),
      'Rappel fièvre aphteuse',
    );
    await appuyer(tester, const Key('suivi-submit'));

    expect(find.textContaining('Rappel fièvre aphteuse'), findsOneWidget);
  });

  testWidgets('météo : prévisions, risques et alertes', (tester) async {
    final notifier = await pumpApp(tester);
    await loginDemo(tester);

    // Les deux alertes non lues sont notifiées à la connexion.
    expect(notifier.titres, hasLength(2));

    await ouvrirOnglet(tester, 'Météo');
    expect(find.text('📍 Dakar, Sénégal'), findsOneWidget);
    expect(find.text("Aujourd'hui"), findsOneWidget);

    await voir(tester, find.text('Fortes pluies dans 3 jours'));
    await voir(tester, find.text('🔔 Mes alertes (2 non lues)'));
    await voir(tester, find.text('Récolte proche : Champ nord'));

    // Revenir sur les alertes ne notifie pas une seconde fois.
    expect(notifier.titres, hasLength(2));
  });

  testWidgets('marché : recherche puis publication d\'une annonce', (
    tester,
  ) async {
    await pumpApp(tester);
    await loginDemo(tester);
    await ouvrirOnglet(tester, 'Marché');

    expect(find.text('Marché agricole'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('marche-recherche')), 'tomate');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await voir(tester, find.text('Tomates fraîches'));
    expect(find.text('Moutons Ladoum'), findsNothing);

    await voir(tester, find.byKey(const Key('marche-vendre')), pas: -300);
    await tester.tap(find.byKey(const Key('marche-vendre')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('annonce-titre')), 'Oignons');
    await tester.tap(find.byKey(const Key('annonce-categorie')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Légumes').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('annonce-prix')), '15000');

    // Sans photo, l'annonce est refusée.
    await appuyer(tester, const Key('annonce-submit'));
    expect(find.text('Ajoutez une photo de votre produit.'), findsOneWidget);

    // Photo choisie dans la galerie (simulée avec une photo du site).
    AnnonceFormScreen.choisirImage = (_) async => XFile.fromData(
      File('assets/img/marche-oignons.jpg').readAsBytesSync(),
      name: 'oignons.jpg',
    );
    await appuyer(tester, const Key('annonce-galerie'));
    expect(find.text('Ajoutez une photo de votre produit.'), findsNothing);
    await appuyer(tester, const Key('annonce-submit'));

    await tester.enterText(find.byKey(const Key('marche-recherche')), '');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('marche-mes-annonces')));
    await tester.pumpAndSettle();
    await voir(tester, find.text('Oignons'));
    expect(find.text('15 000 FCFA'), findsOneWidget);
  });

  testWidgets('marché : le vendeur peut être contacté depuis une annonce', (
    tester,
  ) async {
    await pumpApp(tester);
    await loginDemo(tester);
    await ouvrirOnglet(tester, 'Marché');

    await voir(tester, find.text('Moutons Ladoum'));
    await tester.tap(find.text('Moutons Ladoum'));
    await tester.pumpAndSettle();

    expect(find.text('Ibrahima Sow'), findsOneWidget);
    expect(find.textContaining('76 444 55 66'), findsOneWidget);
    expect(find.byKey(const Key('annonce-appeler')), findsOneWidget);
  });

  testWidgets('bouton Retour : ferme le menu puis revient vers Accueil', (
    tester,
  ) async {
    await pumpApp(tester);
    await loginDemo(tester);

    // Menu ouvert : Retour le ferme sans quitter l'app.
    await ouvrirMenu(tester);
    expect(find.byType(Drawer), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(Drawer), findsNothing);
    expect(find.textContaining('depuis un seul endroit'), findsOneWidget);

    // Depuis un autre onglet, Retour ramène à l'Accueil.
    await ouvrirOnglet(tester, 'Élevage');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.textContaining('depuis un seul endroit'), findsOneWidget);
  });

  testWidgets(
    'profil ouvert après Cultures et Élevage, sans conflit de boutons',
    (tester) async {
      await pumpApp(tester);
      await loginDemo(tester);
      await ouvrirOnglet(tester, 'Cultures');
      await ouvrirOnglet(tester, 'Élevage');

      // Les deux boutons ronds restent montés : la transition vers le profil
      // échouait quand ils partageaient le même identifiant d'animation.
      await tester.tap(find.byKey(const Key('profil')));
      await tester.pumpAndSettle();
      expect(find.text('Informations'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
