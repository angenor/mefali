# Implementation Plan: QR prestataire, plaque et scans de collecte

**Branch**: `006-qr-plaque-collecte` | **Date**: 2026-07-23 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/006-qr-plaque-collecte/spec.md`

## Summary

Le cycle QRC porte les **parcours** de la traçabilité QR — l'identité de plaque (jeton HMAC révocable, code de secours, résolution) est déjà livrée par le cycle 005 et seulement **consommée** ici. Trois blocs :

1. **PDF de plaque** (QRC-01) — le crate `qr` compose un document imprimable (modules QR dessinés en vectoriel + nom + code de secours) à partir du jeton existant, le dépose dans Garage via `socle::DepotObjets` et l'expose en téléchargement admin par URL présignée.
2. **Scan de collecte en course** (QRC-02/03/04) — le crate `qr` orchestre la vérification (résolution du jeton via `prestataires`, géo-proximité < 100 m, politique photo résolue, code dégradé par empreinte + 3 essais, incident « plaque à remplacer »), puis fait basculer l'arrêt en COLLECTÉ ; quand tous les arrêts d'une **livraison** sont résolus, la livraison passe **EN_LIVRAISON**. Tout fonctionne **hors-ligne** (pré-provisionnement d'empreintes, file d'actions idempotente, réconciliation serveur au rejeu).
3. **Socle logistique minimal** — le modèle documenté `livraison → segment → arrêt` (constitution II) n'existe pas encore (crate `commandes` = stub). QRC en introduit la tranche minimale dans le crate `commandes` comme **socle que CMD étendra** ; l'affectation coursier↔livraison (DSP) est simulée dans les tests, exactement comme le cycle 005 a simulé le coursier sur place (`CommandesActivesFixes`).

Côté apps : première surface **coursier** de Mefali Pro (tranche « scanner & collecter » de K3) et première **file d'actions offline** de `mefali_core` (aujourd'hui un simple placeholder, constitution IX).

## Technical Context

**Language/Version** : Rust stable (édition workspace) ; Dart/Flutter (stable, Riverpod 3 codegen) ; TypeScript généré.

**Primary Dependencies** :
- Backend : Actix Web 4.14, sqlx 0.9 (PostgreSQL, macros vérifiées, cache `.sqlx`), utoipa 5.5 + utoipa-actix-web 0.1 + utoipa-swagger-ui 9 (contrat auto-collecté), `aws-sdk-s3` 1.138 (Garage), Redis/deadpool-redis, `hmac` 0.13 + `sha2` 0.11 + `rand` 0.10 (déjà présents), `uuid` v7. **À ajouter** (crate `qr`) : `qrcode` (matrice de modules) + `printpdf` (composition du PDF) — voir [research.md](./research.md) R2.
- Apps : Flutter + `mefali_core` (ThemeData M3 depuis `docs/design/tokens.md`, Inter .ttf, Material Symbols Rounded), Riverpod codegen (`flutter_riverpod` 3, `riverpod_annotation` 4, `riverpod_generator` 4), `image_picker` 1.2 (déjà là), Shorebird OTA. **À ajouter** : `mobile_scanner` (QR), `geolocator` (GPS), `drift` (file offline), `permission_handler` (runtime caméra+localisation) — R5/R11.
- Web : hors périmètre ce cycle (la fiche publique et le scan hors contexte sont au cycle WEB ; QRC ne fournit que la résolution du jeton, déjà exposée par 005).

**Storage** : PostgreSQL (schémas `commandes` [socle] et `qr` [nouveau] — migrations `0005`/`0006`) ; Garage/S3 (PDF de plaque, photos de récupération) via `socle::DepotObjets` ; Redis (compteur d'essais du code dégradé — éphémère). Local app : `drift` (SQLite) pour la file d'actions et le pré-provisionnement.

**Testing** : `cargo test` (tests d'intégration par transition, doubles `MemoireObjets` / `CommandesActivesFixes`) ; `cargo sqlx prepare` après tout SQL ; `flutter test` + `dart analyze` (jamais `flutter analyze`, constitution XII).

**Target Platform** : serveur Linux (API) ; Android 360×800 (Mefali Pro, coursier) — iOS non vérifié (Xcode à installer, cf. mémoire cycle plateformes).

**Project Type** : monorepo — backend Rust (monolithe modulaire) + apps Flutter + contrat OpenAPI générant les clients.

**Performance Goals** : scan → COLLECTÉ perçu instantané (< 1 s en ligne) ; collecte hors-ligne confirmée **localement immédiatement** (0 attente réseau) ; PDF de plaque généré à la demande (< 2 s).

**Constraints** : offline-first coursier (constitution V) ; montants entiers unités mineures + ISO 4217 (III) ; toute chaîne = clé i18n fr ; toute transition = événement outbox dans la même transaction (VI) ; géo-proximité point-rayon (jamais OSRM, cf. Complexity Tracking).

**Scale/Scope** : Tiassalé (MVP), un vertical (restauration + courses). Panier multi-vendeurs natif (1..n arrêts par course).

## Constitution Check

*GATE : passé avant la recherche, re-vérifié après conception (voir fin de section).*

- [x] **I. Sources de vérité** : deux NOUVELLES migrations (`0005_commandes.sql`, `0006_qr.sql`) — `0001..0004` intouchées ; clients Dart/TS régénérés depuis `openapi.json` (jamais édités) ; paramètres « paramétrables » (distance de scan, seuil de montant photo, politique photo de catégorie, rétention photo) en **configuration de zone** héritée (`zones::ConfigurationZones`), jamais en dur.
- [x] **II. Architecture** : travail dans le crate `qr` (nouveau, depuis stub) et le crate `commandes` (socle logistique minimal — sa place selon constitution II, pas dans `qr`) ; **le tronc `commande` reste sans champ logistique** — l'état EN_LIVRAISON vit sur le composant `livraison` (R8) ; modèle `livraison → segment → arrêt` respecté ; aucune supposition « commande = livraison » ni « prestataire = vendeur » ; Redis éphémère (compteur d'essais), Postgres seule vérité durable. Voir Complexity Tracking (justification du socle `commandes`).
- [x] **III. Argent** : `montant_avance` (unités mineures) + `devise` ISO 4217 portée par la zone ; seuil de photo en unités mineures ; jamais de flottant ; aucun paiement partiel (QRC ne touche pas au paiement — le cash à l'arrêt relève de CRS/CMD).
- [x] **IV. Distances** : **la vérification de scan est une proximité point-rayon (grand-cercle) à la position du site**, PAS une distance de trajet — OSRM ne s'applique pas ici (voir Complexity Tracking, justification explicite). Aucune distance de livraison/ETA n'est calculée ce cycle (TRF).
- [x] **V. Offline & idempotence** : toute action de collecte porte un **UUIDv7 client + horodatage local**, part dans la **file locale** (`drift`, construite ce cycle), rejeu **idempotent** (registre `qr.action_traitee`), **serveur fait foi** au rejeu ; les **empreintes (hash) du jeton et du code** sont pré-provisionnées à l'assignation pour la validation hors-ligne (V, littéral).
- [x] **VI. Événements** : cinq événements outbox écrits dans la même transaction (`socle::ecrire_evenement`) — `plaque.generee`, `arret.collecte`, `livraison.mise_en_livraison`, `plaque.remplacement_requis`, `arret.collecte_rejetee` — **déclarés dans `docs/taxonomie-evenements.md` avant implémentation** (tâche dédiée). Payloads minimisés ARTCI (aucun lat/lng brut ; `gps_ok`/`distance_m` ; `acteur` = UUID).
- [x] **VII. Qualité** : tests d'intégration pour CHAQUE transition (collecte par scan, collecte par code, gating EN_LIVRAISON, révocation observée, dégradé 3 essais + incident, rejet au rejeu hors-ligne) ; `cargo sqlx prepare` après le SQL ; aucune chaîne en dur (clés i18n fr) ; logs corrélés.
- [x] **VIII. Sécurité** : endpoints protégés par rôle (`exiger_role(Role::Admin)` pour la plaque, `Role::Coursier` pour course/collecte) ; le pré-provisionnement renvoie des **empreintes**, jamais le code ni un secret ; **rétention limitée des photos de récupération** (paramètre de zone + job de purge, patron du repère vocal R8) ; aucune nouvelle surface non authentifiée (la résolution du jeton, déjà exposée par 005, reste sous session).
- [x] **IX. Périmètre** : QRC augmente la **fiabilité des livraisons** (preuve anti-fraude de récupération, passage automatique en livraison) — cœur de la proposition de valeur (P0). Le socle `commandes` est **minimal** (aucune logique CMD : ni création, ni cash, ni substitution, ni dispatch) ; les PROVISIONS restent données seules. Priorités P0 des stories QRC-01..04 respectées.
- [x] **X. Versions** : nouvelles dépendances (`qrcode`, `printpdf` ; `mobile_scanner`, `geolocator`, `drift`, `permission_handler`) prises en **dernière version stable vérifiée à l'initialisation** du module, puis figées par lockfile.
- [x] **XI. Design** : écran de scan en widgets Material 3 + composants `mefali_core` depuis `docs/design/tokens.md` (bouton `--primary #F97316`, COLLECTÉ `--success #15803D`, bandeau hors-ligne `--warning`) ; **jamais** de transposition DOM/CSS de `docs/design/html/` ; `.adaptive`, pas de Cupertino ; le PDF de plaque n'a aucune contrainte de tokens (artefact d'impression, aucune maquette).

**GATE PASSÉ** avant recherche. Re-vérification post-conception en fin de fichier.

## Project Structure

### Documentation (this feature)

```text
specs/006-qr-plaque-collecte/
├── plan.md              # Ce fichier
├── research.md          # Phase 0 — décisions R1..R12
├── data-model.md        # Phase 1 — schémas, migrations, machines à états, ports
├── quickstart.md        # Phase 1 — scénarios de validation (SC-001..009)
├── contracts/
│   └── qr-openapi.md     # Endpoints (annotations utoipa), DTO, événements
└── tasks.md             # Phase 2 — /speckit-tasks (NON créé par /speckit-plan)
```

### Source Code (dépôts réellement touchés)

```text
backend/
├── crates/
│   ├── commandes/       # SOCLE minimal : commande-ancre, livraison, segment,
│   │                    #   arret ; transition marquer_arret_collecte + gating
│   │                    #   EN_LIVRAISON ; port ArretsDeCollecte + doubles
│   └── qr/              # PDF de plaque, vérification de scan (résolution,
│                        #   proximité, photo, code dégradé, incident),
│                        #   pré-provisionnement d'empreintes
├── api/
│   └── src/
│       ├── qr_http.rs            # coursier : course active, collecte (multipart)
│       └── admin_prestataires_http.rs  # + téléchargement du PDF de plaque (admin)
└── migrations/
    ├── 0005_commandes.sql        # schéma commandes (socle)
    ├── 0006_qr.sql               # schéma qr (incident, idempotence)
    └── seeds/                    # + params de zone : distance scan, seuil photo,
                                  #   politique photo par catégorie, rétention photo

apps/
├── mefali_pro/
│   └── lib/coursier/            # NOUVEAU (miroir de lib/vendeur/) :
│       ├── interface_coursier.dart      # remplace le placeholder (interface_pro.dart)
│       └── course/
│           ├── ecran_course_active.dart # K3 : liste d'arrêts + bouton scan
│           ├── ecran_scan.dart          # mobile_scanner + mode dégradé (code)
│           └── etat_course.dart(+.g)    # AsyncNotifier (course + arrêts)
└── packages/mefali_core/
    └── lib/src/offline/         # NOUVEAU : file d'actions idempotente (drift)
        ├── file_actions.dart(+.g)       # @Riverpod(keepAlive: true)
        └── action_en_attente.dart       # modèle drift + rejeu
    └── lib/src/coursier/        # widgets partagés : BandeauHorsLigne, BandeauSucces

clients/                          # RÉGÉNÉRÉS depuis openapi.json (jamais édités)
infra/                            # inchangé (Garage/Redis/Postgres déjà en place)
```

**Structure Decision** : deux crates backend (`commandes` socle + `qr`), un nouveau module HTTP coursier (`qr_http`) plus l'ajout du téléchargement de plaque à l'admin, deux migrations, un nouveau dossier coursier dans Mefali Pro, et la première implémentation de la file offline dans `mefali_core`. Le web n'est pas touché (résolution déjà exposée par 005).

## Complexity Tracking

| Violation potentielle | Pourquoi nécessaire | Alternative plus simple rejetée parce que |
|-----------|------------|-------------------------------------|
| **Proximité grand-cercle** pour le géo-contrôle < 100 m (tension avec principe IV « jamais de vol d'oiseau ») | QRC-02 vérifie une **présence physique** à l'étal (« suis-je à moins de 100 m »), pas une distance de trajet. C'est une porte anti-fraude, bornée par un paramètre de zone, **jamais** utilisée pour un prix ou un ETA. | OSRM est fait pour router **entre** des points : router vers un point à 50 m est absurde et détruirait l'intention (présence physique). Le principe IV vise les distances de livraison/tarification (TRF, hors périmètre ici). Usage explicitement borné et documenté. |
| **Introduction du socle `commandes`** (tension avec principe IX « prêt ≠ construit ») | QRC-02 (P0) exige un **arrêt à collecter** et la bascule **EN_LIVRAISON**, dont le modèle est entièrement spécifié par les docs (`user-stories §CMD`, `cadrage §7.2/§7.3`) mais non construit (crate `commandes` = stub). Décision de clarification : introduire la **structure documentée** comme socle pour éviter la reprise. | Un modèle d'arrêt **local au crate `qr`** violerait « un schéma par module » (constitution II — la logistique est le domaine `commandes`) et créerait un modèle jetable que CMD devrait refondre — l'inverse exact de l'objectif « socle ». Le socle reste minimal : **aucune** logique CMD (création, cash, substitution, dispatch, autres états). |

## Phase 0 — Recherche

Toutes les inconnues techniques sont résolues (stack imposée). Les décisions de conception (découpage en crates, bibliothèques QR/PDF, proximité, empreintes hors-ligne, file offline, compteur d'essais, résolution de la politique photo, EN_LIVRAISON sur la livraison, plugins Flutter) sont consignées dans **[research.md](./research.md)** (R1..R12). Aucun `NEEDS CLARIFICATION` résiduel.

## Phase 1 — Conception & contrats

- **[data-model.md](./data-model.md)** : schémas `commandes` et `qr`, migrations `0005`/`0006`, enums, machines à états (arrêt, livraison), colonnes, index, ports/traits exposés aux autres crates, événements outbox émis.
- **[contracts/qr-openapi.md](./contracts/qr-openapi.md)** : endpoints (annotations `#[utoipa::path]`), DTO `ToSchema`, gardes de rôle, codes d'erreur i18n, et le tableau des événements.
- **[quickstart.md](./quickstart.md)** : scénarios de validation de bout en bout (SC-001..009), avec le déclencheur de course simulé.

## Post-Design Constitution Re-Check

Re-vérifié après Phase 1 : aucune nouvelle violation. Le tronc `commande` reste sans champ logistique (EN_LIVRAISON sur `livraison`) ; les payloads d'événements sont minimisés ARTCI ; toutes les surfaces sont protégées par rôle ; la file offline et le pré-provisionnement respectent le principe V. **GATE PASSÉ — prêt pour `/speckit-tasks`.**
