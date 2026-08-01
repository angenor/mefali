// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'etat_offre.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// L'offre courante — **jetable**, rechargée par l'écran qui l'affiche.
///
/// ⚠ Aucune horloge ici, délibérément. Un provider qui s'auto-invalide en
/// boucle continue de tourner tant qu'il n'est pas éliminé — donc sur une
/// batterie de téléphone, et sur un arbre de widgets déjà démonté. C'est
/// l'écran qui bat la mesure : il a déjà un tic pour son compte à rebours, et
/// il l'annule dans son `dispose`.

@ProviderFor(OffreEnCours)
final offreEnCoursProvider = OffreEnCoursProvider._();

/// L'offre courante — **jetable**, rechargée par l'écran qui l'affiche.
///
/// ⚠ Aucune horloge ici, délibérément. Un provider qui s'auto-invalide en
/// boucle continue de tourner tant qu'il n'est pas éliminé — donc sur une
/// batterie de téléphone, et sur un arbre de widgets déjà démonté. C'est
/// l'écran qui bat la mesure : il a déjà un tic pour son compte à rebours, et
/// il l'annule dans son `dispose`.
final class OffreEnCoursProvider
    extends $AsyncNotifierProvider<OffreEnCours, OffreCourante?> {
  /// L'offre courante — **jetable**, rechargée par l'écran qui l'affiche.
  ///
  /// ⚠ Aucune horloge ici, délibérément. Un provider qui s'auto-invalide en
  /// boucle continue de tourner tant qu'il n'est pas éliminé — donc sur une
  /// batterie de téléphone, et sur un arbre de widgets déjà démonté. C'est
  /// l'écran qui bat la mesure : il a déjà un tic pour son compte à rebours, et
  /// il l'annule dans son `dispose`.
  OffreEnCoursProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'offreEnCoursProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$offreEnCoursHash();

  @$internal
  @override
  OffreEnCours create() => OffreEnCours();
}

String _$offreEnCoursHash() => r'aff9b738c354811068d4096e9bced3d77b94579a';

/// L'offre courante — **jetable**, rechargée par l'écran qui l'affiche.
///
/// ⚠ Aucune horloge ici, délibérément. Un provider qui s'auto-invalide en
/// boucle continue de tourner tant qu'il n'est pas éliminé — donc sur une
/// batterie de téléphone, et sur un arbre de widgets déjà démonté. C'est
/// l'écran qui bat la mesure : il a déjà un tic pour son compte à rebours, et
/// il l'annule dans son `dispose`.

abstract class _$OffreEnCours extends $AsyncNotifier<OffreCourante?> {
  FutureOr<OffreCourante?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<OffreCourante?>, OffreCourante?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<OffreCourante?>, OffreCourante?>,
              AsyncValue<OffreCourante?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
