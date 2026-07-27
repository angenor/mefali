---

description: "Tâches — dispatch automatique (cycle DSP 009)"
---

# Tasks: Dispatch automatique — assignation des courses sans intervention humaine

**Input**: Design documents from `/specs/009-dispatch-assignation-auto/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/](./contracts/)

**Tests**: les tests d'intégration ne sont pas optionnels ici — la spec les exige nommément (SC-013 : « toutes les décisions du pipeline sont couvertes »), et la constitution VII impose un test d'intégration par **transition de machine à états**. Les tests unitaires du domaine accompagnent les modules purs (scoring, éligibilité, configuration).

**Organization**: une phase par user story, dans l'ordre de dépendance interne du cycle (US1 → US7). Les 7 stories produit sont **toutes P0** ; les priorités P1→P4 des phases sont l'ordre de **livraison**, pas une hiérarchie produit.

**Calibrage**: chaque tâche vise une **demi-journée à une journée**. Une tâche qui déborde se scinde plutôt que de s'étirer.

## Format: `[ID] [P?] [Story] Description`

- **[P]** : parallélisable (fichiers différents, aucune dépendance sur une tâche incomplète)
- **[Story]** : US1..US7 — uniquement dans les phases de story
- Chemins de fichiers exacts dans chaque description

## Path Conventions

- **Backend Rust** : `backend/crates/dispatch/`, `backend/crates/commandes/`, `backend/crates/comptes/`, binaire `backend/api/`, migrations `backend/migrations/`, seeds `backend/seeds/`
- **Apps Flutter** : `apps/mefali_pro/`, partagé `apps/packages/mefali_core/`
- **Clients générés** : `clients/dart/`, `clients/ts/` — **jamais** d'édition manuelle, régénération uniquement
- **Non touchés** : `web/`, `apps/mefali_client/`, `infra/`

## Règles opposables à chaque tâche

Trois règles issues de la demande de découpe, plus celles de la constitution. Une
tâche qui les enfreint est incomplète, même si son code marche :

1. **Toute tâche qui touche l'API se termine par** : annotations `#[utoipa::path]` à
   jour → `./scripts/generate-clients.sh` → `git diff --exit-code clients/` vide →
   `cargo build` vert. Les tâches concernées le rappellent en clair.
2. **Toute tâche qui touche le schéma commence par sa migration sqlx** — une
   **nouvelle** migration, jamais la modification d'une migration appliquée — et se
   termine par `cargo sqlx prepare`. Le nom du fichier dit **quel schéma** il
   touche : `0010`/`0011` pour `dispatch`, `0012` pour `commandes`. Tout le schéma
   du cycle est planifié en T002 et T003 ; une tâche ultérieure qui découvre un
   besoin de colonne **crée une migration `0013_…`**, elle ne retouche jamais les
   trois précédentes.
3. **Toute tâche d'UI référence sa capture** `docs/design/png/` et consomme les
   valeurs de `docs/design/tokens.md` — jamais la structure DOM/CSS de
   `docs/design/html/`.
4. Toute transition d'état → événement outbox dans la **même transaction** +
   déclaration dans `docs/taxonomie-evenements.md` **avant** implémentation + test
   d'intégration de la transition.
5. Toute chaîne utilisateur → clé i18n fr. Tout paramètre « paramétrable » →
   configuration de zone héritée.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: rendre le crate vide constructible, poser tout le schéma et tous les paramètres, déclarer les événements avant d'en émettre un seul.

- [X] T001 Remplir `backend/crates/dispatch/Cargo.toml` (dépendances `socle`, `zones`, `comptes`, `commandes`, `tarification`, `sqlx`, `serde`, `serde_json`, `uuid`, `chrono`, `thiserror`, `async-trait`, `tracing` ; dev `tokio`) et remplacer le `lib.rs` « vide ce cycle » par les déclarations de modules (`modele`, `ports`, `config`, `eligibilite`, `scoring`, `pipeline`, `offre`, `reprise`, `tic`, `depot`). **Aucune dépendance nouvelle au workspace** (principe X) — vérifier que `redis`/`deadpool-redis` y sont déjà.
- [X] T002 Migration `backend/migrations/0010_dispatch_enums.sql` — `CREATE SCHEMA dispatch` + les 4 énums (`mode_offre`, `issue_offre`, `motif_ecart` à 8 valeurs, `motif_reassignation`), **types seuls, aucune structure** (data-model §1 — un fichier mixte échouerait au déploiement, pas en développement). Puis `cargo sqlx migrate run`.
- [X] T003 **Deux** migrations, une par schéma touché — le nom d'un fichier de migration doit dire quel schéma il modifie, sinon l'histoire du schéma `commandes` devient introuvable sous son nom. (a) `backend/migrations/0011_dispatch_tables.sql` : les 4 tables `dispatch` (`offre`, `plafond_jour`, `incident_reassignation`, `suivi_progression`), les **2 index UNIQUE partiels** d'offre en vol (par commande, par coursier), les index d'échéance et de fenêtre — **rien d'autre que le schéma `dispatch`**. (b) `backend/migrations/0012_commandes_capacites.sql` : `commandes.capacite_requise`, l'index partiel `livraison_coursier_livree (coursier_id, livree_le DESC) WHERE etat = 'livree'` (base de l'inactivité — celui du cycle 008 filtre les états de **travail**, pas `livree`), et le **rétro-remplissage** des capacités requises depuis `outbox.evenement` (`payload->>'transport_requis'`). Puis `cargo sqlx migrate run` + `cargo sqlx prepare`.
- [X] T004 [P] Seed `backend/seeds/70_dispatch_parametres.sql` — les **18 paramètres** (7 au niveau pays, 11 au niveau ville), rejouable `ON CONFLICT … DO UPDATE`, aucun événement émis. Valeurs exactes en data-model §4 ; vérifier qu'aucune clé ne double `suivi.position_periode_s`, `commande.escalade_attente_coursier_s` ni `transport.actifs`.
- [X] T005 [P] Déclarer dans `docs/taxonomie-evenements.md` les **12 nouveaux événements** et l'amendement de `commande.attente_coursier_escaladee` (propriété `chemin`), avec leur qualification **produit vs opérations** pour MET-01 (data-model §7). **Avant** toute implémentation (constitution VI).
- [X] T006 [P] Poser les clés i18n : `message_cle` d'erreur du module dans `backend/api/src/erreurs_dispatch.rs` (liste en contracts §1.4), libellés d'écran dans `apps/mefali_pro/lib/l10n/app_fr.arb`, et les clés partagées éventuelles dans `apps/packages/mefali_core/lib/l10n/core_fr.arb`. Aucune chaîne en dur nulle part.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: le domaine pur, ses ports, ses doubles, et les extensions de `commandes` sans lesquelles aucune story ne compile.

**⚠️ CRITICAL**: aucune story ne démarre avant la fin de cette phase.

- [X] T007 `backend/crates/dispatch/src/modele.rs` — types purs de data-model §5 (`InscriptionPool`, `Capacite`, `Candidat`, `Composantes`, `EcartEligibilite`, `MotifEcart`, `Evaluation`, `MesureProximite`, `Offre`, `IssueOffre`, `ModeOffre`, `DecisionPipeline`, `Reprise`) + `ErreurDispatch` (`thiserror`) avec `message_cle()`. Montants en `i64` d'unités mineures + devise `String` ; scores et distances en **entiers** (R6).
- [X] T008 `backend/crates/dispatch/src/ports.rs` — les 2 traits **offerts** (`PoolCoursiers`, `VerrouOffre` + `PoseVerrou` à **trois** issues) et les **5** traits **consommés** (`EtatCoursier`, `NotePrestataire`, `PairesBloquees`, `ProximiteRoutiere`, **`NotificationsDispatch`**), signatures de contracts/ports-dispatch.md §2. Le dernier est **le contrat d'émission** de FR-094 (`Annonce`, `Canal` à 3 valeurs, clés i18n et variables typées, drapeau d'annulation sans frais) : cinq exigences en dépendent — FR-026, FR-053, FR-064, FR-065, FR-073 — et sans lui T035 et T059 sont bloquées. `annoncer` ne rend **jamais** d'erreur fatale : une annonce perdue ne doit pas annuler une affectation déjà écrite.
- [X] T009 [P] Doubles de test dans `backend/crates/dispatch/src/ports.rs` — `MemoirePool` (peupler, vider, faire expirer), `VerrouMemoire`, `CoursierFixe`, `ProximiteFixe` (distances et durées connues d'avance), `PairesSimulees`, `NotificationsCollectees` (retient les annonces, pour que SC-006 et SC-012 puissent asserter « la cliente a été prévenue avec le motif et l'annulation sans frais offerte ») ; plus les **impls de production** `NoteAbsente`, `AucunePaireBloquee` et `AnnoncesJournalisees` (patron `AucuneCommandeActive` : pas des bouchons menteurs, l'état exact du monde avant AVI, CRS-07 et NTF-01).
- [X] T010 `backend/crates/dispatch/src/config.rs` — chargement des 18 paramètres par `ConfigurationZones`, avec **deux gardes qui refusent au chargement** : `verrou_offre_s > timer_offre_s` (SC-005) et somme des 4 poids = 100. Une clé absente est une erreur de configuration, jamais un défaut silencieux (patron `parametre_i64` du cycle 008). Tests unitaires des deux refus.
- [X] T011 `backend/crates/dispatch/src/depot.rs` — `PgDispatch`, racine de composition (pool sqlx + les 6 ports), patron `PgCommandes`. Aucun port optionnel : une composition incomplète ne compile pas.
- [X] T012 `backend/crates/commandes/src/etats.rs` — ajouter les **2 lignes** à `TRANSITIONS` : `nouvelle → en_attente_paiement` et `en_cours → en_attente_coursier`, acteur `Systeme`. Tests unitaires : les deux autorisées, et les refus symétriques (`en_cours → en_attente_paiement` reste **refusé** — on ne remet pas une course en paiement une fois lancée ; `en_attente_coursier → en_attente_paiement` refusé).
- [X] T013 `backend/crates/commandes/src/ports.rs` — étendre `CommandesADispatcher` des **6 méthodes** (`course_active`, `fin_derniere_course`, `capacites_requises`, `etat_progression`, `retirer_coursier`, `exiger_prepaiement`) + les types `EtatProgression`, `Capacite`, `MotifPrepaiement`. Étendre `AffectationSimulee` en conséquence pour que la suite du cycle 008 continue de compiler.
- [X] T014 `backend/crates/commandes/src/depot.rs` — impl des **3 lectures** : `course_active` (index partiel `livraison_coursier_active`), `fin_derniere_course` (index de T003), `etat_progression` (nombre d'arrêts collectés, délai de préparation annoncé, position du premier arrêt non résolu). `cargo sqlx prepare`.
- [X] T015 `backend/crates/commandes/src/depot.rs` — impl des **2 écritures** : `retirer_coursier` (`livraison.coursier_id = NULL` + tronc `en_cours → en_attente_coursier`) et `exiger_prepaiement` (tronc `nouvelle → en_attente_paiement` + `mode_paiement = mobile_money`), chacune avec son événement **dans la même transaction**. Tests d'intégration des 2 transitions dans `backend/api/tests/commandes_etats.rs` (constitution VII).
- [X] T016 `backend/crates/commandes/src/creation.rs` — écrire `commandes.capacite_requise` à la création depuis `demande.transport_slug` (famille `transport`) et implémenter `capacites_requises`. **Le corps HTTP de `POST /commandes` ne change pas** : vérifier par `./scripts/generate-clients.sh` que le diff de clients reste **vide** sur ce chemin.
- [X] T017 `backend/crates/comptes/src/…` — impl du port `EtatCoursier` (`CoursierExploitable` : rôle coursier validé, compte non bloqué, véhicules déclarés lus de `comptes.vehicule_declare`). `dispatch` ne cite jamais `comptes.*` (patron `RestrictionsCompte` du cycle 008). `cargo sqlx prepare`.
- [X] T018 `backend/api/src/infra_redis.rs` — `RedisPool` : publication des **3 clés** (`coursier:pos:{id}` au **format inchangé** du cycle 008, hash `dispatch:etat:{id}` + `EXPIRE`, `GEOADD` dans `dispatch:pool:{zone}`), retrait immédiat, lecture d'état, `dans_rayon` par `GEOSEARCH BYRADIUS`, élagage des fantômes GEO. Aucune erreur de lecture ne remonte : Redis muet dégrade, ne casse pas. Tests dans `backend/api/tests/infra_redis.rs` contre le **vrai** Redis, **sautés** avec message s'il est injoignable.
- [X] T019 `backend/api/src/infra_redis.rs` — `RedisVerrouOffre` : les **2 scripts Lua** (pose **tout-ou-rien** des deux verrous, libération conditionnée au **jeton**). Tests contre le vrai Redis : pose concurrente sur la même commande, pose concurrente sur le même coursier, rollback du premier verrou quand le second échoue, libération refusée avec un mauvais jeton.
- [X] T020 [P] `backend/api/src/infra_dispatch.rs` — impl de `ProximiteRoutiere` au-dessus de `tarification::routage::matrice_ou_degrade` : **une seule** matrice pour tous les candidats, cache par tronçon, dégradé ×1,4 `degraded=true` journalisé, **jamais** d'erreur (R5, constitution IV).
- [X] T021 [P] `backend/api/src/erreurs_dispatch.rs` — mapping `ErreurDispatch` → `{ code, message_cle }` et statuts HTTP, sur le patron de `erreurs_commandes.rs` (transition inexistante = `409`, acteur non autorisé = `403`, offre d'un autre = `404`).
- [X] T022 `backend/api/tests/bac_dispatch/mod.rs` — bac d'essai : app Actix **réelle**, arbre CI → Tiassalé, les 18 paramètres, 4 coursiers avec rôle validé, jetons signés et **véhicules `moto`** déclarés, positions proches, doubles `NoteAbsente`/`AucunePaireBloquee`/`ProximiteFixe`. ⚠ `a_pied` plafonne à 800 m dans la grille seedée : un bac en `a_pied` ferait échouer le devis avant le dispatch.

**Checkpoint**: le crate compile, le schéma existe, les ports sont doublés — les stories peuvent démarrer.

---

## Phase 3: User Story 1 — Être dans le pool tant qu'on donne signe de vie (DSP-01, Priority: P1) 🎯 MVP

**Goal**: Yao se met en ligne, déclare son plafond du jour, publie sa position, et sort du pool quand il se taise — visiblement.

**Independent Test**: trois coursiers en ligne, interrogeables par zone et par rayon avec leur état complet ; couper les publications de l'un → il sort du pool, ne reçoit plus d'offre, son app affiche l'état de reconnexion ; effacer tout le pool → aucune commande perdue, reconstitution à la publication suivante. Aucune offre n'est encore construite.

- [X] T023 [US1] `backend/crates/dispatch/src/pool.rs` — publication (délègue au port, `ttl = dispatch.pool_ttl_s`), retrait **immédiat** au passage hors ligne, lecture d'état avec âge, élagage paresseux d'un membre GEO sans hash. Tests unitaires sur `MemoirePool`.
- [X] T024 [US1] `backend/crates/dispatch/src/plafond.rs` — déclaration du plafond du jour (`dispatch.plafond_jour`, clé primaire portant la **date** : jamais de report tacite), résolution du **plafond retenu** = `min(déclaré, palier de la grille par note)` avec **palier d'entrée** si la note est absente (R7), et exposition de `plafond_source` pour que Yao voie **lequel** s'applique.
- [X] T025 [US1] `backend/api/src/dispatch_http.rs` — `PUT /moi/disponibilite`, `GET /moi/disponibilite`, `POST /moi/position` (contracts §1.1–1.2) : garde `Role::Coursier`, `uuid_client` + `horodatage_local` avec **horodatage serveur** faisant foi, rejeu idempotent. **Terminer par** : annotations `#[utoipa::path]` à jour → `./scripts/generate-clients.sh` → `git diff --exit-code clients/` vide → `cargo build` vert.
- [X] T026 [US1] Émettre `coursier.disponibilite_changee` (avec `motif` : `manuel` \| `ttl_expire`) depuis `backend/crates/dispatch/src/pool.rs` et `coursier.plafond_jour_declare` depuis `backend/crates/dispatch/src/plafond.rs`, chacun par `socle::ecrire_evenement` **dans la même transaction** que son changement ; charges utiles exactes de data-model §7 — **aucune coordonnée**. Vérifier la concordance avec `docs/taxonomie-evenements.md` (T005).
- [X] T027 [US1] `backend/api/tests/dispatch_pool.rs` — les **7 scénarios d'acceptation** de US1 : inscription complète, sortie par silence, retrait immédiat hors ligne, coursier avec course active non offreable, perte totale du pool, plafond plafonné par la grille, plafond redemandé au nouveau jour (SC-003).
- [ ] T028 [US1] `apps/packages/mefali_core/lib/src/coursier/api_dispatch.dart` — couche d'appel des endpoints de disponibilité et d'offre. Rend le **corps JSON du contrat** (via `standardSerializers` du paquet généré), **pas** les DTO : c'est ce chemin que les tests widget couvrent (leçon du cycle 008). Export dans `mefali_core.dart`.
- [ ] T029 [US1] `apps/mefali_pro/lib/coursier/disponibilite/etat_disponibilite.dart` — `Notifier<EtatDisponibilite>` en `@Riverpod(keepAlive: true)` (porteur de **processus** : la mise en ligne traverse les écrans), `retry: pasDeRetry`, `.g.dart` généré par `build_runner` et **commité**.
- [ ] T030 [US1] `apps/mefali_pro/lib/coursier/disponibilite/ecran_disponibilite.dart` — écran K1, cible `docs/design/png/K1-disponibilite.png`, valeurs de `docs/design/tokens.md` : bascule en ligne, saisie du plafond du jour avec le plafond retenu et son palier, bandeau de reconnexion (réutiliser `BandeauHorsLigne` de `mefali_core`), montants par `formaterMontant`. Widgets Material 3 thémés, constructeurs `.adaptive`, aucune transposition de `docs/design/html/`.
- [ ] T031 [US1] `apps/mefali_pro/lib/coursier/disponibilite/emetteur_position.dart` + tests widget de l'écran K1 (`docs/design/png/K1-disponibilite.png`) — publication par `geolocator.getPositionStream` à `suivi.position_periode_s` **en premier plan** (limite assumée : en arrière-plan le coursier sort du pool par TTL, ce qui est conforme à DSP-01 et visible par son bandeau). Tests : plafond retenu affiché, source du plafond, bandeau à la perte de réseau, nouveau jour → plafond redemandé.

**Checkpoint**: US1 est démontrable seule sur appareil — le pool se peuple depuis un vrai téléphone et se vide quand le réseau tombe.

---

## Phase 4: User Story 2 — Ne proposer une course qu'à ceux qui peuvent la faire (DSP-02, Priority: P1)

**Goal**: le filtre écarte tout ce qui rendrait la course impossible, et bascule en prépaiement quand — et seulement quand — l'argent à avancer est le seul obstacle.

**Independent Test**: un pool où chaque coursier échoue sur **un seul** critère (occupé, mauvais véhicule, à 5 km, plafond trop bas, paire bloquée, compte suspendu) → la liste des éligibles est exactement celle attendue, motif par motif ; vider la capacité d'avance de tous les éligibles par ailleurs → bascule prépaiement notifiée ; vider le pool pour une autre raison → file d'attente. Aucune offre n'est émise.

- [ ] T032 [US2] `backend/crates/dispatch/src/eligibilite.rs` — le filtre et ses **8 critères nommés un par un**, dans l'ordre des motifs de l'énum : hors ligne, course active, capacités non couvertes (`capacites_requises` ⊆ capacités déclarées), hors rayon (T033), capacité d'avance (T034), **paire bloquée** — un **seul** appel `PairesBloquees::bloquees(coursier, [client + vendeurs de tous les arrêts])`, jamais un appel par arrêt (FR-025) —, compte indisponible, offre en vol. Rend pour chaque coursier écarté la **liste** de ses motifs (`EcartEligibilite`) et non le premier : FR-026 en dépend. Confirmation en base par `EtatCoursier` et `course_active` — le pool seul ne rend **jamais** éligible (FR-009). Journaliser chaque écart avec son motif (FR-029) — un pipeline qui ne trouve personne n'est jamais silencieux sur la raison. Tests unitaires par motif.
- [ ] T033 [US2] `backend/crates/dispatch/src/eligibilite.rs` — rayon en **deux étages** : pré-filtre `dans_rayon` en vol d'oiseau (sûr par construction : il minore la route), puis test exact sur la **distance routière** de `ProximiteRoutiere`, dégradé journalisé si OSRM est muet et **jamais** bloquant (R5). Test des bornes : 3,9 km retenu, 5 km écarté.
- [ ] T034 [US2] `backend/crates/dispatch/src/eligibilite.rs` — capacité d'avance : **montant des articles, tous arrêts confondus** ≤ `min(palier de la grille par note, plafond déclaré du jour)`, comparaison en **entiers** et même devise. Test du cas qui compte : grille 10 000 et déclaration 15 000 → c'est **10 000** qui décide.
- [ ] T035 [US2] `backend/crates/dispatch/src/pipeline.rs` — bascule prépaiement : déclenchée **seulement** s'il existe un écart dont `motifs == [CapaciteAvance]`, appel de `exiger_prepaiement`, événement `dispatch.bascule_prepaiement`, et annonce cliente portant le motif via `NotificationsDispatch::annoncer` (canal `Client`, T008). Aucun chemin de paiement partiel. Reprise du pipeline sur `commande.paiement_confirme`, **sans** le critère d'avance.
- [ ] T036 [US2] `backend/crates/dispatch/src/pipeline.rs` — mise en file et reprise FIFO : aucun éligible pour une autre raison → `en_attente_coursier` (mécanique CMD-10 existante, aucune table nouvelle), cliente informée, et reprise par âge au tic. Le prépaiement **n'est pas** proposé dans ce cas.
- [ ] T037 [US2] `backend/api/tests/dispatch_eligibilite.rs` — un test par valeur de `dispatch.motif_ecart` (**8**), plus la bascule prépaiement, plus la mise en file, plus le cas OSRM indisponible (SC-012, SC-013). Vérifier qu'un coursier suspendu **après** sa dernière publication est écarté malgré son hash Redis.

**Checkpoint**: le vivier est juste, et l'argent est protégé avant qu'aucune offre ne parte.

---

## Phase 5: User Story 3 — Classer les candidats : rapide et équitable (DSP-03, Priority: P2)

**Goal**: quatre composantes normalisées, pondérées par zone, en entiers, avec l'inactivité qui empêche qu'un coursier ne reçoive jamais rien.

**Independent Test**: un vivier de candidats égaux hormis une composante à la fois → l'ordre suit cette composante ; changer les poids de la zone → l'ordre change ; deux candidats parfaitement égaux → l'ordre varie ; 20 dispatches sur 4 coursiers comparables → aucun laissé de côté.

- [ ] T038 [US3] `backend/crates/dispatch/src/scoring.rs` — les 4 composantes en **millièmes**, les poids en **centièmes**, score = `Σ(poids × composante) / 100`, **entiers de bout en bout** (R6). Normalisations exactes de research R6, dont la proximité **relative au lot** (le meilleur vaut 1000, le pire 0). Tests unitaires par composante.
- [ ] T039 [US3] `backend/crates/dispatch/src/scoring.rs` — inactivité depuis `fin_derniere_course`, ou depuis l'**entrée dans le pool** à défaut (un nouvel arrivant n'est pas traité comme quelqu'un qui vient de finir), normalisée par `dispatch.inactivite_plafond_s` ; taux d'acceptation calculé sur `dispatch.offre` dans la fenêtre `dispatch.acceptation_fenetre_jours`, **hors non-réponses franches**, valeur neutre si aucune offre. `cargo sqlx prepare`.
- [ ] T040 [US3] `backend/crates/dispatch/src/scoring.rs` — égalité de score → ordre **aléatoire** ; journalisation **structurée** du classement complet (candidats, composantes, score, rang, motifs d'écart) avec identifiant de corrélation, **sans aucune coordonnée** ; événement outbox `dispatch.evaluation_faite` avec le seul agrégat (data-model §7).
- [ ] T041 [US3] `backend/api/tests/dispatch_scoring.rs` — les 8 scénarios de US3, dont : poids de zone modifiés → ordre changé **sans redéploiement**, ETA utilisée quand connue et distance sinon, égalité → ordre variable, et **équité** 20 dispatches × 4 coursiers → chacun sollicité ≥ 3 fois (SC-007). Vérifier que `dispatch.poids_inactivite = 0` fait **échouer** le test d'équité — c'est la preuve que le paramètre agit.

**Checkpoint**: le classement est juste, reproductible et auditable.

---

## Phase 6: User Story 4 — Une course, un seul preneur (DSP-04, Priority: P2)

**Goal**: l'offre part au mieux classé sous double verrou, la double acceptation est impossible, et une non-réponse ne coûte rien les trois premières fois du jour.

**Independent Test**: offrir au meilleur candidat et vérifier le contenu, le compte à rebours, l'affectation ; faire accepter **deux coursiers simultanément** → exactement une affectation, le second « déjà prise » sans pénalité et toujours dans le pool ; deux pipelines simultanés sur un seul éligible → une seule offre ; refuser puis laisser expirer → suivant sollicité, compteur de non-réponses franches juste.

- [ ] T042 [US4] `backend/crates/dispatch/src/offre.rs` — émission : pose du **double verrou** (les deux ou aucun) et traitement des **trois** issues de `PoseVerrou`, chacune nommée — `Obtenu` → écrire la ligne `dispatch.offre` avec **échéance persistée** (`emise_le + dispatch.timer_offre_s`), annoncer au coursier (canal `CoursierHautePriorite`) et émettre `dispatch.offre_emise` ; `CoursierDejaPorteur` → passer **immédiatement** au candidat suivant, sans attendre la conclusion de l'offre concurrente (FR-057) ; `CommandeDejaOfferte` → abandonner ce passage, une autre évaluation tient déjà la commande. Ne pas re-solliciter un coursier déjà destinataire pour **cette** commande (lecture de l'historique d'offres, aucune colonne nouvelle).
- [ ] T043 [US4] `backend/crates/dispatch/src/offre.rs` — contenu de l'offre : arrêts dans l'ordre optimisé du devis figé avec **distances inter-arrêts**, destination **approximative** (`zone_nom` + distance, **aucune coordonnée** avant acceptation), gain total détaillé (déplacement, arrêts, effort) et montant à avancer avec le plafond retenu. Consigner l'**écart avec K2** (« quartier Sokoura » impossible : `TypeZone::Quartier` est une PROVISION).
- [ ] T044 [US4] `backend/crates/dispatch/src/offre.rs` — conclusion : acceptation → `CommandesADispatcher::affecter` (jamais d'écriture directe) + `dispatch.offre_acceptee` + libération des deux verrous ; refus explicite → candidat suivant **immédiatement** + `dispatch.offre_refusee` ; seconde acceptation → `dispatch.offre_deja_prise`, **sans pénalité**, coursier **maintenu** dans le pool.
- [ ] T045 [US4] `backend/crates/dispatch/src/offre.rs` — non-réponse : marquage `franche` pour les `dispatch.timeouts_francs_par_jour` premières du **jour** (comptées sur `dispatch.offre`), exclusion des franches du taux d'acceptation, aucune sanction, événement `dispatch.offre_non_repondue` portant `rang_du_jour`.
- [ ] T046 [US4] `backend/api/src/dispatch_http.rs` — `GET /courses/offre-courante` (`204` si aucune, et `204` sur une offre **échue même si le tic n'a pas passé** : l'échéance persistée est l'autorité), `POST /courses/offres/{id}/accepter`, `POST /courses/offres/{id}/refuser` : garde de rôle **et** de propriété (`404` sur l'offre d'un autre), rejeu idempotent rendant le **même** corps. **Terminer par** : `#[utoipa::path]` à jour → `./scripts/generate-clients.sh` → diff `clients/` vide → `cargo build` vert.
- [ ] T047 [US4] `backend/crates/dispatch/src/pipeline.rs` — `DecisionPipeline` : **un seul** point de sortie du pipeline (`OffreEmise`, `BroadcastOuvert`, `BasculePrepaiement`, `MiseEnFile`, `RienAFaire`), donc un seul endroit où les événements s'écrivent et un seul à tester.
- [ ] T048 [US4] `backend/api/src/lib.rs` — `DispatchOutbox`, **premier consommateur outbox réel du produit** (`WorkerOutbox::new(pool, Vec::new())` tourne aujourd'hui à vide), branché sur `commande.prete_a_dispatcher` et `commande.paiement_confirme`. ⚠ Ne rendre `Err` **que** sur une panne d'infrastructure : toute issue métier est un succès écrit en base, sinon l'événement est rejoué indéfiniment (R1).
- [ ] T049 [US4] `backend/api/src/lib.rs` — `job_tic_dispatch` (intervalle 5 s, patron `job_expirer_substitutions`) : expiration des offres échues → non-réponse → candidat suivant. Une erreur est journalisée et retentée ; un incident de tic ne fait **jamais** tomber l'API.
- [ ] T050 [US4] `backend/api/tests/dispatch_offre.rs` — les scénarios 1 à 9 et 11 de US4 : contenu de l'offre, refus d'une seconde offre pour la même commande, refus explicite, non-réponse, franchise du jour puis 4ᵉ qui compte, réseau du destinataire qui tombe, rejeu d'acceptation, libération du verrou de coursier à la conclusion. Plus **SC-002** : asserter `delai_assignation_s` de l'événement `commande.assignee` sous le seuil de 2 min sur un dispatch nominal — mesuré sur l'événement, jamais au chronomètre.
- [ ] T051 [US4] `backend/api/tests/dispatch_concurrence.rs` — **le test qui porte le cycle** : (A) N tâches tokio acceptent en parallèle sur l'app réelle + **vrai Redis** → exactement un `200`, N−1 `409 deja_prise`, aucune pénalité ; (B) `affecter` appelé deux fois en parallèle **sans Redis** → une seule affectation, la seconde refusée par la table fermée, prouvant que SC-001 ne dépend pas de Redis ; (C) deux pipelines simultanés, un seul éligible → une seule offre, la seconde commande passe au candidat suivant (SC-014). Plus les 3 requêtes de contrôle du quickstart. Sauté si Redis est absent — sauf (B).
- [ ] T052 [US4] `apps/mefali_pro/lib/coursier/offre/etat_offre.dart` — `AsyncNotifier` en `@riverpod` **nu** (autoDispose : chargement jetable), interrogation de `GET /courses/offre-courante` toutes les 2 s tant qu'un écran de dispatch est monté, `retry: pasDeRetry`, `.g.dart` commité.
- [ ] T053 [US4] `apps/mefali_pro/lib/coursier/offre/ecran_offre.dart` — écran K2, cible `docs/design/png/K2-offre-course.png`, valeurs de `docs/design/tokens.md` : plein écran, **compte à rebours en état LOCAL du widget** (constitution XII le nomme explicitement), autorité = `echeance_le` du serveur ; arrêts numérotés avec distances inter-arrêts, destination avec la mention « adresse exacte après acceptation », gain en display `--success`, avance en display `--danger` sur fond teinté, décision à une main en bas.
- [ ] T054 [US4] `apps/mefali_pro/lib/coursier/offre/ecran_offre.dart` + tests widget — état K2-1b (`docs/design/png/K2-offre-course.png`, panneau « Timer expiré ») : « course attribuée à un autre coursier », ton **neutre**, « sans pénalité — n sur 3 aujourd'hui », retour au tableau de bord en action unique. Test : reconstruire avec une échéance dépassée affiche K2-1b **sans** appel réseau supplémentaire.

**Checkpoint**: le cœur du cycle tient — une course, un preneur, prouvé avec et sans Redis.

---

## Phase 7: User Story 5 — Quand la cascade s'essouffle, demander à tout le monde (DSP-05, Priority: P3)

**Goal**: après 3 candidats ou 120 s, tous les éligibles en même temps, premier accepteur, sans jamais afficher deux écrans au même coursier.

**Independent Test**: 3 candidats sans réponse → broadcast ; forcer le délai avant les 3 candidats → même bascule ; deux coursiers acceptent en broadcast → un seul gagnant ; personne n'accepte → la recherche continue.

- [ ] T055 [US5] `backend/crates/dispatch/src/pipeline.rs` — bascule broadcast sur conditions **alternatives** (`dispatch.broadcast_apres_candidats` **OU** `dispatch.broadcast_apres_s` depuis le début du pipeline), **réévaluation de l'éligibilité à l'émission**, et application du **verrou de coursier** à chaque destinataire atteint : deux broadcasts concurrents se **sérialisent** au lieu de se disputer les écrans (FR-062). Événement `dispatch.broadcast_ouvert` avec sa `cause`.
- [ ] T056 [US5] `backend/crates/dispatch/src/offre.rs` — premier accepteur par le **même verrou de commande** ; les autres reçoivent `dispatch.offre_deja_prise`, sans pénalité ; un broadcast sans preneur **n'arrête pas** le pipeline et laisse le compte d'escalade courir.
- [ ] T057 [US5] `backend/api/tests/dispatch_broadcast.rs` — les 6 scénarios de US5, dont la **sérialisation de deux broadcasts concurrents** et l'exclusion d'un coursier devenu occupé entre le début du pipeline et l'émission.

**Checkpoint**: trois attentes de 40 s deviennent une seule course.

---

## Phase 8: User Story 6 — Prévenir l'exploitation et la cliente (DSP-06, Priority: P3)

**Goal**: une alerte, une seule, par commande non assignée au seuil de zone — et une annulation sans frais offerte à la cliente, sans arrêter la recherche.

**Independent Test**: une commande sans preneur au-delà du seuil → exactement une alerte d'exploitation et une notification cliente avec annulation sans frais ; rebalayer n'en ré-émet aucune ; une commande escaladée reste assignable et annulable sans frais.

- [ ] T058 [US6] `backend/crates/commandes/src/depot.rs` — étendre `escalader_attentes` : le `WHERE` couvre aussi les commandes en `nouvelle` dont l'âge dépasse le seuil (pas seulement `en_attente_coursier`), et le payload gagne `chemin` (`file` \| `pipeline`). **Conserver** le `NOT EXISTS` sur l'outbox comme marqueur d'idempotence — c'est lui qui livre « exactement une alerte, quel que soit le chemin » (FR-066). `cargo sqlx prepare`.
- [ ] T059 [US6] `backend/api/src/lib.rs` + `backend/crates/dispatch/src/tic.rs` — **câbler** l'escalade dans le tic (elle n'était planifiée nulle part depuis le cycle 008) et émettre **deux** annonces par `NotificationsDispatch::annoncer` (T008) : canal `Exploitation` pour l'alerte, canal `Client` avec `action_annulation_sans_frais = true` pour la cliente (FR-065). L'escalade **ne stoppe pas** le pipeline.
- [ ] T060 [US6] `backend/api/src/admin_dispatch_http.rs` — `GET /admin/dispatch/alertes` (escalades + courses bloquées, plus anciennes d'abord) et `GET /admin/dispatch/pool` (matière de la carte des coursiers d'ADM-02), garde `Role::Admin`. **Aucun écran** n'est construit (FR-096). **Terminer par** : `#[utoipa::path]` à jour → `./scripts/generate-clients.sh` → diff `clients/` vide → `cargo build` vert.
- [ ] T061 [US6] `backend/api/tests/dispatch_escalade.rs` — les 5 scénarios de US6 : alerte + notification, aucune ré-émission au rebalayage, commande escaladée puis assignée, annulation sans frais, et **deux chemins d'arrivée → une alerte chacune** (SC-006). Inclure la requête de contrôle SQL du quickstart.

**Checkpoint**: aucune commande ne reste silencieuse, et l'exploitation n'est pas noyée.

---

## Phase 9: User Story 7 — Reprendre une course qui n'avance pas (DSP-07, Priority: P4)

**Goal**: reprendre l'immobile et l'injoignable, épargner celui qui roule, et ne **jamais** retirer automatiquement une course dont le coursier a déjà payé un vendeur.

**Independent Test**: coursier immobile au-delà du délai → repris, incident tracé, re-proposé ; coursier qui se rapproche → **pas** repris ; coursier qui a cessé de publier → repris ; coursier avec un arrêt collecté → **aucune** reprise automatique, escalade émise.

- [ ] T062 [US7] `backend/crates/dispatch/src/reprise.rs` — critère **sans mouvement** : mise à jour de `dispatch.suivi_progression` à chaque publication de position d'un coursier assigné (distance routière au premier arrêt non résolu, `distance_min_m`, `progresse_le`), et détection d'un rapprochement inférieur à `dispatch.reassignation_deplacement_min_m` sur `dispatch.reassignation_sans_mouvement_s`. L'**absence de position récente** compte comme absence de mouvement (FR-078). `cargo sqlx prepare`.
- [ ] T063 [US7] `backend/crates/dispatch/src/reprise.rs` — critère **sans scan** (`assignee_le` + préparation annoncée + `dispatch.reassignation_sans_scan_marge_s`, motif **distinct**), et la **garde d'argent** : si `etat_progression.nb_arrets_collectes > 0`, **aucune** reprise automatique → événement `dispatch.course_bloquee_escaladee` vers l'exploitation (FR-075).
- [ ] T064 [US7] `backend/crates/dispatch/src/reprise.rs` + `tic.rs` — exécution de la reprise : `retirer_coursier`, ligne `dispatch.incident_reassignation` (index UNIQUE par motif → pas de reprise en boucle), événement `dispatch.reassignation`, notification des deux parties, exclusion du coursier retiré des offres de **cette** commande, et retour au pipeline par la file FIFO. Le devis figé n'est **jamais** recalculé.
- [ ] T065 [US7] `backend/api/src/admin_dispatch_http.rs` — `POST /admin/dispatch/courses/{livraison_id}/reprendre` : **motif obligatoire** journalisé avec son auteur, `422` si aucun arrêt n'est collecté (l'automatisme suffit alors, et une action manuelle masquerait un défaut de pipeline). N'écrit ni caisse ni litige. **Terminer par** : `#[utoipa::path]` à jour → `./scripts/generate-clients.sh` → diff `clients/` vide → `cargo build` vert.
- [ ] T066 [US7] `backend/api/tests/dispatch_reassignation.rs` — les 7 scénarios de US7 dans l'ordre du quickstart : immobile → repris, se rapproche → **pas** repris (SC-015), positions coupées → repris, sans scan → repris pour son motif, arrêt collecté → **jamais** repris + escalade, rebalayage → pas de boucle, réassignation → devis inchangé (SC-010).

**Checkpoint**: toutes les stories sont fonctionnelles indépendamment.

---

## Phase 10: Polish & Cross-Cutting Concerns

- [ ] T067 [P] `backend/crates/dispatch/src/tic.rs` — élaguer les fantômes GEO à chaque passage, avec journalisation du compte. Aucun plafond silencieux : ce qui est élagué est compté.
- [ ] T068 `backend/api/tests/dispatch_resilience.rs` — perte totale du pool en pleine cascade (`FLUSHDB`) : aucune commande perdue, aucune double affectation, reconstitution à la publication suivante, offres en vol redétectées par leur échéance persistée (SC-004). Plus le fantôme GEO : membre présent sans hash → **ne reçoit rien**, puis élagué. **Dépend de T067** — ce test échouerait sans l'élagage, il n'est donc pas marqué parallélisable.
- [ ] T069 [P] `backend/api/tests/dispatch_transverses.rs` — les **18 paramètres** changent le comportement observable sans redéploiement (SC-008, avec le contrôle d'inventaire SQL) ; **aucune** coordonnée ni numéro dans les événements du module, par parcours automatique des charges utiles (SC-011) ; refus de configuration `verrou ≤ timer` et somme de poids ≠ 100 (SC-005).
- [ ] T070 [P] Rapport `specs/009-dispatch-assignation-auto/rapport-ecarts.md` — les écarts assumés et leur raison : « quartier Sokoura » de K2 impossible (`TypeZone::Quartier` = PROVISION), aucune sonnerie (NTF-01), publication de position en premier plan seulement, bandeau de gains du jour laissé à CRS-01. À porter au produit, pas à contourner.
- [ ] T071 Validation `quickstart.md` sur émulateur Android — dérouler SC-001 à SC-015 avec l'API sur IP LAN, position de l'émulateur sur Tiassalé (`adb emu geo fix -4.8210 5.8960`), et consigner les défauts trouvés. Les cycles 006 et 008 ont tous deux trouvé de vrais bugs à cette étape : la prévoir pleine, pas en marge.
- [ ] T072 **Revue Definition of Done** (`docs/user-stories-v2.md` §0.4), point par point sur les 7 stories : (1) critères d'acceptation couverts par des tests, unitaires **et** d'intégration sur les transitions ; (2) annotations utoipa à jour et clients Dart/TS régénérés **sans diff manuel** ; (3) migrations versionnées et seeds à jour ; (4) événement outbox pour tout changement d'état **plus** les événements MET-01 des parcours concernés ; (5) clés i18n fr externalisées, aucune chaîne en dur ; (6) tout paramètre « paramétrable » en configuration de zone. Clore par `cargo test --workspace`, `cargo sqlx prepare`, `cargo clippy --all-targets -- -D warnings`, `flutter test`, `dart analyze`, `./scripts/verifier-accord-locks.sh`.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)** : aucune dépendance. T002 → T003 (les énums avant leur usage, et `0011` avant `0012`) ; T004, T005, T006 en parallèle.
- **Foundational (Phase 2)** : dépend du Setup — **bloque toutes les stories**. T007 → T008 → {T009, T010, T011} ; T012 → T013 → {T014, T015} ; T016 dépend de T003 ; T017, T020, T021 indépendants ; T018 → T019 ; T022 dépend de T004, T017.
- **US1 (Phase 3)** : dépend de Phase 2 (T018 pour le pool, T024 a besoin de la grille de T004).
- **US2 (Phase 4)** : dépend de **US1** — sans pool peuplé, il n'y a rien à filtrer. Et de T013–T016 (capacités requises, prépaiement).
- **US3 (Phase 5)** : dépend de **US2** — on ne classe que des éligibles. Et de T020 (proximité).
- **US4 (Phase 6)** : dépend de **US3** (l'ordre décide du destinataire) et de T019 (verrous Lua).
- **US5 (Phase 7)** : dépend de **US4** — le broadcast réutilise l'émission et le verrou.
- **US6 (Phase 8)** : dépend de **US2** au minimum (la file existe) ; testable pleinement après US4.
- **US7 (Phase 9)** : dépend de **US4** (une course assignée) et de T014–T015 (progression, retrait).
- **Polish (Phase 10)** : dépend des stories souhaitées ; T071 et T072 en dernier, dans cet ordre.

### Chaîne critique

`T001 → T002 → T003 → T007 → T008 → T011 → T018 → T023 → T032 → T038 → T042 → T046 → T051`

C'est la ligne qui mène au test de concurrence, donc à la garantie qui porte le
cycle. Tout ce qui n'est pas sur cette chaîne peut attendre.

### Parallel Opportunities

- Phase 1 : T004, T005, T006 ensemble.
- Phase 2 : {T009, T010} après T008 ; T017, T020, T021 à tout moment ; T012 → T013 en parallèle de T018 → T019.
- Phase 3 : T028 (couche d'appel) en parallèle de T023–T024 ; T029–T031 après T025 et T028.
- Phase 6 : T052–T054 (Flutter) en parallèle de T047–T051 (backend), une fois T046 livré.
- Phase 10 : T067, T069, T070 ensemble ; **T068 après T067** (il teste l'élagage que T067 implémente).

### Within Each User Story

Domaine pur → dépôt sqlx → surface HTTP (avec utoipa + clients + build) →
événements → tests d'intégration → Flutter. Les tests d'intégration d'une story
sont écrits **dans** sa phase, jamais reportés à la fin.

---

## Parallel Example: User Story 1

```bash
# Après T025 (API livrée, clients régénérés), deux fronts indépendants :
Task: "T028 Couche d'appel api_dispatch.dart dans apps/packages/mefali_core/lib/src/coursier/"
Task: "T027 Tests d'intégration du pool dans backend/api/tests/dispatch_pool.rs"

# Puis, une fois T028 et T029 faits :
Task: "T030 Écran K1 dans apps/mefali_pro/lib/coursier/disponibilite/ecran_disponibilite.dart"
Task: "T031 Émetteur de position + tests widget"
```

---

## Implementation Strategy

### MVP (US1 seule)

1. Phases 1 et 2 (T001–T022) — le crate compile, le schéma existe, les ports sont doublés.
2. Phase 3 (T023–T031) — Yao se met en ligne, déclare son plafond, entre et sort du pool.
3. **STOP et VALIDER** : le pool se peuple depuis un vrai téléphone, se vide au silence, survit à un `FLUSHDB`.

À ce point rien n'est encore dispatché — mais la brique dont **tout** le reste
dépend est démontrable, et c'est la seule qui puisse l'être seule.

### Livraison incrémentale

| Incrément | Ce qui devient vrai |
|---|---|
| + US2 | on sait **à qui** une course peut être proposée, et quand il faut exiger un prépaiement |
| + US3 | on sait **dans quel ordre**, et l'équité est mesurable |
| + US4 | une course est **réellement assignée**, et la double acceptation est impossible — première fin en fin sur appareil |
| + US5 | les courses que personne ne prend trouvent preneur |
| + US6 | aucune commande ne reste silencieuse |
| + US7 | une course qui n'avance pas est reprise sans jamais léser le coursier |

**US4 est le premier incrément démontrable de bout en bout** : c'est là qu'une
commande créée dans l'app cliente arrive sur l'écran de Yao et devient une course.

### Développeur solo

Suivre la chaîne critique et ne pas ouvrir deux stories à la fois. Les seuls
vrais parallélismes utiles sont backend/Flutter à l'intérieur d'une même story
(Phases 3 et 6) : ils réduisent le temps d'attente entre une API livrée et son
écran.

---

## Notes

- `[P]` = fichiers différents, aucune dépendance sur une tâche incomplète.
- Commiter par tâche ou par groupe logique, message conventionnel référençant la story : `feat(dispatch): DSP-04 …`.
- Aucune tâche n'édite `clients/dart` ni `clients/ts` — régénération uniquement.
- Aucune tâche ne modifie `backend/migrations/0001` à `0009`. Un besoin de schéma découvert en route crée `0012_…`.
- Aucune tâche n'ajoute de dépendance : si l'une semble en exiger une, c'est le signe qu'elle empiète sur NTF-01 ou CRS — s'arrêter et le signaler.
- S'arrêter à chaque **Checkpoint** pour valider la story seule : c'est ce qui garantit que le cycle reste livrable même interrompu.
