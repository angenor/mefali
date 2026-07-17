import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/clients.dart';
import 'amorce_config.dart';
import 'cache_config.dart';
import 'config_distante.dart';
import 'source_config.dart';

part 'service_config.g.dart';

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

/// La source distante de configuration. `keepAlive` : dépendance d'un service
/// `keepAlive` (en `autoDispose` elle serait reconstruite sous lui). Surchargée
/// en test (FR-035).
@Riverpod(keepAlive: true)
SourceConfig sourceConfig(Ref ref) =>
    SourceConfigApi(ref.watch(clientConfigProvider));

/// Le cache local de configuration (`shared_preferences`). `keepAlive`.
///
/// `Raw<Future<…>>` et NON `CacheConfig` nu : `CacheConfigPreferences(this._prefs)`
/// exige un `SharedPreferences` qui ne s'obtient que par un `await` — un
/// `Provider<CacheConfig>` synchrone NE COMPILE PAS. `Raw` et non `FutureProvider` :
/// même doctrine que `serviceConfig` — aucun `AsyncValue`, aucun retry (R5, R10).
/// Surchargé en test — le canal de plateforme n'est pas simulé (FR-035, FR-039).
@Riverpod(keepAlive: true)
Raw<Future<CacheConfig>> cacheConfig(Ref ref) =>
    SharedPreferences.getInstance().then(CacheConfigPreferences.new);

/// FR-021 — le provider HÉBERGE le service, il ne l'OBSERVE JAMAIS : il expose le
/// SERVICE (un Future dessus), jamais une valeur observée.
///
/// `Raw` rend un `Provider` de Future : PAS de `FutureProvider`, donc AUCUN
/// `AsyncValue` à émettre ⇒ FR-021 devient IMPOSSIBLE à violer, et non tenu par
/// la discipline `read` vs `watch` ; et AUCUN retry automatique ⇒ un échec ne
/// refabriquerait pas un `ServiceConfig`, donc pas un 2ᵉ Timer (FR-019).
///
/// La fonction reste SYNCHRONE : les deux `ref.watch` sont évalués AVANT tout
/// point de suspension (un `watch` après un `await` est une arête non
/// enregistrée), et `cacheConfig` (un `Raw<Future<…>>`) est CHAÎNÉ par `.then`,
/// pas `await`é — sans quoi on retomberait sur l'`AsyncValue` que FR-021 interdit.
@Riverpod(keepAlive: true)
Raw<Future<ServiceConfig>> serviceConfig(Ref ref) {
  final source = ref.watch(sourceConfigProvider);
  final futurCache = ref.watch(cacheConfigProvider);
  final futur = futurCache
      .then((cache) => demarrerServiceConfig(source: source, cache: cache));
  ref.onDispose(() => futur.then((s) => s.arreter()).ignore()); // FR-018
  return futur;
}
