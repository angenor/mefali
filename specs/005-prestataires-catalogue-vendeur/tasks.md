# Tasks: Prestataires agréés et catalogue vendeur

**Input**: Design documents from `/specs/005-prestataires-catalogue-vendeur/`

**Prerequisites**: plan.md, spec.md, research.md (R1–R17), data-model.md, contracts/prestataires-api.yaml, quickstart.md

**Tests**: constitution VII — chaque transition des DEUX machines à états (cycle de vie prestataire, statut de boutique) reçoit un test d'intégration OBLIGATOIRE (T015, T021, T029, T034, T038) ; tout changement SQL déclenche `cargo sqlx prepare`.

**Organization**: tâches groupées par user story (US1–US5 = priorités internes P1–P5 de la spec ; les quatre stories produit VND-01→04 sont toutes P0). Granularité : ½ journée à 1 journée maximum. Règles transverses appliquées : toute tâche d'API se TERMINE par « annotations utoipa à jour + `./scripts/generate-clients.sh` + build vert » ; le schéma du cycle COMMENCE par sa migration sqlx (T004) ; toute tâche d'UI référence sa capture `docs/design/png/` ; la liste se termine par la revue Definition of Done (T042).

## Format: `[ID] [P?] [Story] Description`

- **[P]** : parallélisable (fichiers différents, aucune dépendance sur une tâche inachevée)
- **[Story]** : US1..US5 (phases de stories uniquement)

## Path Conventions

Monorepo Mefali — chemins exacts dans plan.md « Project Structure » : crate `backend/crates/prestataires/`, binaire `backend/api/`, migrations `backend/migrations/`, seeds `backend/seeds/`, app `apps/mefali_pro/`, partagé `apps/packages/mefali_core/`, clients générés `clients/dart` + `clients/ts` (JAMAIS édités à la main — régénération seulement).

---

## Phase 1: Setup

**Purpose**: registre d'événements posé AVANT le code (FR-051), squelette du crate, port bouché.

- [X] T001 Déclarer dans `docs/taxonomie-evenements.md` les 18 types d'événements outbox du cycle (registre + tableau détaillé des payloads, data-model.md §6 — convention `<entite>.<action>`, minimisation FR-052) ET la nouvelle sous-section « Taxonomie produit (MET-01) — déclarations en attente d'ingestion » (6 événements produit V1/V2, research R16). AUCUNE implémentation avant cette tâche.
- [X] T002 Outiller le crate : `backend/crates/prestataires/Cargo.toml` (deps workspace : socle, zones, comptes, sqlx, utoipa, hmac, sha2, chrono, chrono-tz, uuid, serde, thiserror, async-trait), `src/lib.rs` (modules), `src/modele.rs` (enums `StatutPrestataire`/`StatutBoutique`/`SourceBascule`, `ErreurPrestataires` + `From<socle::OutboxError>`), variable `PLAQUE_SECRET` dans la config (`backend/crates/socle/src/config.rs` + `.env.example`, research R2). `cargo build` vert.
- [X] T003 Port `CommandesActives` dans `backend/crates/prestataires/src/ports.rs` : trait + bouchon de production `AucuneCommandeActive` (toujours `false`) + double de test `CommandesActivesFixes` paramétrable (research R5). Tests unitaires du double.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: schéma, reprise du port S3, clés de zone, composition racine — RIEN d'une story ne démarre avant.

**⚠️ CRITICAL**: le schéma COMMENCE par sa migration (T004). Toute évolution de schéma découverte plus tard = NOUVELLE migration `0005+` (jamais de modification de `0004` une fois appliquée).

- [X] T004 Migration sqlx `backend/migrations/0004_prestataires.sql` COMPLÈTE : schéma `prestataires`, 3 enums, 13 tables avec CHECKs (`prix_barre_strictement_superieur`, `plaque_complete`, cohérences pause/journée) et index (data-model.md §2–3) ; mettre à jour `backend/migrations/README.md`. Puis `cargo sqlx migrate run`, `cargo build -p api --bin api` (migrations EMBARQUÉES — piège du cycle 002) et `cargo sqlx prepare`.
- [X] T005 [P] Reprise R1 : créer `backend/crates/socle/src/objets.rs` (`DepotObjets`, `ErreurObjets`, `UrlPresignee`, `MemoireObjets` déplacés depuis comptes), ré-exporter depuis `backend/crates/comptes/src/ports.rs` (API publique inchangée), pointer `backend/api/src/infra_s3.rs` sur le trait socle. `cargo test` workspace vert — AUCUNE régression du cycle 003.
- [X] T006 [P] Clés de zone R8 : étendre le validateur `backend/crates/zones/src/parametre.rs` (`affichage_rupture` dans `categorie.<slug>.*` à valeurs énumérées ; namespaces `rupture.*`, `charte.*`, `zone.*` typés) ; poser les 5 clés seed dans `backend/seeds/10_zones_tiassale.sql` (masquage 2/7 j, affichage `grise` ×6, conservation charte 5 ans, fuseau `Africa/Abidjan`). Tests de validation + seed rejouable deux fois.
- [X] T007 Composition racine : `backend/crates/prestataires/src/depot.rs` (`PgPrestataires` = pool + `PgZones` + `PgComptes` + `Arc<dyn socle::DepotObjets>` + `Arc<dyn CommandesActives>` ; signatures des traits `Prestataires` et `Vendeurs`, research R14) ; montage dans `backend/api/src/lib.rs` (`app_data`, aux DEUX emplacements — `api_openapi()` ET la closure serveur) ; bac de test `backend/crates/prestataires/tests/bac/mod.rs` (patron `Bac` du cycle 003 : arbre CI→Tiassalé, ports mémoire, helpers `evenements`/`compter`).

**Checkpoint**: fondations prêtes — les stories peuvent démarrer.

---

## Phase 3: User Story 1 - Agréer un prestataire et lui donner son identité de plaque (Priority: P1) 🎯 MVP

**Goal**: un prestataire agréé (fiche + charte + site) devient consultable et commandable, reçoit sa plaque (jeton + code), alimente l'activation de catégorie ZON-03 ; rattachement de comptes optionnel.

**Independent Test**: agréer un prestataire de bout en bout SANS compte rattaché, puis vérifier par la consultation publique qu'il est commandable, que son jeton se résout, que l'activation de sa catégorie a été recalculée, et que chaque transition a laissé son événement (spec US1).

### Implementation for User Story 1

- [X] T008 [US1] Domaine fiche dans `backend/crates/prestataires/src/prestataire.rs` : créer (ville de type `ville` REFUSÉE sinon — FR-002, extension `vendeur` + plan `gratuit` posés), modifier ; photos de fiche et charte signée dans `src/prestataire.rs` via `socle::DepotObjets` (clés neuves `prestataires/fiches|chartes/…`, orphelines supprimées APRÈS commit — patron 003). Événements `prestataire.cree`, `prestataire.modifie` (champs seulement), `charte.deposee` dans la même transaction.
- [X] T009 [P] [US1] Domaine site dans `backend/crates/prestataires/src/site.rs` + `src/consultation.rs` : upsert du site UNIQUE (GPS, horaires multi-plages FR-031, statut initial), fonction PURE `etat_effectif` COMPLÈTE (ordre FR-032, échéances absorbées à la lecture, `reouverture_estimee`, fuseau de zone — research R3) et `commandable` (FR-028 : agréé ∧ catégorie active ∧ boutique ouverte). Tests unitaires purs de la matrice horaires × statut × échéances (sans base, horloge en paramètre).
- [X] T010 [US1] Domaine cycle de vie dans `src/prestataire.rs` + `src/plaque.rs` : table de transitions pure (`prospect→agree` seul chemin d'agrément — FR-004), `agreer` (refus motivés si fiche/charte/site incomplets — FR-005 ; génération jeton HMAC `PLAQUE_SECRET` + code 4 chiffres au PREMIER passage — research R2 ; recomptage + `PgZones::recalculer_activation` même transaction — research R7), résolution `resoudre_jeton` (validité DÉRIVÉE — FR-015/016). Événement `prestataire.agree`.
- [X] T011 [P] [US1] Domaine rattachement dans `backend/crates/prestataires/src/rattachement.rs` : rattacher IDEMPOTENT et REFUSÉ si le prestataire n'est pas agréé (FR-007 « à un prestataire agréé » — analyse A1 ; rôle vendeur attribué via `PgComptes::decider_role` SEULEMENT s'il n'est pas déjà `valide` — research R11), détacher (rôle JAMAIS touché — FR-008), `prestataires_pilotables`, garde de pilotage à trois refus (`role_vendeur_requis` / `prestataire_non_rattache` / `prestataire_non_agree`). Événements `rattachement.cree`/`rattachement.supprime`.
- [X] T012 [US1] HTTP admin fiche dans `backend/api/src/admin_prestataires_http.rs` : `POST/GET /admin/prestataires`, `GET/PUT /admin/prestataires/{id}` (détail complet : contact, GPS, chartes présignées, plaque — réservé admin), `POST …/photos` + `DELETE …/photos/{photo_id}` + `POST …/charte` (multipart, patron dossier coursier), `PUT …/site` ; montage aux DEUX emplacements de `api/src/lib.rs`. FINIR PAR : annotations utoipa à jour + `./scripts/generate-clients.sh` + build vert.
- [X] T013 [US1] HTTP décisions + pilotables : `POST /admin/prestataires/{id}/agrement` (422 à motif explicite, 409 transition interdite) et `POST/DELETE /admin/prestataires/{id}/rattachements[/{compte_id}]` dans `admin_prestataires_http.rs` ; `GET /vendeur/prestataires` (liste pilotable) dans `backend/api/src/vendeur_http.rs` (nouvelle garde). FINIR PAR : utoipa + régénération clients + build vert.
- [X] T014 [US1] HTTP consultation dans `backend/api/src/prestataires_http.rs` : `GET /prestataires/{id}` PUBLIC (sous-ensemble FR-027, 404 NEUTRE identique inconnu/prospect/suspendu — research R9, photos présignées TTL 10 min, catalogue encore vide à ce stade, rate-limit IP Governor patron `/config`) et `GET /prestataires/plaque/{jeton}` SOUS SESSION (extracteur `Auth`, aucun rôle particulier — analyse C1, FR-011 respecté ; `{prestataire_id, valide}`). FINIR PAR : utoipa + régénération clients + build vert.
- [X] T015 [US1] Tests d'intégration OBLIGATOIRES dans `backend/crates/prestataires/tests/agrement.rs` + tests HTTP dans `api` : refus d'agrément incomplet (motif), création avec une zone qui n'est pas une ville refusée (FR-002 — analyse G1), agrément complet SANS compte (SC-001), plaque résolue (session requise, 401 sans jeton de session), franchissement de seuil d'activation (SC-010), rattachement sur prestataire non agréé refusé (FR-007 — analyse A1), rattachement idempotent + multi-comptes, garde de pilotage, neutralité 404 et absence de contact/GPS en public (SC-013) — CHAQUE transition vérifie SON événement (SC-009) et son payload sans donnée nominative (SC-011).
- [X] T016 [US1] Seed `backend/seeds/30_prestataires.sql` (research R15 : Tantie Affoué agréée sans compte, Kofi agréé + compte rattaché du seed 20, un prospect complet ; UUID/jetons/horodatages FIGÉS ; `activation_categorie.actif_auto = true` posé DIRECTEMENT) + test d'idempotence dans `backend/api/src/lib.rs` (double exécution identique, ZÉRO événement — SC-012). Schéma inchangé (migration T004) ; `cargo sqlx prepare` si SQL vérifié ajouté.

**Checkpoint**: US1 livrable seule — agrément terrain complet, plaque résolue, activation ZON-03 alimentée.

---

## Phase 4: User Story 2 - Tenir le catalogue et ses prix (Priority: P2)

**Goal**: catalogue d'articles à montants entiers + devise de zone, prix barrés strictement supérieurs, retrait réversible, verrouillage de prix pour CMD ; écran V2 (liste + fiche article) dans Mefali Pro.

**Independent Test**: créer des articles (admin ET vendeur) avec/sans prix barré, vérifier le refus d'un prix barré ≤ prix, figer un prix par déclencheur simulé puis modifier le prix courant et constater l'invariance du montant figé (spec US2).

### Implementation for User Story 2

- [X] T017 [US2] Domaine articles dans `backend/crates/prestataires/src/catalogue.rs` : créer (devise POSÉE par le serveur depuis la zone — research R13, disponible par défaut, ligne `disponibilite_article` par site), modifier (échec explicite si prix barré devient ≤ prix — jamais de retrait silencieux de promo), retrait/remise RÉVERSIBLES (FR-055, `retire_le`), photo d'article (clé neuve + orpheline). Événements `article.cree/modifie/retire_du_catalogue/remis_au_catalogue`.
- [X] T018 [US2] Domaine verrouillage dans `src/catalogue.rs` : `PgPrestataires::figer_prix(&mut tx, article)` → ligne `prix_fige` (research R6, AUCUN endpoint) + `articles_commandables` (trait `Vendeurs`). Test direct (déclencheur simulé) : figer, modifier le prix, montant figé INVARIANT (SC-005).
- [X] T019 [US2] Consultation catalogue dans `src/consultation.rs` + `backend/api/src/prestataires_http.rs` : la fiche publique sert les articles (prix, prix barré, photo présignée, disponibilité), applique ET expose `affichage_rupture` résolu (grise → servi `disponible=false` ; masque → ABSENT — research R8), exclut les retirés ; catalogue en lecture seule si boutique fermée (FR-029). FINIR PAR : utoipa + régénération clients + build vert.
- [X] T020 [US2] HTTP articles dans `backend/api/src/vendeur_http.rs` (GET/POST `…/articles`, PUT `…/articles/{id}`, POST photo/retrait/remise — garde de pilotage T011) et miroir admin dans `admin_prestataires_http.rs` (mêmes méthodes de domaine, `source=admin` — research R12). FINIR PAR : utoipa + régénération clients + build vert.
- [X] T021 [US2] Tests d'intégration OBLIGATOIRES dans `backend/crates/prestataires/tests/catalogue.rs` : prix barré ≤ prix refusé par l'API ET par le CHECK en base (SC-006), montants toujours entiers + devise, retrait → ni servi ni commandable puis remise avec historique, événements de chaque bascule de catalogue, promotion exposée dans la consultation.
- [X] T022 [US2] Seed `backend/seeds/35_articles.sql` (attiéké poisson 1 500, garba 1 000, bissap 500 ; promo Kofi 800 barré 1 000 ; un article en rupture ; disponibilités par site) + compléter le test SC-012 (double seed, prestataires seedés commandables, zéro événement).
- [X] T023 [P] [US2] Formatage montant dans `apps/packages/mefali_core/lib/src/format/montant.dart` : `formaterMontant(unites, devise)` → « 1 500 FCFA » (espace fine insécable, `docs/design/tokens.md`) + export barrel + test unitaire (`apps/packages/mefali_core/test/format/montant_test.dart`).
- [X] T024 [US2] Shell vendeur dans `apps/mefali_pro/lib/vendeur/interface_vendeur.dart` : `NavigationBar` M3 à DEUX destinations (Boutique, Articles — PAS d'onglet Commandes ni de compteur du jour, hors périmètre), `_Bascule` de rôles en tête, `PiedPro` préservé en fin de contenu (FR-046) ; brancher la branche `RolePro.vendeur` de `apps/mefali_pro/lib/roles/interface_pro.dart` ; clés i18n `proVendeur…` dans `lib/l10n/app_fr.arb`. Réf. maquette : `docs/design/png/V1-statut-boutique.png` (barre d'onglets). Tests widget : routeur/porte/bascule non altérés.
- [X] T025 [US2] Écran V2 liste dans `apps/mefali_pro/lib/vendeur/articles/` : provider `MesArticles` (`AsyncNotifier` codegen autoDispose, `.g.dart` commité — `mes_articles.dart`) + `ecran_articles.dart` (recherche locale, compteur « N articles · M en rupture », badge PROMO + prix barré via `formaterMontant`, ajout d'article, section repliée « Articles retirés » avec remise FR-055). Réf. maquette : `docs/design/png/V2-catalogue-stock.png` (vue 1a). Clés i18n `proArticles…` ; tests provider (TransportFake) + widget.
- [X] T026 [US2] Fiche article V2 dans `apps/mefali_pro/lib/vendeur/articles/fiche_article.dart` : steppers ± de prix (pas de clavier obligatoire), toggle promo avec « Le client verra : 800 FCFA ~~1 000 FCFA~~ », photo, enregistrer — état de FORMULAIRE strictement LOCAL (constitution XII) ; aperçu « ce que voit le client » rendu par la consultation PUBLIQUE (même endpoint que C2). Réf. maquette : `docs/design/png/V2-catalogue-stock.png` (vues 1b/1c). Clés i18n ; tests widget (refus prix barré ≤ prix affiché en i18n).

**Checkpoint**: US1 + US2 — catalogue géré depuis l'admin ET depuis Mefali Pro, prix verrouillables.

---

## Phase 5: User Story 3 - Ouvrir, fermer et mettre la boutique en pause (Priority: P3)

**Goal**: statut de boutique en un geste (pause temporisée à réouverture automatique SANS événement, fermé pour la journée, horaires modifiables), rappel non bloquant ; écran V1.

**Independent Test**: basculer par chaque chemin (interrupteur, sortie d'horaires, échéance de pause, prolongation, journée, modification d'horaires) et vérifier à chaque fois l'état effectif, la commandabilité et l'émission — ou l'absence — d'événement selon l'origine (spec US3).

### Implementation for User Story 3

- [X] T027 [US3] Domaine actions boutique dans `backend/crates/prestataires/src/site.rs` : `ouvrir/fermer/mettre_en_pause(durée)/prolonger_pause/fermer_pour_la_journee` (« je reste fermé » ≡ journée — research R4), remplacement des horaires (effet immédiat — FR-034 ; pause en cours inchangée), `rappel_ouverture` dérivé (FR-035), sources `vendeur|admin` + auteur tracés. Événements `site.statut_boutique_change` (avec `pause_fin`) et `site.horaires_modifies` ; les ÉCHÉANCES n'émettent RIEN (FR-036).
- [X] T028 [US3] HTTP boutique : `GET /vendeur/prestataires/{id}/boutique`, `POST …/boutique/action`, `PUT …/horaires` dans `backend/api/src/vendeur_http.rs` + `POST /admin/prestataires/{id}/boutique/action` dans `admin_prestataires_http.rs`. FINIR PAR : utoipa + régénération clients + build vert.
- [X] T029 [US3] Tests d'intégration OBLIGATOIRES dans `backend/crates/prestataires/tests/boutique.rs` : chaque action → état + événement ; échéance de pause → réouverture SANS événement ; échéance hors horaires → reste fermé ; « fermé pour la journée » cesse au prochain jour d'ouverture ; interrupteur « ouvert » hors horaires → fermé et non commandable (SC-004) ; consultation post-bascule JAMAIS l'état précédent (SC-007) ; rappel non réaffiché après « journée ».
- [X] T030 [US3] Écran V1 dans `apps/mefali_pro/lib/vendeur/boutique/` : provider `Boutique` (`AsyncNotifier` codegen autoDispose — `etat_boutique.dart`) + `ecran_boutique.dart` : en-tête + puce d'état, interrupteur 96 px OUVERT/FERMÉ en UN geste, carte pause (30 min / 1 h / 2 h — constantes MVP), état pause (compte à rebours display, « + 30 min », « Fermer pour aujourd'hui », « Réouvrir maintenant »), carte horaires du jour, carte rappel non bloquant (« Ouvrir maintenant » / « Je reste fermé aujourd'hui »). Réf. maquette : `docs/design/png/V1-statut-boutique.png` (états 1a/1b/1c). Clés i18n `proBoutique…` ; tests provider + widget des trois états.
- [X] T031 [US3] Édition des horaires V1 : feuille M3 multi-plages par jour (jour sans plage = fermé) branchée sur `PUT …/horaires`, accessible depuis « ✎ Changer les horaires » dans `ecran_boutique.dart` (fichier `apps/mefali_pro/lib/vendeur/boutique/feuille_horaires.dart`). Réf. maquette : `docs/design/png/V1-statut-boutique.png` (carte « Vos horaires habituels »). Clés i18n ; test widget.

**Checkpoint**: US1–US3 — la tranche T1 du produit (VND-01/02/03) est complète et démontrable.

---

## Phase 6: User Story 4 - Suspendre un prestataire coupe tout, immédiatement (Priority: P4)

**Goal**: suspension à motif = fiche retirée + non commandable + jeton invalide + actions vendeur refusées, sans AUCUNE action de révocation distincte ; rétablissement à l'identique ; correction catégorie/ville (FR-056).

**Independent Test**: suspendre puis vérifier sans délai fiche/commandabilité/jeton/refus vendeur, rétablir et constater le retour à l'identique, jeton et code inchangés (spec US4).

### Implementation for User Story 4

- [X] T032 [US4] Domaine décisions dans `backend/crates/prestataires/src/prestataire.rs` : `suspendre` (motif REQUIS — FR-010, recalcul sans effet à la baisse), `retablir` (plaque INCHANGÉE, recalcul), `corriger` (catégorie et/ou ville — ville de type `ville` ; DOUBLE recalcul ancien + nouveau couple dans la MÊME transaction — FR-056, research R7). Événements `prestataire.suspendu/retabli/corrige` ; journal `statut_decide_par/le/motif`.
- [X] T033 [US4] HTTP admin dans `backend/api/src/admin_prestataires_http.rs` : `POST /admin/prestataires/{id}/suspension` (422 sans motif), `POST …/retablissement`, `POST …/correction` (409 transitions interdites — FR-004). FINIR PAR : utoipa + régénération clients + build vert.
- [X] T034 [US4] Tests d'intégration OBLIGATOIRES dans `backend/crates/prestataires/tests/suspension.rs` + HTTP : suspension → 404 neutre immédiat, non commandable, `resoudre_jeton` → `valide:false`, action vendeur du compte rattaché refusée avec rôle INTACT (SC-002) ; rétablissement → MÊMES jeton/code (SC-003), commandable si catégorie active et boutique ouverte ; correction → deux compteurs recalculés, ancienne catégorie reste active (seuil à la hausse seulement), correction vers une zone qui n'est pas une ville refusée (FR-002) ; décisions journalisées + événements (SC-009).

**Checkpoint**: US1–US4 — la marque « agréé Mefali » est protégée de bout en bout.

---

## Phase 7: User Story 5 - Signaler une rupture par trois chemins (Priority: P5)

**Goal**: bascule de disponibilité par vendeur / coursier sur place (masquage auto 2 distincts / 7 j, précondition de commande active) / admin, tracée et idempotente ; rendu grisé/masqué côté client ; bascule en un geste dans V2.

**Independent Test**: basculer un même article par les trois sources (source + auteur tracés), déclencher le masquage automatique par deux coursiers distincts sous précondition simulée, lever côté vendeur, constater le re-masquage immédiat, et vérifier le refus non compté d'un coursier inéligible (spec US5).

### Implementation for User Story 5

- [X] T035 [US5] Domaine bascules dans `backend/crates/prestataires/src/disponibilite.rs` : bascule vendeur/admin (source + auteur sur la ligne — FR-037), verrou admin (`source='admin' ∧ disponible=false` → seule une bascule admin remet en vente — FR-041, 409 côté vendeur), articles retirés non basculables. Événements `article.mis_en_rupture`/`article.remis_en_vente` (avec `automatique`).
- [X] T036 [US5] Domaine signalements dans `src/disponibilite.rs` : insertion idempotente (`id` = UUID client, `ON CONFLICT DO NOTHING` — FR-039), précondition par le port `CommandesActives` (refus 403 NON compté — FR-038), fenêtre glissante paramétrée (`rupture.masquage_seuil`/`masquage_fenetre_jours`) évaluée À L'ÉCRITURE sur coursiers DISTINCTS (research R10), masquage automatique dans la même transaction, signalement sur article déjà en rupture compté sans changement d'état. Événement `signalement_rupture.recu`.
- [X] T037 [US5] HTTP : `POST …/articles/{id}/disponibilite` (vendeur dans `vendeur_http.rs`, admin dans `admin_prestataires_http.rs`) + `POST /coursier/signalements-rupture` (en-tête `Idempotency-Key` requis, garde `exiger_role(Coursier)`) dans `backend/api/src/signalements_http.rs` (nouveau, montage ×2). FINIR PAR : utoipa + régénération clients + build vert.
- [X] T038 [US5] Tests d'intégration OBLIGATOIRES dans `backend/crates/prestataires/tests/ruptures.rs` : trois sources tracées (source + auteur), coursier inéligible refusé et compté nulle part, rejeu même UUID sans double comptage, 2 coursiers distincts / 7 j → masquage auto + événement, 2 signalements du MÊME coursier = 1, levée vendeur puis re-masquage au signalement suivant, rupture admin non levable par le vendeur, sortie de fenêtre par `UPDATE recu_le` SQL brut, article retiré non signalable, rendu grisé vs masqué selon la config de catégorie (SC-008, FR-042).
- [X] T039 [US5] UI V2 bascule : composant `BasculeStock` 84×44 visuel avec zone de hit ≥ 48 dp (tap-min de tokens.md — analyse X1 ; vert/rouge plein, libellé sous le pouce) dans `apps/mefali_pro/lib/vendeur/composants.dart`, branché en UN geste dans `ecran_articles.dart` (ligne rupture grisée + bordure danger — PAS de bandeau « N clients seront prévenus », VND-09 hors périmètre) et toggle « Disponible à la vente » dans `fiche_article.dart` ; refus du verrou admin affiché en i18n. Réf. maquette : `docs/design/png/V2-catalogue-stock.png` (vue 1a + carte disponibilité 1b). Clés i18n ; tests widget (bascule optimiste + erreur 409).

**Checkpoint**: les cinq stories sont indépendamment démontrables — périmètre VND-01→04 complet.

---

## Phase 8: Polish & Cross-Cutting Concerns

- [ ] T040 Dérouler `specs/005-prestataires-catalogue-vendeur/quickstart.md` intégralement : parcours curl §3 (agrément, suspension/rétablissement à jeton constant, prix barré refusé, seeds ×2) + validation émulateur §4 (V1 trois états, V2 liste/fiche/aperçu, suspension à chaud) ; vérifier transversalement SC-009 (auteur/source/horodatage sur chaque événement) et SC-011 (aucun payload avec nom/contact/GPS).
- [ ] T041 Chaîne qualité complète : `cargo test` workspace + `cargo sqlx prepare` sans diff + `./scripts/generate-clients.sh` puis `git diff --exit-code clients/ openapi.json` + `dart analyze` (JAMAIS `flutter analyze`) et `flutter test` dans `apps/mefali_pro` et `apps/packages/mefali_core` + contrôle de dérive des `.g.dart` (build_runner sans diff).
- [ ] T042 Revue Definition of Done (`docs/user-stories-v2.md` §0.4) story par story pour VND-01, VND-02, VND-03, VND-04 : (1) critères d'acceptation couverts par des tests, (2) annotations utoipa à jour + clients régénérés sans diff manuel, (3) migration versionnée + seeds à jour, (4) événement outbox pour tout changement d'état + taxonomie MET-01 déclarée, (5) clés i18n fr externalisées, (6) paramètres « paramétrables » en configuration de zone — consigner l'écart éventuel et le corriger AVANT le commit de clôture du cycle.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)** : T001 d'abord (registre avant code — FR-051) ; T002 → T003.
- **Foundational (Phase 2)** : T004 (migration) d'abord ; T005/T006 en parallèle ; T007 après T002–T005. BLOQUE toutes les stories.
- **Stories (Phases 3–7)** : ordre de livraison P1 → P5 (dépendances de la spec : US2 dépend de US1 — un article appartient à l'extension vendeur ; US3 dépend de US1 — le statut est porté par le site ; US4 éteint ce que US1–US3 allument ; US5 dépend de US2 — la disponibilité porte sur un article).
- **Polish (Phase 8)** : après US1–US5 ; T042 est la DERNIÈRE tâche.

### Within Each Story

- Domaine avant HTTP ; HTTP avant tests d'intégration HTTP ; backend (clients régénérés) avant UI ; provider avant écran.
- T010 dépend de T008 + T009 (complétude de fiche ET de site vérifiées à l'agrément) ; T024 dépend de T013 (client Dart avec `GET /vendeur/prestataires`) ; T025/T026 dépendent de T020 + T024 ; T030 dépend de T028 + T024 ; T039 dépend de T037 + T025/T026.

### Parallel Opportunities

- Phase 2 : T005 ∥ T006 (crates différents), pendant que T004 tourne sur les migrations.
- US1 : T009 ∥ T008, T011 ∥ T010 (fichiers différents du crate).
- T023 (`mefali_core`) est parallélisable avec TOUT le backend d'US2.
- Les tâches HTTP (T012–T014, T019–T020, T028, T033, T037) sont SÉQUENTIELLES entre elles : elles touchent toutes le montage `api/src/lib.rs` et régénèrent les clients.

---

## Parallel Example: User Story 1

```bash
# Après T007, lancer en parallèle :
Task: "T008 Domaine fiche (prestataire.rs — création, photos, charte)"
Task: "T009 Domaine site + etat_effectif pure (site.rs, consultation.rs)"
# Puis, en parallèle :
Task: "T010 Cycle de vie + plaque (prestataire.rs, plaque.rs)"
Task: "T011 Rattachement + garde de pilotage (rattachement.rs)"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phases 1–2 (registre, migration, reprises, composition).
2. Phase 3 complète → **STOP et VALIDER** : agréer un prestataire seedé via curl, fiche publique servie, jeton résolu, activation recalculée (quickstart §3.1).
3. Démo possible : l'Admin peut agréer sur le terrain — Tantie Affoué existe dans le produit.

### Incremental Delivery

- + US2 → catalogue et prix (T1 produit avance) → valider SC-005/006 → commit/merge.
- + US3 → boutique V1 (tranche T1 de VND complète) → valider SC-004/007.
- + US4 → suspension (protection de la marque) → valider SC-002/003.
- + US5 → ruptures (tranche T2) → valider SC-008 → Phase 8 puis clôture du cycle.
- Un commit conventionnel par tâche ou groupe logique : `feat(prestataires): VND-0x …` (T042 avant le commit de clôture).
