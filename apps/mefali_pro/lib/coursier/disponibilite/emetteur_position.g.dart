// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emetteur_position.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Permet à un test d'injecter un flux de positions déterministe.
///
/// `dependencies: []` la déclare **surchargeable par portée** : sans cette
/// déclaration, un `ProviderScope` imbriqué qui la surcharge serait ignoré —
/// Riverpod hébergerait l'émetteur dans le conteneur parent, où l'override
/// n'existe pas, et un test widget ouvrirait le vrai capteur.

@ProviderFor(sourcePositions)
final sourcePositionsProvider = SourcePositionsProvider._();

/// Permet à un test d'injecter un flux de positions déterministe.
///
/// `dependencies: []` la déclare **surchargeable par portée** : sans cette
/// déclaration, un `ProviderScope` imbriqué qui la surcharge serait ignoré —
/// Riverpod hébergerait l'émetteur dans le conteneur parent, où l'override
/// n'existe pas, et un test widget ouvrirait le vrai capteur.

final class SourcePositionsProvider
    extends $FunctionalProvider<FluxPositions, FluxPositions, FluxPositions>
    with $Provider<FluxPositions> {
  /// Permet à un test d'injecter un flux de positions déterministe.
  ///
  /// `dependencies: []` la déclare **surchargeable par portée** : sans cette
  /// déclaration, un `ProviderScope` imbriqué qui la surcharge serait ignoré —
  /// Riverpod hébergerait l'émetteur dans le conteneur parent, où l'override
  /// n'existe pas, et un test widget ouvrirait le vrai capteur.
  SourcePositionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sourcePositionsProvider',
        isAutoDispose: false,
        dependencies: <ProviderOrFamily>[],
        $allTransitiveDependencies: <ProviderOrFamily>[],
      );

  @override
  String debugGetCreateSourceHash() => _$sourcePositionsHash();

  @$internal
  @override
  $ProviderElement<FluxPositions> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FluxPositions create(Ref ref) {
    return sourcePositions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FluxPositions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FluxPositions>(value),
    );
  }
}

String _$sourcePositionsHash() => r'7099b325eea74d3d5696a1437bd6c44fa5f4b541';

/// Permet à un test de court-circuiter la demande de permission.
///
/// Même raison que [sourcePositions], et même `dependencies: []` : sans cette
/// déclaration, un `ProviderScope` imbriqué qui la surcharge serait ignoré.

@ProviderFor(permissionPosition)
final permissionPositionProvider = PermissionPositionProvider._();

/// Permet à un test de court-circuiter la demande de permission.
///
/// Même raison que [sourcePositions], et même `dependencies: []` : sans cette
/// déclaration, un `ProviderScope` imbriqué qui la surcharge serait ignoré.

final class PermissionPositionProvider
    extends
        $FunctionalProvider<
          DemandePermission,
          DemandePermission,
          DemandePermission
        >
    with $Provider<DemandePermission> {
  /// Permet à un test de court-circuiter la demande de permission.
  ///
  /// Même raison que [sourcePositions], et même `dependencies: []` : sans cette
  /// déclaration, un `ProviderScope` imbriqué qui la surcharge serait ignoré.
  PermissionPositionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'permissionPositionProvider',
        isAutoDispose: false,
        dependencies: <ProviderOrFamily>[],
        $allTransitiveDependencies: <ProviderOrFamily>[],
      );

  @override
  String debugGetCreateSourceHash() => _$permissionPositionHash();

  @$internal
  @override
  $ProviderElement<DemandePermission> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DemandePermission create(Ref ref) {
    return permissionPosition(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DemandePermission value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DemandePermission>(value),
    );
  }
}

String _$permissionPositionHash() =>
    r'3cfe2e984fd6dff9d6619f8f7802db3dd8c5ee69';

/// Permet à un test de fournir un relevé ponctuel déterministe.

@ProviderFor(relevePonctuel)
final relevePonctuelProvider = RelevePonctuelProvider._();

/// Permet à un test de fournir un relevé ponctuel déterministe.

final class RelevePonctuelProvider
    extends
        $FunctionalProvider<
          PositionPonctuelle,
          PositionPonctuelle,
          PositionPonctuelle
        >
    with $Provider<PositionPonctuelle> {
  /// Permet à un test de fournir un relevé ponctuel déterministe.
  RelevePonctuelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'relevePonctuelProvider',
        isAutoDispose: false,
        dependencies: <ProviderOrFamily>[],
        $allTransitiveDependencies: <ProviderOrFamily>[],
      );

  @override
  String debugGetCreateSourceHash() => _$relevePonctuelHash();

  @$internal
  @override
  $ProviderElement<PositionPonctuelle> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PositionPonctuelle create(Ref ref) {
    return relevePonctuel(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PositionPonctuelle value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PositionPonctuelle>(value),
    );
  }
}

String _$relevePonctuelHash() => r'43fca94f39877169804ce4236093bf6769d18b28';

/// Émetteur de position — **jetable** (`@riverpod` nu, autoDispose) : il ne vit
/// que tant qu'un écran de dispatch l'observe.
///
/// C'est délibérément l'inverse du porteur de disponibilité, qui est
/// `keepAlive` : l'INTENTION d'être en ligne traverse les écrans, la
/// PUBLICATION ne le peut pas (constitution XII, deux moules opposés).

@ProviderFor(EmetteurPosition)
final emetteurPositionProvider = EmetteurPositionProvider._();

/// Émetteur de position — **jetable** (`@riverpod` nu, autoDispose) : il ne vit
/// que tant qu'un écran de dispatch l'observe.
///
/// C'est délibérément l'inverse du porteur de disponibilité, qui est
/// `keepAlive` : l'INTENTION d'être en ligne traverse les écrans, la
/// PUBLICATION ne le peut pas (constitution XII, deux moules opposés).
final class EmetteurPositionProvider
    extends $NotifierProvider<EmetteurPosition, int> {
  /// Émetteur de position — **jetable** (`@riverpod` nu, autoDispose) : il ne vit
  /// que tant qu'un écran de dispatch l'observe.
  ///
  /// C'est délibérément l'inverse du porteur de disponibilité, qui est
  /// `keepAlive` : l'INTENTION d'être en ligne traverse les écrans, la
  /// PUBLICATION ne le peut pas (constitution XII, deux moules opposés).
  EmetteurPositionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'emetteurPositionProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[
          sourcePositionsProvider,
          permissionPositionProvider,
          relevePonctuelProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>[
          EmetteurPositionProvider.$allTransitiveDependencies0,
          EmetteurPositionProvider.$allTransitiveDependencies1,
          EmetteurPositionProvider.$allTransitiveDependencies2,
        ],
      );

  static final $allTransitiveDependencies0 = sourcePositionsProvider;
  static final $allTransitiveDependencies1 = permissionPositionProvider;
  static final $allTransitiveDependencies2 = relevePonctuelProvider;

  @override
  String debugGetCreateSourceHash() => _$emetteurPositionHash();

  @$internal
  @override
  EmetteurPosition create() => EmetteurPosition();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$emetteurPositionHash() => r'970cf311a02f6c517ee45de36835ea110fb1c695';

/// Émetteur de position — **jetable** (`@riverpod` nu, autoDispose) : il ne vit
/// que tant qu'un écran de dispatch l'observe.
///
/// C'est délibérément l'inverse du porteur de disponibilité, qui est
/// `keepAlive` : l'INTENTION d'être en ligne traverse les écrans, la
/// PUBLICATION ne le peut pas (constitution XII, deux moules opposés).

abstract class _$EmetteurPosition extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
