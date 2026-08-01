# Implementation Plan: Paiements — chaîne cash tracée par arrêt et prépaiement mobile money via agrégateur

**Branch**: `011-paiements-cash-prepaiement` | **Date**: 2026-08-01 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/011-paiements-cash-prepaiement/spec.md`

## Summary

Ce cycle rend l'argent **vrai**. Jusqu'ici, une commande au-dessus du plafond cash
naissait en `EN_ATTENTE_PAIEMENT` et n'en sortait que par une confirmation
**simulée** ; une commande prépayée laissait une avance non soldée dans la caisse
du coursier ; la retenue de la livraison offerte n'avait aucune configuration pour
se déclencher ; et l'app coursier réclamait au client d'une commande prépayée un
montant qu'il avait déjà réglé.

L'approche technique tient en six mouvements :

1. **Un crate `paiements` réel**, dépendant du seul `commandes`, avec le trait
   `PaymentProvider { create_checkout, verify_webhook, refund, consulter }` et
   trois implémentations dont **aucune n'est l'agrégateur retenu** — le choix
   reste ouvert (cadrage §10.7) et sa réversibilité est **mesurée** par un second
   double au vocabulaire différent (SC-010).
2. **La session de prépaiement** ouverte par un endpoint dédié après la création
   (jamais dans sa transaction), avec échéance **persistée**, notification signée
   idempotente par contrainte de base, et réconciliation auprès du fournisseur
   **avant** toute annulation.
3. **La retenue de la livraison offerte** lue depuis le devis déjà figé,
   appliquée au scan, écrêtée à zéro — plus la part minimale de VND-08 (la
   déclaration `{jamais, toujours, au_delà}`) sans laquelle le critère PAY-01 ne
   serait jamais exerçable.
4. **Trois soldes** : un livre de trésorerie qui gagne `frais_encaisses`,
   `reglement`, `reversement` ; et une table `coursier.creance` pour ce que Mefali
   doit — parce qu'une créance n'est pas de l'argent en poche et que l'inscrire au
   livre ferait mentir l'écran dont c'est la seule raison d'être.
5. **Les anomalies visibles** : `paiements.dossier`, alimenté par le webhook et
   par un consommateur outbox — un montant divergent, un paiement hors délai, une
   retenue écrêtée ou un remboursement client dû ne disparaissent jamais en
   silence.
6. **Deux trous du code livré comblés** : `etat_paiement = 'en_attente'` jamais
   posé (migration 0008), et `montant_a_encaisser = total_unites` même sur une
   commande prépayée (`suivi.rs:555`, `collecte.rs:767`).

Décisions détaillées : [research.md](./research.md). Schéma :
[data-model.md](./data-model.md). Contrats : [contracts/](./contracts/).
Validation : [quickstart.md](./quickstart.md).

## Technical Context

**Language/Version**: Rust 1.97 (workspace `backend/`), Dart/Flutter (apps),
TypeScript (client généré). Versions figées par lockfile (constitution X).

**Primary Dependencies**: Actix Web 4.14, sqlx 0.9 (Postgres, macros vérifiées à
la compilation), utoipa 5.5 + utoipa-actix-web 0.1 + utoipa-swagger-ui 9.0,
tokio 1.52, uuid v7, chrono. **Nouvelles pour ce cycle** : `reqwest` (client HTTP
sortant vers l'agrégateur, TLS rustls pour rester aligné sur sqlx), `hmac` +
`sha2` (vérification de signature), `subtle` (comparaison en temps constant).
Côté Flutter : `url_launcher 6.3.2` ajouté à `mefali_client` — **plugin natif**,
donc passage par le store, Shorebird ne le patche pas (research R17).

**Storage**: PostgreSQL — seule vérité durable. Schéma neuf `paiements` ;
extensions de `coursier`, `commandes` et `prestataires`. Redis **non employé** par
ce cycle : l'idempotence de l'argent ne peut pas reposer sur un cache éphémère
(research R5). Aucun objet S3.

**Testing**: `cargo test` (unitaires de domaine pur + intégration sur base réelle),
tests d'API dans `backend/api/tests/`, `flutter test` dans les deux apps.
`cargo sqlx prepare` après tout changement SQL. Une suite de contrat rejouée avec
un **second** fournisseur (SC-010).

**Target Platform**: Linux (VPS unique, docker-compose), Android d'entrée de gamme
(clients et coursiers), iOS non vérifié (Xcode/CocoaPods à installer).

**Project Type**: monorepo — service web Rust + deux apps Flutter + Nuxt 4
(inchangé ce cycle) + clients générés.

**Performance Goals**: ouverture de session < 10 s bout en bout (SC-001) ;
traitement d'une notification < 500 ms ; balayage d'expiration toutes les 10 s,
annulation effective < 1 min après l'échéance (SC-005).

**Constraints**: aucun flottant pour l'argent ; aucun chemin de paiement partiel ;
webhook idempotent par **contrainte de base**, pas par convention ; aucun secret
de fournisseur en clair dans un log, un événement ou une réponse ; migrations
`0001..0019` intouchées.

**Scale/Scope**: Tiassalé — quelques dizaines de commandes/jour au lancement,
4 coursiers. Le dimensionnement n'est pas le sujet : l'**exactitude** l'est.
Deux migrations, 4 tables/colonnes neuves, 13 endpoints (dont 1 non authentifié),
9 événements neufs + 3 amendés, 4 paramètres de zone.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Portes dérivées de `.specify/memory/constitution.md` (v1.1.0) :

- [x] **I. Sources de vérité** : aucun client `clients/dart`/`clients/ts` édité à
  la main (régénérés par `./scripts/generate-clients.sh`) ; deux **nouvelles**
  migrations `0020`/`0021`, `0001..0019` intouchées ; les quatre paramètres
  métier (durée de session, fenêtre de réconciliation, seuil d'alerte de
  créances, garde-fou de moyens) sont en configuration de zone héritée, aucun en
  dur (research R18).
- [x] **II. Architecture** : le crate `paiements` existait déjà **vide** dans le
  workspace (provision du cycle 001) — aucun membre nouveau, une provision qui
  devient réelle. Dépendance unique `paiements ──▶ commandes` ; ce qu'il ne peut
  pas atteindre (la caisse) passe par l'**outbox**, comme `coursier` le fait
  déjà. **Aucun champ logistique ajouté au tronc `commande`** : la transaction
  vit dans son propre schéma et pointe la commande. La créance vit dans
  `coursier`, parce qu'elle est de la caisse. Redis non employé ; Postgres seule
  vérité durable.
- [x] **III. Argent** : tous les montants sont `bigint` en unités mineures + code
  ISO 4217 de la zone ; aucun flottant, y compris dans les échanges avec le
  fournisseur (`DemandeCheckout.montant_unites: i64`). Prix verrouillés — les
  reçus lisent, ne recalculent pas. **Aucun chemin partiel** : une transaction
  couvre la totalité, l'enum d'état ne contient aucune valeur « partiellement
  payée », et une notification au montant divergent ne vaut pas confirmation.
- [x] **IV. Distances** : ce cycle ne calcule aucune distance. La retenue est lue
  depuis un devis déjà figé par OSRM au cycle 007.
- [x] **V. Offline & idempotence** : aucune nouvelle action coursier n'est
  introduite ; celles qui existent conservent leur UUID client. L'idempotence
  ajoutée porte sur le **webhook** (contrainte unique sur
  `fournisseur + référence + empreinte de charge`) et sur la **créance**
  (`evenement_id UNIQUE`), y compris au rejeu d'une fin de course hors ligne.
- [x] **VI. Événements** : chaque transition écrit son événement outbox dans la
  même transaction SQL ; 9 événements neufs et 3 amendés seront déclarés dans
  `docs/taxonomie-evenements.md` **avant** implémentation (tâche de tête de
  cycle). Les six indicateurs de pilotage dérivent tous du journal.
- [x] **VII. Qualité** : chaque transition des deux machines à états
  (transaction, créance) a son test d'intégration, chemins d'échec compris ;
  `cargo sqlx prepare` après `0020`/`0021` ; toutes les chaînes utilisateur en
  clés i18n fr, y compris les motifs de dossier et les refus de paiement.
- [x] **VIII. Sécurité** : chaque endpoint est protégé par rôle **sauf le
  webhook**, seule surface non authentifiée du cycle — voir Complexity Tracking,
  ligne 1. Rétention : `notification_recue` 12 mois, `acces_paiement` effacé dès
  l'issue, aucune donnée de carte ni de compte mobile money reçue ou stockée.
- [x] **IX. Périmètre** : PAY-01/02/05 sont **P0** ; la feature débloque les
  commandes au-dessus du plafond cash, aujourd'hui impossibles — impact direct
  sur les commandes/jour. PAY-03, PAY-04, PAY-06 et le routage par moyen ne sont
  pas construits. Le débordement sur VND-08 est **borné et justifié** — voir
  Complexity Tracking, ligne 2.
- [x] **X. Versions** : `reqwest`, `hmac`, `sha2`, `subtle`, `url_launcher` en
  dernière version stable au jour du cycle, figées par lockfile ;
  `./scripts/verifier-accord-locks.sh` doit rester vert dans les trois paquets
  Flutter.
- [x] **XI. Design** : les écrans touchés sont construits en Material 3 thémé par
  `mefali_core` depuis `docs/design/tokens.md` ; aucune structure DOM/CSS des
  exports HTML n'est transposée. **Aucune maquette de paiement n'existe** —
  voir Complexity Tracking, ligne 3.
- [x] **XII. État Flutter** : tout porteur d'état est un provider **généré** par
  annotation (`.g.dart` commité, jamais édité) ; injection par la portée ;
  `retry: pasDeRetry` sur toute portée ; durée de vie explicite ; deux moules —
  `Notifier<EtatSessionPaiement>` pour le compte à rebours (état local, pas de
  chargement), `AsyncNotifier` pour les listes (créances, registre). Analyse par
  `dart analyze`, jamais `flutter analyze`.

## Project Structure

### Documentation (this feature)

```text
specs/011-paiements-cash-prepaiement/
├── plan.md              # Ce fichier
├── research.md          # Phase 0 — 22 décisions closes
├── data-model.md        # Phase 1 — migrations 0020/0021, états, table de vérité SC-006
├── quickstart.md        # Phase 1 — validation exécutable
├── contracts/
│   ├── paiements-openapi.md   # 13 endpoints, dont le webhook non authentifié
│   └── ports-paiements.md     # PaymentProvider, ports, outbox, événements
├── checklists/
│   └── requirements.md  # 16/16 verts
└── tasks.md             # Phase 2 — produit par /speckit-tasks, PAS par ce plan
```

### Source Code (repository root)

```text
backend/
├── crates/
│   ├── paiements/            # ★ DEVIENT RÉEL — schéma SQL `paiements`
│   │   ├── src/
│   │   │   ├── fournisseur/  #   trait PaymentProvider + AgregateurHttp + FournisseurSimule
│   │   │   ├── session.rs    #   ouverture idempotente, état, temps restant
│   │   │   ├── webhook.rs    #   signature → idempotence → confirmation
│   │   │   ├── expiration.rs #   réconciliation puis annulation
│   │   │   ├── dossier.rs    #   anomalies d'argent
│   │   │   ├── registre.rs   #   lectures d'exploitation
│   │   │   └── depot.rs      #   PgPaiements
│   │   └── tests/            #   + fournisseur_alternatif.rs (SC-010)
│   ├── commandes/            # ajusté : port CommandesAPayer, retenue au scan,
│   │                         #   montant à encaisser = 0 si prépayé, offre lue au devis
│   ├── coursier/             # ajusté : creance, frais_encaisses, 3 positions
│   └── prestataires/         # ajusté : offre_livraison (VND-08 minimal)
├── api/
│   ├── src/
│   │   ├── paiements_http.rs         # ★ client : session, état, reçu
│   │   ├── paiements_webhook_http.rs # ★ fournisseur : NON authentifié
│   │   ├── admin_paiements_http.rs   # ★ registre, dossiers, créances
│   │   ├── vendeur_http.rs           # ajusté : offre-livraison, reçu vendeur
│   │   ├── coursier_http.rs          # ajusté : caisse à 3 positions
│   │   ├── commandes_http.rs         # ajusté : le suivi porte l'état de paiement
│   │   └── lib.rs                    # câblage : provider, PaiementsOutbox, job d'expiration
│   └── tests/                        # parcours de bout en bout
├── migrations/
│   ├── 0020_paiements_enums.sql      # ★ schéma + enums + ALTER TYPE
│   └── 0021_paiements_tables.sql     # ★ tables, colonnes, index, contraintes
└── seeds/
    └── 90_paiements_parametres.sql   # ★ 4 paramètres de zone

apps/
├── mefali_client/            # écran de paiement (compte à rebours, ouverture,
│                             #   reprise), suivi enrichi, reçu ; + url_launcher
├── mefali_pro/               # coursier : montant net de retenue, « rien à
│                             #   encaisser », caisse à 3 positions et créances
│                             # vendeur : réglage d'offre de livraison, reçu
└── packages/mefali_core/     # composant de compte à rebours, formatage des
                              #   ventilations de montants

clients/
├── dart/                     # RÉGÉNÉRÉ — jamais édité
└── ts/                       # RÉGÉNÉRÉ — jamais édité

docs/taxonomie-evenements.md  # 9 événements neufs + 3 amendés, déclarés AVANT le code
```

**Structure Decision**. Le crate `paiements` existait déjà comme provision vide du
cycle 001 : il n'y a pas de nouveau membre de workspace, seulement une provision
qui devient réelle — exactement le mouvement que le cycle 010 a fait pour
`coursier`. Les trois crates ajustés le sont chacun **sur leur propre schéma** :
`commandes` pour la retenue et le montant à encaisser, `coursier` pour la créance
et les positions, `prestataires` pour l'offre de livraison. Aucun crate n'écrit
dans le schéma d'un autre. `web/` et `infra/` ne sont pas touchés : aucune page
`/admin/**` (ADM-01→06 sont des stories distinctes), aucun service
d'infrastructure nouveau.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| **VIII — un endpoint sans garde de rôle** : `POST /paiements/notifications/{fournisseur}` | Un agrégateur ne porte pas de JWT : la notification vient d'un tiers, pas d'un utilisateur. Sa garde est **cryptographique** — signature HMAC vérifiée sur le corps brut avant toute désérialisation, corps plafonné à 64 Kio, débit limité par IP (patron OTP du cycle 003), tentatives refusées journalisées, exclu de Swagger UI en production. | Un jeton statique en en-tête ne prouve pas l'intégrité du contenu et fuite dans les journaux du tiers ; une allow-list d'IP seule ne prouve rien non plus, et les agrégateurs changent d'IP sans préavis. Les deux seraient **plus faibles** qu'une signature, pas plus simples. |
| **IX — débordement borné sur VND-08 (P1)** : la déclaration `{jamais, toujours, au_delà}` par vendeur | PAY-01 exige que l'avance vaille « montant − frais si livraison offerte ». Sans configuration, la retenue ne se déclencherait **jamais** en production : un critère P0 serait livré non vérifiable, et le cycle VND-08 devrait revalider toute la chaîne d'argent. Clarification Q1, tranchée par le porteur du produit. | Poser le mécanisme inerte (option B) : le critère PAY-01 resterait une affirmation invérifiable. Le reporter entièrement (option C) : PAY-01 livré amputé. Le débordement est **borné à deux colonnes et deux endpoints** — badge client, merchandising et tri restent à VND-08 (FR-049, FR-114). |
| **XI — écrans sans maquette de référence** | `docs/design/png/` ne contient aucune planche de paiement : C3 (panier) et C4 (suivi) s'arrêtent avant l'encaissement, K3/K4/K5 ne montrent ni retenue ni créance. Les écrans neufs sont composés à partir des **composants canoniques** de `mefali_core` et des tokens, en réutilisant les motifs des planches voisines (bandeau d'état de C4, ventilation de montants de K5). | Inventer une planche : le design est source de vérité, pas un livrable de cycle d'implémentation. Attendre une maquette : bloquerait un P0 sur un artefact que rien ne planifie. L'écart est **assumé et documenté**, comme le cycle 010 l'a fait pour l'état 1c de K1. |

## Post-Design Constitution Re-Check

Réévalué après Phase 1 — **aucune porte ne bascule au rouge**. Trois points
méritaient d'être revérifiés une fois le schéma posé :

- **II (architecture)** : la conception a fait apparaître une tentation — loger
  la créance dans `paiements`. Le data-model la refuse (research R12) : la créance
  est de la caisse, elle vit dans `coursier`, et `paiements` ne la connaît pas.
  Le graphe reste acyclique.
- **III (argent)** : la table de vérité de [data-model §5](./data-model.md) a été
  écrite **pour** vérifier cette porte, état par état — et elle a servi. La
  première formule retenue pour l'écriture `frais_encaisses`
  (`= devis_prix_client`) s'est révélée **fausse** dans le cas de la retenue
  VND-08, où le prix client vaut 0 alors que le coursier a bien encaissé sa part.
  Corrigée en `total_du_client − Σ avances` (research R13), elle fait converger
  les **quatre** chemins de livraison sur le même gain. Trouvé en Phase 1, avant
  la première ligne de code : c'est exactement ce à quoi cette porte sert.
- **V (idempotence)** : la contrainte
  `UNIQUE (fournisseur, reference_fournisseur, empreinte_charge)` inclut
  l'empreinte de la charge parce qu'un fournisseur peut légitimement renvoyer la
  même référence avec un contenu différent (`en_cours` → `réussi`). Sans elle, la
  seconde notification — celle qui porte le succès — serait avalée comme un
  doublon. Ce détail n'était pas visible en Phase 0.
