/// **Le canal qui réveille Yao** (CRS-02, T079).
///
/// Réf. `docs/design/png/K2-offre-course.png` — « Plein écran + sonnerie ».
///
/// Une offre a **40 secondes**. Téléphone en poche, écran éteint, une
/// notification ordinaire ne suffit pas : elle s'affiche en silence et l'offre
/// part à quelqu'un d'autre. D'où un canal **dédié**, de haute importance, à son
/// prolongé, qui ouvre directement l'écran d'offre — c'est le manque que le
/// cycle 009 avait constaté sans pouvoir le combler (R12).
///
/// **Deux silences obligatoires** (FR-101, FR-102) :
///
/// - **hors ligne**, aucune offre ne peut lui parvenir (il n'est pas dans le
///   vivier) : sonner serait un mensonge doublé d'un réveil pour rien ;
/// - **déjà en course**, `course_active` l'exclut du vivier : la sonnerie le
///   ferait sortir son téléphone au milieu d'un marché, sans rien à décider.
///
/// La règle vit **ici**, dans une fonction pure, et pas au point d'appel : un
/// seul endroit à relire pour savoir quand le téléphone a le droit de sonner.
library;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Identifiant du canal Android — **stable** : Android fige les réglages d'un
/// canal à sa création, et le renommer en créerait un second, muet, dont
/// personne ne comprendrait la présence dans les réglages du téléphone.
const String canalOffreId = 'mefali_offres_course';

/// Identifiant de la notification d'offre. Fixe : une offre en remplace une
/// autre plutôt que d'empiler des sonneries.
const int notificationOffreId = 4001;

/// Ce qu'une notification d'offre transporte à l'écran.
class AnnonceOffre {
  /// Crée l'annonce.
  const AnnonceOffre({
    required this.offreId,
    required this.titre,
    required this.texte,
  });

  /// Offre concernée — sert de charge utile à l'ouverture de K2.
  final String offreId;

  /// Titre affiché.
  final String titre;

  /// Corps affiché. ⚠ Aucun secret, aucune adresse : l'offre ne révèle la
  /// destination précise qu'après acceptation (contrat du cycle 009).
  final String texte;
}

/// Le canal d'offre, vu par l'app.
///
/// Port doublable : un test widget n'a pas de canal de plateforme, et le vrai
/// plugin lèverait à la première initialisation.
abstract class CanalOffre {
  /// Crée (ou retrouve) le canal et demande la permission de notifier.
  ///
  /// Rend `false` si la permission est refusée — Yao doit l'apprendre par un
  /// message explicite, pas par l'absence de sonnerie (FR-115).
  Future<bool> preparer({required String nom, required String description});

  /// Sonne pour une offre. Sans effet si le canal n'est pas prêt.
  Future<void> sonner(AnnonceOffre annonce);

  /// Retire la notification d'offre — offre acceptée, refusée ou échue.
  Future<void> taire();
}

/// Décide si le téléphone a le droit de sonner (FR-101, FR-102).
///
/// Fonction **pure**, testable sans plateforme : c'est la règle elle-même, pas
/// son exécution.
bool sonnerieAutorisee({required bool enLigne, required bool enCourse}) =>
    enLigne && !enCourse;

/// Implémentation réelle, sur `flutter_local_notifications`.
class CanalOffreNotifications implements CanalOffre {
  /// Construit le canal sur le plugin fourni (injecté pour les tests).
  CanalOffreNotifications([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _pret = false;

  @override
  Future<bool> preparer({
    required String nom,
    required String description,
  }) async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        // L'icône de l'app : `@mipmap/ic_launcher` existe dans tout projet
        // Flutter Android, y compris celui-ci (cycle plateformes natives).
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) {
      // iOS n'est pas vérifié (Xcode absent — dette du cycle plateformes
      // natives). Le canal n'existe pas, mais l'app fonctionne.
      _pret = false;
      return false;
    }

    // ⚠ Créé AVANT la première notification : Android fige les réglages d'un
    // canal à sa création. Un canal créé en `defaultImportance` resterait
    // silencieux à jamais, même si le code demandait `max` ensuite.
    await android.createNotificationChannel(
      AndroidNotificationChannel(
        canalOffreId,
        nom,
        description: description,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
    );

    // Demander NE DIT PAS si c'est autorisé. `requestNotificationsPermission`
    // rend `null` dans deux cas parfaitement normaux : Android < 13, où la
    // méthode est un no-op et où les notifications sont acquises d'office ; et
    // une permission DÉJÀ accordée, que le système ne redemande pas. Un
    // `?? false` sur ce `null` transformait ces deux cas en refus : `_pret`
    // restait faux, `sonner()` sortait aussitôt, et Yao n'était plus jamais
    // réveillé — le bandeau lui affirmant qu'il avait refusé une permission
    // qu'il avait accordée.
    //
    // La vérité est donc RELUE après la demande, jamais déduite d'elle.
    await android.requestNotificationsPermission();
    final autorise = await android.areNotificationsEnabled() ?? false;
    _pret = autorise;
    return autorise;
  }

  @override
  Future<void> sonner(AnnonceOffre annonce) async {
    if (!_pret) return;
    await _plugin.show(
      id: notificationOffreId,
      title: annonce.titre,
      body: annonce.texte,
      payload: annonce.offreId,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          canalOffreId,
          // Le nom du canal est REDONNÉ ici : le plugin l'exige, et Android
          // ignore la valeur si le canal existe déjà.
          'Offres de course',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
          // Plein écran : c'est ce qui réveille l'appareil verrouillé, et la
          // seule façon de tenir les 40 s d'une offre (K2).
          fullScreenIntent: true,
          category: AndroidNotificationCategory.call,
          // Non congédiable au balayage : une offre se décide, elle ne
          // s'écarte pas d'un geste distrait.
          ongoing: true,
        ),
      ),
    );
  }

  @override
  Future<void> taire() => _plugin.cancel(id: notificationOffreId);
}

/// Canal MUET — tests widget et plateformes sans notifications.
///
/// Il retient ce qu'on lui a demandé de sonner : c'est ce qui permet de
/// vérifier les deux silences obligatoires sans canal de plateforme.
class CanalOffreMuet implements CanalOffre {
  /// Crée le double.
  CanalOffreMuet({this.permissionAccordee = true});

  /// Ce que [preparer] rendra.
  final bool permissionAccordee;

  /// Annonces effectivement sonnées, dans l'ordre.
  final List<AnnonceOffre> sonnees = [];

  /// Nombre d'extinctions demandées.
  int taires = 0;

  /// Le canal a-t-il été préparé ?
  bool prepare = false;

  @override
  Future<bool> preparer({
    required String nom,
    required String description,
  }) async {
    prepare = true;
    return permissionAccordee;
  }

  @override
  Future<void> sonner(AnnonceOffre annonce) async => sonnees.add(annonce);

  @override
  Future<void> taire() async => taires++;
}
