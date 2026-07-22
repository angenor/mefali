// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pilotage.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Le prestataire que ce compte PILOTE — le premier rattachement au MVP
/// (aucune sélection de site ni de prestataire n'existe nulle part, FR-019).
///
/// `null` : le compte porte le rôle vendeur mais n'est rattaché à aucun
/// prestataire — le rôle seul n'autorise rien (FR-011), l'écran l'explique.
/// `@riverpod` nu (autoDispose) : chargement d'écran, aucun état à faire
/// survivre.

@ProviderFor(Pilotage)
final pilotageProvider = PilotageProvider._();

/// Le prestataire que ce compte PILOTE — le premier rattachement au MVP
/// (aucune sélection de site ni de prestataire n'existe nulle part, FR-019).
///
/// `null` : le compte porte le rôle vendeur mais n'est rattaché à aucun
/// prestataire — le rôle seul n'autorise rien (FR-011), l'écran l'explique.
/// `@riverpod` nu (autoDispose) : chargement d'écran, aucun état à faire
/// survivre.
final class PilotageProvider
    extends $AsyncNotifierProvider<Pilotage, PrestatairePilotable?> {
  /// Le prestataire que ce compte PILOTE — le premier rattachement au MVP
  /// (aucune sélection de site ni de prestataire n'existe nulle part, FR-019).
  ///
  /// `null` : le compte porte le rôle vendeur mais n'est rattaché à aucun
  /// prestataire — le rôle seul n'autorise rien (FR-011), l'écran l'explique.
  /// `@riverpod` nu (autoDispose) : chargement d'écran, aucun état à faire
  /// survivre.
  PilotageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pilotageProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pilotageHash();

  @$internal
  @override
  Pilotage create() => Pilotage();
}

String _$pilotageHash() => r'cf392c7983fd17df342a66cf4d7be45c55a41401';

/// Le prestataire que ce compte PILOTE — le premier rattachement au MVP
/// (aucune sélection de site ni de prestataire n'existe nulle part, FR-019).
///
/// `null` : le compte porte le rôle vendeur mais n'est rattaché à aucun
/// prestataire — le rôle seul n'autorise rien (FR-011), l'écran l'explique.
/// `@riverpod` nu (autoDispose) : chargement d'écran, aucun état à faire
/// survivre.

abstract class _$Pilotage extends $AsyncNotifier<PrestatairePilotable?> {
  FutureOr<PrestatairePilotable?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<PrestatairePilotable?>, PrestatairePilotable?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<PrestatairePilotable?>,
                PrestatairePilotable?
              >,
              AsyncValue<PrestatairePilotable?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
