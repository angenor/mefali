import 'dart:async';

import 'cache_config.dart';
import 'config_distante.dart';
import 'source_config.dart';

/// Zone de bootstrap des applications : Tiassalé, ville unique du MVP
/// (research R7). UUID FIXE posé par le seed backend
/// (`backend/seeds/10_zones_tiassale.sql`). La sélection de zone par adresse
/// arrive avec CPT-05/CMD-02.
const String zoneBootstrapTiassale = '01900000-0000-7000-8000-000000000002';

/// Service de configuration produit distante, partagé par les deux apps
/// (`mefali_client`, `mefali_pro`).
///
/// - sert la dernière configuration en cache au démarrage (hors-ligne — SC-007) ;
/// - rafraîchit au démarrage puis toutes les heures (FR-020) ;
/// - ne remplace la valeur courante que si la `version` change (FR-019).
class ServiceConfig {
  /// Construit le service. La source et le cache sont injectés (testables).
  ServiceConfig({
    required this.source,
    required this.cache,
    this.zone = zoneBootstrapTiassale,
    this.intervalle = const Duration(hours: 1),
  });

  /// Source de la configuration (client généré en production).
  final SourceConfig source;

  /// Cache local (shared_preferences en production).
  final CacheConfig cache;

  /// Zone servie (bootstrap Tiassalé par défaut).
  final String zone;

  /// Intervalle de rafraîchissement (1 heure par défaut — FR-020).
  final Duration intervalle;

  Timer? _minuteur;
  ConfigDistante? _courante;

  /// Dernière configuration connue (cache ou réseau) ; `null` avant chargement.
  ConfigDistante? get courante => _courante;

  /// Démarre le service : cache immédiat, puis rafraîchissement au démarrage et
  /// programmation du rafraîchissement horaire.
  Future<void> demarrer() async {
    _courante = await cache.lire(zone);
    await rafraichir();
    _minuteur ??= Timer.periodic(intervalle, (_) => rafraichir());
  }

  /// Tente de récupérer la configuration. En cas d'échec réseau, conserve la
  /// dernière connue (aucune erreur visible — SC-007). Met à jour cache et
  /// valeur courante uniquement si la version a changé.
  Future<void> rafraichir() async {
    try {
      final recue = await source.recuperer(zone);
      if (_courante?.version != recue.version) {
        _courante = recue;
        await cache.ecrire(recue);
      }
    } catch (_) {
      // Hors-ligne / serveur indisponible : on garde la dernière config connue.
    }
  }

  /// Arrête le rafraîchissement périodique.
  void arreter() {
    _minuteur?.cancel();
    _minuteur = null;
  }
}
