# Specification Quality Checklist: Moteur de tarification à règles, routage et grille d'effort

**Purpose**: Validate specification completeness and quality before proceeding to planning
**Created**: 2026-07-24
**Feature**: [spec.md](../spec.md)

## Content Quality

- [x] No implementation details (languages, frameworks, APIs)
- [x] Focused on user value and business needs
- [x] Written for non-technical stakeholders
- [x] All mandatory sections completed

## Requirement Completeness

- [x] No [NEEDS CLARIFICATION] markers remain
- [x] Requirements are testable and unambiguous
- [x] Success criteria are measurable
- [x] Success criteria are technology-agnostic (no implementation details)
- [x] All acceptance scenarios are defined
- [x] Edge cases are identified
- [x] Scope is clearly bounded
- [x] Dependencies and assumptions identified

## Feature Readiness

- [x] All functional requirements have clear acceptance criteria
- [x] User scenarios cover primary flows
- [x] Feature meets measurable outcomes defined in Success Criteria
- [x] No implementation details leak into specification

## Notes

- Items marked incomplete require spec updates before `/speckit-clarify` or `/speckit-plan`

### Validation summary (2026-07-24)

Tous les items passent. Points ayant demandé une décision, résolus par des hypothèses documentées plutôt que par des marqueurs [NEEDS CLARIFICATION] (aucun n'atteignait le seuil « impact de périmètre + interprétations multiples + aucun défaut raisonnable ») :

- **VND-08** (référencé par le critère TRF-02 « tel quel » alors que la config vendeur n'est pas construite) → créneau de calcul réservé + entrée simulée ; config vendeur (VND) et retenue à la source (PAY) hors périmètre. Consigné en FR-018, Assumptions, Dependencies — même patron que le cycle 006 (course simulée).
- **Plafond d'éclatement** (« seuil à définir » dans les docs) → paramètre de zone, mécanique spécifiée, valeur seed à calibrer pendant la promo (Annexe B). Non bloquant (FR-032, Assumptions).
- **Consommateurs du devis / optimisation d'ordre** (CMD/DSP/CRS non construits) → capacité exposée et exercée par courses simulées en tests ; ordre optimisé exposé à DSP/CMD (FR-030, FR-031, Assumptions).
- **Imputation de l'arrondi** entre part coursier et marge → **résolu au /speckit-clarify du 2026-07-24** : reliquat → part coursier, marge fixe (§9.3 « marge fixe » / §7.5 « le coursier ne perd jamais » / maquette A3). Reflété en FR-016, FR-019.

Frontières explicites : hors périmètre = console admin (ADM), verrouillage/affichage (CMD), offre coursier (DSP/CRS), scission effective (CMD), config VND-08 + retenue (VND/PAY), commission vendeur (PAY-06), conversion de devise (provision) — FR-036.

### Session de clarification (2026-07-24)

1 question posée (la seule qu'aucune source ne tranchait), 5 ambiguïtés candidates résolues par citation directe des docs/design — conformément à la directive « ne pose que ce qui n'est pas dans les docs ».

- **Question posée** — Prime d'attente, agrégation multi-arrêts → **une seule fois par course** (+100 max). Reflété en FR-028/029, US6 sc.3, Edge Cases, section Clarifications.
- **Résolu par les sources (sans question)** : origine de l'itinéraire tarifé = retraits → client, sans jambe coursier (TRF-03 + A3 + CMD-01, FR-013) ; objectif d'optimisation = distance routière totale minimale (§9.3, FR-031) ; « distance au précédent arrêt » = tronçon routier (constitution IV, FR-029) ; imputation de l'arrondi = part coursier / marge fixe (§9.3/§7.5/A3, FR-016/019) ; simulation réarmée par toute édition (A3, FR-021).

Aucune régression de checklist : les 16 items restent satisfaits, la précision est renforcée (exigences davantage testables, contradiction latente FR-013 levée).

### Traçabilité critères produit → stories

- TRF-01 → User Story 1 (P1 interne / produit P0)
- TRF-02 → User Story 2 (P1 interne / produit P0)
- TRF-03 → User Story 3 (P2 interne / produit P0)
- TRF-05 → User Story 4 (P2 interne / produit P0)
- TRF-04 → User Story 5 (P2 interne / produit P0)
- TRF-06 → User Story 6 (P3 interne / produit **P1**, requise avant la fin de la promo)
