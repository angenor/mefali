# Specification Quality Checklist: Prestataires agréés et catalogue vendeur

**Purpose**: Validate specification completeness and quality before proceeding to planning
**Created**: 2026-07-18
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

- Aucun marqueur [NEEDS CLARIFICATION] : les sept décisions structurantes ont été tranchées par le fondateur et consignées dans la section Clarifications — surface d'interface du cycle, périmètre QR, levée du masquage automatique, absence de cascade sur le rôle vendeur, silence de l'échéance de pause, éligibilité du signalement coursier, rétention de la charte et des photos.
- Vocabulaire technique volontairement neutralisé, dans la continuité du cycle 003 : « Garage / S3 » est exprimé « stockage objet sécurisé à accès restreint » ; « jeton HMAC » est exprimé « jeton signé révocable » ; « endpoint » est exprimé « capacité exposée ». Le mapping exact relève du plan (constitution, principes II et VIII).
- Spécification revue par sept lentilles indépendantes (couverture des critères produit, fuites de périmètre, conformité aux 12 principes, cohérence avec le code déjà livré, testabilité, cohérence interne, gabarit maison), chaque constat ayant été soumis à trois réfutateurs. La revue a été interrompue par une limite de session avant sa synthèse : les 94 constats bruts ont été dédoublonnés et arbitrés manuellement. Deux contradictions bloquantes en sont issues et sont corrigées — l'événement impossible à l'échéance de pause, et la cascade de suspension qui aurait fait échouer la suspension entière.
- Trois exigences décrivent une capacité que ce cycle livre mais qu'un module ultérieur exercera : le verrouillage d'un prix (FR-024), la précondition de commande active du signalement coursier (FR-038) et l'état « commandable » (FR-028). Elles sont testées par déclencheur simulé, patron établi au cycle 003 pour l'enregistrement d'adresse après livraison.
- Le préalable documentaire est levé : les deux paramètres de zone créés par ce cycle — mode d'affichage des articles en rupture par catégorie (seed « grisé », FR-042 et FR-049) et conservation de la charte après la fin de la relation (seed 5 ans, FR-026) — ont été inscrits au « Récapitulatif des paramètres de zone » de `docs/user-stories-v2.md` le 2026-07-18, conformément à la règle de gouvernance qui veut que les documents produit soient mis à jour avant la spécification qui en dépend.
- Une exception au principe VIII est assumée et documentée : la consultation de la fiche et du catalogue (FR-027) est publique en lecture seule, limitée au sous-ensemble destiné aux applications. C'est le précédent exact de la configuration distante du cycle 002, et le cadrage §3.1 et §5.3 font de la plaque un canal d'acquisition — une fiche que seul un porteur de compte pourrait lire n'en serait pas un.
- Items marked incomplete require spec updates before `/speckit-clarify` or `/speckit-plan` — aucun item incomplet.
