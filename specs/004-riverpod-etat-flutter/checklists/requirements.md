# Specification Quality Checklist: Gestion d'état des apps Flutter — migration vers Riverpod codegen

**Purpose**: Validate specification completeness and quality before proceeding to planning
**Created**: 2026-07-17
**Feature**: [spec.md](../spec.md)

## Content Quality

- [x] No implementation details (languages, frameworks, APIs) — *sous réserve documentée, voir Notes*
- [x] Focused on user value and business needs
- [x] Written for non-technical stakeholders — *sous réserve documentée, voir Notes*
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
- [x] No implementation details leak into specification — *sous réserve documentée, voir Notes*

## Notes

**Trois items cochés « sous réserve » — la réserve est assumée, pas oubliée.**

1. **« Pas de détail d'implémentation » et « pas de fuite d'implémentation »** : la spec nomme Riverpod dans son titre, ses clarifications et ses hypothèses. C'est irréductible — l'adoption de ce framework **est** l'objet du cycle, pas son moyen. La règle a néanmoins été tenue là où elle a un sens : les 44 exigences fonctionnelles et les 12 critères de réussite sont formulés en vocabulaire agnostique (« porteur d'état », « portée de providers », « notificateur manuel », « surcharge de test »), afin qu'ils restent vérifiables sans connaître le framework et qu'ils survivent à un changement de version. Précédent maison : `001-socle-monorepo` nomme Postgres, Redis, Garage et OSRM pour la même raison.

2. **« Rédigé pour des parties prenantes non techniques »** : le persona unique de ce cycle est l'**Admin (développeur solo)**, et le bénéficiaire est le développement des cycles suivants. Il n'existe pas de partie prenante non technique pour un refactor sans changement visible. Le procédé est repris verbatim du cycle `001-socle-monorepo`, seul précédent rédactionnel de cycle technique du dépôt.

**Trois clarifications résolues** (session du 2026-07-17) : périmètre de `ServiceConfig` (non-réactivité gelée), sort des quatre fonctions injectées par constructeur (elles restent), rattachement produit (TRX-08, P1). Aucun marqueur `[NEEDS CLARIFICATION]` ne subsiste.

**Deux prémisses de la demande initiale corrigées par la cartographie du code**, et consignées en `Assumptions` plutôt que propagées :
- `ServiceConfig` n'est **pas** un `ChangeNotifier` (classe nue, non observée) — le projet n'en compte que **deux**, pas trois.
- Le décompte des tests est **86**, vérifié par exécution, et non « ~80 » comme estimé. Ce chiffre étant un critère de réussite (SC-002), son exactitude est une condition de la validité du cycle.

**Revue adversariale du 2026-07-17** — la spec a été relue par cinq critiques indépendants (faits, cohérence interne, testabilité, style maison, constitution) puis arbitrée. Tous les chiffres ont tenu à l'unité ; **onze défauts confirmés ont été corrigés**, dont deux exigences qui étaient **fausses sur le comportement actuel** :

- **FR-024** affirmait que la première requête de configuration part *avant le premier rendu*. Faux : le point d'entrée déclenche l'amorçage **sans l'attendre**, et celui-ci se suspend d'abord sur une lecture de plateforme — la requête part donc après le premier rendu. Les deux moitiés de l'exigence étaient jointement insatisfiables : un implémenteur obéissant à la lettre **avançait** la requête et violait SC-004, dans le cycle dont l'invariant est « rien ne change ». Reformulée : amorçage impératif au lancement, non attendu.
- **FR-013 / SC-005** exigeaient « exactement un intercepteur d'autorisation **par client HTTP** ». Faux au départ (le client généré en installe quatre sur chaque client : config = 4, session = 5) et contradictoire avec FR-017. Le critère était donc **incomptable** — alors qu'il est l'unique garde mesurable du mode de panne n°1 du cycle. Reformulé par client, avec les quatre intercepteurs générés explicitement hors décompte.

Autres corrections : TRX-08 écrite dans `docs/` **avant** la spec (la spec l'affirmait sans que ce soit vrai) et FR-040 requalifié en prérequis ; l'argument constitutionnel refondé (il s'appuyait sur une citation retouchée de `research.md:40` et sur un mot que la constitution a précisément supprimé) ; l'exception `session_auth_test` nommée dans FR-003 (FR-003+FR-004+FR-008 y étaient jointement insatisfiables) ; la politique de code généré corrigée (trois politiques coexistent dans le dépôt, pas deux) ; `DOIT` substitué à `MUST` (convention maison, 3 specs sur 3, six négations étaient agrammaticales).

**Contre-vérification du 2026-07-17 (seconde passe)** — les 11 corrections ont été re-contrôlées par quatre vérificateurs indépendants de leur auteur : toutes **appliquées** et vraies au code, aucune référence croisée cassée par la réécriture (FR-001→043 sans saut). Cinq défauts résiduels ont été trouvés et corrigés, dont **deux hérités du verdict lui-même**, recopiés fidèlement :

- **L'Edge Case sur l'amorçage paresseux décrivait un piège inexistant** : il plaçait le premier lecteur de configuration à l'écran de consentement, alors que `RacineAuth` — le `home:` des deux applications — la lit dans son `initState`, donc à chaque lancement (l'écran de consentement, lui, ne lit rien : il reçoit la version en paramètre). Le piège réel est ailleurs, et il est plus intéressant : c'est le geste que l'idiome invite *ensuite*, déplacer la lecture vers les écrans qui en ont besoin. Réécrit — dans une section qui promet que chaque cas correspond à un piège du code réel, une ligne fausse est un défaut de fond.
- **L'argument constitutionnel inférait « pas de marqueur *Décision* ⇒ rien n'est tranché »** : réfuté par le tableau lui-même (`research.md:26` tranche « retenu vs figment » sans marqueur). L'argument tient sans cette béquille — le mot « Différés » suffit. Citation également remise avec ses ellipses, puisque le reproche d'origine portait précisément sur la fidélité d'une citation.
- FR-027 rendait illicite l'exception que les Assumptions lui opposaient (dérive de code généré révélée par le garde-fou) : exception nommée dans le texte de l'exigence, sur le procédé de FR-003.

**Points de vigilance transmis à la planification** (identifiés, non bloquants pour la spec) :
- Les deux méthodes que la migration réécrit pour la configuration ne sont couvertes par **aucun test** : le cycle y avance sans filet, et l'assume explicitement (`Assumptions`).
- L'invariant « un seul renouvellement pour N requêtes concurrentes » — raison d'être du verrou actuel — n'est **couvert par aucun test** aujourd'hui. FR-014 en fait l'un des deux tests que le cycle ajoute, avec l'unicité de l'intercepteur (FR-013).
- Un garde-fou de périmètre à 2 jours borne le lot outillage + harnais (`Assumptions`), sur le procédé du cycle 001.

- Items marked incomplete require spec updates before `/speckit-clarify` or `/speckit-plan`
