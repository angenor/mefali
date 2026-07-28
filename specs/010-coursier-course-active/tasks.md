---

description: "Tâches — app coursier : course active, cash et hors-ligne (cycle CRS 010)"
---

# Tasks: App coursier — course active multi-arrêts, cash et hors-ligne

**Input**: Design documents from `/specs/010-coursier-course-active/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/](./contracts/), [quickstart.md](./quickstart.md)

**Tests**: non optionnels. La spec exige nommément un test de réconciliation (FR-089, SC-004), la constitution VII impose un test d'intégration par transition, et les 7 combinaisons de preuves manquantes (SC-007) ne se vérifient pas à la main. Les tests unitaires accompagnent les modules purs (calcul de présence, consolidation des essais, vérification d'empreinte côté app).

**Organization**: une phase par user story, dans l'ordre de dépendance interne (US1 → US7). Les 7 stories produit sont **toutes P0** ; les priorités P1→P7 des phases sont l'ordre de **livraison**, pas une hiérarchie produit.

**Calibrage**: chaque tâche vise une **demi-journée à une journée**. Une tâche qui déborde se scinde plutôt que de s'étirer.

**Révision du 2026-07-28** (après `/speckit-analyze`) : 90 tâches au lieu de 87 — 3 ajoutées (proposition de remplacement, arrêt entier indisponible, lecture admin des preuves), 1 déplacée d'US3 vers US1 (bandeau hors-ligne, exigé par K3-1b dès le MVP), et 8 amendées. Le doublon de paramètre `coursier.essais_code_remise` est supprimé : le seuil existant `commande.essais_code_livraison` est réutilisé.

## Format: `[ID] [P?] [Story] Description`

- **[P]** : parallélisable (fichiers différents, aucune dépendance sur une tâche incomplète)
- **[Story]** : US1..US7 — uniquement dans les phases de story
- Chemins de fichiers exacts dans chaque description

## Path Conventions

- **Backend Rust** : `backend/crates/coursier/` (cœur), `backend/crates/commandes/`, `backend/crates/qr/`, binaire `backend/api/`, migrations `backend/migrations/`, seeds `backend/seeds/`
- **Apps Flutter** : `apps/mefali_pro/`, partagé `apps/packages/mefali_core/`
- **Clients générés** : `clients/dart/`, `clients/ts/` — **jamais** d'édition manuelle, régénération uniquement
- **Non touchés** : `web/`, `apps/mefali_client/`, `infra/`

## Règles opposables à chaque tâche

Quatre règles issues de la demande de découpe, plus celles de la constitution. Une
tâche qui les enfreint est incomplète, même si son code marche :

1. **Toute tâche qui touche l'API se termine par** : annotations `#[utoipa::path]`
   à jour → `./scripts/generate-clients.sh` → `git diff --exit-code clients/` vide
   → `cargo build` vert. Les tâches concernées le rappellent en clair.
2. **Toute tâche qui touche le schéma commence par sa migration sqlx** — une
   **nouvelle** migration, jamais la retouche d'une migration appliquée — et se
   termine par `cargo sqlx prepare`. Tout le schéma du cycle est planifié en T002
   et T003 ; une tâche ultérieure qui découvre un besoin de colonne **crée une
   migration `0017_…`**, elle ne retouche jamais les deux précédentes.
3. **Toute tâche d'UI référence sa capture** `docs/design/png/` et consomme les
   valeurs de `docs/design/tokens.md` — jamais la structure DOM/CSS de
   `docs/design/html/`.
4. Toute transition d'état → événement outbox dans la **même transaction** +
   déclaration dans `docs/taxonomie-evenements.md` **avant** implémentation + test
   d'intégration de la transition. Toute chaîne utilisateur → clé i18n fr. Tout
   paramètre « paramétrable » → configuration de zone héritée, **et jamais un
   doublon d'un paramètre existant**.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: déclarer les événements avant d'en émettre un seul, poser tout le schéma du cycle, rendre le crate vide constructible, et stabiliser les plugins natifs **une bonne fois** (Shorebird ne les patchera pas).

- [X] T001 Déclarer les **7 nouveaux événements** dans `docs/taxonomie-evenements.md` (`preuves_echec.reunies`, `caisse.mouvement`, `indemnisation.validee`, `indemnisation.refusee`, `remise.code_debloque`, `depot.autorise`, `coursier.action_reconciliee`), avec leurs charges utiles de `contracts/ports-coursier.md` §3, et noter que `appel.intention` gagne son premier émetteur `de: coursier` et que `remise.code_epuise` gagne enfin un consommateur — **aucun secret ni numéro dans une charge utile**
- [X] T002 Migration `backend/migrations/0015_coursier.sql` : schéma `coursier`, **4 énumérations** (`type_ecriture`, `etat_indemnisation`, `motif_appel`, `issue_appel`) et 5 tables (`ecriture_caisse`, `indemnisation`, `appel_coursier` **avec sa colonne `issue`**, `releve_presence`, `preuve_photo`) avec leurs index et contraintes de `data-model.md` §1 ; `cargo sqlx migrate run`
- [X] T003 Migration `backend/migrations/0016_commandes_remise_depot.sql` : colonnes de dépôt autorisé, de blocage/levée du code, `livraison.remise_uuid_client`, `livraison.remise_hors_ligne`, `issue_echec.issue_uuid_client`, contrainte `depot_trace_complete`, **et le `COMMENT ON COLUMN` qui corrige le commentaire trompeur de `0004` sur `prestataire.contact_telephone`** (`data-model.md` §2) ; `cargo sqlx migrate run`
- [ ] T004 [P] Seed `backend/seeds/80_coursier_parametres.sql` : les **7 paramètres de zone** de `research.md` R17 au niveau pays, rejouable (`ON CONFLICT DO UPDATE`), aucun événement émis. ⚠ **Ne PAS créer de clé d'essais du code** : `commande.essais_code_livraison` = 3 existe depuis le cycle 008 et est lu en production ; documenter en tête de fichier pourquoi les **trois** rétentions de photo (`qr.`, `substitution.`, `coursier.`) sont distinctes et non redondantes
- [ ] T005 Rendre le crate constructible : `backend/crates/coursier/Cargo.toml` (dépendances `commandes`, `qr`, `prestataires`, `socle`, sqlx), `src/lib.rs` (table des modules), `src/modele.rs` (types du domaine + `ErreurCoursier` et ses **clés i18n**), `src/config.rs` (chargement des 7 paramètres du cycle **et lecture du seuil d'essais existant**, avec leurs gardes) ; `cargo sqlx prepare` et `cargo build` verts
- [ ] T006 [P] Bac de test `backend/api/tests/bac_coursier/mod.rs` sur le patron de `bac_commandes/mod.rs` : app Actix réelle, zone Tiassalé, paramètres du cycle, 3 vendeurs, un coursier avec rôle valide, helpers « course assignée à 3 arrêts » et « avancer le temps »
- [ ] T007 [P] Ajouter les **deux plugins natifs** à `apps/mefali_pro/pubspec.yaml` (service de premier plan + notifications locales), déclarer permissions et service dans `apps/mefali_pro/android/app/src/main/AndroidManifest.xml`, figer les versions, puis `./scripts/verifier-accord-locks.sh` vert dans les trois paquets (`research.md` R12)
- [ ] T008 [P] Étendre la base locale dans `apps/packages/mefali_core/lib/src/offline/action_en_attente.dart` : 4 tables (`course_cache`, `lignes_checklist`, `essais_remise`, `releves_presence_locaux`), `schemaVersion` + 1 et **migration additive** (aucune action en vol perdue) ; `build_runner` puis `dart analyze`
- [ ] T009 [P] Poser les clés i18n fr des 5 écrans dans `apps/mefali_pro/lib/l10n/app_localizations_fr.dart` et `apps/packages/mefali_core/lib/l10n/mefali_core_localizations_fr.dart` (aucune chaîne en dur ne sera écrite ensuite)

**Checkpoint**: schéma en place, événements déclarés, crate qui compile, appareil prêt — aucune logique encore.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: le pré-provisionnement complet. Toutes les stories en dépendent : sans lui, ni checklist, ni remise hors ligne, ni preuves.

**⚠️ CRITIQUE** : aucune story ne démarre avant la fin de cette phase.

- [ ] T010 Port `CourseCoursier` (+ double `CourseFixe`) dans `backend/crates/commandes/src/ports.rs` : `course_active`, `montant_a_encaisser`, `livrees_du_jour` — signatures de `contracts/ports-coursier.md` §2 ; tests unitaires du double
- [ ] T011 Implémenter `CourseCoursier` pour `PgCommandes` dans `backend/crates/commandes/src/suivi.rs` : **une seule requête** rendant arrêts + `ligne_commande` groupées par arrêt + client (repère texte, clé vocale, position, téléphone) + `code_livraison_hash` / `jeton_reception_hash` + `essais_code` + `depot_autorise` ; `cargo sqlx prepare`
- [ ] T012 `backend/crates/coursier/src/course.rs` + `src/depot.rs` : `PgCoursier` compose `CourseCoursier` (commandes), `qr::pre_provisionnement` (empreintes de plaque, politique photo) et `prestataires` (**téléphone du vendeur — élargissement documenté : servi au coursier ASSIGNÉ, jamais à une consultation non authentifiée, SC-013 du cycle 005 intact**) en une `CourseComplete` ; tests unitaires de composition avec doubles
- [ ] T013 Endpoint `GET /courses/active` dans `backend/api/src/coursier_http.rs` (nouveau module) rendant la structure de `data-model.md` §3 ; **retirer** le handler de `backend/api/src/qr_http.rs` ; garde de rôle **et** de propriété ; note vocale servie en **URL présignée** — puis annotations `#[utoipa::path]` à jour, `./scripts/generate-clients.sh`, `git diff --exit-code clients/` vide, `cargo build` vert
- [ ] T014 Câbler `PgCoursier` dans `backend/api/src/lib.rs` (après `PgQr`, avant le dispatch), enregistrer `coursier_http` dans les deux points de montage de routes ; `PreuvesFixes` **reste** câblé jusqu'à T058
- [ ] T015 Test d'intégration `backend/api/tests/coursier_course_active.rs` : structure complète servie, `204` sans course, `403` pour un autre coursier, **aucun secret** dans la réponse (assertion explicite sur `code_livraison` et `jeton_reception`), lignes correctement groupées par arrêt
- [ ] T016 Adapter `apps/mefali_pro/lib/coursier/course/etat_course.dart` au nouveau contrat : `ArretCourse` gagne ses lignes, `EtatCourse` gagne `client` et `remise`, écriture dans `course_cache` et `lignes_checklist`, préservation des coches optimistes existantes ; `build_runner` + `dart analyze`
- [ ] T017 [P] Non-régression de l'existant : mettre à jour `apps/mefali_pro/test/coursier/course/` (scan, coche optimiste, drain de file) pour le nouveau contrat — les tests du cycle 006 doivent rester verts
- [ ] T018 [P] Effacement du cache local (dont **les deux numéros de téléphone**) à la clôture de la course dans `apps/packages/mefali_core/lib/src/offline/file_actions.dart` + test de la base locale (`research.md` R6)

**Checkpoint**: l'app détient toute la course dès l'assignation, hors ligne comprise. Les stories peuvent démarrer.

---

## Phase 3: User Story 1 — La checklist qui dit quoi acheter et combien avancer (Priority: P1 — produit P0) 🎯 MVP

**Goal**: K3 tel que la maquette le dessine — un arrêt développé, ses articles cochables, le montant exact à payer à CE vendeur, et la bascule automatique à l'arrêt suivant.

**Independent Test**: assigner une course de 3 vendeurs, dérouler les 3 arrêts en cochant, déclarer un article indisponible (le montant baisse du bon montant, la préférence s'applique), scanner, puis vérifier la bascule « en route vers le client » avec note vocale jouable et montant à encaisser.

- [ ] T019 [US1] Widget `CarteArretCourant` dans `apps/mefali_pro/lib/coursier/course/carte_arret.dart` : entête « Arrêt N / total », nom, distance, boutons Itinéraire et Appeler — réf. `docs/design/png/K3-course-active.png` état 1a, valeurs de `docs/design/tokens.md`
- [ ] T020 [P] [US1] Widget `ChecklistArticles` dans `apps/mefali_pro/lib/coursier/course/checklist_articles.dart` : une ligne par article (libellé, quantité, prix), coche 48 dp, bouton « Indisponible », ligne barrée en rouge avec sa raison — réf. `K3-course-active.png` 1a
- [ ] T021 [US1] Persistance des coches dans `lignes_checklist` (drift) — **jamais envoyées au serveur** (`research.md` R11, FR-079) — et recalcul du **montant à payer à cet arrêt** à chaque changement de disponibilité, dans `apps/mefali_pro/lib/coursier/course/etat_course.dart` ; test unitaire du recalcul (FR-013, SC-002)
- [ ] T022 [US1] Brancher l'indisponibilité d'une **ligne** sur `POST /courses/{livraison_id}/substitutions` (chemin existant) avec application visible de la préférence — « retirer » recalcule, « m'appeler » met l'appel en action principale (`K3-course-active.png` 1a, bouton rouge) ; aucune modification serveur
- [ ] T023 [US1] **Proposition de remplacement** (préférence « remplacer », FR-017) dans `apps/mefali_pro/lib/coursier/course/feuille_remplacement.dart` : prise de photo, saisie du prix, envoi en multipart sur le chemin de substitution existant, affichage de la **fenêtre de décision restante** du client et de l'issue (acceptée / refusée / expirée) — réf. `K3-course-active.png` 1a
- [ ] T024 [US1] **Arrêt entier indisponible** (FR-018) dans `apps/mefali_pro/lib/coursier/course/feuille_arret_indisponible.dart` : motifs prédéfinis en clés i18n (vendeur fermé, plus rien en stock), branchement sur `POST /courses/{livraison_id}/arrets/{arret_id}/indisponible` (chemin existant), montant de l'arrêt ramené à zéro et passage à l'arrêt suivant — réf. `K3-course-active.png` 1a
- [ ] T025 [US1] Transitions **un tap** « je pars » / « je suis arrivé » branchées sur les endpoints existants, avec `uuid_client` et passage par la file, dans `apps/mefali_pro/lib/coursier/course/ecran_course_active.dart`
- [ ] T026 [US1] Repli automatique de l'arrêt collecté (avec son heure) et développement du suivant, sans action supplémentaire — réf. `K3-course-active.png` 1b (arrêt 1 replié « ✓ Collecté 14:32 »)
- [ ] T027 [US1] **Bandeau hors-ligne** dans l'entête de course (FR-026) : « Actions enregistrées, synchronisation auto », et grisage motivé des seules actions qui exigent le réseau (itinéraire, appel) tandis que scan et coches restent **visiblement actifs** — réf. `K3-course-active.png` 1b
- [ ] T028 [US1] Écran « en route vers le client » dans `apps/mefali_pro/lib/coursier/course/bandeau_livraison.dart` : bandeau vert, récapitulatif des arrêts avec leurs heures, repère du client (texte **et** vocal), distance, **montant total à encaisser**, action « Je suis arrivé chez le client » — réf. `K3-course-active.png` 1c
- [ ] T029 [US1] Lecture **hors ligne** de la note vocale de repère : téléchargement du fichier à l'assignation, stockage local, `LecteurNoteVocale` de `mefali_core` branché — réf. `K3-course-active.png` 1c (bloc orange) ; test SC-012
- [ ] T030 [US1] Endpoint `POST /courses/{livraison_id}/appels` (+ `PATCH` de l'**issue déclarée**) dans `backend/api/src/coursier_http.rs` et `backend/crates/coursier/src/appels.rs` : idempotent par `uuid_client`, motif et issue de `research.md` R19, émet `appel.intention` avec `de: coursier`, **aucun numéro** ; puis utoipa à jour, clients régénérés sans diff, `cargo build` vert
- [ ] T031 [US1] Appels depuis l'app (client et vendeur) : composition du numéro **sans l'afficher**, déclaration de l'issue au retour d'appel, journalisation enfilée hors ligne, mention explicite « seuls les appels via l'app comptent » ; tests widget des états grisés hors ligne (FR-019, FR-034, FR-036)
- [ ] T032 [US1] Tests d'intégration `backend/api/tests/coursier_appels.rs` (idempotence, motifs, issue déclarée puis modifiée, absence de numéro dans l'événement) + tests widget K3 dans `apps/mefali_pro/test/coursier/course/` (arrêt courant seul développé, montant révisé, remplacement, arrêt indisponible, bascule)

**Checkpoint**: US1 complète et démontrable seule — Yao fait ses trois arrêts, y compris quand un article ou un vendeur manque. SC-001 et SC-002 vérifiables.

---

## Phase 4: User Story 2 — Confirmer la livraison, même sans réseau (Priority: P2 — produit P0)

**Goal**: K4 — trois voies hiérarchisées, validation locale par empreinte, blocage à 3 essais, alerte d'exploitation.

**Independent Test**: mener une course jusqu'à l'arrivée, couper le réseau, confirmer par QR puis (autre course) par code ; vérifier l'acceptation locale, la clôture à l'écran, puis la clôture réelle au retour du réseau. Trois codes faux → blocage + alerte.

- [ ] T033 [US2] `backend/crates/commandes/src/collecte.rs` : rendre `valider_remise` **idempotente** par `remise_uuid_client`, accepter `essais_hors_ligne` et retenir `max(serveur, local)` contre le seuil **existant** `commande.essais_code_livraison`, journaliser `remise_hors_ligne` (`research.md` R4/R5) ; `cargo sqlx prepare`
- [ ] T034 [US2] Refuser en `422` toute remise en mode `depot` sur une commande dont `depot_autorise` est faux, dans `backend/crates/commandes/src/collecte.rs` (garde serveur de FR-048)
- [ ] T035 [US2] Faire passer `POST /courses/{livraison_id}/remise` en **`multipart/form-data`** dans `backend/api/src/course_http.rs` (partie `demande` JSON + partie `photo` binaire + `depot_lat`/`depot_lon`), sur le patron de la collecte 006 et de la rupture 008, avec son schéma OpenAPI dédié — **c'est ce qui rend la voie dépôt utilisable hors ligne** (`research.md` R18, FR-048b) ; puis utoipa à jour, clients régénérés sans diff, `cargo build` vert
- [ ] T036 [US2] Endpoints d'exploitation du blocage dans `backend/api/src/admin_coursier_http.rs` (nouveau) : `GET /admin/remises/bloquees` et `POST /admin/commandes/{id}/code/debloquer` (motif obligatoire, émet `remise.code_debloque`) ; utoipa + clients + build vert
- [ ] T037 [US2] Endpoint `POST /admin/commandes/{id}/depot` (ouverture/fermeture tracée, émet `depot.autorise`) dans `backend/api/src/admin_coursier_http.rs` ; utoipa + clients + build vert
- [ ] T038 [P] [US2] Vérificateur d'empreintes **local** dans `apps/mefali_pro/lib/coursier/remise/verificateur_empreinte.dart` : comparaison sha256 salée sans le moindre appel réseau ; tests unitaires (bon code, mauvais code, jeton d'une autre commande)
- [ ] T039 [US2] Écran de confirmation dans `apps/mefali_pro/lib/coursier/remise/ecran_confirmation.dart` : **nom d'usage du client, repère et heure d'arrivée** (FR-052), montant à encaisser en display, rappel « jamais de paiement partiel », **scan QR en action principale**, code en secondaire, dépôt en lien discret **affiché seulement si ouvert** — réf. `docs/design/png/K4-confirmation-livraison.png` 1a
- [ ] T040 [US2] Pavé de saisie du code dans `apps/mefali_pro/lib/coursier/remise/pave_code.dart` : 4 cases, clavier 64 dp, message « code faux — il reste N essais » — réf. `K4-confirmation-livraison.png` 1b
- [ ] T041 [US2] Porteur d'état `EtatRemise` (`Notifier`, `keepAlive` pendant la course, `retry: pasDeRetry`) dans `apps/mefali_pro/lib/coursier/remise/etat_remise.dart` : voie choisie, essais consommés (persistés dans `essais_remise`), blocage ; `build_runner` + `dart analyze`
- [ ] T042 [US2] Voie **dépôt** côté app : photo + position capturées et **enfilées avec la demande** (jamais d'upload préalable), bandeau « validation locale — sera synchronisée », grisage motivé des options réseau (le lien de paiement n'est **pas construit** — renvoi au chemin de secours, FR-050) — réf. `K4-confirmation-livraison.png` 1a et 1c
- [ ] T043 [US2] Écran de blocage : « 3 codes faux — saisie bloquée », motif en langage clair, **numéro de l'agence en action principale**, scan QR toujours proposé — réf. `K4-confirmation-livraison.png` 1d
- [ ] T044 [US2] Tests d'intégration `backend/api/tests/coursier_remise_hors_ligne.rs` : les 3 voies (dont **dépôt avec photo en multipart**), idempotence du rejeu, consolidation `max()` des essais, blocage à 3, `423`, levée admin, dépôt refusé si fermé (SC-005, SC-006) + tests widget des 4 états de K4

**Checkpoint**: US2 complète — la course se clôt sans réseau par les **trois** voies, et le serveur reste juge.

---

## Phase 5: User Story 3 — Rien ne se perd, rien ne double (Priority: P3 — produit P0)

**Goal**: la file couvre **toutes** les actions de course, se rejoue dans l'ordre, et donne raison au serveur en le disant clairement.

**Independent Test**: le test obligatoire du module — réseau coupé entre le dernier scan et la confirmation, puis rétabli : exactement une collecte, exactement une remise, aucun doublon même en rejouant deux fois.

- [ ] T045 [US3] Étendre la file de `apps/packages/mefali_core/lib/src/offline/file_actions.dart` aux actions du cycle (transitions, appels, relevés de présence, **photos de récupération, de remplacement, de dépôt et de preuve**, remise, échec) avec ordre de création strict et compteur de tentatives (FR-087)
- [ ] T046 [US3] Classement des issues de rejeu dans `apps/mefali_pro/lib/coursier/course/etat_course.dart` : **réessayable** (réseau) vs **refus définitif** (métier) — le second sort de la file après réconciliation affichée (FR-085)
- [ ] T047 [US3] Messages de réconciliation en clés i18n (« cette course ne vous est plus attribuée », « cet arrêt est déjà collecté ») + trace consultable des refus définitifs dans `apps/mefali_pro/lib/coursier/course/journal_reconciliation.dart` (FR-084, FR-086)
- [ ] T048 [US3] Indicateur d'actions en attente (nombre + octets de photos restants) dans le bandeau posé en T027 — réf. `docs/design/png/K3-course-active.png` 1b (FR-083)
- [ ] T049 [US3] Contrôle de **propriété au rejeu** côté serveur pour toutes les actions de course (`backend/crates/commandes/` et `backend/crates/coursier/`) : une action d'un coursier désassigné est refusée et tracée, émission de `coursier.action_reconciliee` (FR-006, FR-088, dette du cycle 008)
- [ ] T050 [US3] Rendre `POST /courses/{livraison_id}/echec` idempotent par `issue_uuid_client` dans `backend/crates/commandes/src/echec.rs` + adapter le DTO dans `backend/api/src/course_http.rs` ; utoipa + clients + build vert
- [ ] T051 [US3] ⭐ Tests d'intégration `backend/api/tests/coursier_reconciliation.rs` — le scénario exact de `quickstart.md` §2.1 (coupure entre le dernier scan et la remise, rejeu, cardinalité 1/1/1, **second rejeu sans effet**) **et** la course réassignée pendant la coupure (actions refusées, tracées, avance engagée ouvrant le litige) — FR-089, SC-004, SC-016

**Checkpoint**: US3 complète — le test qui fait foi passe, deux fois de suite.

---

## Phase 6: User Story 4 — Prouver qu'on a vraiment essayé (Priority: P4 — produit P0)

**Goal**: les trois preuves, mesurées par l'app et **revérifiées par le serveur** ; `PreuvesFixes` quitte la production.

**Independent Test**: arriver chez un client absent, constater le bouton inactif, réunir les preuves une à une, vérifier que le bouton s'active exactement à la troisième, déclarer, et retrouver les preuves attachées.

- [ ] T052 [US4] `backend/crates/coursier/src/presence.rs` : enregistrement des relevés (distance arrondie, jamais de coordonnées) et **calcul de la durée** avec la règle du « trou » de zone ; tests unitaires (présence continue, aller-retour, trou de 5 min, position absente)
- [ ] T053 [US4] Endpoint `POST /courses/{livraison_id}/presence` (lot, idempotent par `uuid_client`) dans `backend/api/src/coursier_http.rs` ; utoipa + clients + build vert
- [ ] T054 [US4] Endpoint `POST /courses/{livraison_id}/preuves/photo` (multipart, dépôt Garage, clé en base) dans `backend/api/src/coursier_http.rs` + `backend/crates/coursier/src/preuves.rs` ; utoipa + clients + build vert
- [ ] T055 [US4] `backend/crates/coursier/src/preuves.rs` : agrégation des trois preuves (appels `client_absent` avec espacement, présence, photos) selon les paramètres de zone, et émission de `preuves_echec.reunies` au basculement
- [ ] T056 [US4] Endpoint `GET /courses/{livraison_id}/preuves` (coursier) rendant l'état détaillé et **ce qui manque** (`contracts/coursier-openapi.md` §1.4) ; utoipa + clients + build vert
- [ ] T057 [US4] Endpoint d'exploitation `GET /admin/livraisons/{id}/preuves` dans `backend/api/src/admin_coursier_http.rs` : appels avec leurs heures et leur issue, présence mesurée, URL présignées des photos — c'est ce qui rend les preuves **lisibles par l'exploitation** (FR-063) ; utoipa + clients + build vert
- [ ] T058 [US4] Implémenter `commandes::PreuvesEchec` pour `PgCoursier` et **remplacer `PreuvesFixes` dans la composition de production** (`backend/api/src/lib.rs`) — la même fonction garde l'écran et l'endpoint (FR-059/FR-060)
- [ ] T059 [US4] Écran des preuves dans `apps/mefali_pro/lib/coursier/preuves/ecran_preuves.dart` : trois lignes avec leur état (faite + horodatages + issue déclarée / en cours + décompte / à faire), compteur « N sur 3 », bouton **grisé**, action « Rappeler le client » — réf. `docs/design/png/K4-confirmation-livraison.png` 1e
- [ ] T060 [US4] Porteur `EtatPreuves` (`Notifier`, `keepAlive` pendant la course) dans `apps/mefali_pro/lib/coursier/preuves/etat_preuves.dart` : échantillonnage de présence, motifs de non-progression (GPS absent, appels trop rapprochés), file hors ligne ; minuteries d'affichage **locales au widget** (constitution XII, piège du cycle 004)
- [ ] T061 [US4] Tests d'intégration `backend/api/tests/coursier_preuves.rs` : les **7 combinaisons** de preuves manquantes refusées, espacement < 3 min refusé, trou de présence, refus serveur d'une déclaration hors app, lecture admin complète (SC-007, SC-008) + tests widget d'activation du bouton
- [ ] T062 [US4] Job de purge des photos de preuve (rétention de zone) dans `backend/api/src/lib.rs`, patron `job_purge_photos_collecte` du cycle 006 + test

**Checkpoint**: US4 complète — un échec ne se déclare plus jamais sans preuves, en test comme en production.

---

## Phase 7: User Story 5 — La caisse (Priority: P5 — produit P0)

**Goal**: K5 — avances en cours exactes, historique du jour, indemnisations rattachées à leur litige, exposition temps réel pour l'exploitation.

**Independent Test**: deux courses cash (une livrée, une en cours) + un échec indemnisable : la caisse affiche l'avance exacte, l'historique à trois chiffres, l'indemnisation « demandée » puis « validée », et l'exposition admin égale la somme des avances.

- [ ] T063 [US5] `backend/crates/coursier/src/caisse.rs` : écritures **append-only**, solde d'avances ouvertes, historique du jour, **et signalement d'incident quand les avances en cours dépassent le plafond du jour** (FR-078) ; refus d'`UPDATE`/`DELETE` (correction = écriture inverse) ; tests unitaires
- [ ] T064 [US5] Traduction événement → écriture dans `backend/crates/coursier/src/caisse.rs` (**la logique reste dans le crate**), et **adaptateur** `CaisseOutbox : socle::ConsommateurOutbox` dans `backend/api/src/lib.rs` (second consommateur réel, patron `DispatchOutbox`) : `arret.collecte` → avance, `livraison.livree` → remboursement **si cash uniquement**, `indemnisation.due` → indemnisation « demandée » ; idempotence par `evenement_id`
- [ ] T065 [US5] Marquage `en_attente_reglement` des avances de commandes **prépayées** (aucun remboursement écrit — `research.md` R10, FR-117) + test qui prouve que le solde ne ment pas
- [ ] T066 [US5] `backend/crates/coursier/src/indemnisation.rs` : états `demandee` → `validee` / `refusee`, écriture de caisse à la validation, événements `indemnisation.validee` / `indemnisation.refusee` dans la même transaction
- [ ] T067 [US5] Port `LitigesOuverts` + double `AucunLitige` dans `backend/crates/coursier/src/ports.rs` (AVI-04 non construit) et rattachement d'un `litige_id` nullable
- [ ] T068 [US5] Endpoint `GET /moi/caisse` dans `backend/api/src/coursier_http.rs` ; utoipa + clients + build vert
- [ ] T069 [US5] Endpoints d'exploitation dans `backend/api/src/admin_coursier_http.rs` : `GET /admin/coursiers/exposition`, `GET /admin/indemnisations`, `POST /admin/indemnisations/{id}/valider`, `POST /admin/indemnisations/{id}/refuser` (motif obligatoire) ; utoipa + clients + build vert
- [ ] T070 [US5] Écran caisse dans `apps/mefali_pro/lib/coursier/caisse/ecran_caisse.dart` : solde avancé en display danger, historique du jour à trois chiffres, indemnisations avec leurs chips d'état — réf. `docs/design/png/K5-caisse-historique.png` 1a
- [ ] T071 [US5] États vide et litige : « Aucune course aujourd'hui » avec action « Passer en ligne », et carte de litige en cours avec engagement de rappel — réf. `K5-caisse-historique.png` 1b et 1c (la carte « Signaler ou bloquer » de 1a et la feuille 1d **ne sont pas construites**, CRS-07)
- [ ] T072 [US5] Porteur `EtatCaisse` (`AsyncNotifier`) + lecture **hors ligne** du dernier état connu, annoncé comme tel (FR-076) ; `build_runner` + `dart analyze`
- [ ] T073 [US5] Tests d'intégration `backend/api/tests/coursier_caisse.rs` (avance → remboursement → solde 0, prépayée → avance ouverte, immuabilité, **incident d'écart au plafond**) et `backend/api/tests/admin_coursier.rs` (exposition = somme, validation, refus motivé) — SC-009, SC-010, SC-011

**Checkpoint**: US5 complète — « le coursier ne perd jamais » devient vérifiable par Yao lui-même.

---

## Phase 8: User Story 6 — Voir ce qu'on a gagné aujourd'hui (Priority: P6 — produit P0)

**Goal**: le bandeau de gains de K1, le reste de plafond, et la navigation basse.

**Independent Test**: livrer trois courses, vérifier le nombre et la somme exacte des parts coursier ; engager une avance et voir « reste disponible » diminuer d'autant ; naviguer entre les trois destinations.

- [ ] T074 [US6] Endpoint `GET /moi/journee` dans `backend/api/src/coursier_http.rs`, **composé dans le handler** à partir de `coursier` (courses livrées, gains, avances) et `dispatch` (plafond retenu, taux d'acceptation) — aucune arête entre les deux crates (`contracts/ports-coursier.md` §2) ; utoipa + clients + build vert
- [ ] T075 [US6] Bandeau de gains et reste de plafond dans `apps/mefali_pro/lib/coursier/disponibilite/ecran_disponibilite.dart` : « N courses livrées », somme, « Reste disponible », taux d'acceptation, **note absente** tant qu'AVI n'existe pas — réf. `docs/design/png/K1-disponibilite.png` 1a et 1b (l'état 1c « paie fixe » **n'est pas construit**, hors produit)
- [ ] T076 [US6] Raccourci « Caisse » depuis le tableau de bord + `NavigationBar` Material 3 à trois destinations dans `apps/mefali_pro/lib/coursier/interface_coursier.dart`, **sous** la règle de priorité du cycle 009 (offre en vol et course active gardent l'écran) — réf. `K1-disponibilite.png` et `K5-caisse-historique.png` (barre basse)
- [ ] T077 [US6] Bornage au **jour civil de la zone** (gains remis à zéro, plafond d'une course déjà acceptée inchangé) dans `backend/crates/coursier/src/caisse.rs` + test de bascule de jour (FR-092, FR-097, SC-013)

**Checkpoint**: US6 complète — K1 montre enfin ce que Yao gagne.

---

## Phase 9: User Story 7 — Être réveillé par une offre (Priority: P7 — produit P0)

**Goal**: l'app reste vivante écran éteint tant que Yao est en ligne, et une offre le réveille.

**Independent Test**: en ligne, téléphone verrouillé 30 minutes → jamais sorti du pool ; une offre émise → sonnerie sur canal dédié, écran d'offre ouvert avec le temps réellement restant.

- [ ] T078 [US7] Service continu dans `apps/mefali_pro/lib/coursier/service_continu/service_continu.dart` : démarrage à la mise en ligne, arrêt à la mise hors ligne, publication de position à la période de zone, notification permanente explicite (FR-111, FR-112, FR-115)
- [ ] T079 [US7] Canal de notification dédié (haute importance, son prolongé, ouverture directe) dans `apps/mefali_pro/lib/coursier/service_continu/canal_offre.dart` — réf. `docs/design/png/K2-offre-course.png` (« Plein écran + sonnerie ») ; silence quand Yao est hors ligne ou déjà en course (FR-101, FR-102)
- [ ] T080 [US7] Interrogation d'offre **en arrière-plan** à la période de zone (`coursier.offre_interrogation_arriere_plan_s`), sans jamais doubler celle du premier plan (`research.md` R13) ; ouverture de K2 avec le **temps réellement restant** (FR-100)
- [ ] T081 [US7] Échantillonnage de la présence géolocalisée **écran éteint** branché sur le service (FR-114, SC-019)
- [ ] T082 [US7] Porteur `ServiceContinu` (`Notifier`, `keepAlive: true`) + gestion des refus de permission et des arrêts par le système, avec message explicite plutôt que silence (FR-115, cas limites de la spec) ; `build_runner` + `dart analyze`
- [ ] T083 [US7] Tests widget et unitaires du service dans `apps/mefali_pro/test/coursier/service_continu/` : démarrage/arrêt sur bascule de disponibilité, aucune sonnerie hors ligne ou en course, compte à rebours cohérent

**Checkpoint**: toutes les stories sont fonctionnelles indépendamment.

---

## Phase 10: Polish & Cross-Cutting Concerns

- [ ] T084 [P] Vérifier la **non-régression complète** : `cargo test` (cycles 006/007/008/009 compris), `flutter test` et `dart analyze` dans `mefali_pro` et `mefali_core`, `./scripts/verifier-accord-locks.sh`
- [ ] T085 [P] Contrôles transverses automatisés dans `backend/api/tests/coursier_transverses.rs` : (a) **aucun secret n'échappe** — balayage des charges utiles d'événements et des réponses d'API pour code, jeton, code vendeur et numéro (SC-015) ; (b) **aucune distance de routage n'est recalculée** par ce cycle (FR-009) ; (c) **l'horodatage serveur fait foi** sur tout ce qui fonde de l'argent — arrivée, présence, remise (FR-010)
- [ ] T086 Mesures de performance sur les cibles de `plan.md` : `GET /courses/active` ≤ 300 ms p95 (une requête), drain de file ≤ 5 s, exposition admin ≤ 5 s de retard
- [ ] T087 Validation **sur appareil** des six scénarios de `quickstart.md` §3 (course en plein soleil, note vocale hors ligne, hors-ligne complet, réveil écran éteint, preuves, caisse) — consigner les résultats
- [ ] T088 Rédiger `specs/010-coursier-course-active/rapport-ecarts.md` : écarts de maquette assumés (paie fixe K1-1c, lien mobile money K4-1a, signaler/bloquer K5-1a et 1d), limites déférées (avance non soldée sur commande prépayée), et décisions prises en cours d'implémentation
- [ ] T089 Mettre à jour `CLAUDE.md` (commandes du cycle : plugins natifs, service continu, nouveaux `--dart-define` éventuels) et le « Récapitulatif des paramètres de zone » de `docs/user-stories-v2.md` avec les 7 paramètres ajoutés
- [ ] T090 **Revue Definition of Done** (`docs/user-stories-v2.md` §0.4), point par point pour les 7 stories : (1) critères couverts par des tests, unitaires et d'intégration sur les transitions ; (2) annotations utoipa à jour et clients Dart/TS régénérés **sans diff manuel** ; (3) migrations versionnées et seeds à jour ; (4) événement outbox pour tout changement d'état **et** événements métriques de la taxonomie ; (5) clés i18n fr externalisées ; (6) paramètres « paramétrables » en configuration de zone, **sans doublon d'un paramètre existant** — toute case non cochée devient une tâche, jamais une note

---

## Dependencies & Execution Order

### Dépendances de phase

- **Phase 1 (Setup)** : aucune dépendance — démarrable immédiatement. T001 **avant** toute émission d'événement.
- **Phase 2 (Foundational)** : dépend de la Phase 1 — **bloque toutes les stories**. Sans le pré-provisionnement complet, ni checklist, ni remise hors ligne, ni preuves.
- **Phase 3 → 9 (Stories)** : toutes dépendent de la Phase 2. Ordre de livraison recommandé US1 → US7 (chaîne de valeur), mais US5 (caisse) et US7 (service continu) sont **techniquement indépendantes** d'US2/US3/US4.
- **Phase 10 (Polish)** : dépend de toutes les stories retenues.

### Dépendances entre stories

- **US1** : indépendante après la Phase 2 — c'est le MVP, bandeau hors-ligne compris (T027, exigé par K3-1b).
- **US2** : indépendante après la Phase 2 (mais démontrable seulement si US1 permet d'arriver chez le client).
- **US3** : s'appuie sur les actions produites par US1 et US2 pour être testable à pleine charge ; ses garanties (T049, T050) profitent rétroactivement aux deux. T048 complète le bandeau posé en T027.
- **US4** : consomme les appels d'US1 (T030) — seule dépendance inter-story réelle du cycle.
- **US5** : dépend de la Phase 2 seulement ; l'indemnisation vient de l'arbre d'échec déjà livré au cycle 008.
- **US6** : dépend d'US5 pour le « reste disponible » (avances en cours).
- **US7** : indépendante de toutes — elle peut être livrée en premier ou en dernier.

### Parallélisation

- Phase 1 : T004, T006, T007, T008, T009 en parallèle après T002/T003.
- Phase 2 : T017 et T018 en parallèle une fois T016 posé.
- Entre stories : US5 + US6 d'un côté, US7 de l'autre, pendant qu'US2 → US4 progresse.

```bash
# Exemple — après la Phase 2, trois chantiers indépendants :
Tâche: "T019-T032  US1 — checklist K3"
Tâche: "T063-T073  US5 — caisse K5"
Tâche: "T078-T083  US7 — service continu + sonnerie"
```

---

## Implementation Strategy

### MVP (US1 seule)

1. Phase 1 (Setup) → 2. Phase 2 (Foundational, **bloquante**) → 3. Phase 3 (US1)
4. **STOP et VALIDER** : `quickstart.md` §3.1 sur appareil — Yao fait ses trois arrêts avec la bonne somme chez chaque vendeur, y compris quand un article manque ou qu'un vendeur est fermé.

### Livraison incrémentale

1. Setup + Foundational → la course tient dans la poche, hors ligne comprise
2. + US1 → **MVP** : la checklist multi-arrêts (K3)
3. + US2 → la course se clôt sans réseau, par les trois voies (K4)
4. + US3 → plus rien ne se perd ni ne double (**le test qui fait foi**)
5. + US4 → un échec se prouve (K4-1e) ; `PreuvesFixes` quitte la production
6. + US5 → l'argent est visible (K5)
7. + US6 → les gains du jour (K1)
8. + US7 → le réveil, écran éteint

### Notes

- Une tâche qui déborde de la journée se **scinde** ; elle ne s'étire pas.
- Commit conventionnel par tâche ou groupe logique, référençant la story :
  `feat(coursier): CRS-03 checklist des articles par vendeur`.
- Aucun `.g.dart` ni client généré n'est édité à la main — régénération seulement.
- Se garder de la tentation du cycle 009 : un contrôle laissé rouge cesse d'être lu.
