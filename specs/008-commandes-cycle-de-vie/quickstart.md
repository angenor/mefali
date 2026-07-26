# Quickstart — validation du cycle de vie d'une commande (cycle 008)

Guide de validation de bout en bout. Prouve que la feature marche contre les critères de succès **SC-001..011** de [spec.md](./spec.md), dont le déroulé **ligne par ligne** de l'arbre §7.5. Détails de schéma et de contrat : [data-model.md](./data-model.md), [contracts/commandes-openapi.md](./contracts/commandes-openapi.md). Aucun code d'implémentation ici.

## Prérequis

```bash
# Infra dev (Postgres, Redis, Garage/S3, OSRM). Postgres écoute sur 5433 en local.
docker compose -f infra/docker-compose.yml up -d

# Schéma + seeds (migrations 0008 et 0009 + seed 60_commandes_parametres.sql, idempotent)
cd backend && cargo sqlx migrate run && cargo sqlx prepare
```

| Service | Variable | Requis pour | Note |
|---|---|---|---|
| Postgres | `DATABASE_URL` | migrations, macros sqlx, `#[sqlx::test]` | port **5433** en local (5432 occupé par un autre projet) |
| Redis | `REDIS_URL` | position coursier éphémère (suivi) | absent ⇒ le suivi renvoie `position: null`, **jamais** une erreur |
| Garage (S3) | `S3_ENDPOINT` | photos de substitution, repères vocaux | sur appareil, l'URL doit être joignable **depuis le téléphone** (IP LAN, pas `localhost`) |
| OSRM | `OSRM_URL` | devis routé réel | absent ⇒ devis `degraded=true` (cycle 007), la commande **n'est jamais bloquée** |

**Aucune dépendance externe ne bloque la suite de tests** : elle n'ouvre aucune socket et injecte les doubles ci-dessous.

## Doubles de test

| Double | Remplace | Ce qu'il permet |
|---|---|---|
| `AffectationSimulee` | **DSP** (non construit) | assigner un coursier, réassigner, vider le pool pour forcer la file d'attente |
| `PaiementSimule` | **PAY** (non construit) | confirmer un prépaiement, le faire expirer |
| `PreuvesFixes` | **CRS-05** (non construit) | preuves d'échec réunies ou non |
| `PositionFixe` | **DSP-01** (non construit) | position datée, ou absence de position |
| `ArretsFixes` | *(existant, cycle 006)* | arrêt à collecter d'un coursier chez un prestataire |

## Suite backend

```bash
cd backend && cargo test -p commandes \
  && cargo test -p api --test commandes_panier   --test commandes_adresse \
                       --test commandes_creation --test commandes_etats \
                       --test commandes_file     --test commandes_suivi \
                       --test commandes_substitution \
                       --test commandes_annulation --test commandes_echecs
```

`cargo test -p commandes` couvre les tests du crate : `collecte.rs` (cycle 006, **non-régression du gating**) et `tronc.rs` (commande sans livraison).

### SC-002 — toutes les transitions couvertes

Un test par ligne des trois tables de transitions ([data-model §3](./data-model.md)), plus le **refus** de chaque transition illégale.

```text
✓ nouvelle → en_cours (assignation)            ✗ en_cours → nouvelle          (409)
✓ nouvelle → en_attente_coursier               ✗ terminee → annulee           (409)
✓ a_collecter → en_route → arrive → collecte   ✗ arrive → livree              (409)
✓ toutes collectes résolues → en_livraison     ✗ en_livraison avant la 3ᵉ     (409)
```

**Non-régression critique (R4)** : le test du cycle 006 (`tests/collecte.rs`) est **conservé**, et un cas est ajouté — une livraison **avec arrêt de remise** doit basculer `en_livraison` quand ses **collectes** sont résolues. Sans la correction du gating, ce test échoue et la commande reste bloquée pour toujours.

### SC-003 — l'arbre §7.5, ligne par ligne

Un test d'intégration **par ligne** du tableau du cadrage. Chacun assert l'issue, **le détenteur de l'argent**, **le détenteur de la marchandise**, et les événements émis.

Le tableau §7.5 compte **10 lignes** ; le cas 2 ci-dessous (**refus de reprise du vendeur**) en est la sous-branche que CMD-08 nomme explicitement (« refus de reprise → litige + indemnisation coursier ») et qui porte une issue distincte — d'où **11 tests pour 10 lignes**.

| # | Cas §7.5 | Issue attendue | Argent | Marchandise |
|---|---|---|---|---|
| 1 | Client refuse / injoignable, **non périssable** | retour aux vendeurs, remboursements **par arrêt** | `vendeur` | `vendeur` |
| 2 | Vendeur **refuse la reprise** | `litige.ouvert` + `indemnisation.due` | `mefali` | `coursier` |
| 3 | **Périssable** | litige + indemnisation + **sanction client** | `mefali` | `coursier` |
| 4 | Client **conteste le montant** | refus traité comme cas 1 ou 3, **aucune négociation** | selon nature | selon nature |
| 5 | Client **sans appoint** | mobile money de la **totalité**, sinon refus | selon issue | selon issue |
| 6 | **Faux billet** | fonds d'incidents, `indemnisation.due` | `mefali` | `client` |
| 7 | **Non-conformité** | reprise vendeur, la photo de collecte départage | `vendeur` | `vendeur` |
| 8 | **Casse en transport** | franchise coursier plafonnée + fonds | `mefali` | `coursier` |
| 9 | **Annulation après achat** | mêmes règles que le refus | selon nature | selon nature |
| 10 | Client injoignable **et vendeur fermé** | **consigne** + re-livraison facturée (commande liée) | `mefali` | `consigne` |
| 11 | **Suspicion de faux refus** | indemnisation **conditionnée aux preuves** | selon preuves | `coursier` |

```bash
cargo test -p api --test commandes_echecs   # 11 tests couvrant les 10 lignes du §7.5
```

Vérifier aussi le **refus sans preuves** : `POST /courses/{livraison}/echec` répond `409 preuves_incompletes` tant que `PreuvesFixes` renvoie faux.

### SC-005 et SC-007 — l'argent

```bash
cargo test -p api --test commandes_creation -- --nocapture
```

- **SC-005** : aucun endpoint n'accepte un montant partiel — la garde est structurelle (un seul `total_unites`, aucun paramètre de fraction). Le test tente un règlement partiel et vérifie qu'aucune surface ne l'expose.
- **SC-007** : après un retrait et une substitution acceptée, `total_unites` recalculé = articles révisés + **frais figés inchangés**. Assertion explicite : `devis_prix_client` et `devis_part_coursier` sont **identiques** avant et après (décision de spec, FR-050).

### SC-006 — la scission

Panier mêlant restauration et courses → `POST /paniers/devis` renvoie `scission.cause = "categorie_non_mixable"` et la prévisualisation des deux commandes. Vérifier qu'**aucune** commande n'est créée sans une seconde requête explicite du client (FR-010), et que l'événement `panier.scission_proposee` est émis pour la métrique.

Rejouer avec un panier dispersé dépassant le plafond d'éclatement de la zone → même bloc, `cause = "plafond_eclatement"`.

### SC-010 — idempotence

```bash
# Même Idempotency-Key envoyée deux fois → une seule commande, réponses identiques
curl -X POST … -H 'Idempotency-Key: 0199…' -d @panier.json    # 201
curl -X POST … -H 'Idempotency-Key: 0199…' -d @panier.json    # 200, corps identique
```

Idem pour chaque transition d'arrêt et chaque décision de substitution (`uuid_client` rejoué → aucun doublon, aucun second événement).

## Suite Flutter

```bash
cd apps/mefali_client && flutter test
cd ../packages/mefali_core && flutter test && dart analyze     # JAMAIS flutter analyze
```

### SC-001 — commander en moins de 3 minutes

Sur émulateur ou appareil :

```bash
flutter run --dart-define=MEFALI_API_URL=http://<ip-lan-du-poste>:8080 \
            --dart-define=MEFALI_DEV_OTP=true
```

1. Se connecter (OTP lisible sur l'écran en mode dev).
2. Composer un panier de **12 articles chez 3 vendeurs** — vérifier le regroupement par vendeur, les sous-totaux, et le récapitulatif « Articles / Livraison / Effort de préparation » **avant** de confirmer (maquette C3-3a).
3. Adresse : « Utiliser ma position actuelle », puis repère **vocal** — vérifier le compteur `0:12 / 0:30 max` et le refus au-delà de la durée de zone.
4. Paiement cash : vérifier l'**appoint exact** affiché ; porter le total au-dessus du plafond et vérifier que le cash est grisé **avec sa raison** (C3-3b).
5. Confirmer : le **code à 4 chiffres et le QR** apparaissent immédiatement.

### SC-004 et SC-009 — le suivi, avec et sans réseau

1. Suivre la commande : stepper en langage clair, « 2 collectes sur 3 », position **avec son âge** (C4-4a).
2. **Couper le réseau de l'appareil** (mode avion) et rouvrir le suivi : le bloc « À la livraison — disponible sans réseau » affiche le QR et le code, l'écran annonce le **dernier état connu** et l'**âge** de la position (C4-4d). Aucun appel réseau n'est émis sur ce chemin.
3. Rétablir le réseau : la file d'actions se draine, l'état se resynchronise sans doublon.

### SC-011 — bout en bout

Dérouler par API (l'app coursier n'existe pas) pendant que l'app cliente est ouverte sur le suivi :

```text
création → affectation (AffectationSimulee) → 3 collectes (scan QR, cycle 006)
        → bascule en_livraison → remise contre code → terminee
```

Vérifier à la fin : `commande.terminee` émis, `total_encaisse = total_unites`, et — assertion structurelle — **aucune colonne logistique sur le tronc** (le devis, le coursier et les états de collecte vivent sur `livraison`/`segment`/`arret`).

## Vérification du contrat

```bash
./scripts/generate-clients.sh    # openapi.json (utoipa) → clients Dart + TS, déterministe
git diff --exit-code clients/    # échoue si un client a été édité à la main (CI : job contrat-clients)
```

Prérequis du script : Java ≥ 11 (openapi-generator pour Dart), Flutter/Dart (`build_runner`), Node + npx.

## Avant commit

```bash
cd backend && cargo test && cargo sqlx prepare
cd ../apps/packages/mefali_core && dart analyze
git status --short   # aucun .sqlx ni client généré non commité
```
