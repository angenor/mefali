# Specification Quality Checklist: Cycle de vie complet d'une commande multi-vendeurs

**Purpose**: Validate specification completeness and quality before proceeding to planning
**Created**: 2026-07-25
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

### Itération 1 — 2026-07-25

**Écarts corrigés avant cette passe** :

- Les noms de tables et de champs présents dans la description d'entrée (`resto_details`, `ServiceWorkflow`, `mixable`, MinIO) ont été reformulés en langage métier dans le corps de la spec — « table de détails dédiée derrière le trait de workflow de service », « catégorie déclarée mixable », « stockage objet » — pour tenir le critère « pas de détail d'implémentation ». Les identifiants techniques ne subsistent que dans la citation d'entrée et dans la section « Ce que ce cycle NE construit PAS », où ils désignent des artefacts **déjà livrés** qu'il faut pouvoir retrouver.
- Les seuils numériques sont systématiquement présentés comme **valeurs par défaut de zone** (FR-064), jamais comme constantes — conformité constitution I.
- SC-007 ne préjuge pas de la réponse à FR-050 : il porte sur l'égalité entre total annoncé et total encaissé, vraie dans les deux options.

**3 marqueurs [NEEDS CLARIFICATION]** avaient été posés (limite du gabarit : 3 maximum), tous de portée « scope ». Ils ont été tranchés en séance et propagés :

| Marqueur | Question | Décision | Propagé dans |
|---|---|---|---|
| FR-068 | Écrans clients Flutter (C3 panier, C4 suivi) dans le périmètre ? | **Oui** — domaine + API + écrans clients ; coursier et admin hors périmètre | FR-068, « Surface d'interface », Assumptions |
| FR-050 | Devis de livraison refigé après substitution, ou figé à la création ? | **Figé** — seul le montant des articles est révisé | FR-050, US7 (récit, test indépendant, scénario 7), SC-007 |
| FR-062 | Frontière CMD-08 ↔ litiges (AVI-04) et caisse (CRS-06) | **Décider, journaliser, sanctionner, émettre** — sans construire litige ni caisse | FR-062, tableau des modules simulés, US9 |

### Itération 2 — validation finale

Tous les items passent. Contrôles automatiques : **0** marqueur restant, **0** placeholder de gabarit, **68** exigences numérotées sans trou ni doublon (FR-001→FR-068), **11** critères de succès, **9** user stories chacune dotée d'un test indépendant et de scénarios Given/When/Then.

Contrôles de fond :

- **Testabilité** — chaque exigence est vérifiable par observation d'un comportement (refus, montant, événement, affichage) ; aucune n'emploie de formulation subjective.
- **Agnosticisme technologique des critères de succès** — les 11 SC portent sur des durées, des taux, des égalités de montants et des couvertures de tests ; aucun ne nomme de technologie.
- **Bornes de périmètre** — les exclusions (CMD-09 multi-segment, réaffectation vers un autre vendeur, apps coursier et admin) sont énoncées, et la section « Ce que ce cycle NE construit PAS » recense les cinq cycles dont les acquis sont consommés tels quels.
- **Traçabilité produit** — les 9 stories couvrent CMD-01 à CMD-08 et CMD-10 ; leur priorité P1→P3 est explicitement présentée comme un ordre de livraison interne, la priorité produit restant P0 partout (constitution IX).

**Statut : prêt pour `/speckit-plan`.**
