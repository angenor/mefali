# Implementation Plan: Prestataires agréés et catalogue vendeur

**Branch**: `005-prestataires-catalogue-vendeur` | **Date**: 2026-07-18 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/005-prestataires-catalogue-vendeur/spec.md`

## Summary

Le cycle VND livre le crate `prestataires` : l'entité générale prestataire
(fiche, agrément avec charte signée scannée, identité de plaque — jeton HMAC
stocké + code de secours à 4 chiffres — dont la validité DÉRIVE de l'état
d'agrément), son extension vendeur (catalogue à prix entiers en unités mineures,
prix barrés strictement supérieurs, retrait réversible), le site unique porteur
du GPS, des horaires hebdomadaires et du statut de boutique (ouvert/fermé/fermé
pour la journée/pause temporisée — état effectif calculé par une fonction PURE,
sans ordonnanceur ni événement d'échéance), et la rupture par trois sources
(vendeur, coursier sur place via le port `CommandesActives` bouché en attendant
CMD, admin) avec masquage automatique à 2 signalements distincts / 7 jours
(paramètres de zone) évalué à l'écriture. L'agrément recompte les prestataires
agréés et appelle `PgZones::recalculer_activation` dans la même transaction
(ZON-03 trouve enfin son appelant). Surface : 1 endpoint public (consultation —
exception VIII documentée), la résolution de plaque sous session authentifiée,
11 vendeur, 21 admin, 1 coursier ; et les DEUX écrans vendeur de Mefali Pro (V1 statut boutique, V2
catalogue & stock) en Riverpod codegen, remplaçant le placeholder `InterfacePro`.
18 types d'événements outbox déclarés avant implémentation ; provisions VND-06
(n sites) et VND-07 (plans) = tables seulement.

## Technical Context

**Language/Version**: Rust stable 1.97 (workspace `rust-version`), édition 2021 ; Dart/Flutter stable (lockfiles du monorepo)

**Primary Dependencies**: Actix Web 4.14, sqlx 0.9 (Postgres, macros, offline), utoipa 5.5 + utoipa-actix-web (`split_for_parts`), aws-sdk-s3 1.138 (Garage, `force_path_style`), actix-governor, actix-multipart, hmac/sha2 (jeton de plaque), chrono-tz (fuseau de zone) ; Flutter + Riverpod codegen (flutter_riverpod, riverpod_annotation, riverpod_generator, build_runner, riverpod_lint), client `mefali_api_client` généré (dart-dio 7.23.0, built_value)

**Storage**: PostgreSQL (nouveau schéma `prestataires`, migration `0004_prestataires.sql`) — seule vérité durable ; Garage S3 (photos fiche/articles, charte signée — bucket privé, URLs présignées TTL 10 min) ; Redis inchangé (rate-limit IP des surfaces publiques)

**Testing**: `cargo test` avec `#[sqlx::test(migrations = "../migrations")]` (base éphémère par test), doubles mémoire des ports (`CommandesActivesFixes`, `MemoireObjets`) ; `flutter test` + harnais `mefali_core/harnais.dart` (`conteneurMefali`, `TransportFake`) ; `dart analyze` (JAMAIS `flutter analyze`) ; `cargo sqlx prepare` après tout changement SQL

**Target Platform**: API Linux (VPS) ; Mefali Pro Android/iOS (une seule identité, `.adaptive`)

**Project Type**: monorepo — backend Rust (crates de domaine + binaire `api`) + app Flutter `mefali_pro` + package `mefali_core` + clients générés

**Performance Goals**: consultation publique et bascules « en un geste » : la lecture qui suit une bascule rend TOUJOURS le nouvel état (SC-007) — aucune mise en cache de l'état effectif ; rate-limit IP sur les 2 endpoints publics (précédent `/config`)

**Constraints**: état effectif de boutique DÉRIVÉ à la lecture (aucun ordonnanceur, aucun événement d'échéance) ; validité du jeton DÉRIVÉE de l'agrément (aucune liste de révocation) ; capacités vendeur DÉRIVÉES du rattachement + état du prestataire (aucune cascade de rôle) ; montants entiers + ISO 4217 (CHECK en base pour prix barré > prix) ; événement outbox dans la MÊME transaction que toute transition décidée ; payloads sans nom/contact/GPS

**Scale/Scope**: 1 migration (13 tables, 3 enums), 35 opérations HTTP (1 publique, 1 sous session, 11 vendeur, 21 admin, 1 coursier), 2 traits de lecture + 1 port + méthodes inhérentes d'écriture, 18 types d'événements outbox + 6 déclarations MET-01, 2 écrans + 1 shell + 2 providers codegen dans Mefali Pro, ~7 fichiers de tests d'intégration backend, 3 fichiers de seeds touchés

## Constitution Check

*GATE: passé avant la Phase 0 ; re-vérifié après la Phase 1 (voir fin de section).*

Portes dérivées de `.specify/memory/constitution.md` (v1.1.0) :

- [x] **I. Sources de vérité** : aucun client édité à la main — `openapi.json`
  régénéré par `export-openapi` puis `scripts/generate-clients.sh` (nouveaux
  groupes `PrestatairesApi`/`VendeurApi`/`CoursierApi`, fusion `AdminApi`) ;
  schéma modifié UNIQUEMENT par la NOUVELLE migration `0004_prestataires.sql` ;
  les 4 paramètres « paramétrables » (seuil + fenêtre de masquage, affichage
  rupture par catégorie, conservation de charte) vivent en configuration de zone
  (héritage), inscrits au Récapitulatif le 2026-07-18 (research R8).
- [x] **II. Architecture** : travail dans le crate de domaine `prestataires`
  (squelette existant), dépendances `socle`/`zones`/`comptes` sans cycle ; AUCUN
  champ logistique, AUCUNE table de commande ; « prestataire ≠ vendeur » rendu
  OPPOSABLE par la table d'extension `vendeur` et la paire de traits
  `Prestataires`/`Vendeurs` (research R14) ; le port technique `DepotObjets`
  migre de `comptes` vers `socle` (reprise annoncée par la spec, research R1) ;
  Redis éphémère uniquement (rate-limit), Postgres seule vérité.
- [x] **III. Argent** : `bigint` unités mineures + colonne `devise` posée par le
  serveur depuis la zone ; `CHECK (prix_barre_unites > prix_unites)` en base ;
  verrouillage par `figer_prix` + table `prix_fige` sans UPDATE (SC-005) ; aucun
  chemin de paiement.
- [x] **IV. Distances** : aucun calcul de distance ce cycle (le GPS du site est
  stocké, consommé par TRF/DSP plus tard) — rien à dégrader, rien à journaliser.
- [x] **V. Offline & idempotence** : le signalement coursier porte un UUID
  généré côté client (= id de ligne, `ON CONFLICT DO NOTHING`) + horodatage
  local, conçu pour la file hors-ligne du cycle CRS ; rejeu sans double comptage
  (FR-039, research R10).
- [x] **VI. Événements** : 18 types `<entite>.<action>` écrits par
  `socle::ecrire_evenement` dans la MÊME transaction que chaque transition
  DÉCIDÉE ; les échéances (pause, journée) n'émettent RIEN — clarification de la
  spec (research R3) ; déclaration dans `docs/taxonomie-evenements.md` AVANT
  implémentation + sous-section produit MET-01 (research R16).
- [x] **VII. Qualité** : chaque transition des deux machines à états (prestataire,
  statut boutique) couverte par un test d'intégration (quickstart §2) ;
  `cargo sqlx prepare` ; toute chaîne des écrans V1/V2 en clés i18n fr
  (`app_fr.arb`).
- [x] **VIII. Sécurité** : toutes les écritures protégées par rôle
  (`exiger_role` + garde de rattachement à trois refus distincts) ; UNE
  surface publique en lecture seule JUSTIFIÉE au Complexity Tracking
  (consultation FR-027 — la plaque est un canal d'acquisition) ; la
  résolution de plaque exige une session valide, AUCUN rôle particulier
  (analyse C1 — FR-011 respecté à la lettre) ; médias en bucket privé,
  présignés TTL 10 min ; réponse
  neutre 404 pour prospect/suspendu/inconnu ; rétention de la charte
  paramétrée par zone (5 ans post-relation), photos purgées avec leur objet.
- [x] **IX. Périmètre** : VND-01→04 sont P0 (T1/T2) — le cycle crée l'offre
  commandable, condition des commandes/jour ; PROVISIONS strictement en tables
  (multi-sites : aucune sélection nulle part ; plans : aucune lecture/écriture ;
  `commande_id`/`reference_externe` sans FK) ; VND-05/08/09, V3, écrans admin et
  client explicitement exclus.
- [x] **X. Versions** : aucune nouvelle brique ; nouvelles deps de crate
  (hmac/sha2, chrono-tz) prises en dernière stable et figées par le lockfile du
  workspace.
- [x] **XI. Design** : V1/V2 en widgets Material 3 thémés `mefali_core` depuis
  `tokens.md` (interrupteur 96 px, bascule 84×44, montants « 1 500 FCFA » à
  espace fine) ; les PNG V1/V2 sont la cible, AUCUNE transposition DOM/CSS ;
  constructeurs `.adaptive`, pas de Cupertino.
- [x] **XII. Riverpod codegen** : `Boutique` et `MesArticles` en
  `AsyncNotifier` autoDispose générés (`.g.dart` commités), injection par la
  portée, `retry: pasDeRetry` déjà posé sur le conteneur, état de formulaire
  LOCAL (steppers, brouillons), analyse `dart analyze`.

**Re-vérification post-design (Phase 1)** : PASS — le design n'a introduit aucune
violation nouvelle ; les deux exceptions au principe VIII sont documentées au
Complexity Tracking ; la reprise `DepotObjets` → `socle` renforce II sans changer
l'API publique de `comptes`.

## Project Structure

### Documentation (this feature)

```text
specs/005-prestataires-catalogue-vendeur/
├── plan.md              # Ce fichier
├── research.md          # Phase 0 — 17 décisions (R1..R17)
├── data-model.md        # Phase 1 — schéma, machines à états, événements, seeds
├── quickstart.md        # Phase 1 — validation SC-001..SC-013
├── contracts/
│   └── prestataires-api.yaml   # Phase 1 — cible de conception (utoipa fait foi)
├── checklists/
└── tasks.md             # Phase 2 (/speckit-tasks — PAS créé par ce plan)
```

### Source Code (repository root)

```text
backend/
├── crates/socle/src/
│   └── objets.rs                    # NOUVEAU — port DepotObjets repris de comptes (R1)
├── crates/comptes/src/
│   └── ports.rs                     # MODIFIÉ — ré-exporte socle::{DepotObjets, …}
├── crates/zones/src/
│   └── parametre.rs                 # MODIFIÉ — validation affichage_rupture + namespaces rupture./charte./zone.
├── crates/prestataires/             # NOUVEAU (squelette → domaine complet)
│   ├── Cargo.toml                   # deps : socle, zones, comptes, sqlx, hmac/sha2, chrono-tz…
│   ├── src/lib.rs                   # exports publics
│   ├── src/modele.rs                # enums, DTO domaine, ErreurPrestataires
│   ├── src/depot.rs                 # traits Prestataires + Vendeurs, PgPrestataires (composition racine)
│   ├── src/ports.rs                 # port CommandesActives + AucuneCommandeActive + CommandesActivesFixes
│   ├── src/prestataire.rs           # fiche, cycle de vie (transition pure), correction FR-056, recomptage R7
│   ├── src/plaque.rs                # génération HMAC jeton + code, résolution (R2)
│   ├── src/rattachement.rs          # rattacher/détacher + rôle vendeur idempotent (R11)
│   ├── src/site.rs                  # site, horaires, actions boutique, etat_effectif PURE (R3)
│   ├── src/catalogue.rs             # articles, prix, retrait/remise, figer_prix (R6)
│   ├── src/disponibilite.rs         # bascules 3 sources, signalements, fenêtre glissante (R10)
│   ├── src/consultation.rs          # fiche publique, commandable (FR-028), affichage_rupture (R8)
│   └── tests/                       # bac/mod.rs + agrement.rs, suspension.rs, catalogue.rs,
│                                    #   boutique.rs, ruptures.rs
├── api/src/
│   ├── lib.rs                       # MODIFIÉ — montage routes (×2 : api_openapi + serveur), PgPrestataires
│   ├── infra_s3.rs                  # MODIFIÉ — implémente socle::DepotObjets
│   ├── prestataires_http.rs         # NOUVEAU — 2 endpoints publics (tag prestataires)
│   ├── vendeur_http.rs              # NOUVEAU — 11 endpoints vendeur + garde de pilotage
│   ├── admin_prestataires_http.rs   # NOUVEAU — 22 endpoints admin (multipart photos/charte)
│   └── signalements_http.rs         # NOUVEAU — 1 endpoint coursier
├── migrations/0004_prestataires.sql # NOUVELLE migration (13 tables, 3 enums)
└── seeds/
    ├── 10_zones_tiassale.sql        # MODIFIÉ — 5 clés de zone (R8)
    ├── 30_prestataires.sql          # NOUVEAU (R15)
    └── 35_articles.sql              # NOUVEAU (R15)

apps/
├── mefali_pro/lib/
│   ├── roles/interface_pro.dart     # MODIFIÉ — branche RolePro.vendeur → InterfaceVendeur (FR-046)
│   ├── vendeur/interface_vendeur.dart      # NOUVEAU — shell NavigationBar [Boutique | Articles]
│   ├── vendeur/composants.dart             # NOUVEAU — InterrupteurBoutique, BasculeStock
│   ├── vendeur/boutique/ecran_boutique.dart    # NOUVEAU — V1 (états ouvert/pause/fermé + rappel)
│   ├── vendeur/boutique/etat_boutique.dart     # NOUVEAU — provider Boutique (AsyncNotifier) + .g.dart
│   ├── vendeur/articles/ecran_articles.dart    # NOUVEAU — V2 liste (recherche, bascule, retirés)
│   ├── vendeur/articles/fiche_article.dart     # NOUVEAU — V2 fiche (steppers, promo, aperçu)
│   ├── vendeur/articles/mes_articles.dart      # NOUVEAU — provider MesArticles (AsyncNotifier) + .g.dart
│   └── l10n/app_fr.arb              # MODIFIÉ — clés proBoutique… / proArticle…
├── mefali_pro/test/vendeur/         # NOUVEAU — tests providers + widgets V1/V2
└── packages/mefali_core/lib/src/format/montant.dart   # NOUVEAU — formaterMontant (tokens.md) + test

clients/dart, clients/ts              # RÉGÉNÉRÉS (jamais édités)
docs/taxonomie-evenements.md          # MODIFIÉ — 18 événements outbox + sous-section MET-01, AVANT implémentation
```

**Structure Decision** : un seul crate de domaine nouveau (`prestataires`,
squelette déjà membre du workspace) ; deux reprises ciblées hors périmètre
strict, toutes deux commandées par la spec — le port objets vers `socle` (R1) et
le validateur de clés de `zones` (R8). Côté apps, tout le nouveau code vendeur
vit sous `mefali_pro/lib/vendeur/` ; `mefali_core` ne gagne que le formatage de
montant (futur consommateur client au cycle CMD). Aucun changement dans `web/`,
`mefali_client`, ni les crates `qr`/`commandes` (le trait `ServiceWorkflow`
n'est pas touché — les workflows vendeur restent au cycle CMD).

## Livrables attendus (demandés dans l'input du plan)

| Livrable | Où |
|---|---|
| **Migrations** | `0004_prestataires.sql` : schéma `prestataires`, enums `statut_prestataire`/`statut_boutique`/`source_bascule`, tables `plan`, `plan_caracteristique` (PROVISION), `prestataire`, `photo_prestataire`, `charte_signee`, `site`, `horaire_site`, `rattachement_compte`, `vendeur`, `article` (CHECK prix barré), `disponibilite_article`, `signalement_rupture`, `prix_fige` — DDL complet en [data-model.md](data-model.md) §2–3. Seeds `30_prestataires.sql`/`35_articles.sql` + clés de zone dans `10_zones_tiassale.sql` (§9, R15). |
| **Endpoints (utoipa)** | 35 opérations — 1 publique (`GET /prestataires/{id}`), 1 sous session (`GET /prestataires/plaque/{jeton}` — analyse C1), 11 `/vendeur/prestataires/…` (boutique, action, horaires, articles, photo, disponibilité, retrait, remise), 21 `/admin/prestataires/…` (CRUD fiche, photos, charte, site, boutique, agrément, suspension, rétablissement, correction, rattachements, catalogue miroir), 1 `POST /coursier/signalements-rupture` (Idempotency-Key). Contrat : [contracts/prestataires-api.yaml](contracts/prestataires-api.yaml) ; annotations sur le patron du cycle 003 (`bearerAuth`, `ErreurApi`, multipart, montage ×2). |
| **Structures & traits exposés** | Traits de LECTURE `Prestataires` (commandable — FR-028 pour CMD ; resoudre_jeton — pour QRC ; fiche_publique — pour WEB ; prestataires_pilotables — pour CRS) et `Vendeurs` (articles_commandables — pour CMD), impl `PgPrestataires` (composition : pool + `PgZones` + `PgComptes` + ports `socle::DepotObjets`, `CommandesActives`) ; ÉCRITURES = méthodes inhérentes sur `&mut PgTransaction` dont `figer_prix` (CMD-03) ; port `CommandesActives` + bouchon prod `AucuneCommandeActive` + double de test (R5, R6, R14) ; reprise `socle::DepotObjets` (R1). |
| **Événements outbox / métriques** | 18 types (payloads en [data-model.md](data-model.md) §6) : `prestataire.{cree,modifie,agree,suspendu,retabli,corrige}`, `charte.deposee`, `rattachement.{cree,supprime}`, `site.{statut_boutique_change,horaires_modifies}`, `article.{cree,modifie,retire_du_catalogue,remis_au_catalogue,mis_en_rupture,remis_en_vente}`, `signalement_rupture.recu` — registre `docs/taxonomie-evenements.md` mis à jour AVANT implémentation (FR-051) ; + `categorie.activation_changee` (cycle 002) émis via le recalcul R7 ; + sous-section produit MET-01 (6 déclarations, aucune émission — R16). Échéances et seeds n'émettent RIEN. |
| **Écrans / widgets** | `mefali_pro` : `InterfaceVendeur` (shell 2 onglets, `_Bascule` en tête, `PiedPro` préservé), `EcranBoutique` (V1 : interrupteur 96 px, pause 30 min/1 h/2 h, +30 min, fermer la journée, horaires, rappel FR-035), `EcranArticles` (V2 : recherche, compteur, `BasculeStock` 84×44, section retirés) + `FicheArticle` (steppers, promo avec aperçu, dispo) ; providers `Boutique`/`MesArticles` (AsyncNotifier codegen) ; `mefali_core` : `formaterMontant` ; clés i18n `proBoutique…`/`proArticle…` (R17). |
| **Tests d'intégration** | Backend : `agrement.rs`, `suspension.rs`, `catalogue.rs`, `boutique.rs`, `ruptures.rs` (crate) + gardes/neutralité/consultation/seeds (api) — mapping complet SC-001→SC-013 en [quickstart.md](quickstart.md) §2, avec fonction pure `etat_effectif` et table `transition` testées sans base ; Flutter : tests providers (TransportFake) + widgets V1/V2 ; portes : `cargo sqlx prepare`, clients régénérés sans diff, `dart analyze`. |

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Principe VIII — 1 endpoint public sans authentification (`GET /prestataires/{id}`) | FR-027 (clarifié) : la fiche est publique en lecture seule, la plaque est un canal d'acquisition dès ce cycle (cadrage §3.1/§5.3) | Exiger un compte pour consulter tuerait le canal d'acquisition (scan de plaque par un passant). Garde-fous : lecture seule, sous-ensemble strict (ni contact, ni GPS, ni exploitation — SC-013), 404 NEUTRE (suspendu ≡ inconnu), rate-limit IP — même patron documenté que `/config?zone=` (cycle 002). La résolution de plaque, elle, exige une session valide (analyse C1) : l'exception ne couvre QUE la consultation, FR-011 reste littéralement vrai |
| Principe VIII — médias servis à des lecteurs non authentifiés via URLs présignées (photos de fiche/articles dans la consultation publique) | Les photos font partie du sous-ensemble public de FR-027 (maquettes C2/V2) ; le bucket reste privé | Un proxy de flux par l'API doublerait la bande passante du VPS pour le même résultat ; précédent accepté au Complexity Tracking du cycle 003 (TTL 10 min, clés non devinables UUIDv7) |
