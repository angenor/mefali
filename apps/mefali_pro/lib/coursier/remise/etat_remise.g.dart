// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'etat_remise.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Processus de confirmation de remise (CRS-04, K4).
///
/// `Notifier` et non `AsyncNotifier` : ce n'est pas un chargement de liste,
/// c'est un **processus** (constitution XII, R15).
///
/// **Durée de vie : `keepAlive` PENDANT LA COURSE, pas au-delà.** Un
/// `autoDispose` nu remettrait les essais à zéro à chaque reconstruction de
/// l'écran — le plafond ne protégerait plus rien. Un `keepAlive: true` les
/// garderait après la course, et le coursier suivant hériterait d'un compteur
/// qui n'est pas le sien. D'où le lien explicite, pris à [charger] et relâché à
/// [reinitialiser] : la durée de vie est celle de la remise en cours, et elle
/// est écrite, pas subie.

@ProviderFor(EtatRemiseNotifier)
final etatRemiseProvider = EtatRemiseNotifierProvider._();

/// Processus de confirmation de remise (CRS-04, K4).
///
/// `Notifier` et non `AsyncNotifier` : ce n'est pas un chargement de liste,
/// c'est un **processus** (constitution XII, R15).
///
/// **Durée de vie : `keepAlive` PENDANT LA COURSE, pas au-delà.** Un
/// `autoDispose` nu remettrait les essais à zéro à chaque reconstruction de
/// l'écran — le plafond ne protégerait plus rien. Un `keepAlive: true` les
/// garderait après la course, et le coursier suivant hériterait d'un compteur
/// qui n'est pas le sien. D'où le lien explicite, pris à [charger] et relâché à
/// [reinitialiser] : la durée de vie est celle de la remise en cours, et elle
/// est écrite, pas subie.
final class EtatRemiseNotifierProvider
    extends $NotifierProvider<EtatRemiseNotifier, EtatRemise> {
  /// Processus de confirmation de remise (CRS-04, K4).
  ///
  /// `Notifier` et non `AsyncNotifier` : ce n'est pas un chargement de liste,
  /// c'est un **processus** (constitution XII, R15).
  ///
  /// **Durée de vie : `keepAlive` PENDANT LA COURSE, pas au-delà.** Un
  /// `autoDispose` nu remettrait les essais à zéro à chaque reconstruction de
  /// l'écran — le plafond ne protégerait plus rien. Un `keepAlive: true` les
  /// garderait après la course, et le coursier suivant hériterait d'un compteur
  /// qui n'est pas le sien. D'où le lien explicite, pris à [charger] et relâché à
  /// [reinitialiser] : la durée de vie est celle de la remise en cours, et elle
  /// est écrite, pas subie.
  EtatRemiseNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'etatRemiseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$etatRemiseNotifierHash();

  @$internal
  @override
  EtatRemiseNotifier create() => EtatRemiseNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EtatRemise value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EtatRemise>(value),
    );
  }
}

String _$etatRemiseNotifierHash() =>
    r'942ff246d944f9a7cccf8a57ad177c06b9105657';

/// Processus de confirmation de remise (CRS-04, K4).
///
/// `Notifier` et non `AsyncNotifier` : ce n'est pas un chargement de liste,
/// c'est un **processus** (constitution XII, R15).
///
/// **Durée de vie : `keepAlive` PENDANT LA COURSE, pas au-delà.** Un
/// `autoDispose` nu remettrait les essais à zéro à chaque reconstruction de
/// l'écran — le plafond ne protégerait plus rien. Un `keepAlive: true` les
/// garderait après la course, et le coursier suivant hériterait d'un compteur
/// qui n'est pas le sien. D'où le lien explicite, pris à [charger] et relâché à
/// [reinitialiser] : la durée de vie est celle de la remise en cours, et elle
/// est écrite, pas subie.

abstract class _$EtatRemiseNotifier extends $Notifier<EtatRemise> {
  EtatRemise build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<EtatRemise, EtatRemise>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EtatRemise, EtatRemise>,
              EtatRemise,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
