# Phase 1 — Modèle de données & conception : commandes

Migrations `0008`/`0009`, répartition tronc/livraison, machine à états à trois niveaux, pipeline de création, traits exposés et événements. Montants = **entiers en unités mineures** + devise ISO 4217 de la zone (constitution III). `0001..0007` **intouchées** (constitution I).

## 1. Migration `0008_commandes_enums.sql` — énums seuls

Ce fichier ne contient **que** des types. Aucune table, aucun index, aucune contrainte : les valeurs ajoutées ne peuvent pas être utilisées dans la transaction qui les crée (research R2).

```sql
-- ── Extensions des énums du socle 006 ──────────────────────────────────────
-- Boucle de collecte par arrêt (cadrage §7.2) : le socle ne posait que
-- 'a_collecter' → 'collecte'. CMD intercale les deux états de la boucle.
ALTER TYPE commandes.statut_arret ADD VALUE IF NOT EXISTS 'en_route'  BEFORE 'collecte';
ALTER TYPE commandes.statut_arret ADD VALUE IF NOT EXISTS 'arrive'    BEFORE 'collecte';

-- États logistiques complets de la livraison (le socle n'avait que les deux
-- états de la fenêtre QRC).
ALTER TYPE commandes.etat_livraison ADD VALUE IF NOT EXISTS 'assignee' BEFORE 'en_collecte';
ALTER TYPE commandes.etat_livraison ADD VALUE IF NOT EXISTS 'livree';
ALTER TYPE commandes.etat_livraison ADD VALUE IF NOT EXISTS 'echouee';
ALTER TYPE commandes.etat_livraison ADD VALUE IF NOT EXISTS 'annulee';

-- ── Types neufs (créables ici, utilisables dès 0009) ───────────────────────

-- États de TRÈS HAUT NIVEAU du tronc (constitution II — aucun état logistique).
CREATE TYPE commandes.etat_commande AS ENUM (
    'nouvelle', 'en_attente_paiement', 'en_attente_coursier',
    'en_cours', 'terminee', 'annulee', 'echouee'
);

-- Nature de l'arrêt (cadrage §7.2 : 1..n collectes + 1 remise).
CREATE TYPE commandes.type_arret AS ENUM ('collecte', 'remise');

-- Préférence de substitution par article (CMD-01, défaut « m'appeler »).
CREATE TYPE commandes.preference_substitution AS ENUM ('remplacer', 'appeler', 'retirer');

-- Cycle de vie d'une ligne de commande.
CREATE TYPE commandes.statut_ligne AS ENUM ('presente', 'remplacee', 'retiree');

-- Issue d'une proposition de remplacement (CMD-06 + maquette C4-4c).
CREATE TYPE commandes.issue_substitution AS ENUM (
    'en_attente', 'acceptee', 'refusee', 'expiree_appel', 'retiree'
);

-- Mode de paiement (III — jamais de chemin partiel).
CREATE TYPE commandes.mode_paiement AS ENUM ('cash', 'mobile_money');
CREATE TYPE commandes.etat_paiement  AS ENUM ('du', 'en_attente', 'regle', 'rembourse');

-- Les 10 lignes du tableau des cas limites (cadrage §7.5) + la sous-branche
-- « refus de reprise vendeur » que CMD-08 nomme explicitement.
CREATE TYPE commandes.type_issue_echec AS ENUM (
    'refus_non_perissable', 'refus_reprise_vendeur', 'refus_perissable',
    'contestation_montant', 'sans_appoint', 'faux_billet',
    'non_conformite', 'casse_transport', 'annulation_apres_achat',
    'vendeur_ferme_consigne', 'suspicion_faux_refus'
);

-- Qui détient l'argent / la marchandise à l'issue (CMD-08 — deux axes
-- INDÉPENDANTS, research R14).
CREATE TYPE commandes.detenteur AS ENUM ('client', 'coursier', 'vendeur', 'mefali', 'consigne');

-- Sanction posée sur le compte client (CPT-06, colonnes déjà en base).
CREATE TYPE commandes.sanction AS ENUM ('aucune', 'prepaiement_impose', 'bloque');
```

## 2. Migration `0009_commandes_tronc.sql` — structures

### 2.1 Tronc `commande` — extension de l'ancre du cycle 006

L'ancre créée en `0005` ne portait que `id` et `cree_le`. **Aucun champ logistique** n'est ajouté (research R3).

```sql
ALTER TABLE commandes.commande
    -- ── Identité ───────────────────────────────────────────────────────────
    ADD COLUMN client_id       uuid NOT NULL REFERENCES comptes.compte (id) ON DELETE RESTRICT,
    ADD COLUMN zone_id         uuid NOT NULL REFERENCES zones.zone (id)     ON DELETE RESTRICT,
    ADD COLUMN categorie_id    uuid NOT NULL REFERENCES zones.categorie (id) ON DELETE RESTRICT,
    -- ── Lieu de prestation (destination pour un vertical de livraison) ─────
    -- DÉNORMALISÉ depuis comptes.adresse : le carnet peut être modifié, purgé
    -- ou supprimé sans jamais altérer une commande passée (R3).
    ADD COLUMN lieu_lat        double precision NOT NULL,
    ADD COLUMN lieu_lon        double precision NOT NULL,
    ADD COLUMN repere_texte    text,
    ADD COLUMN repere_vocal_cle text,                  -- clé S3, copiée à la création
    ADD COLUMN adresse_id      uuid REFERENCES comptes.adresse (id) ON DELETE SET NULL,
    -- ── Montants (III) — les FRAIS vivent sur la livraison, pas ici ────────
    ADD COLUMN montant_articles_unites bigint NOT NULL CHECK (montant_articles_unites >= 0),
    ADD COLUMN total_unites            bigint NOT NULL CHECK (total_unites >= 0),
    ADD COLUMN devise                  text   NOT NULL,          -- ISO 4217 de la zone
    -- ── Paiement ───────────────────────────────────────────────────────────
    ADD COLUMN mode_paiement  commandes.mode_paiement NOT NULL,
    ADD COLUMN etat_paiement  commandes.etat_paiement NOT NULL DEFAULT 'du',
    -- ── État de TRÈS HAUT NIVEAU ───────────────────────────────────────────
    ADD COLUMN etat    commandes.etat_commande NOT NULL DEFAULT 'nouvelle',
    ADD COLUMN etat_le timestamptz NOT NULL DEFAULT now(),
    -- ── Secrets de CONFIRMATION D'EXÉCUTION, remis au client dès la création
    -- (R6). Sur le TRONC et non sur la livraison, malgré leur usage actuel à la
    -- remise : ce sont des secrets GÉNÉRIQUES de confirmation d'exécution d'une
    -- commande, que tout vertical réutilisera tel quel (un artisan de phase N
    -- fait valider son intervention par le même code, sans aucune livraison).
    -- Les placer sur `livraison` rendrait la confirmation IMPOSSIBLE pour un
    -- vertical sans livraison — c'est-à-dire pour le cas que la constitution II
    -- protège. Ils ne portent aucune donnée logistique : ni coursier, ni arrêt,
    -- ni itinéraire, ni montant. Voir plan.md § Complexity Tracking.
    ADD COLUMN code_livraison       text NOT NULL,   -- 4 chiffres, lisible par le CLIENT seul
    ADD COLUMN code_livraison_hash  text NOT NULL,   -- empreinte salée → coursier (offline CRS-04)
    ADD COLUMN jeton_reception      text NOT NULL,   -- encodé dans le QR client
    ADD COLUMN jeton_reception_hash text NOT NULL,   -- empreinte salée → coursier
    ADD COLUMN essais_code smallint NOT NULL DEFAULT 0,  -- 3 max (paramètre de zone)
    -- ── Re-livraison après consigne (§7.5) : nouvelle commande LIÉE (spec) ─
    ADD COLUMN relivraison_de uuid REFERENCES commandes.commande (id) ON DELETE SET NULL,
    -- Cohérence : une commande terminée a forcément été payée.
    ADD CONSTRAINT commande_terminee_payee
        CHECK (etat <> 'terminee' OR etat_paiement IN ('regle', 'rembourse'));

-- L'identifiant EST la clé d'idempotence du POST (patron cycle 003, R7) :
-- aucune colonne ni table supplémentaire n'est nécessaire.

-- File d'attente sans coursier : FIFO par âge, sans table dédiée (CMD-10).
CREATE INDEX commande_attente_fifo ON commandes.commande (cree_le)
    WHERE etat = 'en_attente_coursier';

-- Suivi client : ses commandes en cours.
CREATE INDEX commande_par_client ON commandes.commande (client_id, cree_le DESC);
```

### 2.2 Livraison — le devis figé et l'état logistique

```sql
ALTER TABLE commandes.livraison
    -- ── Devis FIGÉ, copié du cycle 007 à la création, jamais recalculé (R11) ─
    ADD COLUMN devis_prix_client   bigint NOT NULL DEFAULT 0 CHECK (devis_prix_client >= 0),
    ADD COLUMN devis_part_coursier bigint NOT NULL DEFAULT 0 CHECK (devis_part_coursier >= 0),
    ADD COLUMN devis_marge         bigint NOT NULL DEFAULT 0 CHECK (devis_marge >= 0),
    ADD COLUMN devis_devise        text   NOT NULL DEFAULT 'XOF',
    ADD COLUMN devis_distance_m    bigint NOT NULL DEFAULT 0,
    ADD COLUMN devis_eta_s         bigint NOT NULL DEFAULT 0,
    ADD COLUMN devis_degraded      boolean NOT NULL DEFAULT false,  -- constitution IV
    ADD COLUMN devis_composantes   jsonb   NOT NULL DEFAULT '{}',   -- détail effort (affichage)
    ADD COLUMN proposer_scission   boolean NOT NULL DEFAULT false,  -- informatif (déjà décidé par TRF)
    -- ── Remise ─────────────────────────────────────────────────────────────
    ADD COLUMN livree_le    timestamptz,
    ADD COLUMN mode_remise  text,                     -- 'qr' | 'code' | 'depot'
    ADD COLUMN depot_photo_cle text,                  -- mode dépôt autorisé (§7.4-5)
    ADD COLUMN assignee_le  timestamptz;

-- Course active d'un coursier, tous états de travail confondus.
CREATE INDEX livraison_coursier_active ON commandes.livraison (coursier_id)
    WHERE etat IN ('assignee', 'en_collecte', 'en_livraison');
```

> L'index partiel `livraison_par_coursier` du cycle 006 (`WHERE etat = 'en_collecte'`) reste valide et n'est pas touché.

### 2.3 Arrêt — type, boucle de collecte, remise

```sql
ALTER TABLE commandes.arret
    ADD COLUMN type_arret commandes.type_arret NOT NULL DEFAULT 'collecte',
    ADD COLUMN en_route_le timestamptz,
    ADD COLUMN arrive_le   timestamptz,               -- base de la prime d'attente (TRF-06)
    ADD COLUMN transition_uuid_client uuid,           -- idempotence des transitions (V)
    -- La remise n'a pas de prestataire (R4).
    ALTER COLUMN prestataire_id DROP NOT NULL,
    -- Sémantique ÉLARGIE de site_lat/site_lon (nommées au cycle 006 pour les
    -- seules collectes) : position ATTENDUE de l'arrêt — le site du vendeur pour
    -- une collecte, le lieu de prestation du client pour une remise. Les colonnes
    -- ne sont PAS renommées (migration appliquée, constitution I).
    ADD CONSTRAINT arret_prestataire_coherent CHECK (
        (type_arret = 'collecte' AND prestataire_id IS NOT NULL) OR
        (type_arret = 'remise'   AND prestataire_id IS NULL)
    ),
    -- Un seul arrêt de remise par segment, toujours le dernier.
    ADD CONSTRAINT arret_remise_sans_montant CHECK (
        type_arret = 'collecte' OR montant_avance = 0
    );

CREATE UNIQUE INDEX arret_remise_unique ON commandes.arret (segment_id)
    WHERE type_arret = 'remise';
```

> **Correction obligatoire du gating hérité (R4)** — `PgCommandes::gating_livraison` compte aujourd'hui `count(*)` sur **tous** les arrêts du segment. Avec l'arrêt de remise, `resolus = total` ne serait **jamais** vrai. Les trois requêtes de comptage (`gating_livraison`, `progression`) doivent être filtrées par `a.type_arret = 'collecte'`. Le test du cycle 006 est conservé ; un cas « livraison **avec** arrêt de remise » lui est ajouté.

### 2.4 Lignes de commande

```sql
CREATE TABLE commandes.ligne_commande (
    id             uuid PRIMARY KEY,
    commande_id    uuid NOT NULL REFERENCES commandes.commande (id) ON DELETE CASCADE,
    prestataire_id uuid NOT NULL REFERENCES prestataires.prestataire (id) ON DELETE RESTRICT,
    article_id     uuid NOT NULL REFERENCES prestataires.article (id) ON DELETE RESTRICT,
    -- Prix VERROUILLÉ par prestataires::figer_prix dans la MÊME transaction (III).
    prix_fige_id   uuid NOT NULL REFERENCES prestataires.prix_fige (id) ON DELETE RESTRICT,
    quantite       smallint NOT NULL CHECK (quantite > 0),
    preference     commandes.preference_substitution NOT NULL DEFAULT 'appeler',
    statut         commandes.statut_ligne NOT NULL DEFAULT 'presente',
    -- Arrêt qui collecte cette ligne (toujours de type 'collecte').
    arret_id       uuid REFERENCES commandes.arret (id) ON DELETE SET NULL,
    -- Remplacement accepté (CMD-06) — TOUJOURS chez le même vendeur.
    remplace_par_article_id uuid REFERENCES prestataires.article (id) ON DELETE RESTRICT,
    remplace_prix_unites    bigint CHECK (remplace_prix_unites IS NULL OR remplace_prix_unites >= 0),
    cree_le        timestamptz NOT NULL DEFAULT now(),
    CHECK (statut <> 'remplacee' OR remplace_par_article_id IS NOT NULL)
);

CREATE INDEX ligne_par_commande ON commandes.ligne_commande (commande_id);
CREATE INDEX ligne_par_arret    ON commandes.ligne_commande (arret_id) WHERE statut = 'presente';
```

### 2.5 Détails de vertical — `resto_details` derrière `ServiceWorkflow`

```sql
-- Constitution II : AUCUN champ spécifique à un vertical dans le tronc.
CREATE TABLE commandes.resto_details (
    commande_id           uuid PRIMARY KEY REFERENCES commandes.commande (id) ON DELETE CASCADE,
    delai_preparation_min smallint,        -- copié du prestataire à la création
    -- Hooks d'acceptation vendeur (VAP, tranche T4) : colonnes POSÉES, aucune
    -- logique ce cycle — provision au sens constitution IX.
    acceptee_le           timestamptz,
    refus_motif_cle       text
);
```

### 2.6 Substitutions

```sql
CREATE TABLE commandes.substitution (
    id            uuid PRIMARY KEY,
    ligne_id      uuid NOT NULL REFERENCES commandes.ligne_commande (id) ON DELETE CASCADE,
    arret_id      uuid NOT NULL REFERENCES commandes.arret (id) ON DELETE CASCADE,
    -- Article proposé — la garde « même vendeur » est vérifiée à l'écriture (FR-048).
    article_propose_id uuid NOT NULL REFERENCES prestataires.article (id) ON DELETE RESTRICT,
    prix_propose_unites bigint NOT NULL CHECK (prix_propose_unites >= 0),
    photo_cle     text NOT NULL,                     -- clé S3 (rétention de zone)
    proposee_le   timestamptz NOT NULL DEFAULT now(),
    echeance      timestamptz NOT NULL,              -- proposée + délai de zone (60 s) — R10
    issue         commandes.issue_substitution NOT NULL DEFAULT 'en_attente',
    decidee_le    timestamptz,
    uuid_client   uuid NOT NULL,                     -- idempotence de la proposition (V)
    UNIQUE (uuid_client)
);

-- Balayage du job d'expiration (R10).
CREATE INDEX substitution_echeance ON commandes.substitution (echeance)
    WHERE issue = 'en_attente';
```

### 2.7 Issues d'échec — l'arbre §7.5 rendu testable

```sql
CREATE TABLE commandes.issue_echec (
    id            uuid PRIMARY KEY,
    commande_id   uuid NOT NULL REFERENCES commandes.commande (id) ON DELETE CASCADE,
    arret_id      uuid REFERENCES commandes.arret (id) ON DELETE SET NULL,  -- NULL = à la remise
    type_issue    commandes.type_issue_echec NOT NULL,
    -- « Chaque issue journalise qui détient l'argent et la marchandise » (CMD-08).
    detenteur_argent      commandes.detenteur NOT NULL,
    detenteur_marchandise commandes.detenteur NOT NULL,
    montant_en_jeu_unites bigint NOT NULL DEFAULT 0 CHECK (montant_en_jeu_unites >= 0),
    devise        text NOT NULL,
    indemnisation_due     boolean NOT NULL DEFAULT false,   -- → événement, caisse = CRS-06
    litige_ouvert         boolean NOT NULL DEFAULT false,   -- → événement, dossier = AVI-04
    sanction      commandes.sanction NOT NULL DEFAULT 'aucune',
    motif_cle     text NOT NULL,                            -- clé i18n fr, jamais de texte libre
    acteur        uuid NOT NULL REFERENCES comptes.compte (id) ON DELETE RESTRICT,
    cree_le       timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX issue_par_commande ON commandes.issue_echec (commande_id);
```

## 3. Machine à états — table de transitions fermée

Garde unique consultant une constante Rust ; toute transition **absente** est refusée (`409`). Un test d'intégration par ligne (SC-002).

### 3.1 Tronc (`etat_commande`)

| Depuis | Vers | Déclencheur | Acteur |
|---|---|---|---|
| — | `nouvelle` | création, paiement cash autorisé | client |
| — | `en_attente_paiement` | création, prépaiement requis | client |
| `en_attente_paiement` | `nouvelle` | paiement confirmé | système (PAY, simulé) |
| `en_attente_paiement` | `annulee` | expiration ou annulation | système / client |
| `nouvelle` | `en_attente_coursier` | aucun coursier éligible | système (DSP, simulé) |
| `nouvelle` | `en_cours` | livraison assignée | système (DSP, simulé) |
| `en_attente_coursier` | `en_cours` | reprise FIFO | système (DSP, simulé) |
| `en_attente_coursier` | `annulee` | annulation **sans frais** | client / admin |
| `nouvelle` | `annulee` | annulation **sans frais** | client / admin |
| `en_cours` | `terminee` | remise effectuée | coursier |
| `en_cours` | `annulee` | annulation (règles CMD-08 si ≥ 1 collecte) | client / admin |
| `en_cours` | `echouee` | échec déclaré, **preuves réunies** | coursier |

### 3.2 Livraison (`etat_livraison`)

| Depuis | Vers | Déclencheur |
|---|---|---|
| — | `assignee` | affectation d'un coursier |
| `assignee` | `en_collecte` | premier arrêt passé `en_route` |
| `en_collecte` | `en_livraison` | **toutes les collectes résolues** (gating corrigé, R4) |
| `en_livraison` | `livree` | remise validée (QR, code ou dépôt) |
| `assignee`/`en_collecte`/`en_livraison` | `annulee` | annulation de la commande |
| `en_livraison` | `echouee` | échec déclaré avec preuves |

### 3.3 Arrêt (`statut_arret`)

| Depuis | Vers | Déclencheur | Idempotence |
|---|---|---|---|
| `a_collecter` | `en_route` | départ vers l'arrêt | UUID client |
| `en_route` | `arrive` | arrivée géolocalisée (`arrive_le` → prime d'attente) | UUID client |
| `arrive` | `collecte` | **scan QR ou code de secours** (cycle 006, inchangé) | UUID client |
| `arrive` | `indisponible` | toutes les lignes de l'arrêt retirées/refusées | UUID client |
| `a_collecter`/`en_route` | `indisponible` | vendeur fermé constaté | UUID client |

> Le chemin `a_collecter → collecte` **directement** reste accepté : c'est celui du cycle 006 et il ne doit pas régresser (le coursier peut scanner sans avoir déclaré son trajet).

## 4. Pipeline de création (`POST /commandes`)

Ordre **exact**. Les étapes 1 à 6 sont **hors transaction** (dont l'appel réseau OSRM, R11) ; 7 à 16 sont dans **une seule** transaction.

1. Rejet si le compte porte `bloque` (port `RestrictionsCompte`).
2. Résolution de la configuration de zone : `mixable`, `perissable`, plafonds cash, devise, délais.
3. Validation du panier : catégorie unique et mixable, sinon **refus avec proposition de scission**.
4. Validation de l'adresse : repère **texte ≥ N caractères OU vocal** présent, téléphone vérifié.
5. Vérification de commandabilité de **chaque** vendeur (`Commandabilite`) et de disponibilité de chaque article.
6. `OptimisationArrets::optimiser` puis `EvaluationTarifaire::evaluer` → **devis figé** + ordre.
7. **BEGIN**.
8. Insertion du tronc avec `id = Idempotency-Key` (conflit → rejeu idempotent, R7).
9. `prestataires::figer_prix` pour **chaque** article → `prix_fige_id`.
10. Insertion des lignes avec leur préférence de substitution.
11. Insertion de `resto_details` si la catégorie l'exige (`ServiceWorkflow`).
12. Insertion de la livraison + copie du devis figé.
13. Insertion du segment (ordre 0) puis des arrêts : collectes **dans l'ordre optimisé**, puis la **remise**.
14. Rattachement de chaque ligne à son arrêt.
15. Génération du code (4 chiffres) et du jeton, calcul des **empreintes** (`qr::verification`).
16. Décision de paiement (cash sous plafond, sinon prépaiement) → `etat` initial.
17. `comptes::marquer_adresse_utilisee` (avance la rétention).
18. Événements `commande.creee`, `livraison.creee` et (`commande.prete_a_dispatcher` ou `commande.paiement_requis`).
19. **COMMIT**.

## 5. Traits exposés et ports consommés

```rust
// ── OFFERTS aux cycles suivants ────────────────────────────────────────────

/// Vertical de service — constitution II. Toute spécificité passe par là.
pub trait ServiceWorkflow: Send + Sync {
    fn slug(&self) -> &'static str;
    /// Garde propre au vertical, appliquée AVANT écriture (ex. mono-vendeur).
    fn valider_creation(&self, panier: &PanierValide) -> Result<(), ErreurCommandes>;
    /// Détails à insérer (resto_details) — `None` si le vertical n'en a pas.
    fn details(&self, panier: &PanierValide) -> Option<DetailsVertical>;
}

/// Lecture/écriture consommée par DSP (dispatch) — non construit ce cycle.
#[async_trait]
pub trait CommandesADispatcher: Send + Sync {
    /// File FIFO par âge des commandes sans coursier (CMD-10).
    async fn en_attente_coursier(&self, zone: Uuid) -> Result<Vec<CommandeADispatcher>, ErreurCommandes>;
    /// Affecte un coursier : crée la livraison `assignee`, passe le tronc `en_cours`.
    async fn affecter(&self, commande: Uuid, coursier: Uuid) -> Result<(), ErreurCommandes>;
}

// ── CONSOMMÉS (implémentés ailleurs ou simulés) ────────────────────────────

/// Restrictions CPT-06 — implémenté dans le crate `comptes` (R12).
#[async_trait]
pub trait RestrictionsCompte: Send + Sync {
    async fn restrictions(&self, compte: Uuid) -> Result<Restrictions, ErreurCommandes>;
    async fn poser_restriction(
        &self, tx: &mut sqlx::PgTransaction<'_>, compte: Uuid,
        sanction: Sanction, motif_cle: &str,
    ) -> Result<(), ErreurCommandes>;
}

/// Preuves d'échec CRS-05 — double `PreuvesFixes` ce cycle (R16).
#[async_trait]
pub trait PreuvesEchec: Send + Sync {
    async fn preuves_reunies(&self, livraison: Uuid) -> Result<bool, ErreurCommandes>;
}

/// Dernière position connue du coursier + son ÂGE (Redis éphémère, R13).
#[async_trait]
pub trait PositionCoursier: Send + Sync {
    async fn derniere(&self, coursier: Uuid) -> Result<Option<PositionDatee>, ErreurCommandes>;
}
```

Traits **consommés** des cycles précédents, sans modification : `zones::ConfigurationZones`, `tarification::{EvaluationTarifaire, OptimisationArrets}`, `prestataires::{figer_prix, articles_commandables_de, Commandabilite}`, `comptes::marquer_adresse_utilisee`, `qr::verification::{empreinte_code, empreinte_jeton}`, `socle::{ecrire_evenement, DepotObjets}`.

## 6. Paramètres de zone à seeder — `60_commandes_parametres.sql`

Aucune valeur en dur (constitution I). `categorie.<slug>.mixable` est **déjà seedé** (cycle 002).

| Clé | Défaut Tiassalé | Exigence |
|---|---|---|
| `categorie.restauration.perissable` | `true` | FR-059, R15 |
| `categorie.<autres>.perissable` | `false` | FR-059 |
| `commande.plafond_cash_unites` | `15000` | FR-024 |
| `commande.plafond_cash_restauration_sans_historique_unites` | `5000` | FR-024 |
| `commande.historique_min_commandes_terminees` | `1` | FR-024 — en deçà, le client est « sans historique » ; seules les commandes **terminées** comptent |
| `commande.repere_texte_min_caracteres` | `10` | FR-018 |
| `commande.essais_code_livraison` | `3` | CRS-04 |
| `substitution.delai_validation_s` | `60` | FR-045 |
| `substitution.ecart_prix_max_pourcent` | `20` | FR-047 |
| `substitution.photo_retention_jours` | `365` | VIII |
| `suivi.position_periode_s` | `30` | FR-040 |
| `commande.escalade_attente_coursier_s` | `300` | FR-038 |

## 7. Événements outbox

Tous écrits **dans la même transaction** que leur transition (constitution VI), déclarés dans `docs/taxonomie-evenements.md` **avant** implémentation. Propriétés standard (`zone`, `categorie`, `role`, `version_app`) systématiques ; **aucune coordonnée brute** (minimisation ARTCI).

| Événement | Entité | Charge utile spécifique |
|---|---|---|
| `commande.creee` | `commande` | `nb_vendeurs`, `nb_articles`, `montant_articles`, `total`, `devise`, `mode_paiement`, `mono_vendeur` |
| `commande.paiement_requis` | `commande` | `motif` (`plafond` \| `prepaiement_impose` \| `restauration_sans_historique`), `total` |
| `commande.prete_a_dispatcher` | `commande` | `nb_arrets`, `montant_a_avancer`, `transport_requis` — **consommé par DSP** |
| `commande.mise_en_attente_coursier` | `commande` | `motif`, `age_s` |
| `commande.assignee` | `commande` | `livraison`, `coursier` |
| `commande.terminee` | `commande` | `mode_remise`, `duree_totale_s`, `total_encaisse` |
| `commande.annulee` | `commande` | `par` (`client` \| `admin`), `motif_cle`, `sans_frais`, `part_coursier_due` |
| `commande.echec_declare` | `commande` | `type_issue`, `preuves_ok` |
| `panier.scission_proposee` | `commande` (virtuel) | `cause` (`categorie_non_mixable` \| `plafond_eclatement`), `nb_commandes` — **métrique SC-006** |
| `livraison.creee` | `livraison` | `nb_arrets`, `devis_prix_client`, `devis_part_coursier`, `degraded` |
| `livraison.affectee` | `livraison` | `coursier`, `delai_assignation_s` |
| `livraison.livree` | `livraison` | `mode_remise`, `essais_code` |
| `arret.en_route` | `arret` | `commande`, `ordre` |
| `arret.arrive` | `arret` | `commande`, `attente_depuis_s` — **base de la prime d'attente TRF-06** |
| `arret.collecte` | `arret` | *(existant, cycle 006 — inchangé)* |
| `arret.indisponible` | `arret` | `commande`, `nb_lignes_retirees`, `motif` |
| `livraison.mise_en_livraison` | `livraison` | *(existant, cycle 006 — inchangé)* |
| `substitution.proposee` | `substitution` | `ligne`, `ecart_pourcent`, `echeance_s` |
| `substitution.decidee` | `substitution` | `issue`, `delai_reponse_s` |
| `ligne.retiree` | `ligne_commande` | `motif` (`preference` \| `expiration` \| `refus`), `montant_retire` |
| `appel.intention` | `commande` | `de` (`client` \| `coursier`), `vers`, `motif` |
| `echec.issue_enregistree` | `issue_echec` | `type_issue`, `detenteur_argent`, `detenteur_marchandise`, `montant_en_jeu` |
| `litige.ouvert` | `issue_echec` | `type_issue`, `arret` — **contrat pour AVI-04** (sans consommateur) |
| `indemnisation.due` | `issue_echec` | `coursier`, `montant`, `devise` — **contrat pour CRS-06** (sans consommateur) |
| `sanction.posee` | `compte` | `sanction`, `motif_cle`, `rang` (1ᵉʳ ou 2ᵉ refus) |

## 8. Cache client (drift) — deux tables locales

```dart
class BrouillonPanier extends Table { /* contenu JSON, total estimé, zone, maj */ }
class CommandeCache  extends Table {
  // id, dernier état connu, progression (collectées / total), code, jeton QR,
  // dernière position + son âge, horodatage de mise à jour.
}
```

Providers **générés** (constitution XII) : `Notifier<EtatPanier>` `keepAlive` pour le brouillon (porteur de processus) ; `AsyncNotifier` pour la liste des commandes et le suivi (chargements). `retry: pasDeRetry` sur toute portée. Le bloc « À la livraison » (code + QR) se rend **uniquement** depuis `CommandeCache` — aucun appel réseau sur ce chemin.
