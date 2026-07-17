import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'etat_roles_data.dart';

// Les types de données (RolePro, StatutRolePro, AttributionPro, EtatRolesData)
// vivent dans etat_roles_data.dart et sont ré-exportés : les écrans importent
// `etat_roles.dart` et y trouvent tout, sans dépendre du découpage interne.
export 'etat_roles_data.dart';

part 'etat_roles.g.dart';

/// Rôles du compte connecté, et rôle dont Mefali Pro affiche l'interface.
///
/// `@riverpod` NU (autoDispose) — le DÉFAUT du générateur est ici le bon réglage,
/// et c'est le SEUL provider du cycle dans ce cas. `keepAlive` serait une
/// RÉGRESSION DE SÉCURITÉ silencieuse : les rôles survivraient au changement de
/// compte (mode de panne n°3).
///
/// ## Pourquoi la bascule ne parle pas au réseau
///
/// FR-013 exige de passer d'une interface à l'autre « sans reconnexion », en
/// moins de 5 secondes (SC-006). Les rôles validés sont déjà en mémoire :
/// [basculer] ne fait que changer le rôle affiché — aucune requête, aucun jeton
/// touché.
@riverpod
class EtatRoles extends _$EtatRoles {
  @override
  EtatRolesData build() {
    // FR-020/SC-010 — l'arête GRAVÉE : session fermée ⇒ provider invalidé ⇒
    // build() rejoué ⇒ état VIDE avant tout rendu, même si quelqu'un met
    // `keepAlive: true` demain. `.select` et NON `ref.watch` nu : l'intercepteur
    // appelle `ouvrir()` à CHAQUE rotation de jeton ⇒ un `watch` nu rechargerait
    // les rôles à chaque renouvellement silencieux (requête ajoutée FR-002,
    // ChargementPro en plein parcours FR-001) — un chemin que seul un 401
    // déclenche, donc JAMAIS en test (R4). C'est une CORRECTION DE BUG.
    ref.watch(sessionProvider.select((e) => e.connecte));

    // build() NE charge RIEN : le chargement est déclenché par le routeur, et
    // `charger()` est rejouable SANS que build() retourne — c'est ce qui laisse
    // `actif` survivre à un rechargement (R8).
    return const EtatRolesData();
  }

  /// Les rôles sont l'INVERSE de la session : `charge` est NON MONOTONE — remis à
  /// `false` ET notifié, pour que `ChargementPro` réapparaisse. `updateShouldNotify`
  /// explicite : la v3 filtre par `==`, une classe sans `==` marche par accident.
  @override
  bool updateShouldNotify(EtatRolesData p, EtatRolesData n) => true;

  /// Relit `GET /moi` et recalcule les rôles.
  ///
  /// Le contrôle qui FAIT foi est celui du serveur, à chaque requête (FR-009) :
  /// ce que l'on tient ici n'est qu'un reflet, rafraîchi à l'ouverture et à la
  /// demande.
  Future<void> charger() async {
    // charge=false ⇒ ChargementPro réapparaît ; attributions et actif CONSERVÉS.
    state = EtatRolesData(
      attributions: state.attributions,
      actif: state.actif,
    );

    try {
      final reponse = await ref.read(clientSessionProvider).getMoiApi().moi();
      final compte = reponse.data;
      final attributions = <AttributionPro>[];
      for (final etat in compte?.roles ?? const <EtatRoleDto>[]) {
        final role = RolePro.depuis(etat.role);
        if (role == null) continue; // client / admin : hors Mefali Pro.
        attributions.add(
          AttributionPro(
            role: role,
            statut: StatutRolePro.depuis(etat.statut),
            motif: etat.motif,
          ),
        );
      }

      // On CONSERVE le rôle affiché s'il est toujours validé : un
      // rafraîchissement ne doit pas ramener l'utilisateur à l'autre interface
      // sous ses doigts. Sinon (premier chargement, ou rôle affiché suspendu
      // entre-temps), on retombe sur le premier rôle validé.
      final valides = attributions
          .where((a) => a.statut == StatutRolePro.valide)
          .map((a) => a.role)
          .toList(growable: false);
      final actifActuel = state.actif;
      final actif = (actifActuel != null && valides.contains(actifActuel))
          ? actifActuel
          : (valides.isEmpty ? null : valides.first);

      state = EtatRolesData(attributions: attributions, charge: true, actif: actif);
    } catch (_) {
      // Réseau coupé ou serveur en vrac : on le DIT (règle d'or 5), on ne laisse
      // pas un écran blanc. `enErreur: true` ORTHOGONAL à `charge: true`,
      // attributions CONSERVÉES.
      state = EtatRolesData(
        attributions: state.attributions,
        charge: true,
        enErreur: true,
        actif: state.actif,
      );
    }
  }

  /// Affiche l'interface d'un autre rôle validé (FR-013).
  ///
  /// Un rôle non validé est ignoré : la bascule n'est pas un chemin de
  /// contournement de la validation admin (SC-005). Ne parle NI au réseau NI à
  /// la session.
  void basculer(RolePro role) {
    if (state.actif == role || !state.rolesValides.contains(role)) return;
    state = EtatRolesData(
      attributions: state.attributions,
      charge: state.charge,
      enErreur: state.enErreur,
      actif: role,
    );
  }
}
