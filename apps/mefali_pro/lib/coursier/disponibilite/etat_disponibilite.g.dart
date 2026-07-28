// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'etat_disponibilite.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Porteur de la disponibilité — **vit tant que l'app vit**.

@ProviderFor(Disponibilite)
final disponibiliteProvider = DisponibiliteProvider._();

/// Porteur de la disponibilité — **vit tant que l'app vit**.
final class DisponibiliteProvider
    extends $NotifierProvider<Disponibilite, EtatDisponibilite> {
  /// Porteur de la disponibilité — **vit tant que l'app vit**.
  DisponibiliteProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'disponibiliteProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$disponibiliteHash();

  @$internal
  @override
  Disponibilite create() => Disponibilite();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EtatDisponibilite value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EtatDisponibilite>(value),
    );
  }
}

String _$disponibiliteHash() => r'e97a59894d83c5652d79aad54c83880582fc4577';

/// Porteur de la disponibilité — **vit tant que l'app vit**.

abstract class _$Disponibilite extends $Notifier<EtatDisponibilite> {
  EtatDisponibilite build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<EtatDisponibilite, EtatDisponibilite>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EtatDisponibilite, EtatDisponibilite>,
              EtatDisponibilite,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
