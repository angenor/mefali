// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'liste_adresses.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// La liste des adresses du compte. `@riverpod` nu (autoDispose) : écran de
/// liste, aucun état à faire survivre.

@ProviderFor(MesAdresses)
final mesAdressesProvider = MesAdressesProvider._();

/// La liste des adresses du compte. `@riverpod` nu (autoDispose) : écran de
/// liste, aucun état à faire survivre.
final class MesAdressesProvider
    extends $AsyncNotifierProvider<MesAdresses, List<Adresse>> {
  /// La liste des adresses du compte. `@riverpod` nu (autoDispose) : écran de
  /// liste, aucun état à faire survivre.
  MesAdressesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mesAdressesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mesAdressesHash();

  @$internal
  @override
  MesAdresses create() => MesAdresses();
}

String _$mesAdressesHash() => r'1fb726e1037c6771de43bfcf626993fe49ef850f';

/// La liste des adresses du compte. `@riverpod` nu (autoDispose) : écran de
/// liste, aucun état à faire survivre.

abstract class _$MesAdresses extends $AsyncNotifier<List<Adresse>> {
  FutureOr<List<Adresse>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Adresse>>, List<Adresse>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Adresse>>, List<Adresse>>,
              AsyncValue<List<Adresse>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
