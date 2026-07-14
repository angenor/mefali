# Implementation Plan: Arbre de zones et configuration héritée

**Branch**: `002-zones-config-heritee` | **Date**: 2026-07-13 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/002-zones-config-heritee/spec.md`

## Summary

Créer le référentiel géographique (arbre de zones à profondeur variable) et
le mécanisme de configuration héritée parent → enfant avec surcharge au
paramètre près — la brique que TOUS les modules suivants consommeront via le
trait `ConfigurationZones` du crate `zones`. Approche : stockage clé/valeur
par zone (`zones.parametre_zone`, une ligne = un paramètre défini), CTE
récursive + fusion en Rust avec provenance, catégories et types de transport
comme enregistrements de configuration, endpoint public `GET /config?zone=`
versionné par empreinte (SHA-256 canonique, ETag), unique écriture admin
(forçage de catégorie) journalisée par outbox, seeds Tiassalé rejouables à
UUID fixes, et module `config` de `mefali_core` (cache local + refresh
horaire) branché dans les deux apps. Détail des décisions :
[research.md](research.md) R1–R10.

## Technical Context

**Language/Version**: Rust 1.97 (workspace backend, édition 2021) ; Dart/Flutter stable (apps) ; TypeScript (client généré, non touché à la main)

**Primary Dependencies**: Actix Web 4.14 + utoipa 5.5/utoipa-actix-web (contrat), sqlx 0.9 (Postgres, macros vérifiées), socle (outbox, config env, télémétrie) ; nouveaux : `sha2` (version de config, R3), `actix-governor` (rate-limit /config, R4), côté Flutter `shared_preferences` + client généré `mefali_api_client` (R7) — dernières versions STABLES vérifiées puis figées à l'implémentation (constitution X)

**Storage**: PostgreSQL seul (schéma dédié `zones`, migration `0002_zones.sql`) — Redis/Garage/OSRM NON utilisés ce cycle (R8)

**Testing**: `cargo test` avec `#[sqlx::test(migrations = "../migrations")]` (comme le socle) pour domaine + endpoints ; `flutter test` + `fake_async` pour cache/refresh de mefali_core

**Target Platform**: backend Linux (VPS docker compose, migrations embarquées au démarrage) ; apps Android/iOS ; contrat servi sur `/api-docs/openapi.json`

**Project Type**: monorepo — crate de domaine backend + endpoint public + module partagé Flutter (aucune UI ce cycle)

**Performance Goals**: résolution < 10 ms (chaîne ≤ 6 niveaux, 2 requêtes indexées) ; `/config` p95 < 100 ms en local ; polling horaire des apps économisé par ETag/304

**Constraints**: `/config` public en lecture seule limité à la liste blanche de namespaces (clarification Q1, R4) ; UNE seule écriture admin, gardée par jeton temporaire (clarification Q2, R5) ; paramètres jamais en dur (constitution I) ; absence explicite ≠ valeur définie (FR-009) ; seeds déterministes à UUID fixes (SC-008)

**Scale/Scope**: MVP = 1 pays + 1 ville (Tiassalé), 6 catégories, 8 types de transport, < 100 clés de paramètres ; conçu pour des dizaines de zones et de nouveaux namespaces sans migration (FR-011)

## Constitution Check

*GATE: passée avant la Phase 0 ; re-vérifiée après la Phase 1 — conforme, 2
écarts justifiés en Complexity Tracking.*

- [x] **I. Sources de vérité** : clients régénérés par `scripts/generate-clients.sh` uniquement ; NOUVELLE migration `0002_zones.sql` (0001 intouchée) ; ce cycle CRÉE le mécanisme « tout paramètre paramétrable en configuration de zone » — seuils et mixable y compris (pas de colonnes dupliquées, R1).
- [x] **II. Architecture** : tout le domaine dans le crate `zones` existant ; trait de lecture `ConfigurationZones` (R2) ; aucun champ logistique, aucune supposition commande/livraison ni prestataire/vendeur (le comptage de vendeurs est un paramètre d'entrée, R6) ; Redis non utilisé ; Postgres seule vérité durable.
- [x] **III. Argent** : `Devise { code ISO 4217, decimales }`, montants entiers en unités mineures (XOF 0 décimale) ; aucun flux d'argent ce cycle.
- [x] **IV. Distances** : N/A — aucune distance calculée ce cycle.
- [x] **V. Offline & idempotence** : aucune action coursier ; le cache config des apps est en lecture seule (pas de file d'actions) ; seeds idempotents.
- [x] **VI. Événements** : `zone.parametre_modifie`, `categorie.forcage_change`, `categorie.activation_changee` écrits via `socle::ecrire_evenement` dans la MÊME transaction (R9) ; registre `docs/taxonomie-evenements.md` mis à jour AVANT implémentation.
- [x] **VII. Qualité** : tests d'intégration sur TOUTES les transitions d'activation/forçage (data-model §3) + matrice de résolution exhaustive (FR-008) ; `cargo sqlx prepare` après tout SQL ; `nom_cle`/`message_cle` = clés i18n fr, aucune chaîne UI en dur.
- [x] **VIII. Sécurité** : 2 écarts JUSTIFIÉS (Complexity Tracking) — `/config` public (clarification Q1 de la spec) et garde admin par jeton d'environnement en attendant CPT (R5) ; rate-limit par IP ; aucun média, pas de rétention en jeu.
- [x] **IX. Périmètre** : stories P0 de la tranche T1 (fondation des commandes/jour) ; `village`/`quartier` = PROVISION données seulement (aucun écran, aucune logique dédiée) ; ZON-05 hors périmètre ; priorités de `docs/user-stories-v2.md` respectées.
- [x] **X. Versions** : `sha2`, `actix-governor`, `shared_preferences` en dernière version stable vérifiée à l'implémentation puis figée par lockfile.
- [x] **XI. Design** : AUCUNE UI ce cycle (écrans admin en T3) ; rien à transposer ; le module config de `mefali_core` est purement logique.

## Project Structure

### Documentation (this feature)

```text
specs/002-zones-config-heritee/
├── plan.md              # Ce fichier
├── research.md          # Phase 0 — décisions R1–R10
├── data-model.md        # Phase 1 — schéma zones, transitions, seeds
├── quickstart.md        # Phase 1 — validation de bout en bout
├── contracts/
│   └── openapi-zones.yaml  # Cible des annotations utoipa (/config, forçage)
└── tasks.md             # Phase 2 (/speckit-tasks — PAS créé par /speckit-plan)
```

### Source Code (repository root)

```text
backend/
├── crates/zones/           # LE crate du cycle (vide aujourd'hui)
│   └── src/
│       ├── lib.rs          # exports publics (trait, types, erreurs)
│       ├── modele.rs       # Zone, Devise, ConfigurationEffective, CategorieActive…
│       ├── resolution.rs   # trait ConfigurationZones + fusion avec provenance (R2)
│       ├── arbre.rs        # creer_zone, re-parentage, anti-cycle applicatif
│       ├── parametre.rs    # definir_parametre (validation par clé, événement outbox)
│       └── categorie.rs    # forcer_categorie, recalculer_activation (R6)
├── api/src/
│   ├── lib.rs              # enregistrement des nouveaux services utoipa
│   └── zones_http.rs       # GET /config (public, governor, ETag) + PUT forçage (AdminAuth)
├── migrations/0002_zones.sql   # schéma zones : types énumérés, 5 tables, trigger anti-cycle
└── seeds/10_zones_tiassale.sql # seed Tiassalé rejouable, UUID fixes (data-model §6)

apps/packages/mefali_core/
├── lib/src/config/         # service config distante : fetch (client généré),
│                           # cache shared_preferences, refresh horaire, bootstrap Tiassalé (R7)
└── test/config/            # fake_async : démarrage hors-ligne, refresh, invalidation par version

apps/mefali_client/  apps/mefali_pro/   # branchement du service au démarrage (main), aucun écran

clients/dart/  clients/ts/  openapi.json  # RÉGÉNÉRÉS par script — jamais édités à la main
docs/taxonomie-evenements.md              # +3 événements (R9)
```

**Structure Decision** : un seul crate métier touché (`zones`) + la surface
HTTP dans `api` (même découpe que `health.rs` au cycle 001) ; côté apps,
tout le comportement partagé vit dans `mefali_core` (les deux apps ne font
que l'initialiser) ; Nuxt non touché (clarification Q2 — écrans en T3).

## Livrables attendus (demandés dans l'input du plan)

| Livrable | Où |
|---|---|
| Migrations | `0002_zones.sql` — 3 types énumérés, `zone`, `parametre_zone`, `type_transport`, `categorie`, `activation_categorie`, trigger anti-cycle ([data-model](data-model.md) §1–2) |
| Endpoints (utoipa) | `GET /config` public + `PUT /admin/zones/{zone_id}/categories/{categorie_slug}/forcage` ([contracts/openapi-zones.yaml](contracts/openapi-zones.yaml)) |
| Structures & trait exposés | trait `ConfigurationZones`, `PgZones`, `Devise`, `ConfigurationEffective` (avec provenance), `CategorieActive`, `ErreurZones` ([data-model](data-model.md) §5, [research](research.md) R2) |
| Événements outbox / métriques | `zone.parametre_modifie`, `categorie.forcage_change`, `categorie.activation_changee` — registre taxonomie mis à jour ([research](research.md) R9) ; les métriques d'activation en dériveront (constitution VI) |
| Écrans / widgets | AUCUN (spec) — seul le service config de `mefali_core` + branchement au démarrage des 2 apps |
| Tests d'intégration | matrice de résolution (SC-001), paramètre fictif bout-en-bout (SC-006), anti-cycle, devise irrésolvable, transitions activation/forçage + événements (data-model §3), `/config` (200/304/404/429, liste blanche), seeds ×2 (SC-008), cache/refresh Flutter (SC-007) — parcours complet dans [quickstart.md](quickstart.md) |

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| `/config` non authentifié (principe VIII « chaque endpoint protégé par rôle ») | Les apps ont besoin de la config AVANT toute connexion (accueil §8.1, textes, drapeaux) — clarification Q1 de la spec, tranchée par l'utilisateur | Endpoint authentifié : impose une config embarquée qui dérive du serveur ; double surface public/privé (option C) écartée à la clarification. Mitigation : liste blanche structurelle de namespaces (R4), lecture seule, rate-limit, aucune donnée sensible |
| Garde admin par jeton d'environnement `X-Admin-Token` au lieu du rôle JWT (principe VIII) | L'ordre imposé des cycles (TRX → ZON → CPT) fait que comptes et rôles N'EXISTENT PAS encore, alors que ZON-02 exige le forçage admin testable dès ce cycle (clarification Q2) | Attendre CPT : bloque un critère d'acceptation P0 et inverse l'ordre des cycles ; mini-rôles jetables : refaits en CPT. Mitigation : extracteur `AdminAuth` isolé — CPT remplace la garde sans toucher les handlers (R5) ; comparaison à temps constant ; jeton hors Git (`.env`) |
