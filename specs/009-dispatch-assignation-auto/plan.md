# Implementation Plan: Dispatch automatique — assignation des courses sans intervention humaine

**Branch**: `009-dispatch-assignation-auto` | **Date**: 2026-07-26 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/009-dispatch-assignation-auto/spec.md`

## Summary

Le cycle livre le **pipeline complet de dispatch** — pool temps réel, éligibilité
par capacités, classement pondéré, offre en cascade sous double verrou, broadcast,
escalade, réassignation — plus les **deux surfaces coursier** sans lesquelles il
n'existe pas du point de vue de Yao : la disponibilité (K1, tranche DSP) et
l'écran d'offre (K2).

L'approche technique tient en cinq décisions, toutes prises contre le code déjà
livré et détaillées en [research.md](./research.md) :

1. **Déclenchement** par le premier **consommateur outbox** réel du produit
   (`commande.prete_a_dispatcher`) plus un **tic** de 5 s qui ne résout que des
   **échéances persistées** — un redémarrage ne perd aucun compte à rebours (R1).
2. **Pool** en trois clés Redis, la durée de vie portée par le hash d'état, la clé
   de position du cycle 008 **inchangée** pour ne pas casser le suivi client (R2).
3. **Double verrou atomique** par script Lua — commande *et* coursier, les deux ou
   aucun (R3) ; mais la garantie anti-double-acceptation, elle, est **déjà en
   Postgres** : `SELECT … FOR UPDATE` + table de transitions fermée. Elle tient
   **sans Redis** (R4), et c'est ce qui rend SC-001 démontrable.
4. **Proximité** par **une seule** matrice routière par évaluation, pré-filtrée par
   l'index GEO — jamais un appel par candidat, jamais de blocage (R5).
5. **Aucune dépendance nouvelle**, ni Rust ni Flutter : `redis`/`deadpool-redis`
   sont au workspace, `geolocator` est déjà dans `mefali_pro`, et la sonnerie
   appartient à NTF-01.

### Livrables attendus — où les trouver

| Livrable demandé | Artefact |
|---|---|
| Migrations à créer | [data-model.md §1](./data-model.md) — `0010_dispatch_enums.sql`, `0011_dispatch_tables.sql`, `0012_commandes_capacites.sql` (un fichier par schéma touché) |
| Endpoints (annotations utoipa) | [contracts/dispatch-openapi.md](./contracts/dispatch-openapi.md) — 6 coursier + 3 admin |
| Structures et traits exposés aux autres crates | [contracts/ports-dispatch.md](./contracts/ports-dispatch.md) — 2 offerts, 7 consommés (dont le **contrat d'émission** de notifications), surface publique |
| Événements outbox et métriques | [data-model.md §7](./data-model.md) — 12 nouveaux, 1 amendé, produit vs opérations |
| Écrans et widgets concernés | [research.md R15](./research.md) + [quickstart.md](./quickstart.md) — K1 (tranche DSP), K2 |
| Tests d'intégration | [quickstart.md](./quickstart.md) — 10 fichiers, tracés vers SC-001..015 |
| Paramètres de zone | [data-model.md §4](./data-model.md) — 18 créés, 3 réutilisés |

## Technical Context

**Language/Version**: Rust stable (edition et `rust-version` du workspace) ;
Dart/Flutter 3.44.6 pour `mefali_pro` et `mefali_core`.

**Primary Dependencies**: Actix Web, sqlx (macros vérifiées à la compilation),
utoipa + `utoipa-actix-web`, `redis` 1.3.0 + `deadpool-redis` 0.23.0, chrono, uuid,
async-trait, thiserror, tracing. Côté apps : `flutter_riverpod` ^3.3.2 +
`riverpod_annotation` ^4.0.3 + `build_runner`, `geolocator` ^14.0.2,
`mefali_core`, `mefali_api_client` (généré). **Aucune dépendance nouvelle** —
tout est déjà déclaré et figé par lockfile (principe X).

**Storage**: PostgreSQL — schéma `dispatch` neuf (4 tables, migrations `0010`/`0011`)
+ 1 table dans le schéma `commandes` (capacités requises, migration `0012`, R9).
Redis — 5 clés éphémères
reconstructibles (data-model §2). **Aucun objet S3** : le dispatch ne stocke ni
photo ni note vocale, donc ni Garage ni rétention de média n'entrent au périmètre.

**Testing**: `cargo test -p dispatch` (domaine pur) ; `#[sqlx::test]` et tests
d'intégration `backend/api/tests/` sur l'app Actix **réelle** via
`bac_dispatch/mod.rs` ; deux familles de tests contre le **vrai** Redis (pool,
verrous Lua), sautées avec message si Redis est injoignable ; `flutter test` +
`dart analyze` (jamais `flutter analyze`).

**Target Platform**: serveur Linux (VPS, image autonome — migrations embarquées
appliquées au démarrage) ; Android pour `mefali_pro`. iOS non vérifié
(Xcode/CocoaPods à installer — écart consigné au cycle plateformes natives).

**Project Type**: monorepo — service web Actix + apps mobiles Flutter. Le web Nuxt
**n'est pas touché** : l'écran d'opérations est en tranche T3 (FR-096).

**Performance Goals**: assignation en moins de 2 min pour 95 % des commandes avec
au moins un éligible en ligne (SC-002) ; latence de déclenchement ≈ 1 s
(intervalle du worker outbox) ; tic de 5 s pour tout ce qui est temporel ; **une**
matrice routière par évaluation, quel que soit le nombre de candidats.

**Constraints**: la double acceptation doit être impossible **même Redis absent** ;
une perte totale du pool ne perd aucune donnée métier et ne demande aucune
intervention ; 18 paramètres de zone et **zéro** valeur en dur ; aucune coordonnée
du client transmise au coursier **avant** acceptation ; verrou strictement plus
long que le compte à rebours, vérifié au chargement.

**Scale/Scope**: Tiassalé — une zone ville, ~4 coursiers, 8 types de transport dont
3 actifs. Périmètre du cycle : 1 crate à remplir, 2 modules HTTP neufs,
9 endpoints, 5 tables (4 + 1), 2 transitions d'état, 12 événements, 2 écrans
Flutter, 10 fichiers de tests d'intégration.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Portes dérivées de `.specify/memory/constitution.md` (**v1.1.0** — le principe XII
s'ajoute aux onze du gabarit, ce cycle construisant de l'état Flutter) :

- [x] **I. Sources de vérité** : aucun client `clients/dart`/`clients/ts` édité à
  la main (régénérés par `scripts/generate-clients.sh`, diff vide exigé) ; trois
  **nouvelles** migrations — `0010`/`0011` pour le schéma `dispatch`, `0012` pour
  `commandes`, un fichier par schéma touché pour que l'historique reste lisible
  sous son nom — et `0001→0009` **intouchées** ; les 18
  paramètres du pipeline vivent en configuration de zone, et les 3 paramètres
  existants (`suivi.position_periode_s`, `commande.escalade_attente_coursier_s`,
  `transport.actifs`) sont **réutilisés, jamais dupliqués** (R14).
- [x] **II. Architecture** : le travail remplit le crate `dispatch` **existant et
  vide** ; aucun champ logistique n'entre sur le tronc — la capacité requise va
  sur la **livraison** (R9) ; aucun crate ne suppose « commande = livraison » ni
  « prestataire = vendeur » ; le filtre est **par capacités**, générique
  `(famille, valeur)` ; Redis ne porte que de l'éphémère reconstructible, Postgres
  reste la seule vérité durable (R2, R4). La nouvelle table vit dans le schéma
  `commandes` et est **écrite par le crate `commandes`** : l'appartenance des
  schémas est respectée, `dispatch` la lit par un port.
- [x] **III. Argent** : montants en entiers d'unités mineures + devise résolue par
  zone ; aucun flottant, y compris dans le **scoring** (entiers de bout en bout,
  R6) ; le devis figé n'est **jamais** recalculé par une réassignation (FR-077) ;
  la bascule prépaiement porte **un seul** montant et **un seul** état — aucun
  chemin partiel (FR-086).
- [x] **IV. Distances** : itinéraire routier OSRM via
  `tarification::routage::matrice_ou_degrade` (cache par tronçon compris), repli
  vol d'oiseau ×1,4 `degraded=true` **journalisé**, et jamais bloquant (R5,
  FR-030). Le pré-filtre GEO en vol d'oiseau **ne décide rien** : il **minore** la
  route, donc il ne peut pas écarter un coursier réellement dans le rayon ; le
  test de rayon, lui, se fait sur la distance routière.
- [x] **V. Offline & idempotence** — **avec une dérogation déclarée** (voir
  Complexity Tracking) : publication de position et acceptation/refus portent
  `uuid_client` + `horodatage_local`, leur rejeu est **idempotent** et le serveur
  fait foi (il écrit **son** horodatage). En revanche, **ni l'une ni l'autre ne
  passe par la file locale hors réseau**, que le principe exige pour « toute
  action de l'app coursier ». Ce n'est pas un oubli — c'est un écart argumenté et
  tracé, pas une conformité pleine.
- [x] **VI. Événements** : chaque transition écrit son événement dans la **même
  transaction** ; les 12 nouveaux types et l'amendement de
  `commande.attente_coursier_escaladee` sont **déclarés dans
  `docs/taxonomie-evenements.md` avant implémentation** (data-model §7), avec leur
  qualification produit/opérations pour MET-01.
- [x] **VII. Qualité** : les **2** nouvelles transitions de la table fermée ont
  chacune leur test d'intégration, refus symétriques compris ; les **8** motifs
  d'écart d'éligibilité ont chacun le leur (SC-013) ; `cargo sqlx prepare` après
  les migrations ; aucune chaîne utilisateur en dur — clés i18n fr côté API
  (`message_cle`) comme côté app (`app_fr.arb`) ; logs structurés avec identifiant
  de corrélation pour le classement détaillé.
- [x] **VIII. Sécurité** : les 9 endpoints sont gardés par **rôle** et par
  **propriété** (une offre qui n'est pas la sienne n'existe pas → `404`) ; aucune
  surface non authentifiée ajoutée ; aucun média, donc aucune rétention nouvelle.
  Minimisation ARTCI renforcée : **aucune** coordonnée client transmise au coursier
  avant acceptation, **aucune** coordonnée ni numéro dans les événements (SC-011).
  L'accès admin au pool (matière de la carte d'ADM-02) est un besoin
  d'exploitation légitime, gardé par le rôle `Admin`.
- [x] **IX. Périmètre** : DSP-01→07 sont **toutes P0** et augmentent directement la
  fiabilité des livraisons ; DSP-08 (anti-abus, P1) et la superposition de deux
  commandes (phase 2) sont **hors périmètre** ; aucune provision n'est activée —
  en particulier `TypeZone::Quartier` reste **données seulement**, ce qui produit
  un **écart assumé** avec la maquette K2 (« quartier Sokoura ») documenté dans le
  contrat plutôt que contourné.
- [x] **X. Versions** : **aucune dépendance nouvelle** — donc rien à choisir, rien
  à figer, rien à réviser. `redis`/`deadpool-redis` sont déjà au workspace,
  `geolocator` déjà dans `mefali_pro` ; la sonnerie, qui aurait exigé un greffon
  audio, appartient à NTF-01.
- [x] **XI. Design** : K1 et K2 (`docs/design/png/`) sont la cible,
  `docs/design/tokens.md` les valeurs exactes ; widgets Material 3 thémés via
  `mefali_core` (`BandeauHorsLigne`, `formaterMontant`, jetons) ; **aucune**
  transposition de structure DOM/CSS depuis `docs/design/html/` ; pas de variante
  Cupertino, conventions par constructeurs `.adaptive`.
- [x] **XII. État Flutter — Riverpod codegen** : deux porteurs, deux moules
  **opposés et nommés** — `Notifier<EtatDisponibilite>` en
  `@Riverpod(keepAlive: true)` (porteur de **processus** : la mise en ligne
  traverse les écrans) et `AsyncNotifier` en `@riverpod` nu (chargement **jetable**
  de l'offre courante) ; `.g.dart` commités, jamais édités ; injection par la
  **portée** ; `retry: pasDeRetry` ; le **compte à rebours reste un état local du
  widget**, que XII nomme explicitement parmi ce qui ne se providerifie pas ;
  analyse par `dart analyze` (R15).

**Verdict : onze portes conformes, une dérogation déclarée** (principe V — la file
locale hors réseau), justifiée dans Complexity Tracking. Trois autres choix
ajoutent de la surface et sont argumentés plutôt que subis — deux déclencheurs au
lieu d'un (R1), trois clés Redis au lieu d'une (R2), deux verrous au lieu d'un
(R3, imposé par la clarification FR-056) ; ceux-là ne contredisent aucun principe
et n'ont donc pas à y figurer.

## Project Structure

### Documentation (this feature)

```text
specs/009-dispatch-assignation-auto/
├── plan.md                       # Ce fichier
├── research.md                   # Phase 0 — R1..R19
├── data-model.md                 # Phase 1 — migrations, clés Redis, états, paramètres, événements
├── quickstart.md                 # Phase 1 — validation SC-001..015
├── contracts/
│   ├── dispatch-openapi.md       # 6 endpoints coursier + 3 admin
│   └── ports-dispatch.md         # traits offerts/consommés, câblage outbox + tic
├── checklists/requirements.md    # 16/16
└── tasks.md                      # Phase 2 — /speckit-tasks, PAS créé ici
```

### Source Code (repository root)

```text
backend/
├── crates/dispatch/              # NEUF (crate vide depuis le cycle 001)
│   └── src/{lib,modele,ports,eligibilite,scoring,pipeline,offre,reprise,tic,depot}.rs
├── crates/commandes/             # ÉTENDU — jamais réécrit
│   └── src/{ports,etats,creation,depot}.rs   # +6 méthodes, +2 transitions, capacités requises
├── crates/comptes/               # + impl du port EtatCoursier (comptes possède vehicule_declare)
├── api/src/
│   ├── dispatch_http.rs          # NEUF — surface coursier (disponibilité, position, offres)
│   ├── admin_dispatch_http.rs    # NEUF — alertes, pool, reprise manuelle
│   ├── infra_redis.rs            # + RedisPool (3 clés) et RedisVerrouOffre (scripts Lua)
│   ├── erreurs_dispatch.rs       # NEUF — mapping { code, message_cle }
│   └── lib.rs                    # + DispatchOutbox (1er consommateur réel) + job_tic_dispatch
├── api/tests/
│   ├── bac_dispatch/mod.rs       # NEUF — app Actix réelle, zone Tiassalé, coursiers moto
│   └── dispatch_{pool,eligibilite,scoring,offre,concurrence,broadcast,
│                 escalade,reassignation,resilience,transverses}.rs
├── migrations/
│   ├── 0010_dispatch_enums.sql        # types seuls (leçon du cycle 008)
│   ├── 0011_dispatch_tables.sql       # 4 tables — schéma `dispatch` SEUL
│   └── 0012_commandes_capacites.sql   # capacite_requise + index d'inactivité + rétro-remplissage
└── seeds/70_dispatch_parametres.sql

apps/
├── mefali_pro/lib/coursier/
│   ├── disponibilite/            # NEUF — K1 tranche DSP : bascule, plafond, émetteur de position
│   └── offre/                    # NEUF — K2 : compte à rebours, arrêts, gain, avance, décision
├── mefali_pro/lib/l10n/app_fr.arb
└── packages/mefali_core/lib/src/coursier/
    └── api_dispatch.dart         # NEUF — couche d'appel (rend le corps JSON du contrat, pas les DTO)

clients/{dart,ts}                 # RÉGÉNÉRÉS depuis openapi.json — jamais édités
docs/taxonomie-evenements.md      # 12 événements déclarés + 1 amendé, AVANT implémentation
```

**Structure Decision.** Cinq zones du monorepo, et une seule est neuve.

- `backend/crates/dispatch/` est **le** lieu du cycle : le crate existe depuis le
  socle avec un `lib.rs` qui annonce « les entités et parcours de ce domaine
  arrivent dans son cycle dédié ». C'est ce cycle.
- `backend/crates/commandes/` est **étendu, pas réécrit** : le contrat
  `CommandesADispatcher` a été créé au cycle 008 pour être branché ici (« Contrat
  offert à DSP »), et six méthodes s'y ajoutent plutôt que dans un second trait
  qui découperait le même contrat. Deux lignes entrent dans la table de
  transitions fermée. `commandes` **ne dépendra jamais** de `dispatch` — l'inverse
  serait un cycle Cargo (R19).
- `backend/api/` reçoit les implémentations Redis (patron `RedisEphemere`,
  `RedisPositions`), les deux modules HTTP et le câblage des deux déclencheurs.
- `apps/mefali_pro/` reçoit les deux tranches d'écran ; `mefali_core` reçoit la
  couche d'appel, comme il a reçu `CommandesApi` au cycle 008.
- **Non touchés** : `web/` (écran d'opérations en tranche T3),
  `apps/mefali_client/` (l'app cliente n'est pas modifiée), `infra/` (aucun
  service nouveau).

## Complexity Tracking

Une seule entrée : la dérogation au principe **V**. Elle est ici parce que le
gabarit du Constitution Check dit « cocher **ou justifier** » — et qu'une
dérogation non écrite est une dérogation qui se perd.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| **Principe V** — l'**acceptation/refus d'offre** ne part pas dans la file locale hors réseau, alors que V l'exige pour « toute action de l'app coursier (scans, photos, transitions, confirmations) » | Une offre vit **40 s** (`dispatch.timer_offre_s`). Une acceptation enfilée hors réseau et drainée deux minutes plus tard porterait sur une course **déjà attribuée à un autre coursier** : le rejeu produirait systématiquement « déjà prise », c'est-à-dire une déception garantie plutôt qu'une résilience. Et CRS-08 — la story qui **possède** la file — en énumère limitativement le contenu : « scans, photos, transitions, confirmations et appels ». L'acceptation n'y figure pas. Les trois autres garanties de V sont tenues : `uuid_client`, horodatage local observé, rejeu **idempotent**, serveur faisant foi. | *Enfiler quand même* : le drain produirait des acceptations mortes et un compteur de non-réponses faussé (une offre non répondue **puis** acceptée hors ligne compterait deux fois). *Allonger le timer pour couvrir une coupure* : ferait attendre la cliente 5 min derrière un coursier injoignable, ce que DSP-06 est précisément censé éviter. |
| **Principe V** — la **publication de position** ne part pas dans la file locale | Une position est vraie **à l'instant où elle est relevée**. Rejouer au retour du réseau une position vieille de dix minutes réinscrirait le coursier au pool avec une localisation fausse, et le dispatch lui offrirait une course à 4 km de là où il est. Le TTL du pool (`dispatch.pool_ttl_s`) est précisément conçu pour que le silence **soit** l'information. | *Enfiler les positions* : réintroduirait dans le pool des coursiers absents — l'inverse exact de DSP-01, dont le critère est « un coursier muet sort du pool ». *Enfiler avec filtre d'âge au drain* : même résultat que ne pas enfiler, pour le coût d'une file. |

**Portée de la dérogation.** Elle ne couvre **que** ces deux actions. Toutes les
autres actions coursier de ce cycle — il n'y en a pas d'autre, les transitions de
collecte et les confirmations restant au cycle 008 et à CRS — continuent de passer
par la file. Si le produit veut lever la dérogation, cela passe par un
`/speckit-constitution` amendant V, pas par une réinterprétation locale.
