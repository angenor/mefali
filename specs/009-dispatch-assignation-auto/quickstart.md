# Quickstart — validation du dispatch automatique (cycle 009)

Guide de validation de bout en bout. Prouve que la feature marche contre les
critères de succès **SC-001..015** de [spec.md](./spec.md). Détails de schéma,
de clés éphémères et de contrat : [data-model.md](./data-model.md),
[contracts/dispatch-openapi.md](./contracts/dispatch-openapi.md),
[contracts/ports-dispatch.md](./contracts/ports-dispatch.md). Aucun code
d'implémentation ici.

## Prérequis

```bash
# Infra dev (Postgres, Redis, Garage/S3, OSRM). Postgres écoute sur 5433 en local.
docker compose -f infra/docker-compose.yml up -d

# Schéma + seeds (migrations 0010, 0011, 0012 + seed 70_dispatch_parametres.sql, idempotent)
cd backend && cargo sqlx migrate run && cargo sqlx prepare
```

| Service | Variable | Requis pour | Absent ⇒ |
|---|---|---|---|
| Postgres | `DATABASE_URL` | migrations, macros sqlx, `#[sqlx::test]` | rien ne tourne — port **5433** en local |
| Redis | `REDIS_URL` | pool GEO, hash d'état, verrous Lua | les tests de pool/verrou **réel** se sautent ; la suite tourne sur `MemoirePool` |
| OSRM | `OSRM_URL` | ETA routière du scoring | proximité en dégradé ×1,4 `degraded=true` — **jamais** de blocage (constitution IV) |

**Aucune dépendance externe ne bloque la suite** : elle n'ouvre aucune socket et
injecte les doubles ci-dessous. Deux familles de tests seulement touchent le vrai
Redis, et se sautent avec un message explicite s'il est injoignable (patron
`backend/api/tests/infra_redis.rs`).

## Doubles de test

| Double | Remplace | Ce qu'il permet |
|---|---|---|
| `MemoirePool` | Redis (pool GEO + hash) | peupler, vider, faire expirer un coursier sans Redis |
| `VerrouMemoire` | Redis (verrous Lua) | jouer la concurrence sans Redis |
| `CoursierFixe` | `comptes` | rôle valide/suspendu, capacités déclarées |
| `NoteAbsente` | **AVI** (non construit) | palier d'entrée pour le plafond, valeur neutre pour le score |
| `AucunePaireBloquee` / `PairesSimulees` | **CRS-07** (P1) | poser une paire bloquée coursier × client ou × vendeur |
| `ProximiteFixe` | OSRM + cache de routage | distances et durées connues d'avance, donc classement assertable au rang près |
| `NotificationsCollectees` | **NTF-01** (non construit) | retenir les annonces émises, pour asserter « la cliente a été prévenue **avec le motif** » et « l'annulation sans frais lui a été offerte » (SC-006, SC-012) |

Le bac `backend/api/tests/bac_dispatch/mod.rs` monte l'app Actix **réelle** (mêmes
handlers, même `Auth`, mêmes gardes de rôle), zone Tiassalé, paramètres du cycle,
et des coursiers avec véhicules déclarés et jetons signés.

⚠ **Piège d'environnement recensé** : le seed n'active que
`transport.actifs = ["a_pied","velo","moto"]`, et `a_pied` plafonne à 800 m dans la
grille tarifaire. Un bac de dispatch déclare des coursiers **`moto`** et des
positions proches, sinon le devis échoue avant le dispatch (« aucune règle
tarifaire applicable », cycle 008).

## Suite backend

```bash
cd backend && cargo test -p dispatch \
  && cargo test -p api --test dispatch_pool        --test dispatch_eligibilite \
                       --test dispatch_scoring     --test dispatch_offre \
                       --test dispatch_concurrence --test dispatch_broadcast \
                       --test dispatch_escalade    --test dispatch_reassignation \
                       --test dispatch_resilience  --test dispatch_transverses
```

### SC-001 et SC-014 — les deux invariants de concurrence

Le cœur du cycle. **Deux tests, pas un**, parce que la garantie ne doit pas être
louée à Redis :

```bash
# A — chemin réel : N tâches tokio appellent POST /courses/offres/{id}/accepter
#     en parallèle sur l'app réelle + vrai Redis.
cargo test -p api --test dispatch_concurrence -- --nocapture
```

Attendu : exactement **un** `200`, N−1 `409 dispatch.erreur.deja_prise`, aucune
pénalité, les perdants restent dans le pool. Puis, **sans Redis du tout** :
`CommandesADispatcher::affecter` appelé deux fois en parallèle → une seule
affectation, la seconde refusée par la table de transitions fermée
(`SELECT etat … FOR UPDATE` + absence de `en_cours → en_cours`).

Pour SC-014 : deux commandes prêtes au même instant, **un seul** coursier
éligible → il reçoit **une** offre, la seconde commande passe à son candidat
suivant. Et en broadcast : deux broadcasts concurrents se **sérialisent**, le
second n'atteint personne.

Vérification manuelle du filet Postgres, indépendante des tests :

```sql
-- Doit toujours rendre 0 ligne : les index UNIQUE partiels le garantissent.
SELECT commande_id, count(*) FROM dispatch.offre WHERE issue = 'en_vol'
  GROUP BY 1 HAVING count(*) > 1;
SELECT coursier_id, count(*) FROM dispatch.offre WHERE issue = 'en_vol'
  GROUP BY 1 HAVING count(*) > 1;
-- Et aucune commande à deux coursiers :
SELECT commande_id, count(DISTINCT coursier_id) FROM commandes.livraison
  WHERE coursier_id IS NOT NULL GROUP BY 1 HAVING count(DISTINCT coursier_id) > 1;
```

### SC-003 et SC-004 — le pool, et sa perte

```bash
cargo test -p api --test dispatch_pool --test dispatch_resilience
```

- **SC-003** : un coursier cesse de publier → à l'expiration du hash il sort du
  pool et **ne reçoit plus aucune offre**. Vérifier aussi le fantôme GEO : le
  membre survit dans le zset, l'élagage le retire, et **il ne reçoit rien entre
  les deux**.
- **SC-004** : `FLUSHDB` en pleine cascade → aucune commande perdue, aucune double
  affectation, le pool se reconstitue à la publication suivante. Contrôle
  manuel après le vidage :

```bash
redis-cli KEYS 'dispatch:*'      # vide
psql -c "SELECT etat, count(*) FROM commandes.commande GROUP BY 1"   # inchangé
```

### SC-005 — le verrou survit toujours au compte à rebours

Test de configuration, pas de comportement : `dispatch.verrou_offre_s` **doit**
être > `dispatch.timer_offre_s`, vérifié au chargement des paramètres. Poser
`verrou = 30` et `timer = 40` en base doit faire **refuser** la configuration, pas
produire un dispatch bancal.

### SC-002, SC-007 et SC-009 — délai, équité, franchise

```bash
cargo test -p api --test dispatch_scoring --test dispatch_offre
```

- **SC-002** : commande créée avec un éligible en ligne → assignée en moins de
  2 min. Mesuré sur l'événement `commande.assignee` (`delai_assignation_s`), pas
  au chronomètre.
- **SC-007** : 20 dispatches, 4 coursiers de profils comparables → **chacun**
  sollicité au moins 3 fois. C'est la composante d'inactivité qui le produit ;
  mettre `dispatch.poids_inactivite` à `0` doit faire **échouer** ce test — c'est
  la preuve que le paramètre agit.
- **SC-009** : les 3 premières non-réponses du jour portent `franche = true`,
  n'altèrent pas le taux d'acceptation et ne déclenchent aucune sanction ; la 4ᵉ
  compte.

### SC-006 — une seule escalade, quel que soit le chemin

```bash
cargo test -p api --test dispatch_escalade
```

Deux commandes escaladées par des chemins différents (file d'attente et cascade
sans preneur) → **exactement une** alerte chacune. Repasser le tic plusieurs fois
ne doit rien ré-émettre :

```sql
SELECT entite_id, count(*) FROM outbox.evenement
 WHERE type_evenement = 'commande.attente_coursier_escaladee'
 GROUP BY 1 HAVING count(*) > 1;      -- doit rendre 0 ligne
```

Puis : une commande escaladée reste assignable, et son annulation est **sans
frais**.

### SC-010 et SC-015 — reprise, et non-reprise

```bash
cargo test -p api --test dispatch_reassignation
```

Quatre cas, dans cet ordre :

1. coursier **immobile** au-delà du délai → repris, incident tracé, re-proposé ;
2. coursier qui **se rapproche** du premier arrêt → **pas** repris (SC-015) ;
3. coursier qui a **cessé de publier** → repris (FR-078) ;
4. coursier avec **un arrêt collecté** → **jamais** de reprise automatique :
   `dispatch.course_bloquee_escaladee`, et seul
   `POST /admin/dispatch/courses/{id}/reprendre` avec motif peut trancher.

Le cas 4 est celui qui protège l'argent de Yao : il doit échouer bruyamment si
quelqu'un relâche la garde.

### SC-012 — bascule prépaiement, sans chemin partiel

```bash
cargo test -p api --test dispatch_eligibilite
```

Un coursier éligible sur **tous** les critères sauf la capacité d'avance → la
commande passe `en_attente_paiement`, `mode_paiement = mobile_money`, la cliente
est notifiée avec le motif. Pool vide pour une **autre** raison → file FIFO, et le
prépaiement **n'est pas** proposé. Aucun montant partiel n'apparaît nulle part.

### SC-008 — aucun paramètre en dur

```bash
cargo test -p api --test dispatch_transverses
```

Pour **chacun des 18 paramètres** : changer sa valeur en base, rejouer le
scénario, constater le changement de comportement **sans redéploiement**. Contrôle
d'inventaire :

```sql
SELECT cle, valeur FROM zones.parametre_zone WHERE cle LIKE 'dispatch.%' ORDER BY cle;
-- 18 lignes attendues (7 au pays, 11 à la ville) — data-model.md §4
```

### SC-011 — aucune coordonnée, aucun numéro dans les événements

```sql
SELECT type_evenement, payload FROM outbox.evenement
 WHERE type_evenement LIKE 'dispatch.%' OR type_evenement LIKE 'coursier.%';
```

Aucun `lat`, `lon`, `latitude`, `longitude`, ni `+225…`. Les distances sont des
entiers en mètres, les montants des entiers en unités mineures avec leur devise.
Un test dédié parcourt tous les événements du module et échoue sur la présence
d'une clé interdite — plus fiable qu'une relecture.

### SC-013 — chaque décision, chaque motif d'écart a son test

```bash
cargo test -p dispatch                       # domaine : scoring, éligibilité, décisions
cargo test -p api --test dispatch_eligibilite
```

Les 8 valeurs de `dispatch.motif_ecart` ont chacune un test, et les **2 nouvelles
transitions** de la table fermée ont le leur, refus symétriques compris
(`en_cours → en_attente_paiement` doit rester **refusé** : on ne remet pas une
course en paiement une fois lancée).

## Suite Flutter

```bash
cd apps/mefali_pro && flutter test && dart analyze     # JAMAIS flutter analyze
cd ../packages/mefali_core && flutter test && dart analyze
```

### Disponibilité (K1, tranche DSP)

Bascule en ligne, plafond du jour, bandeau de reconnexion. À vérifier en test
widget : le **plafond retenu** affiché est bien `min(déclaré, grille)` et Yao voit
**lequel** s'applique ; un nouveau jour **redemande** le plafond.

### Offre (K2)

Compte à rebours, arrêts et distances inter-arrêts, destination approximative avec
la mention « adresse exacte après acceptation », gain détaillé, montant à avancer
avec son plafond, accepter/refuser en un tap, et l'état K2-1b « course attribuée à
un autre coursier — sans pénalité, n sur 3 aujourd'hui ».

Le compte à rebours est un **état local** du widget ; son autorité est
`echeance_le`. Test : reconstruire le widget avec une échéance dépassée doit
afficher K2-1b, **sans** appel réseau supplémentaire.

Piège du cycle 008 à ne pas repayer : la couche d'appel rend le **corps JSON du
contrat**, pas les DTO — les vues se construisent depuis le JSON, et c'est ce
chemin que les tests widget couvrent.

## Validation sur appareil

```bash
# L'API doit être joignable DEPUIS le téléphone : IP LAN, jamais localhost.
flutter run --dart-define=MEFALI_API_URL=http://<ip-lan>:8080
```

Rappels d'environnement déjà payés aux cycles précédents :

- position de l'émulateur sur Tiassalé : `adb emu geo fix -4.8210 5.8960`, sinon
  le coursier part de Mountain View et n'est jamais dans le rayon ;
- `adb shell input text` **ajoute** au champ et **coupe aux espaces** — vider
  avant chaque saisie ;
- purger `otp:sms:*` / `otp:ip:*` dans Redis si l'OTP se bloque (plafond ≈ 50 min) ;
- les horaires du seed couvrent lun–sam : un dimanche, les boutiques sont fermées
  et aucune commande n'est créable — donc rien à dispatcher.

Payés à la validation T071 de ce cycle :

- `adb emu geo fix` avec la **même** position n'émet aucun relevé — il faut
  déplacer le point, sinon le capteur reste muet et le pool paraît vide ;
- une réinstallation par `flutter run` **révoque** les permissions accordées à la
  main par `adb shell pm grant` : la position redevient à demander ;
- `mode_paiement` vaut `cash` (jamais `especes`), et `POST /commandes` exige
  l'en-tête `Idempotency-Key` **et** un repère (`repere_texte`) ;
- allonger `dispatch.timer_offre_s` pour décider à la main **casse la
  configuration** si `dispatch.verrou_offre_s` ne suit pas : le garde-fou du
  domaine refuse, à juste titre, et le tic s'arrête. Déplacer les deux.

**Ce qui ne se voit pas sur appareil, et c'est normal** : aucune sonnerie ne
réveille le téléphone. Le push haute priorité et la sonnerie prolongée
appartiennent à NTF-01 (FR-094) ; ici, l'app **va chercher** son offre toutes les
2 s depuis l'aiguillage coursier, et seulement quand une offre peut arriver — en
ligne, sans course en cours. En arrière-plan, l'app cesse de
publier sa position et le coursier sort du pool par expiration — comportement
**conforme** à DSP-01, et visible par son bandeau de reconnexion.

## Vérification du contrat

```bash
./scripts/generate-clients.sh          # openapi.json → clients/dart + clients/ts
git diff --exit-code clients/          # doit être VIDE (constitution I)
```

`POST /commandes` gagne un effet **interne** (écriture des capacités requises) sans
changer son corps : aucun diff attendu sur ce chemin. Les nouveaux endpoints
`dispatch_http` et `admin_dispatch_http` en produisent, eux — commités avec le
cycle.

## Avant commit

```bash
cd backend && cargo test --workspace && cargo sqlx prepare && cargo clippy --all-targets -- -D warnings
cd ../apps/mefali_pro && flutter test && dart analyze
./scripts/verifier-accord-locks.sh
```

Message conventionnel référençant la story : `feat(dispatch): DSP-04 …`.
