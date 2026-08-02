// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'etat_preuves.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Processus des trois preuves d'échec (CRS-05, K4-1e).
///
/// `Notifier` et non `AsyncNotifier` (constitution XII, R15) : ce n'est pas un
/// chargement de liste, c'est un **processus** qui dure — dix minutes d'attente
/// devant une porte, échantillonnées.
///
/// **Durée de vie : `keepAlive` PENDANT LA COURSE.** Un `autoDispose` nu
/// remettrait le décompte à zéro à chaque reconstruction de l'écran, et Yao
/// recommencerait ses dix minutes parce qu'il a regardé sa checklist. Le lien
/// est pris à [charger] et relâché à [reinitialiser] — patron `EtatRemise`.
///
/// ⚠ **Aucune minuterie ici.** Le rafraîchissement d'affichage (« encore 4 min »)
/// est une minuterie **locale au widget** : un `Timer` dans un provider survit à
/// l'écran et fait échouer les tests widget par « a Timer is still pending »
/// (piège du cycle 004). Ce qui vit ici, c'est l'échantillonnage — déclenché,
/// pas cadencé.

@ProviderFor(EtatPreuvesNotifier)
final etatPreuvesProvider = EtatPreuvesNotifierProvider._();

/// Processus des trois preuves d'échec (CRS-05, K4-1e).
///
/// `Notifier` et non `AsyncNotifier` (constitution XII, R15) : ce n'est pas un
/// chargement de liste, c'est un **processus** qui dure — dix minutes d'attente
/// devant une porte, échantillonnées.
///
/// **Durée de vie : `keepAlive` PENDANT LA COURSE.** Un `autoDispose` nu
/// remettrait le décompte à zéro à chaque reconstruction de l'écran, et Yao
/// recommencerait ses dix minutes parce qu'il a regardé sa checklist. Le lien
/// est pris à [charger] et relâché à [reinitialiser] — patron `EtatRemise`.
///
/// ⚠ **Aucune minuterie ici.** Le rafraîchissement d'affichage (« encore 4 min »)
/// est une minuterie **locale au widget** : un `Timer` dans un provider survit à
/// l'écran et fait échouer les tests widget par « a Timer is still pending »
/// (piège du cycle 004). Ce qui vit ici, c'est l'échantillonnage — déclenché,
/// pas cadencé.
final class EtatPreuvesNotifierProvider
    extends $NotifierProvider<EtatPreuvesNotifier, EtatPreuvesVue> {
  /// Processus des trois preuves d'échec (CRS-05, K4-1e).
  ///
  /// `Notifier` et non `AsyncNotifier` (constitution XII, R15) : ce n'est pas un
  /// chargement de liste, c'est un **processus** qui dure — dix minutes d'attente
  /// devant une porte, échantillonnées.
  ///
  /// **Durée de vie : `keepAlive` PENDANT LA COURSE.** Un `autoDispose` nu
  /// remettrait le décompte à zéro à chaque reconstruction de l'écran, et Yao
  /// recommencerait ses dix minutes parce qu'il a regardé sa checklist. Le lien
  /// est pris à [charger] et relâché à [reinitialiser] — patron `EtatRemise`.
  ///
  /// ⚠ **Aucune minuterie ici.** Le rafraîchissement d'affichage (« encore 4 min »)
  /// est une minuterie **locale au widget** : un `Timer` dans un provider survit à
  /// l'écran et fait échouer les tests widget par « a Timer is still pending »
  /// (piège du cycle 004). Ce qui vit ici, c'est l'échantillonnage — déclenché,
  /// pas cadencé.
  EtatPreuvesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'etatPreuvesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$etatPreuvesNotifierHash();

  @$internal
  @override
  EtatPreuvesNotifier create() => EtatPreuvesNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EtatPreuvesVue value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EtatPreuvesVue>(value),
    );
  }
}

String _$etatPreuvesNotifierHash() =>
    r'f0329003bc9efb05b73621062ff2d06db9f27ba2';

/// Processus des trois preuves d'échec (CRS-05, K4-1e).
///
/// `Notifier` et non `AsyncNotifier` (constitution XII, R15) : ce n'est pas un
/// chargement de liste, c'est un **processus** qui dure — dix minutes d'attente
/// devant une porte, échantillonnées.
///
/// **Durée de vie : `keepAlive` PENDANT LA COURSE.** Un `autoDispose` nu
/// remettrait le décompte à zéro à chaque reconstruction de l'écran, et Yao
/// recommencerait ses dix minutes parce qu'il a regardé sa checklist. Le lien
/// est pris à [charger] et relâché à [reinitialiser] — patron `EtatRemise`.
///
/// ⚠ **Aucune minuterie ici.** Le rafraîchissement d'affichage (« encore 4 min »)
/// est une minuterie **locale au widget** : un `Timer` dans un provider survit à
/// l'écran et fait échouer les tests widget par « a Timer is still pending »
/// (piège du cycle 004). Ce qui vit ici, c'est l'échantillonnage — déclenché,
/// pas cadencé.

abstract class _$EtatPreuvesNotifier extends $Notifier<EtatPreuvesVue> {
  EtatPreuvesVue build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<EtatPreuvesVue, EtatPreuvesVue>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EtatPreuvesVue, EtatPreuvesVue>,
              EtatPreuvesVue,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
