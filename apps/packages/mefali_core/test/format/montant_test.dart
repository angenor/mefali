import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_core/mefali_core.dart';

void main() {
  group('formaterMontant (tokens.md — FCFA entier, espace fine)', () {
    test('groupe par milliers avec l\'espace fine insécable', () {
      expect(formaterMontant(5800, 'XOF'), '5 800 FCFA');
      expect(formaterMontant(800, 'XOF'), '800 FCFA');
      expect(formaterMontant(1500, 'XOF'), '1 500 FCFA');
      expect(formaterMontant(1234567, 'XOF'), '1 234 567 FCFA');
      expect(formaterMontant(0, 'XOF'), '0 FCFA');
    });

    test('XOF s\'écrit FCFA, les autres devises par leur code', () {
      expect(libelleDevise('XOF'), 'FCFA');
      expect(libelleDevise('GHS'), 'GHS');
      expect(formaterMontant(1000, 'GHS'), '1 000 GHS');
    });

    test('montant négatif (écarts comptables futurs)', () {
      expect(grouperMilliers(-2500), '-2 500');
    });
  });
}
