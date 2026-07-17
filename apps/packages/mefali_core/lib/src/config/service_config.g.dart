// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_config.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// La source distante de configuration. `keepAlive` : dépendance d'un service
/// `keepAlive` (en `autoDispose` elle serait reconstruite sous lui). Surchargée
/// en test (FR-035).

@ProviderFor(sourceConfig)
final sourceConfigProvider = SourceConfigProvider._();

/// La source distante de configuration. `keepAlive` : dépendance d'un service
/// `keepAlive` (en `autoDispose` elle serait reconstruite sous lui). Surchargée
/// en test (FR-035).

final class SourceConfigProvider
    extends $FunctionalProvider<SourceConfig, SourceConfig, SourceConfig>
    with $Provider<SourceConfig> {
  /// La source distante de configuration. `keepAlive` : dépendance d'un service
  /// `keepAlive` (en `autoDispose` elle serait reconstruite sous lui). Surchargée
  /// en test (FR-035).
  SourceConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sourceConfigProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sourceConfigHash();

  @$internal
  @override
  $ProviderElement<SourceConfig> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SourceConfig create(Ref ref) {
    return sourceConfig(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SourceConfig value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SourceConfig>(value),
    );
  }
}

String _$sourceConfigHash() => r'3674ed0c53ee176a2889a2a3a1a11b8a9e3ae5b5';

/// Le cache local de configuration (`shared_preferences`). `keepAlive`.
///
/// `Raw<Future<…>>` et NON `CacheConfig` nu : `CacheConfigPreferences(this._prefs)`
/// exige un `SharedPreferences` qui ne s'obtient que par un `await` — un
/// `Provider<CacheConfig>` synchrone NE COMPILE PAS. `Raw` et non `FutureProvider` :
/// même doctrine que `serviceConfig` — aucun `AsyncValue`, aucun retry (R5, R10).
/// Surchargé en test — le canal de plateforme n'est pas simulé (FR-035, FR-039).

@ProviderFor(cacheConfig)
final cacheConfigProvider = CacheConfigProvider._();

/// Le cache local de configuration (`shared_preferences`). `keepAlive`.
///
/// `Raw<Future<…>>` et NON `CacheConfig` nu : `CacheConfigPreferences(this._prefs)`
/// exige un `SharedPreferences` qui ne s'obtient que par un `await` — un
/// `Provider<CacheConfig>` synchrone NE COMPILE PAS. `Raw` et non `FutureProvider` :
/// même doctrine que `serviceConfig` — aucun `AsyncValue`, aucun retry (R5, R10).
/// Surchargé en test — le canal de plateforme n'est pas simulé (FR-035, FR-039).

final class CacheConfigProvider
    extends
        $FunctionalProvider<
          Raw<Future<CacheConfig>>,
          Raw<Future<CacheConfig>>,
          Raw<Future<CacheConfig>>
        >
    with $Provider<Raw<Future<CacheConfig>>> {
  /// Le cache local de configuration (`shared_preferences`). `keepAlive`.
  ///
  /// `Raw<Future<…>>` et NON `CacheConfig` nu : `CacheConfigPreferences(this._prefs)`
  /// exige un `SharedPreferences` qui ne s'obtient que par un `await` — un
  /// `Provider<CacheConfig>` synchrone NE COMPILE PAS. `Raw` et non `FutureProvider` :
  /// même doctrine que `serviceConfig` — aucun `AsyncValue`, aucun retry (R5, R10).
  /// Surchargé en test — le canal de plateforme n'est pas simulé (FR-035, FR-039).
  CacheConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cacheConfigProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cacheConfigHash();

  @$internal
  @override
  $ProviderElement<Raw<Future<CacheConfig>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Raw<Future<CacheConfig>> create(Ref ref) {
    return cacheConfig(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Raw<Future<CacheConfig>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Raw<Future<CacheConfig>>>(value),
    );
  }
}

String _$cacheConfigHash() => r'84481abd96e4cdbd964ec1cb421aeacd6c12f373';

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

@ProviderFor(serviceConfig)
final serviceConfigProvider = ServiceConfigProvider._();

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

final class ServiceConfigProvider
    extends
        $FunctionalProvider<
          Raw<Future<ServiceConfig>>,
          Raw<Future<ServiceConfig>>,
          Raw<Future<ServiceConfig>>
        >
    with $Provider<Raw<Future<ServiceConfig>>> {
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
  ServiceConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'serviceConfigProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$serviceConfigHash();

  @$internal
  @override
  $ProviderElement<Raw<Future<ServiceConfig>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Raw<Future<ServiceConfig>> create(Ref ref) {
    return serviceConfig(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Raw<Future<ServiceConfig>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Raw<Future<ServiceConfig>>>(value),
    );
  }
}

String _$serviceConfigHash() => r'342ae3d986a5ba1cec4ee96332c43493d3b7f379';
