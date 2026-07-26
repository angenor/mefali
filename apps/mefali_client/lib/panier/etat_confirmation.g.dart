// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'etat_confirmation.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Porteur de la saisie d'adresse et de paiement.
///
/// `keepAlive` explicite (constitution XII) : la saisie traverse l'aller-retour
/// vers la carte et le carnet d'adresses. Sans cela, choisir une adresse
/// enregistrée effacerait le mode de paiement déjà sélectionné.

@ProviderFor(Confirmation)
final confirmationProvider = ConfirmationProvider._();

/// Porteur de la saisie d'adresse et de paiement.
///
/// `keepAlive` explicite (constitution XII) : la saisie traverse l'aller-retour
/// vers la carte et le carnet d'adresses. Sans cela, choisir une adresse
/// enregistrée effacerait le mode de paiement déjà sélectionné.
final class ConfirmationProvider
    extends $NotifierProvider<Confirmation, EtatConfirmation> {
  /// Porteur de la saisie d'adresse et de paiement.
  ///
  /// `keepAlive` explicite (constitution XII) : la saisie traverse l'aller-retour
  /// vers la carte et le carnet d'adresses. Sans cela, choisir une adresse
  /// enregistrée effacerait le mode de paiement déjà sélectionné.
  ConfirmationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'confirmationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$confirmationHash();

  @$internal
  @override
  Confirmation create() => Confirmation();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EtatConfirmation value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EtatConfirmation>(value),
    );
  }
}

String _$confirmationHash() => r'462146036aced281458b577ff0a2b8299b8f8e18';

/// Porteur de la saisie d'adresse et de paiement.
///
/// `keepAlive` explicite (constitution XII) : la saisie traverse l'aller-retour
/// vers la carte et le carnet d'adresses. Sans cela, choisir une adresse
/// enregistrée effacerait le mode de paiement déjà sélectionné.

abstract class _$Confirmation extends $Notifier<EtatConfirmation> {
  EtatConfirmation build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<EtatConfirmation, EtatConfirmation>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EtatConfirmation, EtatConfirmation>,
              EtatConfirmation,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
