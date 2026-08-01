// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'etat_offre_livraison.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Le réglage d'**offre de livraison** d'un vendeur (VND-08 minimal, FR-046).
///
/// `@riverpod` nu (autoDispose) : geste d'écran, aucun état à faire survivre à
/// la fermeture de la feuille. La valeur courante vit sur `PrestatairePilotable`
/// — la relire ici serait une seconde source de vérité pour deux scalaires.

@ProviderFor(OffreLivraison)
final offreLivraisonProvider = OffreLivraisonFamily._();

/// Le réglage d'**offre de livraison** d'un vendeur (VND-08 minimal, FR-046).
///
/// `@riverpod` nu (autoDispose) : geste d'écran, aucun état à faire survivre à
/// la fermeture de la feuille. La valeur courante vit sur `PrestatairePilotable`
/// — la relire ici serait une seconde source de vérité pour deux scalaires.
final class OffreLivraisonProvider
    extends $NotifierProvider<OffreLivraison, void> {
  /// Le réglage d'**offre de livraison** d'un vendeur (VND-08 minimal, FR-046).
  ///
  /// `@riverpod` nu (autoDispose) : geste d'écran, aucun état à faire survivre à
  /// la fermeture de la feuille. La valeur courante vit sur `PrestatairePilotable`
  /// — la relire ici serait une seconde source de vérité pour deux scalaires.
  OffreLivraisonProvider._({
    required OffreLivraisonFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'offreLivraisonProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$offreLivraisonHash();

  @override
  String toString() {
    return r'offreLivraisonProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  OffreLivraison create() => OffreLivraison();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is OffreLivraisonProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$offreLivraisonHash() => r'1350f2ca5be7c14d1721e0331bbfe4214d8547c4';

/// Le réglage d'**offre de livraison** d'un vendeur (VND-08 minimal, FR-046).
///
/// `@riverpod` nu (autoDispose) : geste d'écran, aucun état à faire survivre à
/// la fermeture de la feuille. La valeur courante vit sur `PrestatairePilotable`
/// — la relire ici serait une seconde source de vérité pour deux scalaires.

final class OffreLivraisonFamily extends $Family
    with $ClassFamilyOverride<OffreLivraison, void, void, void, String> {
  OffreLivraisonFamily._()
    : super(
        retry: null,
        name: r'offreLivraisonProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Le réglage d'**offre de livraison** d'un vendeur (VND-08 minimal, FR-046).
  ///
  /// `@riverpod` nu (autoDispose) : geste d'écran, aucun état à faire survivre à
  /// la fermeture de la feuille. La valeur courante vit sur `PrestatairePilotable`
  /// — la relire ici serait une seconde source de vérité pour deux scalaires.

  OffreLivraisonProvider call(String prestataireId) =>
      OffreLivraisonProvider._(argument: prestataireId, from: this);

  @override
  String toString() => r'offreLivraisonProvider';
}

/// Le réglage d'**offre de livraison** d'un vendeur (VND-08 minimal, FR-046).
///
/// `@riverpod` nu (autoDispose) : geste d'écran, aucun état à faire survivre à
/// la fermeture de la feuille. La valeur courante vit sur `PrestatairePilotable`
/// — la relire ici serait une seconde source de vérité pour deux scalaires.

abstract class _$OffreLivraison extends $Notifier<void> {
  late final _$args = ref.$arg as String;
  String get prestataireId => _$args;

  void build(String prestataireId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
