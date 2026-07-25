# Quickstart — validation du moteur de tarification (cycle 007)

Guide de validation de bout en bout. Prouve que la feature marche contre les critères de succès **SC-001..012** de [spec.md](./spec.md). Détails de schéma/contrat : [data-model.md](./data-model.md), [contracts/tarification-openapi.md](./contracts/tarification-openapi.md). Pas de code d'implémentation ici.

## Prérequis

```bash
# Infra dev (Postgres, Redis, OSRM). OSRM : lancer d'abord infra/osrm/prepare.sh.
docker compose -f infra/docker-compose.yml up -d

# Schéma + seeds (migration 0007 + seed 50_tarification_tiassale.sql, idempotent)
cd backend && cargo sqlx migrate run && cargo sqlx prepare
```

### Prérequis d'infrastructure — état vérifié (T002)

| Service | Variable | Requis pour | État local au 2026-07-24 |
|---|---|---|---|
| Postgres | `DATABASE_URL` | migration `0007`, macros sqlx, `#[sqlx::test]` | **présent** — conteneur `mefali-dev-pg`, port **5433** (le 5432 du compose est occupé par un autre projet) |
| Redis | `REDIS_URL` | cache de routage par tronçon (TTL 24 h, R3) | **présent** — `mefali-dev-redis-1:6379` |
| OSRM | `OSRM_URL` | client `/table` en **production** | **absent** — l'extrait OSM n'est pas préparé (`infra/osrm/*.osm.pbf` est gitignoré) |

**OSRM absent ne bloque ni le build, ni les tests, ni une commande.** C'est
exactement le cas prévu par la constitution IV : l'indisponibilité du routage
produit un devis `degraded=true` (vol d'oiseau × facteur de zone) et un
événement `routage.degrade`, jamais un blocage. La suite de tests n'ouvre
d'ailleurs **aucune socket** — elle injecte les doubles ci-dessous. Pour
exercer le vrai client OSRM en local : `infra/osrm/prepare.sh` (télécharge
l'extrait Côte d'Ivoire puis `extract`/`partition`/`customize`), puis
`docker compose -f infra/docker-compose.yml up -d osrm` et
`OSRM_URL=http://localhost:5000`.

## Doubles de test (aucun réseau requis)

- **`RoutageFixe`** — matrice de distances/durées déterministe injectée (géométries de course simulées, R12). Permet de tester l'optimisation d'ordre, le cache et les seeds sans OSRM.
- **`RoutageIndisponible`** — force le repli **vol d'oiseau ×1,4** (`degraded=true`) pour valider le mode dégradé.
- **Course simulée** — `DemandeDevis` fabriquée (retraits + destination + véhicule + articles + instant), sans dépendre des modules CMD/DSP (non construits).

## Suite backend

```bash
cd backend && cargo test -p tarification \
  && cargo test -p api --test tarification_regles --test tarification_publication
```

## Scénarios de validation

### SC-001 — Bornes de marge (garde d'édition et de publication) · US1
1. `PUT …/regles/{id}` avec `marge=110` (bornes zone 25–100).
2. **Attendu** : `409 tarification.erreur.marge_hors_bornes`. La règle n'entre pas dans un brouillon publiable ; la publication d'un brouillon la contenant est refusée.

### SC-002 / SC-003 — Devis routé et non-blocage · US2
1. Évaluer une course à 3 retraits + client avec `RoutageFixe`.
2. **Attendu** : `distance_m`/`eta_s` proviennent de l'**itinéraire à waypoints** (retraits → client, ordre optimisé) ; devis figé, invariant `prix_client = part_coursier + marge` (hors mises à 0). **0 % vol d'oiseau non marqué**.
3. Rejouer avec `RoutageIndisponible`. **Attendu** : `degraded=true`, distance = vol d'oiseau ×1,4, événement `routage.degrade` émis, **aucun blocage** (le devis aboutit).

### SC-004 — Cache de routage 24 h · US2
1. Évaluer deux fois la même course (mêmes points arrondis) avec un `Routage` **compteur d'appels**.
2. **Attendu** : le 2ᵉ passage **ne rappelle pas** le routage (tronçons servis par le cache Redis, TTL 24 h).

### SC-005 — Garde du simulateur avant publication · US3
1. Créer un brouillon, tenter `POST …/publier` **sans** simulation. **Attendu** : `409 simulation_requise`.
2. Introduire une règle hors bornes, simuler, publier. **Attendu** : `409 regle_hors_bornes`.
3. Corriger, `POST …/simuler` (détail complet renvoyé, **aucun** événement outbox), puis `PUT` une règle → la simulation est **réarmée** ; re-simuler puis `publier`. **Attendu** : `200`, grille **en vigueur** à `effet_le`, ancienne passée `historique`, événement `grille.publiee`.

### SC-006 — Seed Tiassalé au FCFA près · US4
1. Simuler/évaluer avec les drapeaux de lancement **OFF** (isoler la grille) :
   - `a_pied`, 600 m → **100** ; `velo`, 1500 m → **150** ; `moto`, 4 km → **300** (200 + 2×50) ; `moto`, 20 km → **500** (plafond) ; drapeau `pluie` ON → **+100**.
2. Basculer les drapeaux de lancement **ON**. **Attendu** : `marge=0`, `prix_client=0`, part coursier **journalisée**.
3. Rejouer le seed. **Attendu** : idempotent (aucune règle dupliquée).

### SC-007 — 100 % de l'effort au coursier · US6
1. Évaluer une course avec effort non nul.
2. **Attendu** : l'effort abonde **uniquement** la part coursier ; la **marge est inchangée** par l'effort ; le reliquat d'arrondi va aussi à la part coursier.

### SC-008 — Marché : 12 articles chez 3 étals voisins · US6
1. `RoutageFixe` : 3 retraits à < 100 m l'un de l'autre, 12 articles.
2. **Attendu** : effort = **2 × 25** (2 arrêts voisins supplémentaires, 1er inclus) **+ 100** (palier 11–20) ; la composante déplacement reste sur les **km réels** de l'itinéraire.

### SC-009 — Optimisation d'ordre ≤ 4 (déterministe) · US6
1. Course à 4 retraits dispersés, matrice connue.
2. **Attendu** : l'ordre retenu est la **meilleure permutation** (distance totale minimale), **déterministe et rejouable** ; l'`Itineraire` est exposable via `OptimisationArrets` (consommable par DSP/CMD).
3. Détour total au-delà de `effort.plafond_eclatement_m` → `proposer_scission=true`.

### SC-010 — Promo : effort journalisé non facturé · US6
1. Drapeau `livraison_offerte_mefali` **ON**, évaluer une course avec effort.
2. **Attendu** : `prix_client = 0`, événement **`effort.calcule`** (`facture=false`) émis, effort **non facturé** ; à la bascule (drapeau OFF), le même effort **est facturé** sans changement de code (paramètre de zone).

### SC-011 — Devise & absence de conversion · US5
1. Lire une règle/un devis de Tiassalé. **Attendu** : montants entiers unités mineures + `XOF`, **sans décimale**.
2. Tenter une opération mêlant deux devises. **Attendu** : **rejetée** (`devise_incoherente`), jamais convertie.

### SC-012 — Invariant du devis · US2
1. Sur un échantillon d'évaluations nominales (hors mises à 0 par drapeau/VND-08).
2. **Attendu** : `prix_client = part_coursier + marge` à 100 %, marge **dans les bornes** de la zone, arrondi au pas de 25.

### Prime d'attente — une seule fois par course (clarification 2026-07-24)
1. Course où l'attente dépasse 15 min à **deux** arrêts.
2. **Attendu** : prime d'attente = **+100** (une seule fois), **pas** 2 × 100.

### VND-08 — mono vs multi-vendeurs · US2
1. `mono_vendeur=true` + `offre_livraison_vendeur` → `prix_client=0` (ou 0 au-delà du seuil), **part coursier inchangée**.
2. `mono_vendeur=false` (panier multi-vendeurs) → VND-08 **ignoré**, frais normaux.

## Porte de sortie

Tous les scénarios verts ; `cargo test` + `cargo sqlx prepare` OK ; `openapi.json` régénéré **sans diff** de clients ; les 3 événements présents dans `docs/taxonomie-evenements.md`. Le simulateur ne laisse **aucune** trace outbox et ne modifie pas la grille en vigueur.

---

## Journal de validation (T033) — 2026-07-24

Déroulé de bout en bout sur Postgres local (port 5433). **Aucune socket** n'est
ouverte : les scénarios injectent les doubles de routage et des géométries de
course simulées, comme prévu ci-dessus. **77 tests TRF verts**, 0 échec.

| Scénario | Prouvé par | Statut |
|---|---|---|
| **SC-001** bornes de marge | `api::tarification_regles::marge_hors_bornes_refusee` (409 + bornes dans le corps, base restée vide, bornes incluses, marge 0 refusée) · `…publication::regle_hors_bornes_bloque_la_publication` | ✓ |
| **SC-002** devis routé | `tarification::evaluation::devis_route_et_invariant` (distance de l'itinéraire, une seule requête de matrice) · `…kilometrage_au_dela_du_seuil_et_plafond` | ✓ |
| **SC-003** non-blocage | `…degrade_aboutit_et_se_journalise` (devis produit, `degraded=true`, ×1,4, `routage.degrade` émis, aucune coordonnée au journal) | ✓ |
| **SC-004** cache 24 h | `…cache_de_routage_evite_le_second_appel` (2ᵉ devis sans appel, identique ; TTL vidé → appel de nouveau) · unitaire `routage::cache_evite_le_second_appel` · `api::infra_redis::cache_routage_aller_retour_et_ordre` (impl RÉELLE) | ✓ |
| **SC-005** garde du simulateur | `api::tarification_publication` — 7 tests : sans simulation, édition ET suppression qui réarment, bornes resserrées, archivage + `grille.publiee`, republication refusée, brouillon vide, 401/403, simulateur sans trace | ✓ |
| **SC-006** seed Tiassalé au FCFA près | `tarification::seed_tiassale::montants_tiassale_au_fcfa_pres` (100 / 150 / 300 / 500 plafond / +100 pluie) · `…drapeaux_de_lancement_du_seed` · `…seed_idempotent` | ✓ |
| **SC-007** 100 % effort au coursier | `tarification::effort::effort_integralement_au_coursier` (marge strictement inchangée) | ✓ |
| **SC-008** marché 12 articles / 3 étals | `…effort::marche_douze_articles_trois_etals_voisins` (2 × 25 + 100 = 150, km réels intacts) | ✓ |
| **SC-009** ordre ≤ 4 déterministe | `…evaluation::ordre_optimise_expose_et_deterministe` (meilleure permutation, rejouable, exposée par `OptimisationArrets`) · `…effort::ordre_optimise_nourrit_l_effort` · `…plafond_d_eclatement_propose_la_scission` | ✓ |
| **SC-010** promo : effort non facturé | `…effort::promo_effort_journalise_non_facture` (`effort.calcule` `facture=false`, puis bascule par simple drapeau) | ✓ |
| **SC-011** devise sans conversion | `tarification::devise` — 5 tests (XOF sans décimale, règle EUR refusée, mélange rejeté, zone sans devise) | ✓ |
| **SC-012** invariant du devis | `…devis_route_et_invariant`, `…kilometrage_au_dela_du_seuil_et_plafond`, `…drapeaux_de_lancement` (et `Devis::invariant_verifie()` rend `None` — non applicable — sur un prix forcé à 0) | ✓ |
| **Prime d'attente une fois/course** | `…effort::prime_attente_une_fois_par_course` (2 arrêts lents → +100, pas 2 × 100) | ✓ |
| **VND-08 mono vs multi** | `…evaluation::vnd08_mono_vendeur_seulement` (mono → 0 et part coursier intacte ; multi → ignoré ; seuil sous/au seuil) | ✓ |

### Porte de sortie

- `cargo test` : **59 suites vertes, 0 échec** (dont 77 tests TRF).
- `cargo sqlx prepare --workspace` : vert, cache `.sqlx` commité.
- `openapi.json` + clients Dart/TS régénérés — génération vérifiée **déterministe**
  sur les fichiers versionnés (l'écart observé au premier contrôle venait du cache
  `.dart_tool`, ignoré par git).
- Les **3 événements** sont déclarés dans `docs/taxonomie-evenements.md` et émis
  (ou volontairement tus) conformément au registre.
- Le simulateur ne laisse **aucune** trace outbox et ne modifie pas la grille en
  vigueur (`simulateur_detaille_et_sans_effet_de_bord`).

### Non exercé en réel

**Le client OSRM `/table`** n'a pas été exercé contre un vrai serveur : l'extrait
OSM n'est pas préparé sur ce poste (voir « Prérequis d'infrastructure » plus
haut). Ce qui EST couvert : la construction de l'URL en `lon,lat` (test
unitaire), le décodage de la matrice, et surtout le comportement quand OSRM
manque — le mode dégradé, qui est précisément le chemin emprunté ici de bout en
bout. Reste à faire au premier déploiement disposant d'OSRM : rejouer SC-002
avec `RoutageOsrm` pour confirmer qu'une matrice réelle se décode et se cache.
