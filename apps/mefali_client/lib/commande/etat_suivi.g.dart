// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'etat_suivi.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Source du suivi — **injectée par la PORTÉE** (constitution XII).
///
/// `throw` par défaut, comme `urlApiProvider` : le porteur d'état ne construit
/// pas son transport, il le reçoit. C'est ce qui permet au test widget de
/// servir une vue figée sans réseau, et à l'app de brancher le client généré,
/// sans qu'aucun des deux ne connaisse l'autre.

@ProviderFor(sourceSuivi)
final sourceSuiviProvider = SourceSuiviProvider._();

/// Source du suivi — **injectée par la PORTÉE** (constitution XII).
///
/// `throw` par défaut, comme `urlApiProvider` : le porteur d'état ne construit
/// pas son transport, il le reçoit. C'est ce qui permet au test widget de
/// servir une vue figée sans réseau, et à l'app de brancher le client généré,
/// sans qu'aucun des deux ne connaisse l'autre.

final class SourceSuiviProvider
    extends
        $FunctionalProvider<
          Future<EtatSuivi> Function(String commandeId),
          Future<EtatSuivi> Function(String commandeId),
          Future<EtatSuivi> Function(String commandeId)
        >
    with $Provider<Future<EtatSuivi> Function(String commandeId)> {
  /// Source du suivi — **injectée par la PORTÉE** (constitution XII).
  ///
  /// `throw` par défaut, comme `urlApiProvider` : le porteur d'état ne construit
  /// pas son transport, il le reçoit. C'est ce qui permet au test widget de
  /// servir une vue figée sans réseau, et à l'app de brancher le client généré,
  /// sans qu'aucun des deux ne connaisse l'autre.
  SourceSuiviProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sourceSuiviProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sourceSuiviHash();

  @$internal
  @override
  $ProviderElement<Future<EtatSuivi> Function(String commandeId)>
  $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  Future<EtatSuivi> Function(String commandeId) create(Ref ref) {
    return sourceSuivi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(
    Future<EtatSuivi> Function(String commandeId) value,
  ) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<Future<EtatSuivi> Function(String commandeId)>(
            value,
          ),
    );
  }
}

String _$sourceSuiviHash() => r'935ab00d7a16beacc940dc2a33efed00f350c502';

/// Porteur du suivi d'UNE commande.
///
/// `@Riverpod` **auto-dispose** (durée de vie EXPLICITE, constitution XII) : un
/// suivi ne survit pas à la fermeture de son écran. Le garder vivant
/// entretiendrait un rafraîchissement pour une commande que le client ne
/// regarde plus — de la batterie et de la data dépensées pour rien, sur des
/// téléphones où les deux comptent.

@ProviderFor(Suivi)
final suiviProvider = SuiviFamily._();

/// Porteur du suivi d'UNE commande.
///
/// `@Riverpod` **auto-dispose** (durée de vie EXPLICITE, constitution XII) : un
/// suivi ne survit pas à la fermeture de son écran. Le garder vivant
/// entretiendrait un rafraîchissement pour une commande que le client ne
/// regarde plus — de la batterie et de la data dépensées pour rien, sur des
/// téléphones où les deux comptent.
final class SuiviProvider extends $AsyncNotifierProvider<Suivi, EtatSuivi> {
  /// Porteur du suivi d'UNE commande.
  ///
  /// `@Riverpod` **auto-dispose** (durée de vie EXPLICITE, constitution XII) : un
  /// suivi ne survit pas à la fermeture de son écran. Le garder vivant
  /// entretiendrait un rafraîchissement pour une commande que le client ne
  /// regarde plus — de la batterie et de la data dépensées pour rien, sur des
  /// téléphones où les deux comptent.
  SuiviProvider._({
    required SuiviFamily super.from,
    required String super.argument,
  }) : super(
         retry: pasDeRetry,
         name: r'suiviProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$suiviHash();

  @override
  String toString() {
    return r'suiviProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  Suivi create() => Suivi();

  @override
  bool operator ==(Object other) {
    return other is SuiviProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$suiviHash() => r'9c4b17501875031b406320c0775c1ff42fd04fcf';

/// Porteur du suivi d'UNE commande.
///
/// `@Riverpod` **auto-dispose** (durée de vie EXPLICITE, constitution XII) : un
/// suivi ne survit pas à la fermeture de son écran. Le garder vivant
/// entretiendrait un rafraîchissement pour une commande que le client ne
/// regarde plus — de la batterie et de la data dépensées pour rien, sur des
/// téléphones où les deux comptent.

final class SuiviFamily extends $Family
    with
        $ClassFamilyOverride<
          Suivi,
          AsyncValue<EtatSuivi>,
          EtatSuivi,
          FutureOr<EtatSuivi>,
          String
        > {
  SuiviFamily._()
    : super(
        retry: pasDeRetry,
        name: r'suiviProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Porteur du suivi d'UNE commande.
  ///
  /// `@Riverpod` **auto-dispose** (durée de vie EXPLICITE, constitution XII) : un
  /// suivi ne survit pas à la fermeture de son écran. Le garder vivant
  /// entretiendrait un rafraîchissement pour une commande que le client ne
  /// regarde plus — de la batterie et de la data dépensées pour rien, sur des
  /// téléphones où les deux comptent.

  SuiviProvider call(String commandeId) =>
      SuiviProvider._(argument: commandeId, from: this);

  @override
  String toString() => r'suiviProvider';
}

/// Porteur du suivi d'UNE commande.
///
/// `@Riverpod` **auto-dispose** (durée de vie EXPLICITE, constitution XII) : un
/// suivi ne survit pas à la fermeture de son écran. Le garder vivant
/// entretiendrait un rafraîchissement pour une commande que le client ne
/// regarde plus — de la batterie et de la data dépensées pour rien, sur des
/// téléphones où les deux comptent.

abstract class _$Suivi extends $AsyncNotifier<EtatSuivi> {
  late final _$args = ref.$arg as String;
  String get commandeId => _$args;

  FutureOr<EtatSuivi> build(String commandeId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<EtatSuivi>, EtatSuivi>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<EtatSuivi>, EtatSuivi>,
              AsyncValue<EtatSuivi>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
