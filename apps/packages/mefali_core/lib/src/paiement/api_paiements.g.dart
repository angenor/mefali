// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_paiements.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// La couche d'appel paiements, sur le client PORTEUR de session.

@ProviderFor(paiementsApi)
final paiementsApiProvider = PaiementsApiProvider._();

/// La couche d'appel paiements, sur le client PORTEUR de session.

final class PaiementsApiProvider
    extends $FunctionalProvider<PaiementsApi, PaiementsApi, PaiementsApi>
    with $Provider<PaiementsApi> {
  /// La couche d'appel paiements, sur le client PORTEUR de session.
  PaiementsApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'paiementsApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$paiementsApiHash();

  @$internal
  @override
  $ProviderElement<PaiementsApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PaiementsApi create(Ref ref) {
    return paiementsApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PaiementsApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PaiementsApi>(value),
    );
  }
}

String _$paiementsApiHash() => r'0f4543fae5f82eb482937940e425e7ab799c2906';
