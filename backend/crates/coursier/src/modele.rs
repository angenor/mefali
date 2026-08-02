//! Types publics du domaine coursier (contracts/ports-coursier.md §4).
//!
//! Réutilise les types de `commandes` partout où ils existent déjà
//! (`StatutArret`, `PreferenceSubstitution`, `StatutLigne`, `ModePaiement`,
//! `EtatLivraison`) : une seconde définition de « ligne présente » divergerait
//! au premier changement. Les DTO HTTP (avec `ToSchema`) vivent dans la couche
//! `api` ; ici, seulement le domaine.
//!
//! **Montants** : entiers en unités mineures + devise ISO 4217, jamais un float
//! (constitution III). **Distances** : entiers de mètres, arrondies (IV, R8).
//! **Secrets** : seules des EMPREINTES circulent — ni code, ni jeton (FR-037).

use std::str::FromStr;

use chrono::{DateTime, Utc};
use commandes::{EtatLivraison, ModePaiement, PreferenceSubstitution, StatutArret, StatutLigne};
use uuid::Uuid;

use crate::creance::Creance;

// ── Course active pré-provisionnée ─────────────────────────────────────────

/// Une ligne d'article à acheter chez un vendeur (K3, FR-012).
///
/// Elle vient de `commandes.ligne_commande` : ce cycle ne crée aucune table de
/// checklist. La **coche** de l'article reste locale à l'appareil (R11) — le
/// serveur ne connaît que « ligne présente / remplacée / retirée ».
#[derive(Debug, Clone, PartialEq)]
pub struct LigneArret {
    /// Ligne de commande.
    pub ligne_id: Uuid,
    /// Libellé de l'article, figé à la création de la commande.
    pub libelle: String,
    /// Quantité commandée.
    pub quantite: i32,
    /// Prix unitaire VERROUILLÉ à la création (unités mineures).
    pub prix_unitaire_unites: i64,
    /// Ce que le client a choisi si l'article manque (FR-016).
    pub preference: PreferenceSubstitution,
    /// Présente, remplacée ou retirée.
    pub statut: StatutLigne,
}

impl LigneArret {
    /// Ce que cette ligne coûte au coursier à cet arrêt.
    ///
    /// Une ligne retirée ne coûte plus rien : c'est ce qui fait baisser le
    /// montant affiché dès qu'un article est déclaré indisponible (FR-013,
    /// SC-002). Une ligne remplacée garde son prix — le remplacement passe par
    /// le chemin de substitution, qui réécrit la ligne.
    pub fn montant_unites(&self) -> i64 {
        match self.statut {
            StatutLigne::Retiree => 0,
            StatutLigne::Presente | StatutLigne::Remplacee => {
                self.prix_unitaire_unites * i64::from(self.quantite)
            }
        }
    }
}

/// Un arrêt de collecte, complet : ce que le cycle 006 servait, plus ses lignes
/// et le contact du vendeur.
#[derive(Debug, Clone, PartialEq)]
pub struct ArretComplet {
    /// Arrêt de la course.
    pub arret_id: Uuid,
    /// Rang dans l'ordre optimisé (0 = premier).
    pub ordre: i16,
    /// Prestataire visé.
    pub prestataire_id: Uuid,
    /// Nom du prestataire (affiché sur la carte K3).
    pub nom: String,
    /// Position attendue du site.
    pub site_lat: f64,
    /// Position attendue du site.
    pub site_lon: f64,
    /// base16(sha256(jeton)) — match hors-ligne du QR scanné (cycle 006).
    pub empreinte_jeton: String,
    /// base16(sha256(prestataire_id ‖ code)) — confirmation dégradée hors-ligne.
    pub empreinte_code: String,
    /// Montant à avancer à CE vendeur (unités mineures), lignes retirées
    /// exclues et **retenue vendeur déduite** (VND-08, cycle PAY 011).
    pub montant_avance: i64,
    /// Articles bruts, AVANT retenue — ce que le vendeur facture.
    ///
    /// Égal à `montant_avance` quand aucune livraison n'est offerte. Sans lui,
    /// K3 afficherait un net inexpliqué et le coursier n'aurait aucun moyen de
    /// justifier l'écart au comptoir (FR-092).
    pub montant_articles_unites: i64,
    /// Part prise en charge par le vendeur (VND-08), `0` sinon.
    pub retenue_appliquee_unites: i64,
    /// Photo de récupération exigée (politique résolue du cycle 006).
    pub photo_exigee: bool,
    /// Rayon max de scan (m) — validation de proximité hors-ligne.
    pub distance_max_m: i64,
    /// Où en est cet arrêt.
    pub statut: StatutArret,
    /// Départ vers l'arrêt déclaré (horodatage serveur).
    pub en_route_le: Option<DateTime<Utc>>,
    /// Arrivée sur l'arrêt (base de la prime d'attente TRF-06).
    pub arrive_le: Option<DateTime<Utc>>,
    /// Collecte validée.
    pub collecte_le: Option<DateTime<Utc>>,
    /// Contact du vendeur — appel HORS LIGNE (R6). Jamais journalisé, jamais
    /// servi à une consultation non authentifiée (SC-013 du cycle 005).
    pub telephone_vendeur: Option<String>,
    /// Articles à acheter chez ce vendeur.
    pub lignes: Vec<LigneArret>,
}

impl ArretComplet {
    /// Montant réellement dû à ce vendeur, recalculé depuis les lignes.
    ///
    /// Les lignes font autorité, pas `montant_avance` : après un retrait, le
    /// second est périmé tant que le devis n'a pas été relu. C'est cette somme
    /// que K3 affiche (FR-013).
    pub fn montant_lignes_unites(&self) -> i64 {
        self.lignes.iter().map(LigneArret::montant_unites).sum()
    }
}

/// Le client, tel que le coursier en a besoin **hors ligne** (K3-1c, K4).
///
/// La seule donnée personnelle du pré-provisionnement, servie uniquement après
/// assignation (FR-104) et effacée du cache local à la clôture (R6).
#[derive(Debug, Clone, PartialEq)]
pub struct ClientCourse {
    /// Nom d'usage. `None` tant que le produit n'en porte aucun : le cycle CPT
    /// 003 a posé « identité Mefali = un numéro vérifié, rien d'autre ». K4-1a
    /// montre « Awa K. » ; l'app affiche le repère à la place plutôt qu'un nom
    /// fabriqué depuis le numéro (voir `commandes::ClientDeCourse`).
    pub nom_usage: Option<String>,
    /// Contact du client. Jamais journalisé.
    pub telephone: Option<String>,
    /// Repère écrit (« cour verte après la pharmacie »).
    pub repere_texte: Option<String>,
    /// URL **présignée** de la note vocale de repère, à télécharger tout de
    /// suite pour la jouer hors ligne (FR-024).
    pub repere_vocal_url: Option<String>,
    /// Durée de la note vocale, en secondes.
    pub repere_vocal_duree_s: Option<i32>,
    /// Point de livraison.
    pub lieu_lat: Option<f64>,
    /// Point de livraison.
    pub lieu_lon: Option<f64>,
    /// La voie « dépôt » est-elle ouverte sur CETTE commande (FR-039) ?
    pub depot_autorise: bool,
}

/// Les seuils de preuve d'échec de la zone, servis avec la course.
///
/// Ils voyagent dans le pré-provisionnement pour que l'écran des preuves sache
/// compter **hors ligne** — le serveur revérifie de toute façon (FR-060).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct SeuilsPreuves {
    /// Appels `client_absent` exigés.
    pub appels_min: i64,
    /// Espacement minimal entre deux appels retenus (secondes).
    pub espacement_s: i64,
    /// Présence continue exigée (secondes).
    pub presence_s: i64,
    /// Rayon dans lequel un relevé compte comme « sur place » (mètres).
    pub rayon_m: i64,
    /// Photos de preuve exigées.
    pub photos_min: i64,
}

/// Ce qu'il faut pour confirmer la remise, **sans réseau** (K4).
///
/// ⚠ Aucune de ces empreintes n'est un secret : ni le code à 4 chiffres, ni le
/// jeton ne sortent jamais du serveur (FR-037). Le risque résiduel du code court
/// est assumé et encadré — la validation locale n'engage rien, le serveur
/// revalide au rejeu (R7).
#[derive(Debug, Clone, PartialEq)]
pub struct RemisePreprovisionnee {
    /// Empreinte salée du code à 4 chiffres (cycle 008, migration 0009).
    pub empreinte_code: String,
    /// Empreinte du jeton de réception encodé dans le QR client.
    pub empreinte_jeton: String,
    /// Essais faux déjà comptés **côté serveur**.
    pub essais_consommes: i16,
    /// Seuil de zone `commande.essais_code_livraison` — celui du cycle 008,
    /// réutilisé tel quel (R5, FR-106).
    pub essais_max: i64,
    /// Saisie du code bloquée (K4-1d).
    pub code_bloque: bool,
    /// Total à encaisser chez le client (unités mineures).
    pub montant_a_encaisser_unites: i64,
    /// Cash ou prépayé — décide s'il y a quelque chose à encaisser.
    pub mode_paiement: ModePaiement,
    /// Seuils de preuve de la zone.
    pub seuils_preuves: SeuilsPreuves,
    /// Arrêt de REMISE — la cible de « je suis arrivé chez le client » (FR-053).
    ///
    /// Absent de la liste des arrêts, qui ne porte que les collectes : c'est ce
    /// qui permet à l'app de savoir que tout est collecté. Mais sans lui, le
    /// bouton de K3-1c n'aurait rien à transitionner.
    pub arret_remise_id: Option<Uuid>,
    /// Statut de l'arrêt de remise.
    pub arret_remise_statut: Option<String>,
    /// Instant SERVEUR d'arrivée chez le client — affiché sur K4-1a (FR-052).
    pub arrive_chez_client_le: Option<chrono::DateTime<chrono::Utc>>,
}

/// La course active, composée en une seule lecture (FR-011, FR-028).
#[derive(Debug, Clone, PartialEq)]
pub struct CourseComplete {
    /// Livraison active.
    pub livraison_id: Uuid,
    /// Commande portée.
    pub commande_id: Uuid,
    /// Où en est la livraison.
    pub etat: EtatLivraison,
    /// Devise ISO 4217 de la zone.
    pub devise: String,
    /// Arrêts de collecte, dans l'ordre optimisé.
    pub arrets: Vec<ArretComplet>,
    /// Le client et son repère.
    pub client: ClientCourse,
    /// De quoi confirmer la remise hors ligne.
    pub remise: RemisePreprovisionnee,
}

// ── Preuves d'échec ────────────────────────────────────────────────────────

/// Preuve « appels » (FR-056) — nombre ET espacement.
#[derive(Debug, Clone, PartialEq)]
pub struct PreuveAppels {
    /// Appels `client_absent` retenus (espacement respecté).
    pub faits: i64,
    /// Appels exigés.
    pub requis: i64,
    /// Espacement respecté entre les appels retenus.
    pub espacement_ok: bool,
    /// Horodatages **serveur** des appels retenus, pour l'affichage de K4-1e.
    pub horodatages: Vec<DateTime<Utc>>,
    /// Issues DÉCLARÉES par le coursier — affichées, jamais un critère (R19).
    pub issues: Vec<IssueAppel>,
    /// Preuve réunie.
    pub ok: bool,
    /// Pourquoi elle ne l'est pas — clé i18n, jamais du texte.
    pub motif_cle: Option<&'static str>,
}

/// Preuve « présence » (FR-056) — durée mesurée, trous exclus.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct PreuvePresence {
    /// Durée retenue, en secondes.
    pub secondes: i64,
    /// Durée exigée.
    pub requis: i64,
    /// Preuve réunie.
    pub ok: bool,
    /// Pourquoi elle ne l'est pas.
    pub motif_cle: Option<&'static str>,
}

/// Preuve « photo » (FR-056).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct PreuvePhotos {
    /// Photos déposées.
    pub faites: i64,
    /// Photos exigées.
    pub requis: i64,
    /// Preuve réunie.
    pub ok: bool,
}

/// L'état des trois preuves, et **ce qui manque** (contrat §1.4).
///
/// C'est la MÊME structure qui garde `POST /courses/{id}/echec` et qui alimente
/// l'écran : l'écran et le serveur ne peuvent pas diverger (FR-059, FR-060).
#[derive(Debug, Clone, PartialEq)]
pub struct EtatPreuves {
    /// Preuve « appels ».
    pub appels: PreuveAppels,
    /// Preuve « présence ».
    pub presence: PreuvePresence,
    /// Preuve « photo ».
    pub photos: PreuvePhotos,
    /// Les trois sont réunies.
    pub reunies: bool,
    /// Combien sur trois (compteur de K4-1e).
    pub reunies_sur: u8,
}

impl EtatPreuves {
    /// Nombre total de preuves — trois, et le compteur de l'écran le dit.
    pub const TOTAL: u8 = 3;
}

// ── Caisse ─────────────────────────────────────────────────────────────────

/// Nature d'une écriture au livre (énum Postgres `coursier.type_ecriture`).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TypeEcriture {
    /// Argent sorti de la poche du coursier à un arrêt.
    Avance,
    /// Encaissé chez le client — **cash uniquement** (R10).
    Remboursement,
    /// Indemnisation validée par l'exploitation.
    Indemnisation,
    /// Écriture INVERSE d'une écriture erronée — jamais un UPDATE (FR-073).
    Correction,
    // ── Cycle PAY 011 (migration 0020, research R13) ──────────────────────
    /// Frais de course **effectivement encaissés** chez le client, à la remise
    /// d'une commande cash. Vaut `total dû − Σ avances` : ce que Yao a en poche
    /// en plus, et **non** `devis_prix_client` — les deux diffèrent dès que la
    /// retenue de la livraison offerte joue (FR-056).
    FraisEncaisses,
    /// Versement effectué par Mefali pour solder une créance (FR-064).
    Reglement,
    /// Versement du coursier vers Mefali, pour ce qu'il détenait (FR-066).
    Reversement,
}

impl TypeEcriture {
    /// Représentation textuelle = valeur Postgres de l'énum.
    pub fn comme_str(self) -> &'static str {
        match self {
            TypeEcriture::Avance => "avance",
            TypeEcriture::Remboursement => "remboursement",
            TypeEcriture::Indemnisation => "indemnisation",
            TypeEcriture::Correction => "correction",
            TypeEcriture::FraisEncaisses => "frais_encaisses",
            TypeEcriture::Reglement => "reglement",
            TypeEcriture::Reversement => "reversement",
        }
    }
}

impl FromStr for TypeEcriture {
    type Err = ErreurCoursier;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "avance" => Ok(TypeEcriture::Avance),
            "remboursement" => Ok(TypeEcriture::Remboursement),
            "indemnisation" => Ok(TypeEcriture::Indemnisation),
            "correction" => Ok(TypeEcriture::Correction),
            "frais_encaisses" => Ok(TypeEcriture::FraisEncaisses),
            "reglement" => Ok(TypeEcriture::Reglement),
            "reversement" => Ok(TypeEcriture::Reversement),
            autre => Err(ErreurCoursier::ValeurInconnue(autre.to_owned())),
        }
    }
}

/// État d'une indemnisation (énum Postgres `coursier.etat_indemnisation`).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum EtatIndemnisation {
    /// Née de la consommation de `indemnisation.due` (cycle 008).
    Demandee,
    /// Validée — l'écriture de caisse suit dans la même transaction.
    Validee,
    /// Refusée — motif obligatoire, aucune écriture.
    Refusee,
}

impl EtatIndemnisation {
    /// Représentation textuelle = valeur Postgres de l'énum.
    pub fn comme_str(self) -> &'static str {
        match self {
            EtatIndemnisation::Demandee => "demandee",
            EtatIndemnisation::Validee => "validee",
            EtatIndemnisation::Refusee => "refusee",
        }
    }
}

impl FromStr for EtatIndemnisation {
    type Err = ErreurCoursier;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "demandee" => Ok(EtatIndemnisation::Demandee),
            "validee" => Ok(EtatIndemnisation::Validee),
            "refusee" => Ok(EtatIndemnisation::Refusee),
            autre => Err(ErreurCoursier::ValeurInconnue(autre.to_owned())),
        }
    }
}

/// Une ligne de l'historique du jour (K5-1a — trois chiffres par course).
#[derive(Debug, Clone, PartialEq)]
pub struct LigneHistorique {
    /// Commande concernée.
    pub commande_id: Uuid,
    /// Livraison concernée.
    pub livraison_id: Option<Uuid>,
    /// Référence lisible affichée (`#418`).
    pub reference: String,
    /// Ce que le coursier a avancé (unités mineures, positif).
    pub avance_unites: i64,
    /// Ce qu'il a récupéré (unités mineures, positif).
    pub rembourse_unites: i64,
    /// Sa part sur cette course (devis figé du cycle 007).
    pub gain_unites: i64,
    /// La course est-elle terminée ?
    pub terminee: bool,
    /// Avance NON SOLDÉE parce que la commande était prépayée (R10, FR-117).
    pub en_attente_reglement: bool,
    /// Heure de la première écriture (horodatage serveur).
    pub heure: DateTime<Utc>,
}

/// Un **mouvement du livre**, tel que l'écran de caisse le liste (K5).
///
/// Cycle PAY 011 : l'historique agrégé par course (trois chiffres) ne suffit
/// plus. Trois natures d'écriture s'ajoutent — `frais_encaisses`, `reglement`,
/// `reversement` —, et deux d'entre elles ne sont **rattachées à aucune
/// course** : un règlement d'agence solde des créances, un reversement rend à
/// Mefali ce qui lui revient. Les agréger par commande les aurait fait
/// disparaître de l'écran.
#[derive(Debug, Clone, PartialEq)]
pub struct MouvementCaisse {
    /// Écriture.
    pub id: Uuid,
    /// Nature du mouvement — les six valeurs de `coursier.type_ecriture`.
    pub type_ecriture: TypeEcriture,
    /// Montant **signé** : négatif quand l'argent sort de la poche du coursier.
    ///
    /// Le signe porte tout le sens, et l'app en dérive « entrée » ou
    /// « sortie » plutôt que de le recopier depuis une table de types — une
    /// table qui divergerait le jour où une nature changerait de sens.
    pub montant_unites: i64,
    /// Commande concernée — `None` pour un règlement ou un reversement, qui
    /// portent sur un solde et non sur une course.
    pub commande_id: Option<Uuid>,
    /// Référence lisible de la commande, quand il y en a une.
    pub reference: Option<String>,
    /// Horodatage **serveur** de l'écriture.
    pub heure: DateTime<Utc>,
}

impl MouvementCaisse {
    /// Vrai si l'argent ENTRE dans la poche du coursier.
    pub fn est_entree(&self) -> bool {
        self.montant_unites > 0
    }
}

/// Une indemnisation, telle que la caisse l'affiche.
#[derive(Debug, Clone, PartialEq)]
pub struct IndemnisationVue {
    /// Indemnisation.
    pub id: Uuid,
    /// Commande d'origine.
    pub commande_id: Uuid,
    /// Référence lisible de la commande.
    pub commande_reference: String,
    /// Montant (unités mineures, toujours positif).
    pub montant_unites: i64,
    /// Devise ISO 4217.
    pub devise: String,
    /// Demandée, validée ou refusée.
    pub etat: EtatIndemnisation,
    /// Litige rattaché — `None` tant qu'AVI-04 n'existe pas (R16).
    pub litige_id: Option<Uuid>,
    /// Clé i18n du motif.
    pub motif_cle: String,
    /// Clé i18n du motif de décision (refus surtout).
    pub decision_motif_cle: Option<String>,
    /// Quand la décision a été prise.
    pub decide_le: Option<DateTime<Utc>>,
    /// Naissance de la demande.
    pub cree_le: DateTime<Utc>,
}

/// Un litige en cours vu par le coursier — port `LitigesOuverts` (AVI-04).
#[derive(Debug, Clone, PartialEq)]
pub struct LitigeVu {
    /// Litige.
    pub id: Uuid,
    /// Commande concernée.
    pub commande_id: Uuid,
    /// Référence lisible.
    pub reference: String,
    /// Clé i18n de l'état affiché.
    pub etat_cle: String,
    /// Montant en jeu (unités mineures).
    pub montant_unites: i64,
    /// Ouverture.
    pub ouvert_le: DateTime<Utc>,
}

/// Tout l'écran caisse (K5-1a), en une lecture.
#[derive(Debug, Clone, PartialEq)]
pub struct VueCaisse {
    /// Argent avancé et non encore récupéré (FR-067) — toujours positif.
    pub avance_en_cours_unites: i64,
    /// Combien de courses portent cette avance.
    pub courses_concernees: i64,
    /// Part de l'avance qui ne sera PAS remboursée en espèces (R10, FR-117).
    pub avances_en_attente_reglement_unites: i64,
    /// Historique du jour civil de la zone.
    pub historique: Vec<LigneHistorique>,
    /// **Mouvements du livre**, du plus récent au plus ancien (cycle PAY 011).
    ///
    /// Additif : l'historique agrégé reste servi tel quel, l'app livrée
    /// continue de fonctionner pendant la transition.
    pub mouvements: Vec<MouvementCaisse>,
    /// Indemnisations rattachées.
    pub indemnisations: Vec<IndemnisationVue>,
    /// Litiges en cours — vide tant qu'AVI-04 n'existe pas.
    pub litiges: Vec<LitigeVu>,
    /// **Les trois positions** (cycle PAY 011, FR-060/FR-061, research R13).
    ///
    /// Toutes CALCULÉES, aucune stockée : une table de soldes serait une
    /// seconde vérité à réconcilier, et le cycle 010 l'a déjà refusée.
    pub positions: PositionsCaisse,
    /// Créances du coursier, les plus récentes d'abord (FR-094).
    pub creances: Vec<Creance>,
    /// Devise ISO 4217 de la zone.
    pub devise: String,
    /// Vrai si les avances en cours dépassent le plafond du jour (FR-078).
    pub ecart_plafond: bool,
}

/// Les trois positions de la caisse — « où est cet argent ? », en trois
/// chiffres (FR-060, FR-094).
///
/// Elles ne se recouvrent pas, et c'est ce qui les rend lisibles :
///
/// | Position | Ce que ça veut dire |
/// |---|---|
/// | avancé non récupéré | Yao a sorti l'argent, personne ne le lui a rendu |
/// | dû par Mefali | Mefali le lui doit, formellement, et ça se règle |
/// | détenu pour Mefali | il a de l'argent qui n'est PAS à lui |
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub struct PositionsCaisse {
    /// Σ avances non compensées par un remboursement (position existante).
    pub avance_non_recuperee_unites: i64,
    /// Σ créances à l'état `due`.
    pub du_par_mefali_unites: i64,
    /// `Σ min(frais_encaisses, devis_marge) − Σ reversements`.
    ///
    /// **Vaut 0 au MVP** : la marge est nulle jusqu'à M4, donc le minimum vaut
    /// toujours zéro. La position s'affiche quand même — une position absente
    /// se lirait comme une position oubliée, et le jour où la marge devient
    /// non nulle il ne faudra rien ajouter à l'écran.
    pub detenu_pour_mefali_unites: i64,
}

/// Le bandeau de gains de K1 (FR-091 → FR-095).
///
/// **Composé dans le handler** à partir de deux dépôts : `coursier` fournit les
/// courses livrées, les gains et les avances ; `dispatch` fournit le plafond
/// retenu et le taux d'acceptation. Aucun des deux crates n'apprend l'existence
/// de l'autre (contracts §2).
#[derive(Debug, Clone, PartialEq)]
pub struct VueJournee {
    /// Courses livrées sur le jour civil de la zone.
    pub courses_livrees: i64,
    /// Somme des parts coursier (devis figés).
    pub gains_unites: i64,
    /// Plafond d'avance retenu (vient de `dispatch`).
    pub plafond_retenu_unites: i64,
    /// Ce qui reste engageable = plafond − avances en cours.
    pub reste_disponible_unites: i64,
    /// Taux d'acceptation sur la fenêtre (vient de `dispatch`).
    pub taux_acceptation_pourcent: i32,
    /// Note du coursier — `None` tant qu'AVI n'existe pas.
    pub note: Option<u16>,
    /// Devise ISO 4217.
    pub devise: String,
}

/// Exposition cash d'un coursier (FR-075).
#[derive(Debug, Clone, PartialEq)]
pub struct LigneExposition {
    /// Coursier.
    pub coursier_id: Uuid,
    /// Nom d'usage.
    pub nom: String,
    /// Avance en cours (unités mineures, positif).
    pub avance_unites: i64,
    /// Courses concernées.
    pub courses: i64,
}

/// Ce que l'exploitation voit du cash en circulation (FR-075).
#[derive(Debug, Clone, PartialEq)]
pub struct ExpositionCash {
    /// Total en circulation.
    pub total_unites: i64,
    /// Devise ISO 4217.
    pub devise: String,
    /// Détail par coursier, du plus exposé au moins exposé.
    pub par_coursier: Vec<LigneExposition>,
}

// ── Appels ─────────────────────────────────────────────────────────────────

/// Motif d'un appel passé via l'app (énum Postgres `coursier.motif_appel`).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MotifAppel {
    /// Appel ordinaire pendant la course.
    Suivi,
    /// Article indisponible, préférence « m'appeler ».
    Substitution,
    /// **Seul** motif compté par la preuve d'échec (FR-035).
    ClientAbsent,
}

impl MotifAppel {
    /// Représentation textuelle = valeur Postgres de l'énum.
    pub fn comme_str(self) -> &'static str {
        match self {
            MotifAppel::Suivi => "suivi",
            MotifAppel::Substitution => "substitution",
            MotifAppel::ClientAbsent => "client_absent",
        }
    }

    /// Cet appel compte-t-il pour la preuve d'échec ?
    pub fn compte_pour_preuve(self) -> bool {
        matches!(self, MotifAppel::ClientAbsent)
    }
}

impl FromStr for MotifAppel {
    type Err = ErreurCoursier;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "suivi" => Ok(MotifAppel::Suivi),
            "substitution" => Ok(MotifAppel::Substitution),
            "client_absent" => Ok(MotifAppel::ClientAbsent),
            autre => Err(ErreurCoursier::ValeurInconnue(autre.to_owned())),
        }
    }
}

/// Issue DÉCLARÉE d'un appel (énum Postgres `coursier.issue_appel`).
///
/// Le serveur ne peut pas l'observer : l'appel part du téléphone. Elle sert
/// l'affichage de K4-1e (FR-036) et n'est **jamais** un critère de preuve (R19).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum IssueAppel {
    /// Non déclarée.
    #[default]
    Inconnue,
    /// Le client n'a pas décroché.
    SansReponse,
    /// Le client a décroché.
    Repondu,
}

impl IssueAppel {
    /// Représentation textuelle = valeur Postgres de l'énum.
    pub fn comme_str(self) -> &'static str {
        match self {
            IssueAppel::Inconnue => "inconnue",
            IssueAppel::SansReponse => "sans_reponse",
            IssueAppel::Repondu => "repondu",
        }
    }
}

impl FromStr for IssueAppel {
    type Err = ErreurCoursier;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "inconnue" => Ok(IssueAppel::Inconnue),
            "sans_reponse" => Ok(IssueAppel::SansReponse),
            "repondu" => Ok(IssueAppel::Repondu),
            autre => Err(ErreurCoursier::ValeurInconnue(autre.to_owned())),
        }
    }
}

/// Vers qui part un appel.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum CibleAppel {
    /// Le client de la commande.
    Client,
    /// Le vendeur d'un arrêt.
    Vendeur,
}

impl CibleAppel {
    /// Représentation textuelle = valeur stockée.
    pub fn comme_str(self) -> &'static str {
        match self {
            CibleAppel::Client => "client",
            CibleAppel::Vendeur => "vendeur",
        }
    }
}

impl FromStr for CibleAppel {
    type Err = ErreurCoursier;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "client" => Ok(CibleAppel::Client),
            "vendeur" => Ok(CibleAppel::Vendeur),
            autre => Err(ErreurCoursier::ValeurInconnue(autre.to_owned())),
        }
    }
}

/// Un appel journalisé, tel que l'exploitation le lit (FR-063).
///
/// **Aucun numéro** : le serveur n'en a jamais vu.
#[derive(Debug, Clone, PartialEq)]
pub struct AppelJournalise {
    /// Appel.
    pub id: Uuid,
    /// Vers le client ou le vendeur.
    pub vers: CibleAppel,
    /// Prestataire appelé (si `vers = vendeur`).
    pub prestataire_id: Option<Uuid>,
    /// Motif.
    pub motif: MotifAppel,
    /// Issue déclarée par le coursier.
    pub issue: IssueAppel,
    /// Horodatage **serveur** — celui qui fait foi.
    pub passe_le: DateTime<Utc>,
    /// Horodatage de l'appareil — observation seulement.
    pub passe_le_local: DateTime<Utc>,
}

// ── Réconciliation de la file hors-ligne ───────────────────────────────────

/// Nature de l'action rejouée depuis la file (payload de
/// `coursier.action_reconciliee`).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ActionRejouee {
    /// Collecte d'un arrêt.
    Collecte,
    /// Transition d'arrêt (« je pars », « je suis arrivé »).
    Transition,
    /// Confirmation de remise.
    Remise,
    /// Déclaration d'échec.
    Echec,
}

impl ActionRejouee {
    /// Représentation textuelle (payload d'événement).
    pub fn comme_str(self) -> &'static str {
        match self {
            ActionRejouee::Collecte => "collecte",
            ActionRejouee::Transition => "transition",
            ActionRejouee::Remise => "remise",
            ActionRejouee::Echec => "echec",
        }
    }
}

/// Comment un rejeu s'est terminé.
///
/// La distinction est celle que l'app doit rendre visible (FR-085) : un refus
/// **réessayable** (réseau) reste dans la file ; un refus **définitif** (métier)
/// en sort après réconciliation affichée.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum IssueRejeu {
    /// L'action a été rejouée avec succès (ou était déjà appliquée).
    Rejouee,
    /// Le serveur refuse définitivement — la file doit l'abandonner.
    RefuseeDefinitivement,
}

impl IssueRejeu {
    /// Représentation textuelle (payload d'événement).
    pub fn comme_str(self) -> &'static str {
        match self {
            IssueRejeu::Rejouee => "rejouee",
            IssueRejeu::RefuseeDefinitivement => "refusee_definitivement",
        }
    }
}

// ── Erreurs ────────────────────────────────────────────────────────────────

/// Erreurs du domaine coursier. Chaque variante métier porte une clé i18n fr
/// (`message_cle`) et un statut HTTP (mappé dans `coursier_http`).
#[derive(Debug, thiserror::Error)]
pub enum ErreurCoursier {
    /// Créance inconnue (404 — file d'exploitation).
    #[error("créance inconnue : {0}")]
    CreanceInconnue(Uuid),
    /// Créance déjà réglée (409 — FR-064). Le marquage n'est PAS une bascule :
    /// une erreur se corrige par une écriture inverse au livre.
    #[error("créance déjà réglée")]
    CreanceDejaReglee,
    /// Aucune course active pour ce coursier.
    #[error("aucune course active")]
    AucuneCourseActive,
    /// La course existe mais appartient à un autre coursier (FR-006). C'est
    /// **la** garde du rejeu : une action d'un coursier désassigné est refusée
    /// et tracée, jamais appliquée en silence.
    #[error("course d'un autre coursier")]
    CourseNonProprietaire,
    /// Les trois preuves ne sont pas réunies (FR-056).
    #[error("preuves d'échec incomplètes")]
    PreuvesIncompletes,
    /// Remise en mode `depot` sur une commande où il n'est pas ouvert (FR-048).
    #[error("dépôt non autorisé sur cette commande")]
    DepotNonAutorise,
    /// L'indemnisation a déjà été validée ou refusée.
    #[error("indemnisation déjà décidée")]
    IndemnisationDejaDecidee,
    /// Indemnisation inconnue.
    #[error("indemnisation inconnue : {0}")]
    IndemnisationInconnue(Uuid),
    /// Motif obligatoire absent (refus, levée de blocage, ouverture de dépôt).
    #[error("motif obligatoire")]
    MotifRequis,
    /// Tentative de mutation d'une écriture de caisse (FR-073) — le trigger de
    /// la migration 0015 la refuse ; cette variante la traduit.
    #[error("écriture de caisse immuable")]
    EcritureImmuable,
    /// Le code de remise n'est pas bloqué : il n'y a rien à lever.
    #[error("code de remise non bloqué")]
    CodeNonBloque,
    /// Paramètre de zone absent — jamais un défaut silencieux (constitution I).
    #[error("paramètre de zone absent : {0}")]
    ParametreAbsent(String),
    /// Configuration de zone refusée au chargement.
    #[error("configuration coursier invalide : {0}")]
    ConfigurationInvalide(String),
    /// Valeur d'énum inconnue lue en base.
    #[error("valeur inconnue : {0}")]
    ValeurInconnue(String),
    /// Requête mal formée.
    #[error("demande invalide : {0}")]
    DemandeInvalide(&'static str),
    /// Domaine commandes.
    #[error("socle logistique : {0}")]
    Commandes(#[from] commandes::ErreurCommandes),
    /// Domaine QR (empreintes de plaque, politique photo).
    #[error("domaine qr : {0}")]
    Qr(#[from] qr::ErreurQr),
    /// Domaine prestataires.
    #[error("domaine prestataires : {0}")]
    Prestataires(#[from] prestataires::ErreurPrestataires),
    /// Configuration de zone.
    #[error("configuration de zone : {0}")]
    Zones(#[from] zones::ErreurZones),
    /// Stockage objet (photos de preuve).
    #[error("stockage objet : {0}")]
    Objets(#[from] socle::ErreurObjets),
    /// Erreur de la base de données.
    #[error("erreur base de données coursier : {0}")]
    Sql(#[from] sqlx::Error),
}

impl ErreurCoursier {
    /// Clé i18n **courte** du refus, ou `None` si l'erreur est technique.
    ///
    /// La couche HTTP la préfixe de son espace de noms (`coursier.erreur.…`) —
    /// patron `erreurs_commandes.rs` / `ErreurDispatch`. Une erreur sans clé
    /// n'expose rien : son détail vit dans les journaux.
    pub fn message_cle(&self) -> Option<&'static str> {
        Some(match self {
            ErreurCoursier::AucuneCourseActive => "aucune_course_active",
            ErreurCoursier::CourseNonProprietaire => "course_non_proprietaire",
            ErreurCoursier::PreuvesIncompletes => "preuves_incompletes",
            ErreurCoursier::DepotNonAutorise => "depot_non_autorise",
            ErreurCoursier::IndemnisationDejaDecidee => "indemnisation_deja_decidee",
            ErreurCoursier::IndemnisationInconnue(_) => "indemnisation_inconnue",
            ErreurCoursier::MotifRequis => "motif_requis",
            ErreurCoursier::EcritureImmuable => "caisse_ecriture_immuable",
            ErreurCoursier::CodeNonBloque => "code_non_bloque",
            ErreurCoursier::CreanceInconnue(_) => "creance_inconnue",
            ErreurCoursier::CreanceDejaReglee => "creance_deja_reglee",
            ErreurCoursier::DemandeInvalide(_) => "demande_invalide",
            // Une valeur d'entrée hors énumération est un refus de DEMANDE, pas
            // une panne : `?etat=peut-etre` rendait `500`, et l'appelant lisait
            // « le serveur est cassé » là où il avait simplement mal écrit
            // (défaut trouvé par `admin_coursier::la_file_…_se_filtre_par_etat`).
            ErreurCoursier::ValeurInconnue(_) => "valeur_inconnue",
            // Techniques : rien à exposer.
            ErreurCoursier::ParametreAbsent(_)
            | ErreurCoursier::ConfigurationInvalide(_)
            | ErreurCoursier::Commandes(_)
            | ErreurCoursier::Qr(_)
            | ErreurCoursier::Prestataires(_)
            | ErreurCoursier::Zones(_)
            | ErreurCoursier::Objets(_)
            | ErreurCoursier::Sql(_) => return None,
        })
    }
}

/// Une écriture d'outbox qui échoue est une erreur de BASE, pas un refus
/// métier : la traduire en `Sql` garde le statut HTTP juste (500, pas 422) et
/// évite d'exposer une clé i18n pour une panne (patron `ErreurCommandes`).
impl From<socle::OutboxError> for ErreurCoursier {
    fn from(erreur: socle::OutboxError) -> Self {
        // `OutboxError` n'a qu'une variante : la déstructurer plutôt que de la
        // filtrer garantit qu'une variante AJOUTÉE plus tard cassera la
        // compilation ici, au lieu de tomber en silence dans un bras fourre-tout
        // qui la maquillerait en erreur de configuration.
        let socle::OutboxError::Db(e) = erreur;
        ErreurCoursier::Sql(e)
    }
}

/// Les refus du domaine coursier remontent tels quels dans `commandes` quand
/// c'est ce crate qui les demande — c'est le cas du port `PreuvesEchec`, dont
/// l'implémentation vit ici (contracts §1).
impl From<ErreurCoursier> for commandes::ErreurCommandes {
    fn from(e: ErreurCoursier) -> Self {
        match e {
            ErreurCoursier::Commandes(inner) => inner,
            ErreurCoursier::Sql(inner) => commandes::ErreurCommandes::Sql(inner),
            autre => commandes::ErreurCommandes::Dependance(autre.to_string()),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn ligne(statut: StatutLigne, prix: i64, quantite: i32) -> LigneArret {
        LigneArret {
            ligne_id: Uuid::now_v7(),
            libelle: "Tomates".to_owned(),
            quantite,
            prix_unitaire_unites: prix,
            preference: PreferenceSubstitution::Appeler,
            statut,
        }
    }

    /// FR-013 / SC-002 — une ligne retirée ne coûte plus rien, et c'est ce qui
    /// fait baisser le montant affiché à l'arrêt dès qu'un article manque.
    #[test]
    fn une_ligne_retiree_ne_coute_plus_rien() {
        assert_eq!(ligne(StatutLigne::Presente, 400, 2).montant_unites(), 800);
        assert_eq!(ligne(StatutLigne::Retiree, 400, 2).montant_unites(), 0);
        // Une ligne REMPLACÉE garde son prix : le remplacement réécrit la ligne
        // par le chemin de substitution, il ne l'annule pas.
        assert_eq!(ligne(StatutLigne::Remplacee, 400, 2).montant_unites(), 800);
    }

    /// Le montant d'un arrêt est la SOMME de ses lignes — pas `montant_avance`,
    /// qui est périmé dès qu'une ligne est retirée.
    #[test]
    fn le_montant_d_un_arret_suit_ses_lignes() {
        let arret = ArretComplet {
            arret_id: Uuid::now_v7(),
            ordre: 0,
            prestataire_id: Uuid::now_v7(),
            nom: "Étal Adjoua".to_owned(),
            site_lat: 5.898,
            site_lon: -4.823,
            empreinte_jeton: "a1b2".to_owned(),
            empreinte_code: "c3d4".to_owned(),
            montant_avance: 2_000,
            montant_articles_unites: 2_000,
            retenue_appliquee_unites: 0,
            photo_exigee: false,
            distance_max_m: 100,
            statut: StatutArret::ACollecter,
            en_route_le: None,
            arrive_le: None,
            collecte_le: None,
            telephone_vendeur: None,
            lignes: vec![
                ligne(StatutLigne::Presente, 400, 2),
                ligne(StatutLigne::Retiree, 1_200, 1),
            ],
        };
        assert_eq!(
            arret.montant_lignes_unites(),
            800,
            "les lignes font autorité : 2 000 était le montant AVANT le retrait",
        );
    }

    /// FR-035 — seul `client_absent` compte pour la preuve. Un appel de suivi
    /// ne prouve pas une absence, et c'est le cœur de la garde.
    #[test]
    fn seul_client_absent_compte_pour_la_preuve() {
        assert!(MotifAppel::ClientAbsent.compte_pour_preuve());
        assert!(!MotifAppel::Suivi.compte_pour_preuve());
        assert!(!MotifAppel::Substitution.compte_pour_preuve());
    }

    /// Les énums font l'aller-retour avec leur valeur Postgres : une valeur
    /// inconnue est une ERREUR, jamais un défaut silencieux.
    #[test]
    fn les_enums_font_l_aller_retour_avec_postgres() {
        for t in [
            TypeEcriture::Avance,
            TypeEcriture::Remboursement,
            TypeEcriture::Indemnisation,
            TypeEcriture::Correction,
        ] {
            assert_eq!(TypeEcriture::from_str(t.comme_str()).unwrap(), t);
        }
        for e in [
            EtatIndemnisation::Demandee,
            EtatIndemnisation::Validee,
            EtatIndemnisation::Refusee,
        ] {
            assert_eq!(EtatIndemnisation::from_str(e.comme_str()).unwrap(), e);
        }
        for i in [
            IssueAppel::Inconnue,
            IssueAppel::SansReponse,
            IssueAppel::Repondu,
        ] {
            assert_eq!(IssueAppel::from_str(i.comme_str()).unwrap(), i);
        }
        assert!(matches!(
            TypeEcriture::from_str("virement"),
            Err(ErreurCoursier::ValeurInconnue(_))
        ));
    }

    /// Une erreur technique n'expose AUCUNE clé : son détail reste au journal.
    #[test]
    fn les_erreurs_techniques_n_exposent_aucune_cle() {
        assert_eq!(
            ErreurCoursier::PreuvesIncompletes.message_cle(),
            Some("preuves_incompletes")
        );
        assert_eq!(
            ErreurCoursier::ParametreAbsent("coursier.preuve_presence_s".to_owned()).message_cle(),
            None,
        );
    }
}
