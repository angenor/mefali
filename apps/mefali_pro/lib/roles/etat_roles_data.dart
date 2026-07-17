import 'package:flutter/foundation.dart';

import 'etat_roles.dart' show AttributionPro, RolePro, StatutRolePro;

/// État des rôles pro. Classe IMMUABLE, volontairement SANS `operator ==`
/// (mêmes règles qu'`EtatSession`), mais de sémantique INVERSE.
///
/// Son `Notifier` (`EtatRoles`) et le `updateShouldNotify => true` explicite
/// naissent en US4 ; ici, seule la valeur. `AsyncValue` est INTERDIT sur ce
/// porteur : il fusionnerait [charge] et [enErreur], qui sont ORTHOGONAUX (R6).
@immutable
class EtatRolesData {
  /// Crée un état des rôles ; par défaut, rien n'a encore été chargé.
  const EtatRolesData({
    this.attributions = const [],
    this.charge = false,
    this.enErreur = false,
    this.actif,
  });

  /// Tous les rôles pro du compte, quel que soit leur statut
  /// (`etat_roles.dart:107`).
  final List<AttributionPro> attributions;

  /// Le compte a-t-il été relu au moins une fois (succès OU échec) ?
  ///
  /// NON MONOTONE — contrairement à `EtatSession.charge` : `charger()` le remet à
  /// `false` ET notifie (`etat_roles.dart:156-158`) ⇒ `ChargementPro` RÉAPPARAÎT
  /// (`routeur_roles.dart:82`). FR-022 exige les DEUX sémantiques opposées.
  final bool charge;

  /// Le dernier chargement a-t-il échoué ? ORTHOGONAL à [charge] : sur erreur,
  /// `etat_roles.dart:189-192` produit `charge: true` ET `enErreur: true`,
  /// attributions CONSERVÉES.
  final bool enErreur;

  /// Rôle dont l'interface est affichée, ou `null` si aucun rôle pro validé.
  ///
  /// Sa MÉMOIRE entre deux `charger()` est une exigence produit
  /// (`etat_roles.dart:177-180`) : la perdre renverrait l'utilisateur à l'autre
  /// interface SOUS SES DOIGTS à chaque rafraîchissement.
  final RolePro? actif;

  /// Rôles pro VALIDÉS — la seule porte d'entrée de Mefali Pro (FR-011).
  ///
  /// L'ordre suit celui du backend (ordre de l'énum : coursier avant vendeur),
  /// donc stable d'un chargement à l'autre (`etat_roles.dart:122-128`).
  List<RolePro> get rolesValides => attributions
      .where((a) => a.statut == StatutRolePro.valide)
      .map((a) => a.role)
      .toList(growable: false);

  /// Statut d'un rôle pro — `aucun` s'il n'a jamais été demandé ni attribué.
  StatutRolePro statut(RolePro role) {
    for (final attribution in attributions) {
      if (attribution.role == role) return attribution.statut;
    }
    return StatutRolePro.aucun;
  }

  /// Motif de la dernière décision admin sur un rôle, s'il y en a une.
  String? motif(RolePro role) {
    for (final attribution in attributions) {
      if (attribution.role == role) return attribution.motif;
    }
    return null;
  }
}
