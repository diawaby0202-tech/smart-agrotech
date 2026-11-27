import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:smart_agrotech/features/marche/annonce.dart';
import 'package:smart_agrotech/features/marche/annonce_repository.dart';
import 'package:smart_agrotech/features/marche/commande.dart';
import 'package:smart_agrotech/features/marche/commande_repository.dart';
import 'package:smart_agrotech/features/marche/commande_screen.dart';

void main() {
  testWidgets('achat : total, QR d’instructions et signalement manuel', (
    tester,
  ) async {
    final annonces = MockAnnonceRepository();
    final annonce = await annonces.create(
      const Annonce(
        titre: 'Mil local',
        categorie: CategorieAnnonce.cereales,
        prix: 900,
        quantite: '10 kg',
        stock: 10,
        unite: UniteAnnonce.kg,
        vendeurNom: 'Vendeuse',
        vendeurTelephone: '771234567',
      ),
    );
    final commandes = MockCommandeRepository(annonces);

    await tester.pumpWidget(
      Provider<CommandeRepository>.value(
        value: commandes,
        child: MaterialApp(home: AchatAnnonceScreen(annonce: annonce)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('commande-quantite')),
      '2',
    );
    await tester.pumpAndSettle();
    expect(find.text('1 800 FCFA'), findsOneWidget);
    await tester.tap(find.text('Orange Money'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('commande-creer')));
    await tester.pumpAndSettle();

    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('77 123 45 67'), findsOneWidget);
    expect(find.text('Orange Money'), findsWidgets);
    expect(
      find.textContaining('Ce n’est pas un QR de paiement opérateur'),
      findsOneWidget,
    );

    await tester.ensureVisible(
      find.byKey(const Key('commande-signaler-paiement')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('commande-signaler-paiement')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('le vendeur vérifie le transfert'),
      findsOneWidget,
    );
    expect(
      (await commandes.list()).single.statut,
      StatutCommande.paiementSignale,
    );
  });
}
