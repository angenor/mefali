import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../l10n/app_localizations.dart';
import 'composants.dart';
import 'etat_roles.dart';

/// Libellés et tons des rôles/statuts — un seul endroit, pour que l'écran
/// d'état et la bascule ne divergent jamais (FR-024 : aucune chaîne en dur).
extension LibellesRoles on AppLocalizations {
  /// Libellé d'un rôle professionnel.
  String role(RolePro role) => switch (role) {
        RolePro.coursier => proRoleCoursier,
        RolePro.vendeur => proRoleVendeur,
      };

  /// Libellé d'un statut d'attribution.
  String statutRole(StatutRolePro statut) => switch (statut) {
        StatutRolePro.aucun => proStatutAucun,
        StatutRolePro.enAttente => proStatutEnAttente,
        StatutRolePro.valide => proStatutValide,
        StatutRolePro.refuse => proStatutRefuse,
        StatutRolePro.suspendu => proStatutSuspendu,
      };

  /// Libellé d'un type de transport du référentiel ZON-03.
  ///
  /// Le slug est du PROTOCOLE ; son libellé est une clé i18n (FR-024). Le
  /// référentiel porte bien un `nom_cle` côté backend, mais `/config` ne sert
  /// que les slugs ACTIFS — le libellé se résout donc ici.
  ///
  /// Un slug inconnu de cette app (type ajouté au référentiel après une version)
  /// s'affiche tel quel : mieux vaut un mot brut qu'une case sans nom.
  String transport(String slug) => switch (slug) {
        'a_pied' => proTransportAPied,
        'velo' => proTransportVelo,
        'moto' => proTransportMoto,
        'tricycle_taxi' => proTransportTricycleTaxi,
        'tricycle_cargo' => proTransportTricycleCargo,
        'voiture' => proTransportVoiture,
        'camionnette' => proTransportCamionnette,
        'camion' => proTransportCamion,
        _ => slug,
      };
}

/// Ton de la puce d'un statut (planche de style §4 — chips de statut).
TonPuce tonStatut(StatutRolePro statut) => switch (statut) {
      StatutRolePro.aucun => TonPuce.contour,
      StatutRolePro.enAttente => TonPuce.avertissement,
      StatutRolePro.valide => TonPuce.succes,
      StatutRolePro.refuse || StatutRolePro.suspendu => TonPuce.danger,
    };

/// Pictogramme d'un rôle — un picto à côté de chaque libellé important
/// (règle d'or 2 des tokens).
IconData pictoRole(RolePro role) => switch (role) {
      RolePro.coursier => Symbols.sports_motorsports,
      RolePro.vendeur => Symbols.storefront,
    };
