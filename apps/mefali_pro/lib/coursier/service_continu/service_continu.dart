/// **Le service qui garde l'app vivante, écran éteint** (CRS-02, US7).
///
/// Le cycle 009 l'avait constaté sans pouvoir le combler : téléphone en poche,
/// écran éteint, Yao ne sait pas qu'une course lui est offerte — et pire, il
/// sort du vivier par expiration parce que plus aucune position n'est publiée.
///
/// **Ce que le natif fait, et rien de plus** : maintenir le processus vivant
/// (service de premier plan Android + notification permanente). Toute la
/// logique reste en Dart, dans l'isolate principal (R12) — c'est ce qui permet
/// à Shorebird de corriger un comportement sans passage store, alors que le
/// natif, lui, ne se patche pas.
///
/// **Jamais deux horloges à la fois** (R13) :
///
/// | Horloge | Premier plan | Écran éteint |
/// |---|---|---|
/// | position | `EmetteurPosition` (cycle 009) | **le même** — il continue |
/// | offre | `InterfaceCoursier`, 2 s (cycle 009) | ce service, période de zone |
/// | présence | `EcranPreuves` (T060) | ce service |
///
/// La **position n'a pas d'horloge ici**, et c'est délibéré : `EmetteurPosition`
/// est observé par `InterfaceCoursier`, donc monté dans tout l'espace coursier,
/// et sa cadence bat déjà à la période de zone. Ce qui l'arrêtait écran éteint,
/// ce n'était pas l'absence d'horloge — c'était la suspension du processus par
/// Android. C'est exactement ce que ce service empêche. Ajouter une seconde
/// horloge de position doublerait le débit sans rien couvrir de plus.
///
/// Les deux autres, en revanche, ont besoin d'un relais : l'écran d'offre n'est
/// pas monté quand Yao range son téléphone, et l'écran des preuves peut être
/// fermé pendant les dix minutes d'attente. La bascule se fait sur le **cycle
/// de vie de l'app**, pas sur un drapeau que quelqu'un pourrait oublier.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../course/etat_course.dart';
import '../disponibilite/etat_disponibilite.dart';
import '../offre/etat_offre.dart';
import '../preuves/etat_preuves.dart';
import 'canal_offre.dart';

part 'service_continu.g.dart';

/// Identifiant du canal Android de la notification **permanente**.
///
/// Distinct de [canalOffreId], et c'est essentiel : celui-ci est volontairement
/// discret (importance basse, aucun son) — il dit « l'app tourne », il ne
/// réveille personne. Les confondre rendrait la sonnerie d'offre inaudible ou
/// la notification permanente insupportable.
const String canalServiceId = 'mefali_service_continu';

/// Le service de premier plan, vu par l'app.
///
/// Port doublable : un test widget n'a aucun canal de plateforme, et le vrai
/// plugin lèverait dès `startService`.
abstract class ServicePremierPlan {
  /// Démarre le service et affiche sa notification permanente.
  ///
  /// Rend `false` si le système refuse — Yao doit l'apprendre par un message,
  /// pas par l'absence de courses (FR-115).
  Future<bool> demarrer({
    required String titre,
    required String texte,
    required String canalNom,
  });

  /// Arrête le service et retire la notification.
  Future<void> arreter();

  /// Le service tourne-t-il ? Interrogé au réveil de l'app : Android peut
  /// l'avoir tué, et c'est **la** manière de l'apprendre.
  Future<bool> tourne();
}

/// Implémentation réelle, sur `flutter_foreground_task`.
class ServicePremierPlanForeground implements ServicePremierPlan {
  @override
  Future<bool> demarrer({
    required String titre,
    required String texte,
    required String canalNom,
  }) async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: canalServiceId,
        channelName: canalNom,
        // DISCRÈTE, et c'est voulu : elle accompagne Yao toute la journée. Une
        // notification permanente qui sonne se fait désactiver le premier jour,
        // et avec elle le service tout entier.
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        playSound: false,
        enableVibration: false,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        // Aucun `TaskHandler` : le service ne fait que maintenir le processus.
        // Les horloges vivent dans l'isolate principal, en Dart (R12).
        eventAction: ForegroundTaskEventAction.nothing(),
        allowWakeLock: true,
        // Le service DOIT survivre au balayage de l'app : Yao range son
        // téléphone, il ne se met pas hors ligne.
        stopWithTask: false,
      ),
    );

    final permission = await FlutterForegroundTask.requestNotificationPermission();
    if (permission != NotificationPermission.granted) return false;

    final resultat = await FlutterForegroundTask.startService(
      // `location` — c'est bien une position que ce service publie, et
      // Android 14+ exige que le type déclaré corresponde à la permission
      // `FOREGROUND_SERVICE_LOCATION` du manifeste. `dataSync` serait plafonné
      // à 6 h par 24 h, ce qu'une journée de courses dépasse.
      serviceTypes: [ForegroundServiceTypes.location],
      notificationTitle: titre,
      notificationText: texte,
    );
    return resultat is ServiceRequestSuccess;
  }

  @override
  Future<void> arreter() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }

  @override
  Future<bool> tourne() => FlutterForegroundTask.isRunningService;
}

/// Service INERTE — tests widget et plateformes sans service de premier plan.
class ServicePremierPlanInerte implements ServicePremierPlan {
  /// Crée le double.
  ServicePremierPlanInerte({this.autorise = true});

  /// Ce que [demarrer] rendra — `false` simule un refus système.
  final bool autorise;

  /// Nombre de démarrages demandés.
  int demarrages = 0;

  /// Nombre d'arrêts demandés.
  int arrets = 0;

  /// État simulé du service. Modifiable par le test pour jouer un arrêt SUBI.
  bool actif = false;

  @override
  Future<bool> demarrer({
    required String titre,
    required String texte,
    required String canalNom,
  }) async {
    demarrages++;
    actif = autorise;
    return autorise;
  }

  @override
  Future<void> arreter() async {
    arrets++;
    actif = false;
  }

  @override
  Future<bool> tourne() async => actif;
}

/// Le service de premier plan — **scopé**, pour que les tests l'injectent.
@Riverpod(keepAlive: true, dependencies: [])
ServicePremierPlan servicePremierPlan(Ref ref) => ServicePremierPlanForeground();

/// Le canal de sonnerie d'offre — **scopé**, même raison.
@Riverpod(keepAlive: true, dependencies: [])
CanalOffre canalOffre(Ref ref) => CanalOffreNotifications();

/// Pourquoi le service ne tourne pas, quand il devrait.
enum MotifServiceArrete {
  /// Rien à signaler.
  aucun,

  /// La permission de notifier a été refusée : sans elle, ni notification
  /// permanente, ni sonnerie d'offre (FR-115).
  permissionRefusee,

  /// Android a tué le service. Yao doit l'APPRENDRE — le découvrir en ne
  /// recevant plus rien lui ferait croire qu'il n'y a pas de courses.
  arreteParSysteme,
}

/// État du service continu (K1, bandeau discret).
class EtatServiceContinu {
  /// Crée l'état.
  const EtatServiceContinu({
    this.actif = false,
    this.motif = MotifServiceArrete.aucun,
    this.enArrierePlan = false,
  });

  /// Le service tourne.
  final bool actif;

  /// Pourquoi il ne tourne pas, le cas échéant.
  final MotifServiceArrete motif;

  /// L'app est en arrière-plan : c'est ce service qui tient les horloges.
  final bool enArrierePlan;

  /// Y a-t-il quelque chose à dire à Yao ?
  bool get aUnProbleme => motif != MotifServiceArrete.aucun;

  /// Copie avec substitution.
  EtatServiceContinu copieAvec({
    bool? actif,
    MotifServiceArrete? motif,
    bool? enArrierePlan,
  }) =>
      EtatServiceContinu(
        actif: actif ?? this.actif,
        motif: motif ?? this.motif,
        enArrierePlan: enArrierePlan ?? this.enArrierePlan,
      );
}

/// Processus du service continu (CRS-02, US7).
///
/// `Notifier` et non `AsyncNotifier` (constitution XII, R15) : ce n'est pas un
/// chargement, c'est un **processus** qui dure toute une journée de travail.
///
/// **`keepAlive: true`** : le service survit à tous les écrans. Un `autoDispose`
/// l'arrêterait dès que Yao quitte K1 — c'est-à-dire au moment précis où il
/// range son téléphone.
///
/// ⚠ Les minuteries vivent **ici** et nulle part ailleurs, et elles sont
/// annulées dans `ref.onDispose` : un `Timer` qui survit à sa portée fait
/// échouer les tests par « a Timer is still pending » (piège du cycle 004). La
/// différence avec `EtatPreuves` est assumée : là-bas la minuterie sert
/// l'affichage et appartient au widget ; ici elle EST le service.
@Riverpod(
  keepAlive: true,
  dependencies: [servicePremierPlan, canalOffre, textesService],
)
class ServiceContinu extends _$ServiceContinu {
  Timer? _offre;
  Timer? _presence;

  /// Dernière offre annoncée — une même offre ne sonne pas deux fois.
  String? _offreAnnoncee;

  @override
  EtatServiceContinu build() {
    ref.onDispose(_arreterLesHorloges);
    // La bascule en ligne / hors ligne PILOTE le service (FR-111, FR-112).
    // `listen` et non `watch` : le service ne se reconstruit pas à chaque
    // publication de position, il réagit au seul changement d'intention.
    ref.listen(
      disponibiliteProvider.select((e) => e.enLigne),
      (avant, apres) {
        if (apres == true) {
          demarrer();
        } else {
          arreter();
        }
      },
    );
    return const EtatServiceContinu();
  }

  /// Démarre le service — appelé à la mise en ligne (FR-111).
  Future<void> demarrer() async {
    final l10n = ref.read(textesServiceProvider);
    final canal = ref.read(canalOffreProvider);
    final service = ref.read(servicePremierPlanProvider);

    // Le canal de sonnerie AVANT le service : sans permission de notifier, le
    // service ne démarrera pas non plus, et le dire une seule fois suffit.
    final sonnerieOk = await canal.preparer(
      nom: l10n.canalOffreNom,
      description: l10n.canalOffreDescription,
    );
    final demarre = await service.demarrer(
      titre: l10n.notificationTitre,
      texte: l10n.notificationTexte,
      canalNom: l10n.canalServiceNom,
    );

    state = state.copieAvec(
      actif: demarre,
      motif: demarre && sonnerieOk
          ? MotifServiceArrete.aucun
          : MotifServiceArrete.permissionRefusee,
    );
    if (demarre) _armerLesHorloges();
  }

  /// Arrête le service — appelé à la mise hors ligne (FR-112).
  ///
  /// L'arrêt est **complet** : plus une position publiée, plus une sonnerie.
  /// Un service qui survivrait à la mise hors ligne continuerait à consommer la
  /// batterie de quelqu'un qui a fini sa journée.
  Future<void> arreter() async {
    _arreterLesHorloges();
    await ref.read(canalOffreProvider).taire();
    await ref.read(servicePremierPlanProvider).arreter();
    state = const EtatServiceContinu();
  }

  /// Suit le cycle de vie de l'app — c'est **la** bascule des horloges (R13).
  ///
  /// Au retour au premier plan, le service vérifie qu'il tourne toujours :
  /// Android a pu le tuer pendant que l'écran était éteint, et c'est le seul
  /// moment où on peut l'apprendre.
  Future<void> changerCycleDeVie(AppLifecycleState cycle) async {
    final enArrierePlan = cycle != AppLifecycleState.resumed;
    state = state.copieAvec(enArrierePlan: enArrierePlan);

    if (!state.actif) return;
    if (!enArrierePlan) {
      final tourne = await ref.read(servicePremierPlanProvider).tourne();
      if (!tourne) {
        _arreterLesHorloges();
        state = state.copieAvec(
          actif: false,
          motif: MotifServiceArrete.arreteParSysteme,
        );
      }
    }
  }

  /// Arme les deux horloges de relais.
  void _armerLesHorloges() {
    _arreterLesHorloges();
    _offre = Timer.periodic(periodeOffreArrierePlan, (_) => _regarderUneOffre());
    _presence = Timer.periodic(
      periodeEchantillonPresence,
      (_) => _echantillonnerPresence(),
    );
  }

  void _arreterLesHorloges() {
    _offre?.cancel();
    _presence?.cancel();
    _offre = null;
    _presence = null;
  }

  /// Interroge l'offre courante **en arrière-plan seulement** (R13, FR-100).
  ///
  /// Au premier plan, `InterfaceCoursier` le fait déjà toutes les 2 s. Doubler
  /// le débit pendant les 40 s d'une décision est exactement ce que le cycle
  /// 009 avait refusé.
  Future<void> _regarderUneOffre() async {
    if (!state.actif || !state.enArrierePlan) return;

    // ⚠ `ref.read` d'un provider `autoDispose` depuis un provider `keepAlive` :
    // le lint le signale par principe, et il a raison dans le cas général — un
    // service qui ferait NAÎTRE ces providers les rechargerait toutes les cinq
    // secondes en arrière-plan. Ce n'est pas le cas ici : l'espace coursier est
    // monté tant que Yao travaille, et il OBSERVE déjà les trois. Ces lectures
    // tombent donc sur des instances vivantes, sans rien maintenir en vie.
    // Silences obligatoires (FR-101, FR-102) : hors ligne ou déjà en course,
    // aucune offre ne peut parvenir — sonner serait un réveil pour rien.
    // ignore: only_use_keep_alive_inside_keep_alive
    final course = ref.read(etatCourseActiveProvider).value;
    final enCourse = course != null && course.arrets.isNotEmpty;
    if (!sonnerieAutorisee(
      enLigne: ref.read(disponibiliteProvider).enLigne,
      enCourse: enCourse,
    )) {
      return;
    }

    ref.invalidate(offreEnCoursProvider);
    // ignore: only_use_keep_alive_inside_keep_alive
    final offre = ref.read(offreEnCoursProvider).value;
    if (offre == null) {
      // L'offre a disparu (échue, prise, refusée) : la notification s'efface.
      if (_offreAnnoncee != null) {
        _offreAnnoncee = null;
        await ref.read(canalOffreProvider).taire();
      }
      return;
    }
    if (offre.offreId == _offreAnnoncee) return;
    if (offre.estEchue(DateTime.now())) return;

    _offreAnnoncee = offre.offreId;
    final l10n = ref.read(textesServiceProvider);
    await ref.read(canalOffreProvider).sonner(
          AnnonceOffre(
            offreId: offre.offreId,
            titre: l10n.offreTitre,
            // Le temps RÉELLEMENT restant, pas la durée nominale du timer :
            // entre l'émission et le réveil, quelques secondes sont passées, et
            // afficher « 40 s » ferait croire à Yao qu'il a le temps (FR-100).
            texte: l10n.offreTexte(offre.restantS(DateTime.now())),
          ),
        );
  }

  /// Échantillonne la présence **écran éteint** (FR-114, SC-019).
  ///
  /// C'est la moitié invisible de la preuve d'échec : dix minutes d'attente
  /// devant une porte close se passent téléphone en poche. Sans le service, le
  /// processus s'endort et la présence ne se mesure jamais — Yao aurait attendu
  /// pour rien.
  ///
  /// Au premier plan, `EcranPreuves` s'en charge (T060) : jamais les deux.
  Future<void> _echantillonnerPresence() async {
    if (!state.actif || !state.enArrierePlan) return;
    // Même remarque que dans `_regarderUneOffre` : instance déjà vivante.
    // ignore: only_use_keep_alive_inside_keep_alive
    final course = ref.read(etatCourseActiveProvider).value;
    // Seulement une fois ARRIVÉ chez le client : avant, la présence ne prouve
    // rien, et l'échantillonner allumerait le GPS toute la course.
    if (course == null || course.remise.arriveChezClientLe == null) return;
    final livraison = course.livraisonId;
    if (livraison == null || livraison.isEmpty) return;
    await ref
        // ignore: only_use_keep_alive_inside_keep_alive
        .read(etatPreuvesProvider.notifier)
        .echantillonnerPresence(livraison);
  }
}

/// Période d'interrogation d'offre **en arrière-plan** (R13).
///
/// Miroir local de `coursier.offre_interrogation_arriere_plan_s` : le paramètre
/// de zone n'est pas servi à l'app, et l'écart tolérable est celui d'un réveil
/// — pas celui d'une décision. Le premier plan, lui, reste à 2 s (cycle 009).
const Duration periodeOffreArrierePlan = Duration(seconds: 5);

/// Les textes du service, résolus **hors du contexte de widget**.
///
/// Un service peut devoir notifier alors qu'aucun `BuildContext` n'est
/// disponible (app en arrière-plan, arbre non monté). Les clés i18n restent la
/// source — elles sont simplement injectées ici plutôt que lues d'un contexte
/// qui n'existe pas (constitution VII respectée : aucune chaîne en dur dans
/// l'app, celles-ci viennent de l'ARB via le point de montage).
class TextesService {
  /// Crée les textes.
  const TextesService({
    required this.notificationTitre,
    required this.notificationTexte,
    required this.canalServiceNom,
    required this.canalOffreNom,
    required this.canalOffreDescription,
    required this.offreTitre,
    required this.offreTexte,
  });

  /// Titre de la notification permanente.
  final String notificationTitre;

  /// Corps de la notification permanente.
  final String notificationTexte;

  /// Nom du canal du service (réglages Android).
  final String canalServiceNom;

  /// Nom du canal d'offre.
  final String canalOffreNom;

  /// Description du canal d'offre.
  final String canalOffreDescription;

  /// Titre de la sonnerie d'offre.
  final String offreTitre;

  /// Corps de la sonnerie, avec le temps réellement restant.
  final String Function(int secondes) offreTexte;
}

/// Textes du service — **scopé** : le point de montage les résout depuis l'ARB.
///
/// Le défaut est volontairement vide plutôt que fabriqué : une chaîne en dur
/// ici passerait la revue i18n sans être traduisible.
@Riverpod(keepAlive: true, dependencies: [])
TextesService textesService(Ref ref) => TextesService(
      notificationTitre: '',
      notificationTexte: '',
      canalServiceNom: '',
      canalOffreNom: '',
      canalOffreDescription: '',
      offreTitre: '',
      offreTexte: (_) => '',
    );
