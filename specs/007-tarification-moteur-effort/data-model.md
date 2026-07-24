# Phase 1 — Modèle de données & conception : tarification

Schéma Postgres, migration `0007`, seeds de zone, pipeline d'évaluation, traits exposés et événements. Montants = entiers unités mineures + devise ISO 4217 de la zone (constitution III). `0001..0006` **intouchées** (constitution I).

## 1. Schéma `tarification` — migration `0007_tarification.sql`

### 1.1 Types énumérés

```sql
CREATE SCHEMA tarification;

-- Cycle de vie d'une grille tarifaire (spec US1/US3, R7).
CREATE TYPE tarification.etat_grille AS ENUM ('brouillon', 'en_vigueur', 'historique');
```

### 1.2 Table `grille` — catalogue versionné par zone

```sql
CREATE TABLE tarification.grille (
    id                uuid PRIMARY KEY,                     -- UUIDv7
    zone_id           uuid NOT NULL REFERENCES zones.zone (id) ON DELETE RESTRICT,
    version           integer NOT NULL,
    etat              tarification.etat_grille NOT NULL DEFAULT 'brouillon',
    effet_le          timestamptz,                          -- date d'entrée en vigueur (NULL tant que brouillon)
    simulee_le        timestamptz,                          -- dernière simulation réussie (garde de publication, R7)
    simulee_empreinte text,                                 -- empreinte du contenu simulé (réarmement FR-021)
    cree_le           timestamptz NOT NULL DEFAULT now(),
    UNIQUE (zone_id, version)
);

-- Au plus UNE grille en vigueur par zone (sélection déterministe, R7).
CREATE UNIQUE INDEX grille_en_vigueur_unique
    ON tarification.grille (zone_id) WHERE etat = 'en_vigueur';

-- Au plus UN brouillon par zone à la fois (édition simple, développeur solo).
CREATE UNIQUE INDEX grille_brouillon_unique
    ON tarification.grille (zone_id) WHERE etat = 'brouillon';
```

### 1.3 Table `regle` — conditions → sorties

```sql
CREATE TABLE tarification.regle (
    id                 uuid PRIMARY KEY,
    grille_id          uuid NOT NULL REFERENCES tarification.grille (id) ON DELETE CASCADE,
    -- ── Conditions ──────────────────────────────────────────────────────────
    transport_slug     text    NOT NULL,                    -- véhicule (réf. zones.type_transport)
    categorie_slug     text,                                -- optionnel (NULL = toutes catégories)
    distance_min_m     integer NOT NULL DEFAULT 0,          -- borne basse de la tranche (mètres routiers)
    distance_max_m     integer,                             -- borne haute (NULL = +∞)
    plage_debut_min    smallint,                            -- minutes depuis minuit (NULL = toute heure)
    plage_fin_min      smallint,
    jours_masque       smallint,                            -- bitmask lun..dim (NULL = tous les jours)
    point_relais_id    uuid,                                -- PROVISION : toujours NULL au MVP (constitution IX)
    -- ── Sorties (unités mineures) ───────────────────────────────────────────
    part_coursier_base bigint  NOT NULL CHECK (part_coursier_base >= 0),
    marge              bigint  NOT NULL CHECK (marge >= 0),  -- bornée par zone à l'écriture (FR-009)
    prix_par_km        bigint  NOT NULL DEFAULT 0 CHECK (prix_par_km >= 0),  -- abonde client ET coursier
    seuil_km_m         integer NOT NULL DEFAULT 0,           -- km facturé au-delà de ce seuil
    prix_plafond       bigint,                               -- plafond du prix client (moto 500) — NULL = aucun
    devise             text    NOT NULL,                     -- ISO 4217, cohérente avec la zone (FR-023)
    priorite           integer NOT NULL DEFAULT 0,           -- départage volontaire (R5)
    actif              boolean NOT NULL DEFAULT true,
    cree_le            timestamptz NOT NULL DEFAULT now(),
    -- prix client de base = part_coursier_base + marge (invariant, dérivé — pas stocké)
    CHECK (distance_max_m IS NULL OR distance_max_m > distance_min_m),
    CHECK (point_relais_id IS NULL)                          -- garde la provision inutilisée (constitution IX)
);

CREATE INDEX regle_par_grille ON tarification.regle (grille_id) WHERE actif = true;
```

**Invariant monétaire** : `prix_client_base = part_coursier_base + marge` (dérivé, non stocké — évite la dénormalisation). La composante km (`prix_par_km` au-delà de `seuil_km_m`), la grille d'effort et le **reliquat d'arrondi** abondent la **part coursier** ; la **marge reste fixe** (clarification 2026-07-24, spec FR-016/FR-019). `prix_plafond` borne le prix **client**.

### 1.4 Notes de schéma

- **Cross-schema FK** `grille.zone_id → zones.zone` : lecture de cohérence, patron du cycle 006 (`arret.prestataire_id → prestataires.prestataire`).
- **Point relais** : colonne `point_relais_id` + `CHECK (… IS NULL)` — la provision existe dans le modèle mais est **structurellement inutilisable** au MVP (constitution IX, « prêt ≠ construit »).
- **Aucune table de course** : l'évaluation ne lit pas la logistique (R12). Aucun `commandes.*` touché.

## 2. Knobs de zone (config héritée) — seed `50_tarification_tiassale.sql`

Paramètres **scalaires** en `zones.parametre_zone` (héritage, lus via `ConfigurationZones::parametre`). Posés au niveau **ville (Tiassalé, `…0002`)** sauf mention. Valeurs = seeds éditables (Récapitulatif des paramètres de zone).

| Clé | Valeur seed | Story |
|---|---|---|
| `tarification.marge.min` | `25` | TRF-01 (borne défaut) |
| `tarification.marge.max` | `100` | TRF-01 |
| `tarification.arrondi_pas` | `25` | TRF-02 (arrondi FCFA sup.) |
| `routage.facteur_degrade` | `1.4` | TRF-02 (Récap. « ×1,4 ») |
| `routage.cache_ttl_h` | `24` | TRF-02 |
| `routage.arrondi_cle_decimales` | `4` | R3 (précision de clé de cache ≈ 11 m) |
| `effort.paliers_articles` | `[[6,10,50],[11,20,100],[21,null,150]]` | TRF-06 (Récap.) |
| `effort.prime_attente` | `{"seuil_min":15,"montant":100,"par":"course"}` | TRF-06 + clarification (une fois/course) |
| `effort.supplement_arret_m` | `[[0,100,25],[100,1000,50],[1000,null,100]]` | TRF-06 (Récap., tronçon routier) |
| `effort.plafond_suppléments_arret` | `null` | TRF-06 (plafond optionnel) |
| `effort.plafond_eclatement_m` | *(absent — dormant)* | TRF-06 (« seuil à définir » : **non seedé** au MVP ; `proposer_scission` reste faux tant qu'il est absent ; à calibrer en promo, Annexe B) |

Déjà présents (seed `10_zones_tiassale.sql`, **réutilisés**) : `devise.code=XOF`/`devise.decimales=0` (pays), `drapeau.livraison_offerte_mefali=true`, `drapeau.gratuite_commissions=true`, `drapeau.pluie=false`, `transport.actifs=[a_pied,velo,moto]` (ville).

### 2.1 Grille seed Tiassalé (rules)

Une grille `version=1`, `etat='en_vigueur'`, `effet_le=now()`, zone Tiassalé. Règles (devise XOF ; **marge 50** dans les bornes — la marge 0 du lancement vient du drapeau `gratuite_commissions`, R4) :

| Véhicule | distance_min–max (m) | part_coursier_base | marge | prix_par_km | seuil_km_m | prix_plafond | prix client dérivé |
|---|---|---|---|---|---|---|---|
| `a_pied` | 0 – 800 | 50 | 50 | 0 | 0 | — | **100** (≤ 800 m) |
| `velo` | 0 – 2000 | 100 | 50 | 0 | 0 | — | **150** (≤ 2 km) |
| `moto` | 0 – null | 150 | 50 | 50 (par km) | 2000 | 500 | **200 + 50/km au-delà de 2 km, plafond 500** |

Exemple moto 4 km : prix client = 200 + 50×(4−2) = **300** ; part = 150 + 50×2 = 250 ; marge 50 ; 300 = 250 + 50 ✓. Au lancement (drapeaux ON) : prix client **0**, marge **0**, part 250 **journalisée** (payée au fixe hors moteur).

Seed **rejouable et idempotent** (`INSERT … ON CONFLICT DO NOTHING`, patron cycle 002), **séparé des migrations** (constitution I).

## 3. Pipeline d'évaluation (cœur `evaluation.rs`)

Entrée `DemandeDevis`, sortie `Devis`. Ordre **exact** (R4/R6, spec Assumptions « pipeline ») :

1. **Optimisation d'ordre** (`OptimisationArrets`) — matrice OSRM (R2) sur retraits + client ; permutations ≤ 4 minimisant la distance totale **retraits → client** (origine = 1er retrait, pas le coursier — R11) ; > 4 : heuristique bornée explicite. Sortie : ordre, `distance_m`, `eta_s`, `degraded`, tronçons.
2. **Sélection de règle** (`regle.rs`) — la plus spécifique, active, en vigueur à l'instant, matchant {véhicule, catégorie?, plage, tranche `distance_m`} ; départage priorité puis id (R5). Absente → `ErreurTarif::AucuneRegle` (edge case, jamais un prix arbitraire).
3. **Composante déplacement** — `prix_client = part_coursier_base + marge + prix_par_km × max(0, km − seuil)` (km dérivés du m routier), plafonné à `prix_plafond`. `part_coursier = prix_client − marge` (marge fixe).
4. **Suppléments** — pluie (drapeau zone `pluie` → +montant seed), plage horaire / longue distance (si règles/params activés). Abondent client **et** part coursier (marge fixe).
5. **Grille d'effort** (`effort.rs`, 100 % coursier) — ajoutée au **prix client et à la part coursier** :
   - **Paliers d'articles** : palier de `nb_articles` (total commande) → montant.
   - **Prime d'attente** : si l'écart (scan − arrivée) > 15 min à **≥ 1** arrêt → **+100 une seule fois par course** (clarification). Requiert les deux horodatages ; sinon 0.
   - **Supplément d'arrêt** : pour chaque arrêt supplémentaire (1er inclus), classer la **distance routière au précédent** (tronçon de la matrice) dans le barème `effort.supplement_arret_m` → montant ; total borné par `effort.plafond_suppléments_arret` si défini.
6. **Arrondi** — prix client arrondi **au pas** `arrondi_pas` (25) **supérieur** ; le **reliquat abonde la part coursier** (marge fixe). Ne s'applique pas à un 0 forcé (étape 7).
7. **Drapeaux de zone** — `livraison_offerte_mefali` → `prix_client = 0` (part coursier conservée) ; `gratuite_commissions` → `marge = 0` (⇒ prix client = part coursier hors autre drapeau).
8. **VND-08** (après drapeaux, R9) — si `offre_livraison_vendeur` présent **et** commande **mono-vendeur** : `prix_client → 0` (ou 0 au-delà du seuil), part coursier inchangée. Ignoré en multi-vendeurs.
9. **Figer** — `Devis { prix_client, part_coursier, marge, devise, distance_m, eta_s, degraded, ordre, composantes }`. Invariant vérifié (hors mises à 0). Émission conditionnelle : `routage.degrade` si `degraded`, `effort.calcule` si effort non facturé (promo).

**Plafond d'éclatement** : si `effort.plafond_eclatement_m` est **défini** et que la distance totale (ou le détour) le dépasse, le devis porte `proposer_scission=true` (CMD proposera de scinder ; TRF ne scinde pas). **Absent (défaut MVP) ⇒ `proposer_scission` toujours faux** — la valeur reste à calibrer (Annexe B) ; les tests la posent explicitement pour exercer le cas.

## 4. Machines à états

### 4.1 Grille (R7)

```
brouillon ──simuler(empreinte courante)──▶ brouillon (simulee_le, simulee_empreinte posés)
brouillon ──éditer une règle──▶ brouillon (empreinte recalculée ⇒ simulation invalidée)
brouillon ──publier [simulée sur empreinte courante ∧ aucune règle hors bornes]──▶ en_vigueur (effet_le)
   │                                                     └─ ancienne en_vigueur ──▶ historique
   └─ publier sans simulation / avec règle hors bornes ──▶ REFUS (409)
```

Transition `publier` = **transaction** : archive l'ancienne, active le brouillon, écrit `grille.publiee`. Garde inviolable côté serveur (jamais côté client).

### 4.2 Devis

Le devis n'est pas une entité persistée par TRF ce cycle (CMD le verrouillera). L'évaluation est **pure** (lecture config/règles/cache + calcul) ; ses seuls effets sont les **événements** (production réelle) — **jamais en simulation**.

## 5. Traits exposés (ports.rs) — capacité pour les cycles suivants

```rust
/// Évaluation tarifaire — consommée par CMD (verrouillage), DSP (offre), le
/// simulateur admin. Prend la GÉOMÉTRIE, pas la logistique (R12).
#[async_trait]
pub trait EvaluationTarifaire: Send + Sync {
    async fn evaluer(&self, demande: DemandeDevis, source: SourceGrille)
        -> Result<Devis, ErreurTarif>;
}

/// Optimisation de l'ordre des arrêts — EXPOSÉE À DSP ET CMD (spec FR-031).
#[async_trait]
pub trait OptimisationArrets: Send + Sync {
    async fn optimiser(&self, retraits: &[Point], client: Point)
        -> Result<Itineraire, ErreurTarif>;   // ordre, distance_m, eta_s, degraded, tronçons
}

/// Routage — trait injecté (client OSRM réel en prod ; RoutageFixe / RoutageIndisponible en test).
#[async_trait]
pub trait Routage: Send + Sync {
    async fn matrice(&self, points: &[Point]) -> Result<Matrice, ErreurRoutage>;  // cache + OSRM + dégradé
}

pub enum SourceGrille { EnVigueur, Brouillon(Uuid) }  // production vs simulateur
```

`DemandeDevis { zone_id, transport_slug, retraits: Vec<Point>, client: Point, nb_articles, instant, categorie_slug: Option<String>, attentes: Vec<(arrivee, scan)>, offre_livraison_vendeur: Option<OffreLivraison>, mono_vendeur: bool }`.

`Devis { prix_client, part_coursier, marge, devise, distance_m, eta_s, degraded, proposer_scission, ordre: Vec<usize>, composantes: Composantes }` où `Composantes { base, km, suppléments, effort_paliers, effort_attente, effort_arrets, arrondi, retenue_vendeur }` (tout en unités mineures — détail du simulateur, FR-020).

Écritures (brouillon, publication) = **méthodes inhérentes de `PgTarification` sur `&mut PgTransaction`** (outbox inclus, patron cycles 002/005). Lectures/évaluation = trait sur pool + `Routage` injecté.

## 6. Événements outbox (constitution VI, R10)

Déclarés dans `docs/taxonomie-evenements.md` **avant** implémentation. Écrits par `socle::ecrire_evenement` dans la transaction de l'opération. **Simulateur muet**.

| `type_evenement` | entité | Déclencheur | Payload (au-delà des clés standard zone/categorie/role) |
|---|---|---|---|
| `grille.publiee` | `grille` | Publication d'un brouillon | `grille_id`, `version`, `effet_le`, `acteur` (admin) |
| `routage.degrade` | `devis` | Repli vol d'oiseau ×1,4 | `zone`, `transport`, `nb_points`, `distance_m` (arrondie), `facteur` |
| `effort.calcule` | `devis` | Effort calculé **non facturé** (promo) | `zone`, `montant_effort`, `paliers`/`attente`/`arrets` (unités mineures), `facture=false` |

Payloads **minimisés ARTCI** : distances **arrondies**, **aucun lat/lng brut**, `acteur` = UUID. Métriques MET dérivées (aucun KPI manuel).

## 7. Couverture de tests d'intégration (constitution VII)

Un test par comportement (doubles `RoutageFixe`/`RoutageIndisponible`, géométries simulées) : borne de marge refusée à l'écriture ; sélection de règle spécifique/priorité/départage ; devis routé + invariant ; **cache** (2ᵉ appel sans OSRM) ; **dégradé** ×1,4 `degraded=true` + `routage.degrade` sans blocage ; optimisation ordre ≤ 4 (meilleure permutation, déterministe) ; drapeaux (client 0 / marge 0) ; VND-08 mono vs multi ; arrondi → part coursier ; **prime d'attente une fois/course** (multi-arrêts lents = +100) ; paliers d'articles ; supplément d'arrêt sur tronçon routier ; **garde de publication** (sans simulation → 409 ; règle hors bornes → 409 ; édition réarme) ; **seed Tiassalé** au FCFA près (100/150/200+50 km/plafond 500) ; `effort.calcule` en promo (journalisé non facturé) ; simulateur **sans effet de bord** (aucun outbox, état en vigueur inchangé).
