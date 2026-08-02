# Specification Quality Checklist: Paiements — chaîne cash tracée par arrêt et prépaiement mobile money via agrégateur

**Purpose**: Validate specification completeness and quality before proceeding to planning
**Created**: 2026-08-01
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

- **Itération 1 (2026-08-01)** — trois marqueurs [NEEDS CLARIFICATION] posés sur des décisions que ni les
  sources produit ni les cycles livrés ne tranchaient : périmètre VND-08 (FR-053), naissance du
  remboursement d'avance prépayée (FR-063), paiement confirmé hors délai (FR-036).
- **Itération 2 (2026-08-01)** — les trois questions ont été tranchées par le porteur du produit,
  toutes sur l'option recommandée, et les réponses sont consignées dans « Clarifications » avec leur
  raison :
  - **Q1 → A** : la déclaration vendeur {jamais, toujours, à partir de X} est construite ici
    (FR-046 à FR-049) ; badge client et merchandising restent à VND-08 (FR-114).
  - **Q2 → A** : la créance qui solde l'avance sur commande prépayée naît **automatiquement** à la
    confirmation de livraison, avec un état de règlement dû → réglé (FR-063, FR-067 à FR-069) ; elle
    n'emprunte pas le chemin de validation des indemnisations, réservé aux cas litigieux.
  - **Q3 → A** : un paiement confirmé après expiration laisse la commande annulée, ouvre un dossier
    « payé hors délai » et notifie le client (FR-036 à FR-038, FR-082).
- Douze autres ambiguïtés candidates ont été tranchées **par les sources** et consignées dans
  « Décisions confirmées par les sources », avec citation de la section qui tranche.
- **Tous les items sont verts.** La spec est prête pour `/speckit-clarify` (facultatif — les zones
  d'ombre connues sont closes) ou directement `/speckit-plan`.
