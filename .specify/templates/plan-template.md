# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link]

**Input**: Feature specification from `/specs/[###-feature-name]/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

[Extract from feature spec: primary requirement + technical approach from research]

## Technical Context

<!--
  ACTION REQUIRED: Replace the content in this section with the technical details
  for the project. The structure here is presented in advisory capacity to guide
  the iteration process.
-->

**Language/Version**: [e.g., Python 3.11, Swift 5.9, Rust 1.75 or NEEDS CLARIFICATION]

**Primary Dependencies**: [e.g., FastAPI, UIKit, LLVM or NEEDS CLARIFICATION]

**Storage**: [if applicable, e.g., PostgreSQL, CoreData, files or N/A]

**Testing**: [e.g., pytest, XCTest, cargo test or NEEDS CLARIFICATION]

**Target Platform**: [e.g., Linux server, iOS 15+, WASM or NEEDS CLARIFICATION]

**Project Type**: [e.g., library/cli/web-service/mobile-app/compiler/desktop-app or NEEDS CLARIFICATION]

**Performance Goals**: [domain-specific, e.g., 1000 req/s, 10k lines/sec, 60 fps or NEEDS CLARIFICATION]

**Constraints**: [domain-specific, e.g., <200ms p95, <100MB memory, offline-capable or NEEDS CLARIFICATION]

**Scale/Scope**: [domain-specific, e.g., 10k users, 1M LOC, 50 screens or NEEDS CLARIFICATION]

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Portes dérivées de `.specify/memory/constitution.md` (v1.0.0) — cocher ou
justifier dans Complexity Tracking :

- [ ] **I. Sources de vérité** : aucun client `clients/dart`/`clients/ts`
  édité à la main ; tout changement de schéma = NOUVELLE migration sqlx ;
  tout paramètre « paramétrable » en configuration de zone (héritage), pas en
  dur.
- [ ] **II. Architecture** : travail dans les crates de domaine existants (ou
  nouveau crate justifié) ; aucun champ logistique dans le tronc commande ;
  aucune supposition « commande = livraison » ni « prestataire = vendeur »
  dans un crate partagé ; spécificités de vertical derrière `ServiceWorkflow` ;
  Redis éphémère uniquement, Postgres seule vérité durable.
- [ ] **III. Argent** : montants en entiers unités mineures + ISO 4217 de
  zone ; jamais de float ; prix verrouillés à la création ; aucun paiement
  partiel.
- [ ] **IV. Distances** : itinéraire routier OSRM (waypoints, cache Redis) ;
  tout vol d'oiseau = dégradé ×1,4 explicite, `degraded=true`, journalisé ;
  le routage ne bloque jamais une commande.
- [ ] **V. Offline & idempotence** : toute action coursier porte UUID client +
  horodatage local, file locale hors réseau, rejeu idempotent, serveur fait
  foi.
- [ ] **VI. Événements** : chaque transition d'état écrit un événement outbox
  dans la même transaction ; événements du parcours déclarés dans
  `docs/taxonomie-evenements.md`.
- [ ] **VII. Qualité** : tests d'intégration prévus pour chaque transition de
  machine à états ; `cargo sqlx prepare` après tout changement SQL ; aucune
  chaîne utilisateur en dur (clés i18n fr).
- [ ] **VIII. Sécurité** : endpoints protégés par rôle ; pas de nouvelle
  surface non authentifiée sans justification ; rétention limitée des médias.
- [ ] **IX. Périmètre** : la feature augmente les commandes/jour ou la
  fiabilité des livraisons ; PROVISIONS = modèle de données seulement (aucune
  UI, aucune logique) ; priorités P0/P1/P2/PROVISION de
  `docs/user-stories-v2.md` respectées.
- [ ] **X. Versions** : toute nouvelle dépendance en dernière version stable,
  figée par lockfile.
- [ ] **XI. Design** : UI Flutter en widgets Material 3 + `mefali_core` depuis
  `docs/design/tokens.md` ; jamais de transposition DOM/CSS de
  `docs/design/html/` (exception : admin Nuxt) ; pas de variante Cupertino
  (constructeurs `.adaptive`).

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)
<!--
  ACTION REQUIRED: Ne conserver ci-dessous que les répertoires du monorepo
  Mefali réellement touchés par cette feature, développés avec les chemins
  réels (crates, écrans, pages). Le plan livré ne liste pas de répertoires non
  concernés.
-->

```text
backend/
├── crates/<domaine>/     # zones, comptes, prestataires, qr, tarification,
│                         # commandes, dispatch, coursier, paiements,
│                         # notifications, avis, metriques
├── api/                  # binaire Actix (assemble les crates, expose utoipa)
└── migrations/           # migrations sqlx versionnées + seeds/

apps/
├── mefali_client/        # Flutter — app client
├── mefali_pro/           # Flutter — app coursier + vendeur
└── packages/
    └── mefali_core/      # thème M3, composants partagés, offline queue

clients/
├── dart/                 # GÉNÉRÉ depuis openapi.json — jamais édité à la main
└── ts/                   # GÉNÉRÉ depuis openapi.json — jamais édité à la main

web/                      # Nuxt 4 (public SSR + /admin/** ssr:false)
infra/                    # docker-compose dev (Postgres, Redis, Garage, OSRM)
```

**Structure Decision**: [Lister les répertoires réellement touchés par cette
feature et pourquoi]

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
