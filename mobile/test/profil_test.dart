import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_agrotech/features/auth/user.dart';

import 'helpers.dart';

void main() {
  testWidgets('profil : informations du compte puis modification', (
    tester,
  ) async {
    await pumpApp(tester);
    await loginDemo(tester);

    await tester.tap(find.byKey(const Key('profil')));
    await tester.pumpAndSettle();

    expect(find.text('Informations'), findsOneWidget);
    expect(find.text('Agriculteur / Éleveur'), findsOneWidget);
    expect(find.text('Validé'), findsOneWidget);
    expect(find.text('demo@agrotech.sn'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('profil-prenom')), 'Aïssatou');
    await appuyer(tester, const Key('profil-enregistrer'));
    expect(
      find.textContaining('Profil mis à jour avec succès.'),
      findsOneWidget,
    );

    // Le nouveau prénom apparaît sur l'accueil.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.textContaining(', Aïssatou 👋'), findsOneWidget);
  });

  test('le rôle admin est reconnu mais pas proposé à l\'inscription', () {
    final admin = User.fromJson({
      'id': 1,
      'email': 'admin@agrotech.sn',
      'nom': 'Faye',
      'prenom': 'Omar',
      'telephone': '',
      'role': 'admin',
      'statut': 'valide',
      'date_inscription': '2026-10-14T10:00:00Z',
    });

    expect(admin.role, UserRole.admin);
    expect(admin.role.label, 'Administrateur');
    expect(admin.dateInscription, DateTime.utc(2026, 10, 14, 10));
    expect(UserRole.inscription, isNot(contains(UserRole.admin)));
  });
}
