import 'package:mefali_api_client/mefali_api_client.dart';

import 'config_distante.dart';

/// Source de la configuration distante. Interface injectable : les tests
/// fournissent un faux (cache / hors-ligne / rafraîchissement).
abstract interface class SourceConfig {
  /// Récupère la configuration effective d'une zone. Lève une exception en cas
  /// d'échec réseau ; le service retombe alors sur le cache (FR-020).
  Future<ConfigDistante> recuperer(String zone);
}

/// Source réelle : consomme le client Dart GÉNÉRÉ (`mefali_api_client`) — jamais
/// d'appel HTTP artisanal (constitution I).
class SourceConfigApi implements SourceConfig {
  /// Construit la source à partir du client généré.
  SourceConfigApi(this._client);

  final MefaliApiClient _client;

  @override
  Future<ConfigDistante> recuperer(String zone) async {
    final reponse = await _client.getZonesApi().config(zone: zone);
    final document = reponse.data;
    if (document == null) {
      throw StateError('réponse /config vide pour la zone $zone');
    }
    final brut = standardSerializers.serializeWith(ConfigZone.serializer, document);
    return ConfigDistante.depuisJson((brut as Map).cast<String, dynamic>());
  }
}
