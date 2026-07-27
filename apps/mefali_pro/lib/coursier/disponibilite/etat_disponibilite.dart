/// Disponibilité du coursier (K1, DSP-01) — **porteur de processus**.
///
/// `Notifier<EtatDisponibilite>` en `@Riverpod(keepAlive: true)`, et le choix
/// est explicite (constitution XII) : la mise en ligne **traverse les écrans**.
/// Yao bascule son interrupteur sur K1, part sur l'écran d'offre, revient — et
/// il est toujours en ligne. Un `autoDispose` le ferait sortir du pool à chaque
/// changement d'écran, ce qui est exactement le bug que DSP-01 ne doit pas
/// avoir.
///
/// L'**offre courante**, elle, prendra l'autre moule : `AsyncNotifier` en
/// `@riverpod` nu, parce qu'un chargement d'offre est jetable.
///
/// Le compte à rebours d'une offre reste un **état local du widget** — jamais
/// providerifié : XII le nomme explicitement.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'etat_disponibilite.g.dart';

/// D'où vient le plafond qui s'applique — ce que K1 affiche à côté du montant.
enum SourcePlafond {
  /// Le palier de la grille (par note) limite l'avance.
  grilleNote,

  /// La déclaration de Yao s'applique — elle est plus basse.
  declaration;

  /// Depuis la valeur du contrat (`plafond_source`).
  static SourcePlafond depuis(String? brut) =>
      brut == 'declaration' ? SourcePlafond.declaration : SourcePlafond.grilleNote;
}

/// L'état de disponibilité tel que l'écran K1 l'affiche.
///
/// **Deux plafonds, jamais un** : le déclaré et le retenu. Un coursier à qui
/// l'on refuse une course sans lui dire que son palier le limite ne peut rien y
/// faire, et croira à un bug (FR-010).
class EtatDisponibilite {
  /// Construit l'état.
  const EtatDisponibilite({
    this.enLigne = false,
    this.plafondDeclareUnites,
    this.plafondRetenuUnites = 0,
    this.source = SourcePlafond.grilleNote,
    this.palierCle = 'dispatch.palier.entree',
    this.devise = 'XOF',
    this.dansLePool = false,
    this.periodePositionS = 30,
    this.capacites = const <String>[],
    this.chargement = false,
    this.horsLigne = false,
    this.codeErreur,
  });

  /// Intention déclarée aujourd'hui.
  final bool enLigne;

  /// Ce que Yao a déclaré, ou `null` si rien n'a été déclaré **aujourd'hui** :
  /// le plafond n'est jamais reporté (FR-011), et l'app le redemande.
  final int? plafondDeclareUnites;

  /// Ce qui s'applique réellement : `min(déclaré, palier)`.
  final int plafondRetenuUnites;

  /// Lequel des deux s'applique.
  final SourcePlafond source;

  /// Clé i18n du palier appliqué.
  final String palierCle;

  /// Devise ISO 4217 de la zone.
  final String devise;

  /// Vrai seulement après une position publiée — l'intention ne suffit pas.
  final bool dansLePool;

  /// Période attendue entre deux publications de position (secondes).
  final int periodePositionS;

  /// Capacités déclarées (slugs de transport).
  final List<String> capacites;

  /// Un appel est en cours.
  final bool chargement;

  /// Le réseau a lâché : c'est le **bandeau de reconnexion** qui le dit, et
  /// c'est honnête — au-delà du TTL, Yao sera effectivement sorti du pool.
  final bool horsLigne;

  /// Code du dernier refus métier (`dispatch.erreur.*`), ou `null`.
  final String? codeErreur;

  /// Vrai seulement si une offre peut RÉELLEMENT parvenir : en ligne **et**
  /// présent au pool. L'intention ne suffit pas — c'est la position publiée
  /// qui fait entrer dans le vivier (contrat §1.1).
  bool get attendDesCourses => enLigne && dansLePool;

  /// Vrai si Yao doit (re)déclarer son plafond : nouveau jour, ou première mise
  /// en ligne.
  bool get plafondADeclarer => plafondDeclareUnites == null;

  /// Copie modifiée. `codeErreur` est remis à `null` par défaut : une erreur
  /// affichée doit disparaître au geste suivant, jamais coller à l'écran.
  EtatDisponibilite copieAvec({
    bool? enLigne,
    int? plafondDeclareUnites,
    int? plafondRetenuUnites,
    SourcePlafond? source,
    String? palierCle,
    String? devise,
    bool? dansLePool,
    int? periodePositionS,
    List<String>? capacites,
    bool? chargement,
    bool? horsLigne,
    String? codeErreur,
    bool effacerPlafondDeclare = false,
  }) =>
      EtatDisponibilite(
        enLigne: enLigne ?? this.enLigne,
        plafondDeclareUnites: effacerPlafondDeclare
            ? null
            : (plafondDeclareUnites ?? this.plafondDeclareUnites),
        plafondRetenuUnites: plafondRetenuUnites ?? this.plafondRetenuUnites,
        source: source ?? this.source,
        palierCle: palierCle ?? this.palierCle,
        devise: devise ?? this.devise,
        dansLePool: dansLePool ?? this.dansLePool,
        periodePositionS: periodePositionS ?? this.periodePositionS,
        capacites: capacites ?? this.capacites,
        chargement: chargement ?? this.chargement,
        horsLigne: horsLigne ?? this.horsLigne,
        codeErreur: codeErreur,
      );

  /// Construit l'état depuis le **corps JSON du contrat** — jamais depuis un
  /// DTO : c'est ce chemin que couvrent les tests widget (leçon du cycle 008).
  factory EtatDisponibilite.depuisJson(Map<String, Object?> json) {
    final capacites = (json['capacites'] as List<Object?>? ?? const <Object?>[])
        .whereType<Map<Object?, Object?>>()
        .map((c) => c['valeur']?.toString() ?? '')
        .where((v) => v.isNotEmpty)
        .toList();
    return EtatDisponibilite(
      enLigne: json['en_ligne'] == true,
      plafondDeclareUnites: (json['plafond_declare_unites'] as num?)?.toInt(),
      plafondRetenuUnites: (json['plafond_retenu_unites'] as num?)?.toInt() ?? 0,
      source: SourcePlafond.depuis(json['plafond_source'] as String?),
      palierCle: json['palier_note_cle'] as String? ?? 'dispatch.palier.entree',
      devise: json['devise'] as String? ?? 'XOF',
      dansLePool: json['dans_le_pool'] == true,
      periodePositionS: (json['periode_position_s'] as num?)?.toInt() ?? 30,
      capacites: capacites,
    );
  }
}

/// Porteur de la disponibilité — **vit tant que l'app vit**.
@Riverpod(keepAlive: true)
class Disponibilite extends _$Disponibilite {
  @override
  EtatDisponibilite build() {
    // Session fermée ⇒ provider invalidé ⇒ état vide (patron `etat_roles`).
    ref.watch(sessionProvider.select((e) => e.connecte));
    return const EtatDisponibilite();
  }

  /// Charge l'état courant depuis le serveur.
  ///
  /// Un échec réseau ne remet pas l'état à zéro : il pose `horsLigne` et garde
  /// ce qu'on savait. Effacer l'écran ferait croire à Yao qu'il n'est plus en
  /// ligne alors que le serveur, lui, l'a toujours dans le pool.
  Future<void> charger() async {
    state = state.copieAvec(chargement: true);
    try {
      final json = await ref.read(dispatchApiProvider).lireDisponibilite();
      state = EtatDisponibilite.depuisJson(json);
    } on Object catch (e) {
      state = state.copieAvec(
        chargement: false,
        horsLigne: true,
        codeErreur: codeErreurApi(e),
      );
    }
  }

  /// Bascule en ligne avec le plafond déclaré du jour.
  Future<void> passerEnLigne(int plafondUnites) async =>
      _basculer(enLigne: true, plafondUnites: plafondUnites);

  /// Bascule hors ligne — sortie **immédiate** du pool (FR-005).
  Future<void> passerHorsLigne() async => _basculer(enLigne: false);

  Future<void> _basculer({required bool enLigne, int? plafondUnites}) async {
    state = state.copieAvec(chargement: true);
    try {
      final json = await ref.read(dispatchApiProvider).basculerDisponibilite(
            enLigne: enLigne,
            plafondDeclareUnites: plafondUnites,
          );
      state = EtatDisponibilite.depuisJson(json);
    } on Object catch (e) {
      // Un refus métier (dossier invalide, course active) n'est PAS une panne :
      // il porte son code, et l'écran en fait une phrase. L'état ne bascule pas.
      state = state.copieAvec(
        chargement: false,
        horsLigne: codeErreurApi(e) == null,
        codeErreur: codeErreurApi(e),
      );
    }
  }

  /// Publie une position. Rend `true` si le coursier est (resté) dans le pool.
  ///
  /// Un `204` (coursier hors ligne) n'est pas une erreur : la position est
  /// **ignorée**, et l'app peut être en retard d'un tic après un « hors ligne ».
  Future<bool> publierPosition({
    required String uuidClient,
    required double lat,
    required double lon,
    int? precisionM,
  }) async {
    try {
      final json = await ref.read(dispatchApiProvider).publierPosition(
            uuidClient: uuidClient,
            horodatageLocal: DateTime.now().toUtc(),
            lat: lat,
            lon: lon,
            precisionM: precisionM,
          );
      final dansLePool = json?['dans_le_pool'] == true;
      state = state.copieAvec(
        dansLePool: dansLePool,
        horsLigne: false,
        periodePositionS:
            (json?['prochaine_publication_s'] as num?)?.toInt() ?? state.periodePositionS,
      );
      return dansLePool;
    } on Object catch (e) {
      // Réseau coupé : le bandeau de reconnexion s'affiche, et c'est HONNÊTE —
      // passé le TTL, Yao sera effectivement sorti du pool sans que l'app ait
      // à le deviner.
      state = state.copieAvec(horsLigne: true, codeErreur: codeErreurApi(e));
      return false;
    }
  }
}
