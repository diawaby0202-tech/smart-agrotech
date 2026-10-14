import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  testWidgets('cultures : liste, ajout d\'une parcelle et calendrier', (
    tester,
  ) async {
    await pumpApp(tester);
    await loginDemo(tester);
    await ouvrirOnglet(tester, 'Cultures');

    expect(find.text('Champ nord — Arachide'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('parcelle-nom')), 'Bas-fond');
    await tester.enterText(find.byKey(const Key('parcelle-culture')), 'Mil');
    await tester.enterText(find.byKey(const Key('parcelle-superficie')), '1,5');
    await appuyer(tester, const Key('parcelle-submit'));

    expect(find.text('Bas-fond — Mil'), findsOneWidget);
    expect(find.textContaining('1,5 ha'), findsOneWidget);

    await tester.tap(find.text('Calendrier'));
    await tester.pumpAndSettle();
    expect(find.text('Arachide — Champ nord'), findsOneWidget);
    expect(find.text('Dans 5 jours'), findsOneWidget);
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

  testWidgets('élevage : fiche d\'un animal et ajout d\'un suivi sanitaire', (
    tester,
  ) async {
    await pumpApp(tester);
    await loginDemo(tester);
    await ouvrirOnglet(tester, 'Élevage');

    expect(find.text('Mouton Lot Tabaski'), findsOneWidget);

    await tester.tap(find.text('Vache SN-0142'));
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

  testWidgets('élevage : échéances à venir', (tester) async {
    await pumpApp(tester);
    await loginDemo(tester);
    await ouvrirOnglet(tester, 'Élevage');

    await tester.tap(find.text('Échéances'));
    await tester.pumpAndSettle();

    expect(find.text('Traitement — Mouton Lot Tabaski'), findsOneWidget);
    expect(find.text('Dans 2 jours'), findsOneWidget);
  });

  testWidgets('météo : prévisions, risques et alertes', (tester) async {
    final notifier = await pumpApp(tester);
    await loginDemo(tester);

    // Les deux alertes non lues sont notifiées à la connexion.
    expect(notifier.titres, hasLength(2));

    await ouvrirOnglet(tester, 'Météo');
    expect(find.text('Fortes pluies dans 3 jours'), findsOneWidget);
    expect(find.textContaining('Vent : 18 km/h'), findsOneWidget);

    await tester.tap(find.text('Alertes'));
    await tester.pumpAndSettle();
    expect(find.text('Récolte proche : Champ nord'), findsOneWidget);

    // Revenir sur les alertes ne notifie pas une seconde fois.
    expect(notifier.titres, hasLength(2));
  });

  testWidgets('marché : recherche puis publication d\'une annonce', (
    tester,
  ) async {
    await pumpApp(tester);
    await loginDemo(tester);
    await ouvrirOnglet(tester, 'Marché');

    expect(find.text('Moutons Ladoum'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('marche-recherche')), 'tomate');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('Tomates fraîches'), findsOneWidget);
    expect(find.text('Moutons Ladoum'), findsNothing);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('annonce-titre')), 'Oignons');
    await tester.tap(find.byKey(const Key('annonce-categorie')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Légumes').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('annonce-prix')), '15000');
    await appuyer(tester, const Key('annonce-submit'));

    await tester.tap(find.text('Mes annonces'));
    await tester.pumpAndSettle();
    expect(find.text('Oignons'), findsOneWidget);
    expect(find.text('15 000 FCFA'), findsOneWidget);
  });

  testWidgets('marché : le vendeur peut être contacté depuis une annonce', (
    tester,
  ) async {
    await pumpApp(tester);
    await loginDemo(tester);
    await ouvrirOnglet(tester, 'Marché');

    await tester.tap(find.text('Moutons Ladoum'));
    await tester.pumpAndSettle();

    expect(find.text('Ibrahima Sow'), findsOneWidget);
    expect(find.byKey(const Key('annonce-appeler')), findsOneWidget);
  });
}
