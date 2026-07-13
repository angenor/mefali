<!--
SYNC IMPACT REPORT — /speckit.constitution du 2026-07-13
Version : template vierge → 1.0.0 (ratification initiale, aucun principe préexistant)
Principes créés :
  I. Sources de vérité uniques
  II. Architecture — monolithe modulaire, cœur agnostique du vertical
  III. Intégrité de l'argent
  IV. Distances par itinéraire routier
  V. Offline-first & idempotence coursier
  VI. Événements outbox & métriques
  VII. Qualité vérifiable
  VIII. Sécurité & conformité
  IX. Périmètre — « Prêt ≠ construit »
  X. Versions à jour puis figées
  XI. Référence visuelle unique
Sections ajoutées : Contexte produit & contraintes ; Workflow de développement
  & portes qualité ; Governance.
Sections supprimées : aucune (placeholders du template remplacés).
Templates propagés :
  ✅ .specify/templates/plan-template.md — portes Constitution Check concrètes
     (I–XI) + arborescence monorepo Mefali
  ✅ .specify/templates/tasks-template.md — conventions de chemins monorepo +
     règles de tâches induites par la constitution + tests d'intégration de
     machines à états rendus obligatoires
  ✅ .specify/templates/spec-template.md — alignement des priorités de stories
     sur P0/P1/P2/PROVISION de docs/user-stories-v2.md
  ✅ .specify/templates/checklist-template.md — générique, aligné, aucun
     changement requis
  — .specify/templates/commands/*.md : répertoire absent (commandes installées
     dans .claude/skills/, maintenues par Spec-Kit) : rien à faire
Actions de cohérence effectuées :
  - docs/Mefali_Cadrage_MVP_v5.md renommé en docs/cadrage-v5.md et
    docs/Mefali_User_Stories_MVP_v2.md en docs/user-stories-v2.md (étape 0 de
    docs/Mefali_Prompts_SpecKit.md, rend valides les références de CLAUDE.md
    et de la présente constitution)
Suivis différés :
  - TODO(taxonomie-evenements) : docs/taxonomie-evenements.md n'existe pas
    encore — à créer au premier cycle qui déclare des événements (principe VI).
  - TODO(git) : dépôt git non initialisé — le principe I (CI en échec sur diff
    de client) et le workflow de commit supposent git + CI, à mettre en place
    au cycle TRX.
-->

# Constitution Mefali

## Core Principles

### I. Sources de vérité uniques

- Le contrat OpenAPI (`openapi.json`) est GÉNÉRÉ par utoipa depuis le code
  Actix. Les clients Dart (`clients/dart`) et TypeScript (`clients/ts`) sont
  générés depuis ce contrat en CI et ne sont JAMAIS écrits ni retouchés à la
  main ; un diff de client non commité fait échouer le build.
- Le schéma PostgreSQL n'est modifié QUE par migrations sqlx versionnées
  (`backend/migrations/`). Une migration appliquée n'est JAMAIS modifiée — on
  crée une nouvelle migration. Les seeds (Tiassalé, catégories, grilles) sont
  rejouables et versionnés à part des migrations.
- Tout paramètre métier qualifié de « paramétrable » vit dans la configuration
  de zone (héritage parent → enfant), JAMAIS en dur dans le code.

Rationale : développeur solo — chaque artefact a exactement un lieu de
modification, tout le reste en dérive mécaniquement ; la dérive casse le build
au lieu de passer inaperçue.

### II. Architecture — monolithe modulaire, cœur agnostique du vertical

- Monolithe modulaire Rust : un crate par domaine (zones, comptes,
  prestataires, qr, tarification, commandes, dispatch, coursier, paiements,
  notifications, avis, metriques), interfaces par traits, un schéma Postgres
  par module.
- L'entité centrale est le PRESTATAIRE (agrément, QR, sites, notes, plan) ; le
  vendeur en est la spécialisation MVP (catalogue, stock). AUCUN crate partagé
  ne suppose que tout prestataire est un vendeur.
- Le tronc de commande ne contient AUCUN champ logistique. La livraison est un
  composant OPTIONNEL (0..n) rattaché à la commande — les verticaux de
  livraison du MVP en créent exactement une. AUCUN crate partagé ne suppose
  que toute commande est une livraison.
- Modèle logistique : livraison → segments (1..n) → arrêts (1..n collectes +
  1 remise). Le MVP crée 1 segment ; le multi-arrêts est actif dès le MVP.
- Toute spécificité de vertical vit dans une table de détails dédiée derrière
  le trait `ServiceWorkflow`.
- Le dispatch filtre sur des CAPACITÉS requises ; le filtre est générique
  (MVP : types de véhicule).
- Redis ne porte que de l'éphémère reconstructible (GEO coursiers, verrous
  `SET NX EX`, pub/sub, cache, rate-limit). MinIO est accédé via l'API S3.
  Postgres est la SEULE vérité durable.

Rationale : les verticaux futurs (prestations à domicile, e-entrepôt…)
s'ajoutent par extension (table de détails + implémentation de trait), jamais
par refonte du tronc.

### III. Intégrité de l'argent

- Tout montant est un entier en unités mineures, accompagné du code ISO 4217
  porté par la zone (XOF, 0 décimale). JAMAIS de flottant pour l'argent.
- Les prix sont verrouillés à la création de la commande.
- AUCUN chemin de paiement partiel, jamais : totalité en cash ou totalité en
  mobile money.
- La chaîne cash est tracée par arrêt : qui détient quoi, à chaque état,
  échecs compris.
- Les webhooks de paiement sont idempotents.

### IV. Distances par itinéraire routier

- Toute distance est calculée par itinéraire routier via OSRM auto-hébergé,
  avec waypoints pour le multi-arrêts et cache Redis.
- JAMAIS de vol d'oiseau, sauf mode dégradé explicite : distance ×1,4, marquée
  `degraded=true` et journalisée.
- Une commande n'est JAMAIS bloquée par le routage.

### V. Offline-first & idempotence coursier

- Toute action de l'app coursier (scans, photos, transitions, confirmations)
  porte un UUID généré côté client + un horodatage local, part dans une file
  locale hors réseau, et son rejeu est idempotent.
- En cas de conflit au rejeu, le serveur fait foi.
- Les empreintes (hash) du code et du jeton QR de livraison sont
  pré-provisionnées à l'assignation pour permettre la validation hors ligne.

### VI. Événements outbox & métriques

- Toute transition d'état écrit un événement outbox dans la MÊME transaction
  SQL que la transition.
- Toute fonctionnalité comportant un parcours utilisateur déclare ses
  événements dans `docs/taxonomie-evenements.md` avant implémentation.
- AUCUN KPI manuel : toute métrique dérive des événements.

### VII. Qualité vérifiable

- Toute transition d'une machine à états est couverte par un test
  d'intégration.
- Les requêtes sqlx sont vérifiées à la compilation ; `cargo sqlx prepare` est
  exécuté après tout changement SQL.
- AUCUNE chaîne utilisateur en dur : clés i18n (fr, structure prête pour en).
- Logs structurés avec identifiant de corrélation ; Sentry ; endpoint
  `/health`.

### VIII. Sécurité & conformité

- OTP SMS rate-limité. JWT de courte durée + refresh token révocable.
- Chaque endpoint est protégé par rôle.
- Swagger UI désactivée ou protégée en production.
- Rétention limitée des photos et notes vocales (conformité ARTCI,
  minimisation des données).

### IX. Périmètre — « Prêt ≠ construit »

- Les provisions du cadrage §11 (villages, interville, multi-sites, plans
  freemium, flotte vendeur, points relais) sont des choix de modèle de données
  UNIQUEMENT : aucune UI, aucune logique au MVP.
- Toute fonctionnalité qui n'augmente pas les commandes/jour ou la fiabilité
  des livraisons est REFUSÉE (cadrage §3.2).
- Les priorités P0/P1/P2/PROVISION de `docs/user-stories-v2.md` font foi.

### X. Versions à jour puis figées

- Chaque brique (Rust, Actix, sqlx, utoipa, Flutter, Shorebird, Nuxt 4,
  Postgres, Redis, MinIO, OSRM, Metabase) est prise en dernière version
  STABLE, vérifiée à l'initialisation du module concerné, puis figée par
  lockfile.
- Revue mensuelle des versions.

### XI. Référence visuelle unique

- `docs/design/png/` est la cible visuelle des écrans.
- `docs/design/tokens.md` porte les valeurs exactes (couleurs, typo,
  espacements) consommées par le ThemeData Flutter (Material 3 thémé, Inter
  embarquée, Material Symbols Rounded — `docs/design/Mefali_DESIGN.md` §10) et
  par le thème Nuxt.
- `docs/design/html/` est une référence de mesures UNIQUEMENT : sa structure
  DOM/CSS n'est JAMAIS transposée en Flutter — implémentation en widgets
  Material 3 + composants `mefali_core`. Exception : l'admin Nuxt peut
  s'appuyer sur la structure HTML, adaptée aux composants du projet.
- Une seule identité visuelle sur Android et iOS : pas de variante Cupertino ;
  conventions système via les constructeurs `.adaptive`.

## Contexte produit & contraintes

- Mefali est une plateforme de services de proximité pour les villes de
  l'intérieur de la Côte d'Ivoire. Premier vertical (MVP) : livraison
  restauration + courses chez vendeurs agréés. Ville 1 : Tiassalé. D'autres
  verticaux suivront (prestations à domicile — plomberie, électricité —,
  e-entrepôt…).
- Développeur solo ; monorepo unique (`backend/`, `apps/`, `clients/`, `web/`,
  `infra/`, `docs/`, `specs/`).
- Documents produit de référence : `docs/cadrage-v5.md` et
  `docs/user-stories-v2.md` — en cas de doute, ces documents PRIMENT sur toute
  supposition ; le « Récapitulatif des paramètres de zone » y fait foi.
- Langue du projet : français. Code et identifiants en anglais ; textes
  utilisateur exclusivement en clés i18n fr.

## Workflow de développement & portes qualité

- Chaque module suit un cycle Spec-Kit complet dans `specs/` : specify →
  clarify → plan → tasks → analyze → implement → commit/merge.
- Le Constitution Check du plan DOIT passer avant la phase de recherche et
  être re-vérifié après la conception ; toute violation restante est justifiée
  dans Complexity Tracking, sinon le design est repris.
- Avant chaque commit : `cargo test` et `cargo sqlx prepare` verts ; clients
  régénérés sans diff ; message conventionnel référençant la story
  (ex. `feat(dispatch): DSP-04 …`) ; rien construit hors du périmètre du cycle
  en cours.
- Chaque story livrée respecte la Definition of Done de
  `docs/user-stories-v2.md` §0.4.
- Si une décision produit change : mettre à jour `docs/` d'abord (cadrage,
  user stories, design), puis relancer le `/speckit.specify` du module
  concerné — jamais l'inverse.

## Governance

- La présente constitution PRIME sur toute autre pratique. En cas de conflit
  avec un artefact (spec, plan, tasks, code, CLAUDE.md), c'est l'artefact qui
  est corrigé, pas la constitution contournée.
- Amendement : via `/speckit.constitution` uniquement — mise à jour de ce
  fichier, rapport d'impact en tête, propagation aux templates dépendants
  (`.specify/templates/`). Versionnage sémantique : MAJOR = retrait ou
  redéfinition incompatible d'un principe ; MINOR = ajout de principe ou de
  section, ou extension matérielle ; PATCH = clarification sans changement de
  sens.
- Conformité : développeur solo — la revue est outillée, pas humaine : portes
  Constitution Check des plans, checklist d'avant-commit, CI (tests,
  `cargo sqlx prepare`, diff de clients générés). Toute complexité résiduelle
  est justifiée dans le Complexity Tracking du plan concerné.
- `CLAUDE.md` (racine) est le guide d'exécution courant ; il reste synchronisé
  avec la constitution et ne la contredit jamais.

**Version**: 1.0.0 | **Ratified**: 2026-07-13 | **Last Amended**: 2026-07-13
