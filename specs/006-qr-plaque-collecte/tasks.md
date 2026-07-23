---
description: "Task list — cycle QRC (006-qr-plaque-collecte)"
---

# Tasks: QR prestataire, plaque et scans de collecte

**Input**: Design documents from `specs/006-qr-plaque-collecte/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/qr-openapi.md](./contracts/qr-openapi.md)

## Conventions de découpe (instruction du cycle)

- **Taille** : chaque tâche tient en **une demi-journée à une journée**, ordonnée par dépendance.
- **Tâche API** (touche `backend/api/src/*_http.rs` / le contrat) → se **termine** par la **clôture API** : *annotations utoipa à jour, `openapi.json` + clients `clients/dart`/`clients/ts` régénérés sans diff, `cargo sqlx prepare` si requêtes touchées, build vert*.
- **Tâche schéma** (DDL) → **commence** par sa **migration sqlx** (`0001..0004` intouchées ; toutes les migrations de ce cycle sont en Phase 2, avant le code qui les consomme).
- **Tâche UI** → **référence la maquette** `docs/design/png/K3-course-active.png` (aucune plaque n'a de maquette — US1 est sans UI) et emploie les constructeurs `.adaptive` (constitution XI — une seule identité Android/iOS, pas de Cupertino).
- **Constitution VII** : chaque transition de machine à états a un **test d'intégration obligatoire**.
- **Dernière tâche** : **revue Definition of Done** (`docs/user-stories-v2.md` §0.4).

## Format : `[ID] [P?] [Story?] Description avec chemin`

- **[P]** : parallélisable (fichiers différents, aucune dépendance incomplète) · **[US#]** : story de rattachement.

## Priorités des stories

| Story | Critère | Priorité cycle | Produit | UI |
|---|---|---|---|---|
| US1 | QRC-01 — Plaque imprimable (Admin) | P1 | P0 | — (API only) |
| US2 | QRC-02 — Scan de collecte en course (Yao) | P1 | P0 | K3 |
| US3 | QRC-03 — Révocation observée au scan | P2 | P0 | K3 |
| US4 | QRC-04 — Mode dégradé + incident | P2 | P0 | K3 |

---

## Phase 1 — Setup

- [X] T001 [P] Ajouter les dépendances backend du crate `qr` — `qrcode` + `printpdf` (dernière stable, constitution X) dans `backend/crates/qr/Cargo.toml`, épinglées au `backend/Cargo.toml`.
- [X] T002 [P] Ajouter les plugins Flutter et manifestes : `mobile_scanner`, `geolocator`, `drift`, `permission_handler` dans `apps/mefali_pro/pubspec.yaml` et `apps/packages/mefali_core/pubspec.yaml` ; `CAMERA` + `ACCESS_FINE_LOCATION` dans `apps/mefali_pro/android/app/src/main/AndroidManifest.xml` ; `NSLocationWhenInUseUsageDescription` dans `apps/mefali_pro/ios/Runner/Info.plist` (piège : `mobile_scanner` utilise la caméra en propre, contrairement à `image_picker`).

---

## Phase 2 — Foundational (bloquant — à finir avant toute story)

- [X] T003 Déclarer les 5 événements outbox dans `docs/taxonomie-evenements.md` (constitution VI, AVANT implémentation) : `plaque.generee`, `arret.collecte`, `livraison.mise_en_livraison`, `plaque.remplacement_requis`, `arret.collecte_rejetee` (payloads minimisés ARTCI, research R12).
- [X] T004 **Migration** `backend/migrations/0005_commandes.sql` (début du travail sur le schéma `commandes`) : enums (`statut_arret`, `mode_collecte`, `etat_livraison`) + tables `commande`/`livraison`/`segment`/`arret` + index (data-model §1).
- [X] T005 **Migration** `backend/migrations/0006_qr.sql` (début du travail sur le schéma `qr`) : `qr.incident_plaque` (UNIQUE arret_id), `qr.action_traitee`, et `ALTER TABLE prestataires.prestataire ADD politique_photo_collecte` (data-model §2).
- [X] T006 Seeds paramètres de zone dans `backend/migrations/seeds/` (`qr.distance_scan_max_m=100`, `qr.photo_seuil_montant=10000` XOF, `qr.retention_photo_collecte_jours=365`, `categorie.restauration/pharmacie.politique_photo`) ; incrémenter les compteurs de `seed_zones_idempotent` dans `backend/api/src/lib.rs` ; inscrire au « Récapitulatif des paramètres de zone » de `docs/user-stories-v2.md`.
- [X] T007 [P] Crate `commandes` — modèle : `backend/crates/commandes/src/modele.rs` (enums miroir, `ArretACollecter`, `ProgressionCollecte`, `ErreurCommandes` + `From<socle::OutboxError>`).
- [X] T008 [P] Crate `commandes` — ports : `backend/crates/commandes/src/ports.rs` (trait `ArretsDeCollecte` + double `ArretsFixes`, patron `CommandesActivesFixes`).
- [X] T009 Crate `commandes` — transition : `backend/crates/commandes/src/depot.rs` `PgCommandes::marquer_arret_collecte` partie A (bascule `a_collecter→collecte` + `socle::ecrire_evenement('arret.collecte')` dans la même transaction) — dépend de T004, T007, T008.
- [X] T010 Crate `commandes` — gating : compléter `marquer_arret_collecte` partie B dans `backend/crates/commandes/src/depot.rs` (bascule livraison `en_collecte→en_livraison` quand tous les arrêts sont résolus + `livraison.mise_en_livraison`, idempotence `uuid_client`) — dépend de T009.
- [X] T011 [P] Crate `qr` — modèle : `backend/crates/qr/src/modele.rs` (`DemandeCollecte`, `ResultatCollecte`, `ArretPreProvisionne`, `ModeCollecte`, `ErreurQr`) + câblage `backend/crates/qr/Cargo.toml` (commandes, prestataires, zones, socle, sha2, qrcode, printpdf).
- [X] T012 Crate `qr` — racine de composition : `backend/crates/qr/src/depot.rs` `PgQr` (pool + `PgCommandes` + `PgPrestataires` + `ConfigurationZones` + `DepotObjets` + port Redis compteur) — dépend de T010, T011.
- [X] T013 `cargo sqlx prepare` après les migrations et les requêtes `commandes`/`qr` ; committer `backend/.sqlx` — dépend de T010, T012.
- [X] T014 Assemblage API : construire `PgCommandes` + `PgQr` dans `backend/api/src/lib.rs` (`run()`), `pub mod qr_http;` + squelette `backend/api/src/qr_http.rs`, exposer `web::Data<PgQr>` — dépend de T012.
- [X] T015 File offline — schéma local : `apps/packages/mefali_core/lib/src/offline/action_en_attente.dart` (tables drift `action_en_attente` + `arret_preprovisionne`, data-model §8) + génération drift — dépend de T002.
- [X] T016 File offline — provider : `apps/packages/mefali_core/lib/src/offline/file_actions.dart` (+`.g.dart`) provider `@Riverpod(keepAlive: true)` `FileActions` (`enfiler` + rejeu idempotent par `uuid_client`) ; export dans `apps/packages/mefali_core/lib/mefali_core.dart` — dépend de T015.

---

## Phase 3 — US1 : Plaque imprimable (P1)

**Objectif** : l'Admin télécharge un PDF imprimable (QR + nom + code) stable pour tout prestataire agréé.
**Test indépendant** : agréer → `GET /admin/prestataires/{id}/plaque` → PDF (QR du jeton + nom + code) ; re-télécharger identique ; prospect/non-admin refusés.

- [X] T017 [P] [US1] Test d'intégration `backend/crates/qr/tests/plaque.rs` : génération + dépôt (`MemoireObjets`) + `plaque.generee` ; re-génération identique ; refus prospect (FR-011) [constitution VII].
- [X] T018 [P] [US1] Composition du PDF : `backend/crates/qr/src/plaque.rs` — matrice `qrcode` (correction M) en rectangles vectoriels `printpdf`, titre i18n rendu serveur + nom + code ; lit `jeton_plaque`/`nom`/`code_secours` via `prestataires`.
- [X] T019 [US1] `PgQr::plaque_pdf` dans `backend/crates/qr/src/depot.rs` : compose (T018), `DepotObjets::deposer("qr/plaques/{id}.pdf")`, `presigner_get`, `ecrire_evenement('plaque.generee')`, refus si pas d'identité — dépend de T018.
- [X] T020 [US1] **API** endpoint admin `telecharger_plaque` (GET `/admin/prestataires/{id}/plaque`, `exiger_role(Role::Admin)`, `PlaqueUrlDto`, clé d'erreur `plaque_absente`) dans `backend/api/src/admin_prestataires_http.rs` + montage aux DEUX chaînes de `backend/api/src/lib.rs` — dépend de T019, T014. **Clôture API**.

---

## Phase 4 — US2 : Scan de collecte en course (P1)

**Objectif** : Yao scanne le QR à chaque arrêt → COLLECTÉ (horodatage serveur) ; toutes les collectes → livraison EN_LIVRAISON ; fonctionne hors-ligne.
**Test indépendant** : course simulée → scan à < 100 m → COLLECTÉ + événement + horodatage serveur ; mauvais vendeur / hors rayon → refus ; dernier arrêt → EN_LIVRAISON ; rejeu hors-ligne idempotent.

- [X] T021 [P] [US2] Test d'intégration `backend/crates/commandes/tests/collecte.rs` : `marquer_arret_collecte` (transition + `arret.collecte`, gating EN_LIVRAISON avec un arrêt `indisponible` compté résolu, idempotence) [VII].
- [X] T022 [P] [US2] Test d'intégration `backend/crates/qr/tests/scan.rs` : scan dans le rayon → COLLECTÉ ; mauvais vendeur → refus ; hors rayon → `hors_zone` ; résolution politique photo ; rejet au rejeu hors-ligne → `arret.collecte_rejetee` [VII].
- [X] T023 [P] [US2] Vérification : `backend/crates/qr/src/verification.rs` — proximité grand-cercle (haversine) vs `qr.distance_scan_max_m`, résolution du jeton via `prestataires::resolution_plaque`, politique photo (prestataire > catégorie > seuil, R4).
- [X] T024 [US2] `PgQr::pre_provisionnement` dans `backend/crates/qr/src/depot.rs` : empreintes `sha256(jeton)` et `sha256(prestataire_id‖code)`, sites, `montant_avance`, `photo_exigee` — dépend de T012, T023.
- [X] T025 [US2] `PgQr::collecter` (mode `scan_qr`, chemin nominal) dans `backend/crates/qr/src/depot.rs` : précondition via `ArretsDeCollecte`, vérification (T023), dépôt photo si exigée (`qr/collectes/{arret_id}.jpg`), appel `commandes::marquer_arret_collecte` — dépend de T010, T023, T024.
- [X] T026 [US2] `PgQr::collecter` — idempotence & rejet : registre `qr.action_traitee`, `arret.collecte_rejetee` sur refus métier (rejeu identique = aucun événement) dans `backend/crates/qr/src/depot.rs` — dépend de T025.
- [X] T027 [US2] **API** `qr_http::course_active` (GET `/courses/active`, `Role::Coursier`, `CourseActiveDto`) dans `backend/api/src/qr_http.rs` + montage `lib.rs` — dépend de T024, T014. **Clôture API**.
- [X] T028 [US2] **API** `qr_http::collecter` (POST `/courses/arrets/{arret_id}/collecte`, multipart si photo, `Role::Coursier`, DTOs + clés `hors_zone`/`photo_requise`/`arret_hors_course`) dans `backend/api/src/qr_http.rs` + montage `lib.rs` — dépend de T026, T027. **Clôture API**.
- [X] T029 [P] [US2] **UI** Bandeaux partagés : `apps/packages/mefali_core/lib/src/coursier/bandeaux.dart` (`BandeauHorsLigne` `--warning`, `BandeauSucces` `--success`) + export — réf. `docs/design/png/K3-course-active.png`.
- [X] T030 [US2] Provider course : `apps/mefali_pro/lib/coursier/course/etat_course.dart` (+`.g.dart`) `AsyncNotifier` (charge `/courses/active`, cache drift `arret_preprovisionne`, coche optimiste) — dépend de T016, T028.
- [X] T031 [US2] **UI** Écran K3 : `apps/mefali_pro/lib/coursier/course/ecran_course_active.dart` — liste d'arrêts (`CarteMefali` + `PuceStatut`), arrêt courant, `BoutonPrincipal(Symbols.qr_code_scanner)` `--primary` en bas, bandeaux — réf. `docs/design/png/K3-course-active.png` — dépend de T030, T029.
- [X] T032 [US2] **UI** Scan (capture) : `apps/mefali_pro/lib/coursier/course/ecran_scan.dart` — `mobile_scanner` + `geolocator` + permission runtime — réf. `docs/design/png/K3-course-active.png` — dépend de T031.
- [X] T033 [US2] **UI** Scan (offline) : compléter `ecran_scan.dart` — comparaison d'empreinte hors-ligne, enfilage via `FileActions`, photo `image_picker` si exigée, coche optimiste — réf. `docs/design/png/K3-course-active.png` — dépend de T032, T016.
- [X] T034 [US2] **UI** Interface coursier : `apps/mefali_pro/lib/coursier/interface_coursier.dart` + remplacer la branche coursier dans `apps/mefali_pro/lib/roles/interface_pro.dart` (patron FR-046 du cycle 005, porte/routeur inchangés) — réf. `docs/design/png/K3-course-active.png` — dépend de T031.
- [X] T035 [US2] Clés i18n fr : `apps/packages/mefali_core/lib/l10n/*.arb` (scan, collecté, hors-ligne, en livraison, message_cle d'erreur) + régénération l10n.
- [X] T036 [US2] `dart run build_runner build` + `dart analyze` propre (JAMAIS `flutter analyze`, constitution XII) ; `.g.dart` commités — dépend de T030, T033.

---

## Phase 5 — US3 : Révocation observée au scan (P2)

**Objectif** : un prestataire suspendu n'est plus collectable ; « prestataire temporairement indisponible ».
**Test indépendant** : suspendre → scan → refus ; rétablir → collectable ; jeton inconnu → plaque invalide.

- [X] T037 [P] [US3] Test d'intégration `backend/crates/qr/tests/revocation.rs` : suspendu → `prestataire_indisponible` ; rétabli → collectable ; jeton forgé → `plaque_invalide` ; rejet hors-ligne au rejeu → `arret.collecte_rejetee` (motif `jeton_revoque`) une fois [VII].
- [X] T038 [US3] **API** Branche de révocation dans `PgQr::collecter` (`backend/crates/qr/src/depot.rs`) + clés `prestataire_indisponible`/`plaque_invalide` dans `backend/api/src/qr_http.rs` : refus si `resolution_plaque().valide == false` ou jeton inconnu ; `arret.collecte_rejetee` à la réconciliation — dépend de T028. **Clôture API**.
- [X] T039 [US3] **UI** Message « prestataire temporairement indisponible » dans `apps/mefali_pro/lib/coursier/course/ecran_scan.dart` + clé i18n — réf. `docs/design/png/K3-course-active.png` — dépend de T033, T038.

---

## Phase 6 — US4 : Mode dégradé + incident (P2)

**Objectif** : QR illisible → saisie du code (3 essais), géoloc exigée, incident « plaque à remplacer » créé.
**Test indépendant** : bon code à < 100 m → COLLECTÉ ; mauvais code → refus ; 3 échecs → épuisé ; incident créé une fois ; bon code hors rayon → refus.

- [X] T040 [P] [US4] Test d'intégration `backend/crates/qr/tests/degrade.rs` : bon code → COLLECTÉ (`mode=code_secours`) ; mauvais code → `code_incorrect` ; 3 échecs → `code_epuise` ; `qr.incident_plaque` créé UNE fois + `plaque.remplacement_requis` ; bon code hors rayon → `hors_zone` (FR-022) [VII].
- [X] T041 [US4] `PgQr::collecter` (mode `code_secours`) dans `backend/crates/qr/src/depot.rs` : comparaison au code du prestataire de l'arrêt (jamais globale), compteur d'essais Redis `qr:essais:{arret_id}`, incident au 1er passage (UNIQUE arret) + `ecrire_evenement('plaque.remplacement_requis')` — dépend de T026.
- [X] T042 [US4] **API** Clés d'erreur `code_incorrect`/`code_epuise` et branchement du mode `code_secours` dans `backend/api/src/qr_http.rs` (DTO `mode` déjà présent, T028) — dépend de T041, T028. **Clôture API**.
- [X] T043 [US4] **UI** Mode dégradé dans `apps/mefali_pro/lib/coursier/course/ecran_scan.dart` : saisie code 4 chiffres, 3 essais locaux, comparaison d'empreinte hors-ligne, géoloc exigée + i18n — réf. `docs/design/png/K3-course-active.png` — dépend de T033.

---

## Phase 7 — Polish & transverse

- [X] T044 [P] Job de purge des photos de récupération : `backend/api/src/lib.rs` (`job_purge_photos_collecte`, patron `job_purge_reperes`, paramètre `qr.retention_photo_collecte_jours`) + test — constitution VIII.
- [~] T045 [P] Validation quickstart : SC-001..009 backend couverts par les tests d'intégration (`cargo test`, 89 verts) ; **passe manuelle K3 sur émulateur NON exécutée** (pas d'appareil dans la session) — à dérouler par l'utilisateur.
- [X] T046 Portes d'avant-commit : `cargo test` + `cargo sqlx prepare` verts ; `openapi.json` + clients régénérés SANS diff ; `dart analyze` propre ; `.g.dart` commités.
- [X] T047 [P] Mettre à jour `MEMORY.md` (pointeur cycle 006) et confirmer le « Récapitulatif des paramètres de zone » (T006).
- [X] T048 **Revue Definition of Done** (`docs/user-stories-v2.md` §0.4) : (1) critères couverts par tests unitaires + intégration ; (2) annotations utoipa à jour + clients régénérés sans diff ; (3) migrations versionnées + seeds à jour ; (4) événements outbox pour chaque transition — **noter que les événements métriques MET-01 sont hors périmètre** (crate `metriques` stub, research R12) ; (5) clés i18n fr externalisées ; (6) paramètres « paramétrables » en configuration de zone. Corriger tout écart avant clôture du cycle.

---

## Dépendances (ordre d'achèvement des stories)

```text
Setup (T001–T002)
  └─> Foundational (T003–T016)  ← BLOQUE toutes les stories
        ├─> US1 (T017–T020)      indépendante — MVP, livrable en premier
        ├─> US2 (T021–T036)      cœur — commandes + qr + offline
        │     ├─> US3 (T037–T039)  greffe sur collecter (révocation)
        │     └─> US4 (T040–T043)  greffe sur collecter (mode dégradé)
        └─> Polish (T044–T048)   après US1..US4 ; T048 = revue DoD (dernière)
```

- US1 est **indépendante** (admin, aucune app coursier, aucun offline).
- US3 et US4 sont des **greffes de `collecter`** (branche + test + message), sans refonte d'US2.
- La file offline (T015–T016) est une infra `mefali_core` partagée par US2/US3/US4.

## Exemples de parallélisation

- **Setup** : T001 (backend) ∥ T002 (Flutter).
- **Foundational** : T007 ∥ T008 ∥ T011 (crates/fichiers distincts) ; T009→T010 puis T012→T013 séquentiels ; T015→T016 (drift) en parallèle du backend.
- **US1** : T017 (test) ∥ T018 (plaque.rs).
- **US2** : T021 ∥ T022 ∥ T023 ∥ T029 ; le backend (T024→T028) et l'app (T030→T036) se rejoignent au contrat régénéré (T028 clôture API).
- **Tests de story** : T037 (US3) ∥ T040 (US4).

## Stratégie d'implémentation (MVP d'abord)

1. **MVP = US1** (T001–T020) : plaque imprimable téléchargeable — livrable et testable seule.
2. **Cœur = US2** (T021–T036) : scan anti-fraude + bascule EN_LIVRAISON + hors-ligne.
3. **Durcissement = US3 + US4** (T037–T043) : révocation observée et mode dégradé.
4. **Polish** (T044–T048) : purge photos, validation quickstart, portes d'avant-commit, **revue DoD**.

**Total : 48 tâches** — Setup 2, Foundational 14, US1 4, US2 16, US3 3, US4 4, Polish 5.
