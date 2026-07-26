// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_commandes.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// La couche d'appel commandes, construite sur le client PORTEUR de session —
/// toutes ces routes exigent `Authorization` (constitution VIII).

@ProviderFor(commandesApi)
final commandesApiProvider = CommandesApiProvider._();

/// La couche d'appel commandes, construite sur le client PORTEUR de session —
/// toutes ces routes exigent `Authorization` (constitution VIII).

final class CommandesApiProvider
    extends $FunctionalProvider<CommandesApi, CommandesApi, CommandesApi>
    with $Provider<CommandesApi> {
  /// La couche d'appel commandes, construite sur le client PORTEUR de session —
  /// toutes ces routes exigent `Authorization` (constitution VIII).
  CommandesApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'commandesApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$commandesApiHash();

  @$internal
  @override
  $ProviderElement<CommandesApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CommandesApi create(Ref ref) {
    return commandesApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CommandesApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CommandesApi>(value),
    );
  }
}

String _$commandesApiHash() => r'23c8541b9396addd34d92cc15bc9e53a158945fb';
