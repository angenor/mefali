import 'dart:convert';

/// Configuration produit d'une zone telle que servie par `GET /config` et mise
/// en cache localement (ZON-04). Immuable et sérialisable pour le cache.
///
/// `donnees` porte le document complet (drapeaux, devise, textes, catégories…) ;
/// `zone` et `version` en sont extraits pour la comparaison de version (FR-019).
class ConfigDistante {
  /// Construit une configuration distante.
  const ConfigDistante({
    required this.zone,
    required this.version,
    required this.donnees,
  });

  /// Reconstruit depuis le document JSON servi par `/config`.
  factory ConfigDistante.depuisJson(Map<String, dynamic> json) {
    return ConfigDistante(
      zone: json['zone'] as String,
      version: json['version'] as String,
      donnees: json,
    );
  }

  /// Reconstruit depuis la chaîne mise en cache.
  factory ConfigDistante.decoder(String source) {
    return ConfigDistante.depuisJson(jsonDecode(source) as Map<String, dynamic>);
  }

  /// Identifiant de la zone servie.
  final String zone;

  /// Empreinte de version (= ETag) — détecte un changement de configuration.
  final String version;

  /// Document complet de `/config`.
  final Map<String, dynamic> donnees;

  /// Sérialise pour le cache local.
  String encoder() => jsonEncode(donnees);
}
