# Specification Quality Checklist: Dispatch automatique — assignation des courses sans intervention humaine

**Purpose**: Validate specification completeness and quality before proceeding to planning
**Created**: 2026-07-26
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

**Itération 1 (2026-07-26, `/speckit-specify`)** — 15/16. Un seul item en échec :
3 `[NEEDS CLARIFICATION]` sur le périmètre de surface (FR-093, FR-094, FR-095).

**Itération 2 (2026-07-26, `/speckit-clarify`)** — **16/16**. Les 3 marqueurs sont
levés, deux par les documents produit, un par décision de l'utilisateur.

- **FR-094 tranché par les documents** : `docs/user-stories-v2.md` §0.5 met NTF-01
  dans la même tranche T1 que DSP-01→05 comme story **distincte**, et §0.6
  l'attribue au module NTF. Le transport de l'offre n'est donc pas l'affaire de ce
  cycle : contrat d'émission ici, push et sonnerie avec NTF-01.
- **FR-095 tranché par les documents** : le « Récapitulatif des paramètres de zone »
  (qui fait foi) nomme la ligne « Réassignation **sans mouvement** / sans scan », et
  le cadrage §7.3 étape 6 dit « pas de **mouvement vers le vendeur** ». Le premier
  critère est géographique ; la dimension d'état est portée par le second critère,
  « sans scan ». La formulation « pas de progression » de DSP-07 paraphrase la même
  ligne. FR-095 est réaffecté à la conformité visuelle des surfaces construites.
- **FR-093 tranché par l'utilisateur** (question 1) : le cycle construit l'écran
  d'offre K2 **et** la tranche de disponibilité dont le pool dépend.
- **Une ambiguïté neuve, trouvée au balayage** (question 2) : deux commandes prêtes
  au même instant pouvaient offrir simultanément au même coursier, le verrou de
  DSP-04 n'étant posé que par commande. Résolu par une **seconde exclusivité par
  coursier**, prise atomiquement avec celle de la commande → FR-056, FR-057,
  FR-059, FR-062, US4 (scénarios 10-11), US5 (scénario 5), SC-014.
- **Deux ambiguïtés supplémentaires levées sans question**, sources citées :
  l'écran d'opérations admin est en tranche T3 (§0.5, §0.6) — son absence est le
  découpage produit, pas un arbitrage ; et l'acceptation d'une offre n'entre pas
  dans la file d'actions hors-ligne, dont CRS-08 énumère limitativement le contenu.

**Écarts assumés, jugés conformes après vérification :**

- **Mentions du mot « API »** (5 occurrences) : toutes sont des **déclarations de
  frontière de périmètre** (« exercés par API, jamais construits ici »), pas des
  choix techniques. C'est la convention déjà retenue au cycle 008 (FR-068) pour
  dire quelle surface est livrée et laquelle est simulée ; la retirer rendrait le
  périmètre indécidable.
- **Le bloc `**Input**`** reproduit la description utilisateur **verbatim**, gabarit
  oblige, et contient donc ses termes techniques (pool temps réel, verrou en
  création exclusive, heartbeats). Le corps de la spécification, lui, ne les
  reprend pas : le pool y est « éphémère et reconstructible », le verrou une
  « exclusivité éphémère », la publication de position un fait métier.
- **Décisions tranchées sans question** (8, chacune avec sa section source citée)
  documentées en tête de la spécification : absence de note, réutilisation du seuil
  d'escalade existant, capacité requise à persister, rayon mesuré au premier arrêt
  de collecte, période de publication déjà paramétrée, condition réelle de la
  bascule prépaiement, arrêt de la réassignation à la première collecte,
  affectation par le contrat offert. Chacune évite une question de plus.

**Couverture** : 7 user stories (une par story produit DSP-01→07, toutes P0),
81 exigences fonctionnelles, 15 critères de succès mesurables, 13 cas limites,
18 paramètres de zone énumérés, 5 modules non construits avec leur frontière
explicite, 2 surfaces coursier construites (disponibilité, écran d'offre).
