import 'package:flutter/material.dart';
import 'package:mefali_core/mefali_core.dart';

import 'ecran_etat_demande.dart';
import 'etat_roles.dart';
import 'interface_pro.dart';

/// Accueil de Mefali Pro : aiguille sur l'interface du rôle actif, ou sur
/// l'état de la demande (FR-013).
///
/// C'est la porte de l'app : `RacineAuth` garantit une session, ce routeur
/// garantit un RÔLE. Une session valide ne suffit pas — un compte client qui
/// installe Mefali Pro s'authentifie normalement et n'y trouve aucune fonction
/// pro, seulement l'état de sa demande (FR-011).
///
/// La porte qui FAIT foi reste celle du serveur (`exiger_role`, à chaque
/// requête — FR-009) : ce routeur n'est que sa traduction à l'écran.
class RouteurRoles extends StatefulWidget {
  /// Crée le routeur.
  const RouteurRoles({super.key, required this.session, this.etat});

  /// Session du compte connecté.
  final SessionAuth session;

  /// État injecté — réservé aux tests.
  ///
  /// En production l'état NAÎT avec cet écran et MEURT avec lui : à la
  /// déconnexion `RacineAuth` démonte le routeur, donc les rôles du compte
  /// précédent ne peuvent pas survivre à un changement de compte sur le même
  /// appareil.
  final EtatRoles? etat;

  @override
  State<RouteurRoles> createState() => _RouteurRolesState();
}

class _RouteurRolesState extends State<RouteurRoles> {
  late final EtatRoles _etat = widget.etat ?? EtatRoles(session: widget.session);

  @override
  void initState() {
    super.initState();
    _etat.charger();
  }

  @override
  void dispose() {
    // On ne dispose que ce que l'on a créé : l'état injecté appartient au test.
    if (widget.etat == null) _etat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _etat,
      builder: (context, _) {
        if (!_etat.charge) return const ChargementPro();
        if (_etat.enErreur) return ErreurPro(etat: _etat);
        // Aucun rôle pro validé : ni coursier, ni vendeur (FR-013).
        if (_etat.rolesValides.isEmpty) return EcranEtatDemande(etat: _etat);
        return InterfacePro(etat: _etat);
      },
    );
  }
}
