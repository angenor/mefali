//! Ports du domaine dispatch (constitution II) — offerts et consommés.
//!
//! **Offerts** à la couche `api`, qui les implémente sur Redis :
//! [`PoolCoursiers`] (l'index éphémère) et [`VerrouOffre`] (l'exclusivité double
//! par script Lua, research R3).
//!
//! **Consommés**, implémentés ailleurs — ou **nulle part encore**, ce qui est
//! l'état exact du monde et non un manque :
//!
//! | Port | Implémenté par | Avant lui |
//! |---|---|---|
//! | [`EtatCoursier`] | `comptes` | — |
//! | [`NotePrestataire`] | AVI (non construit) | [`NoteAbsente`] |
//! | [`PairesBloquees`] | CRS-07 (P1) | [`AucunePaireBloquee`] |
//! | [`ProximiteRoutiere`] | `api`, au-dessus de `tarification` | — |
//! | [`NotificationsDispatch`] | NTF-01 (non construit) | [`AnnoncesJournalisees`] |
//!
//! Les trois impls « avant » ne sont pas des bouchons menteurs : ce sont les
//! réponses exactes du produit tant que leur cycle n'existe pas (patron
//! `AucuneCommandeActive` du cycle 005). C'est parce que `AnnoncesJournalisees`
//! n'ouvre aucune socket que l'app **va chercher** son offre (research R16).
//!
//! **Une seule famille d'erreur.** Tous les ports rendent [`ErreurDispatch`] :
//! le domaine n'a qu'un vocabulaire d'échec, et une panne d'infrastructure y
//! entre par `Dependance`. Multiplier les types d'erreur par port obligerait
//! chaque appelant à les reconvertir sans jamais changer sa décision.

use std::collections::{HashMap, HashSet};
use std::sync::Mutex;
use std::time::Duration;

use async_trait::async_trait;
use uuid::Uuid;

use crate::modele::{Capacite, ErreurDispatch, InscriptionPool};

// ══════════════════════════════════════════════════════════════════════════
// OFFERTS par `dispatch`, implémentés dans `backend/api`
// ══════════════════════════════════════════════════════════════════════════

/// L'index éphémère des coursiers en ligne (data-model §2).
///
/// **« Être dans le pool » = l'état du coursier existe.** L'index géographique
/// n'est qu'un pré-filtre : ses membres peuvent lui survivre (Redis n'expire pas
/// par membre de zset), d'où [`PoolCoursiers::elaguer`]. Un membre fantôme ne
/// reçoit jamais d'offre — l'éligibilité lit l'état **puis** confirme en
/// Postgres (research R12).
#[async_trait]
pub trait PoolCoursiers: Send + Sync {
    /// Écrit l'inscription et repousse sa durée de vie.
    ///
    /// L'implémentation Redis écrit TROIS clés : la position au format du cycle
    /// 008 (**inchangé** — le suivi client la lit), le hash d'état et l'index
    /// GEO.
    async fn publier(&self, i: &InscriptionPool, ttl: Duration) -> Result<(), ErreurDispatch>;

    /// Sortie IMMÉDIATE du pool (FR-005) — sans attendre l'expiration.
    async fn retirer(&self, coursier: Uuid, zone: Uuid) -> Result<(), ErreurDispatch>;

    /// Pré-filtre géographique en **vol d'oiseau**, sûr par construction : il
    /// MINORE la distance routière, donc il ne peut pas écarter un coursier
    /// réellement dans le rayon (research R5). Il ne décide rien — le test de
    /// rayon se fait sur la distance routière.
    async fn dans_rayon(
        &self,
        zone: Uuid,
        lat: f64,
        lon: f64,
        rayon_m: i64,
    ) -> Result<Vec<Uuid>, ErreurDispatch>;

    /// **Tous** les membres de l'index d'une zone, sans centre ni rayon.
    ///
    /// Ce que [`dans_rayon`](PoolCoursiers::dans_rayon) ne peut pas faire : il
    /// répond « qui est près d'ici », question du dispatch, alors que la « carte
    /// des coursiers » de l'exploitation (FR-006) demande « qui est en ligne »,
    /// et n'a aucun centre à proposer. L'approcher par un rayon très large
    /// écarterait en silence le coursier qui le dépasse — une carte qui ment par
    /// omission est pire qu'une carte absente.
    ///
    /// Rend les membres BRUTS, fantômes compris (research R2) : c'est
    /// [`etat`](PoolCoursiers::etat) qui dit lesquels sont vivants, exactement
    /// comme après un pré-filtre géographique.
    async fn membres(&self, zone: Uuid) -> Result<Vec<Uuid>, ErreurDispatch>;

    /// État d'un coursier, ou `None` s'il est sorti du pool.
    ///
    /// `None` n'est JAMAIS une erreur : un index muet doit dégrader, pas casser.
    async fn etat(&self, coursier: Uuid) -> Result<Option<InscriptionPool>, ErreurDispatch>;

    /// Élague les membres de l'index géographique sans état (fantômes) et rend
    /// leur nombre. Appelé par le tic, et paresseusement à la lecture.
    async fn elaguer(&self, zone: Uuid) -> Result<usize, ErreurDispatch>;
}

/// Issue d'une pose de double verrou — **trois** valeurs, pas deux.
///
/// Les deux refus ne conduisent pas au même comportement (FR-057) : un coursier
/// déjà porteur fait passer au candidat SUIVANT ; une commande déjà offerte fait
/// abandonner ce passage, parce qu'une autre évaluation la tient déjà.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PoseVerrou {
    /// Les deux verrous sont posés.
    Obtenu,
    /// Une autre évaluation tient déjà cette commande — abandonner ce passage.
    CommandeDejaOfferte,
    /// Ce coursier porte déjà une offre — passer au candidat suivant, sans
    /// attendre la conclusion de l'offre concurrente.
    CoursierDejaPorteur,
}

/// L'exclusivité **double** d'une offre (research R3).
#[async_trait]
pub trait VerrouOffre: Send + Sync {
    /// Pose les deux verrous ATOMIQUEMENT — les deux, ou aucun (FR-056).
    ///
    /// Le `jeton` est l'identifiant de l'offre : il rend la libération sûre.
    async fn poser(
        &self,
        commande: Uuid,
        coursier: Uuid,
        jeton: Uuid,
        ttl: Duration,
    ) -> Result<PoseVerrou, ErreurDispatch>;

    /// Pose le SEUL verrou de coursier — le mode **broadcast** (FR-062).
    ///
    /// Un broadcast offre la même course à plusieurs coursiers : verrouiller la
    /// commande à chaque destinataire empêcherait le second d'exister, et
    /// « demander à tout le monde » se réduirait à « demander à une personne de
    /// plus ». Ce qui doit rester exclusif, c'est l'**écran du coursier** :
    /// personne ne voit deux offres à la fois, et deux broadcasts concurrents se
    /// sérialisent ainsi au lieu de se disputer les destinataires.
    ///
    /// Rend `false` si le coursier porte déjà une offre.
    async fn poser_coursier(
        &self,
        coursier: Uuid,
        jeton: Uuid,
        ttl: Duration,
    ) -> Result<bool, ErreurDispatch>;

    /// Libère les deux, et SEULEMENT si le jeton correspond : on ne libère
    /// jamais un verrou qu'on ne détient pas — une offre échue puis reprise par
    /// un autre passage ne doit pas se faire effacer sous les pieds.
    async fn liberer(
        &self,
        commande: Uuid,
        coursier: Uuid,
        jeton: Uuid,
    ) -> Result<(), ErreurDispatch>;
}

// ══════════════════════════════════════════════════════════════════════════
// CONSOMMÉS par `dispatch`
// ══════════════════════════════════════════════════════════════════════════

/// Un coursier **exploitable** : rôle validé, compte non bloqué, véhicules
/// déclarés.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CoursierExploitable {
    /// Compte du coursier.
    pub compte: Uuid,
    /// Zone d'exercice déclarée.
    pub zone: Uuid,
    /// Capacités déclarées, lues de `comptes.vehicule_declare`.
    pub capacites: Vec<Capacite>,
}

/// État d'un coursier — **implémenté dans `comptes`**, dont c'est le schéma.
///
/// DSP ne cite JAMAIS `comptes.*` (patron `RestrictionsCompte` du cycle 008).
#[async_trait]
pub trait EtatCoursier: Send + Sync {
    /// `None` = pas un coursier exploitable (rôle non validé, compte bloqué).
    async fn coursier(&self, compte: Uuid) -> Result<Option<CoursierExploitable>, ErreurDispatch>;
}

/// Adaptateur de PRODUCTION : le dépôt du crate `comptes` satisfait le port.
///
/// Le trait est local à `dispatch`, le type est étranger — la règle d'orphelin
/// autorise cette implémentation, et c'est elle qui referme le montage : TOUTE
/// la SQL qui touche `comptes.*` vit dans le crate `comptes`
/// (`restriction::CoursierExploitablePar`), `dispatch` n'en écrit pas une
/// ligne. Patron `RestrictionsCompte for comptes::PgComptes` du cycle 008.
#[async_trait]
impl EtatCoursier for comptes::PgComptes {
    async fn coursier(&self, compte: Uuid) -> Result<Option<CoursierExploitable>, ErreurDispatch> {
        let Some(en_ligne) = comptes::CoursierExploitablePar::coursier_exploitable(self, compte)
            .await?
        else {
            return Ok(None);
        };
        Ok(Some(CoursierExploitable {
            compte: en_ligne.compte,
            zone: en_ligne.zone_id,
            capacites: en_ligne
                .transports
                .into_iter()
                .map(Capacite::transport)
                .collect(),
        }))
    }
}

/// Note d'un prestataire — **sans implémentation** tant qu'AVI n'existe pas.
#[async_trait]
pub trait NotePrestataire: Send + Sync {
    /// Note en CENTIÈMES (barème sur 5 → `450` = 4,50), ou `None`.
    ///
    /// `None` a DEUX conséquences opposées, toutes deux voulues (research R7) :
    /// palier d'**entrée** pour le plafond d'avance (c'est une exposition
    /// financière : un inconnu commence bas), valeur **neutre** pour le score
    /// (c'est un classement relatif : pénaliser un nouveau sur une note qu'il
    /// n'a pas eu l'occasion de mériter l'empêcherait d'en obtenir une).
    async fn note_centiemes(&self, compte: Uuid) -> Result<Option<i32>, ErreurDispatch>;
}

/// Impl de PRODUCTION tant qu'AVI n'existe pas — l'état exact du monde.
#[derive(Debug, Default, Clone, Copy)]
pub struct NoteAbsente;

#[async_trait]
impl NotePrestataire for NoteAbsente {
    async fn note_centiemes(&self, _compte: Uuid) -> Result<Option<i32>, ErreurDispatch> {
        Ok(None)
    }
}

/// Paires bloquées coursier ↔ contrepartie — **sans implémentation** (CRS-07).
#[async_trait]
pub trait PairesBloquees: Send + Sync {
    /// Contreparties bloquées avec ce coursier, en UN aller-retour.
    ///
    /// Une course a 1 client + n vendeurs : un appel par arrêt multiplierait la
    /// latence du chemin le plus sensible du produit (FR-025).
    async fn bloquees(
        &self,
        coursier: Uuid,
        contreparties: &[Uuid],
    ) -> Result<HashSet<Uuid>, ErreurDispatch>;
}

/// Impl de PRODUCTION avant CRS-07 : personne n'est bloqué, parce que rien ne
/// permet encore de bloquer.
#[derive(Debug, Default, Clone, Copy)]
pub struct AucunePaireBloquee;

#[async_trait]
impl PairesBloquees for AucunePaireBloquee {
    async fn bloquees(
        &self,
        _coursier: Uuid,
        _contreparties: &[Uuid],
    ) -> Result<HashSet<Uuid>, ErreurDispatch> {
        Ok(HashSet::new())
    }
}

/// Un trajet routier : distance et durée, **entiers** (research R6).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Trajet {
    /// Distance routière, mètres entiers.
    pub distance_m: i64,
    /// Durée de trajet, secondes entières.
    pub duree_s: i64,
}

/// Résultat d'une mesure de proximité — une entrée par origine, dans l'ORDRE
/// fourni.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Trajets {
    /// Trajets, dans l'ordre des origines.
    pub trajets: Vec<Trajet>,
    /// Vrai si la mesure vient du repli vol d'oiseau (constitution IV).
    pub degraded: bool,
}

/// Proximité routière — **une seule** matrice par évaluation.
///
/// Deux formes de mesure, parce que le domaine en a deux et **une seule
/// matrice** doit suffire à chacune (FR-035, research R5) :
///
/// - [`vers_point`](ProximiteRoutiere::vers_point) — « N origines → 1 point » :
///   le classement des candidats vers le premier arrêt de collecte ;
/// - [`troncons_consecutifs`](ProximiteRoutiere::troncons_consecutifs) — « un
///   itinéraire » : les distances inter-arrêts que l'offre affiche.
///
/// La seconde n'est pas un confort : sans elle, un itinéraire à trois arrêts
/// se mesure par trois appels successifs de la première, c'est-à-dire trois
/// requêtes de routage là où `/table` en rend une. Et le cache par tronçon du
/// cycle 007 ne les absorbe pas — il ne réchauffe jamais `coursier→vendeur`,
/// qui part d'une position mobile.
#[async_trait]
pub trait ProximiteRoutiere: Send + Sync {
    /// Jamais un appel par candidat (FR-035), et **jamais d'erreur** :
    /// l'implémentation s'appuie sur `tarification::routage::matrice_ou_degrade`,
    /// qui retombe sur le vol d'oiseau ×1,4 `degraded=true` journalisé. Une
    /// commande n'est jamais bloquée par le routage (constitution IV, FR-030).
    ///
    /// La `zone` porte les réglages de dégradé et de cache — hérités, jamais en
    /// dur (constitution I). Elle est un PARAMÈTRE et non un champ de
    /// l'implémentation : un dispatch multi-villes partage le même client de
    /// routage, mais pas les mêmes facteurs.
    async fn vers_point(
        &self,
        zone: Uuid,
        origines: &[tarification::Point],
        destination: tarification::Point,
    ) -> Trajets;

    /// Les tronçons **consécutifs** d'un itinéraire, en UNE seule matrice.
    ///
    /// Rend `points.len() - 1` trajets — `points[0]→points[1]`,
    /// `points[1]→points[2]`, … — dans cet ordre, et un vecteur vide pour moins
    /// de deux points.
    ///
    /// **Pourquoi des tronçons et non la matrice n×n.** L'appelant n'a besoin
    /// que de la diagonale adjacente ; lui rendre une `tarification::Matrice`
    /// ferait entrer un type d'infrastructure dans le vocabulaire du domaine et
    /// l'obligerait à connaître l'indexation ligne-majeur d'un moteur de
    /// routage. Le port promet ce que le domaine consomme, pas ce que
    /// l'implémentation calcule.
    async fn troncons_consecutifs(&self, zone: Uuid, points: &[tarification::Point]) -> Trajets;
}

/// Destinataire et canal d'une annonce.
///
/// Les trois canaux de NTF-01 (« client normal ; coursier haute importance,
/// sonnerie prolongée ; exploitation ») sont NOMMÉS ici pour que le module de
/// notifications s'y branche sans changer le contrat.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Canal {
    /// Coursier — haute priorité, sonnerie prolongée (NTF-01).
    CoursierHautePriorite,
    /// Cliente — priorité normale.
    Client,
    /// Exploitation — le destinataire est nul (personne nommée).
    Exploitation,
}

impl Canal {
    /// Représentation textuelle (journalisation, futur transport).
    pub fn comme_str(self) -> &'static str {
        match self {
            Canal::CoursierHautePriorite => "coursier_haute_priorite",
            Canal::Client => "client",
            Canal::Exploitation => "exploitation",
        }
    }
}

/// Ce que le dispatch demande d'annoncer.
///
/// Porte des **clés i18n** et des données **typées** — JAMAIS de texte rendu
/// (constitution VII), JAMAIS de coordonnée ni de numéro (FR-088).
#[derive(Debug, Clone, PartialEq)]
pub struct Annonce {
    /// Canal de remise.
    pub canal: Canal,
    /// Compte destinataire ; `None` pour l'exploitation.
    pub destinataire: Option<Uuid>,
    /// Clé i18n du message (ex. `dispatch.offre.nouvelle`).
    pub cle_i18n: String,
    /// Commande concernée, si l'annonce en porte une.
    pub commande: Option<Uuid>,
    /// Offre concernée, si l'annonce en porte une.
    pub offre: Option<Uuid>,
    /// Variables typées de la clé (montants entiers + devise, délais en
    /// secondes, compteurs). Aucune chaîne pré-formatée.
    pub variables: serde_json::Value,
    /// Vrai quand l'annonce ouvre un droit : « annulation sans frais » (FR-065).
    pub action_annulation_sans_frais: bool,
}

impl Annonce {
    /// Annonce minimale sur un canal, sans variable ni droit ouvert.
    pub fn nouvelle(canal: Canal, destinataire: Option<Uuid>, cle_i18n: &str) -> Self {
        Self {
            canal,
            destinataire,
            cle_i18n: cle_i18n.to_owned(),
            commande: None,
            offre: None,
            variables: serde_json::Value::Object(serde_json::Map::new()),
            action_annulation_sans_frais: false,
        }
    }

    /// Rattache l'annonce à une commande.
    pub fn pour_commande(mut self, commande: Uuid) -> Self {
        self.commande = Some(commande);
        self
    }

    /// Rattache l'annonce à une offre.
    pub fn pour_offre(mut self, offre: Uuid) -> Self {
        self.offre = Some(offre);
        self
    }

    /// Pose les variables typées de la clé.
    pub fn avec_variables(mut self, variables: serde_json::Value) -> Self {
        self.variables = variables;
        self
    }

    /// Ouvre le droit d'annulation sans frais (FR-065).
    pub fn avec_annulation_sans_frais(mut self) -> Self {
        self.action_annulation_sans_frais = true;
        self
    }
}

/// Le **contrat d'émission** de notifications (FR-094).
///
/// Cinq exigences en dépendent : offre au coursier (FR-046), non-réponse non
/// pénalisée (FR-053), bascule prépaiement notifiée à la cliente (FR-026),
/// escalade vers l'exploitation **et** annulation sans frais offerte à la
/// cliente (FR-064, FR-065), retrait notifié aux deux parties (FR-073).
#[async_trait]
pub trait NotificationsDispatch: Send + Sync {
    /// N'ouvre AUCUNE socket et ne rend **jamais** d'erreur : une annonce
    /// perdue ne doit pas annuler une affectation déjà écrite. L'échec est
    /// journalisé, la transaction métier tient.
    async fn annoncer(&self, annonce: Annonce);
}

/// Impl de PRODUCTION tant que NTF-01 n'existe pas : journalise l'annonce et
/// s'arrête là.
///
/// Ce n'est pas un bouchon menteur — c'est l'état exact du monde avant le module
/// de notifications, et c'est pourquoi l'app **va chercher** son offre
/// (research R16) au lieu d'être réveillée.
#[derive(Debug, Default, Clone, Copy)]
pub struct AnnoncesJournalisees;

#[async_trait]
impl NotificationsDispatch for AnnoncesJournalisees {
    async fn annoncer(&self, annonce: Annonce) {
        tracing::info!(
            canal = annonce.canal.comme_str(),
            destinataire = ?annonce.destinataire,
            cle_i18n = %annonce.cle_i18n,
            commande = ?annonce.commande,
            offre = ?annonce.offre,
            annulation_sans_frais = annonce.action_annulation_sans_frais,
            "annonce dispatch (transport livré par NTF-01)",
        );
    }
}

// ══════════════════════════════════════════════════════════════════════════
// DOUBLES DE TEST — la suite entière tourne sans Redis ni OSRM
// ══════════════════════════════════════════════════════════════════════════

/// Double de [`PoolCoursiers`] : inscriptions en mémoire, avec expiration
/// **pilotée** (`faire_expirer`) plutôt que subie.
#[derive(Debug, Default)]
pub struct MemoirePool {
    /// Inscriptions vivantes, par coursier.
    etats: Mutex<HashMap<Uuid, InscriptionPool>>,
    /// Membres de l'index géographique, par zone — ils SURVIVENT à
    /// l'expiration de l'état, comme un zset Redis : c'est ce qui rend le
    /// fantôme reproductible en test.
    index: Mutex<HashMap<Uuid, Vec<Uuid>>>,
}

impl MemoirePool {
    /// Nouveau double : pool vide.
    pub fn nouveau() -> Self {
        Self::default()
    }

    /// Fait expirer l'état d'un coursier **sans** toucher à l'index : c'est
    /// exactement le fantôme de Redis (research R2).
    pub fn faire_expirer(&self, coursier: Uuid) {
        self.etats.lock().expect("etats").remove(&coursier);
    }

    /// Vide tout — simule un `FLUSHDB` (SC-004).
    pub fn vider(&self) {
        self.etats.lock().expect("etats").clear();
        self.index.lock().expect("index").clear();
    }

    /// Nombre d'inscriptions vivantes.
    pub fn taille(&self) -> usize {
        self.etats.lock().expect("etats").len()
    }
}

#[async_trait]
impl PoolCoursiers for MemoirePool {
    async fn publier(&self, i: &InscriptionPool, _ttl: Duration) -> Result<(), ErreurDispatch> {
        self.etats
            .lock()
            .expect("etats")
            .insert(i.coursier, i.clone());
        let mut index = self.index.lock().expect("index");
        let membres = index.entry(i.zone).or_default();
        if !membres.contains(&i.coursier) {
            membres.push(i.coursier);
        }
        Ok(())
    }

    async fn retirer(&self, coursier: Uuid, zone: Uuid) -> Result<(), ErreurDispatch> {
        self.etats.lock().expect("etats").remove(&coursier);
        if let Some(membres) = self.index.lock().expect("index").get_mut(&zone) {
            membres.retain(|c| *c != coursier);
        }
        Ok(())
    }

    async fn dans_rayon(
        &self,
        zone: Uuid,
        lat: f64,
        lon: f64,
        rayon_m: i64,
    ) -> Result<Vec<Uuid>, ErreurDispatch> {
        let etats = self.etats.lock().expect("etats");
        Ok(self
            .index
            .lock()
            .expect("index")
            .get(&zone)
            .map(|membres| {
                membres
                    .iter()
                    .filter(|c| match etats.get(c) {
                        // Vol d'oiseau, comme le GEO de Redis : il MINORE la
                        // route, donc il ne peut pas écarter à tort.
                        Some(i) => distance_grand_cercle_m(lat, lon, i.lat, i.lon) <= rayon_m as f64,
                        // Fantôme : il reste dans l'index, mais l'appelant ne
                        // trouvera aucun état — donc il ne recevra rien.
                        None => true,
                    })
                    .copied()
                    .collect()
            })
            .unwrap_or_default())
    }

    async fn membres(&self, zone: Uuid) -> Result<Vec<Uuid>, ErreurDispatch> {
        Ok(self
            .index
            .lock()
            .expect("index")
            .get(&zone)
            .cloned()
            .unwrap_or_default())
    }

    async fn etat(&self, coursier: Uuid) -> Result<Option<InscriptionPool>, ErreurDispatch> {
        Ok(self.etats.lock().expect("etats").get(&coursier).cloned())
    }

    async fn elaguer(&self, zone: Uuid) -> Result<usize, ErreurDispatch> {
        let etats = self.etats.lock().expect("etats");
        let mut index = self.index.lock().expect("index");
        let Some(membres) = index.get_mut(&zone) else {
            return Ok(0);
        };
        let avant = membres.len();
        membres.retain(|c| etats.contains_key(c));
        Ok(avant - membres.len())
    }
}

/// Rayon terrestre moyen (mètres) — le double mesure comme le GEO de Redis.
const RAYON_TERRE_M: f64 = 6_371_000.0;

/// Distance orthodromique en mètres (haversine).
fn distance_grand_cercle_m(lat_a: f64, lon_a: f64, lat_b: f64, lon_b: f64) -> f64 {
    let (phi_a, phi_b) = (lat_a.to_radians(), lat_b.to_radians());
    let d_phi = (lat_b - lat_a).to_radians();
    let d_lambda = (lon_b - lon_a).to_radians();
    let a =
        (d_phi / 2.0).sin().powi(2) + phi_a.cos() * phi_b.cos() * (d_lambda / 2.0).sin().powi(2);
    2.0 * RAYON_TERRE_M * a.sqrt().atan2((1.0 - a).sqrt())
}

/// Double de [`VerrouOffre`] : deux jeux de verrous en mémoire, posés
/// **tout-ou-rien** comme le script Lua.
#[derive(Debug, Default)]
pub struct VerrouMemoire {
    /// Verrous par commande → jeton.
    commandes: Mutex<HashMap<Uuid, Uuid>>,
    /// Verrous par coursier → jeton.
    coursiers: Mutex<HashMap<Uuid, Uuid>>,
}

impl VerrouMemoire {
    /// Nouveau double : aucun verrou posé.
    pub fn nouveau() -> Self {
        Self::default()
    }
}

#[async_trait]
impl VerrouOffre for VerrouMemoire {
    async fn poser(
        &self,
        commande: Uuid,
        coursier: Uuid,
        jeton: Uuid,
        _ttl: Duration,
    ) -> Result<PoseVerrou, ErreurDispatch> {
        // Les deux verrous sont pris sous les DEUX mutex à la fois : c'est
        // l'atomicité que le script Lua donne côté Redis (FR-056).
        let mut cmds = self.commandes.lock().expect("commandes");
        let mut crss = self.coursiers.lock().expect("coursiers");
        if cmds.contains_key(&commande) {
            return Ok(PoseVerrou::CommandeDejaOfferte);
        }
        if crss.contains_key(&coursier) {
            return Ok(PoseVerrou::CoursierDejaPorteur);
        }
        cmds.insert(commande, jeton);
        crss.insert(coursier, jeton);
        Ok(PoseVerrou::Obtenu)
    }

    async fn poser_coursier(
        &self,
        coursier: Uuid,
        jeton: Uuid,
        _ttl: Duration,
    ) -> Result<bool, ErreurDispatch> {
        let mut crss = self.coursiers.lock().expect("coursiers");
        if crss.contains_key(&coursier) {
            return Ok(false);
        }
        crss.insert(coursier, jeton);
        Ok(true)
    }

    async fn liberer(
        &self,
        commande: Uuid,
        coursier: Uuid,
        jeton: Uuid,
    ) -> Result<(), ErreurDispatch> {
        let mut cmds = self.commandes.lock().expect("commandes");
        let mut crss = self.coursiers.lock().expect("coursiers");
        // Jamais libérer un verrou qu'on ne détient pas.
        if cmds.get(&commande) == Some(&jeton) {
            cmds.remove(&commande);
        }
        if crss.get(&coursier) == Some(&jeton) {
            crss.remove(&coursier);
        }
        Ok(())
    }
}

/// Double de [`EtatCoursier`] : coursiers exploitables déclarés d'avance.
#[derive(Debug, Default)]
pub struct CoursierFixe {
    coursiers: Mutex<HashMap<Uuid, CoursierExploitable>>,
}

impl CoursierFixe {
    /// Nouveau double : aucun coursier n'est exploitable.
    pub fn nouveau() -> Self {
        Self::default()
    }

    /// Déclare un coursier exploitable avec ses capacités.
    pub fn exploitable(&self, compte: Uuid, zone: Uuid, capacites: Vec<Capacite>) {
        self.coursiers.lock().expect("coursiers").insert(
            compte,
            CoursierExploitable {
                compte,
                zone,
                capacites,
            },
        );
    }

    /// Suspend un coursier (rôle retiré, ou compte bloqué) — il devient
    /// inexploitable **sans** que son état de pool disparaisse : c'est le cas
    /// que FR-009 protège.
    pub fn suspendre(&self, compte: Uuid) {
        self.coursiers.lock().expect("coursiers").remove(&compte);
    }
}

#[async_trait]
impl EtatCoursier for CoursierFixe {
    async fn coursier(&self, compte: Uuid) -> Result<Option<CoursierExploitable>, ErreurDispatch> {
        Ok(self
            .coursiers
            .lock()
            .expect("coursiers")
            .get(&compte)
            .cloned())
    }
}

/// Double de [`NotePrestataire`] : notes posées à la main (AVI simulé).
#[derive(Debug, Default)]
pub struct NoteFixe {
    notes: Mutex<HashMap<Uuid, i32>>,
}

impl NoteFixe {
    /// Nouveau double : aucune note (comme [`NoteAbsente`]).
    pub fn nouveau() -> Self {
        Self::default()
    }

    /// Pose la note d'un compte, en centièmes.
    pub fn definir(&self, compte: Uuid, note_centiemes: i32) {
        self.notes
            .lock()
            .expect("notes")
            .insert(compte, note_centiemes);
    }
}

#[async_trait]
impl NotePrestataire for NoteFixe {
    async fn note_centiemes(&self, compte: Uuid) -> Result<Option<i32>, ErreurDispatch> {
        Ok(self.notes.lock().expect("notes").get(&compte).copied())
    }
}

/// Double de [`PairesBloquees`] : paires posées à la main (CRS-07 simulé).
#[derive(Debug, Default)]
pub struct PairesSimulees {
    paires: Mutex<HashSet<(Uuid, Uuid)>>,
}

impl PairesSimulees {
    /// Nouveau double : aucune paire bloquée.
    pub fn nouveau() -> Self {
        Self::default()
    }

    /// Bloque la paire coursier ↔ contrepartie (client ou vendeur).
    pub fn bloquer(&self, coursier: Uuid, contrepartie: Uuid) {
        self.paires
            .lock()
            .expect("paires")
            .insert((coursier, contrepartie));
    }
}

#[async_trait]
impl PairesBloquees for PairesSimulees {
    async fn bloquees(
        &self,
        coursier: Uuid,
        contreparties: &[Uuid],
    ) -> Result<HashSet<Uuid>, ErreurDispatch> {
        let paires = self.paires.lock().expect("paires");
        Ok(contreparties
            .iter()
            .filter(|c| paires.contains(&(coursier, **c)))
            .copied()
            .collect())
    }
}

/// Double de [`ProximiteRoutiere`] : distances et durées connues d'avance, donc
/// classement assertable au rang près.
///
/// Il **compte ses appels** ([`ProximiteFixe::appels`]) : c'est ce qui rend
/// FR-035 démontrable — « une matrice par évaluation, jamais un appel par
/// candidat » est une promesse qui ne se vérifie qu'en comptant.
#[derive(Debug)]
pub struct ProximiteFixe {
    /// Trajets par point d'origine arrondi — la clé évite les surprises de f64.
    trajets: Mutex<HashMap<(i64, i64), Trajet>>,
    /// Trajet rendu pour une origine non déclarée.
    defaut: Mutex<Trajet>,
    /// Drapeau de dégradé rendu par le double.
    degraded: Mutex<bool>,
    /// Nombre d'appels au port, toutes méthodes confondues.
    appels: std::sync::atomic::AtomicUsize,
}

impl Default for ProximiteFixe {
    fn default() -> Self {
        Self::nouveau()
    }
}

/// Précision de la clé d'un point (≈ 1 cm) — mêmes décimales que le cache de
/// routage du cycle 007.
const CLE_DECIMALES: f64 = 1e7;

fn cle_point(p: tarification::Point) -> (i64, i64) {
    (
        (p.lat * CLE_DECIMALES).round() as i64,
        (p.lon * CLE_DECIMALES).round() as i64,
    )
}

impl ProximiteFixe {
    /// Nouveau double : tout le monde à 1 km / 300 s, sans dégradé.
    pub fn nouveau() -> Self {
        Self {
            trajets: Mutex::new(HashMap::new()),
            defaut: Mutex::new(Trajet {
                distance_m: 1_000,
                duree_s: 300,
            }),
            degraded: Mutex::new(false),
            appels: std::sync::atomic::AtomicUsize::new(0),
        }
    }

    /// Fixe le trajet depuis une origine précise.
    pub fn depuis(&self, origine: tarification::Point, distance_m: i64, duree_s: i64) {
        self.trajets.lock().expect("trajets").insert(
            cle_point(origine),
            Trajet {
                distance_m,
                duree_s,
            },
        );
    }

    /// Fixe le trajet rendu pour toute origine non déclarée.
    pub fn defaut(&self, distance_m: i64, duree_s: i64) {
        *self.defaut.lock().expect("defaut") = Trajet {
            distance_m,
            duree_s,
        };
    }

    /// Force le drapeau de dégradé (constitution IV).
    pub fn degrade(&self, degraded: bool) {
        *self.degraded.lock().expect("degraded") = degraded;
    }

    /// Nombre d'appels au port depuis la dernière remise à zéro.
    pub fn appels(&self) -> usize {
        self.appels.load(std::sync::atomic::Ordering::SeqCst)
    }

    /// Remet le compteur à zéro — pour isoler la mesure d'une phase précise
    /// (l'affichage d'une offre, par exemple) de celle du dispatch qui l'a
    /// produite.
    pub fn oublier_les_appels(&self) {
        self.appels.store(0, std::sync::atomic::Ordering::SeqCst);
    }

    /// Trajet déclaré depuis ce point, ou le défaut.
    fn depuis_ou_defaut(&self, point: tarification::Point) -> Trajet {
        let trajets = self.trajets.lock().expect("trajets");
        let defaut = *self.defaut.lock().expect("defaut");
        trajets.get(&cle_point(point)).copied().unwrap_or(defaut)
    }

    /// Compte un appel au port.
    fn compter_un_appel(&self) {
        self.appels
            .fetch_add(1, std::sync::atomic::Ordering::SeqCst);
    }
}

#[async_trait]
impl ProximiteRoutiere for ProximiteFixe {
    async fn vers_point(
        &self,
        _zone: Uuid,
        origines: &[tarification::Point],
        _destination: tarification::Point,
    ) -> Trajets {
        self.compter_un_appel();
        Trajets {
            trajets: origines.iter().map(|o| self.depuis_ou_defaut(*o)).collect(),
            degraded: *self.degraded.lock().expect("degraded"),
        }
    }

    /// Un tronçon se lit sur son point de DÉPART, comme `vers_point` lit son
    /// origine : `depuis()` suffit donc à piloter les deux mesures d'un test.
    async fn troncons_consecutifs(&self, _zone: Uuid, points: &[tarification::Point]) -> Trajets {
        self.compter_un_appel();
        Trajets {
            trajets: points
                .windows(2)
                .map(|fenetre| self.depuis_ou_defaut(fenetre[0]))
                .collect(),
            degraded: *self.degraded.lock().expect("degraded"),
        }
    }
}

/// Double de [`NotificationsDispatch`] : retient les annonces.
///
/// C'est lui qui permet d'asserter « la cliente a été prévenue **avec le
/// motif**, et l'annulation sans frais lui a été offerte » — ce que SC-006 et
/// SC-012 exigent de vérifier.
#[derive(Debug, Default)]
pub struct NotificationsCollectees {
    annonces: Mutex<Vec<Annonce>>,
}

impl NotificationsCollectees {
    /// Nouveau double : aucune annonce.
    pub fn nouveau() -> Self {
        Self::default()
    }

    /// Toutes les annonces émises, dans l'ordre.
    pub fn annonces(&self) -> Vec<Annonce> {
        self.annonces.lock().expect("annonces").clone()
    }

    /// Annonces d'un canal donné.
    pub fn sur_canal(&self, canal: Canal) -> Vec<Annonce> {
        self.annonces
            .lock()
            .expect("annonces")
            .iter()
            .filter(|a| a.canal == canal)
            .cloned()
            .collect()
    }

    /// Vrai si une annonce porte cette clé i18n.
    pub fn contient_cle(&self, cle: &str) -> bool {
        self.annonces
            .lock()
            .expect("annonces")
            .iter()
            .any(|a| a.cle_i18n == cle)
    }

    /// Oublie tout (entre deux phases d'un même test).
    pub fn vider(&self) {
        self.annonces.lock().expect("annonces").clear();
    }
}

#[async_trait]
impl NotificationsDispatch for NotificationsCollectees {
    async fn annoncer(&self, annonce: Annonce) {
        self.annonces.lock().expect("annonces").push(annonce);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn inscription(coursier: Uuid, zone: Uuid, lat: f64, lon: f64) -> InscriptionPool {
        InscriptionPool {
            coursier,
            zone,
            lat,
            lon,
            en_ligne: true,
            capacites: vec![Capacite::transport("moto")],
            note_centiemes: None,
            plafond_unites: 10_000,
            devise: "XOF".to_owned(),
            course_active: None,
            age_s: 0,
        }
    }

    /// Le double reproduit le FANTÔME de Redis : l'état expire, le membre de
    /// l'index survit. C'est ce comportement-là qui doit être élagué — et qui,
    /// entre-temps, ne doit rendre aucun état.
    #[tokio::test]
    async fn un_membre_survit_a_son_etat_puis_est_elague() {
        let (zone, coursier) = (Uuid::now_v7(), Uuid::now_v7());
        let pool = MemoirePool::nouveau();
        pool.publier(
            &inscription(coursier, zone, 5.8960, -4.8210),
            Duration::from_secs(90),
        )
        .await
        .unwrap();
        assert_eq!(
            pool.dans_rayon(zone, 5.8960, -4.8210, 4_000)
                .await
                .unwrap()
                .len(),
            1
        );

        pool.faire_expirer(coursier);
        assert!(
            pool.etat(coursier).await.unwrap().is_none(),
            "sans état, aucune offre ne peut lui parvenir",
        );
        assert_eq!(
            pool.dans_rayon(zone, 5.8960, -4.8210, 4_000)
                .await
                .unwrap()
                .len(),
            1,
            "le membre fantôme est encore dans l'index — c'est le cas à élaguer",
        );
        assert_eq!(pool.elaguer(zone).await.unwrap(), 1);
        assert!(pool
            .dans_rayon(zone, 5.8960, -4.8210, 4_000)
            .await
            .unwrap()
            .is_empty());
    }

    /// Le pré-filtre en vol d'oiseau MINORE la route : il ne peut pas écarter
    /// un coursier réellement dans le rayon (research R5).
    #[tokio::test]
    async fn le_prefiltre_ecarte_ce_qui_est_certainement_trop_loin() {
        let (zone, proche, loin) = (Uuid::now_v7(), Uuid::now_v7(), Uuid::now_v7());
        let pool = MemoirePool::nouveau();
        pool.publier(
            &inscription(proche, zone, 5.8960, -4.8210),
            Duration::from_secs(90),
        )
        .await
        .unwrap();
        // ≈ 11 km au nord.
        pool.publier(
            &inscription(loin, zone, 5.9960, -4.8210),
            Duration::from_secs(90),
        )
        .await
        .unwrap();
        let dedans = pool.dans_rayon(zone, 5.8960, -4.8210, 4_000).await.unwrap();
        assert_eq!(dedans, vec![proche]);
    }

    /// FR-056 — tout ou rien. Le second verrou refusé ROLLBACK le premier :
    /// sans cela, la commande resterait verrouillée pour une offre qui n'a
    /// jamais existé.
    #[tokio::test]
    async fn la_pose_est_tout_ou_rien_et_nomme_ses_deux_refus() {
        let (cmd_a, cmd_b, crs) = (Uuid::now_v7(), Uuid::now_v7(), Uuid::now_v7());
        let verrou = VerrouMemoire::nouveau();
        let jeton_a = Uuid::now_v7();

        assert_eq!(
            verrou
                .poser(cmd_a, crs, jeton_a, Duration::from_secs(45))
                .await
                .unwrap(),
            PoseVerrou::Obtenu,
        );
        // Même commande, autre coursier → la commande est déjà offerte.
        assert_eq!(
            verrou
                .poser(cmd_a, Uuid::now_v7(), Uuid::now_v7(), Duration::from_secs(45))
                .await
                .unwrap(),
            PoseVerrou::CommandeDejaOfferte,
        );
        // Autre commande, MÊME coursier → il porte déjà une offre (FR-057).
        assert_eq!(
            verrou
                .poser(cmd_b, crs, Uuid::now_v7(), Duration::from_secs(45))
                .await
                .unwrap(),
            PoseVerrou::CoursierDejaPorteur,
        );
        // Et le verrou de `cmd_b` n'a PAS été laissé posé au passage.
        verrou.liberer(cmd_a, crs, jeton_a).await.unwrap();
        assert_eq!(
            verrou
                .poser(cmd_b, crs, Uuid::now_v7(), Duration::from_secs(45))
                .await
                .unwrap(),
            PoseVerrou::Obtenu,
        );
    }

    /// On ne libère jamais un verrou qu'on ne détient pas.
    #[tokio::test]
    async fn liberer_avec_un_mauvais_jeton_ne_fait_rien() {
        let (cmd, crs) = (Uuid::now_v7(), Uuid::now_v7());
        let verrou = VerrouMemoire::nouveau();
        let jeton = Uuid::now_v7();
        verrou
            .poser(cmd, crs, jeton, Duration::from_secs(45))
            .await
            .unwrap();

        verrou.liberer(cmd, crs, Uuid::now_v7()).await.unwrap();
        assert_eq!(
            verrou
                .poser(cmd, Uuid::now_v7(), Uuid::now_v7(), Duration::from_secs(45))
                .await
                .unwrap(),
            PoseVerrou::CommandeDejaOfferte,
            "le verrou tient encore : le mauvais jeton n'a rien libéré",
        );
    }

    /// Les impls de PRODUCTION disent l'état exact du monde : aucune note,
    /// aucune paire bloquée. Ce ne sont pas des bouchons menteurs.
    #[tokio::test]
    async fn les_impls_avant_avi_et_crs_disent_l_etat_du_monde() {
        let compte = Uuid::now_v7();
        assert!(NoteAbsente.note_centiemes(compte).await.unwrap().is_none());
        assert!(AucunePaireBloquee
            .bloquees(compte, &[Uuid::now_v7(), Uuid::now_v7()])
            .await
            .unwrap()
            .is_empty());
    }

    /// Un seul aller-retour pour toutes les contreparties (FR-025).
    #[tokio::test]
    async fn les_paires_se_lisent_en_un_seul_appel() {
        let (crs, client, vendeur_a, vendeur_b) = (
            Uuid::now_v7(),
            Uuid::now_v7(),
            Uuid::now_v7(),
            Uuid::now_v7(),
        );
        let paires = PairesSimulees::nouveau();
        paires.bloquer(crs, vendeur_b);
        let bloquees = paires
            .bloquees(crs, &[client, vendeur_a, vendeur_b])
            .await
            .unwrap();
        assert_eq!(bloquees, HashSet::from([vendeur_b]));
    }

    /// SC-006 / SC-012 — le double retient de quoi asserter qu'une cliente a
    /// été prévenue AVEC son motif, et que l'annulation sans frais lui a été
    /// offerte.
    #[tokio::test]
    async fn les_annonces_collectees_portent_le_motif_et_le_droit_ouvert() {
        let cliente = Uuid::now_v7();
        let commande = Uuid::now_v7();
        let notifs = NotificationsCollectees::nouveau();
        notifs
            .annoncer(
                Annonce::nouvelle(Canal::Client, Some(cliente), "dispatch.escalade.client")
                    .pour_commande(commande)
                    .avec_variables(serde_json::json!({ "age_s": 372, "seuil_s": 300 }))
                    .avec_annulation_sans_frais(),
            )
            .await;
        notifs
            .annoncer(Annonce::nouvelle(
                Canal::Exploitation,
                None,
                "dispatch.escalade.exploitation",
            ))
            .await;

        assert!(notifs.contient_cle("dispatch.escalade.client"));
        let vers_client = notifs.sur_canal(Canal::Client);
        assert_eq!(vers_client.len(), 1);
        assert!(vers_client[0].action_annulation_sans_frais);
        assert_eq!(vers_client[0].variables["seuil_s"], 300);
        assert_eq!(
            notifs.sur_canal(Canal::Exploitation)[0].destinataire,
            None,
            "l'exploitation n'est personne en particulier",
        );
    }

    /// Le double de proximité rend les trajets DANS L'ORDRE des origines —
    /// sans quoi un classement assertable au rang près serait faux.
    #[tokio::test]
    async fn la_proximite_fixe_respecte_l_ordre_des_origines() {
        let a = tarification::Point {
            lat: 5.896,
            lon: -4.821,
        };
        let b = tarification::Point {
            lat: 5.900,
            lon: -4.825,
        };
        let cible = tarification::Point {
            lat: 5.898,
            lon: -4.823,
        };
        let proximite = ProximiteFixe::nouveau();
        proximite.depuis(a, 500, 120);
        proximite.depuis(b, 2_000, 480);

        let trajets = proximite.vers_point(Uuid::now_v7(), &[b, a], cible).await;
        assert_eq!(trajets.trajets[0].distance_m, 2_000);
        assert_eq!(trajets.trajets[1].duree_s, 120);
        assert!(!trajets.degraded);
    }

    /// FR-035 — un itinéraire à `n` points se mesure en UN appel qui rend
    /// `n − 1` tronçons consécutifs, jamais en `n − 1` appels.
    #[tokio::test]
    async fn les_troncons_consecutifs_tiennent_en_un_seul_appel() {
        let a = tarification::Point {
            lat: 5.896,
            lon: -4.821,
        };
        let b = tarification::Point {
            lat: 5.900,
            lon: -4.825,
        };
        let c = tarification::Point {
            lat: 5.902,
            lon: -4.828,
        };
        let proximite = ProximiteFixe::nouveau();
        proximite.depuis(a, 800, 200);
        proximite.depuis(b, 40, 15);

        let trajets = proximite
            .troncons_consecutifs(Uuid::now_v7(), &[a, b, c])
            .await;
        assert_eq!(
            trajets.trajets.len(),
            2,
            "trois points, deux tronçons — a→b puis b→c",
        );
        assert_eq!(trajets.trajets[0].distance_m, 800, "a→b");
        assert_eq!(trajets.trajets[1].distance_m, 40, "b→c");
        assert_eq!(proximite.appels(), 1, "UNE matrice, pas une par tronçon");

        // Moins de deux points : aucun tronçon à mesurer.
        assert!(proximite
            .troncons_consecutifs(Uuid::now_v7(), &[a])
            .await
            .trajets
            .is_empty());
    }
}
