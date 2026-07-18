import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pilotage.g.dart';

/// Le prestataire que ce compte PILOTE — le premier rattachement au MVP
/// (aucune sélection de site ni de prestataire n'existe nulle part, FR-019).
///
/// `null` : le compte porte le rôle vendeur mais n'est rattaché à aucun
/// prestataire — le rôle seul n'autorise rien (FR-011), l'écran l'explique.
/// `@riverpod` nu (autoDispose) : chargement d'écran, aucun état à faire
/// survivre.
@riverpod
class Pilotage extends _$Pilotage {
  @override
  Future<PrestatairePilotable?> build() => _charger();

  Future<PrestatairePilotable?> _charger() async {
    final reponse =
        await ref.read(clientSessionProvider).getVendeurApi().mesPrestataires();
    final pilotables = reponse.data;
    if (pilotables == null || pilotables.isEmpty) return null;
    return pilotables.first;
  }

  /// Recharge (squelette réaffiché — patron `MesAdresses`).
  Future<void> recharger() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_charger);
  }
}
