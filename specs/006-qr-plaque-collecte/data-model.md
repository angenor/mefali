# Modèle de données — QR prestataire, plaque et scans de collecte

Deux nouvelles migrations (`0001..0004` intouchées, constitution I). Un schéma par module (constitution II). Montants en entiers d'unités mineures + devise ISO 4217 (III). GPS minimisé dans les événements (VIII/ARTCI).

---

## 1. Migration `0005_commandes.sql` — socle logistique

> Socle **minimal** que CMD étendra (nouvelles migrations, jamais celle-ci). Aucune logique de création/cash/substitution/dispatch ici.

### 1.1 Enums

```sql
CREATE SCHEMA IF NOT EXISTS commandes;

-- Machine à états de l'arrêt (cadrage §7.2). QRC ne POSE que 'collecte' ;
-- 'indisponible' viendra de CMD-06 (substitution) — présent dès le socle pour
-- que le gating EN_LIVRAISON le compte comme résolu (spec FR-018).
CREATE TYPE commandes.statut_arret AS ENUM ('a_collecter', 'collecte', 'indisponible');

-- Méthode de collecte (unifie scan et dégradé — cadrage §7.2).
CREATE TYPE commandes.mode_collecte AS ENUM ('scan_qr', 'code_secours');

-- État logistique de la livraison (constitution II — PAS sur le tronc commande).
CREATE TYPE commandes.etat_livraison AS ENUM ('en_collecte', 'en_livraison');
```

### 1.2 Tables

```sql
-- Ancre du tronc (constitution II — AUCUN champ logistique). CMD ajoutera
-- identité, montants, paiement, états de haut niveau par migrations ultérieures.
CREATE TABLE commandes.commande (
    id      uuid PRIMARY KEY,
    cree_le timestamptz NOT NULL DEFAULT now()
);

-- Composant OPTIONNEL (0..n) rattaché à la commande. Le MVP en crée une.
-- coursier_id est POSÉ par DSP (affectation) — NULL tant que non assignée ;
-- simulé dans les tests QRC (R10).
CREATE TABLE commandes.livraison (
    id          uuid PRIMARY KEY,
    commande_id uuid NOT NULL REFERENCES commandes.commande (id) ON DELETE CASCADE,
    coursier_id uuid REFERENCES comptes.compte (id) ON DELETE RESTRICT,
    etat        commandes.etat_livraison NOT NULL DEFAULT 'en_collecte',
    etat_le     timestamptz NOT NULL DEFAULT now(),
    cree_le     timestamptz NOT NULL DEFAULT now()
);

-- Segment (niveau transporteur — MVP : 1 segment coursier).
CREATE TABLE commandes.segment (
    id           uuid PRIMARY KEY,
    livraison_id uuid NOT NULL REFERENCES commandes.livraison (id) ON DELETE CASCADE,
    ordre        smallint NOT NULL,
    UNIQUE (livraison_id, ordre)
);

-- Arrêt : maillon documenté (user-stories §CMD ; cadrage §7.3). Position et
-- montant DÉNORMALISÉS depuis le site (stabilité + pré-provisionnement offline).
CREATE TABLE commandes.arret (
    id              uuid PRIMARY KEY,
    segment_id      uuid NOT NULL REFERENCES commandes.segment (id) ON DELETE CASCADE,
    prestataire_id  uuid NOT NULL REFERENCES prestataires.prestataire (id) ON DELETE RESTRICT,
    ordre           smallint NOT NULL,
    -- Position ATTENDUE du site (proximité de scan, R3). Position du VENDEUR,
    -- pas une donnée personnelle.
    site_lat        double precision NOT NULL,
    site_lon        double precision NOT NULL,
    -- Montant avancé par le coursier à cet arrêt (III). Soumis au seuil photo.
    montant_avance  bigint NOT NULL CHECK (montant_avance >= 0),
    devise          text   NOT NULL,                       -- ISO 4217 (XOF)
    statut          commandes.statut_arret NOT NULL DEFAULT 'a_collecter',
    -- Journal de la collecte (renseigné à la bascule 'collecte').
    collecte_le     timestamptz,                           -- horodatage SERVEUR
    mode_collecte   commandes.mode_collecte,
    photo_cle       text,                                  -- clé Garage, si photo
    distance_scan_m integer,                               -- arrondi (ARTCI, pas de GPS brut)
    collecte_uuid_client uuid,                             -- idempotence (V)
    UNIQUE (segment_id, ordre)
);

CREATE INDEX arret_par_coursier ON commandes.arret (prestataire_id)
    WHERE statut = 'a_collecter';
```

### 1.3 Machine à états — arrêt & livraison

- **Arrêt** : `a_collecter → collecte` (QRC, par scan ou code) ; `a_collecter → indisponible` (CMD-06, hors QRC). Transition **gardée** dans le crate (jamais par l'enum seul, patron 005). Idempotence : un rejeu du même `collecte_uuid_client` sur un arrêt déjà `collecte` → succès sans nouvelle écriture ni événement.
- **Livraison** : `en_collecte → en_livraison` quand **tous** les arrêts de la livraison sont **résolus** (`collecte` ou `indisponible`). Une seule fois (garde : ne rebascule pas).

---

## 2. Migration `0006_qr.sql` — traçabilité QR

```sql
CREATE SCHEMA IF NOT EXISTS qr;

-- Override prestataire de la politique photo (R4, niveau 1 de la hiérarchie).
-- Ajout au schéma prestataires par NOUVELLE migration (constitution I).
ALTER TABLE prestataires.prestataire
    ADD COLUMN politique_photo_collecte text
    CHECK (politique_photo_collecte IN ('obligatoire','facultative','desactivee'));

-- Incident « plaque à remplacer » (QRC-04) — créé au passage en mode dégradé,
-- UNE fois par arrêt (clarification Q2). Rattaché au prestataire + contexte.
CREATE TABLE qr.incident_plaque (
    id             uuid PRIMARY KEY,
    prestataire_id uuid NOT NULL REFERENCES prestataires.prestataire (id) ON DELETE RESTRICT,
    arret_id       uuid NOT NULL REFERENCES commandes.arret (id) ON DELETE RESTRICT,
    coursier_id    uuid NOT NULL REFERENCES comptes.compte (id) ON DELETE RESTRICT,
    origine        text NOT NULL DEFAULT 'qr_illisible',
    statut         text NOT NULL DEFAULT 'ouvert',         -- ouvert|resolu (résolution = ADM)
    cree_le        timestamptz NOT NULL DEFAULT now(),
    UNIQUE (arret_id)                                      -- dédup « une fois par arrêt »
);

-- Registre d'idempotence des actions de collecte (V — rejeu idempotent).
-- Mémorise l'ISSUE de chaque uuid_client pour ne ré-émettre aucun événement au
-- rejeu (ni COLLECTÉ ni rejet métier).
CREATE TABLE qr.action_traitee (
    uuid_client uuid PRIMARY KEY,
    arret_id    uuid NOT NULL REFERENCES commandes.arret (id) ON DELETE CASCADE,
    resultat    text NOT NULL,                             -- collecte|rejet:<motif>
    traite_le   timestamptz NOT NULL DEFAULT now()
);
```

> **Compteur d'essais du code dégradé** : Redis `qr:essais:{arret_id}` (INCR + TTL, backstop en ligne, R7) — **pas** de table (éphémère, constitution II).

---

## 3. Paramètres de zone à seeder (`backend/migrations/seeds/`)

À inscrire au « Récapitulatif des paramètres de zone » de `docs/user-stories-v2.md` (mise à jour doc = prérequis, comme la charte 5 ans du cycle 005).

| Clé | Portée | Seed | Story |
|---|---|---|---|
| `qr.distance_scan_max_m` | pays | `100` | QRC-02 (déjà au récap., à matérialiser en base) |
| `qr.photo_seuil_montant` | pays | `10000` (XOF, ≈ 10 000 FCFA — éditable) | QRC-02 (nouveau — R4) |
| `qr.retention_photo_collecte_jours` | pays | `365` (ordre de grandeur du repère vocal) | VIII (nouveau) |
| `categorie.restauration.politique_photo` | catégorie | `facultative` | QRC-02 / cadrage §4 |
| `categorie.pharmacie.politique_photo` | catégorie | `obligatoire` | cadrage §4 l.83 |

Compteurs de seed du test `seed_zones_idempotent` (`api/src/lib.rs`) à **incrémenter** en conséquence.

---

## 4. Traits & structures exposés aux autres crates

### 4.1 Crate `commandes`

```rust
/// Arrêt qu'un coursier peut collecter chez un prestataire (précondition QRC-02).
pub struct ArretACollecter {
    pub arret_id: Uuid,
    pub livraison_id: Uuid,
    pub segment_id: Uuid,
    pub commande_id: Uuid,
    pub prestataire_id: Uuid,
    pub site_lat: f64,
    pub site_lon: f64,
    pub montant_avance: i64,
    pub devise: String,
}

/// Lecture de la précondition — impl Postgres `PgCommandes` (prod) +
/// `ArretsFixes` (tests, patron `CommandesActivesFixes`).
#[async_trait]
pub trait ArretsDeCollecte: Send + Sync {
    async fn arret_a_collecter(
        &self, coursier: Uuid, prestataire: Uuid,
    ) -> Result<Option<ArretACollecter>, ErreurCommandes>;
}

/// Progression renvoyée après une collecte réussie.
pub struct ProgressionCollecte {
    pub nb_collectes: i16,
    pub nb_arrets: i16,
    pub en_livraison: bool,   // vrai si la dernière collecte a basculé la livraison
}

impl PgCommandes {
    /// Bascule l'arrêt en COLLECTÉ dans `tx`, écrit `arret.collecte`, et si tous
    /// les arrêts sont résolus, bascule la livraison + écrit
    /// `livraison.mise_en_livraison`. Idempotent par `uuid_client`.
    pub async fn marquer_arret_collecte(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        arret_id: Uuid,
        uuid_client: Uuid,
        mode: ModeCollecte,
        photo_cle: Option<&str>,
        distance_m: i32,
        horodatage_serveur: DateTime<Utc>,
        acteur: Uuid,
    ) -> Result<ProgressionCollecte, ErreurCommandes>;
}
```

### 4.2 Crate `qr` (composition racine `PgQr`, consommée par `api`)

```rust
impl PgQr {
    /// QRC-01 — compose le PDF, le dépose (Garage), émet `plaque.generee`,
    /// renvoie l'URL présignée. Refuse si pas d'identité de plaque (FR-011).
    pub async fn plaque_pdf(&self, prestataire_id: Uuid, acteur: Uuid)
        -> Result<UrlPresignee, ErreurQr>;

    /// Pré-provisionnement offline (R6) — empreintes + sites + photo résolue.
    pub async fn pre_provisionnement(&self, coursier: Uuid)
        -> Result<Vec<ArretPreProvisionne>, ErreurQr>;

    /// QRC-02/03/04 — vérifie (résolution jeton | code dégradé, proximité,
    /// photo, 3 essais), puis appelle `commandes::marquer_arret_collecte`.
    /// Idempotent (uuid_client). Crée l'incident au 1er passage dégradé.
    pub async fn collecter(&self, coursier: Uuid, demande: DemandeCollecte)
        -> Result<ResultatCollecte, ErreurQr>;
}

pub struct ArretPreProvisionne {
    pub arret_id: Uuid,
    pub prestataire_id: Uuid,
    pub empreinte_jeton: String,   // base16(sha256(jeton))
    pub empreinte_code: String,    // base16(sha256(prestataire_id ‖ code))
    pub site_lat: f64,
    pub site_lon: f64,
    pub montant_avance: i64,
    pub devise: String,
    pub photo_exigee: bool,        // politique résolue (R4)
}
```

`PgQr` dépend de : `commandes::{PgCommandes, ArretsDeCollecte}`, `prestataires::PgPrestataires` (`resolution_plaque`, `code_secours`), `zones::ConfigurationZones` (paramètres), `socle::DepotObjets` (PDF + photo), un port Redis (compteur). Impls réelles câblées dans `api::run` (racine de composition).

### 4.3 Consommation de l'existant (cycle 005, inchangé)

- `prestataires::PgPrestataires::resolution_plaque(jeton) -> Option<ResolutionPlaque>` (`{prestataire_id, valide}`) — révocation observée (QRC-03).
- La ligne `prestataires.prestataire` porte `jeton_plaque`, `code_secours` (lus pour composer le PDF et les empreintes).

---

## 5. Résolution de la politique photo (R4)

```
photo_exigee(arret) =
    match override_prestataire(arret.prestataire) {          // niveau 1
        Some(p) => p,
        None    => politique_categorie(arret.prestataire),    // niveau 2 (zones)
    }
    |> forcer_obligatoire_si(arret.montant_avance >= zone.qr.photo_seuil_montant)  // niveau 3
    == 'obligatoire'
```

---

## 6. Stockage objet (Garage, via `socle::DepotObjets`)

| Objet | Clé | MIME | Rétention |
|---|---|---|---|
| PDF de plaque | `qr/plaques/{prestataire_id}.pdf` | `application/pdf` | régénérable (écrasé) |
| Photo de récupération | `qr/collectes/{arret_id}.jpg` | `image/jpeg` | `qr.retention_photo_collecte_jours` (job de purge, patron repère vocal R8) |

---

## 7. Événements outbox

Voir [research.md](./research.md) R12 (tableau complet). Cinq clés — `plaque.generee`, `arret.collecte`, `livraison.mise_en_livraison`, `plaque.remplacement_requis`, `arret.collecte_rejetee` — écrites par `socle::ecrire_evenement` dans la transaction de la mutation, payloads minimisés ARTCI. À **déclarer d'abord** dans `docs/taxonomie-evenements.md` (constitution VI).

---

## 8. Modèle local des apps (Mefali Pro / `mefali_core`, `drift`)

```text
action_en_attente(uuid_client PK, endpoint, methode, payload_json,
                  photo_octets BLOB?, cree_le_local, tentatives, dernier_motif)
arret_preprovisionne(arret_id PK, prestataire_id, empreinte_jeton, empreinte_code,
                     site_lat, site_lon, montant_avance, devise, photo_exigee, statut_local)
```

- `action_en_attente` : file idempotente (R5), rejeu au retour réseau ; `uuid_client` = UUIDv7 généré à l'action.
- `arret_preprovisionne` : cache de la course active (R6) ; permet scan, proximité et confirmation par code **hors-ligne** ; `statut_local` reflète la coche optimiste avant réconciliation serveur.
