import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_agrotech/features/auth/user.dart';
import 'package:smart_agrotech/features/cultures/calendrier_recoltes_screen.dart';
import 'package:smart_agrotech/features/cultures/historique_recoltes_screen.dart';
import 'package:smart_agrotech/features/cultures/parcelle_form_screen.dart';
import 'package:smart_agrotech/features/elevage/animal_form_screen.dart';
import 'package:smart_agrotech/features/elevage/suivi_reproduction_screen.dart';
import 'package:smart_agrotech/features/home/dashboard_screen.dart';
import 'package:smart_agrotech/features/marche/annonce_form_screen.dart';
import 'package:smart_agrotech/features/marche/annonce_moderation_screen.dart';

import 'helpers.dart';

void main() {
  testWidgets('administrateur : accès complet aux modules et au profil', (
    tester,
  ) async {
    await pumpApp(tester, role: UserRole.admin);

    for (final module in [
      'dashboard-cultures',
      'dashboard-elevage',
      'dashboard-meteo',
      'dashboard-marche',
    ]) {
      expect(find.byKey(Key(module)), findsOneWidget);
    }
    expect(find.byKey(const Key('profil')), findsOneWidget);
    expect(find.text('Gestion de l’application'), findsOneWidget);
    await voir(tester, find.byKey(const Key('dashboard-moderation-annonces')));
    await tester.tap(find.byKey(const Key('dashboard-moderation-annonces')));
    await tester.pumpAndSettle();
    expect(find.byType(AnnonceModerationScreen), findsOneWidget);
    expect(find.text('Aucune annonce à afficher.'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await voir(tester, find.byKey(const Key('dashboard-cultures')));
    await tester.tap(find.byKey(const Key('dashboard-cultures')));
    await tester.pumpAndSettle();
    expect(find.text('Suivi des cultures'), findsOneWidget);

    await ouvrirMenu(tester);
    for (final lien in [
      'Accueil',
      'Cultures',
      'Élevage',
      'Alertes météo',
      'Marché',
      'Tableau de bord',
      'Mon profil',
      'Modération des annonces',
    ]) {
      expect(
        find.descendant(of: find.byType(Drawer), matching: find.text(lien)),
        findsOneWidget,
      );
    }
  });

  testWidgets('acheteur : limité au marché et aux alertes', (tester) async {
    await pumpApp(tester, role: UserRole.acheteur);

    expect(find.byKey(const Key('dashboard-cultures')), findsNothing);
    expect(find.byKey(const Key('dashboard-elevage')), findsNothing);
    expect(find.byKey(const Key('dashboard-meteo')), findsOneWidget);
    expect(find.byKey(const Key('dashboard-marche')), findsOneWidget);
    expect(find.byKey(const Key('profil')), findsNothing);

    final dashboardContext = tester.element(find.byType(DashboardScreen));
    GoRouter.of(dashboardContext).go('/cultures');
    await tester.pumpAndSettle();
    expect(find.byType(DashboardScreen), findsOneWidget);
    GoRouter.of(
      tester.element(find.byType(DashboardScreen)),
    ).go('/admin/annonces');
    await tester.pumpAndSettle();
    expect(find.byType(AnnonceModerationScreen), findsNothing);

    await ouvrirMenu(tester);
    for (final lien in ['Alertes météo', 'Marché']) {
      expect(
        find.descendant(of: find.byType(Drawer), matching: find.text(lien)),
        findsOneWidget,
      );
    }
    for (final lien in [
      'Accueil',
      'Cultures',
      'Élevage',
      'Tableau de bord',
      'Mon profil',
    ]) {
      expect(
        find.descendant(of: find.byType(Drawer), matching: find.text(lien)),
        findsNothing,
      );
    }
  });

  testWidgets('accueil : tuiles des modules', (tester) async {
    await pumpApp(tester);
    await loginDemo(tester);

    expect(find.textContaining('au même endroit'), findsOneWidget);
    await voir(tester, find.byKey(const Key('dashboard-elevage')));

    // Une tuile ouvre l'onglet du module.
    await tester.tap(find.byKey(const Key('dashboard-elevage')));
    await tester.pumpAndSettle();
    expect(find.text('Gestion de l’élevage'), findsOneWidget);
  });

  testWidgets('le tableau de bord ouvre l’accueil complet', (tester) async {
    await pumpApp(tester);
    await loginDemo(tester);

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/img/producteur.jpg',
      ),
      findsNothing,
    );
    await tester.tap(find.byKey(const Key('dashboard-accueil')));
    await tester.pumpAndSettle();

    final hero = find.byKey(const Key('accueil-hero'));
    expect(tester.getSize(hero).height, lessThanOrEqualTo(380));
    expect(
      find.descendant(
        of: hero,
        matching: find.text(
          'Vos champs, vos bêtes et vos ventes, au même endroit.',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: hero,
        matching: find.byKey(const Key('accueil-cultures')),
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == 'assets/img/hero.jpg',
      ),
      findsOneWidget,
    );
    await voir(tester, find.text('Par où commencer ?'));
    await voir(tester, find.text('Mes cultures'));
    await voir(tester, find.text('Mon élevage'));
    await voir(tester, find.text('La météo'));
    expect(find.text('Cultures en images'), findsNothing);
    await voir(tester, find.text('Conseils pour les cultures'));
    await voir(tester, find.text('Conseils pour l’élevage'));
    await voir(tester, find.text('Conseils météo'));
    await voir(tester, find.text('Pour qui ?'));
    await voir(tester, find.text('Agriculteurs et éleveurs'));
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/img/agriculteur-eleveur.jpg',
      ),
      findsOneWidget,
    );
    await voir(tester, find.text('Structures d’appui'));
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/img/structures-appui.jpg',
      ),
      findsOneWidget,
    );
  });

  testWidgets('accueil : le bouton de la photo ouvre les cultures', (
    tester,
  ) async {
    await pumpApp(tester);
    await loginDemo(tester);

    await voir(tester, find.byKey(const Key('dashboard-cultures')));
    await tester.tap(find.byKey(const Key('dashboard-cultures')));
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

  testWidgets('cultures : calendrier et historique des récoltes', (
    tester,
  ) async {
    await pumpApp(tester);
    await loginDemo(tester);
    await ouvrirOnglet(tester, 'Cultures');

    await tester.tap(find.byKey(const Key('cultures-calendrier')));
    await tester.pumpAndSettle();
    expect(find.byType(CalendrierRecoltesScreen), findsOneWidget);
    expect(find.byKey(const Key('calendrier-grille')), findsOneWidget);
    await tester.tap(find.byKey(const Key('calendrier-mois-suivant')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await voir(tester, find.byKey(const Key('parcelle-recoltes-1')));
    await tester.tap(find.byKey(const Key('parcelle-recoltes-1')));
    await tester.pumpAndSettle();
    expect(find.byType(HistoriqueRecoltesScreen), findsOneWidget);
    expect(
      find.text('Aucune récolte enregistrée pour cette parcelle.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('recolte-ajouter')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('recolte-quantite')), '50');
    await appuyer(tester, const Key('recolte-submit'));
    expect(find.byKey(const Key('recolte-1')), findsOneWidget);
    expect(find.textContaining('20 kg/ha'), findsOneWidget);
  });

  testWidgets('cultures : statistiques, carte et ajout d\'une parcelle', (
    tester,
  ) async {
    final choisirImage = ParcelleFormScreen.choisirImage;
    addTearDown(() => ParcelleFormScreen.choisirImage = choisirImage);
    final parcelleImage = File('assets/img/culture-mil.jpg');
    ParcelleFormScreen.choisirImage = () async => XFile.fromData(
      parcelleImage.readAsBytesSync(),
      name: 'culture-mil.jpg',
      path: parcelleImage.path,
    );

    await pumpApp(tester);
    await loginDemo(tester);
    await ouvrirOnglet(tester, 'Cultures');

    expect(find.text('Suivi des cultures'), findsOneWidget);
    expect(find.text('Parcelles suivies'), findsOneWidget);
    expect(find.text('7 ha'), findsOneWidget);

    await voir(tester, find.text('Champ nord'));
    expect(
      find.textContaining('Récolte prévue dans 5 jour(s)'),
      findsOneWidget,
    );

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('parcelle-nom')), 'Bas-fond');
    await tester.enterText(find.byKey(const Key('parcelle-culture')), 'Mil');
    await tester.enterText(find.byKey(const Key('parcelle-superficie')), '1,5');
    await appuyer(tester, const Key('parcelle-choisir-photo'));
    expect(find.byType(Image), findsWidgets);
    await appuyer(tester, const Key('parcelle-submit'));

    expect(find.text('8,5 ha'), findsOneWidget);
    await voir(tester, find.text('Bas-fond'));
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/img/culture-mil.jpg',
      ),
      findsWidgets,
    );
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

  testWidgets('élevage : ajout d\'un animal avec sa propre photo', (
    tester,
  ) async {
    final choisirImage = AnimalFormScreen.choisirImage;
    addTearDown(() => AnimalFormScreen.choisirImage = choisirImage);
    final animalImage = File('assets/img/elevage-bovin.jpg');
    AnimalFormScreen.choisirImage = () async => XFile.fromData(
      animalImage.readAsBytesSync(),
      name: 'elevage-bovin.jpg',
      path: animalImage.path,
    );

    await pumpApp(tester);
    await loginDemo(tester);
    await ouvrirOnglet(tester, 'Élevage');
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('animal-espece')), 'Chèvre');
    await appuyer(tester, const Key('animal-choisir-photo'));
    await appuyer(tester, const Key('animal-submit'));

    expect(find.text('Chèvre'), findsWidgets);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/img/elevage-bovin.jpg',
      ),
      findsWidgets,
    );
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
    await voir(tester, find.textContaining('Vaccin contre la péripneumonie'));
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

    await voir(tester, find.textContaining('Rappel fièvre aphteuse'));
    expect(find.textContaining('Rappel fièvre aphteuse'), findsOneWidget);

    await voir(tester, find.byKey(const Key('animal-suivi-reproduction')));
    await tester.tap(find.byKey(const Key('animal-suivi-reproduction')));
    await tester.pumpAndSettle();
    expect(find.byType(SuiviReproductionScreen), findsOneWidget);
    await tester.tap(find.byKey(const Key('reproduction-ajouter')));
    await tester.pumpAndSettle();
    await appuyer(tester, const Key('reproduction-submit'));
    expect(find.text('Gestation / suivi en cours'), findsOneWidget);
  });

  testWidgets('météo : prévisions, risques et alertes', (tester) async {
    final notifier = await pumpApp(tester);
    await loginDemo(tester);

    // Les deux alertes non lues sont notifiées à la connexion.
    expect(notifier.titres, hasLength(2));

    await ouvrirOnglet(tester, 'Météo');
    expect(find.text('Dakar, Sénégal'), findsOneWidget);
    expect(find.text("Aujourd'hui"), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/img/meteo-arc-en-ciel.jpg',
      ),
      findsOneWidget,
    );

    await voir(tester, find.text('Fortes pluies dans 3 jours'));
    await voir(tester, find.text('Mes alertes (2 non lues)'));
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
    expect(find.text('Aucune annonce ne correspond.'), findsOneWidget);

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
    // Le filtre est au bout de la rangée de catégories, hors de l'écran.
    await appuyer(tester, const Key('marche-mes-annonces'));
    await voir(tester, find.text('Oignons'));
    expect(find.text('15 000 FCFA'), findsOneWidget);
    await appuyer(tester, const Key('marche-mes-annonces'));
    await voir(tester, find.text('Oignons'));
    await tester.tap(find.text('Oignons'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Awa Diop'), findsOneWidget);
    expect(find.textContaining('77 123 45 67'), findsOneWidget);
    expect(find.byKey(const Key('annonce-appeler')), findsNothing);
  });

  testWidgets('marché : filtres par zone et prix', (tester) async {
    await pumpApp(tester);
    await loginDemo(tester);
    await ouvrirOnglet(tester, 'Marché');

    await tester.tap(find.byTooltip('Zone et prix'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('filtre-zone')), findsOneWidget);
    expect(find.text('Prix min'), findsOneWidget);
    expect(find.text('Prix max'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('filtre-zone')), 'Thiès');
    await tester.tap(find.byKey(const Key('filtre-appliquer')));
    await tester.pumpAndSettle();
    expect(find.text('Aucune annonce ne correspond.'), findsOneWidget);
  });

  testWidgets('marché : aucune annonce de démonstration préremplie', (
    tester,
  ) async {
    await pumpApp(tester);
    await loginDemo(tester);
    await ouvrirOnglet(tester, 'Marché');

    expect(find.text('Aucune annonce ne correspond.'), findsOneWidget);
    await voir(tester, find.byKey(const Key('marche-mes-annonces')));
    await tester.tap(find.byKey(const Key('marche-mes-annonces')));
    await tester.pumpAndSettle();
    expect(find.text('Vous n\'avez pas encore d\'annonce.'), findsOneWidget);
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
    expect(find.text('Marché agricole'), findsOneWidget);

    // Depuis un autre onglet, Retour ramène à l'Accueil.
    await ouvrirOnglet(tester, 'Élevage');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.textContaining('au même endroit'), findsOneWidget);
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
