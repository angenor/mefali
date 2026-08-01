// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_continu.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Le service de premier plan — **scopé**, pour que les tests l'injectent.

@ProviderFor(servicePremierPlan)
final servicePremierPlanProvider = ServicePremierPlanProvider._();

/// Le service de premier plan — **scopé**, pour que les tests l'injectent.

final class ServicePremierPlanProvider
    extends
        $FunctionalProvider<
          ServicePremierPlan,
          ServicePremierPlan,
          ServicePremierPlan
        >
    with $Provider<ServicePremierPlan> {
  /// Le service de premier plan — **scopé**, pour que les tests l'injectent.
  ServicePremierPlanProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'servicePremierPlanProvider',
        isAutoDispose: false,
        dependencies: <ProviderOrFamily>[],
        $allTransitiveDependencies: <ProviderOrFamily>[],
      );

  @override
  String debugGetCreateSourceHash() => _$servicePremierPlanHash();

  @$internal
  @override
  $ProviderElement<ServicePremierPlan> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ServicePremierPlan create(Ref ref) {
    return servicePremierPlan(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ServicePremierPlan value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ServicePremierPlan>(value),
    );
  }
}

String _$servicePremierPlanHash() =>
    r'fdcc24a929a07974882dfc843d7f180f868edec2';

/// Le canal de sonnerie d'offre — **scopé**, même raison.

@ProviderFor(canalOffre)
final canalOffreProvider = CanalOffreProvider._();

/// Le canal de sonnerie d'offre — **scopé**, même raison.

final class CanalOffreProvider
    extends $FunctionalProvider<CanalOffre, CanalOffre, CanalOffre>
    with $Provider<CanalOffre> {
  /// Le canal de sonnerie d'offre — **scopé**, même raison.
  CanalOffreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'canalOffreProvider',
        isAutoDispose: false,
        dependencies: <ProviderOrFamily>[],
        $allTransitiveDependencies: <ProviderOrFamily>[],
      );

  @override
  String debugGetCreateSourceHash() => _$canalOffreHash();

  @$internal
  @override
  $ProviderElement<CanalOffre> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CanalOffre create(Ref ref) {
    return canalOffre(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CanalOffre value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CanalOffre>(value),
    );
  }
}

String _$canalOffreHash() => r'44a43c2ef2d58f833950214d7f2afdb8a8c91497';

/// Processus du service continu (CRS-02, US7).
///
/// `Notifier` et non `AsyncNotifier` (constitution XII, R15) : ce n'est pas un
/// chargement, c'est un **processus** qui dure toute une journée de travail.
///
/// **`keepAlive: true`** : le service survit à tous les écrans. Un `autoDispose`
/// l'arrêterait dès que Yao quitte K1 — c'est-à-dire au moment précis où il
/// range son téléphone.
///
/// ⚠ Les minuteries vivent **ici** et nulle part ailleurs, et elles sont
/// annulées dans `ref.onDispose` : un `Timer` qui survit à sa portée fait
/// échouer les tests par « a Timer is still pending » (piège du cycle 004). La
/// différence avec `EtatPreuves` est assumée : là-bas la minuterie sert
/// l'affichage et appartient au widget ; ici elle EST le service.

@ProviderFor(ServiceContinu)
final serviceContinuProvider = ServiceContinuProvider._();

/// Processus du service continu (CRS-02, US7).
///
/// `Notifier` et non `AsyncNotifier` (constitution XII, R15) : ce n'est pas un
/// chargement, c'est un **processus** qui dure toute une journée de travail.
///
/// **`keepAlive: true`** : le service survit à tous les écrans. Un `autoDispose`
/// l'arrêterait dès que Yao quitte K1 — c'est-à-dire au moment précis où il
/// range son téléphone.
///
/// ⚠ Les minuteries vivent **ici** et nulle part ailleurs, et elles sont
/// annulées dans `ref.onDispose` : un `Timer` qui survit à sa portée fait
/// échouer les tests par « a Timer is still pending » (piège du cycle 004). La
/// différence avec `EtatPreuves` est assumée : là-bas la minuterie sert
/// l'affichage et appartient au widget ; ici elle EST le service.
final class ServiceContinuProvider
    extends $NotifierProvider<ServiceContinu, EtatServiceContinu> {
  /// Processus du service continu (CRS-02, US7).
  ///
  /// `Notifier` et non `AsyncNotifier` (constitution XII, R15) : ce n'est pas un
  /// chargement, c'est un **processus** qui dure toute une journée de travail.
  ///
  /// **`keepAlive: true`** : le service survit à tous les écrans. Un `autoDispose`
  /// l'arrêterait dès que Yao quitte K1 — c'est-à-dire au moment précis où il
  /// range son téléphone.
  ///
  /// ⚠ Les minuteries vivent **ici** et nulle part ailleurs, et elles sont
  /// annulées dans `ref.onDispose` : un `Timer` qui survit à sa portée fait
  /// échouer les tests par « a Timer is still pending » (piège du cycle 004). La
  /// différence avec `EtatPreuves` est assumée : là-bas la minuterie sert
  /// l'affichage et appartient au widget ; ici elle EST le service.
  ServiceContinuProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'serviceContinuProvider',
        isAutoDispose: false,
        dependencies: <ProviderOrFamily>[
          servicePremierPlanProvider,
          canalOffreProvider,
          textesServiceProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>[
          ServiceContinuProvider.$allTransitiveDependencies0,
          ServiceContinuProvider.$allTransitiveDependencies1,
          ServiceContinuProvider.$allTransitiveDependencies2,
        ],
      );

  static final $allTransitiveDependencies0 = servicePremierPlanProvider;
  static final $allTransitiveDependencies1 = canalOffreProvider;
  static final $allTransitiveDependencies2 = textesServiceProvider;

  @override
  String debugGetCreateSourceHash() => _$serviceContinuHash();

  @$internal
  @override
  ServiceContinu create() => ServiceContinu();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EtatServiceContinu value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EtatServiceContinu>(value),
    );
  }
}

String _$serviceContinuHash() => r'55f48c8df1fc09fd010d31fe9cc936c06ab2ad85';

/// Processus du service continu (CRS-02, US7).
///
/// `Notifier` et non `AsyncNotifier` (constitution XII, R15) : ce n'est pas un
/// chargement, c'est un **processus** qui dure toute une journée de travail.
///
/// **`keepAlive: true`** : le service survit à tous les écrans. Un `autoDispose`
/// l'arrêterait dès que Yao quitte K1 — c'est-à-dire au moment précis où il
/// range son téléphone.
///
/// ⚠ Les minuteries vivent **ici** et nulle part ailleurs, et elles sont
/// annulées dans `ref.onDispose` : un `Timer` qui survit à sa portée fait
/// échouer les tests par « a Timer is still pending » (piège du cycle 004). La
/// différence avec `EtatPreuves` est assumée : là-bas la minuterie sert
/// l'affichage et appartient au widget ; ici elle EST le service.

abstract class _$ServiceContinu extends $Notifier<EtatServiceContinu> {
  EtatServiceContinu build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<EtatServiceContinu, EtatServiceContinu>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EtatServiceContinu, EtatServiceContinu>,
              EtatServiceContinu,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Textes du service — **scopé** : le point de montage les résout depuis l'ARB.
///
/// Le défaut est volontairement vide plutôt que fabriqué : une chaîne en dur
/// ici passerait la revue i18n sans être traduisible.

@ProviderFor(textesService)
final textesServiceProvider = TextesServiceProvider._();

/// Textes du service — **scopé** : le point de montage les résout depuis l'ARB.
///
/// Le défaut est volontairement vide plutôt que fabriqué : une chaîne en dur
/// ici passerait la revue i18n sans être traduisible.

final class TextesServiceProvider
    extends $FunctionalProvider<TextesService, TextesService, TextesService>
    with $Provider<TextesService> {
  /// Textes du service — **scopé** : le point de montage les résout depuis l'ARB.
  ///
  /// Le défaut est volontairement vide plutôt que fabriqué : une chaîne en dur
  /// ici passerait la revue i18n sans être traduisible.
  TextesServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'textesServiceProvider',
        isAutoDispose: false,
        dependencies: <ProviderOrFamily>[],
        $allTransitiveDependencies: <ProviderOrFamily>[],
      );

  @override
  String debugGetCreateSourceHash() => _$textesServiceHash();

  @$internal
  @override
  $ProviderElement<TextesService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TextesService create(Ref ref) {
    return textesService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TextesService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TextesService>(value),
    );
  }
}

String _$textesServiceHash() => r'a64a2d68ac7ca1ccff1ac8ae2560802041741de1';
