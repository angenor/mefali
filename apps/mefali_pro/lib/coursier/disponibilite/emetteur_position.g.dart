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
        dependencies: <ProviderOrFamily>[sourcePositionsProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          EmetteurPositionProvider.$allTransitiveDependencies0,
        ],
      );

  static final $allTransitiveDependencies0 = sourcePositionsProvider;

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

String _$emetteurPositionHash() => r'418ccc3294b1c37259809ddee3fdfd575690f16f';

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
