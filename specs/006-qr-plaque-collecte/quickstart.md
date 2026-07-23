# Quickstart — validation QRC (plaque, scan, collecte)

Guide de validation de bout en bout. Prouve les critères SC-001..009 de [spec.md](./spec.md) via les tests d'intégration backend (`cargo test`) et une passe manuelle de l'écran K3 dans Mefali Pro. Détails d'API : [contracts/qr-openapi.md](./contracts/qr-openapi.md) ; schémas : [data-model.md](./data-model.md).

## Prérequis

```bash
docker compose -f infra/docker-compose.yml up -d          # Postgres, Redis, Garage
cd backend && cargo sqlx migrate run                       # applique 0001..0006
cargo run --bin mefali-api & # (ou le binaire d'API) — charge les seeds si SEED_DIR
```

- Admin et coursier seedés (cycle 003) ; prestataires Tantie Affoué / Kofi agréés (seed 005).
- OTP lisible en dev : `--dart-define=MEFALI_DEV_OTP=true` (app) ou `/dev/otp` (API dev).
- **Déclencheur de course simulé** (pas de DSP) : les tests insèrent une `livraison` assignée au coursier + `segment` + `arret` visant un prestataire agréé (patron `CommandesActivesFixes`/`ArretsFixes`). Aucune course réelle n'existe en production tant que DSP n'est pas livré — c'est exact et voulu (R10).

## Jeu de tests d'intégration (backend)

Chaque transition de machine à états est couverte (constitution VII). Emplacements : `backend/crates/commandes/tests/`, `backend/crates/qr/tests/`, `backend/api/tests/`.

### SC-001 — Plaque imprimable, stable (QRC-01)

1. `GET /admin/prestataires/{tantie}/plaque` (jeton admin) → `200 { url, expire_le }` ; l'objet `qr/plaques/{tantie}.pdf` existe dans le double `MemoireObjets`, contient un PDF (magic `%PDF`), et l'événement `plaque.generee` est écrit.
2. Rappeler l'endpoint → l'URL re-pointe le **même** contenu ; `jeton_plaque`/`code_secours` inchangés (SC-001). 
3. `GET /admin/prestataires/{prospect}/plaque` (prestataire jamais agréé) → `404 plaque_absente` (FR-011).
4. Sans rôle admin → `403 role_requis`.

### SC-002 / SC-007 — Collecte par scan dans le rayon (QRC-02, anti-fraude)

1. Simuler une course : `livraison(coursier=yao) → segment → arret(prestataire=tantie, site=GPS Tantie, montant, photo facultative)`.
2. `POST /courses/arrets/{arret}/collecte` `{ mode: scan_qr, jeton: <jeton Tantie>, position: <à 30 m>, uuid_client, horodatage_local }` → `200`, `arret.statut = collecte`, `collecte_le` = horodatage **serveur**, événement `arret.collecte` (`mode=scan_qr`, `gps_ok=true`, sans lat/lng).
3. **SC-007** : rejouer avec `position` à 300 m → `422 hors_zone`, l'arrêt reste `a_collecter` (0 collecte à distance).

### SC-003 — Refus de correspondance / distance (QRC-02)

1. `mode: scan_qr, jeton: <jeton Kofi>` sur l'arrêt de Tantie → `422 plaque_invalide`/refus de correspondance ; arrêt inchangé.
2. Position hors rayon → `422 hors_zone` (déjà SC-002.3).

### SC-004 — Révocation observée (QRC-03)

1. Suspendre Tantie (`admin_prestataires_http::suspendre_prestataire`).
2. `POST …/collecte` `{ mode: scan_qr, jeton: <Tantie> }` → `422 prestataire_indisponible` (validité dérivée, via `resolution_plaque`).
3. Rétablir Tantie → la même collecte réussit (jeton inchangé).

### SC-005 — Bascule EN_LIVRAISON (QRC-02)

1. Course à 2 arrêts (Tantie, Kofi). Collecter Tantie → `en_livraison=false`, livraison `en_collecte`.
2. Collecter Kofi (dernier) → `200 { en_livraison: true }`, `livraison.etat = en_livraison`, événement `livraison.mise_en_livraison`. Vérifier qu'un arrêt `indisponible` (posé à la main, façon CMD-06) compte aussi comme résolu (FR-018).

### SC-006 — Mode dégradé + incident (QRC-04)

1. `POST …/collecte` `{ mode: code_secours, code: "0000" (faux), position: <30 m> }` → `422 code_incorrect` ; **incident `qr.incident_plaque` créé** (UNIQUE arret), événement `plaque.remplacement_requis` (une seule fois).
2. « 3 essais max » (FR-020) : les tentatives 1, 2 et 3 comparent le code (3× `422 code_incorrect`) ; **au-delà du 3ᵉ**, `422 code_epuise` (backstop Redis `qr:essais`), aucune nouvelle création d'incident. L'app borne localement la saisie à 3 (`_maxEssais = 3`).
3. Nouvel arrêt, `code: <code de secours réel de Tantie>`, dans le rayon → `200` collecté (`mode=code_secours`). Hors rayon avec bon code → `422 hors_zone` (FR-022).

### SC-008 — Hors-ligne, idempotence, réconciliation (QRC-02)

1. Collecte avec `uuid_client = U` → `200`. Rejouer la **même** requête (`uuid_client = U`) → `200` identique, **aucune** double collecte, **aucun** nouvel événement (`qr.action_traitee`).
2. Réconciliation d'un rejet : pré-provisionner, suspendre le prestataire, puis rejouer une collecte hors-ligne `uuid_client = V` → serveur refuse (`prestataire_indisponible`), l'arrêt **reste `a_collecter`**, événement `arret.collecte_rejetee` (`motif=jeton_revoque`) émis **une** fois ; re-rejeu de `V` → rien (idempotent).

### SC-009 — Traçabilité

Après le parcours complet, `SELECT type_evenement FROM outbox.evenement` contient `plaque.generee`, `arret.collecte`, `livraison.mise_en_livraison`, `plaque.remplacement_requis`, `arret.collecte_rejetee` ; aucun payload ne contient de lat/lng brut (ARTCI).

## Passe manuelle Mefali Pro (écran K3)

```bash
cd apps/mefali_pro
flutter pub get && dart run build_runner build --delete-conflicting-outputs
flutter run --dart-define=MEFALI_API_URL=http://<ip-lan>:8080 --dart-define=MEFALI_DEV_OTP=true
```

1. Se connecter en **coursier** → la branche coursier affiche l'**écran de course active** (remplace l'ancien placeholder) : liste d'arrêts (`CarteMefali` + `PuceStatut`), arrêt courant développé, **gros bouton `Scanner le QR`** en bas (token `--primary #F97316`).
2. Scanner un QR (plaque imprimée via SC-001) dans le rayon → l'arrêt coche **COLLECTÉ** (`--success #15803D`) ; passer au suivant.
3. Couper le réseau → le **bandeau hors-ligne** (`--warning`) apparaît ; scan et coches **restent actifs** (empreintes pré-provisionnées) ; rétablir le réseau → synchronisation, coches confirmées, **aucune** double collecte.
4. Simuler un QR illisible → **mode dégradé** : saisie du code 4 chiffres (3 essais), incident créé ; géoloc toujours exigée.
5. Dernier arrêt collecté → **bandeau succès** « tout est collecté → en route » (EN_LIVRAISON).

## Portes d'avant-commit

- `cargo test` + `cargo sqlx prepare` verts ; clients Dart/TS régénérés **sans diff**.
- `dart analyze` propre (jamais `flutter analyze`) ; `.g.dart` commités.
- `docs/taxonomie-evenements.md` mis à jour (5 événements) **avant** l'implémentation backend.
- Message conventionnel référençant la story (ex. `feat(qr): QRC-02 scan de collecte en course`).
