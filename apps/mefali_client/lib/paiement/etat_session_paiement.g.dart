// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'etat_session_paiement.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Porteur de la session de paiement d'UNE commande.
///
/// `keepAlive` **explicite** (constitution XII), comme `Confirmation` : l'état
/// est posé par `ActionsCommande` juste après l'ouverture de session, et il doit
/// survivre à la transition de navigation qui amène l'écran de règlement. Une
/// portée auto-disposée le perdrait entre les deux et l'écran s'ouvrirait vide.
///
/// Le minuteur, lui, ne survit à rien : il s'arrête tout seul à zéro, à la
/// première issue non payable, et sur [liberer] quand l'écran se ferme.
///
/// ⚠ Ce porteur ne **charge** rien : il n'a donc pas de source injectée par la
/// portée, contrairement à `Suivi`. Écrire un `sourceSessionPaiementProvider`
/// qui lèverait par défaut et que personne ne lirait aurait été une façade.

@ProviderFor(SessionPaiement)
final sessionPaiementProvider = SessionPaiementFamily._();

/// Porteur de la session de paiement d'UNE commande.
///
/// `keepAlive` **explicite** (constitution XII), comme `Confirmation` : l'état
/// est posé par `ActionsCommande` juste après l'ouverture de session, et il doit
/// survivre à la transition de navigation qui amène l'écran de règlement. Une
/// portée auto-disposée le perdrait entre les deux et l'écran s'ouvrirait vide.
///
/// Le minuteur, lui, ne survit à rien : il s'arrête tout seul à zéro, à la
/// première issue non payable, et sur [liberer] quand l'écran se ferme.
///
/// ⚠ Ce porteur ne **charge** rien : il n'a donc pas de source injectée par la
/// portée, contrairement à `Suivi`. Écrire un `sourceSessionPaiementProvider`
/// qui lèverait par défaut et que personne ne lirait aurait été une façade.
final class SessionPaiementProvider
    extends $NotifierProvider<SessionPaiement, EtatSessionPaiement?> {
  /// Porteur de la session de paiement d'UNE commande.
  ///
  /// `keepAlive` **explicite** (constitution XII), comme `Confirmation` : l'état
  /// est posé par `ActionsCommande` juste après l'ouverture de session, et il doit
  /// survivre à la transition de navigation qui amène l'écran de règlement. Une
  /// portée auto-disposée le perdrait entre les deux et l'écran s'ouvrirait vide.
  ///
  /// Le minuteur, lui, ne survit à rien : il s'arrête tout seul à zéro, à la
  /// première issue non payable, et sur [liberer] quand l'écran se ferme.
  ///
  /// ⚠ Ce porteur ne **charge** rien : il n'a donc pas de source injectée par la
  /// portée, contrairement à `Suivi`. Écrire un `sourceSessionPaiementProvider`
  /// qui lèverait par défaut et que personne ne lirait aurait été une façade.
  SessionPaiementProvider._({
    required SessionPaiementFamily super.from,
    required String super.argument,
  }) : super(
         retry: pasDeRetry,
         name: r'sessionPaiementProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sessionPaiementHash();

  @override
  String toString() {
    return r'sessionPaiementProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SessionPaiement create() => SessionPaiement();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EtatSessionPaiement? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EtatSessionPaiement?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SessionPaiementProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sessionPaiementHash() => r'd761d0161a4c8eb4f46d139699b386dbc40945c6';

/// Porteur de la session de paiement d'UNE commande.
///
/// `keepAlive` **explicite** (constitution XII), comme `Confirmation` : l'état
/// est posé par `ActionsCommande` juste après l'ouverture de session, et il doit
/// survivre à la transition de navigation qui amène l'écran de règlement. Une
/// portée auto-disposée le perdrait entre les deux et l'écran s'ouvrirait vide.
///
/// Le minuteur, lui, ne survit à rien : il s'arrête tout seul à zéro, à la
/// première issue non payable, et sur [liberer] quand l'écran se ferme.
///
/// ⚠ Ce porteur ne **charge** rien : il n'a donc pas de source injectée par la
/// portée, contrairement à `Suivi`. Écrire un `sourceSessionPaiementProvider`
/// qui lèverait par défaut et que personne ne lirait aurait été une façade.

final class SessionPaiementFamily extends $Family
    with
        $ClassFamilyOverride<
          SessionPaiement,
          EtatSessionPaiement?,
          EtatSessionPaiement?,
          EtatSessionPaiement?,
          String
        > {
  SessionPaiementFamily._()
    : super(
        retry: pasDeRetry,
        name: r'sessionPaiementProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Porteur de la session de paiement d'UNE commande.
  ///
  /// `keepAlive` **explicite** (constitution XII), comme `Confirmation` : l'état
  /// est posé par `ActionsCommande` juste après l'ouverture de session, et il doit
  /// survivre à la transition de navigation qui amène l'écran de règlement. Une
  /// portée auto-disposée le perdrait entre les deux et l'écran s'ouvrirait vide.
  ///
  /// Le minuteur, lui, ne survit à rien : il s'arrête tout seul à zéro, à la
  /// première issue non payable, et sur [liberer] quand l'écran se ferme.
  ///
  /// ⚠ Ce porteur ne **charge** rien : il n'a donc pas de source injectée par la
  /// portée, contrairement à `Suivi`. Écrire un `sourceSessionPaiementProvider`
  /// qui lèverait par défaut et que personne ne lirait aurait été une façade.

  SessionPaiementProvider call(String commandeId) =>
      SessionPaiementProvider._(argument: commandeId, from: this);

  @override
  String toString() => r'sessionPaiementProvider';
}

/// Porteur de la session de paiement d'UNE commande.
///
/// `keepAlive` **explicite** (constitution XII), comme `Confirmation` : l'état
/// est posé par `ActionsCommande` juste après l'ouverture de session, et il doit
/// survivre à la transition de navigation qui amène l'écran de règlement. Une
/// portée auto-disposée le perdrait entre les deux et l'écran s'ouvrirait vide.
///
/// Le minuteur, lui, ne survit à rien : il s'arrête tout seul à zéro, à la
/// première issue non payable, et sur [liberer] quand l'écran se ferme.
///
/// ⚠ Ce porteur ne **charge** rien : il n'a donc pas de source injectée par la
/// portée, contrairement à `Suivi`. Écrire un `sourceSessionPaiementProvider`
/// qui lèverait par défaut et que personne ne lirait aurait été une façade.

abstract class _$SessionPaiement extends $Notifier<EtatSessionPaiement?> {
  late final _$args = ref.$arg as String;
  String get commandeId => _$args;

  EtatSessionPaiement? build(String commandeId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<EtatSessionPaiement?, EtatSessionPaiement?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EtatSessionPaiement?, EtatSessionPaiement?>,
              EtatSessionPaiement?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
