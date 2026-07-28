// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'etat_panier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Porteur du panier en cours de composition.
///
/// `keepAlive` explicite (constitution XII) : le panier traverse la navigation.

@ProviderFor(Panier)
final panierProvider = PanierProvider._();

/// Porteur du panier en cours de composition.
///
/// `keepAlive` explicite (constitution XII) : le panier traverse la navigation.
final class PanierProvider extends $NotifierProvider<Panier, EtatPanier> {
  /// Porteur du panier en cours de composition.
  ///
  /// `keepAlive` explicite (constitution XII) : le panier traverse la navigation.
  PanierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'panierProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$panierHash();

  @$internal
  @override
  Panier create() => Panier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EtatPanier value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EtatPanier>(value),
    );
  }
}

String _$panierHash() => r'64826041998debda8050bc5a5c60edcaa79d9628';

/// Porteur du panier en cours de composition.
///
/// `keepAlive` explicite (constitution XII) : le panier traverse la navigation.

abstract class _$Panier extends $Notifier<EtatPanier> {
  EtatPanier build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<EtatPanier, EtatPanier>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EtatPanier, EtatPanier>,
              EtatPanier,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
