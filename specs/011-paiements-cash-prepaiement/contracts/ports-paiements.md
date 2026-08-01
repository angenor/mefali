# Contrat — traits, structures et événements du cycle PAY 011

Ce que le cycle expose aux autres crates, et ce qu'il consomme. Aucun de ces
types ne porte de nom de fournisseur (FR-003).

---

## 1. `PaymentProvider` — la frontière réversible (PAY-05)

Défini dans `paiements::fournisseur`. **Rien de ce qui est propre à un agrégateur
ne franchit cette ligne.**

```rust
#[async_trait::async_trait]
pub trait PaymentProvider: Send + Sync {
    /// Identifiant stable, utilisé comme segment d'URL du webhook et stocké sur
    /// la transaction. Jamais interprété par une règle métier.
    fn nom(&self) -> &'static str;

    /// Ouvre un encaissement de la TOTALITÉ du montant dû (FR-002, FR-010).
    async fn create_checkout(&self, d: DemandeCheckout) -> Result<Checkout, ErreurFournisseur>;

    /// Vérifie la signature d'une notification et la traduit. SYNCHRONE : aucune
    /// I/O ne doit s'introduire dans ce chemin (research R3).
    fn verify_webhook(&self, e: &NotificationEntrante) -> Result<Notification, ErreurFournisseur>;

    /// PAY-04 (P1) — DÉFINIE, jamais appelée par ce cycle (FR-041).
    async fn refund(&self, d: DemandeRemboursement) -> Result<Remboursement, ErreurFournisseur>;

    /// Réconciliation avant annulation : un webhook perdu ne coûte ni la
    /// commande ni l'argent du client (FR-027, research R7).
    async fn consulter(&self, reference: &str) -> Result<Notification, ErreurFournisseur>;
}
```

### 1.1 Types d'échange

```rust
pub struct DemandeCheckout {
    pub reference_marchande: Uuid,   // = transaction.id — notre côté de la clé
    pub montant_unites: i64,         // ENTIER, unités mineures (constitution III)
    pub devise: String,              // ISO 4217 de la zone
    pub description_cle: &'static str,
    pub retour_succes: String,       // deep link d'app — informatif, ne crédite RIEN (FR-025)
    pub retour_annulation: String,
}

pub struct Checkout {
    pub reference_fournisseur: String,
    pub acces_paiement: String,      // URL — jamais journalisée, jamais événementielle
    pub expire_le: Option<DateTime<Utc>>,  // le nôtre prime s'il est plus court
}

pub struct NotificationEntrante<'a> {
    pub corps_brut: &'a [u8],        // BRUT : la signature se vérifie dessus (R6)
    pub entetes: &'a HeaderMap,
    pub recue_le: DateTime<Utc>,
}

pub struct Notification {
    pub reference_fournisseur: String,
    pub reference_marchande: Option<Uuid>,
    pub issue: IssuePaiement,
    pub montant_unites: i64,
    pub devise: String,
    pub moyen: Option<MoyenPaiement>,
    pub survenu_le: DateTime<Utc>,
    pub empreinte_charge: String,    // clé d'idempotence (R5)
}

pub enum IssuePaiement { Reussi, Echoue, Annule, EnCours }

pub enum MoyenPaiement { Wave, OrangeMoney, MtnMoMo, MoovMoney, Carte, Autre(String) }

pub enum ErreurFournisseur {
    SignatureInvalide,
    ChargeIllisible(String),
    Indisponible(String),        // → 502, la commande reste intacte (FR-018)
    RefuseParFournisseur(String),
    NonSupporte,                 // `refund` d'un fournisseur sans remboursement API
}
```

### 1.2 Implémentations livrées

| Type | Rôle | FR |
|---|---|---|
| `AgregateurHttp` | client HTTP paramétré (base, clé, secret, en-tête de signature) | FR-042 |
| `FournisseurSimule` | double pilotable : succès, échec, expiration, signature invalide, montant divergent, indisponibilité | FR-044 |
| `FournisseurAlternatif` (tests) | **second** vocabulaire, seconde signature — l'instrument de mesure de SC-010 | FR-042 |

---

## 2. Ce que `paiements` demande à `commandes` (port ajouté)

`commandes::ports` gagne un trait, sur le modèle de `CommandesADispatcher` :

```rust
#[async_trait::async_trait]
pub trait CommandesAPayer: Send + Sync {
    /// Total FIGÉ, devise et état — ce sur quoi la session s'ouvre.
    async fn a_payer(&self, commande: Uuid) -> Result<CommandeAPayer, ErreurCommandes>;

    /// Pose `etat_paiement = 'en_attente'` (research R16, FR-014).
    async fn marquer_paiement_en_attente(&self, commande: Uuid, quand: DateTime<Utc>)
        -> Result<(), ErreurCommandes>;

    /// Chemin EXISTANT du cycle 008 — `en_attente_paiement → nouvelle`,
    /// `etat_paiement = 'regle'`, événement `commande.paiement_confirme`.
    /// Ce cycle le BRANCHE, il ne le réécrit pas (FR-023, FR-032).
    async fn confirmer_prepaiement(&self, commande: Uuid, quand: DateTime<Utc>)
        -> Result<(), ErreurCommandes>;

    /// Chemin EXISTANT d'annulation, motif d'expiration (FR-031, FR-032).
    async fn annuler_pour_expiration(&self, commande: Uuid, quand: DateTime<Utc>)
        -> Result<(), ErreurCommandes>;
}

pub struct CommandeAPayer {
    pub commande_id: Uuid,
    pub zone_id: Uuid,
    pub client_id: Uuid,
    pub total_unites: i64,
    pub devise: String,
    pub mode_paiement: ModePaiement,
    pub etat: EtatCommande,
    pub etat_paiement: EtatPaiement,
}
```

Double de test fourni à côté (patron `ArretsFixes` / `PreuvesFixes` du cycle 010) :
`CommandesAPayerEnMemoire`, pour exercer `paiements` sans base.

---

## 3. Ce que `commandes` demande à `prestataires` (port ajouté)

```rust
// prestataires::depot
pub async fn offre_livraison(&self, prestataire: Uuid)
    -> Result<Option<tarification::OffreLivraison>, ErreurPrestataires>;
```

`None` = `jamais`. `commandes::panier::evaluer_panier` l'appelle **uniquement**
quand le panier est mono-vendeur, et transmet le résultat au devis — l'arbitrage
avec le drapeau de zone reste entier dans `tarification` (research R9, R10).

---

## 4. Consommateur outbox `PaiementsOutbox`

Adaptateur dans `backend/api`, logique dans `paiements` — patron `CaisseOutbox`
(cycle 010). Il reçoit **tout** le journal et ne réagit qu'à ce qui le concerne.

| Événement écouté | Effet | FR |
|---|---|---|
| `arret.collecte` avec `retenue_ecretee = true` | ouvre un dossier `retenue_ecretee` | FR-052 |
| `commande.annulee` avec `remboursement_du = true` | ouvre un dossier `remboursement_client_du` | FR-082, FR-111 |

⚠ Ne rend `Err` **que** sur une panne d'infrastructure récupérable : toute issue
métier est un succès écrit en base, sinon l'événement bloquerait sa propre ligne
d'outbox indéfiniment (contrat `socle`, patron `DispatchOutbox`).

## 5. Extension du consommateur `CaisseOutbox` (crate `coursier`)

`coursier::caisse::consommer_pour_caisse` gagne deux branches :

| Événement | Cas | Effet | FR |
|---|---|---|---|
| `livraison.livree` | **cash** | ajoute `frais_encaisses` (+ `total_du_client − Σ avances`, **pas** `devis_prix_client` — research R13) à côté du `remboursement` existant | FR-056 |
| `livraison.livree` | **cash, part non couverte** | crée la créance `part_course` = `max(P − max(frais_encaisses − M, 0), 0)` si elle est > 0 | FR-060, R13 |
| `livraison.livree` | **prépayée** | crée les créances `avance_prepayee` et `part_course` — remplace le `return Ok(())` documenté « avance laissée ouverte » | FR-063, SC-008 |

`creance.evenement_id UNIQUE` porte l'idempotence : un rejeu du worker ou d'une
fin de course hors-ligne ne crée jamais de doublon (FR-068).

---

## 6. Événements outbox émis — à déclarer dans `docs/taxonomie-evenements.md`

| Type | Entité | Émetteur | Propriétés |
|---|---|---|---|
| `paiement.session_ouverte` | `transaction` | `paiements::session` | `commande`, `montant`, `devise`, `fournisseur`, `expire_le` — **jamais** l'accès de paiement (FR-103) |
| `paiement.confirme` | `transaction` | `paiements::webhook` | `commande`, `montant`, `devise`, `moyen`, `delai_confirmation_s` |
| `paiement.echoue` | `transaction` | `paiements::webhook` | `commande`, `motif_cle`, `moyen` |
| `paiement.session_expiree` | `transaction` | `paiements::expiration` | `commande`, `montant`, `devise`, `duree_s` — **consommé par NTF** (FR-033) |
| `paiement.hors_delai` | `transaction` | `paiements::webhook` | `commande`, `montant`, `devise`, `retard_s` — **consommé par NTF** (FR-038) |
| `paiement.dossier_ouvert` | `dossier` | `paiements::dossier` | `type`, `commande`, `montant_constate`, `montant_attendu`, `motif_cle` |
| `caisse.creance_ouverte` | `creance` | `coursier::caisse` | `coursier`, `commande`, `nature`, `montant`, `devise` |
| `caisse.creance_reglee` | `creance` | `coursier::caisse` | `coursier`, `montant`, `devise`, `regle_par` |
| `vendeur.offre_livraison_modifiee` | `prestataire` | `prestataires::depot` | `offre`, `seuil`, `acteur` |

### 6.1 Événements existants **amendés**

| Type | Ajout | Raison |
|---|---|---|
| `arret.collecte` | `montant_articles`, `retenue_appliquee`, `retenue_ecretee` | R9 — `montant_avance` reste le **net**, la caisse ne change pas de lecture |
| `commande.terminee` | `total_du` distinct de `total_encaisse` (0 si prépayé) | R11 — le trou de `collecte.rs:767` |
| `caisse.mouvement` | les trois nouvelles natures apparaissent dans `type` | R13 — champ existant, valeurs nouvelles |

Aucun renommage, aucune suppression : les consommateurs existants (dispatch,
caisse) continuent de lire ce qu'ils lisaient.

---

## 7. Métriques dérivées (MET non construit — événements seulement)

| Indicateur | Dérivé de |
|---|---|
| Taux de conversion du prépaiement | `paiement.session_ouverte` → `paiement.confirme` |
| Délai médian de confirmation | `delai_confirmation_s` |
| Répartition par moyen de paiement | `moyen` de `paiement.confirme` |
| Taux d'expiration | `paiement.session_expiree` / `paiement.session_ouverte` |
| Exposition de créances | `caisse.creance_ouverte` − `caisse.creance_reglee` |
| Fréquence de la retenue vendeur | `arret.collecte` avec `retenue_appliquee > 0` |

Constitution VI : aucun KPI manuel, tout dérive du journal.

---

## 8. Configuration d'exécution ajoutée

| Variable | Défaut | Rôle |
|---|---|---|
| `PAIEMENT_FOURNISSEUR` | `simule` | sélectionne l'implémentation câblée |
| `PAIEMENT_BASE_URL` | — | requis si `agregateur` |
| `PAIEMENT_CLE_API` | — | requis si `agregateur` |
| `PAIEMENT_WEBHOOK_SECRET` | — | ≥ 32 octets, validé au démarrage comme `jwt_secret` (FR-045) |

Validation dans `socle::Config::valider` : un `agregateur` sans secret **échoue
au démarrage**, il n'encaisse pas dans le vide (patron `SmsMode` du cycle 003).
