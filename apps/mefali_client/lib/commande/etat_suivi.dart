/// État du **suivi d'une commande** (cycle CMD 008, US6 / CMD-05).
///
/// Moule **`AsyncNotifier`** de la constitution XII : contrairement au panier —
/// qui est un objet que le client construit — le suivi est un CHARGEMENT. Il a
/// un état « en cours », un état d'erreur, et une valeur. C'est exactement ce
/// que `AsyncNotifier` modélise, et c'est pourquoi les deux moules coexistent
/// au lieu d'un `AsyncValue` uniforme.
///
/// `retry: pasDeRetry` : un suivi qui échoue faute de réseau ne doit pas
/// repartir en boucle — il bascule sur le **dernier état connu** du cache
/// (maquette C4-4d), ce qui est à la fois plus honnête et moins coûteux en
/// batterie.
library;

import 'package:flutter/foundation.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'etat_suivi.g.dart';

/// L'arrêt où en est le coursier.
@immutable
class ArretCourantVue {
  /// Crée la vue d'un arrêt courant.
  const ArretCourantVue({required this.ordre, this.prestataireNom});

  /// Rang dans l'itinéraire.
  final int ordre;

  /// Nom du vendeur — `null` sur l'arrêt de REMISE, qui n'en a pas.
  final String? prestataireNom;
}

/// Position du coursier, **toujours accompagnée de son âge**.
///
/// L'âge n'est pas un détail d'affichage : sans lui, l'app présenterait une
/// position vieille de dix minutes comme si elle était vraie, et le client
/// attendrait devant sa porte quelqu'un qui est ailleurs (FR-040).
@immutable
class PositionVue {
  /// Crée une position datée.
  const PositionVue({
    required this.lat,
    required this.lon,
    required this.ageS,
  });

  /// Latitude.
  final double lat;

  /// Longitude.
  final double lon;

  /// Ancienneté du relevé, en secondes.
  final int ageS;
}

/// Une proposition de remplacement ouverte (maquette C4-4c).
@immutable
class SubstitutionVue {
  /// Crée la vue d'une proposition.
  const SubstitutionVue({
    required this.id,
    required this.articleNom,
    required this.prixUnites,
    required this.ancienPrixUnites,
    required this.resteS,
  });

  /// Proposition.
  final String id;

  /// Nom de l'article proposé.
  final String articleNom;

  /// Prix proposé (unités mineures).
  final int prixUnites;

  /// Prix de la ligne d'origine (unités mineures).
  final int ancienPrixUnites;

  /// Secondes restantes pour décider.
  final int resteS;

  /// Écart en unités mineures — positif si le remplacement coûte plus cher.
  int get ecartUnites => prixUnites - ancienPrixUnites;
}

/// Le suivi d'une commande, réduit à ce que l'écran affiche.
@immutable
class EtatSuivi {
  /// Crée un état de suivi.
  const EtatSuivi({
    required this.commandeId,
    required this.etat,
    required this.etatCle,
    required this.collectesFaites,
    required this.collectesTotal,
    required this.codeLivraison,
    required this.jetonReception,
    required this.totalUnites,
    required this.devise,
    this.arretCourant,
    this.position,
    this.coursierId,
    this.substitution,
    this.horsLigne = false,
  });

  /// Commande suivie.
  final String commandeId;

  /// État de très haut niveau (`nouvelle`, `en_cours`…).
  final String etat;

  /// **Clé i18n** de l'état — le serveur ne formule jamais de phrase.
  final String etatCle;

  /// Collectes résolues.
  final int collectesFaites;

  /// Nombre total de collectes — la remise n'en est pas une (P1).
  final int collectesTotal;

  /// Code de remise à 4 chiffres.
  final String codeLivraison;

  /// Jeton encodé dans le QR de réception.
  final String jetonReception;

  /// Total à régler.
  final int totalUnites;

  /// Devise ISO 4217.
  final String devise;

  /// Arrêt courant.
  final ArretCourantVue? arretCourant;

  /// Dernière position connue — `null` si aucune (jamais une position inventée).
  final PositionVue? position;

  /// Coursier affecté.
  final String? coursierId;

  /// Proposition de remplacement ouverte.
  final SubstitutionVue? substitution;

  /// Vrai si l'écran affiche le **dernier état connu** issu du cache local et
  /// non une réponse serveur (maquette C4-4d).
  final bool horsLigne;

  /// La commande cherche encore un coursier (maquette C4-4b).
  bool get chercheCoursier => etat == 'en_attente_coursier';

  /// Aucun arrêt n'a encore été collecté : l'annulation est SANS FRAIS
  /// (CMD-07). C'est ce qui autorise le bouton d'annulation de C4-4b.
  bool get annulationSansFrais =>
      collectesFaites == 0 &&
      (etat == 'nouvelle' || etat == 'en_attente_coursier');

  /// Construit la vue depuis le corps JSON de `GET /commandes/{id}`.
  factory EtatSuivi.depuisJson(Map<String, Object?> json) {
    final progression = json['progression']! as Map<String, Object?>;
    final arret = progression['arret_courant'] as Map<String, Object?>?;
    final position = json['position'] as Map<String, Object?>?;
    final coursier = json['coursier'] as Map<String, Object?>?;
    final remise = json['remise']! as Map<String, Object?>;
    final substitution =
        json['substitution_en_attente'] as Map<String, Object?>?;
    return EtatSuivi(
      commandeId: json['id']! as String,
      etat: json['etat']! as String,
      etatCle: json['etat_cle']! as String,
      collectesFaites: progression['collectes_faites']! as int,
      collectesTotal: progression['collectes_total']! as int,
      codeLivraison: remise['code_livraison']! as String,
      jetonReception: remise['jeton_reception']! as String,
      totalUnites: json['total_unites']! as int,
      devise: json['devise']! as String,
      arretCourant: arret == null
          ? null
          : ArretCourantVue(
              ordre: arret['ordre']! as int,
              prestataireNom: arret['prestataire_nom'] as String?,
            ),
      position: position == null
          ? null
          : PositionVue(
              lat: (position['lat']! as num).toDouble(),
              lon: (position['lon']! as num).toDouble(),
              ageS: position['age_s']! as int,
            ),
      coursierId: coursier?['id'] as String?,
      substitution: substitution == null
          ? null
          : SubstitutionVue(
              id: substitution['id']! as String,
              articleNom: substitution['article_nom']! as String,
              prixUnites: substitution['prix_unites']! as int,
              ancienPrixUnites: substitution['ancien_prix_unites']! as int,
              resteS: substitution['reste_s']! as int,
            ),
    );
  }

  /// Reconstruit un suivi depuis le **cache local** (drift), pour le mode hors
  /// ligne (maquette C4-4d).
  ///
  /// L'âge de la position est RECALCULÉ : `positionAgeS` était vrai au moment
  /// de la mise en cache, et le temps a passé depuis. Réafficher l'âge figé
  /// reviendrait à rajeunir la position à chaque ouverture de l'écran.
  factory EtatSuivi.depuisCache(CommandeCache cache, {DateTime? maintenant}) {
    final ecoule =
        (maintenant ?? DateTime.now()).difference(cache.majLeLocal).inSeconds;
    return EtatSuivi(
      commandeId: cache.commandeId,
      etat: cache.etat,
      etatCle: cache.etatCle,
      collectesFaites: cache.collectesFaites,
      collectesTotal: cache.collectesTotal,
      codeLivraison: cache.codeLivraison,
      jetonReception: cache.jetonReception,
      totalUnites: cache.totalUnites,
      devise: cache.devise,
      position: cache.positionLat == null ||
              cache.positionLon == null ||
              cache.positionAgeS == null
          ? null
          : PositionVue(
              lat: cache.positionLat!,
              lon: cache.positionLon!,
              ageS: cache.positionAgeS! + (ecoule < 0 ? 0 : ecoule),
            ),
      horsLigne: true,
    );
  }

  /// Copie marquée hors ligne — le contenu ne change pas, sa VALIDITÉ si.
  EtatSuivi marqueHorsLigne() => EtatSuivi(
        commandeId: commandeId,
        etat: etat,
        etatCle: etatCle,
        collectesFaites: collectesFaites,
        collectesTotal: collectesTotal,
        codeLivraison: codeLivraison,
        jetonReception: jetonReception,
        totalUnites: totalUnites,
        devise: devise,
        arretCourant: arretCourant,
        position: position,
        coursierId: coursierId,
        substitution: substitution,
        horsLigne: true,
      );
}

/// Source du suivi — **injectée par la PORTÉE** (constitution XII).
///
/// `throw` par défaut, comme `urlApiProvider` : le porteur d'état ne construit
/// pas son transport, il le reçoit. C'est ce qui permet au test widget de
/// servir une vue figée sans réseau, et à l'app de brancher le client généré,
/// sans qu'aucun des deux ne connaisse l'autre.
@Riverpod(keepAlive: true)
Future<EtatSuivi> Function(String commandeId) sourceSuivi(Ref ref) =>
    throw UnimplementedError(
      'sourceSuiviProvider doit être surchargé dans la portée : '
      'ProviderScope(overrides: [sourceSuiviProvider.overrideWithValue(…)]).',
    );

/// Porteur du suivi d'UNE commande.
///
/// `@Riverpod` **auto-dispose** (durée de vie EXPLICITE, constitution XII) : un
/// suivi ne survit pas à la fermeture de son écran. Le garder vivant
/// entretiendrait un rafraîchissement pour une commande que le client ne
/// regarde plus — de la batterie et de la data dépensées pour rien, sur des
/// téléphones où les deux comptent.
@Riverpod(retry: pasDeRetry)
class Suivi extends _$Suivi {
  @override
  Future<EtatSuivi> build(String commandeId) =>
      ref.watch(sourceSuiviProvider)(commandeId);

  /// Remplace l'état par une vue fraîchement obtenue du serveur.
  void poser(EtatSuivi suivi) => state = AsyncData(suivi);

  /// Bascule sur le **dernier état connu** : le contenu reste, sa VALIDITÉ
  /// change (maquette C4-4d). Aucun appel réseau n'est émis sur ce chemin —
  /// c'est tout l'intérêt du cache local.
  void basculerHorsLigne(EtatSuivi dernierConnu) =>
      state = AsyncData(dernierConnu.marqueHorsLigne());
}
