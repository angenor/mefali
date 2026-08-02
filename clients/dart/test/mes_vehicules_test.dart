import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for MesVehicules
void main() {
  final instance = MesVehiculesBuilder();
  // TODO add properties to the builder and call build()

  group(MesVehicules, () {
    // Slugs de `zones.type_transport` ACTIFS dans la zone du compte.  La liste remplace la précédente ; elle ne s'y ajoute pas. Une liste vide est refusée : pour cesser de rouler on passe hors ligne, on ne se prive pas de véhicule — sinon le coursier se recrée l'impasse que cette route existe pour ouvrir.
    // BuiltList<String> vehicules
    test('to test the property `vehicules`', () async {
      // TODO
    });

  });
}
