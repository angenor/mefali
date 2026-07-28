# Implementation Plan: App coursier — course active multi-arrêts, cash et hors-ligne

**Branch**: `010-coursier-course-active` | **Date**: 2026-07-28 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/010-coursier-course-active/spec.md`

## Summary

Ce cycle remplit le crate `coursier`, resté **vide depuis le socle** (« prêt ≠
construit »), et refond l'espace coursier de `mefali_pro` autour de la maquette
K3. Le travail se lit en cinq blocs :

1. **Course active enrichie** — un seul point d'entrée, `GET /courses/active`,
   qui passe du crate `qr` au crate `coursier` et cesse de ne servir que des
   arrêts : il porte désormais les **lignes d'articles par vendeur**, le client
   (nom d'usage, repère texte et vocal, position, téléphone), le **montant à
   encaisser**, et les **empreintes de remise** — que le cycle 008 a déjà
   écrites en base (`code_livraison_hash`, `jeton_reception_hash`) sans que
   personne ne les lise. C'est ce qui rend K3, K4 et le hors-ligne possibles
   sans une seule requête de plus au moment où Yao en a besoin.
2. **Preuves d'échec réelles** — `PgCoursier` implémente le port
   `commandes::PreuvesEchec` que le cycle 008 avait laissé à `PreuvesFixes`
   (aucun échec n'est déclarable en production aujourd'hui). Deux tables neuves :
   appels journalisés du coursier et relevés de présence — **distances
   arrondies, jamais de coordonnées**, patron ARTCI de `distance_scan_m`.
3. **Caisse** — un livre d'écritures **append-only** alimenté par un **second
   consommateur outbox** (`arret.collecte`, `livraison.livree`,
   `indemnisation.due`), sur le patron de `DispatchOutbox` livré au cycle 009.
   Aucune dépendance inverse : `commandes` continue d'ignorer `coursier`.
4. **Remise durcie** — idempotence de la remise (elle n'en a pas aujourd'hui),
   consolidation des essais consommés hors ligne, blocage, levée par
   l'exploitation, et drapeau de **dépôt autorisé** fermé par défaut.
5. **App** — K3 (checklist par vendeur, transitions un tap, note vocale hors
   ligne, appels), K4 (trois voies, pavé de code, blocage, preuves), K5
   (caisse), bandeau de gains sur K1, navigation basse, et le **service continu**
   qui garde l'app vivante écran éteint.

Le test qui fait foi est celui de la spec : réseau coupé **entre le dernier scan
et la confirmation de livraison**, tout se réconcilie — exactement une collecte,
exactement une remise.

## Technical Context

**Language/Version**: Rust stable (workspace `backend/`) ; Dart / Flutter 3.44.x
(apps + `mefali_core`) ; TypeScript (client généré, non touché ce cycle).

**Primary Dependencies**: Actix Web + `utoipa` / `utoipa-actix-web` ; `sqlx`
(Postgres, requêtes vérifiées à la compilation) ; Redis (éphémère : positions,
verrous, compteur d'essais du code vendeur) ; **Garage** via l'API S3 (photos,
notes vocales — la constitution a remplacé MinIO par Garage au PATCH 1.0.1 ; le
prompt du cycle dit MinIO, c'est Garage qui fait foi) ; OSRM **consommé
indirectement**, par le devis figé du cycle 007 — ce cycle n'appelle jamais le
routage ; Flutter : Riverpod codegen, `drift`, `mobile_scanner`, `geolocator`,
`just_audio` (lecture du repère, déjà dans `mefali_core`), `connectivity_plus`,
`dio` + client Dart généré ; **deux plugins natifs à ajouter** — service de
premier plan et notifications locales à canal dédié (versions figées à l'ajout,
constitution X).

**Storage**: PostgreSQL — **nouveau schéma `coursier`** (caisse, indemnisations,
appels, relevés de présence, photos de preuve) + colonnes ajoutées à
`commandes.commande` (dépôt autorisé, traces de blocage et de levée du code).
Garage pour les photos de preuve. Local à l'appareil : `drift` (file d'actions,
cache de course, checklist, essais, relevés en attente).

**Testing**: `cargo test` — tests d'intégration HTTP sur application Actix réelle
via un **nouveau bac** `backend/api/tests/bac_coursier/`, patron de
`bac_commandes` / `bac_dispatch` ; tests de domaine dans
`backend/crates/coursier/tests/` ; `flutter test` (widget + unitaires) dans
`mefali_pro` et `mefali_core` ; `dart analyze` (jamais `flutter analyze`).

**Target Platform**: API Linux (VPS) ; app coursier Android d'entrée de gamme
(360 × 800, plein soleil, réseau intermittent) ; iOS non vérifié (Xcode absent —
dette connue du cycle plateformes natives).

**Project Type**: Monorepo — backend Rust modulaire + apps Flutter + clients
générés.

**Performance Goals**: `GET /courses/active` ≤ 300 ms p95 (une seule requête,
tous arrêts et toutes lignes) ; drain de la file ≤ 5 s après le retour du réseau
(SC-004) ; validation locale d'une preuve de remise ≤ 2 s (SC-003) ; exposition
cash admin ≤ 5 s de retard sur la dernière collecte (SC-010).

**Constraints**: hors-ligne d'abord sur **toutes** les actions de course ;
montants entiers en unités mineures + ISO 4217 ; aucun secret (code, jeton,
numéro) dans un événement ou un journal ; aucune coordonnée brute persistée pour
la présence (distance arrondie) ; le service continu s'arrête quand le coursier
se met hors ligne.

**Scale/Scope**: Tiassalé, flotte de 2 à 4 coursiers ; **17 endpoints** nouveaux
ou modifiés (7 coursier, 8 exploitation, 2 existants adaptés) ; 2 migrations +
1 seed de **7 paramètres** ; 5 écrans Flutter (dont 3 neufs) ; 118 exigences de
spec.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Portes dérivées de `.specify/memory/constitution.md` (v1.1.0) — état **après
conception de la Phase 1** ; la première passe donnait le même résultat, aucune
porte n'a bougé au design.

- [x] **I. Sources de vérité** : aucun fichier de `clients/dart` ou `clients/ts`
  touché à la main — ils sont régénérés (`scripts/generate-clients.sh`) et la CI
  échoue sur un diff. Deux **nouvelles** migrations (`0015`, `0016`) ; aucune
  migration appliquée n'est modifiée (le commentaire trompeur de `0004` est
  corrigé par un `COMMENT ON COLUMN` dans `0016`, pas par une réécriture). Les
  **7** nouveaux seuils vivent en configuration de zone
  (`80_coursier_parametres.sql`), aucun en dur — et le nombre d'essais du code de
  remise **n'en fait pas partie** : `commande.essais_code_livraison` existe depuis
  le cycle 008 et est réutilisé tel quel (research R5, FR-106).
- [x] **II. Architecture** : le crate `coursier` cesse d'être vide ; il **dépend**
  de `commandes` et `qr`, jamais l'inverse — `commandes` continue d'ignorer
  `coursier` comme il ignore `dispatch`. Aucun champ logistique n'entre dans le
  tronc `commande` : les colonnes ajoutées portent sur la **remise au client**,
  attribut de la commande depuis le cycle 008 (`code_livraison`, `essais_code`,
  `mode_remise`), pas sur la logistique. Aucun crate partagé ne suppose
  « prestataire = vendeur » ni « commande = livraison ». Redis reste éphémère :
  caisse, preuves et appels sont **durables en Postgres**.
- [x] **III. Argent** : toutes les écritures de caisse sont des entiers d'unités
  mineures + devise de zone. Aucun chemin de paiement partiel n'est ouvert — le
  lien de paiement sur place (PAY-03, P1) n'est pas construit. Les prix restent
  ceux figés à la création.
- [x] **IV. Distances** : ce cycle **ne calcule aucune distance de routage** — il
  affiche celles du devis figé (cycle 007). La seule distance qu'il produit est
  une distance de **proximité** (coursier ↔ point de livraison, pour la présence),
  du même type que la porte de scan du cycle 006 : géodésique, arrondie, jamais
  présentée comme un itinéraire.
- [x] **V. Offline & idempotence** : toute action de course porte `uuid_client` +
  horodatage local, passe par la file locale, se rejoue idempotemment, serveur
  faisant foi. Ce cycle **corrige un manque** : la remise et l'échec du cycle 008
  n'avaient aucune clé d'idempotence. Les deux dérogations déclarées au cycle 009
  (position, acceptation d'offre) sont reconduites telles quelles.
- [x] **VI. Événements** : chaque transition écrit son événement outbox dans la
  même transaction ; 7 nouveaux types sont déclarés dans
  `docs/taxonomie-evenements.md` **avant** implémentation.
- [x] **VII. Qualité** : chaque transition nouvelle a son test d'intégration ;
  `cargo sqlx prepare` après les migrations ; toutes les chaînes utilisateur en
  clés i18n fr.
- [x] **VIII. Sécurité** : tout endpoint est gardé par rôle **et** par propriété
  (un coursier ne lit que sa course, sa caisse, ses preuves) ; les surfaces
  d'exploitation sont sous rôle admin. Les photos de preuve suivent la rétention
  paramétrée, purgées par le même patron de job que les photos de récupération.
  Le **numéro du client** entre dans le pré-provisionnement — l'appel doit
  marcher hors ligne — mais n'est jamais journalisé et est effacé du cache local
  à la clôture de la course (research R6).
- [x] **IX. Périmètre** : la feature est la plus directement liée à la fiabilité
  des livraisons de tout le produit. Aucune provision n'est activée. CRS-07 (P1),
  PAY-03 (P1), les écrans ADM et la paie fixe (hors produit) restent dehors.
- [x] **X. Versions** : deux plugins Flutter natifs ajoutés, en dernière version
  stable vérifiée à l'ajout et figées par lockfile ;
  `scripts/verifier-accord-locks.sh` doit rester vert dans les trois paquets.
- [x] **XI. Design** : K3/K4/K5 en widgets Material 3 thémés depuis `mefali_core`
  et `docs/design/tokens.md` ; aucune transposition DOM/CSS ; pas de variante
  Cupertino, constructeurs `.adaptive`.
- [x] **XII. Riverpod codegen** : tous les nouveaux porteurs d'état sont des
  providers générés, injectés par la portée, `retry: pasDeRetry`, durée de vie
  explicite, et **deux moules nommés** — `Notifier` pour la course active et le
  service continu (processus), `AsyncNotifier` pour la caisse et les gains
  (chargements). `.g.dart` commités, jamais édités.

Aucune violation à justifier : **Complexity Tracking reste vide**.

## Project Structure

### Documentation (this feature)

```text
specs/010-coursier-course-active/
├── plan.md              # Ce fichier
├── research.md          # Phase 0 — 17 décisions
├── data-model.md        # Phase 1 — migrations 0015/0016, schéma coursier, drift
├── quickstart.md        # Phase 1 — scénarios de validation
├── contracts/
│   ├── coursier-openapi.md   # surface HTTP (coursier + admin)
│   └── ports-coursier.md     # traits offerts/consommés, événements outbox
├── checklists/requirements.md
└── tasks.md             # Phase 2 (/speckit-tasks — pas créé ici)
```

### Source Code (repository root)

```text
backend/
├── crates/
│   ├── coursier/          # ⭐ CŒUR DU CYCLE — crate vide jusqu'ici
│   │   └── src/{lib,modele,ports,config,course,appels,presence,preuves,
│   │             caisse,indemnisation,depot}.rs
│   ├── commandes/         # étendu : idempotence remise/échec, essais hors ligne,
│   │                      # levée de blocage, dépôt autorisé, port CourseCoursier
│   └── qr/                # `pre_provisionnement` devient une brique consommée
│                          # par `coursier` (l'endpoint déménage)
├── api/
│   ├── src/coursier_http.rs        # ⭐ neuf — course active, appels, présence,
│   │                               #   preuves, caisse, journée
│   ├── src/admin_coursier_http.rs  # ⭐ neuf — exposition, indemnisations,
│   │                               #   blocages, dépôt autorisé
│   ├── src/{course_http,qr_http,lib}.rs        # ajustés
│   └── tests/{bac_coursier/,coursier_*.rs,admin_coursier.rs}
├── migrations/{0015_coursier.sql,0016_commandes_remise_depot.sql}
└── seeds/80_coursier_parametres.sql

apps/
├── mefali_pro/lib/coursier/
│   ├── course/            # K3 refondu : checklist par vendeur, arrêt courant,
│   │                      # bandeau « en route », note vocale, appels
│   ├── remise/            # ⭐ K4 : trois voies, pavé de code, blocage
│   ├── preuves/           # ⭐ K4-1e : les 3 preuves et leur décompte
│   ├── caisse/            # ⭐ K5 : avances, historique, indemnisations
│   ├── disponibilite/     # K1 : bandeau de gains, reste de plafond
│   ├── service_continu/   # ⭐ premier plan : position, offre, sonnerie, présence
│   └── interface_coursier.dart   # navigation basse (Tableau / Courses / Caisse)
└── packages/mefali_core/lib/src/
    ├── offline/           # drift : 4 tables locales de plus, schemaVersion + 1
    └── coursier/          # composants partagés (bandeaux, montants)

clients/dart/              # RÉGÉNÉRÉ (jamais édité)
docs/taxonomie-evenements.md   # 7 événements déclarés AVANT implémentation
```

**Structure Decision**: le cycle est **centré sur un crate jusqu'ici vide**
(`coursier`) plutôt que sur une extension de `commandes`, pour trois raisons : la
caisse et les preuves sont un domaine propre avec son schéma (constitution II) ;
`commandes` est déjà le plus gros crate du dépôt (≈ 6 500 lignes) ; et le port
`PreuvesEchec` a été conçu au cycle 008 **exactement** pour être implémenté
ailleurs. `web/` n'est pas touché (aucun écran admin dans ce cycle) ;
`mefali_client` n'est pas touché (l'app cliente n'est pas modifiée).

## Complexity Tracking

> Aucune violation du Constitution Check — section vide, volontairement.

Deux **points de vigilance** qui ne sont pas des violations mais que
l'implémentation doit garder sous les yeux :

| Point | Pourquoi c'est délicat | Ce qui le tient |
|---|---|---|
| Le service continu ajoute **deux plugins natifs** | Shorebird ne patche que le Dart : toute correction du service passera par le store | Les deux plugins sont ajoutés **en une fois**, tôt dans le cycle, et toute la logique reste en Dart — le natif ne fait que maintenir le processus vivant |
| L'empreinte d'un code à **4 chiffres** est brute-forçable hors ligne | 10 000 hachages suffisent à retrouver le code sans le client | La validation locale n'engage rien : le serveur **revalide** au rejeu, le mode et l'état réseau sont journalisés, et le jeton QR (aléa long) reste inattaquable — risque résiduel assumé et documenté (research R7) |
