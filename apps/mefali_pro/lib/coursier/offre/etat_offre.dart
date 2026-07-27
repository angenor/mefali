/// Offre courante du coursier (K2, DSP-04) — **chargement jetable**.
///
/// `AsyncNotifier` en `@riverpod` **nu** (autoDispose), et le choix est
/// l'inverse exact de celui de la disponibilité (constitution XII, deux moules
/// opposés) : une offre vit 40 s et n'a aucune raison de survivre à l'écran qui
/// l'affiche. La mise en ligne, elle, traverse les écrans — d'où son
/// `keepAlive`.
///
/// L'app **va chercher** son offre toutes les 2 s tant qu'un écran de dispatch
/// est monté (research R16) : le push haute priorité appartient à NTF-01, et le
/// jour où il arrivera il réveillera l'app, qui appellera le même endpoint.
///
/// ⚠ Le **compte à rebours** n'est PAS ici : c'est un état LOCAL du widget, que
/// la constitution XII nomme explicitement. Son autorité est `echeance_le`,
/// rendu par le serveur — le widget compte, le serveur tranche.
library;

import 'package:mefali_core/mefali_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'etat_offre.g.dart';

/// Période d'interrogation de l'offre courante.
///
/// 2 s : une offre dure 40 s, et attendre plus ferait perdre au coursier une
/// part visible de son temps de décision. Ce n'est pas un paramètre métier —
/// c'est le pas d'un affichage, et il disparaîtra avec NTF-01.
const Duration periodeInterrogation = Duration(seconds: 2);

/// Un arrêt de l'offre, tel que K2 l'affiche.
class ArretOffre {
  /// Construit un arrêt.
  const ArretOffre({
    required this.ordre,
    required this.nom,
    required this.distanceM,
  });

  /// Rang d'affichage (1 = premier arrêt).
  final int ordre;

  /// Nom du vendeur.
  final String nom;

  /// Distance INTER-ARRÊTS en mètres (« + 40 m » de la maquette).
  final int distanceM;
}

/// L'offre courante, telle que l'écran K2 la rend.
class OffreCourante {
  /// Construit l'offre.
  const OffreCourante({
    required this.offreId,
    required this.commandeId,
    required this.echeanceLe,
    required this.timerS,
    required this.arrets,
    required this.zoneNom,
    required this.destinationDistanceM,
    required this.gainTotalUnites,
    required this.gainDeplacementUnites,
    required this.gainArretsUnites,
    required this.gainEffortUnites,
    required this.avanceUnites,
    required this.plafondRetenuUnites,
    required this.devise,
    this.degraded = false,
  });

  /// Offre concernée.
  final String offreId;

  /// Commande offerte.
  final String commandeId;

  /// **L'autorité du compte à rebours.** Le widget compte les secondes ; c'est
  /// cette date qui dit quand il est trop tard.
  final DateTime echeanceLe;

  /// Durée totale du compte à rebours (secondes).
  final int timerS;

  /// Arrêts dans l'ordre du devis figé.
  final List<ArretOffre> arrets;

  /// Nom de la zone de livraison — **jamais** une adresse (ARTCI).
  final String zoneNom;

  /// Distance approximative jusqu'à la destination (mètres).
  final int destinationDistanceM;

  /// Gain total du coursier (unités mineures).
  final int gainTotalUnites;

  /// Part de déplacement.
  final int gainDeplacementUnites;

  /// Part des arrêts.
  final int gainArretsUnites;

  /// Part d'effort.
  final int gainEffortUnites;

  /// Montant à avancer aux vendeurs.
  final int avanceUnites;

  /// Plafond d'avance retenu — pourquoi il peut la prendre.
  final int plafondRetenuUnites;

  /// Devise ISO 4217.
  final String devise;

  /// Vrai si les distances sont estimées (constitution IV).
  final bool degraded;

  /// Vrai si l'échéance est passée : le widget bascule alors en K2-1b **sans
  /// aucun appel réseau supplémentaire** — l'autorité est déjà dans l'état.
  bool estEchue(DateTime maintenant) => !maintenant.isBefore(echeanceLe);

  /// Secondes restantes, jamais négatives.
  int restantS(DateTime maintenant) {
    final reste = echeanceLe.difference(maintenant).inSeconds;
    return reste < 0 ? 0 : reste;
  }

  /// Construit depuis le **corps JSON du contrat** — jamais depuis un DTO.
  factory OffreCourante.depuisJson(Map<String, Object?> json) {
    final arrets = (json['arrets'] as List<Object?>? ?? const <Object?>[])
        .whereType<Map<Object?, Object?>>()
        .map(
          (a) => ArretOffre(
            ordre: (a['ordre'] as num?)?.toInt() ?? 0,
            nom: a['nom']?.toString() ?? '',
            distanceM: (a['distance_m'] as num?)?.toInt() ?? 0,
          ),
        )
        .toList();
    final destination =
        (json['destination'] as Map<Object?, Object?>?) ?? const <Object?, Object?>{};
    final gain = (json['gain'] as Map<Object?, Object?>?) ?? const <Object?, Object?>{};
    final avance = (json['avance'] as Map<Object?, Object?>?) ?? const <Object?, Object?>{};
    return OffreCourante(
      offreId: json['offre_id']?.toString() ?? '',
      commandeId: json['commande_id']?.toString() ?? '',
      echeanceLe: DateTime.tryParse(json['echeance_le']?.toString() ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
      timerS: (json['timer_s'] as num?)?.toInt() ?? 0,
      arrets: arrets,
      zoneNom: destination['zone_nom']?.toString() ?? '',
      destinationDistanceM: (destination['distance_m'] as num?)?.toInt() ?? 0,
      gainTotalUnites: (gain['total_unites'] as num?)?.toInt() ?? 0,
      gainDeplacementUnites: (gain['deplacement_unites'] as num?)?.toInt() ?? 0,
      gainArretsUnites: (gain['arrets_unites'] as num?)?.toInt() ?? 0,
      gainEffortUnites: (gain['effort_unites'] as num?)?.toInt() ?? 0,
      avanceUnites: (avance['montant_unites'] as num?)?.toInt() ?? 0,
      plafondRetenuUnites: (avance['plafond_retenu_unites'] as num?)?.toInt() ?? 0,
      devise: (avance['devise'] ?? gain['devise'])?.toString() ?? 'XOF',
      degraded: json['degraded'] == true,
    );
  }
}

/// Ce qu'une décision a produit — de quoi afficher K2-1b sans deviner.
class DecisionPrise {
  /// Construit le résultat d'une décision.
  const DecisionPrise({required this.acceptee, this.codeErreur});

  /// Vrai si la course est bien affectée à ce coursier.
  final bool acceptee;

  /// Code du refus (`deja_prise`, `offre_echue`…), ou `null`.
  final String? codeErreur;
}

/// L'offre courante — **jetable**, rechargée par l'écran qui l'affiche.
///
/// ⚠ Aucune horloge ici, délibérément. Un provider qui s'auto-invalide en
/// boucle continue de tourner tant qu'il n'est pas éliminé — donc sur une
/// batterie de téléphone, et sur un arbre de widgets déjà démonté. C'est
/// l'écran qui bat la mesure : il a déjà un tic pour son compte à rebours, et
/// il l'annule dans son `dispose`.
@riverpod
class OffreEnCours extends _$OffreEnCours {
  static const _uuid = Uuid();

  @override
  Future<OffreCourante?> build() async => _charger();

  Future<OffreCourante?> _charger() async {
    final json = await ref.read(dispatchApiProvider).offreCourante();
    return json == null ? null : OffreCourante.depuisJson(json);
  }

  /// Accepte l'offre courante.
  ///
  /// Un refus métier n'est **pas** une panne : il rend son code, et l'écran en
  /// fait l'état K2-1b — ton neutre, sans blâme.
  Future<DecisionPrise> accepter() async {
    final offre = state.value;
    if (offre == null) return const DecisionPrise(acceptee: false);
    try {
      await ref.read(dispatchApiProvider).accepterOffre(
            offreId: offre.offreId,
            uuidClient: _uuid.v7(),
            horodatageLocal: DateTime.now().toUtc(),
          );
      ref.invalidateSelf();
      return const DecisionPrise(acceptee: true);
    } on Object catch (e) {
      ref.invalidateSelf();
      return DecisionPrise(acceptee: false, codeErreur: codeErreurApi(e));
    }
  }

  /// Refuse l'offre courante — aucune sanction, le suivant est sollicité.
  Future<void> refuser() async {
    final offre = state.value;
    if (offre == null) return;
    try {
      await ref.read(dispatchApiProvider).refuserOffre(
            offreId: offre.offreId,
            uuidClient: _uuid.v7(),
            horodatageLocal: DateTime.now().toUtc(),
          );
    } on Object catch (e) {
      // Refuser une offre déjà conclue n'est pas un problème : elle n'est plus
      // là, et c'est ce que le rechargement va montrer.
      codeErreurApi(e);
    }
    ref.invalidateSelf();
  }
}
