# Implementation Plan: Comptes, authentification OTP et rôles

**Branch**: `003-comptes-otp-roles` | **Date**: 2026-07-14 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/003-comptes-otp-roles/spec.md`

## Summary

Le cycle CPT crée la première logique métier du crate `comptes` (vierge à ce jour) : identité par numéro E.164 vérifié par OTP SMS (6 chiffres, 5 min, 3 essais, 3 SMS/h/numéro — compteurs Redis), sessions par appareil (JWT d'accès 15 min + refresh opaque révocable, rotation avec détection de réutilisation, session illimitée tant que non révoquée), rôles cumulables {client, coursier, vendeur, admin} avec validation admin (coursier demandé in-app avec dossier — pièce d'identité vers Garage/S3, véhicules du référentiel ZON-03, référent local — ; vendeur attribué à l'agrément), et adresses enregistrées avec repère vocal (purge après 12 mois d'inutilisation, paramètre de zone). Le cycle remplace l'extracteur temporaire `AdminAuth` (X-Admin-Token) par l'extracteur JWT + rôle, comme anticipé au cycle 002. CPT-06 = deux colonnes en provision, aucune logique. Première connexion réelle du backend à Redis (port `DepotEphemere`) et à Garage (port `DepotObjets`) ; côté Flutter, module d'auth partagé dans `mefali_core` + écrans dans les deux apps (aucun PNG cible n'existe pour l'auth → conception directe depuis `docs/design/tokens.md`). Aucun travail Nuxt (admin en API journalisée, précédent 002).

## Technical Context

**Language/Version**: Rust 1.97 (workspace backend, édition 2021) ; Dart/Flutter 3.44.6 (apps + mefali_core) ; TypeScript = client généré uniquement (aucun travail web ce cycle)

**Primary Dependencies**: existants — Actix Web 4.14, utoipa 5.5/utoipa-actix-web, sqlx 0.9, socle (outbox `ecrire_evenement`, config env, télémétrie), zones (trait `ConfigurationZones` pour l'indicatif par défaut, la rétention du repère vocal et les transports actifs). Activés depuis `[workspace.dependencies]` (déclarés au cycle 001, jamais consommés) : `redis 1.3` + `deadpool-redis 0.23` (R3), `aws-sdk-s3 1.138` (R7). Nouveaux backend : `jsonwebtoken` (R1), `phonenumber` (R4), `rand` (CSPRNG), `hmac` (R3), `actix-multipart` (uploads R7). Nouveaux Flutter (mefali_core) : `flutter_secure_storage` (jetons), `image_picker` (pièce), `record` + `just_audio` (repères vocaux — plugins natifs stabilisés tôt, cadrage §10.1). Tous en dernière version STABLE vérifiée puis figée à l'implémentation (constitution X).

**Storage**: PostgreSQL schéma dédié `comptes` (migration `0003_comptes.sql`, seule vérité durable) ; Redis = éphémère reconstructible uniquement (défis OTP, compteurs SMS/IP, jetons d'inscription — R3) ; Garage S3 = pièces d'identité + notes vocales de repère (bucket privé, URLs présignées — R7) ; OSRM non utilisé ce cycle

**Testing**: `cargo test` avec `#[sqlx::test(migrations = "../migrations")]` + implémentations mémoire des ports (`DepotEphemere`, `EnvoiSms`, `DepotObjets` — R3/R6/R7) pour tester expiration, essais et plafonds sans Redis réel ; `flutter test` (widgets auth, bascule de rôle, feuille adresse)

**Target Platform**: backend Linux (VPS docker compose, migrations embarquées — reconstruire le binaire `api` après ajout de migration) ; apps Android/iOS (une seule identité, `.adaptive`) ; contrat sur `/api-docs/openapi.json`

**Project Type**: monorepo — crate de domaine backend + endpoints publics/protégés + module partagé Flutter + écrans dans les 2 apps (premier cycle avec UI mobile)

**Performance Goals**: vérification OTP p95 < 150 ms en local ; extracteur `Auth` = 1 requête indexée supplémentaire par requête protégée (< 5 ms) ; révocation à distance effective ≤ 15 min (durée de l'accès court, SC-004) ; inscription complète < 2 min réception SMS comprise (SC-001)

**Constraints**: anti-énumération — réponses du parcours OTP identiques en contenu et forme pour numéro connu/inconnu (SC-003, tests dédiés) ; consentement ARTCI bloquant à l'inscription ; contrôle de rôle en base à CHAQUE requête (suspension immédiate, US3) ; provisions CPT-06 = colonnes seulement ; paramètres paramétrables (indicatif, durées note vocale/rétention) via configuration de zone, jamais en dur ; aucun montant ce cycle

**Scale/Scope**: MVP = 1 ville (Tiassalé), 2–4 coursiers, dizaines de comptes ; conçu pour multi-zones (indicatif par zone) et multi-appareils sans limite fixée ; 19 endpoints (5 `/auth`, 11 `/moi`, 3 `/admin`) ; ~8 écrans/composants Flutter

## Constitution Check

*GATE : passée avant la Phase 0 ; re-vérifiée après la Phase 1 — conforme, 2
écarts justifiés en Complexity Tracking.*

- [x] **I. Sources de vérité** : clients régénérés par `scripts/generate-clients.sh` uniquement (openapi-generator + build_runner + openapi-typescript) ; NOUVELLE migration `0003_comptes.sql` (0001/0002 intouchées) ; indicatif par défaut, durée max et rétention du repère vocal = paramètres de zone lus via `ConfigurationZones` (seed `20_comptes.sql`), jamais en dur ; constantes OTP = constantes produit (clarification spec, absentes du Récapitulatif des paramètres de zone).
- [x] **II. Architecture** : tout le domaine dans le crate `comptes` existant (squelette du cycle 001) ; pattern 002 respecté — lectures via trait public `Comptes`, écritures inhérentes sur `&mut PgTransaction` pour l'atomicité outbox ; DTO/`ErreurApi` en couche `api`, domaine pur ; AUCUNE supposition prestataire=vendeur (le rôle vendeur pointe vers l'agrément VND sans le contenir) ni commande=livraison (`livraison_origine` = uuid nu en provision, sans FK) ; Redis strictement éphémère reconstructible (perte = re-demander un code) ; Postgres seule vérité durable.
- [x] **III. Argent** : N/A — aucun montant ce cycle (les drapeaux CPT-06 sont des booléens en provision).
- [x] **IV. Distances** : N/A — aucune distance calculée ; la position GPS d'adresse est stockée, pas routée (le routage arrive avec TRF/CMD).
- [x] **V. Offline & idempotence** : aucune action coursier ce cycle (la file offline de `mefali_core` reste à construire au cycle CRS) ; le rafraîchissement de session est naturellement rejouable (rotation avec détection de réutilisation, R2) ; seeds idempotents.
- [x] **VI. Événements** : 14 événements `compte.*`/`session.*`/`role.*`/`dossier_coursier.*`/`adresse.*` écrits via `socle::ecrire_evenement` dans la MÊME transaction que chaque transition (R10) ; registre `docs/taxonomie-evenements.md` mis à jour AVANT implémentation ; le journal admin (qui, quand, motif — FR-014) = colonnes de décision + événements outbox, patron du cycle 002.
- [x] **VII. Qualité** : tests d'intégration sur TOUTES les transitions des machines à états (rôles, dossier, session — data-model §4) + garde-fous OTP + tests de neutralité (SC-003) ; `cargo sqlx prepare` après tout SQL ; `message_cle`/libellés = clés i18n fr (gen-l10n côté Flutter), aucune chaîne UI en dur.
- [x] **VIII. Sécurité** : ce cycle CRÉE la protection par rôle de tous les endpoints (extracteur `Auth` + `exiger_role`, remplacement de `AdminAuth` — R5) ; OTP rate-limité (3 SMS/h/numéro + 10 demandes/h/IP, R12) ; JWT 15 min + refresh révocable ; rétention limitée des médias (purge repère vocal 12 mois, R8 ; pièce = durée de vie du dossier). 2 écarts justifiés (Complexity Tracking) : endpoints `/auth/*` publics par nature ; URLs présignées à durée courte.
- [x] **IX. Périmètre** : CPT-01→05 tous P0 (tranche T1 pour 01→04) — l'inscription est la porte des commandes/jour ; PROVISIONS strictes : `prepaiement_impose`/`bloque` (colonnes, aucune logique), `livraison_origine` (uuid sans FK) ; CPT-06 hors périmètre.
- [x] **X. Versions** : `jsonwebtoken`, `phonenumber`, `hmac`, `rand`, `actix-multipart`, `flutter_secure_storage`, `image_picker`, `record`, `just_audio` en dernière version stable vérifiée à l'implémentation puis figée par lockfile ; redis/deadpool-redis/aws-sdk-s3 déjà figés au workspace.
- [x] **XI. Design** : PREMIER cycle avec UI Flutter — aucun PNG cible n'existe pour auth/adresses (rapport d'exploration §10) : conception directe depuis `docs/design/tokens.md` via `MefaliTokens`/`MefaliTheme` et composants `mefali_core` ; AUCUNE transposition DOM/CSS (aucun HTML d'auth n'existe de toute façon) ; pas de Cupertino, constructeurs `.adaptive` ; pas de mode sombre (tokens).

## Project Structure

### Documentation (this feature)

```text
specs/003-comptes-otp-roles/
├── plan.md              # Ce fichier
├── research.md          # Phase 0 — décisions R1..R13
├── data-model.md        # Phase 1 — schéma comptes, machines à états, traits
├── quickstart.md        # Phase 1 — validation SC-001→SC-008
├── contracts/
│   └── openapi-comptes.yaml  # Phase 1 — contrat des endpoints
└── tasks.md             # Phase 2 (/speckit-tasks — pas créé ici)
```

### Source Code (repository root)

```text
backend/
├── crates/comptes/src/          # NOUVEAU domaine (premier crate métier après zones)
│   ├── lib.rs                   # réexports API publique
│   ├── modele.rs                # Compte, Role, StatutRole, Session, DossierCoursier, Adresse, ErreurComptes
│   ├── otp.rs                   # défis OTP, garde-fous, neutralité (via DepotEphemere)
│   ├── inscription.rs           # flux vérifier → consentement_requis → créer compte
│   ├── session.rs               # émission/rotation/révocation, JWT
│   ├── role.rs                  # machine à états des attributions (R9)
│   ├── dossier.rs               # dossier coursier + véhicules (référentiel zones)
│   ├── adresse.rs               # adresses, repères, purge (R8)
│   ├── depot.rs                 # PgComptes (lectures trait / écritures PgTransaction)
│   └── ports.rs                 # DepotEphemere, EnvoiSms, DepotObjets (+ impls mémoire pour tests)
├── api/src/
│   ├── auth_http.rs             # NOUVEAU — extracteur Auth + exiger_role, endpoints /auth/*
│   ├── comptes_http.rs          # NOUVEAU — DTO utoipa + handlers /moi/*, /admin/comptes/*
│   ├── zones_http.rs            # MODIFIÉ — AdminAuth (X-Admin-Token) → Auth + rôle admin (R5)
│   ├── lib.rs                   # MODIFIÉ — wiring Redis/S3/SMS, montage routes, job de purge, SecurityScheme bearer
│   └── infra_redis.rs / infra_s3.rs  # NOUVEAU — impls réelles des ports (deadpool-redis, aws-sdk-s3)
├── crates/socle/src/config.rs   # MODIFIÉ — jwt_secret (retrait ADMIN_API_TOKEN)
├── migrations/0003_comptes.sql  # NOUVELLE migration (schéma comptes)
└── seeds/20_comptes.sql         # NOUVEAU seed (premier admin + paramètres de zone CPT)

clients/dart/, clients/ts/       # RÉGÉNÉRÉS (jamais à la main)

apps/packages/mefali_core/lib/src/
├── auth/                        # NOUVEAU — SessionAuth (jetons, refresh auto), écrans partagés
│                                #   EcranTelephone, EcranOtp, EcranConsentement
├── adresses/                    # NOUVEAU — ListeAdresses, FeuilleEnregistrerAdresse,
│                                #   LecteurNoteVocale, EnregistreurNoteVocale
└── appareils/                   # NOUVEAU — EcranAppareils (sessions, déconnexion à distance)

apps/mefali_client/lib/          # MODIFIÉ — navigation auth → accueil, paramètres (adresses, appareils)
apps/mefali_pro/lib/             # MODIFIÉ — routeur par rôle validé (bascule coursier/vendeur),
                                 #   FormulaireDossierCoursier, EcranEtatDemande

docs/taxonomie-evenements.md     # MODIFIÉ — registre des 14 événements CPT (avant implémentation)
infra/.env.example               # MODIFIÉ — JWT_SECRET, SMS_MODE ; retrait ADMIN_API_TOKEN
```

**Structure Decision** : le domaine entre dans le crate `comptes` prévu à cet
effet (constitution II) en suivant le patron établi par `zones` (trait de
lecture public, écritures transactionnelles, DTO en couche `api`). `web/` n'est
PAS touché (admin en API journalisée, précédent du cycle 002 ; écrans ADM en
T3). Les impls réelles Redis/S3 vivent dans la couche `api` (composition
racine) — le crate domaine ne connaît que ses ports.

## Livrables attendus (demandés dans l'input du plan)

| Livrable | Où |
|---|---|
| Migrations | `0003_comptes.sql` — 2 enums (`comptes.role`, `comptes.statut_role`), tables `compte`, `session`, `attribution_role`, `dossier_coursier`, `vehicule_declare`, `adresse` ([data-model](data-model.md) §1–3) |
| Endpoints (utoipa) | 5 endpoints `/auth/*` (4 publics rate-limités + déconnexion) + 11 `/moi/*` authentifiés + 3 `/admin/comptes/*` (rôle admin) + migration du `PUT /admin/zones/.../forcage` vers Bearer ([contracts/openapi-comptes.yaml](contracts/openapi-comptes.yaml)) |
| Structures & traits exposés | trait `Comptes` (`roles_valides`, `coursier_autorise_en_ligne` — porte CRS, `capacites_transport` — filtre DSP, `marquer_adresse_utilisee` — CMD), `PgComptes`, ports `DepotEphemere`/`EnvoiSms`/`DepotObjets`, extracteur `Auth` + `exiger_role` ([data-model](data-model.md) §5, [research](research.md) R5) |
| Événements outbox / métriques | `compte.cree`, `session.creee/revoquee`, `role.demande/attribue/valide/refuse/suspendu/retabli`, `dossier_coursier.soumis`, `adresse.enregistree/modifiee/supprimee/repere_vocal_purge` — registre taxonomie mis à jour avant implémentation ([research](research.md) R10) ; les métriques d'inscription/validation en dériveront (MET) |
| Écrans / widgets | `mefali_core` : EcranTelephone, EcranOtp (compte à rebours renvoi), EcranConsentement, ListeAdresses, FeuilleEnregistrerAdresse (+ lecteur/enregistreur vocal), EcranAppareils ; `mefali_pro` : routeur par rôle (bascule sans reconnexion), FormulaireDossierCoursier, EcranEtatDemande ; `mefali_client` : navigation + paramètres ([research](research.md) R11) |
| Tests d'intégration | garde-fous OTP (expiration, 3 essais, 3 SMS/h, invalidation à la re-demande), neutralité anti-énumération (SC-003), rotation/réutilisation/révocation de session, TOUTES les transitions rôles + dossier (avec événement outbox vérifié dans la transaction), porte coursier (SC-005), adresses + purge (rétention de zone), remplacement AdminAuth (JWT admin 200 / sans rôle 403 / ancien X-Admin-Token 401), seeds ×2 idempotents — parcours complet dans [quickstart.md](quickstart.md) |

## Complexity Tracking

> Écarts au principe VIII justifiés (aucun autre écart).

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Endpoints `/auth/otp/*`, `/auth/inscription`, `/auth/rafraichir` non authentifiés | Par nature : on ne peut pas exiger une session pour en créer une. | Aucune — surface minimale (4 routes), rate-limitée (Governor IP global + 3 SMS/h/numéro + 10 demandes/h/IP), réponses neutres anti-énumération, aucune donnée servie. |
| URLs présignées S3 (pièce pour l'admin, repère vocal pour son propriétaire) | Servir des médias privés sans faire transiter chaque octet par l'API ni rendre le bucket public. | Proxy intégral par l'API : double la bande passante du VPS pour un même niveau d'accès ; les URLs sont opaques, à durée courte (10 min), émises uniquement derrière un endpoint authentifié + rôle. |
