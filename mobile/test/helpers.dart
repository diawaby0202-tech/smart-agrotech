import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_agrotech/app.dart';
import 'package:smart_agrotech/core/notification_service.dart';
import 'package:smart_agrotech/core/services.dart';
import 'package:smart_agrotech/core/theme.dart';
import 'package:smart_agrotech/core/token_storage.dart';
import 'package:smart_agrotech/features/auth/mock_auth_repository.dart';
import 'package:smart_agrotech/features/auth/user.dart';

/// Retient les notifications au lieu de les afficher.
class FakeNotifier implements Notifier {
  final List<String> titres = [];

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async => titres.add(title);
}

/// Lance l'application en mode démo, sans latence simulée.
Future<FakeNotifier> pumpApp(WidgetTester tester, {UserRole? role}) async {
  SharedPreferences.setMockInitialValues({});
  AppTheme.policesWeb = false;
  AppTheme.animations = false;
  final notifier = FakeNotifier();
  final services = AppServices.create(
    storage: InMemoryTokenStorage(),
    useMock: true,
    notifier: notifier,
    mockDelay: Duration.zero,
  );
  await services.auth.restoreSession();
  await tester.pumpWidget(SmartAgroTechApp(services: services));
  await tester.pumpAndSettle();
  if (role != null) {
    final email = '${role.apiValue}@agrotech.sn';
    await tester.runAsync(() async {
      await services.auth.register(
        RegisterData(
          nom: 'Test',
          prenom: role.label,
          email: email,
          telephone: '',
          password: 'test1234',
          role: role,
        ),
      );
      await services.auth.login(email, 'test1234');
    });
    await tester.pumpAndSettle();
  }
  return notifier;
}

Future<void> login(WidgetTester tester, String email, String password) async {
  if (find.byKey(const Key('welcome-login')).evaluate().isNotEmpty) {
    await tester.tap(find.byKey(const Key('welcome-login')));
    await tester.pumpAndSettle();
  }
  await tester.enterText(find.byKey(const Key('login-email')), email);
  await tester.enterText(find.byKey(const Key('login-password')), password);
  await tester.tap(find.byKey(const Key('login-submit')));
  await tester.pumpAndSettle();
}

Future<void> loginDemo(WidgetTester tester) => login(
  tester,
  MockAuthRepository.demoEmail,
  MockAuthRepository.demoPassword,
);

/// Ouvre un onglet de la barre de navigation du bas.
Future<void> ouvrirOnglet(WidgetTester tester, String label) async {
  if (find.byType(NavigationBar).evaluate().isEmpty) {
    final key = switch (label) {
      'Cultures' => 'dashboard-cultures',
      'Élevage' => 'dashboard-elevage',
      'Météo' || 'Alertes météo' || 'Alertes' => 'dashboard-meteo',
      'Marché' => 'dashboard-marche',
      _ => null,
    };
    if (key != null) {
      await voir(tester, find.byKey(Key(key)));
      await tester.tap(find.byKey(Key(key)));
      await tester.pumpAndSettle();
      return;
    }
  }
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

/// Fait défiler jusqu'à un bouton puis appuie dessus.
Future<void> appuyer(WidgetTester tester, Key key) async {
  // Le champ en cours de saisie se remet à l'écran tant qu'il a le focus.
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byKey(key));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

/// Fait défiler la page jusqu'à un élément (les listes ne construisent que
/// ce qui est visible).
Future<void> voir(
  WidgetTester tester,
  Finder finder, {
  double pas = 300,
}) async {
  await tester.scrollUntilVisible(
    finder,
    pas,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

/// Ouvre le menu latéral avec le bouton ☰.
Future<void> ouvrirMenu(WidgetTester tester) async {
  if (find.byKey(const Key('menu')).evaluate().isEmpty) {
    await ouvrirOnglet(tester, 'Marché');
  }
  await tester.tap(find.byKey(const Key('menu')));
  await tester.pumpAndSettle();
}
