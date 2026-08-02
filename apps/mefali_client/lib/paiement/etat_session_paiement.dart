/// État de la **session de prépaiement** d'une commande (cycle PAY 011, US1).
///
/// Moule **`Notifier`** de la constitution XII, et non `AsyncNotifier` : ce
/// n'est pas un chargement mais un compte à rebours, c'est-à-dire une valeur
/// qui change toute seule au fil du temps. Il a un contenu dès la première
/// frame — celui que `POST /commandes/{id}/paiement` vient de rendre — et pas
/// d'état « en cours ».
///
/// # Le compte à rebours ne décide de rien
///
/// Il est **local et purement visuel**. La seule autorité sur « cette session
/// vit-elle encore ? » est le serveur, qui sert `restant_s` à chaque lecture
/// (FR-017). Le tic local existe pour que le chiffre bouge à l'écran entre deux
/// lectures, pas pour trancher : quand il atteint zéro, l'app **relit** au lieu
/// de conclure.
///
/// C'est la même leçon qu'au cycle 010, où une horloge d'appareil décalée avait
/// fait basculer un état de boutique. Ici, elle ferait croire à Awa que sa
/// commande est perdue alors qu'elle a payé — ou l'inverse.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'etat_session_paiement.g.dart';

/// La session de paiement, réduite à ce que l'écran affiche.
@immutable
class EtatSessionPaiement {
  /// Crée l'état d'une session.
  const EtatSessionPaiement({
    required this.transactionId,
    required this.etat,
    required this.montantUnites,
    required this.devise,
    required this.restantS,
    this.accesPaiement,
    this.moyen = 'inconnu',
  });

  /// Transaction de paiement.
  final String transactionId;

  /// `ouverte` | `reglee` | `echouee` | `expiree` | `payee_hors_delai`.
  final String etat;

  /// Montant **figé** à l'ouverture (unités mineures).
  final int montantUnites;

  /// Devise ISO 4217.
  final String devise;

  /// Secondes restantes. Vient du **serveur**, puis décroît localement entre
  /// deux lectures — sans jamais passer sous zéro.
  final int restantS;

  /// Page de paiement à ouvrir dans le navigateur système. `null` dès que la
  /// session est close : il n'y a plus rien à ouvrir.
  final String? accesPaiement;

  /// Moyen employé, tel que le fournisseur l'a dit. `inconnu` tant qu'il ne
  /// l'a pas dit — jamais deviné.
  final String moyen;

  /// La session accepte encore un paiement.
  ///
  /// `echouee` en fait partie : un refus d'opérateur (solde insuffisant, code
  /// faux) n'est pas une fin, le client réessaie sur la même session tant que
  /// l'échéance n'est pas franchie (FR-026).
  bool get accepteEncore => etat == 'ouverte' || etat == 'echouee';

  /// Le paiement est confirmé.
  bool get reglee => etat == 'reglee';

  /// Le délai est écoulé — **du point de vue du serveur**.
  bool get expiree => etat == 'expiree' || etat == 'payee_hors_delai';

  /// Le bouton de reprise a un sens : la session vit et porte un accès.
  bool get reprenable => accepteEncore && restantS > 0 && accesPaiement != null;

  /// Construit la vue depuis le corps de `POST`/`GET /commandes/{id}/paiement`.
  factory EtatSessionPaiement.depuisJson(Map<String, Object?> json) =>
      EtatSessionPaiement(
        transactionId: json['transaction_id']! as String,
        etat: json['etat']! as String,
        montantUnites: json['montant_unites']! as int,
        devise: json['devise']! as String,
        restantS: json['restant_s']! as int,
        accesPaiement: json['acces_paiement'] as String?,
        moyen: (json['moyen'] as String?) ?? 'inconnu',
      );

  /// Copie au temps restant décrémenté, **bornée à zéro**.
  EtatSessionPaiement auTemps(int restant) => EtatSessionPaiement(
        transactionId: transactionId,
        etat: etat,
        montantUnites: montantUnites,
        devise: devise,
        restantS: restant < 0 ? 0 : restant,
        accesPaiement: accesPaiement,
        moyen: moyen,
      );
}

/// Porteur de la session de paiement d'UNE commande.
///
/// `keepAlive` **explicite** (constitution XII), comme `Confirmation` : l'état
/// est posé par `ActionsCommande` juste après l'ouverture de session, et il doit
/// survivre à la transition de navigation qui amène l'écran de règlement. Une
/// portée auto-disposée le perdrait entre les deux et l'écran s'ouvrirait vide.
///
/// Le minuteur, lui, ne survit à rien : il s'arrête tout seul à zéro, à la
/// première issue non payable, et sur [liberer] quand l'écran se ferme.
///
/// ⚠ Ce porteur ne **charge** rien : il n'a donc pas de source injectée par la
/// portée, contrairement à `Suivi`. Écrire un `sourceSessionPaiementProvider`
/// qui lèverait par défaut et que personne ne lirait aurait été une façade.
@Riverpod(keepAlive: true, retry: pasDeRetry)
class SessionPaiement extends _$SessionPaiement {
  Timer? _tic;

  @override
  EtatSessionPaiement? build(String commandeId) {
    // Le minuteur meurt avec la portée. Sans ce `onDispose`, il survivrait à
    // l'écran et écrirait dans un notifier détruit.
    ref.onDispose(_arreter);
    return null;
  }

  /// Pose la session rendue par le serveur et **recale** le compte à rebours.
  ///
  /// Appelée à chaque lecture : c'est le seul chemin par lequel `restantS`
  /// reçoit une valeur d'autorité. Le tic local ne fait que la faire descendre
  /// entre deux appels.
  void poser(EtatSessionPaiement session) {
    state = session;
    if (session.accepteEncore && session.restantS > 0) {
      _demarrer();
    } else {
      _arreter();
    }
  }

  /// Le compte à rebours local, une seconde à la fois.
  ///
  /// Arrivé à zéro il **s'arrête** — il n'annule rien et ne conclut rien. C'est
  /// l'écran qui relit alors l'état auprès du serveur ; lui seul sait si la
  /// session a expiré ou si un paiement est arrivé dans la dernière seconde.
  void _demarrer() {
    _arreter();
    _tic = Timer.periodic(const Duration(seconds: 1), (_) {
      final courant = state;
      if (courant == null) return;
      final restant = courant.restantS - 1;
      state = courant.auTemps(restant);
      if (restant <= 0) _arreter();
    });
  }

  void _arreter() {
    _tic?.cancel();
    _tic = null;
  }

  /// L'écran se ferme : le compte à rebours n'a plus personne à informer.
  ///
  /// Sans cet appel, une portée `keepAlive` laisserait un minuteur réveiller le
  /// processeur une fois par seconde pour un écran que plus personne ne regarde
  /// — sur des téléphones d'entrée de gamme, ce genre de détail se sent.
  void liberer() => _arreter();

  /// Vrai si le compte à rebours local tourne — exposé pour que les tests
  /// puissent constater qu'il s'arrête, plutôt que d'attendre pour le croire.
  @visibleForTesting
  bool get ticActif => _tic != null;
}
