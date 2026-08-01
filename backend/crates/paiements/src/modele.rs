//! Types purs du domaine paiement, ses erreurs et leurs clés i18n.
//!
//! Aucune I/O ici : le module compile et se teste sans base ni réseau. La
//! **machine à états de la transaction** y vit aussi (§ *Transitions*), sur le
//! patron de `commandes::etats::verifier_transition` — une table fermée, et une
//! garde unique qui refuse tout ce qui n'y figure pas.

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

// ── 1. États et vocabulaires persistés ────────────────────────────────────

/// Cycle de vie d'une transaction de prépaiement (migration 0020).
///
/// ⚠ Il n'existe **aucun** état « partiellement payée », et ce n'est pas un
/// oubli : la constitution III interdit tout chemin de paiement partiel et la
/// spec en fait un invariant (FR-002). Ajouter une variante ici ouvrirait ce
/// chemin par la porte du type.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "paiements.etat_transaction", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum EtatTransaction {
    /// Session vivante : le client peut payer, l'accès est servi.
    Ouverte,
    /// Notification signée de succès, commande confirmée. **Terminal** (FR-034).
    Reglee,
    /// Refus opérateur. La session **vit encore** : le client réessaie (FR-026).
    Echouee,
    /// Échéance franchie sans succès → la commande est annulée sans frais.
    Expiree,
    /// Succès arrivé **après** l'expiration (R8). Un dossier est ouvert, la
    /// commande n'est **pas** ressuscitée.
    PayeeHorsDelai,
}

impl EtatTransaction {
    /// Libellé SQL — celui de l'énumération PostgreSQL, mot pour mot.
    pub fn comme_str(self) -> &'static str {
        match self {
            EtatTransaction::Ouverte => "ouverte",
            EtatTransaction::Reglee => "reglee",
            EtatTransaction::Echouee => "echouee",
            EtatTransaction::Expiree => "expiree",
            EtatTransaction::PayeeHorsDelai => "payee_hors_delai",
        }
    }

    /// Vrai si l'état accepte encore un paiement du client.
    ///
    /// `Echouee` en fait partie : un refus d'opérateur ne clôt pas la session,
    /// il invite à réessayer tant que l'échéance n'est pas franchie (FR-026).
    pub fn accepte_paiement(self) -> bool {
        matches!(self, EtatTransaction::Ouverte | EtatTransaction::Echouee)
    }
}

/// Moyen effectivement utilisé, tel que le fournisseur le communique (FR-012).
///
/// `Inconnu` est l'état **avant** que le fournisseur ne le dise — jamais deviné,
/// jamais déduit du montant ni de la zone.
///
/// ## Pourquoi `Autre` ne porte pas le libellé du fournisseur
///
/// Le contrat de conception ([`contracts/ports-paiements.md`] §1.1) écrivait
/// `Autre(String)`. Le libellé est délibérément **abandonné à la frontière** :
///
/// 1. FR-003 interdit qu'un vocabulaire propriétaire franchisse
///    `src/fournisseur/` — un libellé d'agrégateur remonté jusqu'au domaine, puis
///    jusqu'à une réponse d'API, est exactement la fuite que PAY-05 existe pour
///    empêcher, et `verifier-frontiere-paiement.sh` la refuserait ;
/// 2. le schéma n'a aucune colonne pour l'accueillir (`paiements.moyen_paiement`
///    est un enum fermé) : le libellé serait perdu au premier `INSERT`, et un
///    type qui promet ce que la base ne tient pas ment à son lecteur.
///
/// Le libellé brut reste **journalisé en `debug` dans le module fournisseur**,
/// où le diagnostic d'intégration en a besoin et où il ne franchit rien.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "paiements.moyen_paiement", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum MoyenPaiement {
    Inconnu,
    Wave,
    OrangeMoney,
    MtnMomo,
    MoovMoney,
    Carte,
    /// Un moyen qu'un futur agrégateur nommerait sans que le domaine migre.
    Autre,
}

/// Anomalie d'argent qui doit être **vue** par un humain (FR-082).
///
/// Un dossier n'est pas un log : un log se perd dans le volume, un dossier a un
/// état et se clôt avec un motif et un auteur.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "paiements.type_dossier", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum TypeDossier {
    /// La notification annonce un autre montant que le total figé (FR-024).
    MontantDivergent,
    /// La notification annonce une autre devise (FR-024).
    DeviseDivergente,
    /// Succès arrivé après l'annulation de la commande (FR-037, R8).
    PaiementHorsDelai,
    /// Référence de fournisseur sans commande rattachable (FR-082).
    TransactionOrpheline,
    /// La retenue dépassait le montant des articles : avance écrêtée (FR-052).
    RetenueEcretee,
    /// PAY-04 n'est pas construit : le dû est **vu**, il n'est pas versé (FR-082).
    RemboursementClientDu,
}

impl TypeDossier {
    pub fn comme_str(self) -> &'static str {
        match self {
            TypeDossier::MontantDivergent => "montant_divergent",
            TypeDossier::DeviseDivergente => "devise_divergente",
            TypeDossier::PaiementHorsDelai => "paiement_hors_delai",
            TypeDossier::TransactionOrpheline => "transaction_orpheline",
            TypeDossier::RetenueEcretee => "retenue_ecretee",
            TypeDossier::RemboursementClientDu => "remboursement_client_du",
        }
    }

    /// Clé i18n du motif par défaut de ce type de dossier.
    ///
    /// Aucun texte libre n'entre jamais dans `dossier.motif_cle` : la colonne
    /// porte une clé, l'affichage porte la phrase.
    pub fn motif_cle(self) -> &'static str {
        match self {
            TypeDossier::MontantDivergent => "paiement.dossier.montant_divergent",
            TypeDossier::DeviseDivergente => "paiement.dossier.devise_divergente",
            TypeDossier::PaiementHorsDelai => "paiement.dossier.paiement_hors_delai",
            TypeDossier::TransactionOrpheline => "paiement.dossier.transaction_orpheline",
            TypeDossier::RetenueEcretee => "paiement.dossier.retenue_ecretee",
            TypeDossier::RemboursementClientDu => "paiement.dossier.remboursement_client_du",
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "paiements.etat_dossier", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum EtatDossier {
    Ouvert,
    Clos,
}

// ── 2. Vues du domaine ────────────────────────────────────────────────────

/// Une transaction telle que le domaine la manipule.
///
/// `acces_paiement` est `None` dès que l'état quitte `Ouverte` : la colonne est
/// effacée à l'issue (data-model §6). Il n'apparaît **jamais** dans un événement
/// outbox ni dans un log (FR-006, FR-103).
#[derive(Debug, Clone)]
pub struct Transaction {
    pub id: Uuid,
    pub commande_id: Uuid,
    pub montant_unites: i64,
    pub devise: String,
    pub etat: EtatTransaction,
    pub moyen: MoyenPaiement,
    pub fournisseur: String,
    pub reference_fournisseur: Option<String>,
    pub acces_paiement: Option<String>,
    pub ouverte_le: DateTime<Utc>,
    pub expire_le: DateTime<Utc>,
    pub issue_le: Option<DateTime<Utc>>,
}

impl Transaction {
    /// Secondes restantes avant l'échéance, **calculées côté serveur**.
    ///
    /// L'horloge de l'app ne décide de rien : elle affiche un compte à rebours
    /// qu'elle recale sur cette valeur à chaque lecture (FR-017). Une session
    /// échue rend `0`, jamais un nombre négatif.
    pub fn restant_s(&self, maintenant: DateTime<Utc>) -> i64 {
        if !self.etat.accepte_paiement() {
            return 0;
        }
        (self.expire_le - maintenant).num_seconds().max(0)
    }

    /// Vrai si l'échéance est franchie, **que le balayage soit passé ou non**.
    ///
    /// C'est la lecture qui fait foi, pas le job (R7) : une session échue est
    /// refusée immédiatement, même si sa ligne porte encore `ouverte` parce que
    /// le balayage n'a pas encore tourné.
    pub fn echue(&self, maintenant: DateTime<Utc>) -> bool {
        maintenant >= self.expire_le
    }
}

/// Un dossier d'anomalie, tel que l'exploitation le lit.
#[derive(Debug, Clone)]
pub struct Dossier {
    pub id: Uuid,
    pub type_dossier: TypeDossier,
    pub etat: EtatDossier,
    pub commande_id: Option<Uuid>,
    pub transaction_id: Option<Uuid>,
    pub arret_id: Option<Uuid>,
    pub montant_constate: Option<i64>,
    pub montant_attendu: Option<i64>,
    pub devise: Option<String>,
    pub motif_cle: String,
    pub ouvert_le: DateTime<Utc>,
    pub clos_par: Option<Uuid>,
    pub clos_le: Option<DateTime<Utc>>,
    pub clos_motif_cle: Option<String>,
}

// ── 3. Transitions — la table fermée ──────────────────────────────────────

/// Table **fermée** des transitions autorisées de la transaction (data-model
/// §4.1). Toute transition absente de cette liste est refusée : c'est la seule
/// façon de garantir que `Reglee` reste terminal (FR-034).
///
/// Lire cette table de haut en bas donne le cycle de vie complet, sans avoir à
/// chercher les `UPDATE` dans le dépôt.
const TRANSITIONS: &[(EtatTransaction, EtatTransaction)] = &[
    // Notification signée de succès, montant et devise conformes.
    (EtatTransaction::Ouverte, EtatTransaction::Reglee),
    // Refus d'opérateur — la session survit, le client peut réessayer.
    (EtatTransaction::Ouverte, EtatTransaction::Echouee),
    // Échéance franchie, après réconciliation infructueuse auprès du fournisseur.
    (EtatTransaction::Ouverte, EtatTransaction::Expiree),
    // Le client réessaie après un refus : retour dans le chemin nominal.
    (EtatTransaction::Echouee, EtatTransaction::Reglee),
    // Un second refus reste un refus (rejouable sans changer d'état de fait,
    // mais la transition existe : elle réécrit le motif et le moyen).
    (EtatTransaction::Echouee, EtatTransaction::Echouee),
    // La session refusée finit par expirer comme les autres.
    (EtatTransaction::Echouee, EtatTransaction::Expiree),
    // Succès tardif (R8) — la commande n'est PAS touchée, un dossier s'ouvre.
    (EtatTransaction::Expiree, EtatTransaction::PayeeHorsDelai),
];

/// **Garde unique** des transitions de transaction.
///
/// Aucun chemin d'écriture du crate ne modifie `etat` sans passer par ici. Le
/// refus nomme les deux états, ce qui rend l'erreur lisible dans un journal sans
/// avoir à retrouver l'appelant.
pub fn verifier_transition(
    depuis: EtatTransaction,
    vers: EtatTransaction,
) -> Result<(), ErreurPaiements> {
    if TRANSITIONS.iter().any(|(d, v)| *d == depuis && *v == vers) {
        return Ok(());
    }
    Err(ErreurPaiements::TransitionRefusee {
        depuis: depuis.comme_str(),
        vers: vers.comme_str(),
    })
}

/// Vrai si la transition figure dans la table, sans lever d'erreur.
///
/// Sert les surfaces qui décident d'un statut HTTP et les tests de couverture.
pub fn transition_existe(depuis: EtatTransaction, vers: EtatTransaction) -> bool {
    TRANSITIONS.iter().any(|(d, v)| *d == depuis && *v == vers)
}

// ── 4. Erreurs et leurs clés i18n ─────────────────────────────────────────

/// Refus et pannes du domaine paiement.
///
/// Chaque refus **métier** porte une clé i18n courte (`message_cle`) que la
/// couche HTTP préfixe de son espace de noms (`paiement.erreur.…`) — patron
/// `ErreurCoursier` / `ErreurDispatch`. Une erreur technique n'expose rien : son
/// détail vit dans les journaux.
#[derive(Debug, thiserror::Error)]
pub enum ErreurPaiements {
    /// Aucune transaction pour cette commande (commande cash, typiquement).
    #[error("aucune transaction de paiement")]
    TransactionInconnue,
    /// La commande n'attend pas de paiement : cash, déjà réglée, ou annulée.
    #[error("paiement non requis pour cette commande")]
    PaiementNonRequis,
    /// La commande n'appartient pas à l'appelant (FR-005).
    #[error("commande d'un autre client")]
    CommandeNonProprietaire,
    /// L'échéance est franchie : plus rien ne peut être payé sur cette session.
    #[error("session de paiement expirée")]
    SessionExpiree,
    /// Transition absente de la table fermée — `Reglee` est terminal (FR-034).
    #[error("transition de paiement refusée : {depuis} → {vers}")]
    TransitionRefusee {
        depuis: &'static str,
        vers: &'static str,
    },
    /// Le segment `{fournisseur}` de l'URL du webhook ne désigne personne.
    #[error("fournisseur inconnu : {0}")]
    FournisseurInconnu(String),
    /// Signature absente, invalide ou périmée (FR-020).
    #[error("signature de notification invalide")]
    SignatureInvalide,
    /// Le fournisseur est injoignable ou en erreur. La commande reste
    /// **intacte** : elle n'est jamais laissée dans un état bancal (FR-018).
    #[error("fournisseur indisponible : {0}")]
    FournisseurIndisponible(String),
    /// Dossier d'exploitation inconnu.
    #[error("dossier inconnu : {0}")]
    DossierInconnu(Uuid),
    /// Dossier déjà clos — la clôture n'est pas une bascule.
    #[error("dossier déjà clos")]
    DossierDejaClos,
    /// Motif de clôture obligatoire absent.
    #[error("motif obligatoire")]
    MotifRequis,
    /// Paramètre de zone absent — jamais un défaut silencieux (constitution I).
    #[error("paramètre de zone absent : {0}")]
    ParametreAbsent(String),
    /// Valeur d'énumération inconnue lue en base ou reçue en requête.
    #[error("valeur inconnue : {0}")]
    ValeurInconnue(String),
    /// Requête mal formée.
    #[error("demande invalide : {0}")]
    DemandeInvalide(&'static str),
    /// Domaine commandes (port `CommandesAPayer`).
    #[error("socle logistique : {0}")]
    Commandes(#[from] commandes::ErreurCommandes),
    /// Configuration de zone.
    #[error("configuration de zone : {0}")]
    Zones(#[from] zones::ErreurZones),
    /// Erreur de la base de données.
    #[error("erreur base de données paiements : {0}")]
    Sql(#[from] sqlx::Error),
}

impl ErreurPaiements {
    /// Clé i18n **courte** du refus, ou `None` si l'erreur est technique.
    ///
    /// ⚠ Aucune de ces clés ne nomme un fournisseur, et aucune ne porte de
    /// montant : un message d'erreur est lu par un client, pas par un
    /// comptable.
    pub fn message_cle(&self) -> Option<&'static str> {
        Some(match self {
            ErreurPaiements::TransactionInconnue => "transaction_inconnue",
            ErreurPaiements::PaiementNonRequis => "paiement_non_requis",
            ErreurPaiements::CommandeNonProprietaire => "commande_interdite",
            ErreurPaiements::SessionExpiree => "session_expiree",
            ErreurPaiements::TransitionRefusee { .. } => "transition_refusee",
            ErreurPaiements::FournisseurInconnu(_) => "fournisseur_inconnu",
            ErreurPaiements::SignatureInvalide => "signature_invalide",
            ErreurPaiements::FournisseurIndisponible(_) => "fournisseur_indisponible",
            ErreurPaiements::DossierInconnu(_) => "dossier_inconnu",
            ErreurPaiements::DossierDejaClos => "dossier_deja_clos",
            ErreurPaiements::MotifRequis => "motif_requis",
            // Une valeur d'entrée hors énumération est un refus de DEMANDE, pas
            // une panne (leçon du cycle 010 : `?etat=peut-etre` rendait 500).
            ErreurPaiements::ValeurInconnue(_) => "valeur_inconnue",
            ErreurPaiements::DemandeInvalide(_) => "demande_invalide",
            // Techniques : rien à exposer.
            ErreurPaiements::ParametreAbsent(_)
            | ErreurPaiements::Commandes(_)
            | ErreurPaiements::Zones(_)
            | ErreurPaiements::Sql(_) => return None,
        })
    }
}

/// Une écriture d'outbox qui échoue est une erreur de BASE, pas un refus
/// métier : la traduire en `Sql` garde le statut HTTP juste (500, pas 422) et
/// évite d'exposer une clé i18n pour une panne (patron `ErreurCoursier`).
impl From<socle::OutboxError> for ErreurPaiements {
    fn from(erreur: socle::OutboxError) -> Self {
        // Déstructurer plutôt que filtrer : une variante AJOUTÉE plus tard
        // cassera la compilation ici au lieu de tomber en silence dans un bras
        // fourre-tout qui la maquillerait en erreur de configuration.
        let socle::OutboxError::Db(e) = erreur;
        ErreurPaiements::Sql(e)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Le chemin nominal complet, dans l'ordre où il se produit.
    #[test]
    fn chemin_nominal_autorise() {
        verifier_transition(EtatTransaction::Ouverte, EtatTransaction::Reglee)
            .expect("une notification signée de succès règle la session");
    }

    /// FR-026 — un refus n'est pas une fin : le client réessaie.
    #[test]
    fn le_refus_permet_le_reessai() {
        verifier_transition(EtatTransaction::Ouverte, EtatTransaction::Echouee).unwrap();
        verifier_transition(EtatTransaction::Echouee, EtatTransaction::Reglee)
            .expect("le client réessaie et réussit, sur la MÊME session");
        assert!(
            EtatTransaction::Echouee.accepte_paiement(),
            "une session refusée accepte encore un paiement tant qu'elle vit",
        );
    }

    /// R8 — le succès tardif ne ressuscite rien, il ouvre un dossier.
    #[test]
    fn le_succes_tardif_part_de_expiree() {
        verifier_transition(EtatTransaction::Expiree, EtatTransaction::PayeeHorsDelai)
            .expect("succès arrivé après l'échéance");
    }

    /// FR-034 — `Reglee` est TERMINAL. C'est le test qui empêche une seconde
    /// notification de rouvrir une session déjà payée, ou une expiration
    /// d'annuler une commande déjà confirmée.
    #[test]
    fn reglee_est_terminal() {
        for vers in [
            EtatTransaction::Ouverte,
            EtatTransaction::Echouee,
            EtatTransaction::Expiree,
            EtatTransaction::PayeeHorsDelai,
            EtatTransaction::Reglee,
        ] {
            let e = verifier_transition(EtatTransaction::Reglee, vers).unwrap_err();
            assert_eq!(
                e.message_cle(),
                Some("transition_refusee"),
                "aucune transition ne sort de `reglee` (vers {})",
                vers.comme_str(),
            );
        }
    }

    /// `payee_hors_delai` est terminal lui aussi : le dossier se clôt à la main,
    /// la transaction ne bouge plus.
    #[test]
    fn payee_hors_delai_est_terminal() {
        for vers in [
            EtatTransaction::Ouverte,
            EtatTransaction::Reglee,
            EtatTransaction::Echouee,
            EtatTransaction::Expiree,
        ] {
            assert!(
                verifier_transition(EtatTransaction::PayeeHorsDelai, vers).is_err(),
                "aucune transition ne sort de `payee_hors_delai` (vers {})",
                vers.comme_str(),
            );
        }
    }

    /// Les transitions INTERDITES, une par une (FR-034). Une table fermée ne
    /// vaut que si son complément est testé : sans ce test, ajouter une paire
    /// par erreur passerait inaperçu.
    #[test]
    fn transitions_interdites_refusees() {
        let interdites = [
            // Ressusciter une session expirée en la rouvrant.
            (EtatTransaction::Expiree, EtatTransaction::Ouverte),
            // Faire échouer une session déjà expirée.
            (EtatTransaction::Expiree, EtatTransaction::Echouee),
            // Régler une session expirée SANS passer par `payee_hors_delai` :
            // ce serait confirmer la commande annulée (R8 l'interdit).
            (EtatTransaction::Expiree, EtatTransaction::Reglee),
            // Revenir en arrière depuis un refus vers l'ouverture : inutile, la
            // session est déjà réessayable — et une transition inutile est une
            // porte ouverte.
            (EtatTransaction::Echouee, EtatTransaction::Ouverte),
            // Une session ouverte ne saute pas directement au hors-délai.
            (EtatTransaction::Ouverte, EtatTransaction::PayeeHorsDelai),
            // Une session ouverte ne se rouvre pas.
            (EtatTransaction::Ouverte, EtatTransaction::Ouverte),
        ];
        for (depuis, vers) in interdites {
            assert!(
                !transition_existe(depuis, vers),
                "{} → {} ne doit PAS figurer dans la table",
                depuis.comme_str(),
                vers.comme_str(),
            );
            assert!(verifier_transition(depuis, vers).is_err());
        }
    }

    /// Le compte des transitions autorisées est figé : toute paire ajoutée sans
    /// être documentée fait tomber ce test, et c'est le but.
    #[test]
    fn la_table_reste_fermee() {
        assert_eq!(
            TRANSITIONS.len(),
            7,
            "7 transitions autorisées (data-model §4.1) — en ajouter une exige \
             de justifier pourquoi l'argent peut désormais suivre ce chemin",
        );
    }

    /// FR-017 — le temps restant est calculé côté serveur, et ne descend jamais
    /// sous zéro : un compte à rebours négatif à l'écran serait un bug visible.
    #[test]
    fn le_restant_ne_descend_pas_sous_zero() {
        let ouverte = chrono::Utc::now();
        let t = Transaction {
            id: Uuid::now_v7(),
            commande_id: Uuid::now_v7(),
            montant_unites: 12_500,
            devise: "XOF".to_owned(),
            etat: EtatTransaction::Ouverte,
            moyen: MoyenPaiement::Inconnu,
            fournisseur: "simule".to_owned(),
            reference_fournisseur: None,
            acces_paiement: None,
            ouverte_le: ouverte,
            expire_le: ouverte + chrono::Duration::seconds(900),
            issue_le: None,
        };

        assert_eq!(t.restant_s(ouverte), 900);
        assert_eq!(t.restant_s(ouverte + chrono::Duration::seconds(100)), 800);
        assert_eq!(
            t.restant_s(ouverte + chrono::Duration::seconds(1_000)),
            0,
            "échue depuis 100 s → 0, jamais −100",
        );
        assert!(t.echue(ouverte + chrono::Duration::seconds(900)));
        assert!(!t.echue(ouverte + chrono::Duration::seconds(899)));
    }

    /// Une session close ne porte plus de temps restant, même si son échéance
    /// est dans le futur : elle est réglée, il n'y a plus rien à attendre.
    #[test]
    fn une_session_reglee_ne_porte_plus_de_restant() {
        let ouverte = chrono::Utc::now();
        let t = Transaction {
            id: Uuid::now_v7(),
            commande_id: Uuid::now_v7(),
            montant_unites: 12_500,
            devise: "XOF".to_owned(),
            etat: EtatTransaction::Reglee,
            moyen: MoyenPaiement::Wave,
            fournisseur: "simule".to_owned(),
            reference_fournisseur: Some("ref".to_owned()),
            acces_paiement: None,
            ouverte_le: ouverte,
            expire_le: ouverte + chrono::Duration::seconds(900),
            issue_le: Some(ouverte + chrono::Duration::seconds(42)),
        };
        assert_eq!(t.restant_s(ouverte), 0);
    }

    /// Les clés i18n existent pour tous les refus métier, et pour aucune panne.
    #[test]
    fn les_refus_metier_portent_une_cle_les_pannes_non() {
        assert_eq!(
            ErreurPaiements::PaiementNonRequis.message_cle(),
            Some("paiement_non_requis"),
        );
        assert_eq!(
            ErreurPaiements::SessionExpiree.message_cle(),
            Some("session_expiree"),
        );
        assert_eq!(
            ErreurPaiements::ParametreAbsent("paiement.session_duree_s".to_owned()).message_cle(),
            None,
            "une panne de configuration n'expose rien au client",
        );
    }
}
