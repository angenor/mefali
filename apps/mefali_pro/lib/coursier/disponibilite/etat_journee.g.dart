// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'etat_journee.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Chargement de la journée (CRS-01).

@ProviderFor(EtatJournee)
final etatJourneeProvider = EtatJourneeProvider._();

/// Chargement de la journée (CRS-01).
final class EtatJourneeProvider
    extends $AsyncNotifierProvider<EtatJournee, EtatJourneeVue> {
  /// Chargement de la journée (CRS-01).
  EtatJourneeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'etatJourneeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$etatJourneeHash();

  @$internal
  @override
  EtatJournee create() => EtatJournee();
}

String _$etatJourneeHash() => r'8ae41606e76eed7855d967101b091128c8b1d889';

/// Chargement de la journée (CRS-01).

abstract class _$EtatJournee extends $AsyncNotifier<EtatJourneeVue> {
  FutureOr<EtatJourneeVue> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<EtatJourneeVue>, EtatJourneeVue>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<EtatJourneeVue>, EtatJourneeVue>,
              AsyncValue<EtatJourneeVue>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
