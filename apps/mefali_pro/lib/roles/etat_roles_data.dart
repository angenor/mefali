import 'package:flutter/foundation.dart';

/// Rôle PROFESSIONNEL : les deux seuls que Mefali Pro sert (FR-013).
///
/// `client` et `admin` existent aussi côté backend mais n'ont rien à faire ici —
/// le premier vit dans l'app client, le second dans la console d'administration
/// (cycle ADM). Un compte qui ne porte QUE ces rôles-là n'a aucun rôle pro.
enum RolePro {
  /// Demandé in-app avec un dossier, validé par un admin (CPT-04).
  coursier('coursier'),

  /// Attribué par un admin à l'agrément — jamais demandé in-app (§5.1).
  vendeur('vendeur');

  const RolePro(this.valeur);

  /// Valeur de l'énum `comptes.role` du backend : c'est du PROTOCOLE, jamais
  /// affiché. Les libellés sont des clés i18n (FR-024).
  final String valeur;

  /// Rôle correspondant à une valeur du contrat, ou `null` si elle ne concerne
  /// pas Mefali Pro (`client`, `admin`, ou un rôle plus récent que cette app).
  static RolePro? depuis(String valeur) {
    for (final role in values) {
      if (role.valeur == valeur) return role;
    }
    return null;
  }
}

/// Statut d'une attribution (énum `comptes.statut_role`), plus son absence.
enum StatutRolePro {
  /// Aucune attribution : le rôle n'a jamais été demandé ni attribué. N'existe
  /// pas côté backend — c'est l'absence de ligne, que FR-013 doit présenter au
  /// même titre que les autres états.
  aucun(''),

  /// Dossier déposé, décision admin attendue.
  enAttente('en_attente'),

  /// Rôle ouvert : la seule porte d'entrée de Mefali Pro.
  valide('valide'),

  /// Demande refusée — le motif accompagne la décision (FR-017).
  refuse('refuse'),

  /// Rôle retiré temporairement, motif à l'appui.
  suspendu('suspendu');

  const StatutRolePro(this.valeur);

  /// Valeur du contrat — protocole, jamais affichée.
  final String valeur;

  /// Statut correspondant à une valeur du contrat.
  ///
  /// Une valeur INCONNUE retombe sur `aucun`, jamais sur `valide` : si un
  /// backend plus récent invente un statut, cette app doit fermer la porte, pas
  /// l'ouvrir (SC-005).
  static StatutRolePro depuis(String valeur) {
    for (final statut in values) {
      if (statut != aucun && statut.valeur == valeur) return statut;
    }
    return aucun;
  }
}

/// État d'un rôle pro tel que le backend le décrit.
@immutable
class AttributionPro {
  /// Crée un état de rôle.
  const AttributionPro({required this.role, required this.statut, this.motif});

  /// Rôle concerné.
  final RolePro role;

  /// Statut courant de l'attribution.
  final StatutRolePro statut;

  /// Motif de la dernière décision admin (refus, suspension).
  ///
  /// CONTENU saisi par l'admin, pas une clé i18n : il s'affiche tel quel.
  final String? motif;
}

/// État des rôles pro. Classe IMMUABLE, volontairement SANS `operator ==`
/// (mêmes règles qu'`EtatSession`), mais de sémantique INVERSE.
///
/// Son `Notifier` (`EtatRoles`) et le `updateShouldNotify => true` explicite
/// vivent dans `etat_roles.dart` ; ici, seule la valeur. `AsyncValue` est
/// INTERDIT sur ce porteur : il fusionnerait [charge] et [enErreur], qui sont
/// ORTHOGONAUX (R6).
@immutable
class EtatRolesData {
  /// Crée un état des rôles ; par défaut, rien n'a encore été chargé.
  const EtatRolesData({
    this.attributions = const [],
    this.charge = false,
    this.enErreur = false,
    this.actif,
  });

  /// Tous les rôles pro du compte, quel que soit leur statut.
  final List<AttributionPro> attributions;

  /// Le compte a-t-il été relu au moins une fois (succès OU échec) ?
  ///
  /// NON MONOTONE — contrairement à `EtatSession.charge` : `charger()` le remet à
  /// `false` ET notifie ⇒ `ChargementPro` RÉAPPARAÎT. FR-022 exige les DEUX
  /// sémantiques opposées.
  final bool charge;

  /// Le dernier chargement a-t-il échoué ? ORTHOGONAL à [charge] : sur erreur,
  /// `charge: true` ET `enErreur: true`, attributions CONSERVÉES.
  final bool enErreur;

  /// Rôle dont l'interface est affichée, ou `null` si aucun rôle pro validé.
  ///
  /// Sa MÉMOIRE entre deux `charger()` est une exigence produit : la perdre
  /// renverrait l'utilisateur à l'autre interface SOUS SES DOIGTS à chaque
  /// rafraîchissement.
  final RolePro? actif;

  /// Rôles pro VALIDÉS — la seule porte d'entrée de Mefali Pro (FR-011).
  ///
  /// L'ordre suit celui du backend (ordre de l'énum : coursier avant vendeur),
  /// donc stable d'un chargement à l'autre.
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
