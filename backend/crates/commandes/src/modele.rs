//! Types publics du socle logistique (cycle QRC 006, data-model §1/§4.1).
//!
//! Énums miroir des types Postgres (`commandes.statut_arret`, `.mode_collecte`,
//! `.etat_livraison`) avec `comme_str()`/`FromStr` — patron du cycle 005 (cast
//! SQL `col::text AS "col!"`, jamais l'énum brut). L'énum fige le vocabulaire ;
//! toute transition est GARDÉE dans le crate (jamais par le type seul).

use std::str::FromStr;

use uuid::Uuid;

/// Machine à états de l'arrêt (cadrage §7.2). Le cycle QRC 006 ne posait que
/// `ACollecter` → `Collecte` ; CMD 008 intercale la boucle du coursier
/// (`EnRoute`, `Arrive`) sans jamais retirer le chemin direct
/// `a_collecter → collecte` — un coursier peut scanner sans avoir déclaré son
/// trajet, et cette non-régression est testée.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum StatutArret {
    /// En attente de collecte par le coursier.
    ACollecter,
    /// Le coursier a déclaré partir vers cet arrêt (CMD-04).
    EnRoute,
    /// Le coursier est arrivé — `arrive_le` fonde la prime d'attente (TRF-06).
    Arrive,
    /// Collecté (scan ou code de secours), horodatage serveur posé.
    Collecte,
    /// Indisponible (substitution CMD-06) — compté comme résolu au gating.
    Indisponible,
}

impl StatutArret {
    /// Représentation textuelle = valeur Postgres de l'énum.
    pub fn comme_str(self) -> &'static str {
        match self {
            StatutArret::ACollecter => "a_collecter",
            StatutArret::EnRoute => "en_route",
            StatutArret::Arrive => "arrive",
            StatutArret::Collecte => "collecte",
            StatutArret::Indisponible => "indisponible",
        }
    }

    /// Vrai si l'arrêt est RÉSOLU pour le gating EN_LIVRAISON (spec FR-018).
    pub fn est_resolu(self) -> bool {
        matches!(self, StatutArret::Collecte | StatutArret::Indisponible)
    }
}

impl FromStr for StatutArret {
    type Err = ErreurCommandes;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "a_collecter" => Ok(StatutArret::ACollecter),
            "en_route" => Ok(StatutArret::EnRoute),
            "arrive" => Ok(StatutArret::Arrive),
            "collecte" => Ok(StatutArret::Collecte),
            "indisponible" => Ok(StatutArret::Indisponible),
            autre => Err(ErreurCommandes::StatutInconnu(autre.to_owned())),
        }
    }
}

/// Nature de l'arrêt (cadrage §7.2 : 1..n collectes + 1 remise).
///
/// ⚠ Seules les COLLECTES comptent au gating EN_LIVRAISON et à la progression
/// (P1, research R4).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TypeArret {
    /// Retrait chez un vendeur — porte un prestataire et un montant avancé.
    Collecte,
    /// Remise au client — ni prestataire, ni montant avancé.
    Remise,
}

impl TypeArret {
    /// Représentation textuelle = valeur Postgres de l'énum.
    pub fn comme_str(self) -> &'static str {
        match self {
            TypeArret::Collecte => "collecte",
            TypeArret::Remise => "remise",
        }
    }
}

impl FromStr for TypeArret {
    type Err = ErreurCommandes;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "collecte" => Ok(TypeArret::Collecte),
            "remise" => Ok(TypeArret::Remise),
            autre => Err(ErreurCommandes::StatutInconnu(autre.to_owned())),
        }
    }
}

/// États de TRÈS HAUT NIVEAU du tronc commande (constitution II — aucun état
/// logistique : la collecte et la remise vivent sur la livraison et ses arrêts).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum EtatCommande {
    /// Créée, prête à être dispatchée (paiement cash autorisé).
    Nouvelle,
    /// Prépaiement requis — rien ne part avant le règlement.
    EnAttentePaiement,
    /// Aucun coursier éligible : file FIFO par âge (CMD-10).
    EnAttenteCoursier,
    /// Prise en charge par un coursier.
    EnCours,
    /// Terminée avec succès (remise validée).
    Terminee,
    /// Annulée avant terme (client, admin ou système).
    Annulee,
    /// Échec déclaré avec preuves — l'arbre §7.5 a tranché.
    Echouee,
}

impl EtatCommande {
    /// Représentation textuelle = valeur Postgres de l'énum.
    pub fn comme_str(self) -> &'static str {
        match self {
            EtatCommande::Nouvelle => "nouvelle",
            EtatCommande::EnAttentePaiement => "en_attente_paiement",
            EtatCommande::EnAttenteCoursier => "en_attente_coursier",
            EtatCommande::EnCours => "en_cours",
            EtatCommande::Terminee => "terminee",
            EtatCommande::Annulee => "annulee",
            EtatCommande::Echouee => "echouee",
        }
    }

    /// Vrai si l'état est TERMINAL : plus aucune transition n'en part.
    pub fn est_terminal(self) -> bool {
        matches!(
            self,
            EtatCommande::Terminee | EtatCommande::Annulee | EtatCommande::Echouee
        )
    }
}

impl FromStr for EtatCommande {
    type Err = ErreurCommandes;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "nouvelle" => Ok(EtatCommande::Nouvelle),
            "en_attente_paiement" => Ok(EtatCommande::EnAttentePaiement),
            "en_attente_coursier" => Ok(EtatCommande::EnAttenteCoursier),
            "en_cours" => Ok(EtatCommande::EnCours),
            "terminee" => Ok(EtatCommande::Terminee),
            "annulee" => Ok(EtatCommande::Annulee),
            "echouee" => Ok(EtatCommande::Echouee),
            autre => Err(ErreurCommandes::StatutInconnu(autre.to_owned())),
        }
    }
}

/// Préférence de substitution PAR ARTICLE (CMD-01). Défaut produit :
/// « m'appeler » — c'est le seul choix qui ne décide rien à la place du client.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PreferenceSubstitution {
    /// Le coursier propose un remplacement, le client tranche dans la fenêtre.
    Remplacer,
    /// Le coursier appelle ; sans réponse, l'article est retiré.
    Appeler,
    /// Retrait immédiat, sans appel ni proposition.
    Retirer,
}

impl PreferenceSubstitution {
    /// Représentation textuelle = valeur Postgres de l'énum.
    pub fn comme_str(self) -> &'static str {
        match self {
            PreferenceSubstitution::Remplacer => "remplacer",
            PreferenceSubstitution::Appeler => "appeler",
            PreferenceSubstitution::Retirer => "retirer",
        }
    }
}

impl Default for PreferenceSubstitution {
    /// « M'appeler » — défaut produit (CMD-01, maquette C3-3a).
    fn default() -> Self {
        PreferenceSubstitution::Appeler
    }
}

impl FromStr for PreferenceSubstitution {
    type Err = ErreurCommandes;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "remplacer" => Ok(PreferenceSubstitution::Remplacer),
            "appeler" => Ok(PreferenceSubstitution::Appeler),
            "retirer" => Ok(PreferenceSubstitution::Retirer),
            autre => Err(ErreurCommandes::StatutInconnu(autre.to_owned())),
        }
    }
}

/// Cycle de vie d'une ligne de commande.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum StatutLigne {
    /// Présente — comptée dans le montant des articles.
    Presente,
    /// Remplacée par un autre article du MÊME vendeur (FR-048).
    Remplacee,
    /// Retirée — plus rien à payer pour elle.
    Retiree,
}

impl StatutLigne {
    /// Représentation textuelle = valeur Postgres de l'énum.
    pub fn comme_str(self) -> &'static str {
        match self {
            StatutLigne::Presente => "presente",
            StatutLigne::Remplacee => "remplacee",
            StatutLigne::Retiree => "retiree",
        }
    }
}

impl FromStr for StatutLigne {
    type Err = ErreurCommandes;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "presente" => Ok(StatutLigne::Presente),
            "remplacee" => Ok(StatutLigne::Remplacee),
            "retiree" => Ok(StatutLigne::Retiree),
            autre => Err(ErreurCommandes::StatutInconnu(autre.to_owned())),
        }
    }
}

/// Issue d'une proposition de remplacement (CMD-06, maquette C4-4c).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum IssueSubstitution {
    /// Dans la fenêtre de décision.
    EnAttente,
    /// Acceptée par le client — la ligne devient `remplacee`.
    Acceptee,
    /// Refusée par le client — la ligne est retirée.
    Refusee,
    /// Échéance dépassée : appel puis retrait si le client reste injoignable.
    ExpireeAppel,
    /// Retirée par le coursier avant décision.
    Retiree,
}

impl IssueSubstitution {
    /// Représentation textuelle = valeur Postgres de l'énum.
    pub fn comme_str(self) -> &'static str {
        match self {
            IssueSubstitution::EnAttente => "en_attente",
            IssueSubstitution::Acceptee => "acceptee",
            IssueSubstitution::Refusee => "refusee",
            IssueSubstitution::ExpireeAppel => "expiree_appel",
            IssueSubstitution::Retiree => "retiree",
        }
    }
}

impl FromStr for IssueSubstitution {
    type Err = ErreurCommandes;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "en_attente" => Ok(IssueSubstitution::EnAttente),
            "acceptee" => Ok(IssueSubstitution::Acceptee),
            "refusee" => Ok(IssueSubstitution::Refusee),
            "expiree_appel" => Ok(IssueSubstitution::ExpireeAppel),
            "retiree" => Ok(IssueSubstitution::Retiree),
            autre => Err(ErreurCommandes::StatutInconnu(autre.to_owned())),
        }
    }
}

/// Mode de paiement (constitution III — jamais de chemin partiel : un seul
/// montant, encaissé en une fois).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ModePaiement {
    /// Espèces à la remise, sous plafond de zone.
    Cash,
    /// Mobile money — prépaiement.
    MobileMoney,
}

impl ModePaiement {
    /// Représentation textuelle = valeur Postgres de l'énum.
    pub fn comme_str(self) -> &'static str {
        match self {
            ModePaiement::Cash => "cash",
            ModePaiement::MobileMoney => "mobile_money",
        }
    }
}

impl FromStr for ModePaiement {
    type Err = ErreurCommandes;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "cash" => Ok(ModePaiement::Cash),
            "mobile_money" => Ok(ModePaiement::MobileMoney),
            autre => Err(ErreurCommandes::StatutInconnu(autre.to_owned())),
        }
    }
}

/// État du paiement d'une commande.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum EtatPaiement {
    /// Dû — encaissement à la remise (cash).
    Du,
    /// Prépaiement en attente de confirmation (PAY, non construit).
    EnAttente,
    /// Réglé intégralement — le seul montant possible est le total.
    Regle,
    /// Remboursé (annulation d'une commande prépayée).
    Rembourse,
}

impl EtatPaiement {
    /// Représentation textuelle = valeur Postgres de l'énum.
    pub fn comme_str(self) -> &'static str {
        match self {
            EtatPaiement::Du => "du",
            EtatPaiement::EnAttente => "en_attente",
            EtatPaiement::Regle => "regle",
            EtatPaiement::Rembourse => "rembourse",
        }
    }
}

impl FromStr for EtatPaiement {
    type Err = ErreurCommandes;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "du" => Ok(EtatPaiement::Du),
            "en_attente" => Ok(EtatPaiement::EnAttente),
            "regle" => Ok(EtatPaiement::Regle),
            "rembourse" => Ok(EtatPaiement::Rembourse),
            autre => Err(ErreurCommandes::StatutInconnu(autre.to_owned())),
        }
    }
}

/// Les 10 lignes du tableau des cas limites (cadrage §7.5) + la sous-branche
/// « refus de reprise vendeur » que CMD-08 nomme explicitement.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TypeIssueEchec {
    /// §7.5-1 — client refuse / injoignable, marchandise NON périssable.
    RefusNonPerissable,
    /// §7.5-2 — le vendeur refuse la reprise (sous-branche de CMD-08).
    RefusRepriseVendeur,
    /// §7.5-3 — marchandise PÉRISSABLE : litige, indemnisation, sanction.
    RefusPerissable,
    /// §7.5-4 — le client conteste le montant : aucune négociation sur place.
    ContestationMontant,
    /// §7.5-5 — client sans appoint : mobile money de la TOTALITÉ, sinon refus.
    SansAppoint,
    /// §7.5-6 — faux billet : fonds d'incidents, coursier indemnisé.
    FauxBillet,
    /// §7.5-7 — non-conformité : la photo de collecte départage.
    NonConformite,
    /// §7.5-8 — casse en transport : franchise coursier plafonnée + fonds.
    CasseTransport,
    /// §7.5-9 — annulation après achat : mêmes règles que le refus.
    AnnulationApresAchat,
    /// §7.5-10 — client injoignable ET vendeur fermé : consigne + re-livraison.
    VendeurFermeConsigne,
    /// §7.5-11 — suspicion de faux refus : indemnisation conditionnée aux preuves.
    SuspicionFauxRefus,
}

impl TypeIssueEchec {
    /// Représentation textuelle = valeur Postgres de l'énum.
    pub fn comme_str(self) -> &'static str {
        match self {
            TypeIssueEchec::RefusNonPerissable => "refus_non_perissable",
            TypeIssueEchec::RefusRepriseVendeur => "refus_reprise_vendeur",
            TypeIssueEchec::RefusPerissable => "refus_perissable",
            TypeIssueEchec::ContestationMontant => "contestation_montant",
            TypeIssueEchec::SansAppoint => "sans_appoint",
            TypeIssueEchec::FauxBillet => "faux_billet",
            TypeIssueEchec::NonConformite => "non_conformite",
            TypeIssueEchec::CasseTransport => "casse_transport",
            TypeIssueEchec::AnnulationApresAchat => "annulation_apres_achat",
            TypeIssueEchec::VendeurFermeConsigne => "vendeur_ferme_consigne",
            TypeIssueEchec::SuspicionFauxRefus => "suspicion_faux_refus",
        }
    }
}

impl FromStr for TypeIssueEchec {
    type Err = ErreurCommandes;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "refus_non_perissable" => Ok(TypeIssueEchec::RefusNonPerissable),
            "refus_reprise_vendeur" => Ok(TypeIssueEchec::RefusRepriseVendeur),
            "refus_perissable" => Ok(TypeIssueEchec::RefusPerissable),
            "contestation_montant" => Ok(TypeIssueEchec::ContestationMontant),
            "sans_appoint" => Ok(TypeIssueEchec::SansAppoint),
            "faux_billet" => Ok(TypeIssueEchec::FauxBillet),
            "non_conformite" => Ok(TypeIssueEchec::NonConformite),
            "casse_transport" => Ok(TypeIssueEchec::CasseTransport),
            "annulation_apres_achat" => Ok(TypeIssueEchec::AnnulationApresAchat),
            "vendeur_ferme_consigne" => Ok(TypeIssueEchec::VendeurFermeConsigne),
            "suspicion_faux_refus" => Ok(TypeIssueEchec::SuspicionFauxRefus),
            autre => Err(ErreurCommandes::StatutInconnu(autre.to_owned())),
        }
    }
}

/// Qui détient l'argent / la marchandise à l'issue d'un échec (CMD-08).
///
/// Les deux axes sont **indépendants** (research R14) : le coursier peut
/// détenir la marchandise pendant que Mefali détient la dette.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Detenteur {
    /// Le client.
    Client,
    /// Le coursier.
    Coursier,
    /// Le vendeur (reprise).
    Vendeur,
    /// Mefali (fonds d'incidents, dette envers le coursier).
    Mefali,
    /// En consigne, en attente de re-livraison (§7.5-10).
    Consigne,
}

impl Detenteur {
    /// Représentation textuelle = valeur Postgres de l'énum.
    pub fn comme_str(self) -> &'static str {
        match self {
            Detenteur::Client => "client",
            Detenteur::Coursier => "coursier",
            Detenteur::Vendeur => "vendeur",
            Detenteur::Mefali => "mefali",
            Detenteur::Consigne => "consigne",
        }
    }
}

impl FromStr for Detenteur {
    type Err = ErreurCommandes;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "client" => Ok(Detenteur::Client),
            "coursier" => Ok(Detenteur::Coursier),
            "vendeur" => Ok(Detenteur::Vendeur),
            "mefali" => Ok(Detenteur::Mefali),
            "consigne" => Ok(Detenteur::Consigne),
            autre => Err(ErreurCommandes::StatutInconnu(autre.to_owned())),
        }
    }
}

/// Sanction posée sur le compte client (CPT-06). L'écriture vit dans le crate
/// `comptes` — CMD passe par le port `RestrictionsCompte` (research R12).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Sanction {
    /// Aucune.
    Aucune,
    /// 1ᵉʳ refus périssable : le client doit désormais prépayer.
    PrepaiementImpose,
    /// 2ᵉ refus : le compte ne peut plus commander.
    Bloque,
}

impl Sanction {
    /// Représentation textuelle = valeur Postgres de l'énum.
    pub fn comme_str(self) -> &'static str {
        match self {
            Sanction::Aucune => "aucune",
            Sanction::PrepaiementImpose => "prepaiement_impose",
            Sanction::Bloque => "bloque",
        }
    }

    /// Rang de la sanction (1 = 1ᵉʳ refus, 2 = 2ᵉ) — payload `sanction.posee`.
    pub fn rang(self) -> i16 {
        match self {
            Sanction::Aucune => 0,
            Sanction::PrepaiementImpose => 1,
            Sanction::Bloque => 2,
        }
    }

    /// Sanction POSABLE côté `comptes`, ou `None` pour `Aucune` — « aucune
    /// sanction » n'est pas une pose, c'est une absence. Cette conversion est
    /// la frontière entre l'énum Postgres `commandes.sanction` (porté par
    /// `issue_echec`) et le concept CPT-06 qui vit dans le crate `comptes`.
    pub fn pour_compte(self) -> Option<comptes::SanctionCompte> {
        match self {
            Sanction::Aucune => None,
            Sanction::PrepaiementImpose => Some(comptes::SanctionCompte::PrepaiementImpose),
            Sanction::Bloque => Some(comptes::SanctionCompte::Bloque),
        }
    }
}

impl FromStr for Sanction {
    type Err = ErreurCommandes;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "aucune" => Ok(Sanction::Aucune),
            "prepaiement_impose" => Ok(Sanction::PrepaiementImpose),
            "bloque" => Ok(Sanction::Bloque),
            autre => Err(ErreurCommandes::StatutInconnu(autre.to_owned())),
        }
    }
}

/// Restrictions courantes d'un compte client (CPT-06).
///
/// **Ré-export** du type du crate `comptes` : les drapeaux vivent dans SON
/// schéma, la restriction est SON concept (research R12). CMD les lit par le
/// port [`crate::ports::RestrictionsCompte`] et ne les écrit jamais lui-même.
/// Dupliquer la structure ici créerait deux vérités pour un même fait.
pub use comptes::Restrictions;

/// Méthode de collecte (unifie scan et dégradé — cadrage §7.2).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ModeCollecte {
    /// Scan du QR de la plaque.
    ScanQr,
    /// Saisie du code de secours (mode dégradé QRC-04).
    CodeSecours,
}

impl ModeCollecte {
    /// Représentation textuelle = valeur Postgres de l'énum.
    pub fn comme_str(self) -> &'static str {
        match self {
            ModeCollecte::ScanQr => "scan_qr",
            ModeCollecte::CodeSecours => "code_secours",
        }
    }
}

impl FromStr for ModeCollecte {
    type Err = ErreurCommandes;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "scan_qr" => Ok(ModeCollecte::ScanQr),
            "code_secours" => Ok(ModeCollecte::CodeSecours),
            autre => Err(ErreurCommandes::ModeInconnu(autre.to_owned())),
        }
    }
}

/// État logistique de la livraison (constitution II — PAS sur le tronc commande).
///
/// Le cycle QRC 006 ne connaissait que la fenêtre `EnCollecte`/`EnLivraison` ;
/// CMD 008 ajoute l'affectation en amont et les trois sorties en aval.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum EtatLivraison {
    /// Coursier affecté, collecte pas encore commencée.
    Assignee,
    /// Collecte des arrêts en cours.
    EnCollecte,
    /// Toutes les COLLECTES résolues — en route vers le client.
    EnLivraison,
    /// Remise validée (QR, code ou dépôt).
    Livree,
    /// Échec déclaré avec preuves.
    Echouee,
    /// Annulée avec sa commande.
    Annulee,
}

impl EtatLivraison {
    /// Représentation textuelle = valeur Postgres de l'énum.
    pub fn comme_str(self) -> &'static str {
        match self {
            EtatLivraison::Assignee => "assignee",
            EtatLivraison::EnCollecte => "en_collecte",
            EtatLivraison::EnLivraison => "en_livraison",
            EtatLivraison::Livree => "livree",
            EtatLivraison::Echouee => "echouee",
            EtatLivraison::Annulee => "annulee",
        }
    }
}

impl FromStr for EtatLivraison {
    type Err = ErreurCommandes;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "assignee" => Ok(EtatLivraison::Assignee),
            "en_collecte" => Ok(EtatLivraison::EnCollecte),
            "en_livraison" => Ok(EtatLivraison::EnLivraison),
            "livree" => Ok(EtatLivraison::Livree),
            "echouee" => Ok(EtatLivraison::Echouee),
            "annulee" => Ok(EtatLivraison::Annulee),
            autre => Err(ErreurCommandes::StatutInconnu(autre.to_owned())),
        }
    }
}

/// Arrêt qu'un coursier peut collecter chez un prestataire (précondition QRC-02).
/// Position et montant sont DÉNORMALISÉS depuis le site (pré-provisionnement
/// offline R6).
#[derive(Debug, Clone, PartialEq)]
pub struct ArretACollecter {
    /// Identifiant de l'arrêt.
    pub arret_id: Uuid,
    /// Livraison porteuse (état EN_LIVRAISON).
    pub livraison_id: Uuid,
    /// Segment (niveau transporteur).
    pub segment_id: Uuid,
    /// Commande ancre.
    pub commande_id: Uuid,
    /// Prestataire visé à cet arrêt.
    pub prestataire_id: Uuid,
    /// Position ATTENDUE du site (proximité de scan).
    pub site_lat: f64,
    /// Position ATTENDUE du site.
    pub site_lon: f64,
    /// Montant avancé (unités mineures, III).
    pub montant_avance: i64,
    /// Devise ISO 4217.
    pub devise: String,
}

/// Progression renvoyée après une collecte réussie.
///
/// ⚠ Les deux compteurs ne portent que sur les arrêts de type `collecte`
/// (cycle CMD 008, P1 / research R4) : l'arrêt de REMISE est un arrêt du
/// segment, mais ce n'est pas une collecte — une course de 2 collectes + 1
/// remise annonce « 2 sur 2 », jamais « 2 sur 3 ».
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ProgressionCollecte {
    /// Nombre de COLLECTES déjà faites (statut `collecte`).
    pub nb_collectes: i16,
    /// Nombre total de COLLECTES de la livraison (la remise n'en est pas une).
    pub nb_arrets: i16,
    /// Vrai si cette collecte a fait basculer la livraison EN_LIVRAISON.
    pub en_livraison: bool,
}

/// Erreurs du domaine commandes.
#[derive(Debug, thiserror::Error)]
pub enum ErreurCommandes {
    /// Arrêt introuvable (ou hors de la course active du coursier).
    #[error("arrêt inconnu : {0}")]
    ArretInconnu(Uuid),
    /// Transition d'arrêt refusée (état incompatible — déjà collecté par un
    /// autre uuid, arrêt indisponible…).
    #[error("état d'arrêt incompatible : « {avant} » ne peut passer à « {apres} »")]
    EtatIncompatible {
        /// État courant de l'arrêt.
        avant: String,
        /// État cible refusé.
        apres: String,
    },
    /// Valeur d'énum `statut_arret` inconnue lue en base.
    #[error("statut d'arrêt inconnu : {0}")]
    StatutInconnu(String),
    /// Valeur d'énum `mode_collecte` inconnue lue en base.
    #[error("mode de collecte inconnu : {0}")]
    ModeInconnu(String),

    // ── Refus métier du cycle CMD 008 ─────────────────────────────────────
    // Chacun porte sa CLÉ i18n fr (`message_cle`) — aucune chaîne utilisateur
    // en dur (constitution VII). Le mapping vers un statut HTTP vit dans la
    // couche `api`, jamais ici.
    /// Commande introuvable, ou hors du périmètre de l'appelant.
    #[error("commande inconnue : {0}")]
    CommandeInconnue(Uuid),
    /// Livraison introuvable, ou non assignée à l'appelant.
    #[error("livraison inconnue : {0}")]
    LivraisonInconnue(Uuid),
    /// Substitution introuvable.
    #[error("substitution inconnue : {0}")]
    SubstitutionInconnue(Uuid),
    /// L'appelant n'est pas le propriétaire de la ressource (FR-041).
    #[error("ressource non possédée par l'appelant")]
    NonProprietaire,
    /// Le compte porte le drapeau `bloque` (FR-026).
    #[error("compte bloqué — aucune commande possible")]
    CompteBloque,
    /// Panier mêlant une catégorie non `mixable` aux courses (FR-009).
    #[error("catégorie non mixable dans un panier multi-vendeurs")]
    CategorieNonMixable,
    /// Panier vide, quantité nulle, ou lignes incohérentes.
    #[error("panier invalide : {0}")]
    PanierInvalide(String),
    /// Ni repère texte assez long, ni note vocale (FR-018).
    #[error("repère de livraison requis (texte ou vocal)")]
    RepereManquant,
    /// Téléphone non vérifié (FR-019).
    #[error("téléphone non vérifié")]
    TelephoneNonVerifie,
    /// Vendeur non commandable à la confirmation (FR-029).
    #[error("vendeur indisponible : {0}")]
    VendeurIndisponible(Uuid),
    /// Article indisponible ou retiré entre le panier et la confirmation (FR-029).
    #[error("article indisponible : {0}")]
    ArticleIndisponible(Uuid),
    /// Cash refusé : plafond de zone dépassé ou prépaiement imposé (FR-024/025).
    #[error("paiement en espèces indisponible pour cette commande")]
    CashIndisponible,
    /// Transition absente de la table FERMÉE des transitions (research R5).
    #[error("transition refusée : « {depuis} » ne peut passer à « {vers} » ({niveau})")]
    TransitionRefusee {
        /// Niveau concerné (`commande`, `livraison`, `arret`).
        niveau: &'static str,
        /// État de départ.
        depuis: String,
        /// État cible refusé.
        vers: String,
    },
    /// Remplacement proposé chez un AUTRE vendeur (FR-048).
    #[error("le remplacement doit venir du même vendeur")]
    SubstitutionAutreVendeur,
    /// Écart de prix au-delà du plafond de zone (FR-047).
    #[error("écart de prix du remplacement au-delà du plafond de zone")]
    SubstitutionEcartPrix,
    /// Décision arrivée après l'échéance persistée (research R10).
    #[error("fenêtre de décision expirée")]
    SubstitutionExpiree,
    /// Code de remise épuisé après le nombre d'essais de zone (CRS-04).
    #[error("code de remise épuisé")]
    CodeEpuise,
    /// Code ou jeton de remise incorrect.
    #[error("code ou jeton de remise incorrect")]
    RemiseIncorrecte,
    /// Échec déclaré sans preuves réunies (FR-056).
    #[error("preuves d'échec incomplètes")]
    PreuvesIncompletes,
    /// Motif d'annulation admin absent (FR-054).
    #[error("motif d'annulation obligatoire")]
    MotifRequis,
    /// Un crate consommé a refusé (zones, prestataires, tarification, comptes).
    #[error("dépendance du domaine : {0}")]
    Dependance(String),

    /// Erreur base de données.
    #[error("erreur base de données commandes : {0}")]
    Sql(#[from] sqlx::Error),
}

impl ErreurCommandes {
    /// Clé i18n fr du refus, ou `None` si l'erreur est technique (l'API sert
    /// alors un 500 neutre). Patron `ErreurTarif::message_cle` du cycle 007.
    pub fn message_cle(&self) -> Option<&'static str> {
        Some(match self {
            ErreurCommandes::ArretInconnu(_) => "arret_inconnu",
            ErreurCommandes::EtatIncompatible { .. } => "etat_incompatible",
            ErreurCommandes::CommandeInconnue(_) => "commande_inconnue",
            ErreurCommandes::LivraisonInconnue(_) => "livraison_inconnue",
            ErreurCommandes::SubstitutionInconnue(_) => "substitution_inconnue",
            ErreurCommandes::NonProprietaire => "non_proprietaire",
            ErreurCommandes::CompteBloque => "compte_bloque",
            ErreurCommandes::CategorieNonMixable => "categorie_non_mixable",
            ErreurCommandes::PanierInvalide(_) => "panier_invalide",
            ErreurCommandes::RepereManquant => "repere_manquant",
            ErreurCommandes::TelephoneNonVerifie => "telephone_non_verifie",
            ErreurCommandes::VendeurIndisponible(_) => "vendeur_indisponible",
            ErreurCommandes::ArticleIndisponible(_) => "article_indisponible",
            ErreurCommandes::CashIndisponible => "cash_indisponible",
            ErreurCommandes::TransitionRefusee { .. } => "transition_refusee",
            ErreurCommandes::SubstitutionAutreVendeur => "substitution_autre_vendeur",
            ErreurCommandes::SubstitutionEcartPrix => "substitution_ecart_prix",
            ErreurCommandes::SubstitutionExpiree => "substitution_expiree",
            ErreurCommandes::CodeEpuise => "code_epuise",
            ErreurCommandes::RemiseIncorrecte => "remise_incorrecte",
            ErreurCommandes::PreuvesIncompletes => "preuves_incompletes",
            ErreurCommandes::MotifRequis => "motif_requis",
            // Techniques : Sql, StatutInconnu, ModeInconnu, Dependance.
            _ => return None,
        })
    }
}

impl From<zones::ErreurZones> for ErreurCommandes {
    fn from(e: zones::ErreurZones) -> Self {
        match e {
            zones::ErreurZones::Sql(sql) => ErreurCommandes::Sql(sql),
            autre => ErreurCommandes::Dependance(autre.to_string()),
        }
    }
}

impl From<prestataires::ErreurPrestataires> for ErreurCommandes {
    fn from(e: prestataires::ErreurPrestataires) -> Self {
        match e {
            prestataires::ErreurPrestataires::Sql(sql) => ErreurCommandes::Sql(sql),
            autre => ErreurCommandes::Dependance(autre.to_string()),
        }
    }
}

impl From<tarification::ErreurTarif> for ErreurCommandes {
    fn from(e: tarification::ErreurTarif) -> Self {
        match e {
            tarification::ErreurTarif::Sql(sql) => ErreurCommandes::Sql(sql),
            autre => ErreurCommandes::Dependance(autre.to_string()),
        }
    }
}

impl From<comptes::ErreurComptes> for ErreurCommandes {
    fn from(e: comptes::ErreurComptes) -> Self {
        match e {
            comptes::ErreurComptes::Sql(sql) => ErreurCommandes::Sql(sql),
            autre => ErreurCommandes::Dependance(autre.to_string()),
        }
    }
}

/// L'outbox se replie sur `Sql` pour préserver l'atomicité (patron cycle 005) :
/// écrire l'événement ET la transition dans la même transaction — un échec de
/// l'un est un échec de l'autre.
impl From<socle::OutboxError> for ErreurCommandes {
    fn from(erreur: socle::OutboxError) -> Self {
        match erreur {
            socle::OutboxError::Db(e) => ErreurCommandes::Sql(e),
        }
    }
}
