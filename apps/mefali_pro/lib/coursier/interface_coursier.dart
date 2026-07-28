/// Espace coursier de Mefali Pro — l'**aiguillage** des trois écrans de Yao.
///
/// Le cycle DSP 009 a livré K1 (disponibilité) et K2 (offre) sans les brancher :
/// l'espace coursier menait directement à la course active, et les deux écrans
/// n'étaient atteignables que par leurs tests widget. Un coursier ne pouvait
/// donc **jamais** se mettre en ligne depuis l'app, ni voir une offre arriver.
/// Défaut trouvé à la validation sur émulateur (T071).
///
/// L'aiguillage suit ce que Yao vit, dans l'ordre d'urgence :
///
/// 1. une **offre en vol** prend tout l'écran — elle a 40 s, rien ne passe
///    devant (K2, DSP-04) ;
/// 2. une **course assignée** occupe l'écran tant qu'elle dure — pendant une
///    course, aucune offre ne lui parvient (`course_active` l'exclut du vivier),
///    et son plafond du jour est déjà engagé ;
/// 3. sinon, **K1** : en ligne / hors ligne, plafond d'avance du jour.
///
/// **C'est ici, et ici seulement, que bat la mesure** de l'interrogation
/// d'offre (research R16) : `GET /courses/offre-courante` est appelé toutes les
/// 2 s — mais uniquement quand une offre peut RÉELLEMENT arriver, c'est-à-dire
/// quand Yao est en ligne et sans course en cours. Le mettre plus bas — dans K1
/// seul — le laisserait sans offre dès qu'il regarde autre chose ; le mettre
/// dans le provider en ferait une horloge qui tourne sur un arbre démonté, ce
/// que `OffreEnCours` refuse explicitement ; en poser une SECONDE dans K2
/// doublait le débit pendant les 40 s de décision.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import '../roles/etat_roles.dart';
import '../roles/interface_pro.dart';
import 'course/ecran_course_active.dart';
import 'course/etat_course.dart';
import 'disponibilite/ecran_disponibilite.dart';
import 'disponibilite/emetteur_position.dart';
import 'disponibilite/etat_disponibilite.dart';
import 'offre/ecran_offre.dart';
import 'offre/etat_offre.dart';

/// L'espace coursier.
///
/// `@Dependencies` remonte celle d'[`EcranDisponibilite`] : c'est cet écran qui
/// observe l'émetteur de position, et sans la déclaration ici un point de
/// montage qui surcharge la source de positions verrait son override ignoré.
@Dependencies([EmetteurPosition])
class InterfaceCoursier extends ConsumerStatefulWidget {
  /// Crée l'espace coursier.
  const InterfaceCoursier({super.key, required this.etat});

  /// Rôles du compte connecté.
  final EtatRolesData etat;

  @override
  ConsumerState<InterfaceCoursier> createState() => _InterfaceCoursierState();
}

class _InterfaceCoursierState extends ConsumerState<InterfaceCoursier> {
  /// Tic d'interrogation de l'offre — **local**, annulé au démontage.
  Timer? _tic;

  /// Identifiant de l'offre que K2 tient à l'écran, ou `null`.
  ///
  /// Il SURVIT à la disparition de l'offre côté serveur, et c'est tout son
  /// intérêt : `GET /courses/offre-courante` rend `204` dès qu'une offre est
  /// échue ou conclue, et sans cette mémoire K2-1b — « sans pénalité, n sur
  /// 3 aujourd'hui » — clignoterait deux secondes avant de disparaître. Yao doit
  /// pouvoir LIRE qu'il n'a pas été puni.
  String? _offreTenue;

  /// Identifiant de l'offre que Yao a REFERMÉE.
  ///
  /// Distinct de [_offreTenue] : oublier simplement l'offre tenue la ferait
  /// revenir au tic suivant tant que le serveur la rend encore. Une offre
  /// congédiée l'est pour de bon — une AUTRE offre, elle, a un autre
  /// identifiant et s'affiche normalement.
  String? _offreCongediee;

  @override
  void initState() {
    super.initState();
    _tic = Timer.periodic(periodeInterrogation, (_) {
      if (!mounted || !_uneOffrePeutArriver()) return;
      ref.invalidate(offreEnCoursProvider);
    });
  }

  /// Une offre peut-elle RÉELLEMENT arriver à cet instant ?
  ///
  /// Interroger quand la réponse est non coûte de l'argent à Yao — forfait
  /// prépayé — et sa batterie : le tic tournait tant que l'espace coursier
  /// était monté, soit ~1 800 `GET /courses/offre-courante` par heure pour un
  /// coursier **hors ligne** qui laisse l'app ouverte.
  ///
  /// Les deux cas où le serveur ne peut rien envoyer :
  ///
  /// - **hors ligne** : Yao n'est pas dans le vivier (contrat §1.1) ;
  /// - **en course** : `course_active` l'en exclut (FR-007).
  bool _uneOffrePeutArriver() {
    if (!ref.read(disponibiliteProvider).enLigne) return false;
    final course = ref.read(etatCourseActiveProvider).value;
    return course == null || course.arrets.isEmpty;
  }

  @override
  void dispose() {
    _tic?.cancel();
    super.dispose();
  }

  /// Yao a conclu : offre acceptée, refusée, ou panneau refermé.
  ///
  /// La course active est RELUE au passage. Sans cela, un coursier qui vient
  /// d'accepter retombe sur K1 — il a gagné la course, et son app ne la lui
  /// montre pas. `EtatCourseActive` n'a aucune raison de savoir tout seul qu'une
  /// offre vient d'être acceptée : c'est ici qu'on l'apprend.
  void _congedier(String offreId) {
    if (!mounted) return;
    setState(() => _offreCongediee = offreId);
    ref.invalidate(etatCourseActiveProvider);
  }

  @override
  Widget build(BuildContext context) {
    // L'émetteur de position est observé ICI, pas dans K1 seul : « tant qu'un
    // écran de dispatch est monté » (research R15) vaut pour les TROIS écrans.
    // Le laisser à K1 faisait cesser la publication dès que K2 prenait l'écran
    // — sans conséquence sur les 40 s d'une offre, mais K2-1b reste jusqu'à ce
    // que Yao le referme, et le coursier sortait du pool en lisant « restez en
    // ligne : une autre course arrive bientôt ».
    //
    // L'INTENTION d'être en ligne, elle, se charge dans `Disponibilite.build`
    // — une fois par session, quel que soit l'écran monté. Tant qu'elle
    // appartenait à K1, un coursier dont Android tue l'app en pleine course la
    // rouvrait sur l'écran de course : K1 jamais monté, `enLigne` faux, aucune
    // position publiée, et le serveur reprenait la course faute de progression.
    ref.watch(emetteurPositionProvider);

    final valides = widget.etat.rolesValides;
    // Bascule de rôle en entête UNIQUEMENT si deux rôles validés — passée à
    // l'écran destinataire, qui la rend dans son propre Scaffold (aucune
    // imbrication).
    final entete = valides.length > 1
        ? BasculeRoles(valides: valides, actif: RolePro.coursier)
        : null;

    // 1. Offre — elle passe devant tout. K2 tranche lui-même entre l'offre
    //    vivante (K2-1a) et le panneau d'expiration (K2-1b) : l'aiguillage ne
    //    fait que lui laisser l'écran jusqu'à ce que Yao ait conclu.
    final offre = ref.watch(offreEnCoursProvider).value;
    if (offre != null && offre.offreId != _offreTenue) {
      // Hors du build : écrire un champ pendant la construction du frame est
      // exactement ce que la leçon du cycle 004 interdit.
      Future.microtask(() {
        if (mounted) setState(() => _offreTenue = offre.offreId);
      });
    }
    final tenue = offre?.offreId ?? _offreTenue;
    if (tenue != null && tenue != _offreCongediee) {
      return EcranOffre(onTermine: () => _congedier(tenue));
    }

    // 2. Course assignée — tant qu'elle dure, elle occupe l'écran.
    final course = ref.watch(etatCourseActiveProvider).value;
    if (course != null && course.arrets.isNotEmpty) {
      return EcranCourseActive(entete: entete);
    }

    // 3. Sinon K1 : c'est là que Yao décide s'il travaille, et pour combien.
    return EcranDisponibilite(entete: entete);
  }
}
