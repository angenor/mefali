---
description: "Task list — cycle 008 commandes (cycle de vie complet d'une commande multi-vendeurs)"
---

# Tasks: Cycle de vie complet d'une commande multi-vendeurs

**Input**: Design documents from `specs/008-commandes-cycle-de-vie/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/commandes-openapi.md](./contracts/commandes-openapi.md), [quickstart.md](./quickstart.md)

**Tests** : les tests d'intégration sont **obligatoires** (constitution VII + DoD §0.4.1) — une tâche de test par transition d'état et **une par ligne** du tableau des cas limites du cadrage §7.5. Jamais optionnels ici.

**Organization** : tâches groupées par user story (priorité produit rappelée), **ordonnées par dépendance**. Chaque tâche vise **½ à 1 jour**. Les tâches d'UI d'une story viennent **après** ses tâches d'API : une story n'est close que lorsque son écran fonctionne.

## Règles de ce cycle (imposées)

- **Schéma** : toute tâche touchant le schéma **commence par sa migration sqlx** (nouvelle, jamais modifier une migration appliquée) ; toute tâche ajoutant des requêtes sqlx **se termine par `cargo sqlx prepare`**.
- **API** : toute tâche touchant l'API **se termine par** : annotations `#[utoipa::path]` à jour → `openapi.json` régénéré → clients Dart/TS régénérés **sans diff manuel** (`./scripts/generate-clients.sh`) → **build vert** (constitution I).
- **UI** : toute tâche d'UI **référence sa capture** `docs/design/png/` (C3 panier, C4 suivi) ; widgets Material 3 thémés par `mefali_core` depuis `docs/design/tokens.md` — **jamais** de transposition DOM/CSS de `docs/design/html/` (constitution XI) ; état en **Riverpod codegen** (constitution XII), analyse par `dart analyze`.
- **Événements/i18n/zone** : toute transition → événement outbox **dans la même transaction** + déclaration dans la taxonomie ; toute chaîne utilisateur → clé i18n fr ; tout paramètre « paramétrable » → configuration de zone.
- **Points obligatoires** : **P1** (correction du gating) et **P2** (deux migrations) du [plan §Points obligatoires](./plan.md) ont leurs tâches dédiées — T006 et T004/T005 — et leur vérification finale en T066.

## Path Conventions

Backend Rust : crate `backend/crates/commandes/` (**étendu**, pas de nouveau crate), `backend/crates/comptes/` (restrictions), binaire `backend/api/`, migrations `backend/migrations/`, seeds `backend/seeds/`. Flutter : `apps/mefali_client/`, partagé `apps/packages/mefali_core/`. Clients `clients/dart|ts/` = **régénérés**, jamais édités.

---

## Phase 1: Setup (infrastructure partagée)

- [X] T001 [P] Déclarer les **23 nouveaux événements** du cycle dans `docs/taxonomie-evenements.md` (25 au tableau de [data-model.md §7](./data-model.md), dont **2 déjà déclarés au cycle 006 et inchangés** : `arret.collecte`, `livraison.mise_en_livraison`) : `commande.*`, `livraison.*`, `arret.en_route`/`arret.arrive`/`arret.indisponible`, `substitution.*`, `ligne.retiree`, `appel.intention`, `echec.issue_enregistree`, `litige.ouvert`, `indemnisation.due`, `sanction.posee`, `panier.scission_proposee` — entité, déclencheur, payload **minimisé ARTCI** (aucune coordonnée brute) — **avant** toute implémentation (constitution VI).
- [X] T002 [P] Créer le seed `backend/seeds/60_commandes_parametres.sql` — les **12** paramètres de zone de [data-model.md §6](./data-model.md) (dont `commande.historique_min_commandes_terminees`, défaut 1, qui définit « client sans historique » — FR-024) (`categorie.<slug>.perissable`, plafonds cash, `substitution.delai_validation_s`, `substitution.ecart_prix_max_pourcent`, `commande.repere_texte_min_caracteres`, `suivi.position_periode_s`…), **rejouable et idempotent** ; aucune valeur en dur ailleurs (constitution I).
- [X] T003 [P] Étendre `backend/crates/commandes/Cargo.toml` (deps internes : `zones`, `prestataires`, `tarification`, `qr`, `comptes` ; workspace : `redis`, `serde_json`) et déclarer les nouveaux modules dans `backend/crates/commandes/src/lib.rs` (`etats`, `panier`, `creation`, `substitution`, `annulation`, `echec`, `suivi`, `workflow`). **Aucune nouvelle dépendance tierce** (constitution X).

---

## Phase 2: Foundational (prérequis bloquants — AVANT toute user story)

**⚠️ CRITIQUE** : aucune user story ne démarre avant la fin de cette phase.

- [X] T004 **Migration schéma (1/2)** : créer `backend/migrations/0008_commandes_enums.sql` — **uniquement** les types ([data-model.md §1](./data-model.md)) : `ALTER TYPE … ADD VALUE` sur `statut_arret` (`en_route`, `arrive`) et `etat_livraison` (`assignee`, `livree`, `echouee`, `annulee`), puis `CREATE TYPE` de `etat_commande`, `type_arret`, `preference_substitution`, `statut_ligne`, `issue_substitution`, `mode_paiement`, `etat_paiement`, `type_issue_echec`, `detenteur`, `sanction`. **Aucune table, aucun index, aucune contrainte** : une valeur ajoutée ne peut pas être utilisée dans la transaction qui l'ajoute (**P2**, research R2). Puis `cargo sqlx migrate run`.
- [X] T005 **Migration schéma (2/2)** : créer `backend/migrations/0009_commandes_tronc.sql` — toutes les structures de [data-model.md §2](./data-model.md) : colonnes du tronc `commande` (identité, lieu de prestation dénormalisé, montants, paiement, état, code + jeton + empreintes, `relivraison_de`), colonnes de `livraison` (devis figé, remise), colonnes et contraintes de `arret` (`type_arret`, `en_route_le`, `arrive_le`, `prestataire_id` **nullable** + `CHECK` de cohérence, index unique de remise), tables `ligne_commande`, `resto_details`, `substitution`, `issue_echec`, et les index (`commande_attente_fifo`, `commande_par_client`, `livraison_coursier_active`, `substitution_echeance`). `0001..0007` **intouchées**. Puis `cargo sqlx migrate run` **sur base vierge ET sur une base déjà migrée jusqu'à `0007`** (**P2**, critère (b)), puis `cargo sqlx prepare`.
- [ ] T006 ⚠️ **P1 — non-régression critique** : corriger le **gating `EN_LIVRAISON`** dans `backend/crates/commandes/src/depot.rs` — les comptages de `gating_livraison` et `progression` filtrent désormais `a.type_arret = 'collecte'` ([data-model.md §2.3](./data-model.md), research R4). Sans cette correction, l'arrêt de remise empêche **à jamais** la bascule et aucun test existant ne le signale. Vérifier : (a) `backend/crates/commandes/tests/collecte.rs` du cycle 006 **reste vert sans modification de ses assertions** ; (b) ajouter un test « livraison à 2 collectes + 1 remise » qui bascule dès ses 2 collectes résolues ; (c) la progression annonce « 2 sur 2 », **jamais** « 2 sur 3 ». Puis `cargo sqlx prepare`.
- [X] T007 [P] Types du domaine dans `backend/crates/commandes/src/modele.rs` : `EtatCommande`, `TypeArret`, `PreferenceSubstitution`, `StatutLigne`, `IssueSubstitution`, `ModePaiement`, `EtatPaiement`, `TypeIssueEchec`, `Detenteur`, `Sanction` (patron `comme_str()`/`FromStr` + cast SQL `::text`), et les variantes d'erreur de `ErreurCommandes` avec leur **clé i18n**.
- [X] T008 [P] Table de transitions **fermée** dans `backend/crates/commandes/src/etats.rs` : constante `(niveau, depuis, vers, acteur)` couvrant les trois tables de [data-model.md §3](./data-model.md), et **garde unique** `verifier_transition` refusant tout ce qui n'y figure pas (→ 409). Conserver le chemin `a_collecter → collecte` **direct** du cycle 006 (non-régression).
- [ ] T009 [P] Traits et doubles dans `backend/crates/commandes/src/ports.rs` : `CommandesADispatcher`, `RestrictionsCompte`, `PreuvesEchec`, `PositionCoursier` + les doubles `AffectationSimulee`, `PaiementSimule`, `PreuvesFixes`, `PositionFixe` (patron `ArretsFixes` du cycle 006, research R16).
- [ ] T010 [P] Restrictions CPT-06 dans `backend/crates/comptes/src/restriction.rs` (**nouveau**) : `restrictions(compte)` et `poser_restriction(tx, compte, sanction, motif_cle)` écrivant `prepaiement_impose`/`bloque` (colonnes déjà en base) + événement `sanction.posee` dans la **même transaction** ; exporter dans `lib.rs` ; implémenter `RestrictionsCompte` (research R12, **P3**). Puis `cargo sqlx prepare`.
- [ ] T011 [P] Trait `ServiceWorkflow` et ses deux implémentations dans `backend/crates/commandes/src/workflow.rs` : `RestaurationWorkflow` (mono-vendeur, `resto_details` avec délai de préparation) et `CoursesWorkflow` (multi-vendeurs, aucun détail) — **aucune** spécificité de vertical hors de ce module (constitution II). ⚠️ Les colonnes `acceptee_le` et `refus_motif_cle` de `resto_details` sont des **PROVISIONS** de l'app vendeur (VAP, tranche T4) : **colonnes seules, aucune logique d'acceptation ni de timeout ne doit être écrite ce cycle** (constitution IX).
- [ ] T012 Étendre `PgCommandes` dans `backend/crates/commandes/src/depot.rs` : branchements `ConfigurationZones`, `EvaluationTarifaire`, `OptimisationArrets`, `PgPrestataires`, `RestrictionsCompte`, `DepotObjets` ; convention **lectures sur pool / écritures sur `&mut PgTransaction`** avec outbox dans la même transaction.
- [ ] T013 [P] Étendre la base drift dans `apps/packages/mefali_core/lib/src/offline/action_en_attente.dart` : tables `BrouillonPanier` et `CommandeCache` ([data-model.md §8](./data-model.md)) ; régénérer les `.g.dart` par `build_runner` (commités, jamais édités) ; `dart analyze` vert.
- [ ] T014 [P] Préparer l'i18n du cycle : module d'erreurs `{ code, message_cle }` de l'API (patron `qr_http`) et entrées ARB `commande.*` / `panier.*` / `suivi.*` / `substitution.*` dans `apps/packages/mefali_core/lib/l10n/` — **aucune chaîne en dur** (constitution VII).

**Checkpoint** : socle prêt (schéma, états, ports, gating corrigé) — les user stories peuvent démarrer.

---

## Phase 3: User Story 1 — Composer un panier chez plusieurs vendeurs (CMD-01, Priority: P1 · produit P0) 🎯 MVP

**Goal** : un panier multi-vendeurs regroupé par vendeur, chiffré avant confirmation, avec la règle de mixage et la proposition de scission.

**Independent Test** : composer 12 articles chez 3 vendeurs d'une catégorie mixable (regroupement, sous-totaux, frais détaillés, préférence « m'appeler » par défaut) ; ajouter un plat de restauration → commande refusée, scission proposée et chiffrée ; forcer un détour au-delà du plafond d'éclatement → même proposition. Aucune commande créée.

- [ ] T015 [US1] Regroupement par vendeur et sous-totaux dans `backend/crates/commandes/src/panier.rs` : validation des lignes, résolution de `categorie.<slug>.mixable` via `ConfigurationZones`, garde **mono-vendeur** pour les catégories non mixables (via `ServiceWorkflow::valider_creation`).
- [ ] T016 [US1] Proposition de **scission unifiée** dans `panier.rs` : les deux causes (`categorie_non_mixable`, `plafond_eclatement` lu du drapeau `proposer_scission` du devis) produisent **une seule** proposition portant sa cause et la **prévisualisation chiffrée** des commandes résultantes ; le serveur ne scinde **jamais** d'office (FR-010, research R9).
- [ ] T017 [US1] Endpoint `POST /paniers/devis` dans `backend/api/src/commandes_http.rs` (**nouveau**) : construit la **géométrie** de la course — points de retrait lus des **sites vendeurs** (`prestataires::Site`, un point par vendeur du panier) et point de remise = lieu de prestation fourni par le client — puis appelle `OptimisationArrets` + `EvaluationTarifaire` en renseignant `nb_articles`, `montant_panier`, `categorie_slug` et **`mono_vendeur`** (champ qui active VND-08 côté tarification — FR-014) ; renvoie groupes, montants, devis détaillé, drapeau de paiement et bloc de scission — **sans aucun effet de bord** (aucune écriture, aucun événement — **P4**, research R8) ; garde `Role::Client`. **Terminer par** : `#[utoipa::path]` à jour → `openapi.json` régénéré → clients Dart/TS régénérés (sans diff) → **build vert**.
- [ ] T018 [P] [US1] Tests d'intégration US1 dans `backend/api/tests/commandes_panier.rs` : regroupement et sous-totaux ; préférence par défaut « m'appeler » ; catégorie non mixable → refus + scission proposée ; plafond d'éclatement → même bloc ; **VND-08 mono-vendeur vs multi-vendeurs** ; événement `panier.scission_proposee` émis ; **aucune écriture ni outbox** sur le chemin du devis (**P4**).
- [ ] T019 [US1] UI **panier groupé par vendeur** dans `apps/mefali_client/lib/panier/` — capture `docs/design/png/C3` (cadre **3a**) : carte vendeur avec sous-total, liste d'articles, sélecteur de préférence de substitution par article (défaut « M'appeler »), récapitulatif « Articles / Livraison / Effort de préparation » avec son détail ; composants partagés dans `apps/packages/mefali_core/lib/src/commande/` ; provider `Notifier<EtatPanier>` généré (`keepAlive`, `retry: pasDeRetry`) ; `dart analyze` vert.
- [ ] T020 [US1] UI **scission et hors ligne** dans `apps/mefali_client/lib/panier/` — capture `docs/design/png/C3` (cadres **3d** et **3c**) : bandeau d'avertissement + bouton « Scinder en 2 commandes » + prévisualisation des deux commandes avec la mention des deux frais de déplacement ; hors connexion, brouillon conservé dans `BrouillonPanier` (drift), total **estimé**, action unique en file — aucune commande créée ; `flutter test` (widget) + `dart analyze` verts.

**Checkpoint** : Awa compose et chiffre son panier, la règle de mixage est opposable — démontrable sans aucune autre story.

---

## Phase 4: User Story 2 — Donner une adresse qu'un coursier peut trouver (CMD-02, Priority: P1 · produit P0)

**Goal** : une adresse de livraison exploitable — pin GPS, repère obligatoire texte **ou** vocal, téléphone vérifié.

**Independent Test** : repère texte de 10 caractères → accepté ; repère uniquement vocal de 30 s → accepté, 31 s → refusé ; aucun repère → refusé ; adresse enregistrée réutilisée en un tap avec son vocal ; repère vocal purgé → repère redemandé. Aucune commande créée.

- [ ] T021 [US2] Validation d'adresse de commande dans `backend/crates/commandes/src/creation.rs` : repère **texte ≥ `commande.repere_texte_min_caracteres`** OU **note vocale** présente (durée déjà bornée par le paramètre de zone du cycle 003), **téléphone vérifié** exigé, et **dénormalisation** du pin et du repère sur le tronc (immuabilité — research R3). Erreurs i18n `commande.refus.repere_requis` / `commande.refus.telephone`.
- [ ] T022 [US2] Appel de `comptes::marquer_adresse_utilisee` dans la transaction de création (la rétention repart de cette date) et **redemande de repère** lorsque `repere_vocal_cle_objet` a été purgé et qu'aucun repère texte ne subsiste. Puis `cargo sqlx prepare`.
- [ ] T023 [P] [US2] Tests d'intégration US2 dans `backend/api/tests/commandes_adresse.rs` : les cinq cas d'acceptation/refus du repère ; téléphone non vérifié → 403 ; usage marqué (`derniere_utilisation_le` avancée) ; repère purgé → refus explicite avant confirmation.
- [ ] T024 [US2] UI **adresse et repère** dans `apps/mefali_client/lib/panier/` — capture `docs/design/png/C3` (cadre **3a′**) : carte avec pin déplaçable, bouton « Utiliser ma position actuelle », bascule **Texte / Vocal** avec compteur `0:12 / 0:30 max` et réécoute, réutilisation d'une adresse enregistrée en un tap ; réemploi des composants existants `mefali_core/src/adresses/` (cycle 003) ; `dart analyze` vert.

**Checkpoint** : une adresse trouvable est fournie et validée, réutilisable en un tap.

---

## Phase 5: User Story 3 — Créer la commande : prix verrouillés, devis figé, code et QR (CMD-03 + structure CMD-04, Priority: P1 · produit P0) 🎯 MVP

**Goal** : la commande naît avec sa structure imposée, ses prix verrouillés, son devis figé, et le code + QR remis immédiatement.

**Independent Test** : confirmer un panier de 3 vendeurs → tronc **sans champ logistique**, 1 livraison, 1 segment, 4 arrêts (3 collectes dans l'ordre optimisé + 1 remise), prix verrouillés, devis figé, code + QR retournés ; total au-dessus du plafond → bascule prépaiement ; rejeu de la même clé → une seule commande.

- [ ] T025 [US3] Validations préalables **hors transaction** dans `backend/crates/commandes/src/creation.rs` (étapes 1–5 de [data-model.md §4](./data-model.md)) : refus si compte `bloque` (port `RestrictionsCompte`), résolution de la configuration de zone, validation du panier, **commandabilité de chaque vendeur** (`prestataires::Commandabilite`) et disponibilité de chaque article — refus **avant** tout verrouillage de prix.
- [ ] T026 [US3] Obtention du devis **hors transaction** dans `creation.rs` (étape 6) : même construction de géométrie qu'en T017 (retraits = positions des **sites vendeurs**, remise = lieu de prestation) et mêmes entrées dont **`mono_vendeur`**, puis `OptimisationArrets::optimiser` et `EvaluationTarifaire::evaluer` — l'appel réseau OSRM ne doit **jamais** se faire transaction ouverte (research R11). Le devis obtenu ici est celui qui sera figé en T028 : il DOIT être calculé sur la même géométrie que celle annoncée au panier.
- [ ] T027 [US3] Transaction de création, part tronc, dans `creation.rs` (étapes 7–11) : insertion du tronc avec `id = Idempotency-Key` (conflit → **rejeu idempotent**, research R7), `prestataires::figer_prix` par article → `prix_fige_id`, insertion des `ligne_commande` avec leur préférence, insertion de `resto_details` si le `ServiceWorkflow` l'exige. Puis `cargo sqlx prepare`.
- [ ] T028 [US3] Transaction de création, part logistique, dans `creation.rs` (étapes 12–14) : insertion de la `livraison` avec **copie du devis figé** (montants, composantes, distance, ETA, `degraded`, `proposer_scission`), du `segment` (ordre 0), puis des `arret` — **collectes dans l'ordre optimisé** suivies de l'**arrêt de remise** — et rattachement de chaque ligne à son arrêt. Puis `cargo sqlx prepare`.
- [ ] T029 [US3] Secrets de remise et décision de paiement dans `creation.rs` (étapes 15–16) : code à 4 chiffres et jeton aléatoires **cryptographiques**, empreintes salées via `qr::verification::{empreinte_code, empreinte_jeton}` (research R6) ; cash autorisé si **total** ≤ plafond de zone et compte sans `prepaiement_impose`, plafond réduit pour la **restauration d'un client sans historique** — c'est-à-dire comptant **moins de commandes terminées** que `commande.historique_min_commandes_terminees` (défaut 1 ; les commandes annulées ou échouées ne comptent pas, FR-024) —, sinon `en_attente_paiement` ; événements `commande.creee`, `livraison.creee` et `commande.prete_a_dispatcher` **ou** `commande.paiement_requis`. Puis `cargo sqlx prepare`.
- [ ] T030 [US3] Endpoint `POST /commandes` dans `backend/api/src/commandes_http.rs` : en-tête `Idempotency-Key` **obligatoire**, `201` à la création / `200` au rejeu avec corps identique, les sept refus i18n du [contrat §1.2](./contracts/commandes-openapi.md) ; le code et le jeton ne sont renvoyés qu'au **client propriétaire**. **Terminer par** : `#[utoipa::path]` à jour → `openapi.json` régénéré → clients Dart/TS régénérés (sans diff) → **build vert**.
- [ ] T031 [P] [US3] Tests d'intégration US3 dans `backend/api/tests/commandes_creation.rs` : structure produite (tronc **sans colonne logistique**, 1 livraison, 1 segment, 3 collectes ordonnées + 1 remise) ; prix verrouillés invariants ; devis figé ; **idempotence** (même clé ×2 → une commande, réponses identiques) ; plafonds cash et bascule prépaiement ; compte bloqué → 403 ; vendeur fermé / article indisponible → refus avant verrouillage ; **plafond réduit** appliqué à la 1ʳᵉ commande de restauration puis levé après une commande terminée (FR-024) ; **SC-005** — aucune surface n'accepte un règlement fractionné : une tentative de paiement partiel est refusée et le total reste l'unique montant encaissable.
- [ ] T032 [US3] UI **paiement et confirmation** dans `apps/mefali_client/lib/panier/` — capture `docs/design/png/C3` (cadre **3b**) : cash avec **appoint exact** et mention « préparez l'appoint », cash **grisé avec sa raison** au-dessus du plafond et mobile money présélectionné, puis affichage immédiat du **code à 4 chiffres et du QR** après confirmation (écrits dans `CommandeCache`) ; `flutter test` + `dart analyze` verts.

**Checkpoint** : MVP atteint — Awa compose, adresse, paie et obtient sa commande avec son code et son QR (US1 + US2 + US3).

---

## Phase 6: User Story 4 — Faire avancer la commande sous garde serveur, arrêt par arrêt (CMD-04, Priority: P1 · produit P0)

**Goal** : la machine à états à trois niveaux, gardée serveur, avec la boucle de collecte par arrêt.

**Independent Test** : dérouler une commande à 3 collectes par API (transitions, bascule automatique en livraison, événement outbox à chaque pas) ; tenter une transition hors séquence → refus sans changement d'état ; rejouer une transition → aucun doublon.

- [ ] T033 [US4] Transitions d'arrêt `a_collecter → en_route → arrive` dans `backend/crates/commandes/src/collecte.rs` : garde par `etats::verifier_transition`, horodatage **serveur**, **idempotence par `transition_uuid_client`**, `arrive_le` renseigné (base de la **prime d'attente** TRF-06), événements `arret.en_route` / `arret.arrive` dans la même transaction. Puis `cargo sqlx prepare`.
- [ ] T034 [US4] Arrêt **indisponible** et bascule de livraison dans `collecte.rs` : `arret.indisponible` compté comme **résolu** pour le gating (corrigé en T006), montant avancé nul, puis transitions de livraison `assignee → en_collecte → en_livraison → livree` et transitions du tronc `nouvelle → en_cours → terminee`, chacune gardée et événementée. Puis `cargo sqlx prepare`.
- [ ] T035 [US4] Endpoints coursier dans `backend/api/src/course_http.rs` (**nouveau**) : `POST /courses/{livraison}/arrets/{arret}/en-route`, `.../arrive`, `.../indisponible` — garde `Role::Coursier` **et propriété** (livraison assignée à l'appelant), `uuid_client` + `horodatage_local` exigés, refus `409` sur transition illégale. **Terminer par** : `#[utoipa::path]` à jour → `openapi.json` régénéré → clients Dart/TS régénérés (sans diff) → **build vert**.
- [ ] T036 [P] [US4] Tests d'intégration US4 dans `backend/api/tests/commandes_etats.rs` : **une assertion par ligne** des trois tables de transitions de [data-model.md §3](./data-model.md), plus le **refus** de chaque transition illégale (livrer avant la dernière collecte, annuler une commande livrée, revenir en arrière) ; rejeu d'une transition → effet unique, second événement **absent** ; événement outbox présent pour **chaque** transition acceptée.
- [ ] T037 [P] [US4] Test structurel dans `backend/crates/commandes/tests/tronc.rs` : une commande **sans aucune livraison** est créée et lue sans erreur (composant optionnel 0..n, constitution II) ; aucune colonne logistique n'existe sur le tronc.

**Checkpoint** : le cycle de vie logistique est gardé de bout en bout et prouvé transition par transition.

---

## Phase 7: User Story 5 — Attendre un coursier sans rester dans le noir (CMD-10, Priority: P2 · produit P0)

**Goal** : aucune commande perdue faute de coursier — file FIFO, client informé, reprise automatique.

**Independent Test** : créer une commande sans coursier éligible → état d'attente + délai estimé + annulation sans frais ; trois commandes en attente, un coursier redevient éligible → la plus ancienne reprise en premier, automatiquement.

- [ ] T038 [US5] File d'attente dans `backend/crates/commandes/src/depot.rs` : passage en `en_attente_coursier` (événement `commande.mise_en_attente_coursier`), lecture **FIFO par âge** via l'index partiel `commande_attente_fifo` (aucune table dédiée), reprise automatique à l'affectation, et **escalade** au franchissement de `commande.escalade_attente_coursier_s`. Puis `cargo sqlx prepare`.
- [ ] T039 [US5] Implémenter `CommandesADispatcher` (`en_attente_coursier(zone)`, `affecter(commande, coursier)`) dans `depot.rs` et exposer `GET /admin/commandes/attente` dans `backend/api/src/admin_commandes_http.rs` (**nouveau**, `Role::Admin`, journalisé) — contrat que DSP consommera sans modification. **Périmètre** : cet endpoint est une **surface de lecture seule** servant à observer la file en test et en exploitation ; il ne construit **aucun écran** ADM (l'écran opérations reste au cycle ADM) et peut être différé si l'on préfère n'exercer la file que par le trait. **Terminer par** : `#[utoipa::path]` à jour → `openapi.json` régénéré → clients Dart/TS régénérés (sans diff) → **build vert**.
- [ ] T040 [P] [US5] Tests d'intégration US5 dans `backend/api/tests/commandes_file.rs` (double `AffectationSimulee`) : mise en attente sans coursier éligible ; annulation **sans frais** depuis l'attente ; **ordre FIFO** sur trois commandes d'âges différents ; reprise **automatique** ; événement d'escalade au seuil.

**Checkpoint** : la pénurie de coursier n'est plus une perte de commande.

---

## Phase 8: User Story 6 — Suivre sa commande, même sans réseau (CMD-05, Priority: P2 · produit P0)

**Goal** : un suivi en langage clair, avec progression par arrêt, position datée, et code + QR disponibles **hors ligne**.

**Independent Test** : suivre une commande (stepper, « 2 collectes sur 3 », position < 30 s avec son âge, appel journalisé) ; couper le réseau → QR et code affichés, dernier état connu annoncé comme tel, âge de la position visible.

- [ ] T041 [US6] Vue de suivi dans `backend/crates/commandes/src/suivi.rs` : état en **clé i18n** (`suivi.etat.*`), progression par arrêt (collectes faites / total, **hors remise**), arrêt courant avec le nom du vendeur, substitution en attente le cas échéant. Puis `cargo sqlx prepare`.
- [ ] T042 [US6] Implémenter `PositionCoursier` sur Redis dans `backend/api/src/infra_redis.rs` : lecture de la dernière position et calcul de son **âge en secondes** ; absence de position → `None`, **jamais** une erreur (research R13) ; aucune coordonnée brute journalisée.
- [ ] T043 [US6] Endpoints de suivi dans `backend/api/src/commandes_http.rs` : `GET /commandes/{id}` (garde de **propriété**), `GET /moi/commandes`, `POST /commandes/{id}/appel` (événement `appel.intention`) — le code et le jeton ne sont servis qu'au propriétaire. **Terminer par** : `#[utoipa::path]` à jour → `openapi.json` régénéré → clients Dart/TS régénérés (sans diff) → **build vert**.
- [ ] T044 [P] [US6] Tests d'intégration US6 dans `backend/api/tests/commandes_suivi.rs` (double `PositionFixe`) : progression correcte (la remise n'est jamais comptée comme collecte) ; position **avec son âge** ; absence de position → champ nul sans erreur ; intention d'appel journalisée ; **403** pour un compte non propriétaire.
- [ ] T045 [US6] UI **suivi** dans `apps/mefali_client/lib/commande/` — capture `docs/design/png/C4` (cadres **4a** et **4b**) : stepper « Commande reçue → Collecte en cours *n*/*N* → En route vers vous → Livrée », carte multi-arrêts avec âge de la position, bouton d'appel, bloc « À la livraison » (QR + code) ; état de recherche de coursier avec délai allongé et **annulation sans frais** ; provider `AsyncNotifier` généré ; `dart analyze` vert.
- [ ] T046 [US6] UI **suivi hors ligne** dans `apps/mefali_client/lib/commande/` — capture `docs/design/png/C4` (cadre **4d**) : bandeau « Hors connexion », **dernier état connu** annoncé comme tel, âge de la position figée, bloc « À la livraison — disponible sans réseau » rendu **uniquement** depuis `CommandeCache` (drift) — **aucun appel réseau** sur ce chemin ; `flutter test` (widget, mode hors ligne) + `dart analyze` verts.

**Checkpoint** : Awa n'a jamais besoin d'internet au moment de la remise.

---

## Phase 9: User Story 7 — Gérer un article manquant sans casser la commande (CMD-06, Priority: P2 · produit P0)

**Goal** : une rupture applique la préférence de l'article, chez le même vendeur, sans jamais faire varier les frais ni fractionner le paiement.

**Independent Test** : provoquer une rupture sur un article de chaque préférence ; vérifier la fenêtre de 60 s puis l'appel et le retrait si injoignable ; refuser +25 %, accepter +20 % ; refuser un article d'un autre vendeur ; vérifier que **seul** le montant des articles bouge.

- [ ] T047 [US7] Application des trois préférences dans `backend/crates/commandes/src/substitution.rs` : « retirer » → `ligne.retiree` + révision du montant ; « m'appeler » → `appel.intention` + résolution saisie ; « remplacer » → ouverture d'une proposition. Puis `cargo sqlx prepare`.
- [ ] T048 [US7] Proposition de remplacement dans `substitution.rs` : gardes **même vendeur** (`substitution.refus.autre_vendeur`) et **écart de prix** borné par `substitution.ecart_prix_max_pourcent` (`substitution.refus.ecart_prix`), photo déposée dans le stockage objet (rétention de zone), événement `substitution.proposee`.
- [ ] T049 [US7] Échéance et expiration dans `substitution.rs` : `echeance = proposee_le + substitution.delai_validation_s`, **résolution à la lecture** (toute proposition échue est traitée comme expirée) **et** job périodique de balayage dans `backend/api/src/lib.rs` (patron des purges existantes) ; expiration → **appel** puis **retrait** de l'article si injoignable (`issue = expiree_appel`, maquette C4-4c) ; research R10.
- [ ] T050 [US7] Révision du montant dans `substitution.rs` : `montant_articles_unites` et `total_unites` recalculés, **devis de livraison inchangé** — assertion explicite que `devis_prix_client` et `devis_part_coursier` sont identiques avant et après (FR-050) ; aucun chemin de paiement partiel.
- [ ] T051 [US7] Endpoints de substitution : `POST /courses/{livraison}/substitutions` (coursier, multipart photo + prix) dans `backend/api/src/course_http.rs` et `POST /commandes/{id}/substitutions/{sub}/decision` (client propriétaire) dans `commandes_http.rs`. **Terminer par** : `#[utoipa::path]` à jour → `openapi.json` régénéré → clients Dart/TS régénérés (sans diff) → **build vert**.
- [ ] T052 [P] [US7] Tests d'intégration US7 dans `backend/api/tests/commandes_substitution.rs` : les trois préférences ; acceptation et refus dans la fenêtre ; **expiration → appel → retrait non facturé** ; +25 % refusé / +20 % accepté ; **autre vendeur refusé** ; arrêt entièrement indisponible → `indisponible`, compté comme résolu, montant avancé nul ; **frais et effort inchangés** après substitution.
- [ ] T053 [US7] UI **feuille de substitution** dans `apps/mefali_client/lib/commande/` — capture `docs/design/png/C4` (cadre **4c**) : feuille par-dessus le suivi avec photo, écart de prix (« 600 FCFA au lieu de 500 »), **compte à rebours 60 s** visible, boutons Refuser / Accepter, et la phrase d'issue par défaut (« Sans réponse dans 60 s, on appelle. Injoignable : article retiré, rien à payer ») ; `flutter test` + `dart analyze` verts.

**Checkpoint** : une rupture ne casse plus une commande, et le coursier ne perd rien.

---

## Phase 10: User Story 8 — Annuler proprement, sans que personne ne perde (CMD-07, Priority: P3 · produit P0)

**Goal** : l'annulation est sans frais avant tout achat, et bascule sur les règles d'échec dès qu'un arrêt est collecté.

**Independent Test** : annuler avant toute collecte → sans frais ; annuler après une collecte → règles d'échec, part coursier due ; annuler en admin → motif obligatoire et journalisé.

- [ ] T054 [US8] Annulations dans `backend/crates/commandes/src/annulation.rs` : **sans frais** tant qu'aucun arrêt n'est collecté ; au-delà, bascule sur les règles d'échec avec **part coursier due** (research : au moins un arrêt collecté) ; annulation admin **avec motif obligatoire** journalisé ; refus sur état terminal ; événements `commande.annulee` et remboursement dû si prépayée. Puis `cargo sqlx prepare`.
- [ ] T055 [US8] Endpoints d'annulation : `POST /commandes/{id}/annuler` (client propriétaire) dans `backend/api/src/commandes_http.rs` et `POST /admin/commandes/{id}/annuler` (admin, motif obligatoire) dans `admin_commandes_http.rs`. **Terminer par** : `#[utoipa::path]` à jour → `openapi.json` régénéré → clients Dart/TS régénérés (sans diff) → **build vert**.
- [ ] T056 [P] [US8] Tests d'intégration US8 dans `backend/api/tests/commandes_annulation.rs` : sans frais avant collecte ; après collecte → règles d'échec + part due ; admin sans motif → refus ; commande livrée → **409** ; commande prépayée annulée → événement de remboursement dû émis.

**Checkpoint** : toutes les sorties de parcours sont propres et tracées.

---

## Phase 11: User Story 9 — Dérouler l'arbre des échecs sans jamais que le coursier perde (CMD-08, Priority: P3 · produit P0)

**Goal** : l'arbre complet du cadrage §7.5, résolu **par arrêt**, journalisant qui détient l'argent et la marchandise.

**Independent Test** : un test d'intégration par ligne du tableau §7.5, chacun vérifiant l'issue, les deux détenteurs, les événements et la sanction éventuelle ; un échec déclaré sans preuves est refusé.

- [ ] T057 [US9] Arbre §7.5 dans `backend/crates/commandes/src/echec.rs` : écriture de `issue_echec` avec **`detenteur_argent` et `detenteur_marchandise`** (axes indépendants, research R14), résolution **par arrêt** (non périssable → retour vendeur et remboursements tracés ; refus de reprise → litige + indemnisation ; périssable → litige + indemnisation + **sanction** via `RestrictionsCompte`, rang 1 = `prepaiement_impose`, rang 2 = `bloque`) ; événements `echec.issue_enregistree`, `litige.ouvert`, `indemnisation.due`, `sanction.posee`. Puis `cargo sqlx prepare`.
- [ ] T058 [US9] Remise dans `backend/crates/commandes/src/collecte.rs` : validation du **jeton QR** ou du **code** contre la valeur stockée, incrément d'`essais_code`, **blocage au 3ᵉ échec** (`code_epuise` + alerte admin), mode **dépôt** autorisé (photo + position), transition `en_livraison → livree` et `en_cours → terminee`, événements `livraison.livree` et `commande.terminee`. Le coursier ne reçoit **jamais** le code — seulement les empreintes (research R6). Puis `cargo sqlx prepare`.
- [ ] T059 [US9] Re-livraison après consigne dans `echec.rs` : le cas « client injoignable **et** vendeur fermé » place la marchandise en `consigne` et crée une **nouvelle commande liée** (`relivraison_de`) portant **son propre devis** — jamais un second segment (CMD-09 hors périmètre, spec). Puis `cargo sqlx prepare`.
- [ ] T060 [US9] Endpoints d'échec : `POST /courses/{livraison}/echec` (coursier, **refusé sans preuves** via `PreuvesEchec`) et `POST /courses/{livraison}/remise` dans `backend/api/src/course_http.rs` ; `POST /admin/commandes/{id}/issues` dans `admin_commandes_http.rs`. **Terminer par** : `#[utoipa::path]` à jour → `openapi.json` régénéré → clients Dart/TS régénérés (sans diff) → **build vert**.
- [ ] T061 [P] [US9] Tests d'intégration de l'arbre dans `backend/api/tests/commandes_echecs.rs` : **11 tests couvrant les 10 lignes** du tableau §7.5 ([quickstart §SC-003](./quickstart.md)), chacun assertant l'issue, `detenteur_argent`, `detenteur_marchandise` et les événements émis ; sanction client au 1ᵉʳ puis au 2ᵉ refus périssable.
- [ ] T062 [P] [US9] Tests complémentaires dans `commandes_echecs.rs` : échec déclaré **sans preuves** → `409 preuves_incompletes` (double `PreuvesFixes`) ; remise par QR, par code, en dépôt ; **3 codes faux** → blocage + alerte ; re-livraison créée comme **commande liée** avec son propre devis ; `litige.ouvert` et `indemnisation.due` émis **sans consommateur** (contrats AVI/CRS).

**Checkpoint** : la promesse « le coursier ne perd jamais » est prouvée cas par cas.

---

## Phase 12: Polish & vérifications transverses

- [ ] T063 [P] Job de purge des **photos de substitution** dans `backend/api/src/lib.rs` selon `substitution.photo_retention_jours` (patron des purges de repères vocaux et de photos de collecte) ; test de rétention.
- [ ] T064 [P] Vérifier l'**i18n complète** : aucune chaîne utilisateur en dur côté API (`message_cle` sur tous les refus) ni côté Flutter (toutes les entrées ARB présentes en fr) ; grep de contrôle documenté dans le quickstart.
- [ ] T065 [P] Vérifier que **tous les paramètres** du cycle sont résolus par configuration de zone (aucune constante en dur) : les 11 clés de [data-model.md §6](./data-model.md), plus `mixable` (déjà seedé au cycle 002) ; test de résolution par héritage.
- [ ] T066 **Vérifier les cinq points obligatoires** du [plan §Points obligatoires](./plan.md) : **P1** — les trois critères du gating (test 006 vert sans modification, bascule avec arrêt de remise, progression « 2 sur 2 ») ; **P2** — `cargo sqlx migrate run` vert sur base vierge **et** sur base déjà migrée à `0007` ; **P3** — aucune requête de `commandes` n'écrit dans `comptes.compte` ; **P4** — le devis de panier n'écrit rien et n'émet rien ; **P5** — `backend/crates/` contient toujours 13 crates.
- [ ] T067 Dérouler [quickstart.md](./quickstart.md) de bout en bout : suite backend complète, puis validation **sur émulateur Android** des parcours SC-001 (panier 12 articles / 3 vendeurs en < 3 min), SC-004 et SC-009 (suivi puis **mode avion** — QR et code affichés, dernier état connu, âge de la position), SC-011 (création → affectation simulée → 3 collectes → remise → terminée). Consigner les écarts constatés.
- [ ] T068 **Revue Definition of Done** (`docs/user-stories-v2.md` §0.4) — les six points, un par un : (1) critères d'acceptation couverts par des tests, **transitions incluses** ; (2) annotations utoipa à jour et **clients Dart/TS régénérés sans diff manuel** ; (3) migrations SQL versionnées (`0008`, `0009`) et **seeds à jour** (`60_commandes_parametres.sql`) ; (4) **événement outbox pour tout changement d'état** + événements de métriques du parcours déclarés dans la taxonomie ; (5) **clés i18n fr externalisées** ; (6) **paramètres exposés en configuration de zone** partout où la story dit « paramétrable ». Puis `cargo test` + `cargo sqlx prepare` + `dart analyze` verts, et message de commit conventionnel référençant les stories (`feat(commandes): CMD-01..08,10 …`).

---

## Dependencies & Execution Order

### Dépendances de phase

- **Phase 1 (Setup)** : aucune dépendance — démarrage immédiat.
- **Phase 2 (Foundational)** : dépend de la Phase 1 — **BLOQUE toutes** les user stories. En son sein, l'ordre **T004 → T005 → T006** est impératif (les migrations avant le code qui les référence ; le gating **immédiatement après** la migration qui introduit `type_arret`).
- **Phases 3+ (User Stories)** : toutes dépendent de la Phase 2.
- **Phase 12 (Polish)** : dépend des stories souhaitées.

### Dépendances entre stories

- **US1 (panier)** : indépendante après la Phase 2 — c'est l'entrée du MVP.
- **US2 (adresse)** : indépendante après la Phase 2 ; peut être menée **en parallèle** d'US1.
- **US3 (création)** : dépend d'**US1** (panier validé) et d'**US2** (adresse validée).
- **US4 (états)** : dépend d'**US3** (il faut une commande à faire avancer).
- **US5 (file)**, **US6 (suivi)** : dépendent d'**US3** ; indépendantes entre elles.
- **US7 (substitutions)** : dépend d'**US4** (boucle de collecte).
- **US8 (annulations)** : dépend d'**US4**.
- **US9 (échecs)** : dépend d'**US4**, d'**US7** (retraits) et d'**US8** (règles d'annulation après collecte).

### Opportunités de parallélisme

- Phase 1 : **T001, T002, T003** en parallèle.
- Phase 2 : après T004→T005→T006 (séquentiels), **T007, T008, T009, T010, T011, T013, T014** en parallèle ; T012 après T007/T009.
- **US1 et US2 en parallèle** après la Phase 2.
- **US5 et US6 en parallèle** après US3.
- Toutes les tâches de test marquées **[P]** s'exécutent en parallèle de la tâche d'UI de la même story.
- Phase 12 : **T063, T064, T065** en parallèle ; T066 → T067 → T068 séquentiels.

---

## Parallel Example: Phase 2 après les migrations

```bash
# Une fois T004 → T005 → T006 terminés dans cet ordre :
Task: "T007 Types du domaine dans backend/crates/commandes/src/modele.rs"
Task: "T008 Table de transitions fermée dans backend/crates/commandes/src/etats.rs"
Task: "T009 Traits et doubles dans backend/crates/commandes/src/ports.rs"
Task: "T010 Restrictions CPT-06 dans backend/crates/comptes/src/restriction.rs"
Task: "T011 ServiceWorkflow dans backend/crates/commandes/src/workflow.rs"
Task: "T013 Tables drift dans apps/packages/mefali_core/lib/src/offline/action_en_attente.dart"
Task: "T014 i18n : module d'erreurs API + entrées ARB"
```

---

## Implementation Strategy

### MVP d'abord (US1 + US2 + US3)

1. Phase 1 (Setup) → Phase 2 (Foundational, **T006 non négociable**).
2. US1 (panier) et US2 (adresse) — parallélisables.
3. US3 (création) — **STOP et VALIDER** : Awa compose, adresse, paie, obtient son code et son QR.
4. Démo possible : le parcours client jusqu'à la commande créée.

### Livraison incrémentale

1. Socle + US1 + US2 + US3 → **MVP client** (commande créée, code et QR remis).
2. + US4 → la commande **avance** de bout en bout (démo de tranche T1 possible avec l'affectation simulée).
3. + US5 + US6 → plus aucune commande perdue, suivi complet **hors ligne compris**.
4. + US7 → les ruptures ne cassent plus rien.
5. + US8 + US9 → toutes les sorties de parcours sont tracées (**tranche T2** du cadrage).

### Note de charge

68 tâches — c'est le cycle le plus lourd du projet à ce jour (007 en comptait 35, 006 en comptait 48). Si le calendrier se tend, les candidats naturels au report sont **US8** et **US9**, dont la tranche produit est **T2** et non T1 ; **US1 à US7 forment la tranche T1** et ne se scindent pas utilement.

---

## Notes

- `[P]` = fichiers différents, aucune dépendance ; `[Story]` trace la tâche vers sa user story.
- Commit après chaque tâche ou groupe logique, message conventionnel référençant la story.
- **Ne jamais** éditer `clients/dart` ni `clients/ts` à la main — régénération uniquement.
- **Ne jamais** modifier une migration déjà appliquée — `0001..0007` sont intouchables.
- S'arrêter à n'importe quel checkpoint pour valider une story isolément.
