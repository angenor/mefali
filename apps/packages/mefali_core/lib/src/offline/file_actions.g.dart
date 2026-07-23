// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_actions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Base drift de la file offline — durée de vie du processus (`keepAlive`).
/// Surchargée en test par une base mémoire.

@ProviderFor(baseOffline)
final baseOfflineProvider = BaseOfflineProvider._();

/// Base drift de la file offline — durée de vie du processus (`keepAlive`).
/// Surchargée en test par une base mémoire.

final class BaseOfflineProvider
    extends $FunctionalProvider<BaseOffline, BaseOffline, BaseOffline>
    with $Provider<BaseOffline> {
  /// Base drift de la file offline — durée de vie du processus (`keepAlive`).
  /// Surchargée en test par une base mémoire.
  BaseOfflineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'baseOfflineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$baseOfflineHash();

  @$internal
  @override
  $ProviderElement<BaseOffline> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BaseOffline create(Ref ref) {
    return baseOffline(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BaseOffline value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BaseOffline>(value),
    );
  }
}

String _$baseOfflineHash() => r'2c83c5dd0e773e80bd40dc539f076e6ed98a510a';

/// File d'actions coursier idempotente + cache de course pré-provisionné.

@ProviderFor(fileActions)
final fileActionsProvider = FileActionsProvider._();

/// File d'actions coursier idempotente + cache de course pré-provisionné.

final class FileActionsProvider
    extends $FunctionalProvider<FileActions, FileActions, FileActions>
    with $Provider<FileActions> {
  /// File d'actions coursier idempotente + cache de course pré-provisionné.
  FileActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fileActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fileActionsHash();

  @$internal
  @override
  $ProviderElement<FileActions> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FileActions create(Ref ref) {
    return fileActions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FileActions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FileActions>(value),
    );
  }
}

String _$fileActionsHash() => r'ff3f9da3cc2298d63be4c6a87018164da4640c13';
