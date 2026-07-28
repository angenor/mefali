# Specification Quality Checklist: App coursier — course active multi-arrêts, cash et hors-ligne

**Purpose**: Validate specification completeness and quality before proceeding to planning
**Created**: 2026-07-28
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

- Itération 1 (2026-07-28, `/speckit-specify`) : 17 des 18 items passent — seuls
  les marqueurs de clarification restaient, sur 3 points sans défaut raisonnable.
- Itération 2 (2026-07-28, `/speckit-clarify`) : **18 / 18**. Trois questions
  candidates ont d'abord été **retirées** parce que les documents produit les
  tranchaient — frontière caisse / admin (**ADM-07** nomme la validation
  d'indemnisation, le fonds et l'exposition), lien de paiement sur place
  (**PAY-03**, P1, tranche T3), émission de la sonnerie (**NTF-01**, story
  distincte). Les trois questions restantes ont été posées et intégrées :
  1. **Fonctionnement continu écran éteint** → oui, tant que le coursier est en
     ligne (FR-111 à FR-115, SC-018, SC-019).
  2. **Autorisation du dépôt** → drapeau de commande fermé par défaut, ouvrable
     par l'exploitation avec motif tracé (FR-039, FR-048, FR-116).
  3. **Avance sur commande prépayée** → déférée à PAY (tranche T3) ; l'avance
     reste visible comme **non soldée** au lieu de disparaître (FR-117).
- Contrôles de cohérence passés sans écart : aucun montant en décimal, aucune
  chaîne utilisateur en dur, tous les paramètres nouveaux renvoyés à la
  configuration de zone (FR-105), périmètre CRS-07 et paie fixe explicitement
  exclus (FR-108, FR-110), aucune reconstruction de ce que les cycles 006, 008 et
  009 ont déjà livré.
- Deux limites sont assumées et écrites dans la spec plutôt que masquées : une
  avance non soldée sur commande prépayée jusqu'au cycle PAY, et deux écarts de
  maquette (paie fixe de K1-1c, lien mobile money de K4-1a).
- Itération 3 (2026-07-28, après `/speckit-analyze`) : **18 / 18** maintenus. Le
  contrôle croisé spec ↔ plan ↔ tâches ↔ constitution a trouvé 17 écarts, tous
  corrigés — dont un **CRITICAL** (un paramètre de zone dupliquait
  `commande.essais_code_livraison`, déjà seedé et lu en production depuis le cycle
  008) et un **HIGH** de conception (la voie « dépôt » attendait une photo déjà
  déposée, donc ne pouvait pas fonctionner hors ligne : l'endpoint de remise passe
  en multipart). La spec gagne FR-048b, FR-036 gagne son support de données
  (issue déclarée d'appel), et les sections FR sont réordonnées.
