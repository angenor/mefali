---
description: "Task list — cycle 007 tarification (moteur de règles, routage, grille d'effort)"
---

# Tasks: Moteur de tarification à règles, routage et grille d'effort

**Input**: Design documents from `specs/007-tarification-moteur-effort/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/tarification-openapi.md](./contracts/tarification-openapi.md), [quickstart.md](./quickstart.md)

**Tests** : les tests d'intégration sont **obligatoires** (constitution VII + DoD §0.4.1) — une tâche de test par comportement/transition, jamais optionnelle ici.

**Organization** : tâches groupées par user story (priorité produit rappelée), **ordonnées par dépendance** (demande utilisateur). Chaque tâche vise **½ à 1 jour**.

## Règles de ce cycle (imposées)

- **Schéma** : toute tâche touchant le schéma **commence par sa migration sqlx** (nouvelle, jamais modifier une migration appliquée) ; toute tâche ajoutant des requêtes sqlx **se termine par `cargo sqlx prepare`**.
- **API** : toute tâche touchant l'API **se termine par** : annotations `#[utoipa::path]` à jour → `openapi.json` régénéré → clients Dart/TS régénérés **sans diff manuel** → **build vert** (constitution I).
- **UI** : toute tâche d'UI référence sa capture `docs/design/png/`. **Ce cycle ne construit aucune UI** (surface admin = API ; la maquette `docs/design/png/A3` est la cible du cycle **ADM** ; consommateurs CMD/DSP/CRS futurs) → **aucune tâche UI**, règle sans objet (rappelé en T035).
- **Événements/i18n/zone** : toute transition → événement outbox dans la même transaction + déclaration taxonomie ; toute chaîne utilisateur → clé i18n fr ; tout paramètre « paramétrable » → configuration de zone.

## Path Conventions

Backend Rust : crate `backend/crates/tarification/`, binaire `backend/api/`, migrations `backend/migrations/`, seeds `backend/seeds/`. Clients `clients/dart|ts/` = **régénérés**, jamais édités.

---

## Phase 1: Setup (infrastructure partagée)

- [X] T001 [P] Configurer le crate `backend/crates/tarification/Cargo.toml` (deps du workspace : `sqlx`, `serde`/`serde_json`, `uuid` v7, `chrono`, `thiserror`, `async-trait`, `reqwest`, `redis`, `utoipa` ; internes : `socle`, `zones`, `comptes`) et `src/lib.rs` (déclaration des modules `modele/grille/regle/routage/optimisation/evaluation/effort/depot/ports`) ; inscrire le crate dans `backend/api` (assemblage). Aucune nouvelle dépendance tierce (constitution X).
- [X] T002 [P] Vérifier l'infra dev : OSRM (`OSRM_URL`, service `/table` répond sur l'extrait CI — sinon `infra/osrm/prepare.sh`) et Redis (`REDIS_URL`) joignables depuis le backend ; consigner tout prérequis dans [quickstart.md](./quickstart.md).

---

## Phase 2: Foundational (prérequis bloquants — AVANT toute user story)

**⚠️ CRITIQUE** : aucune user story ne démarre avant la fin de cette phase.

- [X] T003 **Migration schéma** : créer `backend/migrations/0007_tarification.sql` (schéma `tarification` ; enum `etat_grille` ; table `grille` + index uniques partiels « en_vigueur unique » et « brouillon unique » par zone ; table `regle` + CHECKs — dont `point_relais_id IS NULL`, provision inutilisée) — `0001..0006` **intouchées** ; puis `cargo sqlx migrate run`. Voir [data-model.md §1](./data-model.md).
- [X] T004 [P] Types du domaine dans `backend/crates/tarification/src/modele.rs` : `EtatGrille`, `Point`, `Matrice`, `Itineraire`, `DemandeDevis`, `Devis`, `Composantes`, `OffreLivraison`, `SourceGrille`, erreurs `ErreurTarif`/`ErreurRoutage` (patron cast `::text`, `From<OutboxError>`).
- [X] T005 [P] Signatures des traits exposés dans `backend/crates/tarification/src/ports.rs` : `EvaluationTarifaire`, `OptimisationArrets`, `Routage` (voir [data-model.md §5](./data-model.md)) — corps `todo!()` pour compiler.
- [X] T006 [P] Déclarer les 3 événements dans `docs/taxonomie-evenements.md` : `grille.publiee`, `routage.degrade`, `effort.calcule` (entité, déclencheur, payload **minimisé ARTCI** — distances arrondies, aucun lat/lng brut) — **avant** toute implémentation (constitution VI).
- [X] T007 Squelette `PgTarification` dans `backend/crates/tarification/src/depot.rs` : constructeur (pool), branchements `ConfigurationZones` (crate `zones`) et `socle::ecrire_evenement` ; convention lectures sur pool / écritures sur `&mut PgTransaction`.

**Checkpoint** : fondation prête — les user stories peuvent démarrer.

---

## Phase 3: User Story 1 — Modèle de règles à marge bornée (TRF-01, Priority: P1 · produit P0) 🎯 MVP

**Goal** : éditer un catalogue de règles versionné (brouillon) avec marge **bornée par zone** et sélection déterministe.

**Independent Test** : créer un brouillon, ajouter une règle bien formée (acceptée) ; porter sa marge hors bornes (refusée) ; vérifier la sélection de la règle la plus spécifique en vigueur — sans évaluation ni publication.

- [X] T008 [US1] Résolution des bornes de marge via `ConfigurationZones` (`tarification.marge.min/max` d'une zone) dans `backend/crates/tarification/src/regle.rs`.
- [X] T009 [US1] Écriture (upsert) de règle dans `backend/crates/tarification/src/depot.rs` avec **garde de borne de marge** (refus hors `[min,max]`) et garde de devise = devise de zone ; `cargo sqlx prepare`.
- [X] T010 [US1] Création/obtention du **brouillon** de zone (clone de la grille en vigueur si absent) dans `backend/crates/tarification/src/grille.rs` ; `cargo sqlx prepare`.
- [X] T011 [US1] Sélection de la règle la plus spécifique en vigueur dans `backend/crates/tarification/src/regle.rs` : filtre {véhicule, catégorie?, plage horaire/jour, tranche de distance}, score de spécificité → priorité → **départage déterministe par id** (R5).
- [X] T012 [US1] Endpoints admin **brouillon CRUD** dans `backend/api/src/admin_tarification_http.rs` (`GET zones/{zone}/grille`, `POST zones/{zone}/brouillon`, `PUT`/`DELETE brouillon/{id}/regles/{id}`), gardés `auth.exiger_role(Role::Admin)` + journalisés ; erreurs i18n `tarification.erreur.*`. **Terminer par** : `#[utoipa::path]` à jour → régénérer `openapi.json` + clients Dart/TS (sans diff) → **build vert**.
- [X] T013 [P] [US1] Tests d'intégration US1 dans `backend/api/tests/` : marge hors bornes → 409 ; sélection spécifique/priorité/départage **déterministe et rejouable** ; `point_relais` reste NULL (provision) ; rôle admin exigé (403/401).

**Checkpoint** : catalogue de règles éditable et gardé, démontrable seul.

---

## Phase 4: User Story 2 — Devis figé sur itinéraire routier multi-arrêts (TRF-02, Priority: P1 · produit P0) 🎯 MVP

**Goal** : transformer une course (retraits → client) en **devis figé** sur km routiers réels, avec cache, dégradé, drapeaux et VND-08.

**Independent Test** : simuler une course multi-arrêts, vérifier la distance par **waypoints** (pas vol d'oiseau), l'invariant du devis, le **cache** (2ᵉ appel sans OSRM), le **dégradé ×1,4** journalisé non bloquant, et `livraison_offerte_mefali` → prix client 0.

- [X] T014 [US2] Client OSRM `/table` (waypoints, `annotations=distance,duration`) via `reqwest` dans `backend/crates/tarification/src/routage.rs` : construction des coordonnées, parse de la matrice.
- [X] T015 [US2] Cache Redis par **tronçon** (paire de points arrondis, TTL 24 h, précision = param de zone) dans `routage.rs` : lecture avant OSRM, écriture après ; namespace propre (R3).
- [X] T016 [US2] **Mode dégradé** dans `routage.rs` : repli vol d'oiseau × facteur de zone (1,4), `degraded=true`, **jamais bloquant** (constitution IV).
- [X] T017 [P] [US2] Optimisation d'ordre dans `backend/crates/tarification/src/optimisation.rs` : permutations **exhaustives ≤ 4** (min distance totale retraits→client, origine = 1er retrait — R6/R11), heuristique bornée explicite > 4, **déterministe** ; implémenter `OptimisationArrets` (exposé à DSP/CMD).
- [X] T018 [US2] Pipeline d'évaluation dans `backend/crates/tarification/src/evaluation.rs` (étapes 1–9 hors effort — [data-model.md §3](./data-model.md)) : sélection → déplacement (base + km au-delà du seuil, `prix_plafond`) → suppléments → **arrondi (reliquat → part coursier)** → drapeaux (client 0 / marge 0) → **VND-08 mono-vendeur** ; implémenter `EvaluationTarifaire` ; vérifier l'invariant.
- [X] T019 [US2] Émettre `routage.degrade` (via `socle::ecrire_evenement`) dans la transaction d'évaluation **réelle** de `backend/crates/tarification/src/evaluation.rs` (payload minimisé) ; le simulateur reste muet.
- [X] T020 [P] [US2] Tests d'intégration US2 dans `backend/crates/tarification/tests/evaluation.rs` (doubles `RoutageFixe`/`RoutageIndisponible`, géométries simulées) : devis routé + invariant ; **cache** (2ᵉ appel sans OSRM) ; **dégradé** ×1,4 + événement + non-blocage ; drapeaux (client 0 / marge 0) ; **VND-08 mono vs multi** ; arrondi → part coursier ; **ordre optimisé = meilleure permutation, déterministe et rejouable** (valide l'optimisation T017 dès l'MVP, sans attendre US6).

**Checkpoint** : le moteur price une livraison de bout en bout (MVP moteur = US1 + US2).

---

## Phase 5: User Story 5 — Devise par zone (TRF-04, Priority: P2 · produit P0)

**Goal** : garantir l'intégrité monétaire par zone (ISO 4217, XOF sans décimale, aucune conversion).

**Independent Test** : montants en unités mineures + code XOF ; règle en devise ≠ zone rejetée ; mélange de devises rejeté (jamais converti).

- [X] T021 [US5] Intégrité de devise : garde à l'écriture de règle (409 `tarification.erreur.devise_incoherente` si ≠ `ConfigurationZones::devise`) et **rejet du mélange de devises** dans `evaluation.rs` (aucune conversion, R8) ; `cargo sqlx prepare` si requêtes modifiées.
- [X] T022 [P] [US5] Tests d'intégration US5 dans `backend/crates/tarification/tests/devise.rs` : XOF entier sans décimale ; règle en devise étrangère rejetée ; opération inter-devises rejetée.

**Checkpoint** : tout montant du moteur est exact et non ambigu.

---

## Phase 6: User Story 3 — Simulateur obligatoire avant publication (TRF-03, Priority: P2 · produit P0)

**Goal** : rejouer un brouillon sur une course réelle et **garder la publication**.

**Independent Test** : publier sans simulation → refus ; règle hors bornes → refus ; simuler (détail complet, sans effet de bord) puis publier → grille en vigueur, ancienne archivée.

- [ ] T023 [US3] **Simulation** dans `backend/crates/tarification/src/grille.rs` : rejoue le cœur d'évaluation contre le brouillon (`SourceGrille::Brouillon`), renvoie le **détail complet** (itinéraire/`degraded`, règle, composantes, retenue, arrondi, devis) **sans effet de bord** ; pose `simulee_le`/`simulee_empreinte` ; `cargo sqlx prepare`.
- [ ] T024 [US3] **Publication** (transaction) dans `grille.rs` : garde (simulé sur **empreinte courante** ∧ aucune règle hors bornes) ; archive l'ancienne `en_vigueur` → `historique`, active le brouillon (`effet_le`) ; événement `grille.publiee` ; toute édition de règle **réarme** l'empreinte ; `cargo sqlx prepare`.
- [ ] T025 [US3] Endpoints admin `POST brouillon/{id}/simuler` et `POST brouillon/{id}/publier` dans `backend/api/src/admin_tarification_http.rs` (`Role::Admin`, journalisés ; 409 `simulation_requise`/`regle_hors_bornes`). **Terminer par** : `#[utoipa::path]` → `openapi.json` + clients régénérés (sans diff) → **build vert**.
- [ ] T026 [P] [US3] Tests d'intégration US3 dans `backend/api/tests/tarification_publication.rs` : publication sans simulation → 409 ; règle hors bornes → 409 ; édition post-simulation réarme la garde ; publication OK (en_vigueur/historique + `grille.publiee`) ; **simulateur sans trace outbox** ni changement de la grille en vigueur.

**Checkpoint** : aucune grille fausse ne peut atteindre la production.

---

## Phase 7: User Story 4 — Grille de départ Tiassalé (TRF-05, Priority: P2 · produit P0)

**Goal** : servir la grille seed de Tiassalé, éditable et rejouable.

**Independent Test** : chaque montant Tiassalé vérifié au FCFA près ; drapeaux de lancement → client 0/marge 0 ; rejeu idempotent.

- [ ] T027 [US4] Seed `backend/seeds/50_tarification_tiassale.sql` (**idempotent**, `ON CONFLICT DO NOTHING`, séparé des migrations — constitution I) : **knobs de zone** (bornes de marge, pas d'arrondi, facteur dégradé, TTL cache, seeds d'effort, plafonds — [data-model.md §2](./data-model.md)) + **grille en vigueur Tiassalé** (règles `a_pied`/`velo`/`moto`, marge 50 dans les bornes ; marge 0 du lancement via drapeau `gratuite_commissions`, R4).
- [ ] T028 [P] [US4] Test d'intégration US4 dans `backend/crates/tarification/tests/seed_tiassale.rs` : `a_pied` 100 (≤ 800 m), `velo` 150 (≤ 2 km), `moto` 200 + 50/km (plafond 500), `pluie` +100 ; drapeaux ON → prix client 0 / marge 0 / part journalisée ; rejeu du seed **idempotent**.

**Checkpoint** : Tiassalé peut tarifer dès le premier jour.

---

## Phase 8: User Story 6 — Grille d'effort & optimisation d'ordre (TRF-06, Priority: P3 · produit **P1**, avant fin de promo)

**Goal** : rémunérer l'effort (100 % coursier) et exposer l'ordre optimisé ; effort journalisé non facturé pendant la promo.

**Independent Test** : marché 12 articles/3 étals voisins = km réels + 2×25 + 100 ; prime d'attente **une seule fois par course** ; 100 % coursier ; ordre ≤ 4 optimisé ; promo → effort journalisé non facturé.

- [ ] T029 [US6] Grille d'effort dans `backend/crates/tarification/src/effort.rs` : **paliers d'articles** (total commande) ; **prime d'attente +100 une seule fois par course** (clarification 2026-07-24, requiert les deux horodatages) ; **supplément d'arrêt** indexé sur le **tronçon routier au précédent** (matrice de T017), 1er arrêt inclus, plafond optionnel de zone ; **100 % part coursier**, marge inchangée.
- [ ] T030 [US6] Intégrer l'effort à l'étape 5 du pipeline `evaluation.rs` (ajout client + part coursier) + **plafond d'éclatement** → `proposer_scission` ; émettre `effort.calcule` (journalisé **non facturé** quand `livraison_offerte_mefali` ON) dans la transaction ; à la bascule, effort facturé sans changement de code (param de zone).
- [ ] T031 [P] [US6] Tests d'intégration US6 dans `backend/crates/tarification/tests/effort.rs` : marché 3 étals voisins = 2×25 + 100 (palier 11–20) sur km réels ; **prime une fois/course** (2 arrêts lents → +100, pas 2×100) ; 100 % coursier / marge inchangée ; optimisation ≤ 4 déterministe (exposée `OptimisationArrets`) ; promo → `effort.calcule` non facturé ; plafond d'éclatement → `proposer_scission`.

**Checkpoint** : toutes les user stories sont fonctionnelles indépendamment.

---

## Phase 9: Polish & transverse — clôture

- [ ] T032 [P] Vérifier l'externalisation des **clés i18n fr** (`tarification.erreur.*`, libellés du détail de simulation) dans `backend/crates/tarification/` et `backend/api/src/admin_tarification_http.rs` — aucune chaîne utilisateur en dur (constitution VII).
- [ ] T033 Exécuter la **validation `quickstart.md`** de bout en bout (SC-001..012 + prime/course + VND-08).
- [ ] T034 `cargo test` complet + `cargo sqlx prepare` vert + `openapi.json` régénéré **sans diff** de clients (CI verte par chemins du monorepo).
- [ ] T035 **Revue Definition of Done (`docs/user-stories-v2.md` §0.4)** : (1) critères d'acceptation couverts par des tests d'intégration ; (2) annotations utoipa à jour + clients Dart/TS régénérés sans diff manuel ; (3) migration `0007` versionnée + seed `50_` à jour ; (4) événement outbox pour tout changement d'état (`grille.publiee`) + `routage.degrade`/`effort.calcule` déclarés dans la taxonomie (matière des métriques MET) ; (5) clés i18n fr externalisées ; (6) paramètres « paramétrables » en configuration de zone (bornes, arrondi, facteur dégradé, TTL, seeds d'effort, plafonds). **Note UI** : aucune capture `docs/design/png/` à référencer ce cycle — la surface A3 relève du cycle ADM ; règle UI **sans objet**.

---

## Dependencies & Execution Order

### Dépendances de phase

- **Setup (P1)** : aucune dépendance.
- **Foundational (P2)** : dépend du Setup — **bloque toutes les stories** (T003 migration en tête).
- **US1 (P3)** → après Foundational.
- **US2 (P4)** → après US1 (l'évaluation consomme la sélection de règle T011).
- **US5 (P5)** → après US1 + US2 (garde de devise sur écriture et évaluation).
- **US3 (P6)** → après US1 + US2 (le simulateur rejoue le cœur d'évaluation).
- **US4 (P7)** → après US1 + US2 (vérifie les montants via l'évaluation).
- **US6 (P8)** → après US2 (effort greffé sur le pipeline + tronçons de la matrice).
- **Polish (P9)** → après toutes les stories visées.

### Au sein d'une story

Migration/knobs → dépôt/logique → endpoints (utoipa+clients+build) → tests. Modèles avant services, services avant endpoints.

### Opportunités parallèles ([P])

- Foundational : T004, T005, T006 en parallèle (fichiers différents) après T003.
- T017 (optimisation) en parallèle des tâches `routage.rs` (T014–T016) — fichier différent.
- Tests de story : T013, T020, T022, T026, T028, T031 — chacun isolé, parallélisable en fin de sa story.
- Polish : T032 en parallèle.

---

## Implementation Strategy

### MVP d'abord (moteur = US1 + US2)

1. Phase 1 Setup → Phase 2 Foundational.
2. US1 (catalogue + bornes) → **valider seul** (règle acceptée/refusée, sélection déterministe).
3. US2 (devis routé figé) → **valider seul** (waypoints, cache, dégradé, drapeaux, VND-08). **À ce stade le moteur price une livraison** — cœur de valeur.

### Livraison incrémentale

US5 (intégrité devise) → US3 (simulateur + garde de publication) → US4 (seed Tiassalé) → US6 (grille d'effort + optimisation exposée). Chaque story ajoute de la valeur sans casser les précédentes.

---

## Notes

- `[P]` = fichiers différents, aucune dépendance sur une tâche inachevée.
- Aucune tâche n'édite `clients/dart` ou `clients/ts` (régénération seule).
- **Aucune app Flutter ni page Nuxt** ce cycle : backend + API admin uniquement ; les traits `EvaluationTarifaire`/`OptimisationArrets` sont la capacité exposée à CMD/DSP/CRS, exercée par des courses simulées dans les tests (patron cycle 006).
- Commit conventionnel par tâche/groupe, référençant la story (ex. `feat(tarification): TRF-02 …`).
