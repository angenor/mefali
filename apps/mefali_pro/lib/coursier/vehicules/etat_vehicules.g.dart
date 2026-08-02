// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'etat_vehicules.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Les transports ACTIFS de la zone — injectés par la PORTÉE (constitution XII).
///
/// Le défaut lit le service de config. L'injecter permet à un test de servir
/// une liste figée sans armer le minuteur horaire du service, qui laisserait un
/// `Timer` pendant à la destruction de l'arbre (piège du cycle 010).
///
/// Surchargée sur le conteneur RACINE, pas par `ProviderScope` : l'écran est
/// poussé par `Navigator`, donc monté au-dessus de tout scope local. Une portée
/// déclarée (`dependencies: []`) n'y changerait rien, et propagerait
/// `@Dependencies` à chaque appelant jusqu'aux tests.

@ProviderFor(sourceTransportsActifs)
final sourceTransportsActifsProvider = SourceTransportsActifsProvider._();

/// Les transports ACTIFS de la zone — injectés par la PORTÉE (constitution XII).
///
/// Le défaut lit le service de config. L'injecter permet à un test de servir
/// une liste figée sans armer le minuteur horaire du service, qui laisserait un
/// `Timer` pendant à la destruction de l'arbre (piège du cycle 010).
///
/// Surchargée sur le conteneur RACINE, pas par `ProviderScope` : l'écran est
/// poussé par `Navigator`, donc monté au-dessus de tout scope local. Une portée
/// déclarée (`dependencies: []`) n'y changerait rien, et propagerait
/// `@Dependencies` à chaque appelant jusqu'aux tests.

final class SourceTransportsActifsProvider
    extends
        $FunctionalProvider<
          Future<List<String>> Function(),
          Future<List<String>> Function(),
          Future<List<String>> Function()
        >
    with $Provider<Future<List<String>> Function()> {
  /// Les transports ACTIFS de la zone — injectés par la PORTÉE (constitution XII).
  ///
  /// Le défaut lit le service de config. L'injecter permet à un test de servir
  /// une liste figée sans armer le minuteur horaire du service, qui laisserait un
  /// `Timer` pendant à la destruction de l'arbre (piège du cycle 010).
  ///
  /// Surchargée sur le conteneur RACINE, pas par `ProviderScope` : l'écran est
  /// poussé par `Navigator`, donc monté au-dessus de tout scope local. Une portée
  /// déclarée (`dependencies: []`) n'y changerait rien, et propagerait
  /// `@Dependencies` à chaque appelant jusqu'aux tests.
  SourceTransportsActifsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sourceTransportsActifsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sourceTransportsActifsHash();

  @$internal
  @override
  $ProviderElement<Future<List<String>> Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Future<List<String>> Function() create(Ref ref) {
    return sourceTransportsActifs(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Future<List<String>> Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Future<List<String>> Function()>(
        value,
      ),
    );
  }
}

String _$sourceTransportsActifsHash() =>
    r'e1f513745cc216688d9a677bd770130c141397cb';

/// Le geste « je change mes véhicules » (CPT-04).
///
/// Nommé `DeclarationVehicules` et non `MesVehicules` : ce dernier est le nom du
/// modèle GÉNÉRÉ du corps de requête, et deux `MesVehicules` dans le même
/// fichier ne se distingueraient que par leur import.
///
/// `@riverpod` NU (autoDispose, constitution XII) : l'écran est éphémère, et
/// l'état n'a aucune raison de lui survivre. La valeur qui DOIT survivre — les
/// capacités que K1 affiche — vit sur `disponibiliteProvider`, qui est rechargé
/// après un enregistrement réussi.
/// Porteur NU (autoDispose) : aucune portée déclarée. `sourceTransportsActifs`
/// est surchargée sur le conteneur RACINE, jamais dans un `ProviderScope`
/// imbriqué — l'écran étant poussé par `Navigator`, il est monté au-dessus de
/// tout scope local, et une portée déclarée n'y changerait rien tout en
/// propageant `@Dependencies` à chaque appelant.

@ProviderFor(DeclarationVehicules)
final declarationVehiculesProvider = DeclarationVehiculesProvider._();

/// Le geste « je change mes véhicules » (CPT-04).
///
/// Nommé `DeclarationVehicules` et non `MesVehicules` : ce dernier est le nom du
/// modèle GÉNÉRÉ du corps de requête, et deux `MesVehicules` dans le même
/// fichier ne se distingueraient que par leur import.
///
/// `@riverpod` NU (autoDispose, constitution XII) : l'écran est éphémère, et
/// l'état n'a aucune raison de lui survivre. La valeur qui DOIT survivre — les
/// capacités que K1 affiche — vit sur `disponibiliteProvider`, qui est rechargé
/// après un enregistrement réussi.
/// Porteur NU (autoDispose) : aucune portée déclarée. `sourceTransportsActifs`
/// est surchargée sur le conteneur RACINE, jamais dans un `ProviderScope`
/// imbriqué — l'écran étant poussé par `Navigator`, il est monté au-dessus de
/// tout scope local, et une portée déclarée n'y changerait rien tout en
/// propageant `@Dependencies` à chaque appelant.
final class DeclarationVehiculesProvider
    extends $AsyncNotifierProvider<DeclarationVehicules, EtatMesVehicules> {
  /// Le geste « je change mes véhicules » (CPT-04).
  ///
  /// Nommé `DeclarationVehicules` et non `MesVehicules` : ce dernier est le nom du
  /// modèle GÉNÉRÉ du corps de requête, et deux `MesVehicules` dans le même
  /// fichier ne se distingueraient que par leur import.
  ///
  /// `@riverpod` NU (autoDispose, constitution XII) : l'écran est éphémère, et
  /// l'état n'a aucune raison de lui survivre. La valeur qui DOIT survivre — les
  /// capacités que K1 affiche — vit sur `disponibiliteProvider`, qui est rechargé
  /// après un enregistrement réussi.
  /// Porteur NU (autoDispose) : aucune portée déclarée. `sourceTransportsActifs`
  /// est surchargée sur le conteneur RACINE, jamais dans un `ProviderScope`
  /// imbriqué — l'écran étant poussé par `Navigator`, il est monté au-dessus de
  /// tout scope local, et une portée déclarée n'y changerait rien tout en
  /// propageant `@Dependencies` à chaque appelant.
  DeclarationVehiculesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'declarationVehiculesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$declarationVehiculesHash();

  @$internal
  @override
  DeclarationVehicules create() => DeclarationVehicules();
}

String _$declarationVehiculesHash() =>
    r'00489519b2961c1fd1c629c72e838b17b2199481';

/// Le geste « je change mes véhicules » (CPT-04).
///
/// Nommé `DeclarationVehicules` et non `MesVehicules` : ce dernier est le nom du
/// modèle GÉNÉRÉ du corps de requête, et deux `MesVehicules` dans le même
/// fichier ne se distingueraient que par leur import.
///
/// `@riverpod` NU (autoDispose, constitution XII) : l'écran est éphémère, et
/// l'état n'a aucune raison de lui survivre. La valeur qui DOIT survivre — les
/// capacités que K1 affiche — vit sur `disponibiliteProvider`, qui est rechargé
/// après un enregistrement réussi.
/// Porteur NU (autoDispose) : aucune portée déclarée. `sourceTransportsActifs`
/// est surchargée sur le conteneur RACINE, jamais dans un `ProviderScope`
/// imbriqué — l'écran étant poussé par `Navigator`, il est monté au-dessus de
/// tout scope local, et une portée déclarée n'y changerait rien tout en
/// propageant `@Dependencies` à chaque appelant.

abstract class _$DeclarationVehicules extends $AsyncNotifier<EtatMesVehicules> {
  FutureOr<EtatMesVehicules> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<EtatMesVehicules>, EtatMesVehicules>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<EtatMesVehicules>, EtatMesVehicules>,
              AsyncValue<EtatMesVehicules>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
