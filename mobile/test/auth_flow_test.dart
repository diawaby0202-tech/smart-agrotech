import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_agrotech/features/auth/mock_auth_repository.dart';

import 'helpers.dart';

void main() {
  testWidgets('un visiteur arrive sur l\'écran de connexion', (tester) async {
    await pumpApp(tester);

    expect(find.text('Se connecter'), findsOneWidget);
  });

  testWidgets('le formulaire de connexion valide les champs', (tester) async {
    await pumpApp(tester);

    await login(tester, 'pas-un-email', '');

    expect(find.text('Adresse email invalide'), findsOneWidget);
    expect(find.text('Champ obligatoire'), findsOneWidget);
  });

  testWidgets('affiche une erreur si les identifiants sont faux', (
    tester,
  ) async {
    await pumpApp(tester);

    await login(tester, MockAuthRepository.demoEmail, 'mauvais-mdp');

    expect(
      find.textContaining('Email ou mot de passe incorrect.'),
      findsOneWidget,
    );
  });

  testWidgets('connexion, navigation entre onglets puis déconnexion', (
    tester,
  ) async {
    await pumpApp(tester);

    await loginDemo(tester);
    expect(find.textContaining('depuis un seul endroit'), findsOneWidget);

    await ouvrirOnglet(tester, 'Marché');
    expect(find.text('Arachide décortiquée'), findsOneWidget);

    await ouvrirMenu(tester);
    await appuyer(tester, const Key('menu-deconnexion'));
    expect(find.text('Se connecter'), findsOneWidget);
  });

  testWidgets('inscription : retour vers la connexion', (tester) async {
    await pumpApp(tester);
    await appuyer(tester, const Key('login-inscription'));

    const champs = {
      'register-prenom': 'Moussa',
      'register-nom': 'Ndiaye',
      'register-email': 'moussa@example.sn',
      'register-telephone': '78 123 45 67',
      'register-password': 'motdepasse',
      'register-confirm': 'motdepasse',
    };
    for (final champ in champs.entries) {
      await tester.enterText(find.byKey(Key(champ.key)), champ.value);
    }
    await appuyer(tester, const Key('register-submit'));

    expect(find.text('Se connecter'), findsOneWidget);
    expect(
      find.text('Compte créé. Connectez-vous pour continuer.'),
      findsOneWidget,
    );
    expect(find.text('moussa@example.sn'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('login-password')),
      'motdepasse',
    );
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    expect(find.textContaining('depuis un seul endroit'), findsOneWidget);
  });
}
