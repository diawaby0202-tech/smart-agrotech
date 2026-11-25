import 'package:flutter_test/flutter_test.dart';
import 'package:smart_agrotech/core/format.dart';

void main() {
  test('numéros de téléphone sénégalais lisibles', () {
    expect(formatTelephone('771234567'), '77 123 45 67');
    expect(formatTelephone('+221771234567'), '+221 77 123 45 67');
    expect(formatTelephone('221 78 111 22 33'), '+221 78 111 22 33');
    // Un numéro inattendu est affiché tel quel.
    expect(formatTelephone('12345'), '12345');
  });

  test('prix en FCFA', () {
    expect(formatPrix(450000), '450 000 FCFA');
    expect(formatPrix(8000), '8 000 FCFA');
  });
}
