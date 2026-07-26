// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'actions_commande.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Position GPS de l'appareil — **injectée par la PORTÉE** (constitution XII).
///
/// Un provider, et non un appel direct à `Geolocator` depuis l'écran : c'est ce
/// qui permet aux tests de servir un pin sans toucher au canal de plateforme
/// (FR-039). Rend `null` quand la permission est refusée ou le service coupé —
/// jamais une position inventée.

@ProviderFor(positionAppareil)
final positionAppareilProvider = PositionAppareilProvider._();

/// Position GPS de l'appareil — **injectée par la PORTÉE** (constitution XII).
///
/// Un provider, et non un appel direct à `Geolocator` depuis l'écran : c'est ce
/// qui permet aux tests de servir un pin sans toucher au canal de plateforme
/// (FR-039). Rend `null` quand la permission est refusée ou le service coupé —
/// jamais une position inventée.

final class PositionAppareilProvider
    extends
        $FunctionalProvider<
          Future<({double lat, double lon})?> Function(),
          Future<({double lat, double lon})?> Function(),
          Future<({double lat, double lon})?> Function()
        >
    with $Provider<Future<({double lat, double lon})?> Function()> {
  /// Position GPS de l'appareil — **injectée par la PORTÉE** (constitution XII).
  ///
  /// Un provider, et non un appel direct à `Geolocator` depuis l'écran : c'est ce
  /// qui permet aux tests de servir un pin sans toucher au canal de plateforme
  /// (FR-039). Rend `null` quand la permission est refusée ou le service coupé —
  /// jamais une position inventée.
  PositionAppareilProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'positionAppareilProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$positionAppareilHash();

  @$internal
  @override
  $ProviderElement<Future<({double lat, double lon})?> Function()>
  $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  Future<({double lat, double lon})?> Function() create(Ref ref) {
    return positionAppareil(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(
    Future<({double lat, double lon})?> Function() value,
  ) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<Future<({double lat, double lon})?> Function()>(
            value,
          ),
    );
  }
}

String _$positionAppareilHash() => r'd131d39d14180153838ec407dd14614aaa9a71e0';

/// Les actions du parcours de commande. `keepAlive` : la clé d'idempotence
/// qu'elle détient doit survivre à la navigation entre panier et confirmation.

@ProviderFor(actionsCommande)
final actionsCommandeProvider = ActionsCommandeProvider._();

/// Les actions du parcours de commande. `keepAlive` : la clé d'idempotence
/// qu'elle détient doit survivre à la navigation entre panier et confirmation.

final class ActionsCommandeProvider
    extends
        $FunctionalProvider<ActionsCommande, ActionsCommande, ActionsCommande>
    with $Provider<ActionsCommande> {
  /// Les actions du parcours de commande. `keepAlive` : la clé d'idempotence
  /// qu'elle détient doit survivre à la navigation entre panier et confirmation.
  ActionsCommandeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'actionsCommandeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$actionsCommandeHash();

  @$internal
  @override
  $ProviderElement<ActionsCommande> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ActionsCommande create(Ref ref) {
    return actionsCommande(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ActionsCommande value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ActionsCommande>(value),
    );
  }
}

String _$actionsCommandeHash() => r'3dcbfa825ee9a1f5a5b0cef572822f5418c0b5ed';
