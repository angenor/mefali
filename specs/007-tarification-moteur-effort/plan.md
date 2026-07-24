# Implementation Plan: Moteur de tarification à règles, routage et grille d'effort

**Branch**: `007-tarification-moteur-effort` | **Date**: 2026-07-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/007-tarification-moteur-effort/spec.md`

## Summary

Le cycle TRF construit le **moteur de tarification** — la fonction qui transforme une course (des retraits, un client, un véhicule, une heure, un panier) en un **devis figé** {prix client, part coursier, marge, devise} calculé sur des **kilomètres routiers réels**. Cinq blocs, tous dans un nouveau crate `tarification` (aujourd'hui un stub) :

1. **Modèle de règles versionné** (TRF-01) — un schéma `tarification` propre (constitution II) porte des **grilles** (brouillon / en vigueur / historique par zone) et leurs **règles** {conditions → sorties, priorité, dates d'effet}. La **marge est bornée par zone** (garde à l'édition). Les *knobs* scalaires (bornes de marge, pas d'arrondi, facteur dégradé, TTL de cache, seeds d'effort, plafonds, drapeaux) restent en **configuration de zone héritée** (`zones.parametre_zone`, constitution I) ; seul le **catalogue structuré et versionné** vit dans le schéma du module (voir Complexity Tracking).
2. **Évaluation routée & devis figé** (TRF-02) — premier **client OSRM** du dépôt : matrice de distances par `/table` (waypoints), **optimisation de l'ordre des arrêts** (permutations ≤ 4), sélection de la règle la plus spécifique en vigueur, suppléments, grille d'effort, arrondi, **drapeaux de zone** et **VND-08**, le tout figé. **Cache Redis** par paire de points arrondis (24 h) ; **dégradé** vol d'oiseau × 1,4 `degraded=true` journalisé — une commande n'est jamais bloquée (constitution IV).
3. **Simulateur admin & garde de publication** (TRF-03) — le même cœur d'évaluation rejoué sur un **brouillon**, renvoyant le détail complet ; la publication est **gardée** (simulation obligatoire + aucune règle hors bornes).
4. **Devises par zone** (TRF-04) — devise ISO 4217 portée par la zone (`ConfigurationZones::devise`), XOF sans décimale, aucune conversion.
5. **Grille de départ Tiassalé & grille d'effort** (TRF-05/TRF-06) — seed rejouable de la grille + params d'effort ; trois composantes 100 % coursier (paliers d'articles, **prime d'attente une seule fois par course**, supplément d'arrêt indexé sur le tronçon routier au précédent), optimisation d'ordre **exposée à DSP/CMD**, plafond d'éclatement, effort **journalisé non facturé** pendant la promo.

Comme au cycle 006, l'évaluation prend la **géométrie en entrée** (points), pas les tables `commandes` : la course réelle et la destination client (CMD-02, non construits) sont **simulées dans les tests** ; CMD/DSP fourniront la géométrie plus tard. **Aucune UI n'est construite** (comme 002/003/005) : le simulateur, l'édition de grille et la publication sont exposés en **API admin** (la maquette `docs/design/png/A3` est la cible du cycle **ADM**) ; le devis, le détail d'effort et l'ordre optimisé sont exposés comme **capacité (traits)** pour CMD/DSP/CRS.

## Technical Context

**Language/Version** : Rust stable (workspace) ; contrat OpenAPI utoipa → clients Dart/TS régénérés. Aucune app Flutter/Nuxt touchée ce cycle.

**Primary Dependencies** :
- Backend : Actix Web, sqlx (PostgreSQL, macros vérifiées, cache `.sqlx`), utoipa + utoipa-actix-web + utoipa-swagger-ui (contrat auto-collecté), `reqwest` (**déjà en workspace**, api) pour le client OSRM, `redis` (**déjà utilisé** par `qr`/`comptes`) pour le cache de routage, `serde`/`serde_json`, `uuid` v7, `chrono`, `thiserror`, `async-trait`. **Aucune nouvelle dépendance tierce** n'est introduite (bonus principe X) — le crate `tarification` assemble des briques déjà figées au workspace.
- Consommé : crate `zones` (`ConfigurationZones` — knobs, devise, drapeaux), crate `socle` (`Config.osrm_url`/`redis_url`, `ecrire_evenement`, télémétrie), crate `comptes` (`Auth` + `Role::Admin` au niveau `api`).

**Storage** : PostgreSQL — **nouveau schéma `tarification`** (migration `0007_tarification.sql`, `0001..0006` intouchées) : `grille`, `regle`. Redis — **cache de routage** éphémère (paire de points arrondis, TTL 24 h), reconstructible (constitution II). Aucun stockage objet (pas de PDF/média ce cycle). **Aucune** table `commandes` créée ou modifiée (l'évaluation est découplée de la logistique).

**Testing** : `cargo test` (tests d'intégration par transition/scénario, avec un **double de routage** `RoutageFixe`/`RoutageIndisponible` et des géométries de course simulées) ; `cargo sqlx prepare` après le SQL ; contrat régénéré sans diff. Pas de `flutter test` ce cycle (aucune UI).

**Target Platform** : serveur Linux (API). OSRM auto-hébergé (extrait OSM Côte d'Ivoire, `infra/docker-compose.yml`).

**Project Type** : monorepo — backend Rust (monolithe modulaire) ; ce cycle est **backend seul**.

**Performance Goals** : devis en ligne perçu instantané (< 1 s) ; **une seule** requête OSRM `/table` par course (matrice), puis permutations ≤ 4 en mémoire ; cache de routage éliminant l'appel sur trajets répétés (< 24 h) ; dégradé sans blocage.

**Constraints** : montants entiers unités mineures + ISO 4217 de zone (III) ; distances par itinéraire routier, dégradé ×1,4 tracé (IV) ; toute chaîne = clé i18n fr ; publication/dégradé/effort-promo = événement outbox dans la même transaction (VI) ; simulateur **sans effet de bord** (aucun outbox, aucune écriture de l'état en vigueur).

**Scale/Scope** : Tiassalé (MVP), un vertical (restauration + courses). Panier multi-vendeurs natif (1..n retraits → 1 client). Optimisation exhaustive jusqu'à 4 arrêts.

## Constitution Check

*GATE : passé avant la recherche, re-vérifié après conception (voir fin de fichier).*

- [x] **I. Sources de vérité** : UNE nouvelle migration (`0007_tarification.sql`) — `0001..0006` intouchées ; clients Dart/TS régénérés depuis `openapi.json` (jamais édités) ; **tous les paramètres scalaires paramétrables** (bornes de marge, pas d'arrondi, facteur dégradé, TTL cache, seeds d'effort, plafonds, drapeaux) en **configuration de zone héritée**, jamais en dur. Le **catalogue de règles versionné** vit dans le schéma `tarification` (voir Complexity Tracking — le store clé-valeur hérité ne modélise pas un catalogue multi-lignes à priorité, brouillon/publié).
- [x] **II. Architecture** : nouveau crate `tarification` (depuis stub), **schéma Postgres propre** ; l'évaluation prend la **géométrie en entrée** — elle **ne lit aucune table `commandes`**, ne suppose ni « commande = livraison » ni « prestataire = vendeur », et **ne touche pas le tronc `commande`** (aucun champ logistique posé). Redis = éphémère (cache), Postgres = seule vérité durable. Le dispatch reste filtré par capacités ailleurs ; TRF lui **expose** l'ordre optimisé sans en dépendre.
- [x] **III. Argent** : tout montant (prix, part, marge, suppléments, effort, bornes, plafonds) en **entiers unités mineures** + **devise ISO 4217 de la zone** (`ConfigurationZones::devise`) ; **jamais de flottant** pour l'argent (le seul flottant est le facteur dégradé ×1,4 et les coordonnées, non monétaires) ; **aucune conversion**, aucun chemin partiel ; le devis est **figé** (prêt à être verrouillé par CMD).
- [x] **IV. Distances** : **premier consommateur de routage tarifaire** — distance/ETA par **itinéraire routier OSRM avec waypoints** (`/table`), **cache Redis** (paire de points arrondis, 24 h) ; tout repli = **vol d'oiseau ×1,4 explicite, `degraded=true`, journalisé** (`routage.degrade`) ; le routage **ne bloque jamais** une commande. La proximité point-rayon du scan (cycle 006) est un contrôle distinct, non réemployé ici.
- [x] **V. Offline & idempotence** : **sans objet** ce cycle — TRF est backend, sans action coursier hors-ligne. Le devis figé et l'ordre optimisé pré-provisionnables par le coursier relèvent de CRS/CMD (consommateurs futurs).
- [x] **VI. Événements** : trois événements outbox écrits dans la même transaction que leur opération — `grille.publiee` (publication), `routage.degrade` (repli), `effort.calcule` (effort journalisé non facturé pendant la promo) — **déclarés dans `docs/taxonomie-evenements.md` avant implémentation** (tâche dédiée). Le **simulateur n'émet rien** (dry run). Les métriques (MET) en dérivent, aucun KPI manuel.
- [x] **VII. Qualité** : tests d'intégration pour CHAQUE comportement clé (garde de borne, sélection de règle, routage + cache + dégradé, optimisation d'ordre ≤ 4, drapeaux, VND-08 mono/multi, arrondi → part coursier, prime une fois/course, garde de publication, seed Tiassalé au FCFA près) ; `cargo sqlx prepare` après le SQL ; aucune chaîne en dur (clés i18n fr) ; logs corrélés.
- [x] **VIII. Sécurité** : édition de grille, simulation et publication **protégées par `Role::Admin`** et journalisées (patron 002/003/005) ; l'évaluation est un **trait interne** (pas de nouvelle surface HTTP non authentifiée) ; aucune donnée personnelle dans les payloads d'événements (distances arrondies, pas de lat/lng brut — minimisation ARTCI).
- [x] **IX. Périmètre** : TRF augmente la **fiabilité et la soutenabilité** des livraisons (prix justes sur km réels, effort infalsifiable rémunérant le coursier) — P0/P1. La **dimension point relais est une PROVISION** (colonne nullable jamais renseignée, aucune logique) ; aucune conversion de devise (provision) ; priorités P0 (TRF-01..05) / P1 (TRF-06) respectées.
- [x] **X. Versions** : aucune nouvelle dépendance tierce — `reqwest`, `redis`, `sqlx`, `utoipa` sont déjà figés au workspace ; réutilisés à leur version verrouillée.
- [x] **XI. Design** : **aucune UI construite** ce cycle (surface admin en API, cible A3 = cycle ADM ; consommateurs CMD/DSP/CRS futurs) → aucune transposition DOM/CSS, aucun écran Flutter. Porte satisfaite par absence de surface visuelle.

**GATE PASSÉ** avant recherche. Re-vérification post-conception en fin de fichier.

## Project Structure

### Documentation (this feature)

```text
specs/007-tarification-moteur-effort/
├── plan.md              # Ce fichier
├── research.md          # Phase 0 — décisions R1..R13
├── data-model.md        # Phase 1 — schéma tarification, migration 0007, pipeline, traits, événements
├── quickstart.md        # Phase 1 — scénarios de validation (SC-001..012)
├── contracts/
│   └── tarification-openapi.md   # Endpoints admin (utoipa), DTO, traits exposés, événements
└── tasks.md             # Phase 2 — /speckit-tasks (NON créé par /speckit-plan)
```

### Source Code (dépôts réellement touchés)

```text
backend/
├── crates/
│   └── tarification/         # NOUVEAU (depuis stub) :
│       ├── modele.rs         #   Grille, Regle, Devis, Composantes, enums, erreurs
│       ├── grille.rs         #   CRUD brouillon, simulation, publication (gardes)
│       ├── regle.rs          #   sélection de la règle la plus spécifique en vigueur
│       ├── routage.rs        #   trait Routage + client OSRM /table + cache Redis + dégradé
│       ├── optimisation.rs   #   permutations ≤ 4 (min distance) + heuristique bornée
│       ├── evaluation.rs     #   pipeline : route→règle→suppléments→effort→arrondi→drapeaux→VND-08
│       ├── effort.rs         #   grille d'effort (paliers, prime/course, supplément d'arrêt)
│       ├── depot.rs          #   PgTarification (lectures pool + écritures &mut tx, outbox)
│       ├── ports.rs          #   traits exposés : EvaluationTarifaire, OptimisationArrets
│       └── lib.rs
├── api/
│   └── src/
│       └── admin_tarification_http.rs   # NOUVEAU : brouillon CRUD, simuler, publier (Role::Admin)
└── migrations/
    └── 0007_tarification.sql            # schéma tarification (grille, regle) — 0001..0006 intouchées

backend/seeds/
└── 50_tarification_tiassale.sql         # NOUVEAU : grille seed Tiassalé + params de zone (bornes,
                                         #   arrondi, facteur dégradé, TTL, seeds d'effort, plafonds)

docs/
└── taxonomie-evenements.md              # + grille.publiee, routage.degrade, effort.calcule

clients/                                  # RÉGÉNÉRÉS depuis openapi.json (jamais édités)
infra/                                    # inchangé (OSRM/Redis/Postgres déjà en place)
```

**Structure Decision** : **backend seul**. Un nouveau crate de domaine `tarification` (schéma Postgres propre), un nouveau module HTTP admin (`admin_tarification_http`), une migration (`0007`) et un seed (`50_`). Aucune app Flutter ni page Nuxt : la surface admin (A3) est au cycle ADM, les consommateurs du devis (CMD/DSP/CRS) sont futurs — TRF expose des **traits**, exercés par des courses simulées dans les tests (patron cycle 006).

## Complexity Tracking

| Violation potentielle | Pourquoi nécessaire | Alternative plus simple rejetée parce que |
|-----------|------------|-------------------------------------|
| **Catalogue de règles versionné en schéma `tarification`** (tension avec principe I « paramétrable → configuration de zone ») | Une grille est un ensemble **multi-lignes, priorisé, à dates d'effet, avec un cycle brouillon → en vigueur → historique** et une garde de simulation. Ce n'est pas un paramètre scalaire. Les **knobs** scalaires (bornes de marge, arrondi, facteur dégradé, TTL, seeds d'effort, plafonds, drapeaux) restent, eux, en configuration de zone héritée. | Le store clé-valeur `zones.parametre_zone` (héritage par clé) **ne peut pas** modéliser un catalogue versionné multi-lignes ni le workflow brouillon/simulation/publication sans le dénaturer en blobs JSON opaques — ce qui détruirait la sélection de règle, l'héritage par paramètre et la traçabilité de version. Le schéma de module est le bon lieu (constitution II : un schéma par module), keyé par `zone_id`. |
| **Introduction du client de routage OSRM** (aucune violation — inscription explicite) | TRF-02 (P0) EXIGE des distances par itinéraire routier ; aucun client de routage n'existe (QRC faisait une proximité point-rayon, pas un itinéraire). C'est le premier consommateur, prévu par la constitution IV et l'infra existante. | N/A — conforme au principe IV ; consigné ici pour mémoire de la nouveauté d'infrastructure applicative (client, cache, dégradé). |

## Phase 0 — Recherche

Toutes les inconnues techniques sont résolues (stack imposée, infra OSRM/Redis déjà en place). Les décisions de conception — découpage du crate, service OSRM `/table` vs `/route`, stratégie de cache, réconciliation marge 0/bornes par drapeau, sélection de règle déterministe, optimisation d'ordre, versionnage + garde de publication, devise par zone, entrée VND-08 simulée, événements, découplage de la géométrie — sont consignées dans **[research.md](./research.md)** (R1..R13). Aucun `NEEDS CLARIFICATION` résiduel (la clarification du 2026-07-24 sur la prime d'attente est intégrée).

## Phase 1 — Conception & contrats

- **[data-model.md](./data-model.md)** : schéma `tarification` et migration `0007` (grille, regle, enums, index dont l'unicité partielle « une grille en vigueur par zone »), les **knobs de zone** seedés, le **pipeline d'évaluation** (ordre exact, invariants monétaires, drapeaux, VND-08, arrondi → part coursier, prime d'attente une fois/course), les **traits exposés** (`EvaluationTarifaire`, `OptimisationArrets`, `Routage`) et les **événements outbox**.
- **[contracts/tarification-openapi.md](./contracts/tarification-openapi.md)** : endpoints admin (`#[utoipa::path]`), DTO `ToSchema` (règle, brouillon, résultat de simulation détaillé), gardes de rôle, codes d'erreur i18n, le tableau des événements, et la signature des traits consommés par CMD/DSP.
- **[quickstart.md](./quickstart.md)** : scénarios de validation de bout en bout (SC-001..012) avec le double de routage et les géométries de course simulées.

## Post-Design Constitution Re-Check

Re-vérifié après Phase 1 : aucune nouvelle violation. Le tronc `commande` n'est pas touché ; l'évaluation reste découplée de la logistique (géométrie en entrée) ; les montants sont des entiers en unités mineures avec devise de zone ; le routage respecte le principe IV (cache, dégradé tracé, jamais bloquant) ; les trois événements sont minimisés ARTCI et déclarés avant implémentation ; les surfaces d'écriture sont protégées par `Role::Admin` ; le simulateur est sans effet de bord. Le seul écart consigné (catalogue versionné en schéma module) est justifié en Complexity Tracking. **GATE PASSÉ — prêt pour `/speckit-tasks`.**
