# Specification Quality Checklist: QR prestataire, plaque et scans de collecte

**Purpose**: Validate specification completeness and quality before proceeding to planning
**Created**: 2026-07-22
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

- Périmètre recentré après lecture du code livré : le cycle 005 porte déjà le jeton, le code de secours, la validité dérivée (révocation) et la résolution du jeton. Ce cycle construit les PARCOURS (plaque PDF, scan, distance, photo, mode dégradé) — reflété dans la section « Ce que ce cycle NE construit PAS » et FR-006/FR-007.
- `/speckit-clarify` a tourné le 2026-07-22 : 3 questions posées (uniquement des points ABSENTS des docs, après vérification et citation des sections), 3 réponses (options recommandées retenues), intégrées en `## Clarifications`. (1) Ce cycle introduit la structure d'arrêt-collecte **documentée** (`livraison → segment → arrêt`, statut {à collecter, collecté, indisponible}) comme socle + course simulée en test ; (2) incident « plaque à remplacer » créé dès le basculement en mode dégradé, une fois par arrêt ; (3) collecte hors-ligne refusée à la synchro → arrêt « à collecter » + coursier notifié. Corrections d'alignement doc appliquées : statut `indisponible` ajouté, bornage EN_LIVRAISON, machine d'états citée.
- Domaine de la plaque : `mefali.com` (docs user-stories-v2 et cadrage-v5 harmonisés le 2026-07-22 ; `.com` déjà présent dans le prompt, le fichier de prompts et la recherche du cycle 005). Cohérent dans toute la spec.
- 16/16 items au vert après clarification (aucune régression). Reste un paramètre à seeder au « Récapitulatif des paramètres de zone » lors du plan : le seuil de montant forçant la photo (non bloquant). Prêt pour `/speckit-plan`.
