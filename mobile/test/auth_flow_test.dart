import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_agrotech/app.dart';
import 'package:smart_agrotech/core/token_storage.dart';
import 'package:smart_agrotech/features/auth/auth_provider.dart';
import 'package:smart_agrotech/features/auth/mock_auth_repository.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    final repository = MockAuthRepository(
      InMemoryTokenStorage(),
      delay: Duration.zero,
    );
    final auth = AuthProvider(repository);
    await auth.restoreSession();
    await tester.pumpWidget(SmartAgroTechApp(auth: auth));
    await tester.pumpAndSettle();
  }

  Future<void> login(WidgetTester tester, String email, String password) async {
    await tester.enterText(find.byKey(const Key('login-email')), email);
    await tester.enterText(find.byKey(const Key('login-password')), password);
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
  }

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

    expect(find.text('Email ou mot de passe incorrect.'), findsOneWidget);
  });

  testWidgets('connexion, navigation entre onglets puis déconnexion', (
    tester,
  ) async {
    await pumpApp(tester);

    await login(
      tester,
      MockAuthRepository.demoEmail,
      MockAuthRepository.demoPassword,
    );
    expect(find.text('Bonjour Awa'), findsOneWidget);

    await tester.tap(find.text('Marché').last);
    await tester.pumpAndSettle();
    expect(find.text('Bientôt disponible'), findsOneWidget);

    await tester.tap(find.text('Accueil'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('logout')));
    await tester.pumpAndSettle();
    expect(find.text('Se connecter'), findsOneWidget);
  });

  testWidgets('inscription : retour vers la connexion', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Pas encore de compte ? S\'inscrire'));
    await tester.pumpAndSettle();

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
    await tester.ensureVisible(find.byKey(const Key('register-submit')));
    await tester.tap(find.byKey(const Key('register-submit')));
    await tester.pumpAndSettle();

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
    expect(find.text('Bonjour Moussa'), findsOneWidget);
  });
}
