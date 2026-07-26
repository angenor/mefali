// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cache_commandes.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Cache des commandes du client — durée de vie du processus (`keepAlive`),
/// comme la base qu'il enveloppe.

@ProviderFor(cacheCommandes)
final cacheCommandesProvider = CacheCommandesProvider._();

/// Cache des commandes du client — durée de vie du processus (`keepAlive`),
/// comme la base qu'il enveloppe.

final class CacheCommandesProvider
    extends $FunctionalProvider<CacheCommandes, CacheCommandes, CacheCommandes>
    with $Provider<CacheCommandes> {
  /// Cache des commandes du client — durée de vie du processus (`keepAlive`),
  /// comme la base qu'il enveloppe.
  CacheCommandesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cacheCommandesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cacheCommandesHash();

  @$internal
  @override
  $ProviderElement<CacheCommandes> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CacheCommandes create(Ref ref) {
    return cacheCommandes(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CacheCommandes value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CacheCommandes>(value),
    );
  }
}

String _$cacheCommandesHash() => r'e22fa1e6eccfaa6f70da4a909ce228eebe6f4e96';
