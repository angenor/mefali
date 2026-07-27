// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_dispatch.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// La couche d'appel dispatch, construite sur le client PORTEUR de session —
/// toutes ces routes exigent `Authorization` et le rôle coursier.

@ProviderFor(dispatchApi)
final dispatchApiProvider = DispatchApiProvider._();

/// La couche d'appel dispatch, construite sur le client PORTEUR de session —
/// toutes ces routes exigent `Authorization` et le rôle coursier.

final class DispatchApiProvider
    extends $FunctionalProvider<DispatchApi, DispatchApi, DispatchApi>
    with $Provider<DispatchApi> {
  /// La couche d'appel dispatch, construite sur le client PORTEUR de session —
  /// toutes ces routes exigent `Authorization` et le rôle coursier.
  DispatchApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dispatchApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dispatchApiHash();

  @$internal
  @override
  $ProviderElement<DispatchApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DispatchApi create(Ref ref) {
    return dispatchApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DispatchApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DispatchApi>(value),
    );
  }
}

String _$dispatchApiHash() => r'956302b083c624b601573f94f0a12d5ad2dcff39';
