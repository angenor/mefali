import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for SignalementRecuDto
void main() {
  final instance = SignalementRecuDtoBuilder();
  // TODO add properties to the builder and call build()

  group(SignalementRecuDto, () {
    // CE signalement a déclenché le masquage automatique (FR-040).
    // bool masquageAutomatique
    test('to test the property `masquageAutomatique`', () async {
      // TODO
    });

    // Reçu (vrai aussi pour un rejeu — même réponse, rien recompté).
    // bool recu
    test('to test the property `recu`', () async {
      // TODO
    });

  });
}
