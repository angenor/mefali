import 'cache_config.dart';
import 'service_config.dart';
import 'source_config.dart';

/// Construit et démarre le [ServiceConfig] d'une application à partir d'une
/// source et d'un cache DÉJÀ construits.
///
/// INVERSION D'INJECTION (FR-010, FR-035) : la fonction REÇOIT sa source et son
/// cache au lieu de les construire elle-même. C'est ce changement de production
/// qui rend les surcharges de `sourceConfigProvider`/`cacheConfigProvider`
/// OPÉRANTES — dans la forme d'origine (elle construisait `SourceConfigApi(...)`
/// et `CacheConfigPreferences(prefs)`), les surcharger ne changeait RIEN et
/// SC-004 se perdait sans qu'aucune assertion ne bronche (R5). `urlApi` n'y
/// descend plus : il descend dans `clientConfigProvider`, que `sourceConfig`
/// watch déjà.
Future<ServiceConfig> demarrerServiceConfig({
  required SourceConfig source,
  required CacheConfig cache,
}) async {
  final service = ServiceConfig(source: source, cache: cache);
  await service.demarrer();
  return service;
}
