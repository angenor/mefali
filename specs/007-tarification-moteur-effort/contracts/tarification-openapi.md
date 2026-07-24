# Contrat — tarification (Phase 1)

Endpoints **admin** (annotations `#[utoipa::path]`, auto-collectés par `utoipa-actix-web`), DTO `ToSchema`, gardes de rôle, codes d'erreur i18n, événements, et les **traits internes** exposés à CMD/DSP (pas d'HTTP). Montants = entiers unités mineures + devise ISO 4217. Toute chaîne utilisateur = clé i18n fr.

## 1. Endpoints admin (`admin_tarification_http.rs`, `Role::Admin`)

Tous protégés par l'extracteur `Auth` + `auth.exiger_role(comptes::Role::Admin)?` et **journalisés** (qui, quand — patron 002/003/005). Préfixe `/admin/tarification`.

| Méthode | Chemin | Rôle | Objet |
|---|---|---|---|
| `GET`  | `/admin/tarification/zones/{zone_id}/grille` | Admin | Grille **en vigueur** + **brouillon** de la zone (avec statut de simulation, règles) |
| `POST` | `/admin/tarification/zones/{zone_id}/brouillon` | Admin | Créer/obtenir le brouillon de la zone (clone de la grille en vigueur si absent) |
| `PUT`  | `/admin/tarification/brouillon/{grille_id}/regles/{regle_id}` | Admin | Créer/mettre à jour une règle (garde de borne de marge ; **réarme la simulation**) |
| `DELETE` | `/admin/tarification/brouillon/{grille_id}/regles/{regle_id}` | Admin | Supprimer une règle du brouillon (réarme la simulation) |
| `POST` | `/admin/tarification/brouillon/{grille_id}/simuler` | Admin | **Simuler** sur une course (dry run, sans effet de bord) → détail complet |
| `POST` | `/admin/tarification/brouillon/{grille_id}/publier` | Admin | **Publier** (gardé : simulé sur empreinte courante ∧ aucune règle hors bornes) |

### 1.1 Écriture de règle — `PUT …/regles/{regle_id}`

Corps `RegleUpsert` (`ToSchema`) :

```jsonc
{
  "transport_slug": "moto",
  "categorie_slug": null,                 // optionnel
  "distance_min_m": 0, "distance_max_m": null,
  "plage_debut_min": null, "plage_fin_min": null, "jours_masque": null,
  "part_coursier_base": 150, "marge": 50, // unités mineures ; marge ∈ [min,max] de zone
  "prix_par_km": 50, "seuil_km_m": 2000, "prix_plafond": 500,
  "devise": "XOF",                        // = devise de la zone
  "priorite": 0, "actif": true
}
```

Réponses : `200` règle enregistrée ; `409 marge_hors_bornes` (clé i18n `tarification.erreur.marge_hors_bornes`, avec `min`/`max`) ; `409 devise_incoherente` ; `422` corps invalide ; `403`/`401` rôle.

### 1.2 Simulation — `POST …/simuler`

Corps `DemandeSimulation` (**pas de coursier** — R11) :

```jsonc
{
  "vendeurs": [{"lat": 5.90, "lon": -4.82}, {"lat": 5.902, "lon": -4.818}],  // retraits
  "destination": {"lat": 5.898, "lon": -4.83},
  "transport_slug": "moto",
  "instant": "2026-07-24T19:30:00Z",
  "nb_articles": 12,
  "categorie_slug": "resto_courses",
  "attentes": [],                         // (arrivée, scan) simulées, optionnel
  "offre_livraison_vendeur": null,        // VND-08 simulé, optionnel
  "mono_vendeur": false
}
```

Réponse `200 ResultatSimulation` — le **détail complet** (FR-020) :

```jsonc
{
  "itineraire": {"ordre": [1,0], "distance_m": 3400, "eta_s": 540, "degraded": false},
  "regle_retenue": {"regle_id": "…", "transport_slug": "moto", "priorite": 0},
  "composantes": {                        // unités mineures
    "base": 200, "km": 100, "supplements": 0,
    "effort_paliers": 100, "effort_attente": 0, "effort_arrets": 50,
    "arrondi": 0, "retenue_vendeur": 0
  },
  "devis": {"prix_client": 450, "part_coursier": 400, "marge": 50, "devise": "XOF",
            "proposer_scission": false},
  "drapeaux": {"livraison_offerte_mefali": true, "gratuite_commissions": true, "pluie": false}
}
```

> **Sans effet de bord** : la simulation n'écrit **aucun** événement outbox et ne modifie ni la grille en vigueur ni l'état de cache observable. Elle pose seulement `simulee_le`/`simulee_empreinte` sur le brouillon (garde de publication).

### 1.3 Publication — `POST …/publier`

`200` grille publiée (`version`, `effet_le`) + événement `grille.publiee`. Refus **gardé** :
- `409 simulation_requise` (clé `tarification.erreur.simulation_requise`) si `simulee_empreinte` ≠ empreinte courante du brouillon (jamais simulé, ou édité depuis).
- `409 regle_hors_bornes` si une règle du brouillon viole les bornes de marge de la zone.

## 2. DTO principaux (`ToSchema`)

`GrilleVue { id, zone_id, version, etat, effet_le, simulee: bool, regles: Vec<RegleVue> }` · `RegleVue` (miroir de `RegleUpsert` + `id`) · `DemandeSimulation` · `ResultatSimulation` · `Point { lat: f64, lon: f64 }` · `DevisVue { prix_client, part_coursier, marge, devise, distance_m, eta_s, degraded, proposer_scission }`.

Les `lat/lon` transitent en clair **dans les DTO de simulation** (positions de vendeurs, non personnelles) mais **jamais** dans les payloads d'événements (minimisation ARTCI — distances arrondies uniquement).

## 3. Traits internes exposés (pas d'HTTP) — consommés par CMD/DSP/CRS

`EvaluationTarifaire::evaluer(DemandeDevis, SourceGrille) -> Devis` · `OptimisationArrets::optimiser(zone, &[Point], Point) -> Itineraire` · `Routage::matrice(&[Point]) -> Matrice` (injecté ; OSRM réel en prod, doubles en test) · `CacheRoutage::{lire, ecrire}` (Redis en prod, mémoire en test). Détail des structures : [data-model.md §5](../data-model.md). Ces traits sont la **capacité** que CMD (verrouillage du devis), DSP (offre + ordre des arrêts) et CRS (gain coursier) consommeront ; ce cycle les exerce par des **courses simulées dans les tests**.

**Deux écarts assumés au data-model §5**, tous deux pour garder « tout paramètre paramétrable vit en configuration de zone » (constitution I) :

1. `OptimisationArrets::optimiser` prend la **zone** en premier argument — elle seule résout le facteur de dégradé et la précision de la clé de cache. Sans elle, ces deux valeurs seraient forcément en dur dans l'implémentation.
2. Le **cache n'est pas dans `Routage`** mais composé au-dessus (`routage::matrice_ou_degrade`). Placé dedans, un double compteur d'appels serait appelé aux DEUX passages d'une même course et SC-004 (« le 2ᵉ passage ne rappelle pas le routage ») ne serait pas démontrable.

`Itineraire` porte en plus `exhaustif: bool` — faux quand l'heuristique bornée a tranché au-delà de 4 retraits, pour qu'un ordre sous-optimal ne soit jamais présenté comme optimal (FR-031) — et `troncons_entre_arrets()`, la matière du barème de supplément d'arrêt (jambes entre retraits, **sans** la jambe de livraison).

## 4. Événements (registre `docs/taxonomie-evenements.md`)

| `type_evenement` | entité | Émis par |
|---|---|---|
| `grille.publiee` | `grille` | `publier` (transaction) |
| `routage.degrade` | `devis` | évaluation réelle, repli ×1,4 |
| `effort.calcule` | `devis` | évaluation réelle, effort non facturé (promo) |

Payloads : voir [data-model.md §6](../data-model.md). **Aucun** lat/lng brut ; distances arrondies ; `acteur` = UUID. Simulateur muet.

## 5. Codes d'erreur (clés i18n fr)

Le corps d'erreur est **toujours** `{ code, message_cle }` — jamais une phrase en dur (FR-001). Deux refus l'enrichissent de données structurées pour que l'admin sache quoi corriger sans aller lire la configuration de zone : `marge_hors_bornes` porte `min`/`max`/`valeur`, `devise_incoherente` porte `attendue`/`fournie`.

| HTTP | Clé | Sens |
|---|---|---|
| 409 | `tarification.erreur.marge_hors_bornes` | marge de règle hors [min,max] de zone (+ `min`/`max`/`valeur`) |
| 409 | `tarification.erreur.devise_incoherente` | devise de règle ≠ devise de zone (+ `attendue`/`fournie`) |
| 409 | `tarification.erreur.simulation_requise` | publication sans simulation valide sur l'empreinte courante |
| 409 | `tarification.erreur.regle_hors_bornes` | publication avec une règle hors bornes |
| 409 | `tarification.erreur.pas_un_brouillon` | écriture, simulation ou publication visant une grille `en_vigueur`/`historique` — la tarification en cours ne se modifie pas sous les pieds des clients (FR-012) |
| 404 | `tarification.erreur.grille_inconnue` | grille absente |
| 404 | `tarification.erreur.regle_inconnue` | règle absente, ou appartenant à une AUTRE grille (jamais déplacée en silence) |
| 422 | `tarification.erreur.corps_invalide` | DTO invalide (ex. aucun point de retrait) |
| 422 | `tarification.erreur.aucune_regle` | aucune règle applicable au simulateur (grille à compléter — condition corrigible par l'admin, pas une faute serveur ni un prix arbitraire). Côté **trait interne** (CMD/DSP), l'évaluation renvoie `ErreurTarif::AucuneRegle`, à traiter par l'appelant. |
| 422 | `tarification.erreur.aucune_grille_en_vigueur` | la zone n'a aucune grille publiée, ou sa grille n'entre en vigueur qu'à une date future |

Le **routage indisponible n'est pas une erreur** : il produit un devis `degraded=true` (jamais un blocage — constitution IV).

## 6. Régénération des clients

Après tout changement de contrat : `openapi.json` régénéré par utoipa, puis clients Dart/TS régénérés en CI — **jamais édités à la main** ; un diff non commité fait échouer le build (constitution I). Aucun client n'est consommé côté app **ce cycle** (surface admin future, ADM), mais le contrat est publié.
