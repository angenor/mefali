//! Les **4 paramètres de zone** du cycle (research R18), hérités pays → ville.
//!
//! Constitution I : aucun de ces nombres n'existe en dur dans le code. Une clé
//! absente est une **erreur de configuration**, jamais un défaut silencieux
//! (patron `coursier::config` et `dispatch::config`). Une durée de session qui
//! tomberait à 0 par accident annulerait toutes les commandes à la seconde où
//! elles naissent — un défaut silencieux ici coûte des commandes, pas un
//! message d'erreur.
//!
//! **Pourquoi pas une constante Rust pour les 15 minutes.** La durée de session
//! est précisément le genre de valeur qu'un lancement fait bouger : trop courte,
//! le client qui cherche son téléphone perd sa commande ; trop longue, le
//! vendeur prépare pour rien. La faire bouger ne doit pas demander un
//! déploiement (FR-100).

use uuid::Uuid;
use zones::ConfigurationZones;

use crate::modele::ErreurPaiements;

/// Clés des paramètres — le seul endroit où ces chaînes sont écrites.
pub mod cles {
    /// Durée de vie d'une session de prépaiement (secondes) — FR-030.
    pub const SESSION_DUREE_S: &str = "paiement.session_duree_s";
    /// Âge à partir duquel le balayage interroge le fournisseur avant
    /// d'annuler (secondes) — R7, FR-027.
    pub const RECONCILIATION_AVANT_EXPIRATION_S: &str =
        "paiement.reconciliation_avant_expiration_s";
    /// Seuil d'alerte d'exposition en créances d'un coursier (unités mineures)
    /// — FR-065.
    pub const CREANCE_ALERTE_UNITES: &str = "paiement.creance_alerte_unites";
    /// Coupe-circuit d'exploitation : liste des moyens laissés actifs.
    /// **Vide = tous actifs** — FR-011 interdit de masquer un moyen au client.
    pub const MOYENS_ACTIFS: &str = "paiement.moyens_actifs";

    /// Les 4 clés créées par ce cycle — l'inventaire opposable.
    pub const TOUTES: [&str; 4] = [
        SESSION_DUREE_S,
        RECONCILIATION_AVANT_EXPIRATION_S,
        CREANCE_ALERTE_UNITES,
        MOYENS_ACTIFS,
    ];
}

/// Toute la configuration de paiement d'une zone, chargée en une fois.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ConfigPaiements {
    /// Zone résolue.
    pub zone: Uuid,
    /// Devise ISO 4217 de la zone (jamais écrite en dur).
    pub devise: String,
    /// Durée de vie d'une session de prépaiement.
    pub session_duree_s: i64,
    /// Fenêtre de réconciliation avant annulation.
    pub reconciliation_avant_expiration_s: i64,
    /// Seuil d'alerte d'exposition en créances.
    pub creance_alerte_unites: i64,
    /// Moyens laissés actifs. **Vide = tous**, et c'est le cas nominal.
    pub moyens_actifs: Vec<String>,
}

impl ConfigPaiements {
    /// Charge et **valide** la configuration d'une zone.
    pub async fn charger(
        zones: &dyn ConfigurationZones,
        zone: Uuid,
    ) -> Result<Self, ErreurPaiements> {
        let devise = zones.devise(zone).await?;
        let moyens_actifs = liste(zones, zone, cles::MOYENS_ACTIFS).await?;

        // Un coupe-circuit ARMÉ doit se voir. Sa présence non vide est
        // anormale par construction (research R18) : elle signifie qu'un moyen
        // est coupé chez l'agrégateur et que des clients se le verront refuser.
        // Sans cette trace, la coupure survivrait à l'incident qui l'a motivée
        // et personne ne saurait pourquoi un moyen a « disparu ».
        if !moyens_actifs.is_empty() {
            tracing::warn!(
                zone = %zone,
                moyens = ?moyens_actifs,
                cle = cles::MOYENS_ACTIFS,
                "coupe-circuit de moyens de paiement ARMÉ — les autres moyens \
                 sont refusés au client ; à lever dès l'incident clos (FR-011)",
            );
        }

        let config = Self {
            zone,
            devise: devise.code,
            session_duree_s: entier(zones, zone, cles::SESSION_DUREE_S).await?,
            reconciliation_avant_expiration_s: entier(
                zones,
                zone,
                cles::RECONCILIATION_AVANT_EXPIRATION_S,
            )
            .await?,
            creance_alerte_unites: entier(zones, zone, cles::CREANCE_ALERTE_UNITES).await?,
            moyens_actifs,
        };
        config.valider()?;
        Ok(config)
    }

    /// Les gardes, isolées pour être testables sans base.
    pub fn valider(&self) -> Result<(), ErreurPaiements> {
        // Une session de durée nulle ou négative annulerait chaque commande à
        // la seconde de sa création : le balayage la trouverait échue au
        // premier tour, et Awa n'aurait jamais le temps d'ouvrir son
        // application de mobile money.
        if self.session_duree_s <= 0 {
            return Err(ErreurPaiements::ValeurInconnue(format!(
                "{} vaut {} : toute session naîtrait déjà expirée",
                cles::SESSION_DUREE_S,
                self.session_duree_s,
            )));
        }
        // La fenêtre de réconciliation borne l'âge à partir duquel il vaut la
        // peine d'interroger le fournisseur. Plus longue que la session
        // elle-même, elle ne se déclencherait jamais : chaque webhook perdu
        // deviendrait un litige, ce que R7 existe pour empêcher.
        if self.reconciliation_avant_expiration_s < 0
            || self.reconciliation_avant_expiration_s > self.session_duree_s
        {
            return Err(ErreurPaiements::ValeurInconnue(format!(
                "{} vaut {} s, hors de [0, {} = {} s] : la réconciliation \
                 avant annulation ne se déclencherait jamais",
                cles::RECONCILIATION_AVANT_EXPIRATION_S,
                self.reconciliation_avant_expiration_s,
                cles::SESSION_DUREE_S,
                self.session_duree_s,
            )));
        }
        if self.creance_alerte_unites < 0 {
            return Err(ErreurPaiements::ValeurInconnue(format!(
                "{} vaut {} : un seuil d'alerte négatif alerterait toujours",
                cles::CREANCE_ALERTE_UNITES,
                self.creance_alerte_unites,
            )));
        }
        Ok(())
    }

    /// Vrai si ce moyen peut être proposé au client.
    ///
    /// **Vide = tous actifs.** FR-011 interdit de masquer un moyen : cette
    /// fonction ne doit jamais devenir un filtre produit — elle n'existe que
    /// pour couper en urgence un moyen défaillant chez l'agrégateur.
    pub fn moyen_actif(&self, moyen: &str) -> bool {
        self.moyens_actifs.is_empty() || self.moyens_actifs.iter().any(|m| m == moyen)
    }
}

/// Paramètre de zone entier, résolu par héritage.
async fn entier(
    zones: &dyn ConfigurationZones,
    zone: Uuid,
    cle: &str,
) -> Result<i64, ErreurPaiements> {
    zones
        .parametre(zone, cle)
        .await?
        .and_then(|v| v.as_i64())
        .ok_or_else(|| ErreurPaiements::ParametreAbsent(cle.to_owned()))
}

/// Paramètre de zone « liste de chaînes », résolu par héritage.
///
/// Une clé **absente** est refusée comme les autres (constitution I) ; une clé
/// présente et **vide** est le cas nominal du coupe-circuit.
async fn liste(
    zones: &dyn ConfigurationZones,
    zone: Uuid,
    cle: &str,
) -> Result<Vec<String>, ErreurPaiements> {
    let valeur = zones
        .parametre(zone, cle)
        .await?
        .ok_or_else(|| ErreurPaiements::ParametreAbsent(cle.to_owned()))?;
    let tableau = valeur
        .as_array()
        .ok_or_else(|| ErreurPaiements::ValeurInconnue(format!("{cle} n'est pas une liste")))?;
    tableau
        .iter()
        .map(|v| {
            v.as_str()
                .map(str::to_owned)
                .ok_or_else(|| ErreurPaiements::ValeurInconnue(format!("{cle} : élément non textuel")))
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn config_saine() -> ConfigPaiements {
        ConfigPaiements {
            zone: Uuid::now_v7(),
            devise: "XOF".to_owned(),
            session_duree_s: 900,
            reconciliation_avant_expiration_s: 60,
            creance_alerte_unites: 50_000,
            moyens_actifs: vec![],
        }
    }

    /// Les valeurs seedées passent la validation — un test qui échouerait ici
    /// signalerait que le seed et le code ne parlent pas de la même chose.
    #[test]
    fn les_valeurs_seedees_sont_coherentes() {
        assert!(config_saine().valider().is_ok());
    }

    /// Une session de durée nulle annulerait toute commande à sa naissance.
    #[test]
    fn une_duree_de_session_nulle_est_refusee() {
        let mut c = config_saine();
        c.session_duree_s = 0;
        assert!(c.valider().is_err());
        c.session_duree_s = -1;
        assert!(c.valider().is_err());
    }

    /// Une fenêtre de réconciliation plus longue que la session ne se
    /// déclencherait jamais : chaque webhook perdu deviendrait un litige.
    #[test]
    fn une_reconciliation_plus_longue_que_la_session_est_refusee() {
        let mut c = config_saine();
        c.reconciliation_avant_expiration_s = 901;
        assert!(c.valider().is_err());
        c.reconciliation_avant_expiration_s = 900;
        assert!(c.valider().is_ok(), "l'égalité reste acceptable");
    }

    /// FR-011 — le coupe-circuit vide laisse TOUT passer. C'est le cas nominal,
    /// et le test existe pour qu'une inversion de condition se voie.
    #[test]
    fn le_coupe_circuit_vide_laisse_tout_passer() {
        let c = config_saine();
        // Les libellés viennent de `MoyenPaiement::PROPOSABLES` et non de
        // chaînes écrites ici : une seule source, et le contrôle de frontière
        // (T079) n'a pas à distinguer un test d'un routage.
        for moyen in crate::modele::MoyenPaiement::PROPOSABLES {
            assert!(
                c.moyen_actif(moyen.comme_str()),
                "{} doit rester proposé",
                moyen.comme_str(),
            );
        }
    }

    /// Armé, il ne laisse passer que ce qu'il nomme.
    #[test]
    fn le_coupe_circuit_arme_ne_laisse_que_ce_qu_il_nomme() {
        use crate::modele::MoyenPaiement;
        let mut c = config_saine();
        let laisse = MoyenPaiement::PROPOSABLES[0];
        let coupe = MoyenPaiement::PROPOSABLES[1];
        c.moyens_actifs = vec![laisse.comme_str().to_owned()];
        assert!(c.moyen_actif(laisse.comme_str()));
        assert!(!c.moyen_actif(coupe.comme_str()));
    }
}
