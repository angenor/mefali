// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'etat_boutique.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// La boutique du prestataire piloté (écran V1 — FR-044). Chargement serveur
/// + gestes en UN appel : moule `AsyncNotifier`, `@riverpod` nu (autoDispose),
/// patron `MesAdresses` du cycle 003/004.

@ProviderFor(Boutique)
final boutiqueProvider = BoutiqueFamily._();

/// La boutique du prestataire piloté (écran V1 — FR-044). Chargement serveur
/// + gestes en UN appel : moule `AsyncNotifier`, `@riverpod` nu (autoDispose),
/// patron `MesAdresses` du cycle 003/004.
final class BoutiqueProvider
    extends $AsyncNotifierProvider<Boutique, BoutiqueVendeur> {
  /// La boutique du prestataire piloté (écran V1 — FR-044). Chargement serveur
  /// + gestes en UN appel : moule `AsyncNotifier`, `@riverpod` nu (autoDispose),
  /// patron `MesAdresses` du cycle 003/004.
  BoutiqueProvider._({
    required BoutiqueFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'boutiqueProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$boutiqueHash();

  @override
  String toString() {
    return r'boutiqueProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  Boutique create() => Boutique();

  @override
  bool operator ==(Object other) {
    return other is BoutiqueProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$boutiqueHash() => r'1790300cb1840b384b3d25a2769c4170ec466ae9';

/// La boutique du prestataire piloté (écran V1 — FR-044). Chargement serveur
/// + gestes en UN appel : moule `AsyncNotifier`, `@riverpod` nu (autoDispose),
/// patron `MesAdresses` du cycle 003/004.

final class BoutiqueFamily extends $Family
    with
        $ClassFamilyOverride<
          Boutique,
          AsyncValue<BoutiqueVendeur>,
          BoutiqueVendeur,
          FutureOr<BoutiqueVendeur>,
          String
        > {
  BoutiqueFamily._()
    : super(
        retry: null,
        name: r'boutiqueProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// La boutique du prestataire piloté (écran V1 — FR-044). Chargement serveur
  /// + gestes en UN appel : moule `AsyncNotifier`, `@riverpod` nu (autoDispose),
  /// patron `MesAdresses` du cycle 003/004.

  BoutiqueProvider call(String prestataireId) =>
      BoutiqueProvider._(argument: prestataireId, from: this);

  @override
  String toString() => r'boutiqueProvider';
}

/// La boutique du prestataire piloté (écran V1 — FR-044). Chargement serveur
/// + gestes en UN appel : moule `AsyncNotifier`, `@riverpod` nu (autoDispose),
/// patron `MesAdresses` du cycle 003/004.

abstract class _$Boutique extends $AsyncNotifier<BoutiqueVendeur> {
  late final _$args = ref.$arg as String;
  String get prestataireId => _$args;

  FutureOr<BoutiqueVendeur> build(String prestataireId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<BoutiqueVendeur>, BoutiqueVendeur>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<BoutiqueVendeur>, BoutiqueVendeur>,
              AsyncValue<BoutiqueVendeur>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
