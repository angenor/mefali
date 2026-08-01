// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'etat_course.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// En ligne ? — dérivé de `connectivity_plus`, réduit à un booléen et
/// `.distinct()` : n'émet qu'aux VRAIES transitions (le flux brut envoie de
/// nombreux événements redondants, surtout sur l'émulateur). Sans ce filtre,
/// chaque événement déclencherait un rebuild de la course (tempête observée).

@ProviderFor(connectiviteEnLigne)
final connectiviteEnLigneProvider = ConnectiviteEnLigneProvider._();

/// En ligne ? — dérivé de `connectivity_plus`, réduit à un booléen et
/// `.distinct()` : n'émet qu'aux VRAIES transitions (le flux brut envoie de
/// nombreux événements redondants, surtout sur l'émulateur). Sans ce filtre,
/// chaque événement déclencherait un rebuild de la course (tempête observée).

final class ConnectiviteEnLigneProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  /// En ligne ? — dérivé de `connectivity_plus`, réduit à un booléen et
  /// `.distinct()` : n'émet qu'aux VRAIES transitions (le flux brut envoie de
  /// nombreux événements redondants, surtout sur l'émulateur). Sans ce filtre,
  /// chaque événement déclencherait un rebuild de la course (tempête observée).
  ConnectiviteEnLigneProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'connectiviteEnLigneProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$connectiviteEnLigneHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return connectiviteEnLigne(ref);
  }
}

String _$connectiviteEnLigneHash() =>
    r'0076e0c81384cc967c9fb3feef4e93cf449fdc0e';

/// Course active du coursier (chargement /courses/active + collecte offline-first).
///
/// `AsyncNotifier` (moule des listes, constitution XII). Charge le
/// pré-provisionnement, le met en cache drift (validation hors-ligne), et
/// applique la coche optimiste avant réconciliation serveur.

@ProviderFor(EtatCourseActive)
final etatCourseActiveProvider = EtatCourseActiveProvider._();

/// Course active du coursier (chargement /courses/active + collecte offline-first).
///
/// `AsyncNotifier` (moule des listes, constitution XII). Charge le
/// pré-provisionnement, le met en cache drift (validation hors-ligne), et
/// applique la coche optimiste avant réconciliation serveur.
final class EtatCourseActiveProvider
    extends $AsyncNotifierProvider<EtatCourseActive, EtatCourse> {
  /// Course active du coursier (chargement /courses/active + collecte offline-first).
  ///
  /// `AsyncNotifier` (moule des listes, constitution XII). Charge le
  /// pré-provisionnement, le met en cache drift (validation hors-ligne), et
  /// applique la coche optimiste avant réconciliation serveur.
  EtatCourseActiveProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'etatCourseActiveProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$etatCourseActiveHash();

  @$internal
  @override
  EtatCourseActive create() => EtatCourseActive();
}

String _$etatCourseActiveHash() => r'd998d9eb30ab23559b5dddc691cec0e28eb52b4e';

/// Course active du coursier (chargement /courses/active + collecte offline-first).
///
/// `AsyncNotifier` (moule des listes, constitution XII). Charge le
/// pré-provisionnement, le met en cache drift (validation hors-ligne), et
/// applique la coche optimiste avant réconciliation serveur.

abstract class _$EtatCourseActive extends $AsyncNotifier<EtatCourse> {
  FutureOr<EtatCourse> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<EtatCourse>, EtatCourse>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<EtatCourse>, EtatCourse>,
              AsyncValue<EtatCourse>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
