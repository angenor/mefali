// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clients.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Le client HTTP PORTEUR d'`Authorization`, et le SEUL. Il pose l'unique
/// instance de `InterceptorAutorisation` de l'app (FR-013) et la retire à sa
/// destruction (FR-018).
///
/// `keepAlive` OBLIGATOIRE : sous `@riverpod` nu, une ré-évaluation empilerait un
/// 2ᵉ intercepteur ⇒ 2 renouvellements concurrents ⇒ jeton déjà tourné rejoué ⇒
/// vol présumé ⇒ session révoquée (mode de panne n°1). NI `dio:` NI
/// `interceptors:` : les délais 5000/3000 ms ne vivent que dans la branche par
/// défaut du client généré, et passer `interceptors:` REMPLACE les 4
/// intercepteurs générés au lieu de s'y ajouter (FR-017, R3).

@ProviderFor(clientSession)
final clientSessionProvider = ClientSessionProvider._();

/// Le client HTTP PORTEUR d'`Authorization`, et le SEUL. Il pose l'unique
/// instance de `InterceptorAutorisation` de l'app (FR-013) et la retire à sa
/// destruction (FR-018).
///
/// `keepAlive` OBLIGATOIRE : sous `@riverpod` nu, une ré-évaluation empilerait un
/// 2ᵉ intercepteur ⇒ 2 renouvellements concurrents ⇒ jeton déjà tourné rejoué ⇒
/// vol présumé ⇒ session révoquée (mode de panne n°1). NI `dio:` NI
/// `interceptors:` : les délais 5000/3000 ms ne vivent que dans la branche par
/// défaut du client généré, et passer `interceptors:` REMPLACE les 4
/// intercepteurs générés au lieu de s'y ajouter (FR-017, R3).

final class ClientSessionProvider
    extends
        $FunctionalProvider<MefaliApiClient, MefaliApiClient, MefaliApiClient>
    with $Provider<MefaliApiClient> {
  /// Le client HTTP PORTEUR d'`Authorization`, et le SEUL. Il pose l'unique
  /// instance de `InterceptorAutorisation` de l'app (FR-013) et la retire à sa
  /// destruction (FR-018).
  ///
  /// `keepAlive` OBLIGATOIRE : sous `@riverpod` nu, une ré-évaluation empilerait un
  /// 2ᵉ intercepteur ⇒ 2 renouvellements concurrents ⇒ jeton déjà tourné rejoué ⇒
  /// vol présumé ⇒ session révoquée (mode de panne n°1). NI `dio:` NI
  /// `interceptors:` : les délais 5000/3000 ms ne vivent que dans la branche par
  /// défaut du client généré, et passer `interceptors:` REMPLACE les 4
  /// intercepteurs générés au lieu de s'y ajouter (FR-017, R3).
  ClientSessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clientSessionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clientSessionHash();

  @$internal
  @override
  $ProviderElement<MefaliApiClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MefaliApiClient create(Ref ref) {
    return clientSession(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MefaliApiClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MefaliApiClient>(value),
    );
  }
}

String _$clientSessionHash() => r'99633ce1c4dddc3638f6b4ddf1c320b9df171f61';

/// Le client HTTP qui NE porte JAMAIS d'`Authorization` (FR-017). Deux clients
/// distincts, JAMAIS un : la garantie ne repose sur AUCUNE assertion runtime —
/// c'est une propriété du graphe, seul `clientSession` pose un intercepteur (R3).

@ProviderFor(clientConfig)
final clientConfigProvider = ClientConfigProvider._();

/// Le client HTTP qui NE porte JAMAIS d'`Authorization` (FR-017). Deux clients
/// distincts, JAMAIS un : la garantie ne repose sur AUCUNE assertion runtime —
/// c'est une propriété du graphe, seul `clientSession` pose un intercepteur (R3).

final class ClientConfigProvider
    extends
        $FunctionalProvider<MefaliApiClient, MefaliApiClient, MefaliApiClient>
    with $Provider<MefaliApiClient> {
  /// Le client HTTP qui NE porte JAMAIS d'`Authorization` (FR-017). Deux clients
  /// distincts, JAMAIS un : la garantie ne repose sur AUCUNE assertion runtime —
  /// c'est une propriété du graphe, seul `clientSession` pose un intercepteur (R3).
  ClientConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clientConfigProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clientConfigHash();

  @$internal
  @override
  $ProviderElement<MefaliApiClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MefaliApiClient create(Ref ref) {
    return clientConfig(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MefaliApiClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MefaliApiClient>(value),
    );
  }
}

String _$clientConfigHash() => r'dbe07fbcd7bec1e32083400dba1c49d21e629809';
