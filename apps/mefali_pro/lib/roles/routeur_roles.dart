import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
class RouteurRoles extends ConsumerStatefulWidget {
  /// Crée le routeur.
  const RouteurRoles({super.key});

  @override
  ConsumerState<RouteurRoles> createState() => _RouteurRolesState();
}

class _RouteurRolesState extends ConsumerState<RouteurRoles> {
  List<String> _transportsActifs = const [];

  @override
  void initState() {
    super.initState();
    // Le chargement est DÉCLENCHÉ ICI (le provider ne charge rien dans build()).
    // L'état des rôles NAÎT avec cet écran et MEURT avec lui (autoDispose) : à la
    // déconnexion `RacineAuth` démonte le routeur, et l'arête `.select(connecte)`
    // le vide de toute façon — les rôles du compte précédent ne survivent pas.
    //
    // DIFFÉRÉ d'un microtask : `charger()` modifie l'état SYNCHRONEMENT dès sa
    // première ligne (charge=false, pour que ChargementPro réapparaisse au
    // rafraîchissement — FR-022), et Riverpod interdit de modifier un provider
    // pendant `initState`. `Session.charger()`, lui, `await` avant tout `state =`,
    // d'où l'absence de ce report côté RacineAuth.
    Future.microtask(() {
      if (mounted) ref.read(etatRolesProvider.notifier).charger();
    });
    _lireTransports();
  }

  /// Récupère les véhicules déclarables dès que la config est là.
  ///
  /// INSTANTANÉ FIGÉ (FR-021) : lu par `ref.read`, JAMAIS `ref.watch`. En
  /// silence : leur absence ne casse pas l'écran d'état, elle se voit dans le
  /// formulaire — le seul endroit où elle compte.
  Future<void> _lireTransports() async {
    try {
      final service = await ref.read(serviceConfigProvider);
      final actifs = service.courante?.transportsActifs ?? const <String>[];
      if (mounted) setState(() => _transportsActifs = actifs);
    } catch (_) {
      // Config injoignable : le formulaire le dira.
    }
  }

  @override
  Widget build(BuildContext context) {
    final etat = ref.watch(etatRolesProvider);
    if (!etat.charge) return const ChargementPro();
    if (etat.enErreur) return const ErreurPro();
    // Aucun rôle pro validé : ni coursier, ni vendeur (FR-013).
    if (etat.rolesValides.isEmpty) {
      return EcranEtatDemande(etat: etat, transportsActifs: _transportsActifs);
    }
    return InterfacePro(etat: etat);
  }
}
