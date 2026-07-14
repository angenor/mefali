import 'package:shared_preferences/shared_preferences.dart';

import 'config_distante.dart';

/// Cache local de la configuration (injectable pour les tests).
abstract interface class CacheConfig {
  /// Lit la dernière configuration connue d'une zone, ou `null` si absente.
  Future<ConfigDistante?> lire(String zone);

  /// Écrit la configuration en cache.
  Future<void> ecrire(ConfigDistante config);
}

/// Cache persistant basé sur `shared_preferences` — permet le démarrage
/// hors-ligne sur la dernière configuration connue (FR-020, SC-007).
class CacheConfigPreferences implements CacheConfig {
  /// Construit le cache à partir d'une instance de préférences.
  CacheConfigPreferences(this._prefs);

  final SharedPreferences _prefs;

  static String _cle(String zone) => 'mefali.config.$zone';

  @override
  Future<ConfigDistante?> lire(String zone) async {
    final source = _prefs.getString(_cle(zone));
    if (source == null) return null;
    return ConfigDistante.decoder(source);
  }

  @override
  Future<void> ecrire(ConfigDistante config) async {
    await _prefs.setString(_cle(config.zone), config.encoder());
  }
}
