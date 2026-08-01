---

description: "Tâches — chaîne cash tracée par arrêt et prépaiement mobile money via agrégateur (cycle PAY 011)"
---

# Tasks: Paiements — chaîne cash tracée par arrêt et prépaiement mobile money via agrégateur

**Input**: Design documents from `/specs/011-paiements-cash-prepaiement/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/](./contracts/), [quickstart.md](./quickstart.md)

**Tests**: non optionnels. C'est le cycle de l'argent : la constitution III et VII imposent un test d'intégration par transition, la spec exige des mesures chiffrées (rejeu ×10 → 1 effet, 100 signatures invalides → 0 effet, 10 états de commande équilibrés à l'unité près), et SC-010 n'est vérifiable **que** par une suite rejouée avec un second fournisseur. Les tests unitaires accompagnent les modules purs (machine à états de la transaction, écrêtage de retenue, calcul des trois positions, vérification de signature).

**Organization**: une phase par user story, dans l'ordre de dépendance interne (US1 → US7). Les 7 stories produit sont **toutes P0** ; les priorités P1→P7 des phases sont l'ordre de **livraison**, pas une hiérarchie produit.

**Calibrage**: chaque tâche vise une **demi-journée à une journée**. Une tâche qui déborde se scinde plutôt que de s'étirer.

## Format: `[ID] [P?] [Story] Description`

- **[P]** : parallélisable (fichiers différents, aucune dépendance sur une tâche incomplète)
- **[Story]** : US1..US7 — uniquement dans les phases de story
- Chemins de fichiers exacts dans chaque description

## Path Conventions

- **Backend Rust** : `backend/crates/paiements/` (cœur), `backend/crates/commandes/`, `backend/crates/coursier/`, `backend/crates/prestataires/`, binaire `backend/api/`, migrations `backend/migrations/`, seeds `backend/seeds/`
- **Apps Flutter** : `apps/mefali_client/`, `apps/mefali_pro/`, partagé `apps/packages/mefali_core/`
- **Clients générés** : `clients/dart/`, `clients/ts/` — **jamais** d'édition manuelle, régénération uniquement
- **Non touchés** : `web/`, `infra/`

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
   migration `0022_…`**, elle ne retouche jamais les deux précédentes.
3. **Toute tâche d'UI référence sa capture** `docs/design/png/` et consomme les
   valeurs de `docs/design/tokens.md` — jamais la structure DOM/CSS de
   `docs/design/html/`. ⚠ **Aucune planche de paiement n'existe** (plan.md,
   Complexity Tracking ligne 3) : chaque tâche d'UI nomme la capture **voisine**
   dont elle emprunte les motifs, et l'écart est assumé, pas inventé.
4. Toute transition d'état → événement outbox dans la **même transaction** +
   déclaration dans `docs/taxonomie-evenements.md` **avant** implémentation +
   test d'intégration de la transition. Toute chaîne utilisateur → clé i18n fr.
   Tout paramètre « paramétrable » → configuration de zone héritée.

**Règle propre à ce cycle** : aucune tâche ne fait apparaître un nom d'agrégateur
(CinetPay, PayDunya, Bizao, HUB2) ailleurs que dans
`backend/crates/paiements/src/fournisseur/`. T079 le vérifie mécaniquement.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: déclarer les événements avant d'en émettre un seul, poser tout le schéma du cycle, rendre constructible un crate resté vide depuis le cycle 001, et stabiliser le plugin natif **une bonne fois** (Shorebird ne le patchera pas).

- [X] T001 Déclarer les **9 événements neufs** dans `docs/taxonomie-evenements.md` (`paiement.session_ouverte`, `paiement.confirme`, `paiement.echoue`, `paiement.session_expiree`, `paiement.hors_delai`, `paiement.dossier_ouvert`, `caisse.creance_ouverte`, `caisse.creance_reglee`, `vendeur.offre_livraison_modifiee`) avec leurs charges utiles de [`contracts/ports-paiements.md`](./contracts/ports-paiements.md) §6, **et les 3 amendements** (`arret.collecte` gagne `montant_articles`/`retenue_appliquee`/`retenue_ecretee`, `commande.terminee` sépare `total_du` de `total_encaisse`, `caisse.mouvement` gagne trois valeurs de `type`) — **aucun accès de paiement, aucune signature, aucun identifiant de session dans une charge utile** (FR-103)
- [X] T002 Migration `backend/migrations/0020_paiements_enums.sql` : schéma `paiements`, **4 énumérations neuves** (`etat_transaction`, `moyen_paiement`, `type_dossier`, `etat_dossier`), `prestataires.offre_livraison`, `coursier.nature_creance`, `coursier.etat_creance`, **et les 3 `ALTER TYPE coursier.type_ecriture ADD VALUE`** (`frais_encaisses`, `reglement`, `reversement`) — commentaire en tête rappelant **pourquoi** les enums sont séparés des tables ([data-model.md](./data-model.md) §1, research R21) ; `cargo sqlx migrate run`
- [X] T003 Migration `backend/migrations/0021_paiements_tables.sql` : `paiements.transaction` (+ index partiel `transaction_vivante_unique`), `paiements.notification_recue` (+ contrainte d'unicité triple), `paiements.dossier`, `coursier.creance`, les 2 colonnes VND-08 sur `prestataires.prestataire` et les 3 colonnes de retenue sur `commandes.arret` avec la contrainte `arret_avance_coherente` ([data-model.md](./data-model.md) §2) ; `cargo sqlx migrate run`
- [X] T004 [P] Seed `backend/seeds/90_paiements_parametres.sql` : les **4 paramètres de zone** de research R18 au niveau pays, rejouable (`ON CONFLICT DO UPDATE`), aucun événement émis ; documenter en tête pourquoi `paiement.moyens_actifs` est **vide par défaut** (FR-011 interdit de masquer un moyen — ce n'est qu'un coupe-circuit d'exploitation)
- [X] T005 Rendre le crate constructible : `backend/crates/paiements/Cargo.toml` (dépendances `socle`, `zones`, `commandes`, `sqlx`, `reqwest`, `hmac`, `sha2`, `subtle`, `chrono`, `uuid`, `serde`, `thiserror`, `async-trait`, `tracing` — versions figées, constitution X), `src/lib.rs` (table des modules), `src/modele.rs` (types du domaine, `ErreurPaiements` et ses **clés i18n**) ; `cargo build` vert
- [X] T006 Étendre `backend/crates/socle/src/config.rs` : `paiement_fournisseur` (défaut `simule`), `paiement_base_url`, `paiement_cle_api`, `paiement_webhook_secret` — et **la validation qui refuse le démarrage** en mode `agregateur` sans secret ≥ 32 octets (patron `jwt_secret`/`plaque_secret`, FR-045) ; tests unitaires des trois configurations invalides
- [X] T007 [P] Bac de test `backend/api/tests/bac_paiements/mod.rs` sur le patron de `bac_commandes/mod.rs` : app Actix réelle, zone Tiassalé, les 4 paramètres du cycle, un client, un vendeur, un coursier, helpers « commande prépayée créée », « signer une notification » et « porter l'horloge au-delà de l'échéance »
- [X] T008 [P] Clés i18n fr du parcours client dans `apps/mefali_client/lib/l10n/app_fr.arb` : états de paiement, compte à rebours, reprise, annulation par expiration, remboursement à venir, reçu — aucune chaîne en dur ne sera écrite ensuite
- [X] T009 [P] Clés i18n fr des surfaces pro dans `apps/mefali_pro/lib/l10n/app_fr.arb` : « rien à encaisser », explication de la retenue, trois positions de caisse, états de créance, réglage d'offre de livraison, reçu vendeur
- [X] T010 [P] Ajouter `url_launcher: 6.3.2` à `apps/mefali_client/pubspec.yaml` (version alignée sur `mefali_pro`), vérifier la configuration Android (aucune permission nouvelle pour `externalApplication`), figer par lockfile, puis `./scripts/verifier-accord-locks.sh` vert dans les **trois** paquets — et consigner dans le journal du cycle que **cet écran ne sera jamais patchable par Shorebird** (research R17)

**Checkpoint**: schéma en place, événements déclarés, crate qui compile, configuration qui refuse de démarrer à moitié. Aucune logique encore.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: la frontière fournisseur et le dépôt. Toutes les stories en dépendent : sans le trait et son double, rien n'est exerçable sans réseau.

**⚠️ CRITIQUE** : aucune story ne démarre avant la fin de cette phase.

- [X] T011 Trait `PaymentProvider` et ses types neutres dans `backend/crates/paiements/src/fournisseur/mod.rs` : `create_checkout`, `verify_webhook` (**synchrone**), `refund`, `consulter` ; `DemandeCheckout`, `Checkout`, `NotificationEntrante`, `Notification`, `IssuePaiement`, `MoyenPaiement`, `ErreurFournisseur` — signatures exactes de [`contracts/ports-paiements.md`](./contracts/ports-paiements.md) §1, **montants en `i64` d'unités mineures**, zéro nom de fournisseur
- [X] T012 `FournisseurSimule` dans `backend/crates/paiements/src/fournisseur/simule.rs` : pilotable par scénario — succès, échec, `en_cours`, signature invalide, montant divergent, devise divergente, indisponibilité, latence — plus un signataire de test réutilisable par le bac d'API (FR-044) ; tests unitaires de chaque scénario
- [X] T013 [P] Port `CommandesAPayer` (+ double `CommandesAPayerEnMemoire`) dans `backend/crates/commandes/src/ports.rs` : `a_payer`, `marquer_paiement_en_attente`, `confirmer_prepaiement`, `annuler_pour_expiration` — signatures de [`contracts/ports-paiements.md`](./contracts/ports-paiements.md) §2 ; tests unitaires du double
- [X] T014 Implémenter `CommandesAPayer` pour `PgCommandes` dans `backend/crates/commandes/src/depot.rs` : `marquer_paiement_en_attente` pose enfin `etat_paiement = 'en_attente'` (**valeur d'enum présente depuis 0008 et jamais écrite**, research R16), `annuler_pour_expiration` **réutilise** le chemin d'annulation existant avec son motif tracé — aucune seconde règle d'annulation (FR-032) ; `cargo sqlx prepare`
- [X] T015 `PgPaiements` dans `backend/crates/paiements/src/depot.rs` : accès aux trois tables, `maintenant()` piloté par l'horloge serveur, lecture des 4 paramètres de zone avec leurs gardes ; `cargo sqlx prepare` et `cargo build` verts
- [X] T016 Machine à états de la transaction dans `backend/crates/paiements/src/modele.rs` : table fermée des transitions autorisées (`ouverte → reglee|echouee|expiree`, `echouee → ouverte`, `expiree → payee_hors_delai`, `reglee` **terminal**), patron `commandes::etats::verifier_transition` ; tests unitaires exhaustifs, **y compris les transitions interdites** (FR-034)
- [X] T017 Câbler le fournisseur dans `backend/api/src/lib.rs` : sélection `simule` / `agregateur` depuis la configuration, `Arc<dyn PaymentProvider>` injecté, trace au démarrage nommant le fournisseur actif (patron des messages « pipeline DSP câblé ») ; `cargo build` vert

**Checkpoint**: le domaine sait ouvrir un encaissement et vérifier une notification, sans qu'aucun fournisseur réel n'existe. Les stories peuvent démarrer.

---

## Phase 3: User Story 1 — Payer d'avance sans quitter le parcours (Priority: P1 — produit P0) 🎯 MVP

**Goal**: une commande au-dessus du plafond cash trouve un moyen d'être payée, et repart au dispatch dès la confirmation.

**Independent Test**: créer une commande dépassant le plafond, suivre l'accès retourné, faire confirmer par le double, vérifier que la commande est `nouvelle` avec `etat_paiement = 'regle'` et qu'elle est visible du dispatch.

- [X] T018 [US1] `backend/crates/paiements/src/session.rs` : ouverture **idempotente** — une seule transaction vivante par commande (index partiel de T003), échéance calculée depuis `paiement.session_duree_s`, appel `create_checkout` **hors** de la transaction SQL (research R2), écriture `paiement.session_ouverte` dans la même transaction que la ligne ; tests unitaires du double appel et de l'échéance
- [X] T019 [US1] Endpoint `POST /commandes/{id}/paiement` dans `backend/api/src/paiements_http.rs` (nouveau module) : garde de rôle **et** de propriété, `409 paiement_non_requis` sur une commande cash ou déjà réglée, `502 fournisseur_indisponible` sans laisser la commande dans un état bancal (FR-018) — puis annotations `#[utoipa::path]` à jour, `./scripts/generate-clients.sh`, `git diff --exit-code clients/` vide, `cargo build` vert
- [X] T020 [P] [US1] Endpoint `GET /commandes/{id}/paiement` dans `backend/api/src/paiements_http.rs` : état, `restant_s` calculé **côté serveur** (l'horloge de l'app ne décide de rien), `acces_paiement` à `null` dès que l'état quitte `ouverte`, `404` sur une commande cash — puis utoipa + régénération des clients + `git diff --exit-code clients/` vide + build vert
- [X] T021 [US1] `backend/crates/paiements/src/webhook.rs` — **chemin nominal seulement** : notification `Reussi` valide → `confirmer_prepaiement` + `paiement.confirme` dans la même transaction SQL (FR-023). Le durcissement (signature, rejeu, divergences) est US3 : ici, le double signe correctement et le montant correspond
- [X] T022 [US1] Endpoint `POST /paiements/notifications/{fournisseur}` dans `backend/api/src/paiements_webhook_http.rs` (nouveau module) : corps reçu en `web::Bytes` **brut** (jamais `web::Json`), fournisseur inconnu → `404`, enregistré dans les deux points de montage de routes — puis utoipa + régénération des clients + build vert
- [X] T023 [US1] Test d'intégration `backend/api/tests/paiements_session.rs` : parcours nominal complet, idempotence du `POST` (deux appels → une transaction), `403` pour un autre client, `409` sur commande cash, et **la commande confirmée est bien reprise par le dispatch** (`commande.paiement_confirme` est déjà consommé par `DispatchOutbox` depuis le cycle 009 — vérifier, ne rien câbler)
- [X] T024 [US1] État Flutter `apps/mefali_client/lib/paiement/etat_session_paiement.dart` : `Notifier<EtatSessionPaiement>` **généré** (`@Riverpod(keepAlive: true)`, `retry: pasDeRetry`), compte à rebours local recalé sur `restant_s` du serveur à chaque lecture ; `build_runner` + `dart analyze`
- [X] T025 [US1] Écran de paiement `apps/mefali_client/lib/paiement/ecran_paiement.dart` : montant, compte à rebours, bouton d'ouverture, état en clair — motifs empruntés au bandeau d'état de `docs/design/png/C4-suivi-commande.png` et aux blocs de montant de `docs/design/png/C3-panier-multi-vendeurs.png`, valeurs de `docs/design/tokens.md` ; **écart assumé** : aucune planche de paiement n'existe
- [X] T026 [US1] Ouverture de l'accès via `url_launcher` en `LaunchMode.externalApplication` et **retour par relecture d'état** dans `apps/mefali_client/lib/paiement/ecran_paiement.dart` : le retour de navigateur ne crédite **rien** (FR-025) ; test widget du chemin « revenu sans confirmation »
- [X] T027 [US1] Brancher la création de commande sur la session dans `apps/mefali_client/lib/panier/etat_confirmation.dart` : quand `etat == "en_attente_paiement"`, enchaîner sur `POST /commandes/{id}/paiement` et router vers l'écran de paiement — sans jamais bloquer l'UI en attente d'une notification (FR-090) ; `build_runner` + `dart analyze`
- [X] T028 [US1] Bandeau de paiement dans le suivi `apps/mefali_client/lib/parcours/pages_commande.dart` : état, temps restant, bouton « reprendre le paiement » tant que la session vit (FR-016, FR-017) — réf. `docs/design/png/C4-suivi-commande.png`

**Checkpoint**: Awa paie d'avance, sa commande part. C'est le MVP — `quickstart.md` §3.1 doit passer sur appareil.

---

## Phase 4: User Story 2 — La commande fantôme n'existe pas (Priority: P2 — produit P0)

**Goal**: une session abandonnée annule sa commande, sans frais, et Awa le sait.

**Independent Test**: créer une commande prépayée, ne rien confirmer, porter l'horloge au-delà de l'échéance, déclencher le balayage, vérifier l'annulation, son motif, son caractère sans frais et l'événement de notification.

- [X] T029 [US2] `backend/crates/paiements/src/expiration.rs` : sélection des sessions échues, **appel `consulter` avant toute annulation** (FR-027) — un succès rattrapé confirme au lieu d'annuler —, puis `annuler_pour_expiration` + `paiement.session_expiree` dans la même transaction ; tests unitaires des deux issues
- [X] T030 [US2] Job `job_expirer_sessions` dans `backend/api/src/lib.rs` : `tokio::spawn`, constante `BALAYAGE_SESSIONS_PAIEMENT = 10 s` documentée sur le modèle de `BALAYAGE_SUBSTITUTIONS` (**le job matérialise, il n'est pas la source de vérité — l'échéance est persistée**), une erreur journalisée ne fait jamais tomber l'API
- [X] T031 [US2] Refus de paiement après échéance dans `backend/crates/paiements/src/session.rs` et l'endpoint `POST /commandes/{id}/paiement` : `409 session_expiree` avec sa clé i18n, proposition de recommander (FR-035) — puis utoipa + régénération des clients + build vert
- [X] T032 [US2] Test d'intégration `backend/api/tests/paiements_expiration.rs` : annulation sans frais et sans part coursier due, `paiement.session_expiree` écrit **une** fois, **une commande réglée à la 14ᵉ minute n'est pas annulée à la 16ᵉ** (FR-034), et le cas « `consulter` répond réussi » confirme la commande
- [X] T033 [P] [US2] Affichage de l'annulation par expiration dans `apps/mefali_client/lib/parcours/pages_commande.dart` : motif en clair, **sans jargon de paiement**, action « recommander » qui repart du panier — réf. `docs/design/png/C4-suivi-commande.png`
- [X] T034 [P] [US2] Tests widget `apps/mefali_client/test/paiement/` : le compte à rebours s'arrête à zéro sans figer l'écran, l'état bascule sur annulation, le bouton de reprise disparaît

**Checkpoint**: plus aucune commande n'attend éternellement. Le dispatch et les métriques cessent d'être pollués.

---

## Phase 5: User Story 3 — Une notification signée, comptée une seule fois (Priority: P3 — produit P0)

**Goal**: le webhook devient hostile-résistant — signature, rejeu, concurrence, divergences, retard.

**Independent Test**: rejouer une notification valide 10 fois, en poster une à signature invalide, en poster deux concurrentes, et vérifier qu'il n'existe qu'une confirmation, un événement, une transition.

- [X] T035 [US3] Vérification de signature dans `backend/crates/paiements/src/fournisseur/signature.rs` : HMAC-SHA256 sur le **corps brut**, comparaison en temps constant (`subtle`), tolérance d'horodatage ±5 min, secret depuis la configuration ; tests unitaires — signature absente, tronquée, d'un autre secret, périmée
- [X] T036 [US3] Idempotence dans `backend/crates/paiements/src/webhook.rs` : `INSERT … ON CONFLICT DO NOTHING RETURNING id` sur `notification_recue`, puis `SELECT … FOR UPDATE` sur la transaction ; un rejeu répond `{"traite": false, "motif": "rejeu"}` **sans erreur** (FR-021, FR-022) ; `cargo sqlx prepare`
- [X] T037 [US3] Contrôle du montant et de la devise dans `backend/crates/paiements/src/webhook.rs` : divergence → **aucune confirmation** + `paiements.dossier` (`montant_divergent` ou `devise_divergente`) + `paiement.dossier_ouvert` (FR-024) ; `backend/crates/paiements/src/dossier.rs` créé ici
- [X] T038 [US3] Notification de succès **après expiration** dans `backend/crates/paiements/src/webhook.rs` : transaction → `payee_hors_delai`, dossier `paiement_hors_delai`, `paiement.hors_delai` émis pour NTF, **commande intouchée** (FR-036 → FR-038, research R8) ; tests unitaires
- [X] T039 [US3] Notification d'échec : la commande **reste en attente** jusqu'à l'échéance, `paiement.echoue` émis, réessai permis sur la même session (FR-026) — `backend/crates/paiements/src/webhook.rs`
- [X] T040 [US3] Durcissement de l'endpoint dans `backend/api/src/paiements_webhook_http.rs` : corps plafonné à **64 Kio**, limitation de débit par IP (patron OTP du cycle 003), refus `401` journalisé **sans le corps**, exclusion de Swagger UI en production — puis utoipa + régénération des clients + build vert
- [X] T041 [US3] Test d'intégration `backend/api/tests/paiements_webhook.rs` : **rejeu ×10 → 1** confirmation / 1 événement / 1 transition (SC-003), **100 signatures invalides → 0** effet et 100 traces de refus (SC-004), deux notifications concurrentes → un seul effet
- [X] T042 [P] [US3] Test d'intégration `backend/api/tests/paiements_hors_delai.rs` : succès tardif → commande toujours annulée, transaction `payee_hors_delai`, dossier ouvert, `paiement.hors_delai` écrit une seule fois
- [X] T043 [P] [US3] Test de non-fuite `backend/api/tests/paiements_secrets.rs` : ni `acces_paiement`, ni signature, ni identifiant de session complet dans un événement outbox, une réponse d'API ou un log capturé (FR-006, FR-103)

**Checkpoint**: l'argent ne se duplique pas et ne s'invente pas. Le cœur risqué du cycle est clos.

---

## Phase 6: User Story 4 — Ce que Yao sort de sa poche, au franc près (Priority: P4 — produit P0)

**Goal**: la chaîne cash est complète au livre — avances, encaissement du total en une fois, frais encaissés — et une commande prépayée ne réclame plus rien.

**Independent Test**: dérouler une course cash à deux arrêts avec un article retiré et un arrêt indisponible, puis la remise ; comparer le livre ligne à ligne avec le cash réellement manipulé.

- [X] T044 [US4] **Corriger le montant à encaisser** dans `backend/crates/commandes/src/suivi.rs` : `montant_a_encaisser_unites` vaut `0` quand `mode_paiement <> 'cash'` (aujourd'hui il vaut `total_unites` **quel que soit le mode** — ligne 555, research R11) ; `cargo sqlx prepare` — puis utoipa + régénération des clients + build vert
- [X] T045 [US4] **Corriger `commande.terminee`** dans `backend/crates/commandes/src/collecte.rs` : séparer `total_du` (le total figé, ajusté par les retraits) de `total_encaisse` (`0` si prépayé) — ligne 767 ; mettre à jour la charge utile dans `docs/taxonomie-evenements.md` (déjà annoncée en T001)
- [X] T046 [US4] Écriture `frais_encaisses` dans `backend/crates/coursier/src/caisse.rs` : à `livraison.livree` **cash**, montant = `total_du_client − Σ avances` (**et non `devis_prix_client`** — research R13, la formule naïve est fausse dès que la retenue joue), à côté du `remboursement` existant ; `evenement_id` distinct pour rester idempotent
- [X] T047 [US4] Tests unitaires du calcul dans `backend/crates/coursier/src/caisse.rs` : les quatre cas de la table de research R13 (cash ordinaire, cash + retenue, cash + promo Mefali, prépayé) — c'est **ce test** qui a fait rejeter la première formule
- [X] T048 [US4] Test d'intégration `backend/api/tests/coursier_chaine_cash.rs` : course à 2 arrêts, une ligne retirée, un arrêt indisponible, remise cash → le livre porte exactement `avance ×2`, `remboursement`, `frais_encaisses`, et le montant encaissé égale le total dû **recalculé** (FR-054, FR-055)
- [X] T049 [P] [US4] App coursier — **« rien à encaisser »** sur commande prépayée dans `apps/mefali_pro/lib/coursier/remise/ecran_confirmation.dart` et `apps/mefali_pro/lib/coursier/course/bandeau_livraison.dart` : formulation sans ambiguïté possible avec un encaissement oublié (FR-093, SC-012) — réf. `docs/design/png/K4-confirmation-livraison.png`
- [X] T050 [P] [US4] App coursier — historique de caisse enrichi dans `apps/mefali_pro/lib/coursier/caisse/` : les trois nouvelles natures d'écriture affichées avec leur sens (entrée / sortie) et leur motif — réf. `docs/design/png/K5-caisse-historique.png`
- [X] T051 [P] [US4] Tests widget `apps/mefali_pro/test/coursier/` : une course prépayée n'affiche **jamais** un montant à réclamer ; l'historique distingue les six natures d'écriture

**Checkpoint**: le livre dit ce que Yao a vraiment en poche, cash comme prépayé.

---

## Phase 7: User Story 5 — La retenue de la livraison offerte, visible des deux côtés (Priority: P5 — produit P0)

**Goal**: un vendeur peut offrir la livraison ; le coursier paie « articles − frais » et les deux reçus l'expliquent.

**Independent Test**: déclarer l'offre, drapeau de zone au repos, passer une commande mono-vendeur ; vérifier l'avance nette au scan, la retenue aux deux reçus, et l'absence totale de retenue sur un panier multi-vendeurs.

- [X] T052 [US5] Lecture `offre_livraison` dans `backend/crates/prestataires/src/depot.rs` : rend `Option<tarification::OffreLivraison>` (`None` = jamais), le type existant du cycle 007 traverse tel quel ([`contracts/ports-paiements.md`](./contracts/ports-paiements.md) §3) ; `cargo sqlx prepare` ; tests unitaires des trois valeurs
- [X] T053 [US5] Endpoints `PUT /vendeur/prestataires/{id}/offre-livraison` dans `backend/api/src/vendeur_http.rs` et son miroir `PUT /admin/prestataires/{id}/offre-livraison` dans `backend/api/src/admin_prestataires_http.rs` : `400 offre_seuil_manquant` sans seuil > 0 en mode `au_dela`, événement `vendeur.offre_livraison_modifiee` — puis utoipa + régénération des clients + `git diff --exit-code clients/` vide + build vert
- [X] T054 [US5] Brancher l'offre au devis dans `backend/crates/commandes/src/panier.rs` : remplacer `offre_livraison_vendeur: None` (ligne 423) par la lecture de T052, **uniquement si le panier est mono-vendeur** — l'arbitrage avec le drapeau de zone reste entier dans `tarification` (research R9, R10) ; `cargo sqlx prepare`
- [X] T055 [US5] Retenue au scan dans `backend/crates/commandes/src/depot.rs` (`marquer_arret_collecte`) : lire `devis_composantes->>'retenue_vendeur'`, n'appliquer que si la livraison n'a **qu'un** arrêt de collecte, écrêter à zéro, renseigner les 3 colonnes de T003, enrichir `arret.collecte` des 3 propriétés (FR-050 → FR-052) ; `cargo sqlx prepare`
- [X] T056 [US5] Tests d'intégration `backend/api/tests/commandes_retenue_vendeur.rs` : avance nette conforme, **aucune retenue en multi-vendeurs**, **le drapeau de zone prime** sur l'offre vendeur, retenue > articles → avance nulle jamais négative et `retenue_ecretee = true`, aucune commande antérieure retarifée (FR-048, FR-051, FR-052)
- [X] T057 [US5] Consommateur `PaiementsOutbox` dans `backend/crates/paiements/src/dossier.rs` + adaptateur dans `backend/api/src/lib.rs` : `arret.collecte` avec `retenue_ecretee` → dossier `retenue_ecretee` ; `commande.annulee` avec `remboursement_du` → dossier `remboursement_client_du` — **ne rend `Err` que sur une panne d'infrastructure** (patron `DispatchOutbox`, sinon l'événement bloque sa ligne d'outbox à jamais)
- [X] T058 [US5] Endpoint `GET /commandes/{id}/recu` dans `backend/api/src/paiements_http.rs` : lignes à prix verrouillés (retirées incluses avec leur statut, **hors montants**), frais, retenue, mode, moyen, `deja_regle`, montant à remettre au coursier — aucune recopie en table (research R15) — puis utoipa + régénération des clients + build vert
- [X] T059 [US5] Endpoint `GET /vendeur/arrets/{arret_id}/recu` dans `backend/api/src/vendeur_http.rs` : articles, retenue, net versé — **les mêmes trois chiffres** que le reçu client, garde de propriété sur le prestataire — puis utoipa + régénération des clients + build vert
- [X] T060 [US5] Test d'intégration `backend/api/tests/paiements_recus.rs` : les deux reçus affichent des montants **identiques** au franc près, le reçu d'une commande prépayée porte `deja_regle: true` et `montant_a_remettre = 0`, `403` croisés (SC-009, FR-073)
- [X] T061 [P] [US5] App coursier — montant net **et son explication** sur la carte d'arrêt dans `apps/mefali_pro/lib/coursier/course/carte_arret.dart` : « Articles 3 000 − Livraison offerte 500 = **2 500 à payer** » (FR-092) — réf. `docs/design/png/K3-course-active.png` état 1a
- [X] T062 [P] [US5] App vendeur — réglage de l'offre de livraison dans `apps/mefali_pro/lib/vendeur/` : trois choix, saisie du seuil, rappel explicite que les commandes en cours ne changent pas — réf. `docs/design/png/V1-statut-boutique.png` (motifs de réglage) ; **écart assumé** : le badge client relève de VND-08
- [X] T063 [P] [US5] App vendeur — reçu d'un arrêt collecté dans `apps/mefali_pro/lib/vendeur/recu_arret.dart` : les trois montants, motif de retenue en clé i18n — réf. `docs/design/png/V3-commande-entrante.png`
- [X] T064 [P] [US5] App cliente — reçu de commande dans `apps/mefali_client/lib/parcours/recu_commande.dart` : détail des lignes, frais, retenue le cas échéant, « déjà réglé » si prépayée — réf. `docs/design/png/C4-suivi-commande.png`

**Checkpoint**: la retenue existe pour de vrai, et personne n'a à faire le calcul de tête.

---

## Phase 8: User Story 6 — Personne ne détient l'argent d'un autre sans que ça se voie (Priority: P6 — produit P0)

**Goal**: les créances naissent seules, les trois positions sont exactes à chaque état, et l'exploitation voit tout.

**Independent Test**: parcourir les dix états de commande et vérifier que la ventilation équilibre à l'unité près ; régler une créance et constater le mouvement au livre.

- [X] T065 [US6] Création **automatique** des créances dans `backend/crates/coursier/src/caisse.rs` : à `livraison.livree`, remplacer le `return Ok(())` documenté « avance laissée ouverte » par la création de `avance_prepayee` (Σ avances, si prépayée) et `part_course` (formule de research R13, si > 0) — `evenement_id UNIQUE` porte l'idempotence (FR-063, FR-068) ; `cargo sqlx prepare`
- [X] T066 [US6] Règlement d'une créance dans `backend/crates/coursier/src/caisse.rs` : `due → reglee` **et** écriture `reglement` (+montant) dans la **même** transaction, `caisse.creance_reglee` émis, second appel refusé — une erreur se corrige par une écriture **inverse**, jamais par un retour arrière (FR-064, FR-067)
- [X] T067 [US6] Les trois positions dans `backend/crates/coursier/src/caisse.rs` (`vue_caisse`) : avancé non récupéré (existant), dû par Mefali (Σ créances dues), détenu pour Mefali (`Σ min(frais_encaisses, devis_marge) − Σ reversements`) — **aucune table de solde** (FR-061) ; `cargo sqlx prepare`
- [X] T068 [US6] Test d'intégration `backend/api/tests/coursier_positions.rs` — **le test qui fait foi du cycle** : les **dix** états de [data-model.md](./data-model.md) §5, ventilation équilibrée **sans écart d'une seule unité mineure**, et les quatre chemins de livraison convergeant sur le même gain (SC-006)
- [X] T069 [US6] Test d'intégration `backend/api/tests/coursier_creances.rs` : créance créée **sans intervention humaine**, rejeu de la fin de course depuis la file hors-ligne → **aucune** créance supplémentaire, règlement → écriture au livre + solde remonté, second règlement → `409` (SC-008)
- [X] T070 [US6] `GET /moi/caisse` enrichi dans `backend/api/src/coursier_http.rs` : bloc `positions` et liste `creances`, **champs additifs** — l'app livrée continue de fonctionner pendant la transition — puis utoipa + régénération des clients + build vert
- [X] T071 [US6] Endpoints d'exploitation `GET /admin/creances` et `POST /admin/creances/{id}/regler` dans `backend/api/src/admin_paiements_http.rs` (nouveau module) : filtres état/coursier, total dû, motif de règlement obligatoire — puis utoipa + régénération des clients + build vert
- [X] T072 [US6] Endpoints `GET /admin/paiements/transactions`, `GET /admin/paiements/dossiers`, `POST /admin/paiements/dossiers/{id}/clore` dans `backend/api/src/admin_paiements_http.rs` : filtres état/moyen/zone/période, drapeau `orpheline`, clôture motivée — puis utoipa + régénération des clients + build vert
- [X] T073 [US6] Test d'intégration `backend/api/tests/paiements_registre.rs` : rapprochement exact **dans les deux sens** (SC-011), les quatre familles d'anomalies visibles avec leur motif, `403` pour un rôle non admin
- [X] T074 [P] [US6] App coursier — caisse à trois positions dans `apps/mefali_pro/lib/coursier/caisse/ecran_caisse.dart` : les trois chiffres lisibles d'un coup d'œil, chaque créance avec son état de règlement (FR-094) — réf. `docs/design/png/K5-caisse-historique.png`
- [X] T075 [P] [US6] Tests widget `apps/mefali_pro/test/coursier/caisse/` : les trois positions s'affichent séparément, une créance réglée se distingue d'une créance due, un solde négatif reste lisible

**Checkpoint**: « où est cet argent ? » a une réponse pour n'importe quelle commande, à n'importe quel état.

---

## Phase 9: User Story 7 — Changer d'agrégateur sans toucher au métier (Priority: P7 — produit P0)

**Goal**: la réversibilité du choix d'agrégateur cesse d'être une affirmation et devient une mesure.

**Independent Test**: faire passer à un second double, au vocabulaire et aux signatures différents, la totalité de la suite de tests de paiement — sans modifier une règle métier.

- [X] T076 [US7] `AgregateurHttp` dans `backend/crates/paiements/src/fournisseur/agregateur.rs` : client `reqwest` paramétré (base, clé, secret, en-tête de signature), délais d'attente et politique de reprise, traduction des codes d'état vers `ErreurFournisseur`, **montants transmis en entiers** ; tests unitaires avec serveur HTTP bouchon
- [X] T077 [US7] `refund` **définie, jamais appelée** dans `backend/crates/paiements/src/fournisseur/agregateur.rs` et `simule.rs` : implémentée pour honorer PAY-05, sans aucun appelant dans le produit — un test vérifie qu'**aucun chemin de code ne l'invoque** (FR-041, FR-111)
- [X] T078 [US7] `FournisseurAlternatif` dans `backend/crates/paiements/tests/fournisseur_alternatif.rs` : vocabulaire, algorithme de signature et codes d'état **différents**, puis rejeu de la totalité de la suite de paiement à travers lui (SC-010)
- [X] T079 [US7] Contrôle mécanique de la frontière dans `scripts/verifier-frontiere-paiement.sh`, appelé par `.github/workflows/backend.yml` : échoue si un nom d'agrégateur (CinetPay, PayDunya, Bizao, HUB2) ou un moyen propriétaire apparaît hors de `backend/crates/paiements/src/fournisseur/` (SC-010, FR-003)
- [X] T080 [US7] Documenter la procédure de bascule dans `backend/crates/paiements/README.md` : ce qu'il faut changer pour brancher l'agrégateur retenu, ce qu'il ne faut **jamais** toucher, et le point d'accroche du routage par moyen de phase 2+ (segment `{fournisseur}` du webhook, **sans règle aujourd'hui** — FR-043, FR-113)

**Checkpoint**: le choix de l'agrégateur peut se faire — et se défaire — sans rouvrir la chaîne d'argent.

---

## Phase 10: Polish & Cross-Cutting Concerns

- [ ] T081 [P] Non-régression complète : `cargo test` depuis `backend/` sur tout le workspace, en vérifiant que les cycles 006 → 010 restent verts — en particulier `backend/crates/coursier/tests/` et `backend/api/tests/coursier_caisse.rs`, dont la sémantique s'est **élargie** sans changer
- [ ] T082 [P] `dart analyze` (jamais `flutter analyze`) et `flutter test` verts dans `apps/mefali_client`, `apps/mefali_pro`, `apps/packages/mefali_core` ; `./scripts/verifier-accord-locks.sh` vert dans les trois paquets
- [ ] T083 [P] `./scripts/generate-clients.sh` puis `git diff --exit-code clients/` **vide** — déterminisme vérifié par deux exécutions successives (la CI `contrat-clients` échoue sinon)
- [ ] T084 [P] Mettre à jour `CLAUDE.md` : le nouveau plugin natif de `mefali_client` (`url_launcher`, **non patchable par Shorebird**), les 4 variables d'environnement `PAIEMENT_*`, et le fait que l'API refuse de démarrer en mode `agregateur` sans secret
- [ ] T085 Validation sur appareil selon [`quickstart.md`](./quickstart.md) §4 : les **8 gestes**, dont le navigateur qui s'ouvre sur tous les moyens, l'app tuée pendant le paiement, l'expiration vue à l'écran, et « rien à encaisser » sur une course prépayée — consigner les écarts constatés dans un `rapport-ecarts.md` (patron du cycle 010, dont la seconde passe avait trouvé 9 défauts)
- [ ] T086 **Revue Definition of Done** (`docs/user-stories-v2.md` §0.4), point par point et par écrit : (1) critères d'acceptation couverts par des tests unitaires **et** d'intégration sur les transitions ; (2) annotations utoipa à jour et clients Dart/TS régénérés **sans diff manuel** ; (3) migrations `0020`/`0021` versionnées et seed `90_paiements_parametres.sql` à jour ; (4) événement outbox pour **tout** changement d'état métier + événements de taxonomie MET-01 pour le parcours client ; (5) clés i18n fr externalisées — **aucune chaîne en dur**, y compris les motifs de dossier et de refus ; (6) les 4 paramètres « paramétrables » exposés en configuration de zone héritée. Toute case non cochable est soit corrigée, soit consignée comme réserve explicite — jamais laissée implicite

---

## Dependencies & Execution Order

### Dépendances de phase

- **Phase 1 (Setup)** : aucune dépendance — démarrable immédiatement. T001 **avant** toute émission d'événement ; T002 **avant** T003 (piège `ALTER TYPE`, research R21).
- **Phase 2 (Foundational)** : dépend de la Phase 1 — **bloque toutes les stories**. Sans le trait et son double, rien n'est exerçable sans réseau.
- **Phases 3 → 9 (Stories)** : toutes dépendent de la Phase 2.
- **Phase 10 (Polish)** : dépend de toutes les stories retenues. T086 est **la dernière tâche du cycle**.

### Dépendances entre stories

- **US1** : indépendante après la Phase 2 — c'est le MVP.
- **US2** : dépend d'US1 (il faut une session pour qu'elle expire).
- **US3** : dépend d'US1 (elle durcit le webhook que T021/T022 ont posé) et d'US2 (le cas hors délai suppose l'expiration).
- **US4** : **indépendante d'US1/US2/US3** — la chaîne cash ne passe par aucun fournisseur. Elle peut être menée en parallèle du prépaiement.
- **US5** : dépend d'US4 (elle modifie l'avance au scan que la chaîne cash consomme).
- **US6** : dépend d'US4 (les écritures) **et** d'US1 (la commande prépayée qui crée les créances).
- **US7** : dépend d'US1 → US3 (c'est leur suite de tests qu'elle rejoue).

### Parallélisation

- Phase 1 : T004, T007, T008, T009, T010 en parallèle après T002/T003.
- Phase 2 : T013 en parallèle de T011/T012.
- **Entre stories** : le chantier cash (US4 → US5) et le chantier prépaiement (US1 → US2 → US3) ne se touchent qu'en US6. Deux personnes, ou deux séquences, sans conflit de fichiers.

```bash
# Après la Phase 2, deux chantiers indépendants :
Tâche: "T018-T043  US1 → US3 — prépaiement, expiration, webhook durci"
Tâche: "T044-T064  US4 → US5 — chaîne cash et retenue"
# Puis convergence :
Tâche: "T065-T075  US6 — positions et créances"
```

---

## Implementation Strategy

### MVP (US1 seule)

1. Phase 1 (Setup) → 2. Phase 2 (Foundational, **bloquante**) → 3. Phase 3 (US1)
4. **STOP et VALIDER** : `quickstart.md` §3.1 sur appareil — Awa paie une commande au-dessus du plafond et la voit partir au dispatch.

⚠ Ne pas mettre ce MVP en production seul : sans US2, une session abandonnée
laisse une commande en attente indéfiniment ; sans US3, un rejeu de webhook n'est
pas garanti sans effet. **US1 + US2 + US3 forment le plus petit ensemble
livrable** en production.

### Livraison incrémentale

1. Setup + Foundational → la frontière fournisseur existe, sans fournisseur réel
2. + US1 → **MVP démontrable** : le prépaiement fonctionne
3. + US2 → plus de commande fantôme
4. + US3 → **plus petit ensemble déployable** : le webhook résiste au rejeu et à la fraude
5. + US4 → le livre dit ce que Yao a vraiment en poche
6. + US5 → la retenue existe, expliquée des deux côtés
7. + US6 → « qui détient quoi » a une réponse à chaque état
8. + US7 → l'agrégateur peut être choisi, et changé

### Notes

- Une tâche qui déborde de la journée se **scinde** ; elle ne s'étire pas.
- Commit conventionnel par tâche ou groupe logique, référençant la story :
  `feat(paiements): PAY-02 session de prépaiement idempotente`.
- Le commit de fin de cycle mentionne explicitement le **débordement borné sur
  VND-08** (T052 à T054, T062) pour que la story VND-08 sache ce qui lui reste.
- Aucun `.g.dart` ni client généré n'est édité à la main — régénération seulement.
- T047 et T068 sont les deux tâches à ne pas bâcler : ce sont elles qui
  empêchent le livre de mentir.
