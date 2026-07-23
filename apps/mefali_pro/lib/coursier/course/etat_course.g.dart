// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'etat_course.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

String _$etatCourseActiveHash() => r'b2fc6a3e77292d789c6358fc01bb9efefa31aefb';

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
