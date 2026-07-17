// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Le stockage sécurisé des jetons. Surchargé en test par `StockageJetonsMemoire`
/// (FR-035) — AUCUN canal de plateforme n'est simulé, on double la FONCTION, pas
/// le canal (FR-039). `keepAlive` : dépendance d'un porteur de processus.

@ProviderFor(stockageJetons)
final stockageJetonsProvider = StockageJetonsProvider._();

/// Le stockage sécurisé des jetons. Surchargé en test par `StockageJetonsMemoire`
/// (FR-035) — AUCUN canal de plateforme n'est simulé, on double la FONCTION, pas
/// le canal (FR-039). `keepAlive` : dépendance d'un porteur de processus.

final class StockageJetonsProvider
    extends $FunctionalProvider<StockageJetons, StockageJetons, StockageJetons>
    with $Provider<StockageJetons> {
  /// Le stockage sécurisé des jetons. Surchargé en test par `StockageJetonsMemoire`
  /// (FR-035) — AUCUN canal de plateforme n'est simulé, on double la FONCTION, pas
  /// le canal (FR-039). `keepAlive` : dépendance d'un porteur de processus.
  StockageJetonsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'stockageJetonsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$stockageJetonsHash();

  @$internal
  @override
  $ProviderElement<StockageJetons> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  StockageJetons create(Ref ref) {
    return stockageJetons(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StockageJetons value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StockageJetons>(value),
    );
  }
}

String _$stockageJetonsHash() => r'1e0fe3b19941b8cfc6d9fa8ad9aff76b1a3db429';

/// La session d'authentification. `keepAlive` : elle naît au lancement et vit
/// tout le processus (FR-019 ; `@riverpod` nu = mode de panne n°2).
///
/// NE dépend d'AUCUN provider de client : le renouvellement vit dans
/// l'intercepteur, qui capture le client de `clientSession`. Un
/// `ref.watch(clientSessionProvider)` ici serait une arête INUTILE — donc une
/// ré-évaluation de trop (R3).

@ProviderFor(Session)
final sessionProvider = SessionProvider._();

/// La session d'authentification. `keepAlive` : elle naît au lancement et vit
/// tout le processus (FR-019 ; `@riverpod` nu = mode de panne n°2).
///
/// NE dépend d'AUCUN provider de client : le renouvellement vit dans
/// l'intercepteur, qui capture le client de `clientSession`. Un
/// `ref.watch(clientSessionProvider)` ici serait une arête INUTILE — donc une
/// ré-évaluation de trop (R3).
final class SessionProvider extends $NotifierProvider<Session, EtatSession> {
  /// La session d'authentification. `keepAlive` : elle naît au lancement et vit
  /// tout le processus (FR-019 ; `@riverpod` nu = mode de panne n°2).
  ///
  /// NE dépend d'AUCUN provider de client : le renouvellement vit dans
  /// l'intercepteur, qui capture le client de `clientSession`. Un
  /// `ref.watch(clientSessionProvider)` ici serait une arête INUTILE — donc une
  /// ré-évaluation de trop (R3).
  SessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionHash();

  @$internal
  @override
  Session create() => Session();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EtatSession value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EtatSession>(value),
    );
  }
}

String _$sessionHash() => r'aac700ac4abdb7a300146071bfeb2938a31ddde2';

/// La session d'authentification. `keepAlive` : elle naît au lancement et vit
/// tout le processus (FR-019 ; `@riverpod` nu = mode de panne n°2).
///
/// NE dépend d'AUCUN provider de client : le renouvellement vit dans
/// l'intercepteur, qui capture le client de `clientSession`. Un
/// `ref.watch(clientSessionProvider)` ici serait une arête INUTILE — donc une
/// ré-évaluation de trop (R3).

abstract class _$Session extends $Notifier<EtatSession> {
  EtatSession build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<EtatSession, EtatSession>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EtatSession, EtatSession>,
              EtatSession,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
