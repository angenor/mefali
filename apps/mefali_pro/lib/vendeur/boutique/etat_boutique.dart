import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'etat_boutique.g.dart';

/// La boutique du prestataire piloté (écran V1 — FR-044). Chargement serveur
/// + gestes en UN appel : moule `AsyncNotifier`, `@riverpod` nu (autoDispose),
/// patron `MesAdresses` du cycle 003/004.
@riverpod
class Boutique extends _$Boutique {
  @override
  Future<BoutiqueVendeur> build(String prestataireId) => _charger();

  Future<BoutiqueVendeur> _charger() async {
    final reponse = await ref
        .read(clientSessionProvider)
        .getVendeurApi()
        .maBoutique(id: prestataireId);
    return reponse.data!;
  }

  /// Réaffiche le squelette puis recharge (patron R9).
  Future<void> recharger() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_charger);
  }

  /// Applique un geste (FR-033) puis relit l'état résultant — la lecture qui
  /// suit une bascule ne rend JAMAIS l'état précédent (SC-007).
  Future<void> geste(ActionBoutiqueDto action, {int? dureeMinutes}) async {
    await ref.read(clientSessionProvider).getVendeurApi().actionBoutique(
          id: prestataireId,
          corpsActionBoutique: CorpsActionBoutique((b) => b
            ..action = action
            ..dureeMinutes = dureeMinutes),
        );
    await recharger();
  }

  /// Remplace les horaires hebdomadaires (FR-034).
  Future<void> modifierHoraires(HorairesSemaineDto horaires) async {
    await ref.read(clientSessionProvider).getVendeurApi().modifierHoraires(
          id: prestataireId,
          horairesSemaineDto: horaires,
        );
    await recharger();
  }
}
