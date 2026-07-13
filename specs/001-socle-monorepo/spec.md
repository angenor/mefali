# Feature Specification: Socle technique du monorepo Mefali

**Feature Branch**: `001-socle-monorepo`

**Created**: 2026-07-13

**Status**: Draft

**Input**: User description: "Socle technique du monorepo Mefali — stories TRX-01 à TRX-05 (critères d'acceptation repris tels quels), création de l'arborescence monorepo complète (workspace Rust un crate par domaine, trait ServiceWorkflow, apps Flutter + mefali_core thémé depuis les tokens, Nuxt 4 hybride, clients générés, infra docker-compose Postgres/Redis/MinIO/OSRM avec extrait OSM Côte d'Ivoire, CI filtrée par chemins). Première tâche obligatoire : vérifier docs/design/tokens.md. Hors périmètre : TRX-06 et TRX-07 (emplacements seulement). Versions stables vérifiées puis figées ; openapi.json présent dès ce cycle avec au moins /health ; CI en échec sur diff de client non commité."

## Clarifications

### Session 2026-07-13

- Q: Le provisionnement du VPS de production et un premier déploiement du backend font-ils partie de ce cycle TRX ? → A: Oui, avec un périmètre volontairement minimal : UN VPS, docker compose en production, déploiement par GitHub Action sur `main` (SSH : pull d'image + compose up), secrets dans un `.env` sur le VPS hors Git, Swagger UI protégée, `/health` derrière la sonde uptime. PAS de staging, PAS de blue-green, PAS de Kubernetes, PAS de CDN — la production est le seul environnement jusqu'à la bêta, chargée avec les seeds de démo. Garde-fou : si ce lot dépasse 2 jours de tâches à la planification, il est dégradé en « VPS provisionné, déploiement différé » (TRX-03/04 vérifiés en local en attendant).
- Q: Vers quelle destination externaliser le `pg_dump` quotidien chiffré et la synchronisation MinIO (TRX-04) ? → A: Bucket S3-compatible chez un fournisseur tiers distinct du VPS (ex. Backblaze B2, Scaleway, Wasabi) — même API S3 que MinIO, séparation fournisseur réelle ; choix précis du fournisseur au plan.
- Q: Quelle durée de rétention pour les sauvegardes quotidiennes (pg_dump + sync MinIO) ? → A: 30 jours glissants — chaque sauvegarde est conservée 30 jours puis supprimée par rotation.
- Q: MinIO community est archivé (avril 2026, plus de patchs sécurité) — quelle brique de stockage objet S3 ? → A: Bascule sur Garage (mono-nœud `replication_mode = 1`, layout et buckets créés au provisioning, une clé d'accès par usage backend/backup, image épinglée par digest). POC limité aux endpoints S3 requis : put/get, multipart, URLs présignées. Immutabilité/versioning des sauvegardes portés par le bucket externe (object lock), pas par Garage. AGPL sans objet (usage non modifié, non redistribué). Docs mises à jour (cadrage §10.4, user-stories, CLAUDE.md) ; amendement constitution (principes II et X) à passer via /speckit.constitution.

## User Scenarios & Testing *(mandatory)*

Persona unique de ce cycle : **Admin (toi)** — fondateur et développeur solo. Le « bénéficiaire » du socle est le développement de tous les cycles suivants (tranche T1 et au-delà).

Priorités produit : les cinq stories TRX-01 → TRX-05 sont toutes **P0** dans `docs/user-stories-v2.md`. Les priorités P1→P6 ci-dessous sont l'ordre de livraison interne au cycle (dépendances), pas une hiérarchie produit.

### User Story 1 - Monorepo compilable et environnement de développement (Priority: P1 — produit : support des P0 TRX)

L'Admin clone le dépôt sur un poste vierge, démarre l'environnement local en une commande et compile chaque composant du monorepo sans erreur. L'arborescence complète existe : backend Rust (un crate par domaine, vides mais compilables), deux apps Flutter partageant un thème construit depuis les tokens de design, projet web hybride, clients générés, infrastructure de développement conteneurisée. Toutes les briques sont en dernière version stable, vérifiée à l'initialisation puis figée par lockfile.

**Why this priority**: Rien d'autre ne peut être construit ni testé sans ce socle ; c'est le prérequis de toutes les autres stories du cycle et de la tranche T1.

**Independent Test**: Sur un poste disposant des prérequis documentés : cloner le dépôt, lancer la commande unique d'environnement, compiler backend, apps et web — tout passe sans intervention manuelle supplémentaire.

**Acceptance Scenarios**:

1. **Given** un poste de développement avec les prérequis documentés, **When** l'Admin exécute la commande unique de démarrage de l'environnement local, **Then** Postgres, Redis, Garage et OSRM (alimenté par l'extrait OSM Côte d'Ivoire) sont opérationnels.
2. **Given** le monorepo cloné, **When** l'Admin compile le workspace backend, **Then** les douze crates de domaine (zones, comptes, prestataires, qr, tarification, commandes, dispatch, coursier, paiements, notifications, avis, metriques) et le binaire d'assemblage compilent, crates vides compris, et le trait `ServiceWorkflow` est défini dans le crate commandes sans aucune implémentation de vertical.
3. **Given** `docs/design/tokens.md` vérifié complet (hex, échelle typographique, espacements, rayons), **When** l'Admin compile et lance `mefali_client` et `mefali_pro`, **Then** les deux apps affichent un écran de démarrage thémé Material 3 dont chaque valeur de style provient des tokens, avec la police Inter embarquée et les Material Symbols Rounded disponibles.
4. **Given** une valeur manquante ou ambiguë dans `docs/design/tokens.md`, **When** la vérification initiale (première tâche obligatoire du cycle) s'exécute, **Then** la valeur est complétée depuis `docs/design/html/` et `tokens.md` est mis à jour AVANT toute construction du thème.
5. **Given** le projet web, **When** l'Admin le lance, **Then** les pages publiques sont servies en rendu serveur et l'espace `/admin/**` en rendu client pur.
6. **Given** l'ensemble des composants, **When** on inspecte le dépôt, **Then** chaque composant possède un lockfile commité figeant des versions vérifiées stables à la date d'initialisation, et des emplacements sont réservés (sans aucune implémentation) pour TRX-06 (pipeline Shorebird) et TRX-07 (conformité ARTCI).

---

### User Story 2 - Contrat d'API et clients générés (TRX-01, Priority: P2 — produit : P0)

L'Admin dispose d'un contrat d'API unique, généré depuis le code du backend, publié dès ce cycle avec au moins la sonde de santé documentée. Les clients Dart et TypeScript en sont dérivés mécaniquement ; toute dérive entre le contrat et les clients commités casse le build.

**Why this priority**: Le contrat est la source de vérité de tous les cycles suivants (constitution, principe I) ; le garde-fou CI doit exister avant la première story métier.

**Independent Test**: Démarrer le backend, consulter le contrat, régénérer les clients (aucun diff), puis modifier l'API sans régénérer et constater l'échec de la CI.

**Acceptance Scenarios**:

1. **Given** le backend démarré, **When** on consulte `/api-docs/openapi.json`, **Then** la spec est servie, `openapi.json` est commité à la racine et documente au moins `/health` ; handlers annotés `#[utoipa::path]`, schémas `ToSchema`/`IntoParams` ; Swagger UI accessible en développement et protégée hors production.
2. **Given** le contrat commité, **When** le script de génération s'exécute, **Then** `clients/dart` (openapi-generator) et `clients/ts` sont régénérés à l'identique — aucun diff.
3. **Given** une modification d'API sans régénération des clients, **When** la CI s'exécute, **Then** le build échoue sur le diff de client non commité.

---

### User Story 3 - Journal d'événements métier — outbox (TRX-02, Priority: P3 — produit : P0)

Toute transition d'état métier écrit un événement dans le même geste transactionnel que la transition ; un worker publie ces événements vers des consommateurs qui tolèrent le rejeu. Ce cycle livre l'infrastructure (table, écriture transactionnelle, worker, contrat de consommateur), validée par des transitions de test — les premières transitions métier réelles arrivent aux cycles suivants.

**Why this priority**: La Definition of Done commune (user-stories §0.4) exige un événement outbox pour tout changement d'état dès la première story métier ; l'infrastructure doit préexister.

**Independent Test**: Un test d'intégration déclenche une transition d'état factice et vérifie l'insertion transactionnelle, la publication par le worker et l'idempotence du consommateur.

**Acceptance Scenarios**:

1. **Given** une transition d'état, **When** elle est validée, **Then** un événement `{type, entité, payload, horodatage}` est inséré dans la même transaction.
2. **Given** la transaction de la transition échoue, **When** elle est annulée, **Then** aucun événement n'est publié ni conservé.
3. **Given** des événements en attente, **When** le worker de publication s'exécute, **Then** ils sont livrés aux consommateurs (notifications, métriques) ; un rejeu du même événement ne produit aucun double effet (consommateurs idempotents).

---

### User Story 4 - Observabilité (TRX-03, Priority: P4 — produit : P0)

L'Admin peut diagnostiquer tout comportement du backend : chaque requête laisse des logs structurés corrélés, les erreurs remontent dans l'outil de suivi, et une sonde externe l'alerte si le service est indisponible plus de 2 minutes.

**Why this priority**: Développeur solo — sans observabilité, chaque incident des cycles suivants coûte des heures ; l'alerte d'indisponibilité protège la bêta.

**Independent Test**: Émettre une requête (logs corrélés), provoquer une erreur (remontée Sentry), couper le service > 2 minutes (alerte reçue).

**Acceptance Scenarios**:

1. **Given** une requête traitée par le backend, **When** on consulte les logs, **Then** ils sont structurés et corrélés par identifiant de requête.
2. **Given** une erreur serveur, **When** elle survient, **Then** elle est remontée dans Sentry.
3. **Given** la sonde uptime branchée sur `/health`, **When** le service est indisponible plus de 2 minutes, **Then** une alerte est émise à l'Admin.

---

### User Story 5 - Sauvegardes (TRX-04, Priority: P5 — produit : P0)

Les données de production sont sauvegardées chaque jour, chiffrées, stockées hors du serveur, et l'Admin sait les restaurer intégralement en suivant une procédure documentée et déjà testée.

**Why this priority**: Perte de la base = perte du produit ; la restauration doit être prouvée avant la bêta, mais n'est pas bloquante pour développer les autres stories du cycle.

**Independent Test**: Dérouler la procédure de restauration documentée sur un environnement vierge à partir d'une sauvegarde réelle et retrouver l'intégralité des données.

**Acceptance Scenarios**:

1. **Given** l'infrastructure en place, **When** l'échéance quotidienne passe, **Then** un `pg_dump` chiffré est externalisé (hors du serveur de production) et le contenu du stockage objet (Garage) est synchronisé.
2. **Given** une sauvegarde existante, **When** l'Admin déroule la procédure de restauration documentée sur un environnement vierge, **Then** la restauration complète réussit — testée et documentée avant la bêta.

---

### User Story 6 - Seeds & démo (TRX-05, Priority: P6 — produit : P0)

L'Admin recharge en une seule commande un environnement de démonstration complet : zone Tiassalé, 5 vendeurs multi-catégories (dont un avec prix barrés et un en « livraison offerte dès X »), 20 articles, 2 coursiers, grille tarifaire et comptes de test.

**Why this priority**: Indispensable aux démos de fin de tranche et aux tests manuels, mais dépend des schémas livrés par les cycles suivants de la tranche T1 (voir Assumptions) — c'est la dernière story pleinement vérifiable du cycle.

**Independent Test**: Exécuter la commande unique de seed sur une base vierge puis une seconde fois sur la base peuplée : le jeu de données annoncé est présent, sans doublon.

**Acceptance Scenarios**:

1. **Given** une base vierge dont les schémas requis existent, **When** l'Admin exécute la commande unique de seed, **Then** zone Tiassalé, 5 vendeurs multi-catégories (dont un avec prix barrés et un en « livraison offerte dès X »), 20 articles, 2 coursiers, grille tarifaire et comptes de test sont chargés.
2. **Given** une base déjà peuplée par un seed antérieur, **When** l'Admin relance la commande, **Then** le jeu de données est rechargé proprement, sans doublon ni résidu.

---

### User Story 7 - Déploiement production minimal (Priority: P7 — issu de la clarification du 2026-07-13)

L'Admin fusionne sur `main` ; une GitHub Action se connecte au VPS en SSH, récupère l'image et relance la pile docker compose. La production — un seul VPS, seul environnement jusqu'à la bêta — est chargée avec les seeds de démo, expose `/health` à la sonde uptime et protège Swagger UI. Les secrets vivent dans un `.env` sur le VPS, hors Git.

**Why this priority**: Conditionne la vérification en conditions réelles des US4 (sonde, alerte) et US5 (sauvegardes externalisées). Garde-fou : si ce lot dépasse 2 jours de tâches à la planification, il est dégradé en « VPS provisionné, déploiement différé ».

**Independent Test**: Pousser un commit sur `main` et constater que la production reflète ce commit sans intervention manuelle ; vérifier `/health` joignable, Swagger UI protégée et l'absence de tout secret dans le dépôt.

**Acceptance Scenarios**:

1. **Given** le VPS provisionné (pile docker compose : backend, Postgres, Redis, Garage, OSRM), **When** un commit est fusionné sur `main`, **Then** la GitHub Action déploie par SSH (pull d'image + compose up) et la production sert la nouvelle version.
2. **Given** la production déployée, **When** on l'inspecte, **Then** les secrets sont dans un `.env` sur le VPS hors Git, Swagger UI est protégée, `/health` répond à la sonde uptime et les seeds de démo sont chargés.
3. **Given** le dépôt Git, **When** on l'audite, **Then** aucun secret de production n'y figure.

---

### Edge Cases

- Valeur absente à la fois de `docs/design/tokens.md` et de `docs/design/html/` : la vérification initiale la signale explicitement pour arbitrage — aucune valeur n'est inventée silencieusement.
- Extrait OSM Côte d'Ivoire indisponible au téléchargement, ou OSRM en échec : le reste de l'environnement local (Postgres, Redis, Garage) démarre quand même ; la compilation et les tests des autres composants ne sont jamais bloqués par le routage (constitution IV, décliné en dev).
- Génération de clients non déterministe (horodatages, ordre des fichiers) : la génération doit être reproductible, sinon le contrôle de diff en CI produit des faux positifs — à neutraliser dès ce cycle.
- Filtrage CI par chemins masquant un contrôle : un changement backend modifie le contrat → les vérifications de clients doivent quand même se déclencher ; le filtrage ne doit jamais faire sauter le contrôle de dérive.
- Panne ou redémarrage du worker de publication : aucun événement perdu (l'événement persiste tant qu'il n'est pas publié) ; la redélivrance ne crée pas de double effet.
- Perte de la clé de chiffrement des sauvegardes : la gestion de la clé (emplacement, sauvegarde de la clé elle-même) fait partie de la procédure documentée de restauration.
- Relance du seed interrompue à mi-course : la commande de rechargement ramène toujours à l'état de démo complet.

## Requirements *(mandatory)*

### Functional Requirements

Socle du monorepo :

- **FR-001**: La PREMIÈRE tâche du cycle DOIT vérifier que `docs/design/tokens.md` est complet et exploitable — couleurs en hex, échelle typographique, espacements, rayons — et compléter depuis `docs/design/html/` toute valeur manquante, avant toute construction du thème. C'est ce fichier que consomme `mefali_core`.
- **FR-002**: Le dépôt DOIT contenir l'arborescence monorepo complète : `backend/` (workspace Rust : un crate par domaine — zones, comptes, prestataires, qr, tarification, commandes, dispatch, coursier, paiements, notifications, avis, metriques — vides mais compilables, plus `backend/api/` binaire d'assemblage), `apps/mefali_client`, `apps/mefali_pro`, `apps/packages/mefali_core`, `web/`, `clients/dart`, `clients/ts`, `infra/`, `.github/workflows/`.
- **FR-003**: Le trait `ServiceWorkflow` DOIT être défini dans le crate commandes (interface seulement — aucune implémentation de vertical dans ce cycle).
- **FR-004**: `mefali_core` DOIT exposer le thème Material 3 construit depuis `docs/design/tokens.md`, avec Inter embarquée et Material Symbols Rounded ; les deux apps DOIVENT consommer ce thème — aucune valeur de style en dur dans les apps.
- **FR-005**: `web/` DOIT être un projet Nuxt 4 hybride : pages publiques en rendu serveur, `/admin/**` en rendu client pur (ssr: false).
- **FR-006**: `infra/` DOIT fournir un environnement de développement conteneurisé démarrable en une commande : Postgres, Redis, Garage, OSRM alimenté d'un extrait OSM Côte d'Ivoire.
- **FR-007**: Chaque brique de la stack DOIT être prise en dernière version STABLE, vérifiée à l'initialisation du cycle, puis figée par lockfile commité (constitution X).
- **FR-008**: Des emplacements DOIVENT être réservés pour TRX-06 (pipeline Shorebird) et TRX-07 (conformité ARTCI) — aucune implémentation, aucune logique.
- **FR-009**: La CI DOIT être filtrée par chemins : un changement ne déclenche que les vérifications des composants touchés ; le contrôle de dérive du contrat et des clients se déclenche sur tout changement du backend ou des clients et ne peut jamais être court-circuité par le filtrage.

Déploiement production minimal (clarification du 2026-07-13) :

- **FR-017**: `infra/` DOIT provisionner UN VPS de production exécutant la pile du cycle via docker compose (backend, Postgres, Redis, Garage, OSRM) ; les secrets vivent dans un `.env` sur le VPS, hors Git ; Swagger UI protégée ; `/health` exposé à la sonde uptime ; les seeds de démo (FR-016) y sont chargés.
- **FR-018**: Le déploiement DOIT être déclenché par GitHub Action à chaque fusion sur `main` : connexion SSH au VPS, récupération de l'image, `compose up`. Aucun staging, blue-green, Kubernetes ni CDN — la production est le seul environnement jusqu'à la bêta.
- *Garde-fou de périmètre* : si FR-017 + FR-018 dépassent 2 jours de tâches à la planification, le lot est dégradé en « VPS provisionné, déploiement différé » (FR-018 sort du cycle ; FR-014/FR-015 se vérifient en local en attendant).

TRX-01 — Contrat OpenAPI et génération des clients (critères repris tels quels) :

- **FR-010**: Handlers annotés `#[utoipa::path]` ; schémas `ToSchema`/`IntoParams` ; spec `/api-docs/openapi.json` ; Swagger UI protégée hors production.
- **FR-011**: CI : génération client Dart (openapi-generator) + client TypeScript ; diff non commité = build en échec.
- **FR-012**: `openapi.json` DOIT exister dès ce cycle, commité, documentant au moins `/health`.

TRX-02 — Journal d'événements métier, outbox (critères repris tels quels) :

- **FR-013**: Toute transition d'état insère `{type, entité, payload, horodatage}` dans la même transaction ; worker de publication ; consommateurs (notifications, métriques) idempotents.

TRX-03 — Observabilité (critères repris tels quels) :

- **FR-014**: Logs structurés avec corrélation par requête ; Sentry ; sonde uptime sur `/health` ; alerte si indisponibilité > 2 min.

TRX-04 — Sauvegardes (critères repris tels quels) :

- **FR-015**: `pg_dump` quotidien chiffré externalisé + sync du stockage objet (Garage) ; restauration complète testée et documentée avant la bêta. Destination d'externalisation : bucket S3-compatible chez un fournisseur tiers distinct du VPS ; rétention 30 jours glissants avec rotation automatique (clarifications du 2026-07-13 ; fournisseur précis choisi au plan).

TRX-05 — Seeds & démo (critères repris tels quels) :

- **FR-016**: Zone Tiassalé, 5 vendeurs multi-catégories (dont un avec prix barrés et un en « livraison offerte dès X »), 20 articles, 2 coursiers, grille tarifaire, comptes de test — rechargeables en une commande.

### Hors périmètre

- **TRX-06 — Pipeline Shorebird (P1, tranche T4)** : seul l'emplacement est prévu ; aucune configuration, aucun test de patch.
- **TRX-07 — Conformité ARTCI (P1)** : seul l'emplacement est prévu ; ni export/suppression de données, ni politique de rétention, ni consentement.
- Toute UI ou logique métier des modules ZON, CPT, VND, QRC, TRF, CMD, DSP, CRS, PAY, NTF, AVI, VAP, ADM, WEB, MET — les crates correspondants sont créés vides.
- Toute sophistication de déploiement : staging, blue-green, Kubernetes, CDN — la production sur UN VPS (docker compose) est le seul environnement jusqu'à la bêta (clarification du 2026-07-13).

### Key Entities

- **Événement outbox** : fait métier journalisé — type, entité concernée, charge utile, horodatage, état de publication ; écrit atomiquement avec la transition qui le provoque.
- **Contrat d'API et clients dérivés** : description unique et générée de l'API (`openapi.json`), dont dérivent mécaniquement un client Dart et un client TypeScript ; jamais édités à la main.
- **Jeu de tokens de design** : valeurs uniques de style (couleurs hex, échelle typographique, espacements, rayons) consommées par le thème partagé des apps.
- **Sauvegarde** : copie quotidienne chiffrée de la base et du stockage d'objets, conservée hors du serveur de production, accompagnée de sa procédure de restauration.
- **Jeu de démonstration (seed)** : données rejouables décrivant la zone Tiassalé, vendeurs, articles, coursiers, grille tarifaire et comptes de test ; versionné à part des migrations.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Sur un poste disposant des prérequis documentés, l'Admin obtient un environnement complet (services locaux démarrés + tous les composants compilés) en moins de 30 minutes, sans intervention non documentée.
- **SC-002**: 100 % des composants du monorepo possèdent un lockfile commité figeant des versions vérifiées stables à la date d'initialisation.
- **SC-003**: Le contrat d'API est consultable dès ce cycle et couvre 100 % des endpoints exposés (au minimum la sonde de santé) ; les deux clients dérivés se régénèrent à l'identique (0 diff) depuis le contrat commité.
- **SC-004**: 100 % des modifications du contrat sans régénération des clients sont bloquées avant fusion.
- **SC-005**: 100 % des transitions d'état exercées en test produisent exactement un événement journalisé ; 0 événement perdu en cas de panne du worker ; 0 double effet au rejeu chez les consommateurs.
- **SC-006**: Toute indisponibilité du service de plus de 2 minutes déclenche une alerte à l'Admin.
- **SC-007**: La perte de données maximale en cas de sinistre est bornée à 24 heures (sauvegarde quotidienne) ; au moins une restauration complète documentée a réussi avant la bêta.
- **SC-008**: L'environnement de démonstration se recharge en une seule commande, en moins de 5 minutes, et le rechargement répété ne crée aucun doublon.
- **SC-009**: 0 valeur de style codée en dur dans les apps : 100 % des valeurs du thème proviennent du fichier de tokens.
- **SC-010**: Une modification ne touchant qu'un composant ne déclenche que les vérifications de ce composant, sans jamais faire sauter le contrôle de dérive contrat/clients.
- **SC-011**: Un changement fusionné sur `main` est visible en production sans aucune intervention manuelle, en moins de 15 minutes ; aucun secret de production ne figure dans le dépôt.

## Assumptions

- **TRX-05 et les schémas manquants** : les entités seedées (zones, vendeurs, articles, coursiers, grilles, comptes) relèvent des cycles ZON/CPT/VND/TRF de la tranche T1. Le présent cycle livre le mécanisme de seed « rechargeable en une commande » et la structure versionnée des jeux de données ; le contenu complet du critère FR-016 devient vérifiable au fur et à mesure que ces cycles livrent leurs schémas, et est contrôlé à la clôture de la tranche T1 (démo de fin de tranche).
- **TRX-02 sans machine à états métier** : aucune transition métier n'existe encore ; l'outbox est livrée comme infrastructure (persistance, écriture transactionnelle, worker, contrat de consommateur idempotent) validée par des transitions de test d'intégration. `docs/taxonomie-evenements.md` est créé au premier événement déclaré (suivi différé de la constitution, principe VI).
- **Sonde uptime et alerte (TRX-03)** : assurées par un service de supervision externe au serveur ; le choix précis relève du plan.
- **Sauvegardes (TRX-04)** : « externalisé » = bucket S3-compatible chez un fournisseur tiers distinct du VPS (clarification du 2026-07-13) ; la gestion de la clé de chiffrement (conservation, duplication) fait partie de la procédure de restauration documentée. La sauvegarde s'exerce sur le VPS de production dès le premier déploiement (US7), la restauration testée avant la bêta.
- **Environnements** : développement = poste unique du développeur solo (macOS/Linux) ; production = UN VPS (cadrage §10.10) provisionné et déployé dans ce cycle (clarification du 2026-07-13), seul environnement jusqu'à la bêta, chargé avec les seeds de démo. En cas de dégradation du garde-fou 2 jours : VPS provisionné, déploiement différé.
- **Dépôt et CI** : le dépôt git existe ; la CI s'exécute sur GitHub (`.github/workflows/`).
- **Critères verbatim** : conformément à la demande, les critères d'acceptation de TRX-01 → TRX-05 sont repris tels quels depuis `docs/user-stories-v2.md` — aucune exigence produit supplémentaire n'a été inventée ; les FR-001 → FR-009 ne font que matérialiser le périmètre de création du socle énoncé dans la demande et la constitution, et les FR-017/FR-018 (déploiement) proviennent des clarifications du 2026-07-13.
