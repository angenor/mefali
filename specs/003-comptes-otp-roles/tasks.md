# Tasks: Comptes, authentification OTP et rôles

**Input**: Design documents from `/specs/003-comptes-otp-roles/`

**Prerequisites**: plan.md, spec.md, research.md (R1–R13), data-model.md, contracts/openapi-comptes.yaml, quickstart.md

**Tests**: constitution VII — chaque transition des machines à états (data-model §4) reçoit un test d'intégration OBLIGATOIRE ; les garde-fous OTP et la neutralité anti-énumération (SC-002/003) sont couverts par des tests dédiés ; tout changement SQL → `cargo sqlx prepare`.

**Organization**: tâches groupées par user story (US1 → US5, priorités internes P1 → P5 de la spec — produit : toutes P0). Consignes de l'input respectées : tâches ≤ 1 j ; toute tâche API SE TERMINE par annotations utoipa → `./scripts/generate-clients.sh` → build vert ; la (seule) tâche de schéma COMMENCE par sa migration sqlx ; toute tâche UI référence sa cible design — AUCUNE capture `docs/design/png/` dédiée à l'auth/adresses n'existe (exploration §10) : `Planche-de-style.png` + `docs/design/tokens.md` font foi ; la DERNIÈRE tâche est la revue Definition of Done (§0.4).

## Format: `[ID] [P?] [Story] Description`

- **[P]** : parallélisable (fichiers différents, aucune dépendance sur une tâche inachevée)
- **[Story]** : US1..US5 (phases stories uniquement)
- Chemins exacts dans chaque description ; estimation entre parenthèses

## Path Conventions

- Backend : `backend/crates/comptes/`, couche HTTP `backend/api/src/`, migrations `backend/migrations/`, seeds `backend/seeds/`
- Apps : `apps/mefali_client/`, `apps/mefali_pro/`, partagé `apps/packages/mefali_core/`
- Clients générés : `clients/dart/`, `clients/ts/` — JAMAIS édités à la main (régénération uniquement)
- `web/` : NON touché ce cycle (admin en API journalisée — plan, précédent 002)

## Règles constitutionnelles appliquées

- Schéma : UNE nouvelle migration `0003_comptes.sql` (T002) — 0001/0002 intouchées ; `cargo sqlx prepare` après tout SQL ; ⚠ migrations EMBARQUÉES : reconstruire `cargo build -p api --bin api` après T002.
- API : chaque tâche endpoint (T008, T012, T015, T018, T021) se termine par utoipa → régénération clients → build vert, diff commité.
- Événements : les 14 événements déclarés dans `docs/taxonomie-evenements.md` (T004) AVANT toute implémentation ; émission via `socle::ecrire_evenement` dans la MÊME transaction ; test par transition.
- i18n : `message_cle` backend + `flutter gen-l10n` (fr) pour toute chaîne UI.
- Paramétrable → configuration de zone : indicatif, durée note vocale, rétention, version consentement (seed T009) — jamais en dur.
- PROVISIONS (CPT-06 `prepaiement_impose`/`bloque`, `livraison_origine`) : colonnes en T002 UNIQUEMENT — aucune tâche de logique ou d'UI.

---

## Phase 1: Setup

**Objectif** : dépendances vérifiées et figées (constitution X).

- [X] T001 Vérifier sur crates.io/pub.dev les dernières versions STABLES et les figer : backend `jsonwebtoken` (R1), `phonenumber` (R4), `hmac` (R3), `rand`, `actix-multipart` (R7) dans `backend/Cargo.toml` (workspace.dependencies) ; activer `redis`/`deadpool-redis`/`aws-sdk-s3` (déjà déclarés, jamais consommés) dans les `Cargo.toml` de `backend/crates/comptes/` et `backend/api/` ; Flutter : `flutter_secure_storage`, `image_picker`, `record`, `just_audio` (plugins natifs stabilisés tôt — cadrage §10.1, R11) dans `apps/packages/mefali_core/pubspec.yaml`. `cargo build` + `flutter pub get` verts, lockfiles commités. (½ j)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Objectif** : schéma, types, ports et infra partagés — bloque toutes les stories.

- [X] T002 COMMENCE par la migration sqlx : créer `backend/migrations/0003_comptes.sql` (data-model §1–2 : schéma `comptes`, enums `role`/`statut_role`, tables `compte` — avec colonnes PROVISION CPT-06 —, `session`, `attribution_role` + CHECK client toujours valide, `dossier_coursier`, `vehicule_declare` FK `zones.type_transport`, `adresse` — `livraison_origine` uuid SANS FK —, index et UNIQUE de data-model) ; `cargo sqlx migrate run`, `cargo sqlx prepare --workspace`, **reconstruire `cargo build -p api --bin api`** (migrations embarquées) ; mettre à jour `backend/migrations/README.md`. (1 j)
- [X] T003 [P] Types et ports du crate : `backend/crates/comptes/src/modele.rs` (Compte, Role, StatutRole, Session, AttributionRole, DossierCoursier, VehiculeDeclare, Adresse, ErreurComptes — data-model §5), `backend/crates/comptes/src/ports.rs` (traits `DepotEphemere`, `EnvoiSms`, `DepotObjets` + impls de test `MemoireEphemere` à horloge injectable, `SmsTraces`, `MemoireObjets` — R3/R6/R7), exports `backend/crates/comptes/src/lib.rs`, dépendances `backend/crates/comptes/Cargo.toml` (socle, zones, sqlx, serde, uuid, chrono, thiserror, async-trait, jsonwebtoken, phonenumber, hmac, sha2, rand). (1 j)
- [X] T004 [P] Déclarer AVANT implémentation (constitution VI) les 14 événements dans `docs/taxonomie-evenements.md` : `compte.cree`, `session.creee`, `session.revoquee` (origine locale/à distance/réutilisation), `role.demande`, `role.attribue`, `role.valide`, `role.refuse`, `role.suspendu`, `role.retabli`, `dossier_coursier.soumis` (drapeau re-soumission), `adresse.enregistree`, `adresse.modifiee`, `adresse.supprimee`, `adresse.repere_vocal_purge` — payloads avec `decide_par`/`motif` (journal FR-014), propriétés standard zone/role (R10, data-model §4). (½ j)
- [X] T005 Infra réelle des ports dans la couche api : `backend/api/src/infra_redis.rs` (`RedisEphemere` — deadpool-redis, opérations atomiques vérifier-et-décrémenter par script Lua, clés/TTL de data-model §3) et `backend/api/src/infra_s3.rs` (`S3Objets` — aws-sdk-s3, `S3_ENDPOINT` override + `force_path_style`, put/presigner_get(10 min)/supprimer) ; `backend/crates/socle/src/config.rs` : + `jwt_secret`, `sms_mode` ; `infra/.env.example` : + `JWT_SECRET`, `SMS_MODE=traces` ; wiring optionnel dans `api::run()` (`backend/api/src/lib.rs`, patron du pool Pg : absent → /health seul). Dépend de T001, T003. (1 j)

**Checkpoint** : schéma en place, ports mockables — les stories peuvent démarrer.

---

## Phase 3: User Story 1 — Inscription et connexion par téléphone + OTP (US1, P1 — CPT-01) 🎯 MVP

**Objectif** : flux unique inscription/connexion — E.164 (+225 par zone), OTP 6 chiffres/5 min/3 essais/3 SMS/h, consentement ARTCI bloquant, compte réduit au numéro, session ouverte.

**Test indépendant** : sur environnement vierge, inscription complète d'un numéro inconnu (code → consentement → accueil connecté) puis connexion du même numéro ; garde-fous et neutralité vérifiés sans aucun autre module (SC-001/002/003/008).

- [X] T006 [US1] Domaine OTP : `backend/crates/comptes/src/otp.rs` — normalisation E.164 (`phonenumber` + indicatif `telephone.indicatif_defaut` résolu via `ConfigurationZones` — R4), défi OTP via `DepotEphemere` (code CSPRNG 6 chiffres, HMAC-SHA256, TTL 300 s, 3 essais atomiques, écrasement à chaque nouvelle demande), plafonds 3 SMS/h/numéro + 10 demandes/h/IP (R12), envoi via `EnvoiSms` ; tests avec `MemoireEphemere` (horloge injectable) : expiration > 5 min, 4ᵉ saisie invalide le défi, 4ᵉ SMS non envoyé, nouvelle demande invalide l'ancien code, numéro non normalisable refusé. Dépend de T002, T003. (1 j)
- [X] T007 [US1] Domaine compte + session initiale : `backend/crates/comptes/src/inscription.rs` (issue de vérification → session (numéro connu) OU `consentement_requis` + jeton d'inscription usage unique TTL 10 min (R3) ; création de compte TRANSACTIONNELLE : compte réduit au numéro + zone + consentement horodaté/version, attribution `client` valide, événements `compte.cree` + `session.creee` — FR-005/006) et `backend/crates/comptes/src/session.rs` (émission JWT HS256 15 min claims sub/sid + refresh opaque 256 bits haché SHA-256 — R1/R2) ; `backend/crates/comptes/src/depot.rs` (`PgComptes` : lectures + écritures inhérentes sur `&mut PgTransaction`) ; tests : création, unicité du numéro (pas de doublon), consentement absent → aucun compte, `derniere_connexion_le` mis à jour. Dépend de T006, T004. (1 j)
- [X] T008 [US1] Endpoints publics : `backend/api/src/auth_http.rs` — `POST /auth/otp/demander` (202 UNIQUE et neutre), `POST /auth/otp/verifier` (200 `session`|`consentement_requis`, 401 neutre unique), `POST /auth/inscription` (201/401/422) conformes à `contracts/openapi-comptes.yaml`, DTO `ToSchema`, erreurs `{code, message_cle}` i18n fr, montage dans `backend/api/src/lib.rs` ; tests Actix : parcours complet, garde-fous (SC-002) et test de NEUTRALITÉ octet-à-octet numéro connu vs inconnu sur toutes les issues (SC-003). SE TERMINE PAR : annotations utoipa à jour → `./scripts/generate-clients.sh` → build vert, diff `openapi.json` + `clients/` commité. Dépend de T007, T005. (1 j)
- [X] T009 [P] [US1] Seeds : `backend/seeds/20_comptes.sql` (data-model §6 — UUID FIXES + `ON CONFLICT DO UPDATE` : compte premier admin avec attributions `client`+`admin` valides ; paramètres de zone sur CI : `telephone.indicatif_defaut="+225"`, `adresse.retention_repere_vocal_jours=365`, `medias.note_vocale_duree_max_s=30`, `consentement.artci_version="2026-07"` ; AUCUN événement outbox) ; test `seed_comptes_idempotent` (double seed → état identique, SC-008). Dépend de T002. (½ j)
- [X] T010 [US1] UI auth partagée : `apps/packages/mefali_core/lib/src/auth/` — `SessionAuth` (jetons dans `flutter_secure_storage`, en-tête Authorization sur le client généré), écrans `EcranTelephone`, `EcranOtp` (6 cases, compte à rebours de renvoi), `EcranConsentement` (case JAMAIS pré-cochée — FR-006) ; branchement navigation splash → auth → accueil provisoire dans `apps/mefali_client/lib/main.dart` et `apps/mefali_pro/lib/main.dart` ; clés fr via gen-l10n. **Design : aucune capture dédiée dans `docs/design/png/` (exploration §10) — `Planche-de-style.png` + `docs/design/tokens.md` font foi (M3 `.adaptive`, bouton primaire 56 px, actions en bas, pas de mode sombre).** Tests widget : saisie code, compte à rebours, consentement bloquant. Dépend de T008 (client Dart régénéré). (1 j)

**Checkpoint US1** : Awa s'inscrit et se reconnecte — MVP démontrable.

---

## Phase 4: User Story 2 — Sessions multi-appareils et déconnexion à distance (US2, P2 — CPT-02)

**Objectif** : session par appareil sans expiration propre, rotation du refresh avec détection de réutilisation, liste/révocation à distance, contrôle session+rôle à CHAQUE requête — et remplacement d'`AdminAuth` (contrat du cycle 002).

**Test indépendant** : deux appareils sur un compte, révocation de l'un depuis l'autre (SC-004) ; fonction protégée refusée sans session valide ou sans rôle.

- [ ] T011 [US2] Domaine sessions complet : `backend/crates/comptes/src/session.rs` — rotation à chaque rafraîchissement (`refresh_precedent_hash`, réutilisation détectée → session RÉVOQUÉE + `session.revoquee` origine=réutilisation — R2), révocation locale/à distance, liste des appareils actifs, `derniere_activite_le` ; tests d'intégration de TOUTES les transitions (data-model §4) : rotation, réutilisation → révocation, session révoquée refusée, aucune expiration d'inactivité, indépendance des appareils. Dépend de T007. (1 j)
- [ ] T012 [US2] Extracteur `Auth` + `exiger_role` (R5) : `backend/api/src/auth_http.rs` — validation JWT + UNE requête indexée (session non révoquée + rôles `valide`) ; REMPLACEMENT d'`AdminAuth` : `backend/api/src/zones_http.rs` (`forcer_categorie` → `Auth` + `exiger_role(Admin)`, handler inchangé), suppression `X-Admin-Token`/`ADMIN_API_TOKEN` (`backend/crates/socle/src/config.rs`, `infra/.env.example`), `SecurityScheme` `adminToken` → `bearerAuth` ; endpoints `POST /auth/rafraichir`, `POST /auth/deconnexion`, `GET /moi`, `GET /moi/sessions`, `DELETE /moi/sessions/{session_id}` ; tests Actix : 401 sans/après révocation, 403 sans rôle, forçage zones avec JWT admin 200 / ancien X-Admin-Token 401, révocation à distance effective (SC-004). SE TERMINE PAR : annotations utoipa à jour → `./scripts/generate-clients.sh` → build vert, diff commité. Dépend de T011, T009. (1 j)
- [ ] T013 [US2] UI appareils + refresh auto : `apps/packages/mefali_core/lib/src/appareils/EcranAppareils` (liste, session courante marquée, déconnexion à distance) ; intercepteur refresh automatique sur 401 + déconnexion propre si refresh refusé (`SessionAuth`) ; entrée « Appareils connectés » dans les paramètres des 2 apps. **Design : aucune capture dédiée — `Planche-de-style.png` + `docs/design/tokens.md` font foi.** Tests widget : liste, révocation, retour à l'auth après refresh refusé. Dépend de T012, T010. (½ j)

**Checkpoint US2** : téléphone perdu = révocable à distance ; tous les endpoints suivants ont leur garde.

---

## Phase 5: User Story 3 — Rôles cumulables et bascule Mefali Pro (US3, P3 — CPT-03)

**Objectif** : 1..n rôles par compte ; coursier demandé in-app (validation admin), vendeur attribué à l'agrément (§5.1), admin par admin existant ; Mefali Pro bascule sans reconnexion ; décisions journalisées, prise d'effet immédiate.

**Test indépendant** : compte multi-rôles ; demande coursier sans privilège avant validation ; Pro refuse sans rôle validé ; bascule bi-rôle sans re-OTP (SC-005 partiel, SC-006, SC-008).

- [ ] T014 [US3] Domaine rôles : `backend/crates/comptes/src/role.rs` — machine à états UNIQUE (R9, data-model §4) : `attribuer` (vendeur/admin, par admin), `valider`/`refuser` (coursier en_attente), `suspendre`/`retablir` (coursier/vendeur), transitions invalides → `TransitionInvalide` ; `Comptes::roles_valides` ; chaque transition émet son événement `role.*` (decide_par, motif) dans la MÊME transaction ; tests d'intégration de TOUTES les transitions + rollback → aucun événement + motif requis pour refuser/suspendre. Dépend de T007, T004. (1 j)
- [ ] T015 [US3] Endpoint décisions admin : `backend/api/src/comptes_http.rs` — `POST /admin/comptes/{compte_id}/roles/{role}` (actions par rôle du contrat, 200 EtatRole / 409 transition invalide / 403 non-admin / 404) ; tests Actix par action, y compris attribution admin par admin uniquement (FR-012) et effet IMMÉDIAT d'une suspension sur la requête suivante (R5). SE TERMINE PAR : annotations utoipa à jour → `./scripts/generate-clients.sh` → build vert, diff commité. Dépend de T014, T012. (½ j)
- [ ] T016 [US3] UI bascule Mefali Pro : `apps/mefali_pro/lib/` — routeur d'accueil par rôles validés (aucun rôle pro → écran d'état de la demande FR-013 ; un rôle → son interface placeholder ; deux → bascule coursier/vendeur SANS reconnexion, < 5 s — SC-006) ; clés fr gen-l10n. **Design : aucune capture dédiée — les écrans K\*/V\* de `docs/design/png/` sont les cibles des cycles CRS/VND ; `Planche-de-style.png` + `docs/design/tokens.md` font foi pour le routeur/état.** Tests widget : `bascule_role_sans_reconnexion`, état en attente/refusé affiché. Dépend de T015, T010. (1 j)

**Checkpoint US3** : Kofi (vendeur attribué) et Yao (coursier en attente) voient chacun le bon écran Pro.

---

## Phase 6: User Story 4 — Dossier coursier (US4, P4 — CPT-04)

**Objectif** : dossier soumis in-app (pièce → Garage, véhicules du référentiel ZON-03 actifs dans la zone, référent local) ; statut = attribution coursier ; porte de mise en ligne exposée aux cycles CRS/DSP.

**Test indépendant** : soumission complète → en attente → refus de mise en ligne → validation admin → porte ouverte → suspension → porte refermée (SC-005).

- [ ] T017 [US4] Domaine dossier : `backend/crates/comptes/src/dossier.rs` — soumission TRANSACTIONNELLE (dossier + véhicules soumis par SLUG — analyze C2 —, résolus en id `zones.type_transport` et validés contre `ConfigurationZones::transports_actifs` de la zone — `VehiculeHorsZone` sinon —, pièce via `DepotObjets` clé `comptes/pieces/{compte_id}/{uuidv7}`, transition rôle ∅/refuse → en_attente, événements `role.demande` + `dossier_coursier.soumis`) ; re-soumission après refus ; `Comptes::coursier_autorise_en_ligne` (true ⇔ statut valide — SC-005) et `Comptes::capacites_transport` (filtre DSP futur) ; tests : dossier incomplet non soumis, véhicule hors zone, porte false pour en_attente/refuse/suspendu, type désactivé après déclaration conservé mais signalé (edge case spec). Dépend de T014, T005. (1 j)
- [ ] T018 [US4] Endpoints dossier : `backend/api/src/comptes_http.rs` — `POST /moi/dossier-coursier` (multipart `actix-multipart`, en-tête `Idempotency-Key` REQUIS — rejeu pendant en_attente → 200 état courant, R14 —, pièce ≤ 10 Mo jpeg/png/webp/pdf, 201/409/422) + `GET /moi/dossier-coursier` (statut+motif) + `GET /admin/comptes/dossiers-coursier?statut=` + `GET /admin/comptes/{compte_id}/dossier-coursier` (avec `piece_url` présignée 10 min — R7) ; tests Actix : soumission, 409 si en_attente/valide, présignée admin, 403 non-admin. SE TERMINE PAR : annotations utoipa à jour → `./scripts/generate-clients.sh` → build vert, diff commité. Dépend de T017, T015. (1 j)
- [ ] T019 [US4] UI dossier coursier : `apps/mefali_pro/lib/` — `FormulaireDossierCoursier` (photo de pièce via `image_picker`, véhicules cochés depuis `transport.actifs` de la config distante déjà servie par `ServiceConfig`, référent nom+téléphone) + `EcranEtatDemande` enrichi (statut, motif de refus, re-soumission) ; clés fr. **Design : aucune capture dédiée (`A2-prestataires-agrement.png` = console admin Nuxt T3, PAS une cible Flutter — constitution XI) ; `Planche-de-style.png` + `docs/design/tokens.md` font foi.** Tests widget : validation du formulaire (incomplet bloqué), re-soumission après refus. Dépend de T018, T016. (1 j)

**Checkpoint US4** : Yao soumet depuis son téléphone, l'admin valide par API, la porte CRS répond.

---

## Phase 7: User Story 5 — Adresses enregistrées avec repère vocal (US5, P5 — CPT-05)

**Objectif** : enregistrement post-livraison (déclencheur simulé — assumption spec), réutilisation en un geste avec note vocale, gestion, purge à 12 mois d'inutilisation (paramètre de zone).

**Test indépendant** : événement « livraison réussie » simulé → enregistrement (GPS + note vocale) → réutilisation à l'identique → renommage/suppression → purge (SC-007).

- [ ] T020 [US5] Domaine adresses : `backend/crates/comptes/src/adresse.rs` — enregistrer (repère texte et/ou note vocale via `DepotObjets` clé `comptes/reperes/{compte_id}/{uuidv7}`, durée ≤ `medias.note_vocale_duree_max_s` de la zone), modifier, supprimer (soft — `supprimee_le`), `marquer_adresse_utilisee` (appelée par CMD plus tard), `purger_reperes_vocaux` (rétention `adresse.retention_repere_vocal_jours` par zone, transaction DB + `adresse.repere_vocal_purge` PUIS delete S3 best-effort — R8) + job quotidien tokio dans `api::run()` (`backend/api/src/lib.rs`, patron WorkerOutbox) ; événements `adresse.enregistree/modifiee/supprimee` ; tests : CRUD complet, purge à 366 j (événement + objet supprimé via `MemoireObjets`), adresse purgée reste utilisable (FR-022). Dépend de T007, T005, T004. (1 j)
- [ ] T021 [US5] Endpoints adresses : `backend/api/src/comptes_http.rs` — `GET/POST /moi/adresses` (multipart note vocale ≤ 1,5 Mo ; en-tête `Idempotency-Key` REQUIS = id de l'adresse, rejeu → adresse existante sans doublon, R14), `PATCH/DELETE /moi/adresses/{adresse_id}`, `GET /moi/adresses/{adresse_id}/repere-vocal` (présignée propriétaire, 404 si purgé) + `POST …/repere-vocal` (remplacement après purge) ; tests Actix : octets de la note restitués à l'identique (SC-007), propriété stricte (404 sur l'adresse d'autrui), 422 durée/taille. SE TERMINE PAR : annotations utoipa à jour → `./scripts/generate-clients.sh` → build vert, diff commité. Dépend de T020, T012. (1 j)
- [ ] T022 [US5] UI adresses : `apps/packages/mefali_core/lib/src/adresses/` — `ListeAdresses`, `FeuilleEnregistrerAdresse` (chips Maison/Bureau/libre, proposition refusable — déclencheur simulé pour les tests), `LecteurNoteVocale` (`just_audio`), `EnregistreurNoteVocale` (`record`, borné par le paramètre de zone, re-capture après purge) ; entrée « Mes adresses » dans `apps/mefali_client/lib/` (paramètres) ; clés fr. **Design : aucune capture dédiée — `Planche-de-style.png` + `docs/design/tokens.md` font foi (cibles ≥ 48 dp pour lecture/enregistrement).** Tests widget : feuille d'enregistrement, lecture, adresse sans repère → demande de re-capture. Dépend de T021, T010. (1 j)

**Checkpoint US5** : la deuxième commande d'Awa tient en un geste, note vocale comprise.

---

## Phase 8: Polish & validation finale

- [ ] T023 Passe complète de `specs/003-comptes-otp-roles/quickstart.md` sur environnement dev (docker compose avec Redis + Garage initialisés) : SC-001 → SC-008, neutralité par `diff` de réponses, double seed, `./scripts/generate-clients.sh` puis `git status --porcelain` vide (CI contrat-clients), `flutter analyze`/`flutter test` verts dans core + 2 apps. Dépend de toutes les stories. (½ j)
- [ ] T024 Revue Definition of Done (`docs/user-stories-v2.md` §0.4 — DERNIÈRE tâche, demande utilisateur) : (1) critères CPT-01→05 couverts par tests unitaires + intégration sur TOUTES les transitions ; (2) annotations utoipa à jour, clients Dart/TS régénérés SANS diff manuel ; (3) migration `0003_comptes.sql` versionnée + seeds `20_comptes.sql` à jour ; (4) événements outbox pour chaque changement d'état + taxonomie à jour (T004) — parcours utilisateur : les événements métriques app relèvent du cycle MET ; (5) clés i18n fr externalisées (backend `message_cle`, apps gen-l10n) ; (6) paramètres « paramétrables » en configuration de zone (indicatif, durées, version consentement) — AUCUNE constante en dur hors constantes produit OTP documentées ; puis re-passer `specs/003-comptes-otp-roles/checklists/requirements.md`, vérifier les PROVISIONS (CPT-06 : colonnes sans logique), `cargo test` + `cargo sqlx prepare` verts, commits conventionnels `feat(comptes): CPT-0X …`. Dépend de T023. (½ j)

---

## Dependencies & Execution Order

### Phase Dependencies

```
Phase 1 (T001) ─▶ Phase 2 (T002 ─▶ T003/T004/T005)
Phase 2 ─▶ US1 (T006→T007→T008→T010 ; T009 [P])
US1 ─▶ US2 (T011→T012→T013)          ← T012 requiert T009 (admin seed)
US2 ─▶ US3 (T014→T015→T016)          ← l'extracteur Auth (T012) garde tout
US3 ─▶ US4 (T017→T018→T019)
US1/US2 ─▶ US5 (T020→T021→T022)      ← indépendant de US3/US4
US2..US5 ─▶ Phase 8 (T023→T024)
```

### Chaîne critique

T001 → T002 → T003 → T006 → T007 → T008 → T011 → T012 → T014 → T015 → T017 → T018 → T023 → T024 (backend) ; l'UI (T010, T013, T016, T019, T022) se greffe après chaque régénération de clients.

### Parallel Opportunities

- T003 ∥ T004 (fichiers différents) dès T002 lancée ; T004 ne dépend d'aucun code.
- T009 [P] ∥ T006–T008 (seed vs domaine).
- Chaque tâche UI est parallélisable avec le domaine de la story suivante : T010 ∥ T011, T013 ∥ T014, T016 ∥ T017, T019 ∥ T020.
- US5 (T020–T022) peut démarrer dès T012 finie, en parallèle de US3/US4.

## Implementation Strategy

MVP = Phases 1–3 (T001–T010) : Awa s'inscrit, se connecte, l'app est utilisable — démontrable seule. Livraison incrémentale ensuite : US2 (sécurité des sessions + dette AdminAuth soldée), US3 (Pro), US4 (flotte), US5 (re-commande). Chaque checkpoint est indépendamment testable via les critères de sa story ; `quickstart.md` rejoue l'ensemble en fin de cycle.

## Notes

- Les constantes OTP (6 chiffres, 5 min, 3 essais, 3/h, 10/h/IP) sont des CONSTANTES PRODUIT (clarification spec) — documentées dans le code, PAS en configuration de zone.
- La bascule d'interface Pro (T016) et la proposition d'adresse (T022) livrent leurs déclencheurs simulés : CRS/VND et CMD les brancheront sans retouche du module.
- Estimation totale : ~19,5 jours-homme (24 tâches ≤ 1 j).
