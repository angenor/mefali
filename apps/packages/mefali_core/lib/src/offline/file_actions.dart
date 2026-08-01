/// File d'actions coursier hors-ligne — API de haut niveau (constitution V, R5).
///
/// `FileActions` enveloppe la base drift : enfiler une action idempotente
/// (`uuidClient`), lire/écrire le cache de course pré-provisionné, cocher un
/// arrêt de façon optimiste, et parcourir la file pour le rejeu. Le rejeu HTTP
/// lui-même vit dans le provider de course (il connaît le client généré) — ici,
/// seulement le stockage durable.
library;

import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'action_en_attente.dart';

part 'file_actions.g.dart';

/// Base drift de la file offline — durée de vie du processus (`keepAlive`).
/// Surchargée en test par une base mémoire.
@Riverpod(keepAlive: true)
BaseOffline baseOffline(Ref ref) {
  final base = BaseOffline.ouvrir();
  ref.onDispose(base.close);
  return base;
}

/// File d'actions coursier idempotente + cache de course pré-provisionné.
@Riverpod(keepAlive: true)
FileActions fileActions(Ref ref) => FileActions(ref.watch(baseOfflineProvider));

/// API de stockage de la file offline (drift). Aucune I/O réseau ici (R5).
class FileActions {
  /// Construit sur une base drift ouverte.
  FileActions(this._base);

  final BaseOffline _base;

  /// Enfile une action POST idempotente. Un `uuidClient` déjà présent est
  /// laissé tel quel (rejeu d'une même action = aucun doublon, V).
  Future<void> enfiler({
    required String uuidClient,
    required String endpoint,
    required String payloadJson,
    List<int>? photoOctets,
    required DateTime creeLeLocal,
    bool multipart = true,
  }) async {
    await _base.into(_base.actionsEnAttente).insert(
          ActionsEnAttenteCompanion.insert(
            uuidClient: uuidClient,
            endpoint: endpoint,
            payloadJson: payloadJson,
            photoOctets: Value(photoOctets == null ? null : Uint8List.fromList(photoOctets)),
            creeLeLocal: creeLeLocal,
            multipart: Value(multipart),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  /// Actions en attente de rejeu, dans leur ordre de création **strict**
  /// (FR-087).
  ///
  /// L'horodatage local seul ne suffit pas : deux actions créées dans la même
  /// milliseconde — deux taps rapides, un scan suivi d'une transition — se
  /// départageraient au hasard, et rejouer « arrivé » avant « en route » se
  /// ferait refuser par la machine à états du serveur. L'`uuid_client` est un
  /// UUIDv7, donc **chronologique** : il tranche les égalités sans rien
  /// stocker de plus.
  ///
  /// Les actions REFUSÉES définitivement n'y figurent plus : les rejouer ne
  /// changerait rien et masquerait les autres (FR-085).
  Future<List<ActionEnAttente>> enAttente() {
    return (_base.select(_base.actionsEnAttente)
          ..where((a) => a.statut.equals('en_attente'))
          ..orderBy([
            (a) => OrderingTerm(expression: a.creeLeLocal),
            (a) => OrderingTerm(expression: a.uuidClient),
          ]))
        .get();
  }

  /// Refus DÉFINITIF du serveur : l'action quitte la file et rejoint la trace.
  ///
  /// Elle n'est pas supprimée (FR-086) : derrière une collecte refusée, il y a
  /// une avance que Yao a réellement engagée. Effacer la ligne effacerait la
  /// seule preuve qu'il en parle à l'exploitation.
  Future<void> marquerRefusDefinitif(String uuidClient, String motifCle) async {
    await (_base.update(_base.actionsEnAttente)
          ..where((a) => a.uuidClient.equals(uuidClient)))
        .write(ActionsEnAttenteCompanion(
      statut: const Value('refuse'),
      dernierMotif: Value(motifCle),
      refuseLeLocal: Value(DateTime.now()),
    ));
  }

  /// Refus définitifs consultables, le plus récent d'abord (FR-086).
  Future<List<ActionEnAttente>> refusDefinitifs() {
    return (_base.select(_base.actionsEnAttente)
          ..where((a) => a.statut.equals('refuse'))
          ..orderBy([
            (a) => OrderingTerm(
                expression: a.refuseLeLocal, mode: OrderingMode.desc),
          ]))
        .get();
  }

  /// Vide la trace des refus — Yao l'a lue, elle a fait son travail.
  Future<void> effacerRefus() async {
    await (_base.delete(_base.actionsEnAttente)
          ..where((a) => a.statut.equals('refuse')))
        .go();
  }

  /// Octets de photo restant à transmettre (FR-083) — l'attente de Yao ne se
  /// mesure pas en nombre d'actions quand l'une d'elles pèse 2 Mo.
  Future<int> octetsEnAttente() async {
    final actions = await enAttente();
    return actions.fold<int>(0, (n, a) => n + (a.photoOctets?.length ?? 0));
  }

  /// Retire une action de la file (rejeu abouti ou refus définitif réconcilié).
  Future<void> retirer(String uuidClient) async {
    await (_base.delete(_base.actionsEnAttente)
          ..where((a) => a.uuidClient.equals(uuidClient)))
        .go();
  }

  /// Marque un échec de rejeu RETRYABLE (réseau) : incrémente le compteur et
  /// mémorise le motif, sans retirer l'action.
  Future<void> marquerEchec(String uuidClient, String motif) async {
    final ligne = await (_base.select(_base.actionsEnAttente)
          ..where((a) => a.uuidClient.equals(uuidClient)))
        .getSingleOrNull();
    if (ligne == null) return;
    await (_base.update(_base.actionsEnAttente)
          ..where((a) => a.uuidClient.equals(uuidClient)))
        .write(ActionsEnAttenteCompanion(
      tentatives: Value(ligne.tentatives + 1),
      dernierMotif: Value(motif),
    ));
  }

  /// Remplace le cache de course par les arrêts pré-provisionnés fournis.
  Future<void> remplacerCache(List<ArretsPreprovisionnesCompanion> arrets) async {
    await _base.transaction(() async {
      await _base.delete(_base.arretsPreprovisionnes).go();
      await _base.batch((b) => b.insertAll(_base.arretsPreprovisionnes, arrets));
    });
  }

  /// Arrêts pré-provisionnés en cache (course active hors-ligne).
  Future<List<ArretPreprovisionne>> arretsCache() {
    return _base.select(_base.arretsPreprovisionnes).get();
  }

  /// Coche optimiste locale d'un arrêt (avant réconciliation serveur).
  Future<void> cocherOptimiste(String arretId) async {
    await (_base.update(_base.arretsPreprovisionnes)
          ..where((a) => a.arretId.equals(arretId)))
        .write(const ArretsPreprovisionnesCompanion(
      statutLocal: Value('collecte'),
    ));
  }

  /// Annule la coche optimiste d'un arrêt (refus métier réconcilié au rejeu :
  /// le serveur a refusé, l'arrêt RESTE à collecter — SC-008).
  Future<void> decocherOptimiste(String arretId) async {
    await (_base.update(_base.arretsPreprovisionnes)
          ..where((a) => a.arretId.equals(arretId)))
        .write(const ArretsPreprovisionnesCompanion(
      statutLocal: Value('a_collecter'),
    ));
  }

  // ── Course complète (cycle CRS 010) ──────────────────────────────────────

  /// Remplace le cache de course. Une seule course active à la fois : la
  /// précédente est effacée, **numéro de téléphone compris** (R6).
  ///
  /// Une remise déjà validée SANS RÉSEAU survit au remplacement, comme les
  /// coches de la checklist : le serveur, qui n'a pas encore reçu l'action,
  /// continue de servir une course « à remettre », et la laisser écraser le
  /// drapeau local rouvrirait l'écran de remise sur une commande que Yao a déjà
  /// donnée. Le drapeau ne disparaît qu'à la clôture ([effacerCourse]).
  Future<void> remplacerCourse(CourseCacheTableCompanion course) async {
    await _base.transaction(() async {
      final precedente = await _base
          .select(_base.courseCacheTable)
          .getSingleOrNull();
      final memeCourse = precedente != null &&
          course.livraisonId.present &&
          precedente.livraisonId == course.livraisonId.value;
      await _base.delete(_base.courseCacheTable).go();
      await _base.into(_base.courseCacheTable).insert(
            memeCourse && precedente.remiseValideeLocalementLe != null
                ? course.copyWith(
                    remiseValideeLocalementLe:
                        Value(precedente.remiseValideeLocalementLe),
                  )
                : course,
          );
    });
  }

  /// La course en cache, ou `null` si aucune n'est active.
  Future<CourseCache?> courseCache() {
    return _base.select(_base.courseCacheTable).getSingleOrNull();
  }

  /// Avance LOCALEMENT le statut de l'arrêt de remise (`en_route` | `arrive`).
  ///
  /// Symétrique de [cocherOptimiste] pour les collectes. Sans elle, « je suis
  /// arrivé chez le client » n'avait aucun effet visible hors ligne : l'action
  /// partait bien dans la file, mais l'écran attendait un statut serveur qui ne
  /// pouvait pas venir — la course ne pouvait donc pas se terminer sans réseau,
  /// ce qui est précisément la promesse du cycle (T087, SC-003/SC-017).
  ///
  /// L'heure d'arrivée, elle, n'est PAS inventée : elle fonde une prime
  /// d'attente et reste horodatée par le serveur (cycle 005).
  Future<void> avancerRemiseLocalement(String livraisonId, String statut) async {
    await (_base.update(_base.courseCacheTable)
          ..where((c) => c.livraisonId.equals(livraisonId)))
        .write(CourseCacheTableCompanion(arretRemiseStatut: Value(statut)));
  }

  /// Marque la remise validée hors ligne, en attente de synchronisation.
  Future<void> marquerRemiseValideeLocalement(
    String livraisonId,
    DateTime le,
  ) async {
    await (_base.update(_base.courseCacheTable)
          ..where((c) => c.livraisonId.equals(livraisonId)))
        .write(CourseCacheTableCompanion(remiseValideeLocalementLe: Value(le)));
  }

  /// Remplace la checklist en **préservant les coches déjà posées**.
  ///
  /// C'est le point délicat : un rechargement de la course ne doit pas effacer
  /// ce que Yao a coché dans l'allée du marché. Le statut serveur, lui, écrase —
  /// c'est le serveur qui sait si une ligne a été retirée.
  Future<void> remplacerChecklist(List<LignesChecklistCompanion> lignes) async {
    await _base.transaction(() async {
      final cochees = <String>{
        for (final l in await _base.select(_base.lignesChecklist).get())
          if (l.cochee) l.ligneId,
      };
      await _base.delete(_base.lignesChecklist).go();
      await _base.batch((b) => b.insertAll(
            _base.lignesChecklist,
            [
              for (final l in lignes)
                if (cochees.contains(l.ligneId.value))
                  l.copyWith(cochee: const Value(true))
                else
                  l,
            ],
          ));
    });
  }

  /// Toutes les lignes de checklist, dans l'ordre d'affichage.
  Future<List<LigneChecklist>> lignesChecklist() {
    return (_base.select(_base.lignesChecklist)
          ..orderBy([(l) => OrderingTerm(expression: l.ordre)]))
        .get();
  }

  /// Coche (ou décoche) un article. **Jamais envoyé au serveur** (R11, FR-079).
  Future<void> cocherLigne(String ligneId, {required bool cochee}) async {
    await (_base.update(_base.lignesChecklist)
          ..where((l) => l.ligneId.equals(ligneId)))
        .write(LignesChecklistCompanion(cochee: Value(cochee)));
  }

  // ── Essais du code de remise consommés hors ligne (R5) ───────────────────

  /// Essais faux comptés localement pour une livraison.
  Future<int> essaisHorsLigne(String livraisonId) async {
    final ligne = await (_base.select(_base.essaisRemise)
          ..where((e) => e.livraisonId.equals(livraisonId)))
        .getSingleOrNull();
    return ligne?.essaisHorsLigne ?? 0;
  }

  /// Compte un essai faux de plus. Le total voyage AVEC la demande de remise,
  /// jamais essai par essai : envoyer des codes faux au serveur les ferait
  /// voyager sans aucun bénéfice (R5).
  Future<int> ajouterEssaiHorsLigne(String livraisonId) async {
    final courant = await essaisHorsLigne(livraisonId);
    await _base.into(_base.essaisRemise).insertOnConflictUpdate(
          EssaisRemiseCompanion.insert(
            livraisonId: livraisonId,
            essaisHorsLigne: Value(courant + 1),
            dernierEssaiLocal: Value(DateTime.now()),
          ),
        );
    return courant + 1;
  }

  /// Remet le compteur à zéro après consolidation serveur.
  ///
  /// Appelé quand le serveur a **accusé réception** des essais hors ligne
  /// (il retient `max(serveur, local)`, R5) : les garder après cela les ferait
  /// compter deux fois à la remise suivante.
  Future<void> consoliderEssais(String livraisonId) async {
    await (_base.delete(_base.essaisRemise)
          ..where((e) => e.livraisonId.equals(livraisonId)))
        .go();
  }

  // ── Relevés de présence en attente (FR-061) ─────────────────────────────

  /// Enregistre un échantillon de présence — une **distance arrondie**, jamais
  /// une position (R8).
  Future<void> enfilerPresence({
    required String uuidClient,
    required String livraisonId,
    required int distanceM,
    required DateTime releveLeLocal,
  }) async {
    await _base.into(_base.relevesPresenceLocaux).insert(
          RelevesPresenceLocauxCompanion.insert(
            uuidClient: uuidClient,
            livraisonId: livraisonId,
            distanceM: distanceM,
            releveLeLocal: releveLeLocal,
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  /// Relevés non encore transmis, les plus anciens d'abord — ils partent en LOT.
  Future<List<RelevePresenceLocal>> presenceEnAttente(String livraisonId) {
    return (_base.select(_base.relevesPresenceLocaux)
          ..where((r) => r.livraisonId.equals(livraisonId) & r.envoye.equals(false))
          ..orderBy([(r) => OrderingTerm(expression: r.releveLeLocal)]))
        .get();
  }

  /// Marque un lot de relevés comme transmis.
  Future<void> marquerPresenceEnvoyee(List<String> uuidsClient) async {
    if (uuidsClient.isEmpty) return;
    await (_base.update(_base.relevesPresenceLocaux)
          ..where((r) => r.uuidClient.isIn(uuidsClient)))
        .write(const RelevesPresenceLocauxCompanion(envoye: Value(true)));
  }

  // ── Dernier état connu de la caisse (FR-076) ────────────────────────────

  /// Range la caisse lue en ligne, pour que K5 s'ouvre sans réseau.
  ///
  /// Une seule ligne : c'est un instantané, pas un journal. L'historique du
  /// livre vit côté serveur, où il est immuable — en garder une copie locale
  /// modifiable créerait un second livre, contre lequel personne n'arbitre.
  Future<void> remplacerCaisse(String vueJson, {DateTime? luLe}) async {
    await _base.transaction(() async {
      await _base.delete(_base.caisseCacheTable).go();
      await _base.into(_base.caisseCacheTable).insert(
            CaisseCacheTableCompanion.insert(
              vueJson: vueJson,
              luLeLocal: luLe ?? DateTime.now(),
            ),
          );
    });
  }

  /// La caisse en cache, ou `null` si elle n'a jamais été lue en ligne.
  Future<CaisseCache?> caisseCache() {
    return _base.select(_base.caisseCacheTable).getSingleOrNull();
  }

  /// Efface tout ce qui appartient à une course terminée — **numéros compris**
  /// (R6, FR-034). Les actions ENCORE EN ATTENTE ne sont pas touchées.
  Future<void> effacerCourse(String livraisonId) =>
      _base.effacerCourse(livraisonId);
}
