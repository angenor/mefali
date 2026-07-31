// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'etat_caisse.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Chargement de la caisse (CRS-06, K5).
///
/// `retry: pasDeRetry` vient de la **portée** (`mefali_core`, constitution XII),
/// et c'est ce qu'il faut ici : un rejeu automatique masquerait la coupure que
/// l'écran doit justement annoncer, et relancerait la requête dans le dos de
/// Yao sur un forfait prépayé.

@ProviderFor(EtatCaisse)
final etatCaisseProvider = EtatCaisseProvider._();

/// Chargement de la caisse (CRS-06, K5).
///
/// `retry: pasDeRetry` vient de la **portée** (`mefali_core`, constitution XII),
/// et c'est ce qu'il faut ici : un rejeu automatique masquerait la coupure que
/// l'écran doit justement annoncer, et relancerait la requête dans le dos de
/// Yao sur un forfait prépayé.
final class EtatCaisseProvider
    extends $AsyncNotifierProvider<EtatCaisse, EtatCaisseVue> {
  /// Chargement de la caisse (CRS-06, K5).
  ///
  /// `retry: pasDeRetry` vient de la **portée** (`mefali_core`, constitution XII),
  /// et c'est ce qu'il faut ici : un rejeu automatique masquerait la coupure que
  /// l'écran doit justement annoncer, et relancerait la requête dans le dos de
  /// Yao sur un forfait prépayé.
  EtatCaisseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'etatCaisseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$etatCaisseHash();

  @$internal
  @override
  EtatCaisse create() => EtatCaisse();
}

String _$etatCaisseHash() => r'24c26f7972c13833092aa977c88f9fe22991f4c6';

/// Chargement de la caisse (CRS-06, K5).
///
/// `retry: pasDeRetry` vient de la **portée** (`mefali_core`, constitution XII),
/// et c'est ce qu'il faut ici : un rejeu automatique masquerait la coupure que
/// l'écran doit justement annoncer, et relancerait la requête dans le dos de
/// Yao sur un forfait prépayé.

abstract class _$EtatCaisse extends $AsyncNotifier<EtatCaisseVue> {
  FutureOr<EtatCaisseVue> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<EtatCaisseVue>, EtatCaisseVue>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<EtatCaisseVue>, EtatCaisseVue>,
              AsyncValue<EtatCaisseVue>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
