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
///
/// **La navigation basse (T076) vient SOUS cette règle, pas devant.** Ses trois
/// destinations — Tableau, Courses, Caisse — n'existent qu'aux points 2 et 3 :
/// une offre a 40 s pour être décidée, et lui laisser une barre d'onglets
/// donnerait à Yao le moyen de la perdre en tapant à côté. Une course active,
/// elle, garde la barre : consulter sa caisse au milieu d'une course est
/// légitime, et le retour à la course est immédiat.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import '../l10n/app_localizations.dart';
import '../roles/etat_roles.dart';
import '../roles/interface_pro.dart';
import 'caisse/ecran_caisse.dart';
import 'course/ecran_course_active.dart';
import 'course/etat_course.dart';
import 'disponibilite/ecran_disponibilite.dart';
import 'disponibilite/emetteur_position.dart';
import 'disponibilite/etat_disponibilite.dart';
import 'offre/ecran_offre.dart';
import 'offre/etat_offre.dart';
import 'service_continu/service_continu.dart';

/// Les trois destinations de la barre basse (K1, K5).
enum DestinationCoursier {
  /// K1 — disponibilité, plafond, gains du jour.
  tableau,

  /// K3 — la course active, ou son état vide.
  courses,

  /// K5 — la caisse.
  caisse,
}

/// L'espace coursier.
///
/// Son unique rôle propre : **poser les textes du service continu dans la
/// portée**. Le service peut devoir notifier alors qu'aucun `BuildContext`
/// n'est disponible — app en arrière-plan, arbre non monté — et les clés i18n
/// doivent donc être résolues **avant**, ici, où le contexte existe encore. Les
/// chaînes restent dans l'ARB fr (constitution VII) ; seule leur résolution
/// change de moment.
@Dependencies([EmetteurPosition, ServiceContinu])
class InterfaceCoursier extends ConsumerWidget {
  /// Crée l'espace coursier.
  const InterfaceCoursier({super.key, required this.etat});

  /// Rôles du compte connecté.
  final EtatRolesData etat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    return ProviderScope(
      overrides: [
        textesServiceProvider.overrideWithValue(
          TextesService(
            notificationTitre: t.crsServiceNotificationTitre,
            notificationTexte: t.crsServiceNotificationTexte,
            canalServiceNom: t.crsServiceNotificationTitre,
            canalOffreNom: t.crsServiceCanalOffreNom,
            canalOffreDescription: t.crsServiceCanalOffreDescription,
            offreTitre: t.crsServiceOffreTitre,
            offreTexte: t.crsServiceOffreTexte,
          ),
        ),
      ],
      child: _Aiguillage(etat: etat),
    );
  }
}

/// L'aiguillage lui-même — il porte tout l'état local de l'espace coursier.
///
/// `@Dependencies` remonte celle d'[`EcranDisponibilite`] : c'est cet écran qui
/// observe l'émetteur de position, et sans la déclaration ici un point de
/// montage qui surcharge la source de positions verrait son override ignoré.
/// [`ServiceContinu`] s'y ajoute pour la même raison — un test qui injecte un
/// service inerte doit être entendu.
@Dependencies([EmetteurPosition, ServiceContinu])
class _Aiguillage extends ConsumerStatefulWidget {
  const _Aiguillage({required this.etat});

  final EtatRolesData etat;

  @override
  ConsumerState<_Aiguillage> createState() => _InterfaceCoursierState();
}

class _InterfaceCoursierState extends ConsumerState<_Aiguillage>
    with WidgetsBindingObserver {
  /// Tic d'interrogation de l'offre — **local**, annulé au démontage.
  Timer? _tic;

  /// Destination choisie dans la barre basse — **état LOCAL du widget** : il ne
  /// survit pas à la session et n'intéresse personne d'autre (constitution XII).
  DestinationCoursier _destination = DestinationCoursier.tableau;

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
    // Le cycle de vie de l'app pilote la bascule des horloges (R13) : c'est le
    // seul signal fiable — un drapeau posé à la main serait oublié le jour où
    // un écran de plus s'intercale.
    WidgetsBinding.instance.addObserver(this);
    _tic = Timer.periodic(periodeInterrogation, (_) {
      if (!mounted || !_uneOffrePeutArriver()) return;
      ref.invalidate(offreEnCoursProvider);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState etat) {
    ref.read(serviceContinuProvider.notifier).changerCycleDeVie(etat);
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
  /// - **en arrière-plan** : c'est le service continu qui interroge, à la
  ///   période de zone (R13). Garder cette horloge-ci en plus doublerait le
  ///   débit exactement là où la batterie compte le plus.
  bool _uneOffrePeutArriver() {
    if (ref.read(serviceContinuProvider).enArrierePlan) return false;
    if (!ref.read(disponibiliteProvider).enLigne) return false;
    final course = ref.read(etatCourseActiveProvider).value;
    return course == null || course.arrets.isEmpty;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
    // Le service continu est OBSERVÉ ici, et nulle part ailleurs : c'est lui
    // qui écoute la bascule en ligne / hors ligne (FR-111, FR-112), et sans un
    // observateur il ne se construirait jamais — Yao se mettrait en ligne sans
    // que rien ne démarre.
    ref.watch(serviceContinuProvider);

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

    // 2. Course assignée — elle prend l'écran, et la barre basse la SUIT :
    //    consulter sa caisse au milieu d'une course est légitime, le retour est
    //    immédiat. Ce qui ne change pas, c'est la destination par défaut : une
    //    course active ouvre sur la course, jamais sur le tableau de bord.
    final course = ref.watch(etatCourseActiveProvider).value;
    final enCourse = course != null && course.arrets.isNotEmpty;
    final destination = enCourse && _destination == DestinationCoursier.tableau
        ? DestinationCoursier.courses
        : _destination;

    final barre = _BarreBasse(
      destination: destination,
      onChoisir: (d) => setState(() => _destination = d),
    );

    return switch (destination) {
      DestinationCoursier.caisse => EcranCaisse(
          entete: entete,
          barreBasse: barre,
          // K5-1b — « Passer en ligne » ramène au tableau de bord, où le
          // plafond d'avance se déclare : passer en ligne sans plafond est
          // refusé par le serveur (`capacite_non_declaree`, cycle 009).
          onPasserEnLigne: () =>
              setState(() => _destination = DestinationCoursier.tableau),
        ),
      // K3 gère lui-même son état vide (« aucune course en cours »).
      DestinationCoursier.courses =>
        EcranCourseActive(entete: entete, barreBasse: barre),
      // 3. K1 : c'est là que Yao décide s'il travaille, et pour combien.
      DestinationCoursier.tableau => EcranDisponibilite(
          entete: entete,
          barreBasse: barre,
          onCaisse: () =>
              setState(() => _destination = DestinationCoursier.caisse),
        ),
    };
  }
}

/// La barre basse à trois destinations (K1 et K5, FR-096).
///
/// `NavigationBar` Material 3 thémée depuis `mefali_core` — jamais une
/// transposition de la structure des exports HTML (constitution XI).
class _BarreBasse extends StatelessWidget {
  const _BarreBasse({required this.destination, required this.onChoisir});

  final DestinationCoursier destination;
  final ValueChanged<DestinationCoursier> onChoisir;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return NavigationBar(
      key: const Key('coursier-nav'),
      selectedIndex: destination.index,
      onDestinationSelected: (i) => onChoisir(DestinationCoursier.values[i]),
      backgroundColor: MefaliTokens.surface,
      indicatorColor: MefaliTokens.primaryTint,
      destinations: [
        NavigationDestination(
          icon: const Icon(Symbols.dashboard_rounded),
          label: t.crsNavTableau,
        ),
        NavigationDestination(
          icon: const Icon(Symbols.local_shipping_rounded),
          label: t.crsNavCourses,
        ),
        NavigationDestination(
          icon: const Icon(Symbols.account_balance_wallet_rounded),
          label: t.crsNavCaisse,
        ),
      ],
    );
  }
}
