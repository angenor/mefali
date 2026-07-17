// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ecran_appareils.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// La liste des appareils/sessions du compte. `@riverpod` nu (autoDispose) :
/// écran de liste, aucun état à faire survivre.

@ProviderFor(MesSessions)
final mesSessionsProvider = MesSessionsProvider._();

/// La liste des appareils/sessions du compte. `@riverpod` nu (autoDispose) :
/// écran de liste, aucun état à faire survivre.
final class MesSessionsProvider
    extends $AsyncNotifierProvider<MesSessions, List<SessionAppareil>> {
  /// La liste des appareils/sessions du compte. `@riverpod` nu (autoDispose) :
  /// écran de liste, aucun état à faire survivre.
  MesSessionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mesSessionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mesSessionsHash();

  @$internal
  @override
  MesSessions create() => MesSessions();
}

String _$mesSessionsHash() => r'c7949b007feeeddbd74818b61ca27e3c37e01c82';

/// La liste des appareils/sessions du compte. `@riverpod` nu (autoDispose) :
/// écran de liste, aucun état à faire survivre.

abstract class _$MesSessions extends $AsyncNotifier<List<SessionAppareil>> {
  FutureOr<List<SessionAppareil>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<SessionAppareil>>, List<SessionAppareil>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<SessionAppareil>>,
                List<SessionAppareil>
              >,
              AsyncValue<List<SessionAppareil>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
