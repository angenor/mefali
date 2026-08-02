import 'package:dio/dio.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'etat_offre_livraison.g.dart';

/// Le réglage d'**offre de livraison** d'un vendeur (VND-08 minimal, FR-046).
///
/// `@riverpod` nu (autoDispose) : geste d'écran, aucun état à faire survivre à
/// la fermeture de la feuille. La valeur courante vit sur `PrestatairePilotable`
/// — la relire ici serait une seconde source de vérité pour deux scalaires.
@riverpod
class OffreLivraison extends _$OffreLivraison {
  @override
  void build(String prestataireId) {}

  /// Déclare l'offre. Rend `null` en cas de succès, sinon la **clé i18n** du
  /// refus — le patron des gestes du cycle 010 : l'appelant décide où et
  /// comment l'afficher, jamais le notifier.
  ///
  /// Ne recharge PAS le pilotage : ce porteur est auto-dispose, et sa portée
  /// meurt avec la feuille. Un `ref.read` après l'aller-retour y lèverait une
  /// `UnmountedRefException` — qui n'est pas une `DioException`, traverse donc
  /// le `catch`, et laisse la feuille figée sur un réglage pourtant enregistré
  /// (constaté sur appareil en T085). Le rechargement appartient à l'écran,
  /// dont la portée survit : voir `ecran_boutique.dart`.
  Future<String?> declarer(String offre, int? seuilUnites) async {
    try {
      await ref.read(clientSessionProvider).getVendeurApi().definirOffreLivraison(
            id: prestataireId,
            offreLivraisonDeclaration: OffreLivraisonDeclaration((b) => b
              ..offre = offre
              ..seuilUnites = seuilUnites),
          );
      return null;
    } on DioException catch (e) {
      // Le serveur nomme le refus (`offre_seuil_manquant`) ; l'app le traduit.
      // Un message générique ferait chercher au vendeur ce qu'il a mal saisi.
      final code = e.response?.data is Map
          ? (e.response!.data as Map)['code'] as String?
          : null;
      return code ?? 'erreur_interne';
    }
  }
}
