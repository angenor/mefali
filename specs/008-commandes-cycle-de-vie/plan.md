# Implementation Plan: Cycle de vie complet d'une commande multi-vendeurs

**Branch**: `008-commandes-cycle-de-vie` | **Date**: 2026-07-25 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/008-commandes-cycle-de-vie/spec.md`

## Summary

Le cycle CMD construit **la commande** : le tronc commun sans champ logistique, son composant de livraison optionnel, et tout le cycle de vie qui va du panier multi-vendeurs à la remise — ou à l'arbre des échecs. Il est bâti **par extension** du crate `commandes`, qui porte déjà le socle logistique minimal posé au cycle 006 (ancre `commande`, `livraison`, `segment`, `arret`, collecte par scan, bascule en livraison). Sept blocs :

1. **Tronc & composant de livraison** (CMD-04, structure) — le tronc reçoit identité, prestataires, lieu de prestation, montants d'articles, paiement et **états de très haut niveau** ; le **devis figé et tous les états logistiques** vivent sur la livraison, les segments et les arrêts (constitution II). La **remise devient un arrêt** du segment — ce qui impose de corriger le gating de bascule hérité du cycle 006 pour qu'il ne compte que les **collectes** (voir R4, non-régression).
2. **Panier multi-vendeurs & règle de mixage** (CMD-01) — le panier est un **brouillon local** (aucune table serveur) ; l'API expose un **devis de panier sans effet de bord** qui regroupe par vendeur, chiffre les frais via `EvaluationTarifaire` et renvoie les deux déclencheurs de **proposition de scission** : catégorie non `mixable` et `proposer_scission` du devis (déjà produit par le cycle 007).
3. **Adresse de commande** (CMD-02) — réutilise le carnet `comptes.adresse` (pin, repère texte/vocal, purge de rétention) ; CMD **revalide** la présence d'un repère à la commande, **dénormalise** l'adresse sur le tronc (immuabilité) et appelle `marquer_adresse_utilisee`, prévue pour ce cycle.
4. **Création** (CMD-03) — verrouillage des prix par `figer_prix` (déjà prêt), **devis figé copié** sur la livraison dans la même transaction, plafonds cash résolus par configuration de zone, **code de livraison à 4 chiffres + jeton QR de réception** générés et remis immédiatement, création **idempotente** par clé client.
5. **Machine à états gardée** (CMD-04) — trois niveaux d'états (tronc / livraison / arrêt) avec une table de transitions **fermée** : toute transition non listée est refusée en conflit, horodatée serveur, et écrit son **événement outbox dans la même transaction**.
6. **Branches de vie** — file d'attente sans coursier (CMD-10, FIFO par âge sans table dédiée), suivi client avec position **et son âge** (CMD-05), substitutions à échéance persistée (CMD-06), annulations (CMD-07), et l'**arbre §7.5 complet** (CMD-08) qui journalise, pour chaque issue, **qui détient l'argent et la marchandise**.
7. **Écrans clients Flutter** (maquettes C3, C4) — panier groupé par vendeur, adresse et paiement, suivi avec bloc « À la livraison » fonctionnel **hors ligne**, feuille de substitution. État en **Riverpod codegen** (constitution XII), cache local **drift** (la base et la file d'actions existent déjà).

Trois modules dont CMD dépend ne sont pas construits — **dispatch**, **paiements**, **coursier/avis**. Le cycle pose leurs états, préconditions et événements, et les exerce par des **doubles**, exactement comme le cycle 006 a simulé la course active et le cycle 007 les courses tarifées.

## Technical Context

**Language/Version** : Rust stable (workspace) ; Dart/Flutter stable pour `mefali_client` et `mefali_core`. Contrat OpenAPI utoipa → clients Dart/TS régénérés.

**Primary Dependencies** :
- Backend : Actix Web, sqlx (PostgreSQL, macros vérifiées, cache `.sqlx`), utoipa + utoipa-actix-web + utoipa-swagger-ui, `redis` (position coursier éphémère), `serde`/`serde_json`, `uuid` v7, `chrono`, `thiserror`, `async-trait`, `sha2`/`hmac` (déjà utilisés par `qr`). **Aucune nouvelle dépendance tierce** (principe X).
- Crates consommés : `zones` (`ConfigurationZones` — mixable, plafonds, périssable, devise, rétentions), `comptes` (carnet d'adresses, `marquer_adresse_utilisee`, restrictions CPT-06), `prestataires` (`figer_prix`, `articles_commandables_de`, `Commandabilite`, sites), `tarification` (`EvaluationTarifaire`, `OptimisationArrets`, `Devis`), `qr` (`empreinte_code`, `empreinte_jeton`, politique photo), `socle` (`ecrire_evenement`, `DepotObjets` S3, télémétrie).
- Flutter : `flutter_riverpod` + `riverpod_annotation` + `riverpod_generator` (codegen, constitution XII), `drift` (cache local — base et file d'actions **déjà en place**), client Dart généré. Aucun nouveau paquet.

**Storage** : PostgreSQL — schéma `commandes` **étendu** par deux migrations (`0008`, `0009` ; `0001..0007` intouchées). Redis — position coursier éphémère lue par le suivi (alimentée par DSP, simulée ici). Stockage objet S3 — photos de substitution (rétention de zone, comme les photos de collecte du cycle 006). Sur l'appareil client — base **drift** existante, étendue de deux tables locales (brouillon de panier, cache de commande).

**Testing** : `cargo test` — tests d'intégration **par transition** de la machine à états et **un test par ligne** du tableau §7.5 ; doubles pour dispatch, paiement et preuves d'échec. `cargo sqlx prepare` après le SQL. `flutter test` — widget tests des écrans C3/C4 et tests des providers. `dart analyze` (jamais `flutter analyze`, constitution XII).

**Target Platform** : serveur Linux (API) ; Android (app cliente, cible vérifiée sur émulateur — iOS non vérifié, Xcode absent).

**Project Type** : monorepo — backend Rust (monolithe modulaire) + app Flutter cliente. Pas de page Nuxt ce cycle (l'admin est au cycle ADM).

**Performance Goals** : devis de panier perçu instantané (< 1 s, une seule évaluation tarifaire par recalcul) ; création de commande en une transaction ; suivi rafraîchi au moins toutes les 30 s ; écrans hors ligne rendus sans aucun appel réseau.

**Constraints** : montants entiers en unités mineures + ISO 4217 de zone, **aucun chemin partiel** (III) ; devis figé **jamais recalculé** après création (décision de spec) ; toute transition = événement outbox dans la même transaction (VI) ; actions coursier idempotentes par UUID client (V) ; aucune chaîne en dur (VII) ; code et QR de réception accessibles **sans réseau** côté client.

**Scale/Scope** : Tiassalé (MVP), un vertical (restauration + courses). Panier multi-vendeurs natif (1..n collectes + 1 remise, 1 segment). 9 user stories, 68 exigences.

## Constitution Check

*GATE : passé avant la recherche, re-vérifié après conception (voir fin de fichier).*

- [x] **I. Sources de vérité** : **deux nouvelles** migrations (`0008_commandes_enums.sql`, `0009_commandes_tronc.sql`) — `0001..0007` intouchées ; la scission en deux est imposée par PostgreSQL (`ALTER TYPE … ADD VALUE` inutilisable dans la transaction qui l'ajoute — R2). Clients Dart/TS **régénérés** depuis `openapi.json`, jamais édités. **Tous** les paramètres métier (mixable — déjà seedé, périssable, plafonds cash, plafond restauration sans historique, délai de validation de substitution, écart de prix, longueur minimale du repère texte, période de position, rétention des photos de substitution) en **configuration de zone héritée**.
- [x] **II. Architecture** : extension du crate de domaine **`commandes`** existant, schéma `commandes` (un schéma par module). Le **tronc ne reçoit aucun champ logistique** : le devis figé, le coursier, les états de collecte et de remise vivent sur `livraison`/`segment`/`arret` (R3). La livraison reste **optionnelle (0..n)** — une commande sans livraison est acceptée par le modèle et testée. Aucun crate partagé ne suppose « commande = livraison » ni « prestataire = vendeur ». Les spécificités du vertical restauration vivent dans `resto_details` derrière le trait **`ServiceWorkflow`**. Redis ne porte que la position éphémère ; Postgres reste la seule vérité durable.
- [x] **III. Argent** : montants en **entiers d'unités mineures** + devise ISO 4217 de la zone ; **prix verrouillés** à la création via `figer_prix` (cycle 005) ; **devis figé** copié sur la livraison ; **aucun chemin de paiement partiel** — la garde est structurelle (un seul montant à encaisser, aucune API de règlement fractionné) et testée. La chaîne cash est tracée **par arrêt** (montant avancé déjà porté par `arret`).
- [x] **IV. Distances** : CMD **ne calcule aucune distance** — il appelle `EvaluationTarifaire` et `OptimisationArrets` du cycle 007, qui portent OSRM, le cache et le dégradé ×1,4. Le drapeau `degraded` du devis est **conservé** sur la livraison et journalisé ; une commande n'est jamais bloquée par le routage.
- [x] **V. Offline & idempotence** : création **idempotente** par clé client ; **toute** transition d'arrêt et toute décision de substitution portent un UUID client + horodatage local, rejeu idempotent, **serveur fait foi**. Côté client, le panier hors ligne est un brouillon local à envoi unique, et le **code + jeton de réception sont mis en cache** dès la création — le client n'a jamais besoin de réseau au moment de la remise. Les **empreintes** (hash salé) du code et du jeton sont exposées pour le pré-provisionnement coursier de CRS-04.
- [x] **VI. Événements** : chaque transition écrit son événement outbox **dans la même transaction** ; les 25 événements du cycle (23 nouveaux + 2 hérités du cycle 006) sont **déclarés dans `docs/taxonomie-evenements.md` avant implémentation** (tâche dédiée). Les événements destinés aux modules non construits (`litige.ouvert`, `indemnisation.due`, `commande.prete_a_dispatcher`) sont émis sans consommateur — c'est le contrat que AVI, CRS et DSP brancheront.
- [x] **VII. Qualité** : un test d'intégration **par transition** de la machine à états (les trois niveaux), **un test par ligne** du tableau §7.5, plus les gardes (plafonds, repère obligatoire, écart de prix, même vendeur, idempotence). `cargo sqlx prepare` après le SQL. Aucune chaîne utilisateur en dur — clés i18n fr côté API (`message_cle`) et côté Flutter (ARB).
- [x] **VIII. Sécurité** : chaque endpoint protégé par rôle (client propriétaire, coursier assigné, admin) ; le **code de livraison n'est jamais exposé au coursier** (il ne reçoit que l'empreinte) ni à un tiers ; photos de substitution soumises à la **rétention de zone** comme les photos de collecte ; payloads d'événements **sans coordonnées brutes** (distances arrondies — minimisation ARTCI).
- [x] **IX. Périmètre** : CMD est le cœur qui augmente les commandes/jour. CMD-09 (multi-segment planifié) reste **hors périmètre** — le modèle `segment (1..n)` le permet sans migration, aucune logique n'est écrite. La réaffectation vers un autre vendeur est refusée explicitement (test). Aucun écran coursier ni admin n'est construit.
- [x] **X. Versions** : aucune nouvelle dépendance, ni Rust ni Dart — le cycle assemble des briques déjà figées par lockfile.
- [x] **XI. Design** : écrans Flutter en widgets **Material 3 thémés par `mefali_core`** depuis `docs/design/tokens.md` ; `docs/design/png/C3` et `C4` sont la **cible**, `docs/design/html/` n'est lu que pour des **mesures** — aucune transposition DOM/CSS ; constructeurs `.adaptive`, aucune variante Cupertino.

**GATE PASSÉ** avant recherche. Re-vérification post-conception en fin de fichier.

## Project Structure

### Documentation (this feature)

```text
specs/008-commandes-cycle-de-vie/
├── plan.md              # Ce fichier
├── research.md          # Phase 0 — décisions R1..R17
├── data-model.md        # Phase 1 — migrations 0008/0009, machine à états, traits, événements
├── quickstart.md        # Phase 1 — scénarios de validation (SC-001..011 + arbre §7.5)
├── contracts/
│   └── commandes-openapi.md   # Endpoints (utoipa), DTO, traits exposés, événements
├── checklists/
│   └── requirements.md  # Qualité de la spec (déjà validé)
└── tasks.md             # Phase 2 — /speckit-tasks (NON créé par /speckit-plan)
```

### Source Code (dépôts réellement touchés)

```text
backend/
├── crates/
│   ├── commandes/                    # ÉTENDU (socle 006 → domaine complet) :
│   │   ├── modele.rs                 #   + EtatCommande, TypeArret, PreferenceSubstitution,
│   │   │                             #     StatutLigne, TypeIssue, Detenteur, DTO de domaine
│   │   ├── etats.rs                  #   NOUVEAU : table de transitions fermée (3 niveaux), gardes
│   │   ├── panier.rs                 #   NOUVEAU : devis de panier, regroupement, mixage, scission
│   │   ├── creation.rs               #   NOUVEAU : prix figés + devis figé + code/jeton, idempotent
│   │   ├── collecte.rs               #   NOUVEAU : boucle par arrêt (en_route/arrivé), gating corrigé
│   │   ├── substitution.rs           #   NOUVEAU : préférences, proposition, échéance, expiration
│   │   ├── annulation.rs             #   NOUVEAU : sans frais / après collecte / admin
│   │   ├── echec.rs                  #   NOUVEAU : arbre §7.5, détenteurs, sanctions, événements
│   │   ├── suivi.rs                  #   NOUVEAU : progression par arrêt, position + âge
│   │   ├── workflow.rs               #   NOUVEAU : trait ServiceWorkflow + Restauration / Courses
│   │   ├── depot.rs                  #   ÉTENDU : PgCommandes (lectures pool, écritures &mut tx)
│   │   ├── ports.rs                  #   ÉTENDU : + Affectation, PreuvesEchec, RestrictionsCompte,
│   │   │                             #     PositionCoursier (+ doubles de test)
│   │   └── lib.rs
│   └── comptes/
│       └── restriction.rs            #   NOUVEAU : lire/poser prepaiement_impose & bloque (CPT-06,
│                                     #   colonnes déjà en base — implémenté ici, appelé par CMD)
├── api/
│   └── src/
│       ├── commandes_http.rs         # NOUVEAU : panier, création, suivi, annulation, décisions client
│       ├── course_http.rs            # NOUVEAU : transitions d'arrêt, substitutions, remise, échec
│       └── admin_commandes_http.rs   # NOUVEAU : annulation admin, résolution d'issue §7.5
└── migrations/
    ├── 0008_commandes_enums.sql      # ALTER TYPE … ADD VALUE isolés (contrainte PostgreSQL, R2)
    └── 0009_commandes_tronc.sql      # tronc, lignes, resto_details, substitution, issue_echec, index

backend/seeds/
└── 60_commandes_parametres.sql       # NOUVEAU : périssable par catégorie, plafonds cash, écart de
                                      #   substitution, délai de validation, période de position…

apps/
├── mefali_client/lib/
│   ├── panier/                       # NOUVEAU : écrans C3 (panier, adresse+paiement, mixte, hors ligne)
│   ├── commande/                     # NOUVEAU : écrans C4 (suivi, recherche, substitution, hors ligne)
│   └── main.dart                     # ÉTENDU : routes des nouveaux écrans
└── packages/mefali_core/lib/src/
    ├── commande/                     # NOUVEAU : composants partagés (carte vendeur, récap frais,
    │                                 #   stepper, bloc « À la livraison », feuille de substitution)
    └── offline/action_en_attente.dart # ÉTENDU : + tables drift brouillon_panier, commande_cache

clients/                              # RÉGÉNÉRÉS depuis openapi.json (jamais édités)
docs/
└── taxonomie-evenements.md           # + 23 nouveaux événements commande.*, arret.*, substitution.*, echec.*
```

**Structure Decision** : **backend + app cliente**. Le domaine est une **extension du crate `commandes`** (pas de nouveau crate : le socle logistique y vit déjà, et l'éclater couperait le gating de bascule de ses arrêts). Une méthode d'écriture est ajoutée au crate **`comptes`** parce que les restrictions vivent dans **son** schéma (constitution II) — CMD l'appelle par un port. Trois modules HTTP séparent les trois rôles. Aucune page Nuxt : l'écran opérations est au cycle ADM.

## Complexity Tracking

| Violation potentielle | Pourquoi nécessaire | Alternative plus simple rejetée parce que |
|-----------|------------|-------------------------------------|
| **Deux migrations pour un seul cycle** (`0008` énums, `0009` structures) | PostgreSQL refuse d'**utiliser** une valeur d'énum dans la transaction qui l'ajoute (`ALTER TYPE … ADD VALUE`), et sqlx exécute chaque fichier de migration dans **une** transaction. Les nouveaux états (`en_route`, `arrive` sur l'arrêt ; `assignee`, `livree`, `echouee`, `annulee` sur la livraison) sont référencés par des `CHECK`, des `DEFAULT` et des index partiels de `0009`. | Un fichier unique **échoue au déploiement** (`unsafe use of new value`). Recréer les énums à neuf (type v2 + migration de colonne) casserait les vues, index et code du cycle 006 pour un bénéfice nul. |
| **Modification du gating `EN_LIVRAISON` livré au cycle 006** | La remise devient un **arrêt** du segment (cadrage §7.2, périmètre imposé). Le gating hérité compte **tous** les arrêts ; avec la remise, il ne basculerait plus jamais. Il doit compter les seuls arrêts de **type collecte**. | Modéliser la remise hors des arrêts (champ du segment) contredirait explicitement le cadrage §7.2 et le périmètre imposé. Laisser le gating tel quel produirait une commande qui ne part jamais en livraison — régression silencieuse. Le test d'intégration du cycle 006 est **conservé** et complété. |
| **Écriture dans le schéma `comptes` (restrictions CPT-06)** | La sanction client de CMD-08 (`prepaiement_impose` puis `bloque`) et la garde de CMD-03 sont **dans le périmètre CMD**, mais les colonnes vivent dans le schéma `comptes` — « un schéma par module » impose que l'écriture vive dans **son** crate. | Écrire directement depuis `commandes` violerait la frontière de schéma (constitution II) ; dupliquer les drapeaux dans le schéma `commandes` créerait deux vérités pour un même fait. CMD passe par un **port** (`RestrictionsCompte`), implémenté dans `comptes`. |
| **Secrets de confirmation (`code_livraison`, `jeton_reception`, empreintes, `essais_code`) sur le TRONC** — tension apparente avec « aucun champ logistique sur le tronc » (constitution II) | Leur seul usage **aujourd'hui** est la remise, mais leur nature est générique : ce sont des secrets de **confirmation d'exécution d'une commande**, remis au client à la création (CMD-03, FR-028). Un vertical sans livraison (artisan à domicile, phase N) fait valider son intervention par le **même** code, sans coursier ni arrêt. Ils ne portent aucune donnée logistique — ni coursier, ni arrêt, ni itinéraire, ni montant. | Les placer sur `livraison` rendrait la confirmation **impossible** pour une commande sans livraison — précisément le cas que le principe II protège (« aucun crate partagé ne suppose que toute commande est une livraison »). Les dupliquer aux deux niveaux créerait deux vérités pour un même secret. Arbitrage consigné à l'analyse du 2026-07-25 (constat C1). |
| **Aucune table de panier serveur** (le panier est local) | Le panier est un brouillon **modifiable hors ligne** (maquette C3-3c) ; le persister côté serveur imposerait une synchronisation d'état mutable sans valeur métier — rien n'est engagé tant que la commande n'est pas créée. | Une table `panier` serveur ajouterait un cycle de vie complet (création, expiration, purge, conflits multi-appareils) pour un objet qui n'existe que jusqu'à la confirmation. L'API expose un **devis de panier sans effet de bord** : même service, aucun état. |

## Points obligatoires de ce cycle

Les cinq écarts ci-dessus ne sont pas des recommandations à arbitrer plus tard : ce sont des **livrables de ce cycle**, chacun avec son critère de vérification. `/speckit-tasks` DOIT produire une tâche dédiée pour les deux premiers (les trois autres sont structurels et se réalisent en écrivant le code décrit).

| # | Livrable obligatoire | Critère de vérification | Spécifié dans |
|---|---|---|---|
| **P1** | **Correction du gating `EN_LIVRAISON`** hérité du cycle 006 : les trois requêtes de comptage (`gating_livraison`, `progression`) filtrent sur `a.type_arret = 'collecte'`. | (a) `tests/collecte.rs` du cycle 006 reste **vert sans modification de ses assertions** ; (b) nouveau test : une livraison à **2 collectes + 1 remise** bascule `en_livraison` dès ses 2 collectes résolues ; (c) la progression annonce « 2 sur 2 », **jamais** « 2 sur 3 » — la remise n'est pas une collecte. | [research R4](./research.md), [data-model §2.3](./data-model.md) |
| **P2** | **Scission en deux migrations** : `0008` ne contient que des types, `0009` toutes les structures. | (a) `cargo sqlx migrate run` réussit sur **base vierge** ; (b) il réussit aussi sur une **base déjà migrée jusqu'à `0007`** (le cas réel du poste de dev) ; (c) aucune valeur d'énum ajoutée en `0008` n'est référencée dans `0008`. | [research R2](./research.md), [data-model §1](./data-model.md) |
| P3 | Restrictions CPT-06 écrites dans le crate `comptes`, appelées par CMD via le port `RestrictionsCompte`. | Aucune requête de `commandes` ne cite `comptes.compte` en écriture. | [research R12](./research.md) |
| P4 | Aucune table de panier serveur ; `POST /paniers/devis` sans effet de bord. | Un appel au devis de panier n'écrit **aucune** ligne et n'émet **aucun** événement outbox. | [research R8](./research.md) |
| P5 | Extension du crate `commandes`, pas de nouveau crate. | `backend/crates/` contient toujours 13 crates après le cycle. | [research R1](./research.md) |

**P1 est le point le plus risqué du cycle** : sans lui, aucune commande ne bascule jamais en livraison, et *aucun test existant n'échoue* pour le signaler (le cycle 006 ne crée pas d'arrêt de remise). Sa tâche est donc ordonnée **immédiatement après** la migration qui introduit `type_arret`, jamais reportée en fin de cycle.

## Phase 0 — Recherche

Les inconnues techniques sont résolues (stack imposée, cycles 002/003/005/006/007 livrés). Restent des décisions de **conception** — répartition tronc/livraison, contrainte de migration d'énums, correction du gating, secrets de remise, échéance de substitution, doubles des modules absents, cache local Flutter — consignées dans **[research.md](./research.md)** (R1..R17). Aucun `NEEDS CLARIFICATION` résiduel : les trois questions de portée ont été tranchées à la spécification (session 2026-07-25).

## Phase 1 — Conception & contrats

- **[data-model.md](./data-model.md)** : les deux migrations (`0008` énums, `0009` structures), la répartition **tronc / livraison / segment / arrêt**, la **machine à états à trois niveaux** avec sa table de transitions fermée, le pipeline de création (ordre exact des opérations dans la transaction), les tables de substitution et d'issue d'échec, les **paramètres de zone** à seeder, les **traits exposés** (`ServiceWorkflow`, ports vers DSP/PAY/CRS/AVI) et les **événements outbox**.
- **[contracts/commandes-openapi.md](./contracts/commandes-openapi.md)** : les endpoints des trois rôles (`#[utoipa::path]`), les DTO `ToSchema`, les gardes de rôle et de propriété, les codes d'erreur avec leurs clés i18n, le tableau des événements et les signatures des traits offerts aux cycles suivants.
- **[quickstart.md](./quickstart.md)** : scénarios de validation de bout en bout (SC-001..011), le déroulé **ligne par ligne** de l'arbre §7.5, et la procédure de vérification sur émulateur des deux écrans.

## Post-Design Constitution Re-Check

Re-vérifié après Phase 1 : aucune nouvelle violation.

Le **tronc reste sans champ logistique** — la conception détaillée place le devis figé, le coursier, l'ordre et tous les états de collecte sur `livraison`/`segment`/`arret`, et le modèle accepte (et teste) une commande **sans** livraison. Les montants sont des entiers en unités mineures avec la devise de zone, les prix sont verrouillés à la création et **aucune API n'accepte un règlement fractionné**. CMD ne calcule aucune distance : il consomme les capacités du cycle 007 et conserve le drapeau de dégradé. Chaque transition écrit son événement dans la même transaction, et les 25 événements sont déclarés avant implémentation. Le code de remise n'est jamais exposé au coursier — seule son empreinte l'est, ce qui sert directement le hors-ligne de CRS-04. Les écrans sont des widgets Material 3 thémés par `mefali_core`, sans transposition DOM/CSS.

Les quatre écarts consignés en Complexity Tracking (deux migrations, correction du gating hérité, écriture des restrictions dans `comptes`, absence de panier serveur) sont **structurels et justifiés** : trois sont imposés par des contraintes techniques ou constitutionnelles, le quatrième supprime de la complexité plutôt qu'il n'en ajoute. **GATE PASSÉ — prêt pour `/speckit-tasks`.**
