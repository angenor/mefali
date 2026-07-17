# Implementation Plan: Gestion d'état des apps Flutter — migration vers Riverpod codegen

**Branch**: `004-riverpod-etat-flutter` | **Date**: 2026-07-17 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/004-riverpod-etat-flutter/spec.md`

## Summary

Migrer les trois paquets Flutter de `ChangeNotifier` + `ListenableBuilder` injectés par constructeur vers Riverpod codegen, en REFACTOR PUR — aucun écran, aucun texte, aucun enchaînement, aucune requête ne change, et les 86 cas de test existants font contrat (FR-003, SC-002) —, afin que les cycles métier suivants (VND, CMD, DSP, CRS…) partent d'un moule unique, outillé et opposable au lieu de recopier une convention qui n'existe aujourd'hui que dans un commentaire de code (TRX-08, P1). Approche : 11 providers générés — 8 `keepAlive` (URL d'API, les deux clients HTTP, stockage de jetons, session, source et cache de configuration, service de configuration) et 3 `autoDispose` (rôles, adresses, appareils) —, l'intercepteur d'autorisation posé par le provider de client qui ne dépend d'aucun état mutable, ce qui rend le mode de panne n°1 du cycle structurellement inatteignable plutôt que seulement testé (R3) ; la configuration hébergée derrière un `Raw<Future<ServiceConfig>>` qui n'a aucun `AsyncValue` à émettre, ce qui rend FR-021 impossible à violer (R5) ; deux moules assumés — `Notifier<Etat…>` pour les porteurs à sémantique propre, `AsyncNotifier` pour les chargements de liste (R6, R13) — parce qu'un `AsyncValue` uniforme détruirait les deux sémantiques opposées de chargement que FR-022 exige de préserver ; le retry automatique de Riverpod 3, actif PAR DÉFAUT et qui violerait FR-002 sans une ligne de code, neutralisé à la création de chaque portée (R10) ; l'analyse statique basculée de `flutter analyze` vers `dart analyze`, sans quoi les règles du plugin sont un no-op silencieux (R2, R12) ; et un harnais de test partagé qui n'existe pas aujourd'hui, où 6 transports et 6 montages de session sont recopiés d'un fichier à l'autre (R11). Ne sont touchés NI le backend, NI le contrat d'API, NI les clients générés, NI le web Nuxt (FR-006) ; R14 (double-submit concurrent du dossier) et le chantier iOS/enregistrement vocal restent exactement dans l'état où le cycle les a trouvés (FR-026). Détail des décisions : [research.md](research.md) R1–R13.

## Technical Context

**Language/Version**: Dart `^3.12.0` / Flutter **3.44.6** (stable) — épinglée en dur dans `.github/workflows/apps.yml:33` et `contrat-clients.yml:48`, qui en sont l'UNIQUE source de vérité (ni `.fvmrc`, ni gestionnaire de version). Aucun Rust, aucun TypeScript ce cycle.

**Primary Dependencies**: *Existants, inchangés* — `dio 5.10.0` (transport du client GÉNÉRÉ), `flutter_secure_storage` (jetons), `shared_preferences` (cache de configuration), `mefali_api_client` (chemin local, GÉNÉRÉ, JAMAIS édité). *Nouveaux, tous résolus par exécution le 2026-07-17 et non relevés sur pub.dev* — `flutter_riverpod 3.3.2`, `riverpod_annotation 4.0.3` (dependencies), `riverpod_generator 4.0.4`, `build_runner ^2.15.1` (dev_dependencies), `riverpod_lint 3.1.4` déclaré **hors du gestionnaire de paquets**, dans `analysis_options.yaml` (R1, R2). *Écarté* — `custom_lint`, insoluble : `0.8.1` exige `analyzer ^8.0.0` contre `^12.0.0` pour Riverpod ; la demande initiale le nommait, la recherche l'a enterré (R2). Tous en dernière version STABLE vérifiée puis figée (constitution X) — **à trois écarts près, nommés au Complexity Tracking** : une prérelease imposée transitivement, un plafond de version, et une brique que le lockfile ne peut pas atteindre.

**Storage**: aucun stockage ce cycle — la persistance des jetons (stockage sécurisé du système) et le cache de configuration (préférences) passent derrière des providers **SANS changer de support** (FR-035) ; aucun Postgres, aucun Redis, aucun S3, aucune migration.

**Testing**: `flutter test` — **86 cas existants** (61 `mefali_core`, 23 `mefali_pro`, 2 `mefali_client`), dont 84 en CI (`--exclude-tags golden`) et 2 goldens hors CI, à rejouer À LA MAIN avant fusion. Le cycle ajoute **3 cas** (unicité de l'intercepteur, renouvellement partagé — FR-013, FR-014, SC-005) : décompte de sortie **≥ 89**, dont aucun des 86 n'a disparu (FR-004). Doubles par surcharge de portée (FR-035) ; AUCUN canal de plateforme simulé (FR-039).

**Target Platform**: Android (émulateur et appareil) — le parcours de validation de bout en bout du cycle précédent. iOS reste NON vérifié : chantier hors périmètre.

**Project Type**: monorepo — **3 paquets Flutter uniquement**. Aucun crate backend, aucune page Nuxt, aucun client régénéré.

**Performance Goals**: aucun objectif de performance — l'objectif est l'INDISCERNABILITÉ (FR-001) : mêmes écrans, mêmes états de chargement, mêmes temporisations perceptibles. Le seul micro-réordonnancement assumé du cycle est une frame (R3, décision a5).

**Constraints**: **0 requête réseau ajoutée, supprimée ou déplacée** (FR-002, SC-004) — contrainte la plus dure du cycle, et celle que le retry par défaut de Riverpod 3 violerait silencieusement ; **exactement 1** intercepteur d'autorisation sur le client de session, **0** sur celui de configuration (FR-013, FR-017) ; le rafraîchissement horaire n'atteint JAMAIS l'interface (FR-021) ; la relecture du code dev reste une constante de compilation (FR-025) ; la clé d'idempotence garde exactement sa portée (FR-026).

**Scale/Scope**: 2 notificateurs + 3 porteurs → **11 providers** (8 `keepAlive`, 3 `autoDispose`) ; 34 mutations d'état locales en code, dont 26 dans le paquet cœur ; **86 cas de test sur 13 fichiers → ≥ 89** ; 3 `pubspec.lock` indépendants à accorder ; 6 doubles de transport et 6 montages de session à fusionner dans un harnais qui n'existe pas (FR-037, SC-011).

## Constitution Check

*GATE : passée avant la Phase 0, re-vérifiée après la Phase 1 — **conforme, 5 écarts justifiés au Complexity Tracking** (IX × 1, VII × 1, X × 3).*

- [x] **I. Sources de vérité** : `openapi.json` et les clients `clients/dart` / `clients/ts` **INTOUCHÉS** (FR-006) ; aucune migration sqlx ; aucun paramètre métier en dur. Le cycle ajoute une **4ᵉ source dérivée** — les `.g.dart` des providers — sous la MÊME règle que les clients : générée, commitée, gardée par un contrôle de dérive, jamais éditée à la main (FR-029, FR-030, FR-031, R12).
- [x] **II. Architecture** : N/A côté backend — aucun crate touché. Côté apps, `mefali_core` reste agnostique du vertical : aucun provider n'introduit de notion de commande, de livraison ou de vendeur. Nuance consignée : le harnais de test vivra dans `lib/` de `mefali_core`, sur le précédent assumé de `StockageJetonsMemoire` (`stockage_jetons.dart:84`, un double exposé depuis la production) — barrière conventionnelle, pas mécanique (R11).
- [x] **III. Argent** : N/A — aucun montant ce cycle.
- [x] **IV. Distances** : N/A — aucune distance calculée.
- [x] **V. Offline & idempotence** : CONCERNÉE **par non-action**. FR-026 gèle la portée de la clé d'idempotence ; R14 reste hors périmètre ; la file hors-ligne n'est pas entamée (les répertoires réservés restent vides). Le seul chemin de violation est le geste que l'idiome invite — transformer le formulaire de dossier en widget sans état — et il est nommé, testé et interdit (edge case de la spec, R13).
- [x] **VI. Événements** : N/A — aucune transition d'état **métier**, donc aucun événement outbox. Les transitions de **durée de vie** relèvent de VII.
- [x] **VII. Qualité** : CONCERNÉE — **conforme avec 1 écart**. Les durées de vie SONT des machines à états ([data-model.md](data-model.md) §2) et chaque flèche est couverte par un test. Exception : les **deux lectures d'instantané de configuration**, que la migration réécrit et qu'AUCUN des 86 cas ne couvre — aucun test ne passe de configuration, si bien que les deux méthodes sortent immédiatement (`spec.md`, Assumptions). → **Complexity Tracking**. Clés i18n : invariant à ne pas régresser (FR-001). `cargo sqlx prepare` : N/A.
- [x] **VIII. Sécurité** : CONCERNÉE — **renforcée**. L'isolation inter-comptes (FR-020, SC-010) cesse de reposer sur un démontage de widget pour être gravée dans le graphe de dépendances (R4) ; FR-013 empêche la révocation de session par auto-vol présumé ; FR-025 garde la relecture du code dev hors du binaire de release. Aucun endpoint, aucun média, aucune rétention en jeu.
- [x] **IX. Périmètre** : CONCERNÉE — **conforme avec 1 écart, et il faut le dire**. *Provisions* : aucune touchée. *« Toute fonctionnalité qui n'augmente pas les commandes/jour est REFUSÉE »* : l'argument de la spec tient — un refactor défini par « aucun changement visible » n'est pas une fonctionnalité, il n'y a rien à reporter ; et IX ne gouverne pas la pratique d'ingénierie, sinon il refuserait le principe X et la section « Workflow & portes qualité » de la constitution elle-même. Le précédent est dans le fait : TRX porte déjà cinq P0 sans bénéfice utilisateur direct. *« Les priorités font foi »* : **écart réel et assumé** — TRX-08 est un P1 qui passe devant des P0 de la tranche T1. → **Complexity Tracking**.
- [x] **X. Versions** : CONCERNÉE — **structurante, conforme avec 3 écarts**. Recherche du 2026-07-17, versions **résolues par exécution** et non relevées ; 3 lockfiles commités ; accord des 3 paquets contrôlé mécaniquement (SC-008). Écarts : **(1)** `riverpod_analyzer_utils 1.0.0-dev.10` — une **prérelease** dans le lockfile, imposée à l'exact par `riverpod_generator 4.0.4` ET `riverpod_lint 3.1.4` ; **(2)** `build_runner` **plafonné à 2.15.1** alors que 2.15.2 est la dernière stable ; **(3)** `riverpod_lint` **hors lockfile** — résolu par l'outil d'analyse, « figé par lockfile » lui est mécaniquement inapplicable. → **Complexity Tracking × 3**. ⚠ Riverpod ne figure pas dans la liste nommée du principe X : l'amendement (FR-040) est l'occasion de l'y ajouter.
- [x] **XI. Design** : CONCERNÉE **par non-action**. Aucune transposition DOM/CSS (`docs/design/html/` n'est pas ouvert) ; constructeurs `.adaptive` intacts ; aucun Cupertino ; **les 2 goldens passent sans régénération** (FR-005, SC-002), garanti structurellement : ils montent un `StatelessWidget` nu, hors de toute portée (R13).

⚠ **Amendement de constitution (FR-040)** : éditer la constitution hors `/speckit.constitution` est interdit par la gouvernance. Amendement **MINOR (1.0.1 → 1.1.0**, ajout de principe) à passer juste après ce plan. Le principe ajouté DOIT nommer **les deux moules** (`Notifier<Etat…>` pour les porteurs à sémantique propre, `AsyncNotifier` pour les chargements de liste), sinon le prochain cycle uniformisera derrière `AsyncValue` et détruira les deux sémantiques opposées que FR-022 protège (R6, R13).

## Project Structure

### Documentation (this feature)

```text
specs/004-riverpod-etat-flutter/
├── spec.md                      # Phase -1 (/speckit-specify)
├── plan.md                      # Ce fichier (/speckit-plan)
├── research.md                  # Phase 0 — R1–R13, décisions arrêtées
├── data-model.md                # Phase 1 — porteurs, durées de vie, surcharges
├── quickstart.md                # Phase 1 — validation des 12 SC
├── contracts/
│   ├── providers.md             # Le moule : 11 providers + les gestes qui cassent en silence
│   ├── harnais-de-test.md       # FR-037 : l'API du harnais + les 3 contraintes dures
│   └── ci-apps.md               # FR-031/033/034 : ce qui casse le build
├── checklists/
│   └── requirements.md          # Qualité de la spec
└── tasks.md                     # Phase 2 (/speckit-tasks — PAS créé ici)
```

### Source Code (repository root)

```text
apps/
├── packages/mefali_core/        # MODIFIÉ — le gros du cycle : 26 des 34 setState, la session
│   ├── lib/src/auth/            #   session_auth.dart → providers ; l'intercepteur change de main
│   ├── lib/src/config/          #   amorce_config.dart → signature inversée (source + cache reçus)
│   ├── lib/src/adresses/        #   liste_adresses.dart → AsyncNotifier
│   ├── lib/src/appareils/       #   ecran_appareils.dart → AsyncNotifier
│   ├── lib/harnais.dart         #   NOUVEAU — le harnais partagé (FR-037)
│   ├── analysis_options.yaml    #   MODIFIÉ — bloc plugins: + diagnostics: error (FR-033)
│   └── pubspec.yaml             #   MODIFIÉ — riverpod + generator + build_runner
├── mefali_pro/                  # MODIFIÉ — EtatRoles, le routeur, le formulaire de dossier
│   ├── lib/main.dart            #   MODIFIÉ — UncontrolledProviderScope + retry neutralisé
│   └── lib/roles/               #   etat_roles.dart → Notifier ; le seam mort disparaît (FR-043)
├── mefali_client/               # MODIFIÉ — 2 fichiers, aucun état : ProviderScope seulement
│   └── lib/main.dart
└── */lib/**/*.g.dart            # NOUVEAU — GÉNÉRÉ, commité, gardé par le contrôle de dérive

.github/workflows/apps.yml       # MODIFIÉ — dart analyze (PAS flutter analyze) + garde-fou dérive

backend/  clients/  web/  infra/ # INTOUCHÉS (FR-006)
docs/user-stories-v2.md          # DÉJÀ FAIT — TRX-08 (P1) + tableau §0.6, avant ce plan
.specify/memory/constitution.md  # À AMENDER via /speckit.constitution (FR-040), après ce plan
CLAUDE.md                        # MODIFIÉ en fin de cycle — mêmes règles (FR-041)
```

**Structure Decision**: Le cycle ne touche que `apps/` et la CI qui la garde. `mefali_core` concentre l'essentiel — la session, l'intercepteur, la configuration, deux écrans de liste et 26 des 34 mutations d'état locales — et il est la dépendance des deux applications : rien ne peut migrer avant lui, d'où l'ordre de livraison interne cœur → rôles → client (US2 → US5). `mefali_pro` porte le second notificateur et le seul dont la durée de vie est une garantie de sécurité. `mefali_client` est trivial (deux fichiers, aucun état) mais ferme le périmètre : tant qu'un porteur subsiste, la convention est « Riverpod sauf exceptions », ce qui n'est pas une convention. Ne sont PAS touchés : le backend et ses crates, `openapi.json`, les clients générés, le web Nuxt, l'infrastructure — aucune ligne (FR-006). `docs/user-stories-v2.md` a été mis à jour AVANT ce plan, comme la constitution l'impose.

## Livrables attendus (demandés dans l'input du plan)

| Livrable | Où |
|---|---|
| Migrations | **AUCUNE** — aucun schéma touché ; aucun `cargo sqlx prepare` (FR-006). |
| Endpoints utoipa | **AUCUN** — le backend n'est pas touché ; `openapi.json` et les 2 clients générés restent identiques (FR-006). |
| Structures & traits exposés | **11 providers** + `EtatSession` et `EtatRolesData` ([data-model.md](data-model.md) §1, §4) ; le moule opposable aux cycles suivants ([contracts/providers.md](contracts/providers.md)) ; le harnais partagé ([contracts/harnais-de-test.md](contracts/harnais-de-test.md), FR-037). |
| Événements outbox | **AUCUN** — aucune transition d'état métier ce cycle (constitution VI). |
| Écrans-widgets | **AUCUN NOUVEL ÉCRAN** — c'est l'invariant central (FR-001). Les écrans existants changent de mécanique d'injection, jamais d'apparence ni d'enchaînement. |
| Tests d'intégration | Les **86 cas existants**, migrés en surcharges de portée et VERTS à l'identique (FR-003, SC-002) ; **+3 cas neufs** — unicité de l'intercepteur et renouvellement partagé (FR-013, FR-014, SC-005) ; les 2 goldens sans régénération (FR-005). |

### Garde-fou de périmètre (≤ 2 jours)

L'Assumption de la spec dégrade le lot si l'outillage (US1) et le harnais (FR-037) dépassent **2 jours de tâches à la planification**. Estimation après la Phase 0 : l'outillage est **PLUS PETIT que prévu** — pas de `custom_lint`, pas de `build.yaml` (le générateur livre le sien), pas de `.gitignore` à toucher, zéro relâchement de lint, `mefali_client` quasi vide : il se réduit à 2 × 4 lignes de `pubspec`, 3 blocs `plugins:`, 1 script d'accord des lockfiles et ~12 lignes de CI → **~1 jour**. Le harnais est le vrai coût (~0,5 jour), mais sa forme est déjà tranchée par trois contraintes vérifiées par exécution (R11) : pas d'exploration à payer. **Total ~1,5 jour → sous le seuil, lot maintenu.** À réévaluer au `/speckit-tasks` : si le compte dépasse 2 jours, outillage et harnais sont livrés d'abord et la migration des porteurs est reportée story par story, plutôt que d'entamer le nœud de session sans filet.

## Complexity Tracking

> Écarts aux principes IX, VII et X justifiés (aucun autre écart), plus la ligne de gouvernance de l'amendement.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| **IX** — TRX-08 est un **P1 livré avant des P0 de la tranche T1** (« les priorités de `docs/user-stories-v2.md` font foi ») | Un moule n'a de valeur que s'il **précède** les cycles qui l'appliquent. C'est la seule fenêtre utile. | Livrer après VND/CMD/DSP/CRS : il faudrait repayer la migration sur du code déjà écrit, dans un cycle métier qui n'aurait aucune raison de la porter. Le fallback P0 (ne rien faire) devient alors le plus coûteux des deux. |
| **VII** — les **deux lectures d'instantané de configuration** que la migration réécrit ne sont couvertes par AUCUN test (aucun cas ne passe de configuration : les deux méthodes sortent immédiatement) | La spec l'assume explicitement plutôt que de le découvrir sur émulateur. Le portage est conçu pour être **évident à relire** — type identique, `ref.read` jamais `ref.watch` — parce que c'est le seul critère qui vaille quand la couverture est nulle (R5). | Écrire d'abord des tests de caractérisation : ce serait le geste correct, mais il exige de passer une configuration à deux écrans qui n'en reçoivent pas en test — donc de migrer d'abord ce que ces tests devaient protéger. L'ordre est impossible ; le risque est nommé, pas dissimulé. |
| **X** — `riverpod_analyzer_utils **1.0.0-dev.10**`, une **prérelease**, entre dans les 3 lockfiles | Épinglée **à l'exact** par `riverpod_generator 4.0.4` ET `riverpod_lint 3.1.4`. Non contournable : c'est la chaîne codegen officielle de Riverpod 3. | Rester en Riverpod 2 : la décision (mémoire projet, `research.md:40` du cycle 001) porte sur la v3, et la v2 est en fin de vie. Écrire les providers à la main sans codegen : c'est précisément la saveur que la demande écarte. |
| **X** — `build_runner` **plafonné à ^2.15.1** alors que 2.15.2 est la dernière stable | Conflit dur, vérifié par exécution : `build_runner >=2.15.2` exige `analyzer >=13.3.0`, `riverpod_generator 4.0.4` exige `analyzer ^12.0.0` → résolution impossible. | Forcer 2.15.2 : le build ne résout pas. Attendre une version compatible de la chaîne Riverpod : le cycle serait suspendu à un calendrier tiers. Un `pub upgrade` futur re-cassera : consigné. |
| **X** — `riverpod_lint 3.1.4` **n'est figé par aucun lockfile** | Depuis sa 3.1.0, il est un plugin de l'outil d'analyse déclaré dans `analysis_options.yaml`, hors du gestionnaire de paquets : « figé par lockfile » lui est **mécaniquement inapplicable** (vérifié : il n'apparaît dans aucun `pubspec.lock`, et fonctionne). SC-008 a été réaligné sur ce fait. | `custom_lint`, que la demande nommait : insoluble (`analyzer ^8` contre `^12`). Gel par **version exacte répétée à l'identique** dans les 3 `analysis_options.yaml`, accord garanti par script — c'est le maximum atteignable. |
| **Gouvernance** — la constitution est amendée dans le périmètre de ce cycle (FR-040) | Le verrou EST la raison d'être du cycle : sans lui, le refactor est un goût personnel exprimé une fois, et rien n'empêche le cycle CRS de réintroduire un notificateur. | Éditer `.specify/memory/constitution.md` depuis ce cycle est **interdit par la gouvernance** : amendement **MINOR (1.0.1 → 1.1.0)** à passer via `/speckit.constitution`, avec rapport d'impact et propagation aux templates, juste après ce plan. |
