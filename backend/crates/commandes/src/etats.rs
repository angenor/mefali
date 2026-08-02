//! Machine à états à trois niveaux — table de transitions **FERMÉE**
//! (data-model §3, research R5).
//!
//! Le cadrage §7.2 mêle en un seul diagramme des états de nature différente :
//! `NOUVELLE`/`ANNULÉE` sont des états de **commande**, `EN_COLLECTE`/
//! `EN_LIVRAISON` des états de **livraison**, `EN_ROUTE`/`ARRIVÉ`/`COLLECTÉ` des
//! états d'**arrêt**. Les séparer est exactement ce qu'impose la constitution II
//! et rend chaque garde locale.
//!
//! La table est **déclarative** : une transition ABSENTE est refusée. C'est la
//! différence entre « refus par défaut » et « oubli par défaut » — et elle rend
//! la couverture de test mécanique (SC-002 : une ligne = un test).

use crate::modele::ErreurCommandes;

/// Acteur autorisé à déclencher une transition.
///
/// `Systeme` couvre les modules non construits (DSP, PAY), exercés par des
/// doubles ce cycle (research R16).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Acteur {
    /// Le client propriétaire de la commande.
    Client,
    /// Le coursier assigné à la livraison.
    Coursier,
    /// Un administrateur (action journalisée).
    Admin,
    /// Le système : dispatch, paiement, expiration, escalade.
    Systeme,
}

impl Acteur {
    /// Représentation textuelle (payloads d'événements, journaux).
    pub fn comme_str(self) -> &'static str {
        match self {
            Acteur::Client => "client",
            Acteur::Coursier => "coursier",
            Acteur::Admin => "admin",
            Acteur::Systeme => "systeme",
        }
    }
}

/// Niveau de la machine à états. Les trois vivent côte à côte et ne se
/// mélangent jamais : un état de livraison n'est pas un état de commande.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Niveau {
    /// Tronc `commande` — états de très haut niveau.
    Commande,
    /// Composant `livraison` — état logistique.
    Livraison,
    /// `arret` — boucle de collecte et remise.
    Arret,
}

impl Niveau {
    /// Nom du niveau, porté par le refus (`ErreurCommandes::TransitionRefusee`).
    pub fn comme_str(self) -> &'static str {
        match self {
            Niveau::Commande => "commande",
            Niveau::Livraison => "livraison",
            Niveau::Arret => "arret",
        }
    }
}

/// Une ligne de la table : `(niveau, depuis, vers, acteurs autorisés)`.
///
/// `depuis = None` = **création** (aucun état de départ). Les états sont écrits
/// avec la valeur Postgres de leur énum : la table se lit à côté de
/// `data-model §3` sans traduction.
struct Transition {
    niveau: Niveau,
    depuis: Option<&'static str>,
    vers: &'static str,
    acteurs: &'static [Acteur],
}

/// TOUTE la machine à états du cycle. Rien d'autre n'est autorisé.
const TRANSITIONS: &[Transition] = &[
    // ── Tronc `commande` (data-model §3.1) ────────────────────────────────
    Transition {
        niveau: Niveau::Commande,
        depuis: None,
        vers: "nouvelle",
        acteurs: &[Acteur::Client],
    },
    Transition {
        niveau: Niveau::Commande,
        depuis: None,
        vers: "en_attente_paiement",
        acteurs: &[Acteur::Client],
    },
    // Paiement confirmé (PAY, simulé ce cycle).
    Transition {
        niveau: Niveau::Commande,
        depuis: Some("en_attente_paiement"),
        vers: "nouvelle",
        acteurs: &[Acteur::Systeme],
    },
    // Expiration du prépaiement, ou renoncement du client.
    Transition {
        niveau: Niveau::Commande,
        depuis: Some("en_attente_paiement"),
        vers: "annulee",
        acteurs: &[Acteur::Systeme, Acteur::Client, Acteur::Admin],
    },
    // Aucun coursier éligible (DSP, simulé).
    Transition {
        niveau: Niveau::Commande,
        depuis: Some("nouvelle"),
        vers: "en_attente_coursier",
        acteurs: &[Acteur::Systeme],
    },
    // ── Ajouts du cycle DSP 009 (specs/009 data-model §3) ─────────────────
    // Bascule prépaiement : la capacité d'avance était le SEUL obstacle du
    // vivier (FR-026). Avant ce cycle, `en_attente_paiement` n'était atteignable
    // qu'à la CRÉATION — le dispatch ne pouvait donc pas l'exiger après coup.
    Transition {
        niveau: Niveau::Commande,
        depuis: Some("nouvelle"),
        vers: "en_attente_paiement",
        acteurs: &[Acteur::Systeme],
    },
    // Retrait du coursier par réassignation : la commande RETOURNE au pipeline
    // par son entrée normale, la file FIFO (specs/009 research R13). Aucun état
    // nouveau n'est inventé.
    Transition {
        niveau: Niveau::Commande,
        depuis: Some("en_cours"),
        vers: "en_attente_coursier",
        acteurs: &[Acteur::Systeme],
    },
    // Livraison assignée (DSP, simulé).
    Transition {
        niveau: Niveau::Commande,
        depuis: Some("nouvelle"),
        vers: "en_cours",
        acteurs: &[Acteur::Systeme],
    },
    // Reprise FIFO depuis la file d'attente.
    Transition {
        niveau: Niveau::Commande,
        depuis: Some("en_attente_coursier"),
        vers: "en_cours",
        acteurs: &[Acteur::Systeme],
    },
    // Annulation SANS FRAIS depuis l'attente.
    Transition {
        niveau: Niveau::Commande,
        depuis: Some("en_attente_coursier"),
        vers: "annulee",
        acteurs: &[Acteur::Client, Acteur::Admin],
    },
    // Annulation SANS FRAIS avant toute prise en charge.
    Transition {
        niveau: Niveau::Commande,
        depuis: Some("nouvelle"),
        vers: "annulee",
        acteurs: &[Acteur::Client, Acteur::Admin],
    },
    // Remise effectuée.
    Transition {
        niveau: Niveau::Commande,
        depuis: Some("en_cours"),
        vers: "terminee",
        acteurs: &[Acteur::Coursier],
    },
    // Annulation en course : règles CMD-08 dès qu'un arrêt est collecté.
    Transition {
        niveau: Niveau::Commande,
        depuis: Some("en_cours"),
        vers: "annulee",
        acteurs: &[Acteur::Client, Acteur::Admin],
    },
    // Échec déclaré, PREUVES RÉUNIES (FR-056).
    Transition {
        niveau: Niveau::Commande,
        depuis: Some("en_cours"),
        vers: "echouee",
        acteurs: &[Acteur::Coursier, Acteur::Admin],
    },
    // ── Composant `livraison` (data-model §3.2) ───────────────────────────
    Transition {
        niveau: Niveau::Livraison,
        depuis: None,
        vers: "assignee",
        acteurs: &[Acteur::Systeme],
    },
    // Premier arrêt passé en route.
    Transition {
        niveau: Niveau::Livraison,
        depuis: Some("assignee"),
        vers: "en_collecte",
        acteurs: &[Acteur::Coursier],
    },
    // TOUTES les collectes résolues (gating corrigé, P1/R4).
    Transition {
        niveau: Niveau::Livraison,
        depuis: Some("en_collecte"),
        vers: "en_livraison",
        acteurs: &[Acteur::Coursier],
    },
    // Remise validée (QR, code ou dépôt).
    Transition {
        niveau: Niveau::Livraison,
        depuis: Some("en_livraison"),
        vers: "livree",
        acteurs: &[Acteur::Coursier],
    },
    // Annulation de la commande, à n'importe quel stade de travail.
    Transition {
        niveau: Niveau::Livraison,
        depuis: Some("assignee"),
        vers: "annulee",
        acteurs: &[Acteur::Client, Acteur::Admin, Acteur::Systeme],
    },
    Transition {
        niveau: Niveau::Livraison,
        depuis: Some("en_collecte"),
        vers: "annulee",
        acteurs: &[Acteur::Client, Acteur::Admin, Acteur::Systeme],
    },
    Transition {
        niveau: Niveau::Livraison,
        depuis: Some("en_livraison"),
        vers: "annulee",
        acteurs: &[Acteur::Client, Acteur::Admin, Acteur::Systeme],
    },
    // Échec déclaré avec preuves.
    Transition {
        niveau: Niveau::Livraison,
        depuis: Some("en_livraison"),
        vers: "echouee",
        acteurs: &[Acteur::Coursier, Acteur::Admin],
    },
    // ── `arret` (data-model §3.3) ─────────────────────────────────────────
    Transition {
        niveau: Niveau::Arret,
        depuis: Some("a_collecter"),
        vers: "en_route",
        acteurs: &[Acteur::Coursier],
    },
    Transition {
        niveau: Niveau::Arret,
        depuis: Some("en_route"),
        vers: "arrive",
        acteurs: &[Acteur::Coursier],
    },
    // Scan QR ou code de secours — chemin NOMINAL de la boucle CMD-04.
    Transition {
        niveau: Niveau::Arret,
        depuis: Some("arrive"),
        vers: "collecte",
        acteurs: &[Acteur::Coursier],
    },
    // ⚠ NON-RÉGRESSION du cycle 006 : le coursier peut scanner sans avoir
    // déclaré son trajet. Ce chemin DIRECT reste accepté (data-model §3.3).
    Transition {
        niveau: Niveau::Arret,
        depuis: Some("a_collecter"),
        vers: "collecte",
        acteurs: &[Acteur::Coursier],
    },
    // Toutes les lignes de l'arrêt retirées ou refusées.
    Transition {
        niveau: Niveau::Arret,
        depuis: Some("arrive"),
        vers: "indisponible",
        acteurs: &[Acteur::Coursier],
    },
    // Vendeur fermé constaté, avant ou pendant le trajet.
    Transition {
        niveau: Niveau::Arret,
        depuis: Some("a_collecter"),
        vers: "indisponible",
        acteurs: &[Acteur::Coursier],
    },
    Transition {
        niveau: Niveau::Arret,
        depuis: Some("en_route"),
        vers: "indisponible",
        acteurs: &[Acteur::Coursier],
    },
];

/// **Garde unique** du domaine : refuse toute transition absente de la table,
/// ou demandée par un acteur non autorisé.
///
/// `depuis = None` demande une CRÉATION. Le refus porte le niveau, ce qui rend
/// le message d'erreur lisible sans connaître l'appelant.
pub fn verifier_transition(
    niveau: Niveau,
    depuis: Option<&str>,
    vers: &str,
    acteur: Acteur,
) -> Result<(), ErreurCommandes> {
    let autorisee = TRANSITIONS.iter().any(|t| {
        t.niveau == niveau && t.depuis == depuis && t.vers == vers && t.acteurs.contains(&acteur)
    });
    if autorisee {
        return Ok(());
    }
    Err(ErreurCommandes::TransitionRefusee {
        niveau: niveau.comme_str(),
        depuis: depuis.unwrap_or("—").to_owned(),
        vers: vers.to_owned(),
    })
}

/// Vrai si la transition existe dans la table, QUEL QUE SOIT l'acteur. Sert les
/// tests de couverture (SC-002) et les surfaces qui décident du statut HTTP :
/// une transition inexistante est un `409`, une transition existante refusée à
/// cet acteur est un `403`.
pub fn transition_existe(niveau: Niveau, depuis: Option<&str>, vers: &str) -> bool {
    TRANSITIONS
        .iter()
        .any(|t| t.niveau == niveau && t.depuis == depuis && t.vers == vers)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn chemin_direct_du_cycle_006_conserve() {
        // Non-régression : le coursier scanne sans avoir déclaré son trajet.
        verifier_transition(
            Niveau::Arret,
            Some("a_collecter"),
            "collecte",
            Acteur::Coursier,
        )
        .expect("chemin direct du cycle 006");
    }

    #[test]
    fn boucle_de_collecte_complete() {
        for (depuis, vers) in [
            ("a_collecter", "en_route"),
            ("en_route", "arrive"),
            ("arrive", "collecte"),
        ] {
            verifier_transition(Niveau::Arret, Some(depuis), vers, Acteur::Coursier)
                .unwrap_or_else(|_| panic!("{depuis} → {vers} doit être autorisée"));
        }
    }

    #[test]
    fn transition_absente_refusee() {
        // Livrer avant d'avoir collecté.
        let e = verifier_transition(
            Niveau::Livraison,
            Some("assignee"),
            "livree",
            Acteur::Coursier,
        )
        .unwrap_err();
        assert_eq!(e.message_cle(), Some("transition_refusee"));

        // Revenir en arrière sur le tronc.
        assert!(verifier_transition(
            Niveau::Commande,
            Some("en_cours"),
            "nouvelle",
            Acteur::Systeme
        )
        .is_err());

        // Ressusciter une commande terminée.
        assert!(
            verifier_transition(Niveau::Commande, Some("terminee"), "annulee", Acteur::Admin)
                .is_err()
        );
    }

    #[test]
    fn acteur_non_autorise_refuse_meme_si_la_transition_existe() {
        // La remise est l'affaire du coursier, jamais du client.
        assert!(transition_existe(
            Niveau::Commande,
            Some("en_cours"),
            "terminee"
        ));
        assert!(verifier_transition(
            Niveau::Commande,
            Some("en_cours"),
            "terminee",
            Acteur::Client
        )
        .is_err());
    }

    #[test]
    fn les_niveaux_ne_se_melangent_pas() {
        // `en_collecte` est un état de LIVRAISON : il n'existe pas sur le tronc.
        assert!(!transition_existe(
            Niveau::Commande,
            Some("nouvelle"),
            "en_collecte"
        ));
        // `terminee` est un état de COMMANDE : il n'existe pas sur la livraison.
        assert!(!transition_existe(
            Niveau::Livraison,
            Some("en_livraison"),
            "terminee"
        ));
    }

    /// Cycle DSP 009 — les DEUX lignes ajoutées, et rien d'autre.
    #[test]
    fn les_deux_transitions_du_dispatch_sont_autorisees() {
        // Bascule prépaiement après création (FR-026).
        verifier_transition(
            Niveau::Commande,
            Some("nouvelle"),
            "en_attente_paiement",
            Acteur::Systeme,
        )
        .expect("le dispatch peut exiger un prépaiement après création");

        // Retrait du coursier par réassignation (FR-073).
        verifier_transition(
            Niveau::Commande,
            Some("en_cours"),
            "en_attente_coursier",
            Acteur::Systeme,
        )
        .expect("une course reprise retourne à la file d'attente");
    }

    /// Les refus SYMÉTRIQUES — ce sont eux qui disent que la table est restée
    /// fermée. On ne remet pas une course en paiement une fois lancée : le
    /// coursier a déjà commencé, et la cliente ne peut plus renoncer sans frais.
    #[test]
    fn les_refus_symetriques_des_deux_ajouts_tiennent() {
        assert!(
            !transition_existe(Niveau::Commande, Some("en_cours"), "en_attente_paiement"),
            "une course lancée ne repart jamais en paiement",
        );
        assert!(
            !transition_existe(
                Niveau::Commande,
                Some("en_attente_coursier"),
                "en_attente_paiement"
            ),
            "une commande en file d'attente ne bascule pas en paiement : le \
             prépaiement se décide sur le vivier, pas sur l'attente",
        );
        // Et l'acteur reste borné : ni le client ni le coursier ne déclenchent
        // ces deux transitions.
        for acteur in [Acteur::Client, Acteur::Coursier] {
            assert!(verifier_transition(
                Niveau::Commande,
                Some("nouvelle"),
                "en_attente_paiement",
                acteur
            )
            .is_err());
            assert!(verifier_transition(
                Niveau::Commande,
                Some("en_cours"),
                "en_attente_coursier",
                acteur
            )
            .is_err());
        }
    }

    #[test]
    fn aucune_transition_depuis_un_etat_terminal() {
        for terminal in ["terminee", "annulee", "echouee"] {
            for vers in ["nouvelle", "en_cours", "terminee", "annulee", "echouee"] {
                assert!(
                    !transition_existe(Niveau::Commande, Some(terminal), vers),
                    "« {terminal} » est terminal : aucune transition n'en part",
                );
            }
        }
    }
}
