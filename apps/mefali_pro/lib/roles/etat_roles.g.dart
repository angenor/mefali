// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'etat_roles.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Rôles du compte connecté, et rôle dont Mefali Pro affiche l'interface.
///
/// `@riverpod` NU (autoDispose) — le DÉFAUT du générateur est ici le bon réglage,
/// et c'est le SEUL provider du cycle dans ce cas. `keepAlive` serait une
/// RÉGRESSION DE SÉCURITÉ silencieuse : les rôles survivraient au changement de
/// compte (mode de panne n°3).
///
/// ## Pourquoi la bascule ne parle pas au réseau
///
/// FR-013 exige de passer d'une interface à l'autre « sans reconnexion », en
/// moins de 5 secondes (SC-006). Les rôles validés sont déjà en mémoire :
/// [basculer] ne fait que changer le rôle affiché — aucune requête, aucun jeton
/// touché.

@ProviderFor(EtatRoles)
final etatRolesProvider = EtatRolesProvider._();

/// Rôles du compte connecté, et rôle dont Mefali Pro affiche l'interface.
///
/// `@riverpod` NU (autoDispose) — le DÉFAUT du générateur est ici le bon réglage,
/// et c'est le SEUL provider du cycle dans ce cas. `keepAlive` serait une
/// RÉGRESSION DE SÉCURITÉ silencieuse : les rôles survivraient au changement de
/// compte (mode de panne n°3).
///
/// ## Pourquoi la bascule ne parle pas au réseau
///
/// FR-013 exige de passer d'une interface à l'autre « sans reconnexion », en
/// moins de 5 secondes (SC-006). Les rôles validés sont déjà en mémoire :
/// [basculer] ne fait que changer le rôle affiché — aucune requête, aucun jeton
/// touché.
final class EtatRolesProvider
    extends $NotifierProvider<EtatRoles, EtatRolesData> {
  /// Rôles du compte connecté, et rôle dont Mefali Pro affiche l'interface.
  ///
  /// `@riverpod` NU (autoDispose) — le DÉFAUT du générateur est ici le bon réglage,
  /// et c'est le SEUL provider du cycle dans ce cas. `keepAlive` serait une
  /// RÉGRESSION DE SÉCURITÉ silencieuse : les rôles survivraient au changement de
  /// compte (mode de panne n°3).
  ///
  /// ## Pourquoi la bascule ne parle pas au réseau
  ///
  /// FR-013 exige de passer d'une interface à l'autre « sans reconnexion », en
  /// moins de 5 secondes (SC-006). Les rôles validés sont déjà en mémoire :
  /// [basculer] ne fait que changer le rôle affiché — aucune requête, aucun jeton
  /// touché.
  EtatRolesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'etatRolesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$etatRolesHash();

  @$internal
  @override
  EtatRoles create() => EtatRoles();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EtatRolesData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EtatRolesData>(value),
    );
  }
}

String _$etatRolesHash() => r'e3bb4028ad04cd0f9751e85c3a241c28607723e7';

/// Rôles du compte connecté, et rôle dont Mefali Pro affiche l'interface.
///
/// `@riverpod` NU (autoDispose) — le DÉFAUT du générateur est ici le bon réglage,
/// et c'est le SEUL provider du cycle dans ce cas. `keepAlive` serait une
/// RÉGRESSION DE SÉCURITÉ silencieuse : les rôles survivraient au changement de
/// compte (mode de panne n°3).
///
/// ## Pourquoi la bascule ne parle pas au réseau
///
/// FR-013 exige de passer d'une interface à l'autre « sans reconnexion », en
/// moins de 5 secondes (SC-006). Les rôles validés sont déjà en mémoire :
/// [basculer] ne fait que changer le rôle affiché — aucune requête, aucun jeton
/// touché.

abstract class _$EtatRoles extends $Notifier<EtatRolesData> {
  EtatRolesData build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<EtatRolesData, EtatRolesData>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EtatRolesData, EtatRolesData>,
              EtatRolesData,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
