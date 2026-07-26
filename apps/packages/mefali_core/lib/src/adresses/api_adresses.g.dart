// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_adresses.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// La couche d'appel des adresses, sur le client PORTEUR de session.

@ProviderFor(adressesApi)
final adressesApiProvider = AdressesApiProvider._();

/// La couche d'appel des adresses, sur le client PORTEUR de session.

final class AdressesApiProvider
    extends $FunctionalProvider<AdressesApi, AdressesApi, AdressesApi>
    with $Provider<AdressesApi> {
  /// La couche d'appel des adresses, sur le client PORTEUR de session.
  AdressesApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adressesApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adressesApiHash();

  @$internal
  @override
  $ProviderElement<AdressesApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AdressesApi create(Ref ref) {
    return adressesApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdressesApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdressesApi>(value),
    );
  }
}

String _$adressesApiHash() => r'af5c731ec08b425de90459afd821db76d02f026f';
