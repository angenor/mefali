//! Ports du domaine commandes (constitution II) — offerts et consommés.
//!
//! **Offerts** aux cycles suivants : [`ArretsDeCollecte`] (précondition QRC-02,
//! cycle 006) et [`CommandesADispatcher`] (file d'attente + affectation, que
//! DSP consommera sans modification).
//!
//! **Consommés** par CMD, implémentés ailleurs ou simulés : [`RestrictionsCompte`]
//! (crate `comptes`, research R12), [`PreuvesEchec`] (CRS-05) et
//! [`PositionCoursier`] (Redis, alimenté par DSP-01).
//!
//! Chaque trait a son **double** juste à côté, sur le modèle d'`ArretsFixes`
//! déjà livré au cycle 006 (research R16) : c'est ce qui permet d'exercer
//! l'arbre §7.5 et la file d'attente sans construire DSP, PAY ni CRS, et laisse
//! ces cycles brancher leur implémentation réelle sans toucher au contrat.

use std::collections::HashMap;
use std::sync::{Arc, Mutex};

use async_trait::async_trait;
use chrono::{DateTime, Utc};
use uuid::Uuid;

use crate::modele::{
    ArretACollecter, ErreurCommandes, EtatCommande, EtatLivraison, EtatPaiement, ModePaiement,
    PreferenceSubstitution, Restrictions, Sanction, StatutArret, StatutLigne,
};

/// Lecture de l'arrêt à collecter d'un coursier chez un prestataire donné.
#[async_trait]
pub trait ArretsDeCollecte: Send + Sync {
    /// Renvoie l'arrêt `à_collecter` de la course active du coursier visant ce
    /// prestataire, ou `None` s'il n'y en a pas (aucune course, prestataire
    /// hors course, arrêt déjà résolu).
    async fn arret_a_collecter(
        &self,
        coursier: Uuid,
        prestataire: Uuid,
    ) -> Result<Option<ArretACollecter>, ErreurCommandes>;
}

/// Double de test : arrêts pré-enregistrés par `(coursier, prestataire)`.
/// Simule l'affectation DSP (R10) — en production, aucune course n'est assignée
/// tant que DSP n'existe pas, la lecture renvoie vide (exact et voulu).
#[derive(Debug, Default)]
pub struct ArretsFixes {
    arrets: Mutex<HashMap<(Uuid, Uuid), ArretACollecter>>,
}

impl ArretsFixes {
    /// Nouveau double vide.
    pub fn nouveau() -> Self {
        Self::default()
    }

    /// Enregistre l'arrêt à collecter d'un coursier chez un prestataire.
    pub fn autoriser(&self, coursier: Uuid, prestataire: Uuid, arret: ArretACollecter) {
        self.arrets
            .lock()
            .expect("arrets")
            .insert((coursier, prestataire), arret);
    }

    /// Retire l'arrêt (simule sa résolution).
    pub fn retirer(&self, coursier: Uuid, prestataire: Uuid) {
        self.arrets
            .lock()
            .expect("arrets")
            .remove(&(coursier, prestataire));
    }
}

#[async_trait]
impl ArretsDeCollecte for ArretsFixes {
    async fn arret_a_collecter(
        &self,
        coursier: Uuid,
        prestataire: Uuid,
    ) -> Result<Option<ArretACollecter>, ErreurCommandes> {
        Ok(self
            .arrets
            .lock()
            .expect("arrets")
            .get(&(coursier, prestataire))
            .cloned())
    }
}

// ── OFFERT à DSP : file d'attente et affectation (CMD-10) ─────────────────

/// Une commande en attente de coursier, telle que DSP la lira.
///
/// ARTCI : aucune coordonnée du CLIENT ici — seul le point de première collecte
/// (position d'un site vendeur, donnée professionnelle) est exposé, parce que
/// c'est lui qui décide de l'éligibilité géographique d'un coursier.
#[derive(Debug, Clone, PartialEq)]
pub struct CommandeADispatcher {
    /// Commande concernée.
    pub commande_id: Uuid,
    /// Zone de la commande (résout les paramètres de dispatch).
    pub zone_id: Uuid,
    /// Ancienneté dans la file, en secondes (FIFO par âge — aucune table).
    pub age_s: i64,
    /// Nombre d'arrêts de collecte à desservir.
    pub nb_collectes: i64,
    /// Montant total que le coursier devra avancer (unités mineures, III).
    pub montant_a_avancer: i64,
    /// Devise ISO 4217.
    pub devise: String,
    /// Position de la PREMIÈRE collecte (site vendeur).
    pub premiere_collecte_lat: Option<f64>,
    /// Position de la première collecte.
    pub premiere_collecte_lon: Option<f64>,
}

/// Une capacité REQUISE par une course, ou DÉCLARÉE par un coursier.
///
/// Paire générique `(famille, valeur)` — MVP : famille `transport`, valeur =
/// slug de `zones.type_transport`. FR-018 du cycle DSP exige que l'ajout d'une
/// famille (qualification d'artisan, phase N) ne coûte ni migration ni
/// réécriture du filtre : c'est pourquoi ce n'est pas une énum.
#[derive(Debug, Clone, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub struct Capacite {
    /// Famille de capacité (MVP : `transport`).
    pub famille: String,
    /// Valeur dans la famille (MVP : slug de transport).
    pub valeur: String,
}

/// Ce que la réassignation doit savoir **avant** de retirer quoi que ce soit
/// (cycle DSP 009, FR-072, FR-075).
#[derive(Debug, Clone, PartialEq)]
pub struct EtatProgression {
    /// Commande de la livraison.
    pub commande_id: Uuid,
    /// Coursier assigné, ou `None` si la livraison n'en a plus.
    pub coursier_id: Option<Uuid>,
    /// Instant d'affectation — base du délai « sans scan ».
    pub assignee_le: Option<DateTime<Utc>>,
    /// Nombre d'arrêts de collecte **déjà collectés**. `> 0` interdit toute
    /// reprise automatique : le coursier a engagé ses fonds propres (FR-075).
    pub nb_arrets_collectes: i64,
    /// Nombre total d'arrêts de collecte.
    pub nb_arrets_collecte_total: i64,
    /// Position du premier arrêt NON résolu — la cible contre laquelle le
    /// rapprochement se mesure.
    pub premier_arret_lat: Option<f64>,
    /// Position du premier arrêt non résolu.
    pub premier_arret_lon: Option<f64>,
}

/// Pourquoi un prépaiement est exigé APRÈS création (cycle DSP 009).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MotifPrepaiementDispatch {
    /// Aucun coursier ne peut avancer le montant des articles, et c'est le SEUL
    /// obstacle du vivier (FR-026). Le prépaiement lève exactement ce blocage —
    /// il ne rapprocherait pas un coursier trop loin.
    CapaciteAvanceCoursier,
}

impl MotifPrepaiementDispatch {
    /// Représentation textuelle (payload d'événement).
    pub fn comme_str(self) -> &'static str {
        match self {
            MotifPrepaiementDispatch::CapaciteAvanceCoursier => "capacite_avance_coursier",
        }
    }
}

/// Contrat offert à **DSP** (dispatch).
///
/// Créé au cycle 008 avec ses deux premières méthodes, **étendu** de six autres
/// par le cycle 009 — plutôt qu'un second trait qui découperait le même contrat
/// en deux. Aucune dépendance inverse : `commandes` ne dépendra jamais de
/// `dispatch` (specs/009 research R19).
#[async_trait]
pub trait CommandesADispatcher: Send + Sync {
    /// File FIFO **par âge** des commandes sans coursier dans une zone (CMD-10).
    /// La plus ancienne d'abord, sans table dédiée (index partiel).
    async fn en_attente_coursier(
        &self,
        zone: Uuid,
    ) -> Result<Vec<CommandeADispatcher>, ErreurCommandes>;

    /// Affecte un coursier : crée la livraison `assignee` et passe le tronc
    /// `en_cours`. Reprend une commande en attente comme une commande neuve.
    async fn affecter(&self, commande: Uuid, coursier: Uuid) -> Result<Uuid, ErreurCommandes>;

    // ── Ajouté par le cycle DSP 009 ───────────────────────────────────────

    /// Course active d'un coursier (FR-007, FR-016). `None` = offreable.
    ///
    /// Le pool en garde une copie ; c'est CETTE lecture qui tranche (FR-009).
    async fn course_active(&self, coursier: Uuid) -> Result<Option<Uuid>, ErreurCommandes>;

    /// Fin de la dernière course LIVRÉE — base de l'inactivité (FR-036).
    ///
    /// `None` = jamais livré : l'inactivité part alors de l'entrée dans le pool,
    /// pour qu'un nouvel arrivant ne soit pas traité comme quelqu'un qui vient
    /// de finir.
    async fn fin_derniere_course(
        &self,
        coursier: Uuid,
    ) -> Result<Option<DateTime<Utc>>, ErreurCommandes>;

    /// Capacités requises d'une commande, lues sur la LIVRAISON (research R9,
    /// FR-017) — jamais sur le tronc, qui ne porte aucun champ logistique.
    async fn capacites_requises(&self, commande: Uuid) -> Result<Vec<Capacite>, ErreurCommandes>;

    /// Ce que la réassignation doit savoir avant de retirer quoi que ce soit.
    async fn etat_progression(
        &self,
        livraison: Uuid,
    ) -> Result<EtatProgression, ErreurCommandes>;

    /// Retire le coursier et remet la commande dans le pipeline :
    /// `livraison.coursier_id = NULL`, tronc `en_cours → en_attente_coursier`,
    /// événement dans la MÊME transaction.
    ///
    /// La livraison reste `assignee` **sans coursier** — sémantique documentée
    /// depuis le cycle 006 (« `coursier_id` est POSÉ par DSP — NULL tant que non
    /// assignée »). Aucune transition de livraison n'est inventée.
    async fn retirer_coursier(
        &self,
        livraison: Uuid,
        horodatage: DateTime<Utc>,
    ) -> Result<(), ErreurCommandes>;

    /// Escalade les commandes non assignées au-delà du seuil de zone, et rend
    /// celles qui l'ont été (FR-064, research R14).
    ///
    /// Écrite au cycle 008 mais **planifiée nulle part** : c'est le tic de
    /// dispatch qui l'appelle désormais. Idempotente par le `NOT EXISTS` sur
    /// l'outbox — exactement une alerte par commande, quel que soit le chemin.
    async fn escalader_attentes(
        &self,
        zone: Uuid,
        horodatage: DateTime<Utc>,
    ) -> Result<Vec<Uuid>, ErreurCommandes>;

    /// Met la commande dans la file FIFO faute d'éligible (CMD-10, FR-037).
    ///
    /// Le cycle 008 laissait cette décision à l'appelant (« `Ok(None)` = aucun
    /// coursier éligible : c'est à l'appelant de mettre la commande en
    /// attente »). Cet appelant, c'est le pipeline de dispatch — d'où cette
    /// méthode plutôt qu'un accès direct : `dispatch` n'écrit jamais dans le
    /// schéma `commandes`.
    ///
    /// Une commande qui n'est plus `nouvelle` refuse la transition, et c'est un
    /// refus ATTENDU (annulée, déjà assignée entre-temps) — pas une panne.
    async fn mettre_en_attente(
        &self,
        commande: Uuid,
        horodatage: DateTime<Utc>,
    ) -> Result<(), ErreurCommandes>;

    /// Bascule cash → mobile money après création (FR-026) : tronc
    /// `nouvelle → en_attente_paiement`, `mode_paiement = mobile_money`.
    ///
    /// AUCUN chemin partiel — un seul montant, un seul état (constitution III).
    async fn exiger_prepaiement(
        &self,
        commande: Uuid,
        motif: MotifPrepaiementDispatch,
        horodatage: DateTime<Utc>,
    ) -> Result<(), ErreurCommandes>;
}

/// Double de test du **dispatch** (DSP non construit, research R16).
///
/// DSP décidera QUEL coursier prendre ; ce double porte cette décision — un
/// vivier de coursiers éligibles par zone — et délègue l'écriture au vrai
/// [`CommandesADispatcher`]. Vider le vivier force la file d'attente CMD-10,
/// ce qui rend le cas « aucun coursier éligible » exerçable sans DSP.
#[derive(Debug, Default)]
pub struct AffectationSimulee {
    viviers: Mutex<HashMap<Uuid, Vec<Uuid>>>,
}

impl AffectationSimulee {
    /// Nouveau double : aucun coursier éligible nulle part.
    pub fn nouveau() -> Self {
        Self::default()
    }

    /// Ajoute un coursier au vivier d'une zone.
    pub fn ajouter_coursier(&self, zone: Uuid, coursier: Uuid) {
        self.viviers
            .lock()
            .expect("viviers")
            .entry(zone)
            .or_default()
            .push(coursier);
    }

    /// Vide le vivier d'une zone — plus aucun coursier éligible (CMD-10).
    pub fn vider(&self, zone: Uuid) {
        self.viviers.lock().expect("viviers").remove(&zone);
    }

    /// Prochain coursier éligible de la zone, sans le consommer.
    pub fn coursier_eligible(&self, zone: Uuid) -> Option<Uuid> {
        self.viviers
            .lock()
            .expect("viviers")
            .get(&zone)
            .and_then(|v| v.first().copied())
    }

    /// Affecte le premier coursier éligible de la zone à cette commande, via le
    /// dépôt réel. `Ok(None)` = aucun coursier éligible : c'est à l'appelant de
    /// mettre la commande en attente (la décision reste dans le domaine).
    pub async fn affecter_via<D: CommandesADispatcher + ?Sized>(
        &self,
        depot: &D,
        zone: Uuid,
        commande: Uuid,
    ) -> Result<Option<Uuid>, ErreurCommandes> {
        let Some(coursier) = self.coursier_eligible(zone) else {
            return Ok(None);
        };
        depot.affecter(commande, coursier).await?;
        Ok(Some(coursier))
    }
}

// ── OFFERT à CRS : la course active complète (cycle 010) ───────────────────

/// Une ligne d'article à acheter chez un vendeur (K3, FR-012).
///
/// Elle vient de `commandes.ligne_commande`. La **coche** de l'article reste
/// locale à l'appareil (specs/010 R11) : le serveur ne connaît que « présente /
/// remplacée / retirée », et inventer un état « article coché » créerait une
/// troisième vérité que rien ne consomme.
#[derive(Debug, Clone, PartialEq)]
pub struct LigneDeCourse {
    /// Ligne de commande.
    pub ligne_id: Uuid,
    /// Libellé de l'article, figé à la création.
    pub libelle: String,
    /// Quantité commandée.
    pub quantite: i16,
    /// Prix unitaire VERROUILLÉ à la création (unités mineures).
    pub prix_unitaire_unites: i64,
    /// Ce que le client a choisi si l'article manque (FR-016).
    pub preference: PreferenceSubstitution,
    /// Présente, remplacée ou retirée.
    pub statut: StatutLigne,
}

/// Un arrêt de collecte, avec ses lignes et sa progression.
#[derive(Debug, Clone, PartialEq)]
pub struct ArretDeCourse {
    /// Arrêt de la course.
    pub arret_id: Uuid,
    /// Rang dans l'ordre optimisé.
    pub ordre: i16,
    /// Prestataire visé.
    pub prestataire_id: Uuid,
    /// Position attendue du site.
    pub site_lat: f64,
    /// Position attendue du site.
    pub site_lon: f64,
    /// Distance depuis l'arrêt précédent (m).
    ///
    /// ⚠ `None` aujourd'hui, et pour une raison qu'il faut connaître : le cycle
    /// 007 a figé la distance TOTALE du devis (`livraison.devis_distance_m`)
    /// mais pas le détail par tronçon, et ce cycle **ne recalcule aucun
    /// itinéraire** (FR-009, constitution IV). Servir une distance à vol
    /// d'oiseau ici la ferait passer pour un trajet. K3 affiche « à 800 m » ;
    /// tant que le tronçon n'est pas figé à la création, l'app masque la ligne
    /// plutôt que d'afficher un chiffre faux.
    pub distance_precedent_m: Option<i64>,
    /// Montant à avancer à CE vendeur (unités mineures) — **net de retenue**.
    ///
    /// C'est le chiffre que K3 affiche en gros : ce que Yao sort de sa poche au
    /// comptoir. Avant le scan c'est une prévision (`articles − retenue
    /// prévue`), après c'est le montant réellement versé. Les deux coïncident,
    /// sauf si des lignes bougent entre-temps — auquel cas la prévision suit.
    pub montant_avance: i64,
    /// Articles bruts de cet arrêt, AVANT retenue (cycle PAY 011, FR-092).
    ///
    /// Sans lui, l'app afficherait un net inexpliqué : « pourquoi 2 500 alors
    /// que le vendeur en demande 3 000 ? ». Un coursier qui ne comprend pas un
    /// écart d'argent appelle le support — ou paie le brut de sa poche.
    pub montant_articles_unites: i64,
    /// Part prise en charge par le vendeur (VND-08), `0` sinon.
    ///
    /// Avant la collecte c'est la retenue **prévue**, calculée par la règle du
    /// scan (research R9) ; après, c'est celle qui a été appliquée — l'histoire
    /// ne se réécrit pas.
    pub retenue_appliquee_unites: i64,
    /// Où en est cet arrêt.
    pub statut: StatutArret,
    /// Départ vers l'arrêt déclaré (horodatage serveur).
    pub en_route_le: Option<DateTime<Utc>>,
    /// Arrivée sur l'arrêt.
    pub arrive_le: Option<DateTime<Utc>>,
    /// Collecte validée.
    pub collecte_le: Option<DateTime<Utc>>,
    /// Articles à acheter chez ce vendeur.
    pub lignes: Vec<LigneDeCourse>,
}

/// Le client, tel que le coursier en a besoin **hors ligne** (specs/010 R6).
///
/// ⚠ `nom_usage` est `None` aujourd'hui, et ce n'est pas un oubli : le cycle
/// CPT 003 a posé « identité Mefali = un numéro vérifié, rien d'autre », et
/// aucune colonne nominative n'existe. La maquette K4-1a montre « Awa K. » ; le
/// champ est servi optionnel pour que l'app se contente du repère aujourd'hui
/// et affiche le nom le jour où le produit en aura un — sans changement de
/// contrat. Fabriquer un nom depuis le numéro serait créer la donnée
/// nominative que la minimisation ARTCI a délibérément écartée.
#[derive(Debug, Clone, PartialEq)]
pub struct ClientDeCourse {
    /// Compte client.
    pub compte_id: Uuid,
    /// Nom d'usage — `None` tant que le produit n'en porte pas (voir ci-dessus).
    pub nom_usage: Option<String>,
    /// Contact du client — l'appel doit marcher SANS RÉSEAU (R6). Jamais
    /// journalisé, jamais servi hors du coursier assigné.
    pub telephone: Option<String>,
    /// Repère écrit.
    pub repere_texte: Option<String>,
    /// Clé objet de la note vocale de repère — l'appelant la présigne.
    pub repere_vocal_cle: Option<String>,
    /// Durée de la note vocale (s), lue sur l'adresse d'origine. `None` si la
    /// commande a été créée sans adresse enregistrée (pin ponctuel) : l'app
    /// affiche alors le lecteur sans compteur, plutôt qu'un « 0:00 » faux.
    pub repere_vocal_duree_s: Option<i16>,
    /// Point de livraison.
    pub lieu_lat: f64,
    /// Point de livraison.
    pub lieu_lon: f64,
    /// La voie « dépôt » est-elle ouverte sur CETTE commande (FR-039) ?
    pub depot_autorise: bool,
}

/// Ce qu'il faut pour confirmer la remise **sans réseau** (K4).
///
/// ⚠ Seules des EMPREINTES : ni le code à 4 chiffres, ni le jeton ne sortent
/// jamais du serveur (FR-037). Elles existent en base depuis le cycle 008
/// (migration 0009, commentées « empreinte salée → coursier (offline CRS-04) »)
/// sans que personne ne les ait encore lues — ce port est leur premier lecteur.
#[derive(Debug, Clone, PartialEq)]
pub struct RemiseDeCourse {
    /// Empreinte salée du code à 4 chiffres.
    pub empreinte_code: String,
    /// Empreinte du jeton de réception encodé dans le QR client.
    pub empreinte_jeton: String,
    /// Essais faux déjà comptés côté serveur.
    pub essais_consommes: i16,
    /// Saisie du code bloquée par l'exploitation ou par épuisement (FR-043).
    pub code_bloque: bool,
    /// Total à encaisser chez le client (unités mineures) — recalculé après
    /// substitutions (FR-023).
    pub montant_a_encaisser_unites: i64,
    /// Cash ou prépayé : décide s'il y a quelque chose à encaisser.
    pub mode_paiement: ModePaiement,
    /// Arrêt de REMISE — celui que « je suis arrivé chez le client »
    /// transitionne (FR-053).
    ///
    /// Il ne figure pas dans [`CourseDuCoursier::arrets`], qui ne porte que les
    /// collectes : c'est ce qui permet à l'app de savoir que la course est
    /// « toute collectée ». Mais sans son identifiant, le bouton de K3-1c
    /// n'aurait rien à envoyer.
    pub arret_remise_id: Option<Uuid>,
    /// Statut de l'arrêt de remise (`a_collecter` → `en_route` → `arrive`).
    pub arret_remise_statut: Option<StatutArret>,
    /// Instant SERVEUR d'arrivée chez le client — affiché sur K4-1a (FR-052) et
    /// base du délai des preuves d'échec.
    pub arrive_chez_client_le: Option<DateTime<Utc>>,
}

/// La course active d'un coursier, telle que `commandes` la connaît.
///
/// Ce n'est PAS la structure servie à l'app : le crate `coursier` la compose
/// avec les empreintes de plaque (`qr`) et le contact du vendeur
/// (`prestataires`) pour produire sa propre `CourseComplete`. La frontière est
/// exactement celle des domaines — `commandes` ne sait rien d'une plaque.
#[derive(Debug, Clone, PartialEq)]
pub struct CourseDuCoursier {
    /// Livraison active.
    pub livraison_id: Uuid,
    /// Commande portée.
    pub commande_id: Uuid,
    /// Zone de la commande — résout les paramètres de configuration.
    pub zone_id: Uuid,
    /// Où en est la livraison.
    pub etat: EtatLivraison,
    /// Devise ISO 4217.
    pub devise: String,
    /// Arrêts de collecte, dans l'ordre de passage.
    pub arrets: Vec<ArretDeCourse>,
    /// Le client et son repère.
    pub client: ClientDeCourse,
    /// De quoi confirmer la remise hors ligne.
    pub remise: RemiseDeCourse,
}

/// Un montant : un entier d'unités mineures et sa devise, jamais l'un sans
/// l'autre (constitution III).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Montant {
    /// Unités mineures.
    pub unites: i64,
    /// Code ISO 4217.
    pub devise: String,
}

/// Une livraison remise dans la journée — base du bandeau de gains (FR-091).
#[derive(Debug, Clone, PartialEq)]
pub struct LivraisonLivree {
    /// Livraison.
    pub livraison_id: Uuid,
    /// Commande portée.
    pub commande_id: Uuid,
    /// Part coursier du devis FIGÉ (unités mineures) — jamais recalculée.
    pub part_coursier_unites: i64,
    /// Devise ISO 4217.
    pub devise: String,
    /// Instant de remise (horodatage serveur).
    pub livree_le: DateTime<Utc>,
}

/// Contrat offert à **CRS** (coursier), cycle 010.
///
/// Une seule lecture doit suffire à faire fonctionner TOUTE la course hors
/// ligne (FR-011, FR-028) : c'est pourquoi `course_active` rend les arrêts,
/// leurs lignes, le client et les empreintes de remise d'un bloc, plutôt que de
/// laisser l'appelant recoudre trois requêtes au pire moment.
///
/// Aucune dépendance inverse : `commandes` ne dépendra jamais de `coursier`,
/// comme il ne dépend jamais de `dispatch`.
#[async_trait]
pub trait CourseCoursier: Send + Sync {
    /// Course active complète d'un coursier. `None` si aucune course.
    ///
    /// « Active » = livraison `assignee`, `en_collecte` ou `en_livraison`. Une
    /// livraison `livree` n'en est plus une : l'app doit basculer, pas garder
    /// une course close à l'écran.
    async fn course_active(
        &self,
        coursier: Uuid,
    ) -> Result<Option<CourseDuCoursier>, ErreurCommandes>;

    /// Montant total à encaisser, recalculé après substitutions (FR-023).
    async fn montant_a_encaisser(&self, livraison: Uuid) -> Result<Montant, ErreurCommandes>;

    /// Livraisons dont la remise est validée sur un jour civil de zone
    /// (bandeau de gains, FR-091).
    ///
    /// Le jour est passé par l'appelant, déjà résolu dans le fuseau de la zone :
    /// `commandes` n'a pas à connaître `zone.fuseau_horaire`, et un jour calculé
    /// dans le fuseau du serveur ferait basculer les gains de Yao à minuit
    /// UTC — c'est-à-dire à minuit tout court à Abidjan, mais par accident.
    async fn livrees_du_jour(
        &self,
        coursier: Uuid,
        debut: DateTime<Utc>,
        fin: DateTime<Utc>,
    ) -> Result<Vec<LivraisonLivree>, ErreurCommandes>;
}

/// Double de test de [`CourseCoursier`] : une course posée d'avance.
///
/// Patron `ArretsFixes` / `PreuvesFixes`. Il permet d'exercer la composition du
/// crate `coursier` — plaque, contact vendeur, seuils de preuve — sans monter
/// une base de commandes complète.
#[derive(Debug, Default)]
pub struct CourseFixe {
    courses: Mutex<HashMap<Uuid, CourseDuCoursier>>,
    livrees: Mutex<HashMap<Uuid, Vec<LivraisonLivree>>>,
}

impl CourseFixe {
    /// Nouveau double : aucun coursier n'a de course.
    pub fn nouveau() -> Self {
        Self::default()
    }

    /// Pose la course active d'un coursier.
    pub fn definir(&self, coursier: Uuid, course: CourseDuCoursier) {
        self.courses
            .lock()
            .expect("courses")
            .insert(coursier, course);
    }

    /// Retire la course (simule une clôture ou une réassignation).
    pub fn retirer(&self, coursier: Uuid) {
        self.courses.lock().expect("courses").remove(&coursier);
    }

    /// Pose les livraisons du jour d'un coursier.
    pub fn definir_livrees(&self, coursier: Uuid, livrees: Vec<LivraisonLivree>) {
        self.livrees
            .lock()
            .expect("livrees")
            .insert(coursier, livrees);
    }
}

#[async_trait]
impl CourseCoursier for CourseFixe {
    async fn course_active(
        &self,
        coursier: Uuid,
    ) -> Result<Option<CourseDuCoursier>, ErreurCommandes> {
        Ok(self.courses.lock().expect("courses").get(&coursier).cloned())
    }

    async fn montant_a_encaisser(&self, livraison: Uuid) -> Result<Montant, ErreurCommandes> {
        let courses = self.courses.lock().expect("courses");
        let course = courses
            .values()
            .find(|c| c.livraison_id == livraison)
            .ok_or(ErreurCommandes::LivraisonInconnue(livraison))?;
        Ok(Montant {
            unites: course.remise.montant_a_encaisser_unites,
            devise: course.devise.clone(),
        })
    }

    async fn livrees_du_jour(
        &self,
        coursier: Uuid,
        debut: DateTime<Utc>,
        fin: DateTime<Utc>,
    ) -> Result<Vec<LivraisonLivree>, ErreurCommandes> {
        Ok(self
            .livrees
            .lock()
            .expect("livrees")
            .get(&coursier)
            .map(|v| {
                v.iter()
                    .filter(|l| l.livree_le >= debut && l.livree_le < fin)
                    .cloned()
                    .collect()
            })
            .unwrap_or_default())
    }
}

// ── CONSOMMÉ : restrictions de compte (CPT-06, research R12) ───────────────

/// Restrictions de compte — **implémenté dans le crate `comptes`**, dont c'est
/// le schéma (constitution II). CMD ne cite jamais `comptes.compte` en écriture.
#[async_trait]
pub trait RestrictionsCompte: Send + Sync {
    /// Restrictions courantes du compte (prépaiement imposé, blocage).
    async fn restrictions(&self, compte: Uuid) -> Result<Restrictions, ErreurCommandes>;

    /// Pose une sanction DANS la transaction fournie, avec son événement
    /// `sanction.posee` — l'atomicité est impossible à contourner (VI).
    async fn poser_restriction(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        compte: Uuid,
        sanction: Sanction,
        motif_cle: &str,
    ) -> Result<(), ErreurCommandes>;
}

/// Adaptateur de PRODUCTION : le dépôt du crate `comptes` satisfait le port.
///
/// Le trait est local à `commandes`, le type est étranger — la règle d'orphelin
/// autorise cette implémentation, et c'est elle qui referme le montage de
/// **P3** : toute la SQL qui touche `comptes.compte` vit dans le crate
/// `comptes` (`restriction.rs`), `commandes` n'en écrit pas une ligne.
///
/// `Sanction::Aucune` n'est pas une pose : la demander ne fait rien.
#[async_trait]
impl RestrictionsCompte for comptes::PgComptes {
    async fn restrictions(&self, compte: Uuid) -> Result<Restrictions, ErreurCommandes> {
        Ok(comptes::RestrictionsDeCompte::restrictions_de(self, compte).await?)
    }

    async fn poser_restriction(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        compte: Uuid,
        sanction: Sanction,
        motif_cle: &str,
    ) -> Result<(), ErreurCommandes> {
        let Some(sanction) = sanction.pour_compte() else {
            return Ok(());
        };
        comptes::PgComptes::poser_restriction(self, tx, compte, sanction, motif_cle).await?;
        Ok(())
    }
}

/// Double de test : restrictions en mémoire, sanctions mémorisées.
#[derive(Debug, Default)]
pub struct RestrictionsSimulees {
    etat: Mutex<HashMap<Uuid, Restrictions>>,
    posees: Mutex<Vec<(Uuid, Sanction, String)>>,
}

impl RestrictionsSimulees {
    /// Nouveau double : aucun compte restreint.
    pub fn nouveau() -> Self {
        Self::default()
    }

    /// Force les restrictions d'un compte.
    pub fn definir(&self, compte: Uuid, restrictions: Restrictions) {
        self.etat.lock().expect("etat").insert(compte, restrictions);
    }

    /// Sanctions posées depuis la création du double, dans l'ordre.
    pub fn posees(&self) -> Vec<(Uuid, Sanction, String)> {
        self.posees.lock().expect("posees").clone()
    }
}

#[async_trait]
impl RestrictionsCompte for RestrictionsSimulees {
    async fn restrictions(&self, compte: Uuid) -> Result<Restrictions, ErreurCommandes> {
        Ok(self
            .etat
            .lock()
            .expect("etat")
            .get(&compte)
            .copied()
            .unwrap_or_default())
    }

    async fn poser_restriction(
        &self,
        _tx: &mut sqlx::PgTransaction<'_>,
        compte: Uuid,
        sanction: Sanction,
        motif_cle: &str,
    ) -> Result<(), ErreurCommandes> {
        self.posees
            .lock()
            .expect("posees")
            .push((compte, sanction, motif_cle.to_owned()));
        let mut etat = self.etat.lock().expect("etat");
        let r = etat.entry(compte).or_default();
        match sanction {
            Sanction::PrepaiementImpose => r.prepaiement_impose = true,
            Sanction::Bloque => r.bloque = true,
            Sanction::Aucune => {}
        }
        Ok(())
    }
}

// ── CONSOMMÉ : preuves d'échec (CRS-05, non construit) ─────────────────────

/// Preuves réunies pour déclarer un échec (FR-056). Tant qu'elles ne le sont
/// pas, l'échec est REFUSÉ : « le coursier ne perd jamais » suppose une trace.
#[async_trait]
pub trait PreuvesEchec: Send + Sync {
    /// Vrai si les preuves de la livraison sont complètes.
    async fn preuves_reunies(&self, livraison: Uuid) -> Result<bool, ErreurCommandes>;
}

/// Double de test : preuves réunies ou non, par livraison (défaut : non).
#[derive(Debug, Default)]
pub struct PreuvesFixes {
    reunies: Mutex<HashMap<Uuid, bool>>,
    defaut: Mutex<bool>,
}

impl PreuvesFixes {
    /// Nouveau double — par défaut, AUCUNE preuve n'est réunie (le défaut le
    /// plus sûr : un test qui oublie de les poser voit son échec refusé).
    pub fn nouveau() -> Self {
        Self::default()
    }

    /// Preuves réunies (ou non) pour une livraison donnée.
    pub fn definir(&self, livraison: Uuid, reunies: bool) {
        self.reunies
            .lock()
            .expect("reunies")
            .insert(livraison, reunies);
    }

    /// Réponse par défaut pour les livraisons non renseignées.
    pub fn definir_defaut(&self, reunies: bool) {
        *self.defaut.lock().expect("defaut") = reunies;
    }
}

#[async_trait]
impl PreuvesEchec for PreuvesFixes {
    async fn preuves_reunies(&self, livraison: Uuid) -> Result<bool, ErreurCommandes> {
        let defaut = *self.defaut.lock().expect("defaut");
        Ok(self
            .reunies
            .lock()
            .expect("reunies")
            .get(&livraison)
            .copied()
            .unwrap_or(defaut))
    }
}

// ── CONSOMMÉ : position du coursier (Redis éphémère, research R13) ─────────

/// Dernière position connue d'un coursier, **avec son âge**.
///
/// L'âge est ce qui empêche l'app d'inventer une position (FR-040, maquette
/// C4-4d « Position non actualisée — il y a 4 min »).
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct PositionDatee {
    /// Latitude.
    pub lat: f64,
    /// Longitude.
    pub lon: f64,
    /// Instant de relevé (serveur).
    pub releve_le: DateTime<Utc>,
    /// Âge en secondes au moment de la lecture.
    pub age_s: i64,
}

/// Lecture de la dernière position d'un coursier.
///
/// ⚠ L'absence de position renvoie `None`, **jamais** une erreur : Redis
/// indisponible ne doit pas casser un suivi (research R13).
#[async_trait]
pub trait PositionCoursier: Send + Sync {
    /// Dernière position connue, ou `None` si aucune n'est disponible.
    async fn derniere(&self, coursier: Uuid) -> Result<Option<PositionDatee>, ErreurCommandes>;
}

/// Double de test : position fixe par coursier, ou absence de position.
#[derive(Debug, Default)]
pub struct PositionFixe {
    positions: Mutex<HashMap<Uuid, PositionDatee>>,
}

impl PositionFixe {
    /// Nouveau double — aucun coursier n'a de position.
    pub fn nouveau() -> Self {
        Self::default()
    }

    /// Pose la position d'un coursier et son âge.
    pub fn definir(&self, coursier: Uuid, position: PositionDatee) {
        self.positions
            .lock()
            .expect("positions")
            .insert(coursier, position);
    }

    /// Retire la position (simule l'expiration du TTL Redis).
    pub fn retirer(&self, coursier: Uuid) {
        self.positions.lock().expect("positions").remove(&coursier);
    }
}

#[async_trait]
impl PositionCoursier for PositionFixe {
    async fn derniere(&self, coursier: Uuid) -> Result<Option<PositionDatee>, ErreurCommandes> {
        Ok(self
            .positions
            .lock()
            .expect("positions")
            .get(&coursier)
            .copied())
    }
}

// ── Doubles TARIFAIRES (cycle 007 réel en production) ─────────────────────

/// Double de test du moteur tarifaire : un devis **fixe**, un ordre d'arrêts
/// **identité**.
///
/// Le vrai moteur (cycle 007) est branché en production ; ici, un devis figé et
/// connu d'avance permet d'asserter des montants au FCFA près sans OSRM ni
/// grille — et surtout de prouver que le devis **ne bouge pas** après une
/// substitution ou un retrait (FR-050), ce qu'un devis calculé rendrait flou.
#[derive(Debug, Clone)]
pub struct TarifFixe {
    devis: tarification::Devis,
    /// Demandes REÇUES, dans l'ordre. Le double ne rejoue pas l'arbitrage du
    /// moteur (ce serait un second moteur, et il mentirait le jour où le vrai
    /// changerait) : il se contente de garder trace de ce qu'on lui a passé,
    /// pour qu'un test puisse prouver que CMD transmet bien l'offre du vendeur
    /// — et seulement en mono-vendeur (cycle 011, T054/T056).
    demandes: Arc<Mutex<Vec<tarification::DemandeDevis>>>,
}

impl TarifFixe {
    /// Devis fixe complet.
    pub fn nouveau(devis: tarification::Devis) -> Self {
        Self {
            devis,
            demandes: Arc::new(Mutex::new(Vec::new())),
        }
    }

    /// Devis simple : prix client, part coursier, marge, en XOF.
    pub fn simple(prix_client: i64, part_coursier: i64, marge: i64) -> Self {
        Self {
            demandes: Arc::new(Mutex::new(Vec::new())),
            devis: tarification::Devis {
                prix_client,
                part_coursier,
                marge,
                devise: "XOF".to_owned(),
                distance_m: 2_400,
                eta_s: 480,
                degraded: false,
                proposer_scission: false,
                ordre: Vec::new(),
                composantes: tarification::Composantes::default(),
            },
        }
    }

    /// Remplace les composantes du devis fixe.
    ///
    /// `simple` les laisse toutes à zéro, et c'est un double qui MENT : aucun
    /// devis réel n'a une part coursier non nulle sous des composantes vides.
    /// Un test qui décompose le gain lit alors des zéros, et passe quoi qu'on
    /// lui donne — c'est ainsi que « 0 + 0 + 0 » sous un gain de 150 FCFA a
    /// survécu jusqu'à la validation sur émulateur (T071).
    ///
    /// À l'appelant de garder l'invariant du modèle :
    /// `part_coursier = base − marge + km + supplements + effort + arrondi`.
    pub fn avec_composantes(mut self, composantes: tarification::Composantes) -> Self {
        self.devis.composantes = composantes;
        self
    }

    /// Force le drapeau de proposition de scission (plafond d'éclatement).
    pub fn avec_proposer_scission(mut self, proposer: bool) -> Self {
        self.devis.proposer_scission = proposer;
        self
    }

    /// Le devis servi (pour asserter l'invariance côté test).
    pub fn devis(&self) -> &tarification::Devis {
        &self.devis
    }

    /// Demandes d'évaluation reçues, dans l'ordre — ce que CMD a réellement
    /// transmis au moteur (offre du vendeur, drapeau mono-vendeur, panier).
    pub fn demandes_recues(&self) -> Vec<tarification::DemandeDevis> {
        self.demandes.lock().expect("verrou du double").clone()
    }
}

#[async_trait]
impl tarification::EvaluationTarifaire for TarifFixe {
    async fn evaluer(
        &self,
        demande: tarification::DemandeDevis,
        _source: tarification::SourceGrille,
    ) -> Result<tarification::Devis, tarification::ErreurTarif> {
        let mut devis = self.devis.clone();
        // L'ordre suit le nombre de retraits demandés : un double qui renverrait
        // un ordre plus court ferait silencieusement disparaître des arrêts.
        devis.ordre = (0..demande.retraits.len()).collect();
        self.demandes
            .lock()
            .expect("verrou du double")
            .push(demande);
        Ok(devis)
    }
}

#[async_trait]
impl tarification::OptimisationArrets for TarifFixe {
    async fn optimiser(
        &self,
        _zone: Uuid,
        retraits: &[tarification::Point],
        _client: tarification::Point,
    ) -> Result<tarification::Itineraire, tarification::ErreurTarif> {
        Ok(tarification::Itineraire {
            ordre: (0..retraits.len()).collect(),
            distance_m: self.devis.distance_m,
            eta_s: self.devis.eta_s,
            degraded: self.devis.degraded,
            troncons: Vec::new(),
            exhaustif: true,
        })
    }
}

// ── Port CommandesAPayer (cycle PAY 011, contracts §2) ─────────────────────

/// Ce que le crate `paiements` a besoin de savoir d'une commande pour ouvrir
/// une session — et rien de plus.
///
/// Le total est **figé** : c'est lui qui est comparé au montant annoncé par une
/// notification (FR-024). Le comparer au total *courant* de la commande
/// transformerait un retrait de ligne postérieur en divergence de paiement.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CommandeAPayer {
    pub commande_id: Uuid,
    pub zone_id: Uuid,
    /// Propriétaire — la garde de propriété de l'endpoint s'appuie dessus.
    pub client_id: Uuid,
    pub total_unites: i64,
    pub devise: String,
    pub mode_paiement: ModePaiement,
    pub etat: EtatCommande,
    pub etat_paiement: EtatPaiement,
}

impl CommandeAPayer {
    /// Vrai si une session de prépaiement a lieu d'être ouverte (FR-010).
    ///
    /// Trois conditions, et chacune correspond à un `409 paiement_non_requis` :
    /// une commande **cash** ne passe par aucun fournisseur ; une commande
    /// **déjà réglée** ne se paie pas deux fois ; une commande qui n'est plus
    /// `en_attente_paiement` (annulée, déjà partie) n'attend plus rien.
    pub fn attend_un_paiement(&self) -> bool {
        self.mode_paiement == ModePaiement::MobileMoney
            && self.etat == EtatCommande::EnAttentePaiement
            && self.etat_paiement != EtatPaiement::Regle
    }
}

/// Ce que `paiements` demande à `commandes`.
///
/// Deux des quatre méthodes **branchent un chemin existant** plutôt que d'en
/// écrire un second (FR-032) : `confirmer_prepaiement` et l'annulation vivent
/// depuis le cycle 008, avec leurs transitions gardées et leurs événements. Ce
/// cycle les appelle ; il ne les réécrit pas. Une seconde règle d'annulation
/// aurait divergé de la première au premier correctif.
#[async_trait]
pub trait CommandesAPayer: Send + Sync {
    /// Total FIGÉ, devise, propriétaire et état — ce sur quoi la session
    /// s'ouvre.
    async fn a_payer(&self, commande: Uuid) -> Result<CommandeAPayer, ErreurCommandes>;

    /// Pose `etat_paiement = 'en_attente'` (research R16, FR-014).
    ///
    /// La valeur d'enum existe depuis la migration 0008 et **aucune ligne de
    /// code ne l'a jamais écrite** : une commande mobile money restait à `'du'`,
    /// indiscernable d'une commande cash. C'est ce cycle qui la pose enfin.
    async fn marquer_paiement_en_attente(
        &self,
        commande: Uuid,
        quand: DateTime<Utc>,
    ) -> Result<(), ErreurCommandes>;

    /// Chemin **existant** du cycle 008 : `en_attente_paiement → nouvelle`,
    /// `etat_paiement = 'regle'`, événement `commande.paiement_confirme`
    /// (déjà consommé par le pipeline de dispatch depuis le cycle 009).
    async fn confirmer_prepaiement(
        &self,
        commande: Uuid,
        quand: DateTime<Utc>,
    ) -> Result<(), ErreurCommandes>;

    /// Chemin **existant** d'annulation, avec le motif d'expiration (FR-031,
    /// FR-032). Sans frais, et sans part coursier due : rien n'a été acheté.
    async fn annuler_pour_expiration(
        &self,
        commande: Uuid,
        quand: DateTime<Utc>,
    ) -> Result<(), ErreurCommandes>;
}

/// Motif d'annulation d'une session de paiement expirée.
///
/// Clé i18n, jamais du texte libre : elle sera lue par Awa, dans sa langue — et
/// **sans jargon de paiement** (ni « transaction », ni « session », ni
/// « fournisseur »). Elle n'a pas à connaître notre plomberie pour comprendre
/// qu'elle n'a rien payé.
pub const MOTIF_ANNULATION_EXPIRATION: &str = "commande.annulation.paiement_expire";

/// Double **en mémoire** de [`CommandesAPayer`] — patron `ArretsFixes`.
///
/// Permet d'exercer `paiements` sans base : ouverture, idempotence, expiration
/// et réconciliation se testent sur des types purs. Il note les appels reçus
/// pour que les tests puissent asserter qu'un chemin a bien été emprunté —
/// notamment qu'une session expirée annule **une** fois et pas deux.
#[derive(Debug, Default)]
pub struct CommandesAPayerEnMemoire {
    commandes: Mutex<HashMap<Uuid, CommandeAPayer>>,
    en_attente: Mutex<Vec<Uuid>>,
    confirmees: Mutex<Vec<Uuid>>,
    annulees: Mutex<Vec<Uuid>>,
}

impl CommandesAPayerEnMemoire {
    pub fn nouveau() -> Self {
        Self::default()
    }

    /// Enregistre une commande interrogeable.
    pub fn ajouter(&self, commande: CommandeAPayer) {
        self.commandes
            .lock()
            .expect("commandes")
            .insert(commande.commande_id, commande);
    }

    /// Commande mobile money en attente de paiement — le cas nominal.
    pub fn ajouter_prepayable(
        &self,
        commande_id: Uuid,
        client_id: Uuid,
        total_unites: i64,
    ) -> CommandeAPayer {
        let c = CommandeAPayer {
            commande_id,
            zone_id: Uuid::now_v7(),
            client_id,
            total_unites,
            devise: "XOF".to_owned(),
            mode_paiement: ModePaiement::MobileMoney,
            etat: EtatCommande::EnAttentePaiement,
            etat_paiement: EtatPaiement::Du,
        };
        self.ajouter(c.clone());
        c
    }

    /// Commandes passées à `marquer_paiement_en_attente`.
    pub fn mises_en_attente(&self) -> Vec<Uuid> {
        self.en_attente.lock().expect("en_attente").clone()
    }

    /// Commandes confirmées.
    pub fn confirmees(&self) -> Vec<Uuid> {
        self.confirmees.lock().expect("confirmees").clone()
    }

    /// Commandes annulées pour expiration.
    pub fn annulees(&self) -> Vec<Uuid> {
        self.annulees.lock().expect("annulees").clone()
    }
}

#[async_trait]
impl CommandesAPayer for CommandesAPayerEnMemoire {
    async fn a_payer(&self, commande: Uuid) -> Result<CommandeAPayer, ErreurCommandes> {
        self.commandes
            .lock()
            .expect("commandes")
            .get(&commande)
            .cloned()
            .ok_or(ErreurCommandes::CommandeInconnue(commande))
    }

    async fn marquer_paiement_en_attente(
        &self,
        commande: Uuid,
        _quand: DateTime<Utc>,
    ) -> Result<(), ErreurCommandes> {
        self.en_attente.lock().expect("en_attente").push(commande);
        if let Some(c) = self.commandes.lock().expect("commandes").get_mut(&commande) {
            c.etat_paiement = EtatPaiement::EnAttente;
        }
        Ok(())
    }

    async fn confirmer_prepaiement(
        &self,
        commande: Uuid,
        _quand: DateTime<Utc>,
    ) -> Result<(), ErreurCommandes> {
        self.confirmees.lock().expect("confirmees").push(commande);
        if let Some(c) = self.commandes.lock().expect("commandes").get_mut(&commande) {
            c.etat = EtatCommande::Nouvelle;
            c.etat_paiement = EtatPaiement::Regle;
        }
        Ok(())
    }

    async fn annuler_pour_expiration(
        &self,
        commande: Uuid,
        _quand: DateTime<Utc>,
    ) -> Result<(), ErreurCommandes> {
        self.annulees.lock().expect("annulees").push(commande);
        if let Some(c) = self.commandes.lock().expect("commandes").get_mut(&commande) {
            c.etat = EtatCommande::Annulee;
        }
        Ok(())
    }
}

// ── Double de PAIEMENT (PAY non construit, research R16) ───────────────────

/// Double de test du module paiements : confirme un prépaiement ou le fait
/// expirer. Aucun trait n'est déclaré côté domaine — PAY posera le sien à son
/// cycle ; ici, le double sert à piloter l'état de paiement dans les tests, à
/// travers les transitions gardées du tronc.
#[derive(Debug, Default)]
pub struct PaiementSimule {
    confirmes: Mutex<Vec<Uuid>>,
    expires: Mutex<Vec<Uuid>>,
}

impl PaiementSimule {
    /// Nouveau double.
    pub fn nouveau() -> Self {
        Self::default()
    }

    /// Note un prépaiement comme confirmé.
    pub fn confirmer(&self, commande: Uuid) {
        self.confirmes.lock().expect("confirmes").push(commande);
    }

    /// Note un prépaiement comme expiré.
    pub fn expirer(&self, commande: Uuid) {
        self.expires.lock().expect("expires").push(commande);
    }

    /// Vrai si le prépaiement de cette commande a été confirmé.
    pub fn est_confirme(&self, commande: Uuid) -> bool {
        self.confirmes.lock().expect("confirmes").contains(&commande)
    }

    /// Vrai si le prépaiement de cette commande a expiré.
    pub fn est_expire(&self, commande: Uuid) -> bool {
        self.expires.lock().expect("expires").contains(&commande)
    }
}

#[cfg(test)]
mod tests_paiement {
    use super::*;

    /// Les trois cas où l'ouverture d'une session est REFUSÉE, et le seul où
    /// elle est permise. Chacun correspond à un `409 paiement_non_requis` de
    /// l'endpoint (FR-010) : le test les nomme ici pour que la règle vive dans
    /// le domaine et non dans le handler HTTP.
    #[test]
    fn seule_une_commande_mobile_money_en_attente_appelle_un_paiement() {
        let base = CommandeAPayer {
            commande_id: Uuid::now_v7(),
            zone_id: Uuid::now_v7(),
            client_id: Uuid::now_v7(),
            total_unites: 20_000,
            devise: "XOF".to_owned(),
            mode_paiement: ModePaiement::MobileMoney,
            etat: EtatCommande::EnAttentePaiement,
            etat_paiement: EtatPaiement::Du,
        };
        assert!(base.attend_un_paiement(), "le cas nominal");

        // Une commande CASH ne passe par aucun fournisseur.
        let mut cash = base.clone();
        cash.mode_paiement = ModePaiement::Cash;
        assert!(!cash.attend_un_paiement());

        // Une commande DÉJÀ RÉGLÉE ne se paie pas deux fois. C'est la garde
        // qui empêche un second `POST` de rouvrir une session sur une commande
        // confirmée entre-temps.
        let mut reglee = base.clone();
        reglee.etat_paiement = EtatPaiement::Regle;
        assert!(!reglee.attend_un_paiement());

        // Une commande ANNULÉE (ou déjà partie) n'attend plus rien.
        let mut annulee = base.clone();
        annulee.etat = EtatCommande::Annulee;
        assert!(!annulee.attend_un_paiement());
    }

    /// Le double suit l'état comme le ferait la base : marquer, confirmer,
    /// annuler laissent la commande dans l'état que l'endpoint relira.
    #[tokio::test]
    async fn le_double_suit_les_trois_ecritures() {
        let depot = CommandesAPayerEnMemoire::nouveau();
        let commande = Uuid::now_v7();
        let client = Uuid::now_v7();
        depot.ajouter_prepayable(commande, client, 20_000);
        let quand = Utc::now();

        depot
            .marquer_paiement_en_attente(commande, quand)
            .await
            .unwrap();
        assert_eq!(depot.mises_en_attente(), vec![commande]);
        assert_eq!(
            depot.a_payer(commande).await.unwrap().etat_paiement,
            EtatPaiement::EnAttente,
            "R16 — la valeur `en_attente` existe depuis 0008 et personne ne la posait",
        );

        depot.confirmer_prepaiement(commande, quand).await.unwrap();
        let apres = depot.a_payer(commande).await.unwrap();
        assert_eq!(apres.etat, EtatCommande::Nouvelle, "le tronc repart");
        assert_eq!(apres.etat_paiement, EtatPaiement::Regle);
        assert!(
            !apres.attend_un_paiement(),
            "une commande confirmée n'attend plus de paiement",
        );
    }

    /// L'annulation pour expiration passe par le double sans le rejouer : le
    /// test d'expiration s'appuie dessus pour prouver qu'une session échue
    /// n'annule qu'UNE fois.
    #[tokio::test]
    async fn l_annulation_pour_expiration_est_observable() {
        let depot = CommandesAPayerEnMemoire::nouveau();
        let commande = Uuid::now_v7();
        depot.ajouter_prepayable(commande, Uuid::now_v7(), 20_000);

        assert!(depot.annulees().is_empty());
        depot
            .annuler_pour_expiration(commande, Utc::now())
            .await
            .unwrap();
        assert_eq!(depot.annulees(), vec![commande]);
        assert_eq!(depot.a_payer(commande).await.unwrap().etat, EtatCommande::Annulee);
    }

    /// Une commande inconnue est une erreur nommée, pas un `None` silencieux :
    /// l'endpoint doit pouvoir rendre `404` plutôt que d'ouvrir une session sur
    /// du vide.
    #[tokio::test]
    async fn une_commande_inconnue_est_une_erreur() {
        let depot = CommandesAPayerEnMemoire::nouveau();
        assert!(matches!(
            depot.a_payer(Uuid::now_v7()).await.unwrap_err(),
            ErreurCommandes::CommandeInconnue(_),
        ));
    }

    /// Le motif d'annulation est une CLÉ i18n, et elle ne contient aucun jargon
    /// de paiement : Awa lira « votre commande a été annulée », pas
    /// « transaction expirée ».
    #[test]
    fn le_motif_d_expiration_est_une_cle_sans_jargon() {
        assert_eq!(
            MOTIF_ANNULATION_EXPIRATION,
            "commande.annulation.paiement_expire",
        );
        for jargon in ["transaction", "session", "fournisseur", "webhook"] {
            assert!(
                !MOTIF_ANNULATION_EXPIRATION.contains(jargon),
                "la clé ne doit pas porter le mot « {jargon} »",
            );
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn arret(arret_id: Uuid, prestataire: Uuid) -> ArretACollecter {
        ArretACollecter {
            arret_id,
            livraison_id: Uuid::now_v7(),
            segment_id: Uuid::now_v7(),
            commande_id: Uuid::now_v7(),
            prestataire_id: prestataire,
            site_lat: 5.898,
            site_lon: -4.823,
            montant_avance: 2000,
            devise: "XOF".to_owned(),
        }
    }

    #[tokio::test]
    async fn autoriser_puis_retirer() {
        let coursier = Uuid::now_v7();
        let presta = Uuid::now_v7();
        let a = Uuid::now_v7();
        let fixes = ArretsFixes::nouveau();
        assert!(fixes
            .arret_a_collecter(coursier, presta)
            .await
            .unwrap()
            .is_none());
        fixes.autoriser(coursier, presta, arret(a, presta));
        assert_eq!(
            fixes
                .arret_a_collecter(coursier, presta)
                .await
                .unwrap()
                .unwrap()
                .arret_id,
            a
        );
        fixes.retirer(coursier, presta);
        assert!(fixes
            .arret_a_collecter(coursier, presta)
            .await
            .unwrap()
            .is_none());
    }

    fn course_fixe_type(coursier: Uuid) -> CourseDuCoursier {
        CourseDuCoursier {
            livraison_id: Uuid::now_v7(),
            commande_id: Uuid::now_v7(),
            zone_id: Uuid::now_v7(),
            etat: EtatLivraison::EnCollecte,
            devise: "XOF".to_owned(),
            arrets: vec![ArretDeCourse {
                arret_id: Uuid::now_v7(),
                ordre: 0,
                prestataire_id: coursier,
                site_lat: 5.898,
                site_lon: -4.823,
                distance_precedent_m: None,
                montant_avance: 1_500,
                // Aucune livraison offerte dans le cas type : le net et le brut
                // coïncident, et c'est bien la situation ordinaire.
                montant_articles_unites: 1_500,
                retenue_appliquee_unites: 0,
                statut: StatutArret::ACollecter,
                en_route_le: None,
                arrive_le: None,
                collecte_le: None,
                lignes: vec![LigneDeCourse {
                    ligne_id: Uuid::now_v7(),
                    libelle: "Tomates".to_owned(),
                    quantite: 2,
                    prix_unitaire_unites: 400,
                    preference: PreferenceSubstitution::Appeler,
                    statut: StatutLigne::Presente,
                }],
            }],
            client: ClientDeCourse {
                compte_id: Uuid::now_v7(),
                nom_usage: None,
                telephone: Some("+2250700000002".to_owned()),
                repere_texte: Some("Cour verte après la pharmacie".to_owned()),
                repere_vocal_cle: None,
                repere_vocal_duree_s: None,
                lieu_lat: 5.905,
                lieu_lon: -4.830,
                depot_autorise: false,
            },
            remise: RemiseDeCourse {
                empreinte_code: "a1b2".to_owned(),
                empreinte_jeton: "c3d4".to_owned(),
                essais_consommes: 0,
                code_bloque: false,
                montant_a_encaisser_unites: 5_800,
                mode_paiement: ModePaiement::Cash,
                arret_remise_id: None,
                arret_remise_statut: None,
                arrive_chez_client_le: None,
            },
        }
    }

    #[tokio::test]
    async fn course_fixe_pose_et_retire_une_course() {
        let coursier = Uuid::now_v7();
        let fixe = CourseFixe::nouveau();
        assert!(fixe.course_active(coursier).await.unwrap().is_none());

        let course = course_fixe_type(coursier);
        let livraison = course.livraison_id;
        fixe.definir(coursier, course);
        let vue = fixe.course_active(coursier).await.unwrap().unwrap();
        assert_eq!(vue.arrets.len(), 1);
        assert_eq!(vue.arrets[0].lignes.len(), 1);
        assert_eq!(
            fixe.montant_a_encaisser(livraison).await.unwrap(),
            Montant {
                unites: 5_800,
                devise: "XOF".to_owned()
            },
        );

        // Réassignation : la course disparaît du coursier, et le montant d'une
        // livraison qu'il ne porte plus n'est plus lisible par lui.
        fixe.retirer(coursier);
        assert!(fixe.course_active(coursier).await.unwrap().is_none());
        assert!(fixe.montant_a_encaisser(livraison).await.is_err());
    }

    /// Le double ne SERT que ce qui tombe dans la fenêtre du jour : sans ce
    /// filtre, un test de bascule de jour civil (SC-013) passerait en comptant
    /// les gains de la veille.
    #[tokio::test]
    async fn course_fixe_filtre_les_livrees_sur_la_fenetre() {
        let coursier = Uuid::now_v7();
        let fixe = CourseFixe::nouveau();
        let minuit = "2026-07-28T00:00:00Z".parse::<DateTime<Utc>>().unwrap();
        let demain = "2026-07-29T00:00:00Z".parse::<DateTime<Utc>>().unwrap();
        let livree = |quand: &str| LivraisonLivree {
            livraison_id: Uuid::now_v7(),
            commande_id: Uuid::now_v7(),
            part_coursier_unites: 1_200,
            devise: "XOF".to_owned(),
            livree_le: quand.parse().unwrap(),
        };
        fixe.definir_livrees(
            coursier,
            vec![
                livree("2026-07-27T23:59:00Z"), // la veille
                livree("2026-07-28T14:32:00Z"), // le jour
                livree("2026-07-29T00:00:01Z"), // le lendemain
            ],
        );

        let jour = fixe.livrees_du_jour(coursier, minuit, demain).await.unwrap();
        assert_eq!(jour.len(), 1, "seule la course du jour compte");
        assert_eq!(jour[0].part_coursier_unites, 1_200);
    }

    /// Aucun secret ne peut être posé dans la course : les champs n'existent
    /// pas. Un test qui compile est ici la moitié de la preuve — l'autre moitié
    /// est cette assertion sur ce qui EST servi (FR-037).
    #[tokio::test]
    async fn la_course_ne_porte_que_des_empreintes() {
        let coursier = Uuid::now_v7();
        let fixe = CourseFixe::nouveau();
        fixe.definir(coursier, course_fixe_type(coursier));
        let vue = fixe.course_active(coursier).await.unwrap().unwrap();
        assert_eq!(vue.remise.empreinte_code, "a1b2");
        assert_eq!(vue.remise.empreinte_jeton, "c3d4");
        assert!(
            vue.client.nom_usage.is_none(),
            "aucune donnée nominative n'existe au MVP (cycle CPT 003) — le champ \
             est servi optionnel, jamais fabriqué depuis le numéro",
        );
    }

    #[tokio::test]
    async fn preuves_fixes_refusent_par_defaut() {
        let livraison = Uuid::now_v7();
        let preuves = PreuvesFixes::nouveau();
        assert!(
            !preuves.preuves_reunies(livraison).await.unwrap(),
            "le défaut le plus sûr : sans preuve posée, l'échec est refusé",
        );
        preuves.definir(livraison, true);
        assert!(preuves.preuves_reunies(livraison).await.unwrap());
    }

    #[tokio::test]
    async fn position_absente_rend_none_jamais_une_erreur() {
        let coursier = Uuid::now_v7();
        let fixe = PositionFixe::nouveau();
        assert!(fixe.derniere(coursier).await.unwrap().is_none());
        fixe.definir(
            coursier,
            PositionDatee {
                lat: 5.898,
                lon: -4.823,
                releve_le: Utc::now(),
                age_s: 12,
            },
        );
        assert_eq!(fixe.derniere(coursier).await.unwrap().unwrap().age_s, 12);
        // Expiration du TTL Redis → absence, pas erreur (research R13).
        fixe.retirer(coursier);
        assert!(fixe.derniere(coursier).await.unwrap().is_none());
    }

    #[tokio::test]
    async fn restrictions_simulees_cumulent_les_sanctions() {
        let compte = Uuid::now_v7();
        let doubles = RestrictionsSimulees::nouveau();
        assert_eq!(
            doubles.restrictions(compte).await.unwrap(),
            Restrictions::default(),
            "aucun compte n'est restreint par défaut",
        );
        doubles.definir(
            compte,
            Restrictions {
                prepaiement_impose: true,
                bloque: false,
            },
        );
        assert!(doubles.restrictions(compte).await.unwrap().prepaiement_impose);
        assert!(!doubles.restrictions(compte).await.unwrap().bloque);
    }
}
