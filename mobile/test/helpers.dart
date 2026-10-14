import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_agrotech/app.dart';
import 'package:smart_agrotech/core/notification_service.dart';
import 'package:smart_agrotech/core/services.dart';
import 'package:smart_agrotech/core/token_storage.dart';
import 'package:smart_agrotech/features/auth/mock_auth_repository.dart';

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
Future<FakeNotifier> pumpApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
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
  return notifier;
}

Future<void> login(WidgetTester tester, String email, String password) async {
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
