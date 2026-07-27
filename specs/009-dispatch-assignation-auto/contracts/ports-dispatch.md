# Contrat — traits et structures exposés/consommés par `dispatch` (cycle 009)

Le crate `dispatch` est un **domaine pur** : il porte sqlx et son schéma
(`PgDispatch`), et tout le reste passe par des traits doublables (constitution II).
Signatures indicatives — le contrat qui compte est la **forme** des ports et le
sens des issues, pas la ponctuation.

---

## 1. Offerts par `dispatch`, implémentés dans `backend/api`

### `PoolCoursiers` — l'index éphémère (implémentation Redis, double mémoire)

```rust
#[async_trait]
pub trait PoolCoursiers: Send + Sync {
    /// Écrit les TROIS clés (position historique, hash d'état, index GEO) et
    /// repousse la durée de vie. `coursier:pos:{id}` garde le format du cycle
    /// 008 — le suivi client le lit (data-model §2).
    async fn publier(&self, i: &InscriptionPool, ttl: Duration) -> Result<(), ErreurPool>;

    /// Sortie IMMÉDIATE (FR-005) : supprime le hash et retire du GEO.
    async fn retirer(&self, coursier: Uuid, zone: Uuid) -> Result<(), ErreurPool>;

    /// Pré-filtre géographique — vol d'oiseau, donc sûr par construction : il
    /// MINORE la route et ne peut pas écarter à tort (R5).
    async fn dans_rayon(&self, zone: Uuid, lat: f64, lon: f64, rayon_m: i64)
        -> Result<Vec<Uuid>, ErreurPool>;

    /// TOUS les membres de l'index d'une zone, sans centre ni rayon — la
    /// « carte des coursiers » de l'exploitation (FR-006) demande « qui est en
    /// ligne », pas « qui est près d'ici », et n'a aucun centre à proposer.
    /// L'index GEO de Redis est un zset : `ZRANGE 0 -1` sait l'énumérer.
    /// Rend les membres BRUTS, fantômes compris — c'est `etat` qui tranche.
    async fn membres(&self, zone: Uuid) -> Result<Vec<Uuid>, ErreurPool>;

    /// État d'un coursier, ou `None` s'il est sorti du pool. `None` n'est
    /// JAMAIS une erreur — Redis muet doit dégrader, pas casser.
    async fn etat(&self, coursier: Uuid) -> Result<Option<InscriptionPool>, ErreurPool>;

    /// Élague les membres GEO sans hash (fantômes — Redis n'expire pas par
    /// membre de zset). Appelé par le tic, et paresseusement à la lecture.
    async fn elaguer(&self, zone: Uuid) -> Result<usize, ErreurPool>;
}
```

### `VerrouOffre` — l'exclusivité double (script Lua, R3)

```rust
/// Trois issues, pas deux : les deux refus ne conduisent PAS au même
/// comportement (FR-057 — passer au candidat suivant vs abandonner ce passage).
pub enum PoseVerrou { Obtenu, CommandeDejaOfferte, CoursierDejaPorteur }

#[async_trait]
pub trait VerrouOffre: Send + Sync {
    /// Pose les deux verrous ATOMIQUEMENT — les deux, ou aucun (FR-056).
    async fn poser(&self, commande: Uuid, coursier: Uuid, jeton: Uuid, ttl: Duration)
        -> Result<PoseVerrou, ErreurVerrou>;

    /// Libère les deux, et SEULEMENT si le jeton correspond : on ne libère
    /// jamais un verrou qu'on ne détient pas.
    async fn liberer(&self, commande: Uuid, coursier: Uuid, jeton: Uuid)
        -> Result<(), ErreurVerrou>;
}
```

---

## 2. Consommés par `dispatch`

### `CommandesADispatcher` — **étendu**, pas remplacé

Le cycle 008 a créé ce trait dans `commandes::ports` en le documentant « Contrat
offert à DSP ». Quatre méthodes s'y ajoutent plutôt que dans un second trait qui
découperait le même contrat en deux. **Aucune dépendance inverse** :
`commandes` ne dépendra jamais de `dispatch` (R19).

```rust
#[async_trait]
pub trait CommandesADispatcher: Send + Sync {
    // ── existant (cycle 008), inchangé ────────────────────────────────────
    async fn en_attente_coursier(&self, zone: Uuid)
        -> Result<Vec<CommandeADispatcher>, ErreurCommandes>;
    async fn affecter(&self, commande: Uuid, coursier: Uuid) -> Result<Uuid, ErreurCommandes>;

    // ── ajouté par le cycle 009 ───────────────────────────────────────────
    /// Course active d'un coursier (FR-007, FR-016). `None` = offreable.
    async fn course_active(&self, coursier: Uuid) -> Result<Option<Uuid>, ErreurCommandes>;

    /// Fin de la dernière course livrée — base de l'inactivité (FR-036).
    /// `None` = jamais livré : l'inactivité part de l'entrée dans le pool.
    async fn fin_derniere_course(&self, coursier: Uuid)
        -> Result<Option<DateTime<Utc>>, ErreurCommandes>;

    /// Capacités requises d'une commande, lues sur la LIVRAISON (R9, FR-017).
    async fn capacites_requises(&self, commande: Uuid)
        -> Result<Vec<Capacite>, ErreurCommandes>;

    /// Ce que la réassignation doit savoir avant de retirer quoi que ce soit :
    /// nombre d'arrêts collectés (FR-075 — > 0 interdit l'automatisme), délai de
    /// préparation annoncé (FR-072) et position du premier arrêt non résolu.
    async fn etat_progression(&self, livraison: Uuid)
        -> Result<EtatProgression, ErreurCommandes>;

    /// Retire le coursier et remet la commande dans le pipeline :
    /// `livraison.coursier_id = NULL`, tronc `en_cours → en_attente_coursier`
    /// (data-model §3), événement dans la même transaction.
    async fn retirer_coursier(&self, livraison: Uuid, horodatage: DateTime<Utc>)
        -> Result<(), ErreurCommandes>;

    /// Bascule cash → mobile money après création (FR-026) : tronc
    /// `nouvelle → en_attente_paiement`, `mode_paiement = mobile_money`.
    /// AUCUN chemin partiel — un seul montant, un seul état (constitution III).
    async fn exiger_prepaiement(&self, commande: Uuid, motif: MotifPrepaiement)
        -> Result<(), ErreurCommandes>;
}
```

### `EtatCoursier` — implémenté dans `comptes`

```rust
#[async_trait]
pub trait EtatCoursier: Send + Sync {
    /// Rôle coursier VALIDE, compte non bloqué, véhicules déclarés.
    /// `None` = pas un coursier exploitable. DSP ne cite JAMAIS `comptes.*`
    /// (patron `RestrictionsCompte` du cycle 008).
    async fn coursier(&self, compte: Uuid) -> Result<Option<CoursierExploitable>, ErreurCoursier>;
}

pub struct CoursierExploitable {
    pub compte: Uuid,
    pub zone: Uuid,
    pub capacites: Vec<Capacite>,   // depuis comptes.vehicule_declare
}
```

### `NotePrestataire` — **sans implémentation** (AVI non construit, R7)

```rust
#[async_trait]
pub trait NotePrestataire: Send + Sync {
    /// Note en CENTIÈMES (barème sur 5 → `450` = 4,50), ou `None`.
    /// `None` a DEUX conséquences opposées, toutes deux voulues :
    /// palier d'ENTRÉE pour le plafond d'avance, valeur NEUTRE pour le score.
    async fn note_centiemes(&self, compte: Uuid) -> Result<Option<i32>, ErreurNote>;
}

/// Impl de PRODUCTION tant qu'AVI n'existe pas — ce n'est pas un bouchon
/// menteur, c'est l'état exact du monde (patron `AucuneCommandeActive` du
/// cycle 005).
pub struct NoteAbsente;
```

### `PairesBloquees` — **sans implémentation** (CRS-07, P1, R8)

```rust
#[async_trait]
pub trait PairesBloquees: Send + Sync {
    /// Contreparties bloquées avec ce coursier, en UN aller-retour : une course
    /// a 1 client + n vendeurs, et un appel par arrêt multiplierait la latence
    /// du chemin le plus sensible du produit.
    async fn bloquees(&self, coursier: Uuid, contreparties: &[Uuid])
        -> Result<HashSet<Uuid>, ErreurPaires>;
}

pub struct AucunePaireBloquee;   // impl de production avant CRS-07
```

### `NotificationsDispatch` — **le contrat d'émission** (FR-094, sans implémentation)

C'est le port que cinq exigences invoquent : offre au coursier (FR-046), non-réponse
non pénalisée (FR-053), bascule prépaiement notifiée à la cliente (FR-026), escalade
vers l'exploitation **et** annulation sans frais offerte à la cliente (FR-064,
FR-065), retrait notifié aux deux parties (FR-073).

```rust
/// Destinataire et canal. Les trois canaux de NTF-01 (« client normal ; coursier
/// haute importance, sonnerie prolongée ; vendeur ») sont NOMMÉS ici pour que le
/// module de notifications s'y branche sans changer le contrat.
pub enum Canal { CoursierHautePriorite, Client, Exploitation }

/// Ce que le dispatch demande d'annoncer. Porte des CLÉS i18n et des données
/// typées — JAMAIS de texte rendu (constitution VII), JAMAIS de coordonnée ni de
/// numéro (FR-088).
pub struct Annonce {
    pub canal: Canal,
    pub destinataire: Uuid,          // compte ; `Exploitation` = destinataire nul
    pub cle_i18n: String,            // ex. « dispatch.offre.nouvelle »
    pub commande: Option<Uuid>,
    pub offre: Option<Uuid>,
    /// Variables typées de la clé (montants entiers + devise, délais en secondes,
    /// compteurs). Aucune chaîne pré-formatée.
    pub variables: serde_json::Value,
    /// Vrai quand l'annonce ouvre un droit : « annulation sans frais » (FR-065).
    pub action_annulation_sans_frais: bool,
}

#[async_trait]
pub trait NotificationsDispatch: Send + Sync {
    /// N'ouvre AUCUNE socket et ne rend JAMAIS d'erreur fatale : une annonce
    /// perdue ne doit pas annuler une affectation déjà écrite. L'échec est
    /// journalisé, la transaction métier tient.
    async fn annoncer(&self, annonce: Annonce);
}

/// Impl de PRODUCTION tant que NTF-01 n'existe pas : journalise l'annonce
/// (canal, clé, destinataire) et s'arrête là. Ce n'est pas un bouchon menteur —
/// c'est l'état exact du monde avant le module de notifications, et c'est
/// pourquoi l'app VA CHERCHER son offre (R16) au lieu d'être réveillée.
pub struct AnnoncesJournalisees;

/// Double de test : retient les annonces pour qu'un test puisse asserter
/// « la cliente a été prévenue avec le motif, et l'annulation sans frais lui a
/// été offerte » — ce que SC-006 et SC-012 exigent de vérifier.
pub struct NotificationsCollectees { /* Mutex<Vec<Annonce>> */ }
```

### `ProximiteRoutiere` — au-dessus de `tarification` (R5)

```rust
#[async_trait]
pub trait ProximiteRoutiere: Send + Sync {
    /// UNE matrice pour TOUS les candidats (jamais un appel par candidat,
    /// FR-035). Ne rend JAMAIS d'erreur : l'implémentation s'appuie sur
    /// `tarification::routage::matrice_ou_degrade`, qui retombe sur le vol
    /// d'oiseau ×1,4 `degraded=true` journalisé — une commande n'est jamais
    /// bloquée par le routage (constitution IV, FR-030).
    async fn vers_point(&self, origines: &[Point], destination: Point) -> Trajets;

    /// Les `n − 1` tronçons CONSÉCUTIFS d'un itinéraire (`p0→p1`, `p1→p2`, …),
    /// depuis UNE seule matrice — les distances inter-arrêts de l'écran K2.
    /// Sans elle, un itinéraire se mesure tronçon par tronçon, c'est-à-dire une
    /// requête de routage par arrêt, et le cache par tronçon du cycle 007 ne les
    /// absorbe pas : il ne réchauffe jamais coursier→vendeur, qui part d'une
    /// position mobile. Rend des `Trajets` et non une `Matrice` : l'appelant n'a
    /// besoin que de la diagonale adjacente, et le domaine n'a pas à connaître
    /// l'indexation d'un moteur de routage.
    async fn troncons_consecutifs(&self, zone: Uuid, points: &[Point]) -> Trajets;
}

pub struct Trajets {
    /// Une entrée par origine (`vers_point`) ou par tronçon
    /// (`troncons_consecutifs`), dans l'ORDRE fourni.
    pub trajets: Vec<Trajet>,
    pub degraded: bool,
}
pub struct Trajet { pub distance_m: i64, pub duree_s: i64 }
```

---

## 3. Surface publique du crate `dispatch`

```rust
pub use pipeline::{DecisionPipeline, Pipeline};        // évaluer → offrir → conclure
pub use eligibilite::{EcartEligibilite, MotifEcart};
pub use scoring::{Composantes, Candidat, Poids};
pub use offre::{Offre, IssueOffre, ModeOffre};
pub use reprise::{MotifReassignation, Reprise};
pub use depot::PgDispatch;
pub use ports::{ /* offerts */ PoolCoursiers, VerrouOffre, PoseVerrou,
                 /* consommés */ EtatCoursier, NotePrestataire, PairesBloquees,
                 ProximiteRoutiere, NotificationsDispatch, Annonce, Canal,
                 /* impls de production avant AVI/CRS-07/NTF-01 */
                 NoteAbsente, AucunePaireBloquee, AnnoncesJournalisees,
                 /* doubles de test */ MemoirePool, VerrouMemoire, CoursierFixe,
                 PairesSimulees, ProximiteFixe, NotificationsCollectees };
pub use tic::{ResultatTic, Tic};                       // ce que le job périodique exécute
```

**Un seul point de sortie du pipeline.** `DecisionPipeline` énumère tout ce qu'un
passage peut décider — `OffreEmise`, `BroadcastOuvert`, `BasculePrepaiement`,
`MiseEnFile`, `RienAFaire`. Un seul type de retour, donc un seul endroit à tester
et un seul endroit où les événements sont écrits.

---

## 4. Consommateur outbox et tic — le câblage dans `backend/api`

```rust
/// PREMIER consommateur outbox réel du produit : `WorkerOutbox::new(pool, vec![])`
/// tourne aujourd'hui avec zéro consommateur (`lib.rs:325`).
pub struct DispatchOutbox { /* PgDispatch + ports */ }

#[async_trait]
impl ConsommateurOutbox for DispatchOutbox {
    fn nom(&self) -> &'static str { "dispatch" }

    /// ⚠ Ne rend `Err` QUE sur une panne d'infrastructure récupérable. Toute
    /// issue métier — aucun éligible, bascule prépaiement, pool vide — est un
    /// SUCCÈS écrit en base. Un `Err` fait rejouer l'événement indéfiniment
    /// (`worker.rs:143`) : une commande sans coursier bloquerait sa propre
    /// ligne d'outbox pour toujours (R1).
    async fn consommer(&self, e: &EvenementPublie) -> Result<(), ConsommationError> {
        match e.type_evenement.as_str() {
            "commande.prete_a_dispatcher" | "commande.paiement_confirme" => { /* évaluer */ }
            _ => Ok(()),          // idempotent, indifférent au reste du journal
        }
    }
}
```

Le **tic** (`job_tic_dispatch`, intervalle 5 s, patron `job_expirer_substitutions`
de `lib.rs:234`) exécute dans l'ordre, par zone :

1. expiration des offres échues → non-réponse (franche ou non) → candidat suivant ;
2. ouverture de broadcast (candidats épuisés **ou** délai) ;
3. reprise FIFO des commandes en attente ;
4. escalade (`PgCommandes::escalader_attentes` — aujourd'hui **planifiée nulle
   part**, R14) ;
5. réassignations (sans mouvement / sans scan), garde d'arrêt collecté ;
6. élagage des fantômes GEO.

Chaque étape est **idempotente** et rend un compte ; une erreur est journalisée et
retentée au passage suivant — un incident de tic ne fait jamais tomber l'API.
