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

  /// Slugs des types de transport ACTIFS dans la zone (référentiel ZON-03).
  ///
  /// C'est la SEULE liste dans laquelle un coursier peut déclarer un véhicule
  /// (FR-015) : le serveur refuse tout le reste. Servie à plat par `/config`,
  /// et non dans `parametres` — ce dernier ne porte que les clés `client.*`.
  ///
  /// Vide si la config n'a jamais pu être chargée : l'appelant doit alors le
  /// dire plutôt que d'afficher un formulaire sans choix.
  List<String> get transportsActifs =>
      (donnees['transports_actifs'] as List?)?.cast<String>() ?? const [];

  /// Durée maximale d'une note vocale de repère, en secondes (FR-019).
  ///
  /// `null` si la config n'a jamais été chargée ou si la zone ne la résout pas :
  /// l'enregistreur laisse alors le serveur trancher plutôt que d'inventer une
  /// borne. JAMAIS de constante en dur ici (FR-024).
  int? get noteVocaleDureeMaxS => (donnees['note_vocale_duree_max_s'] as num?)?.toInt();

  /// Sérialise pour le cache local.
  String encoder() => jsonEncode(donnees);
}
