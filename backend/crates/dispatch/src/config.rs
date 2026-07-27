//! Les 18 paramètres de zone du pipeline, et les **deux gardes** qui refusent
//! une configuration incohérente au CHARGEMENT (data-model §4, SC-005).
//!
//! Constitution I : aucun de ces nombres n'existe en dur dans le code. Une clé
//! absente est une **erreur de configuration**, jamais un défaut silencieux
//! (patron `parametre_i64` du cycle 008) — un rayon qui vaudrait 0 par accident
//! n'éliminerait pas un coursier, il les éliminerait tous, en silence.
//!
//! Trois paramètres **existants** sont réutilisés et jamais redéclarés :
//! `suivi.position_periode_s`, `commande.escalade_attente_coursier_s` et
//! `transport.actifs`.
//!
//! **Pourquoi refuser au chargement plutôt qu'au moment d'agir.** Les deux
//! incohérences que ce module attrape — un verrou plus court que le compte à
//! rebours, une somme de poids ≠ 100 — ne produisent pas d'erreur : elles
//! produisent un dispatch **bancal**, qui offre deux fois la même course ou
//! classe sur une échelle faussée. Un dispatch bancal se remarque des semaines
//! plus tard ; un refus de configuration se remarque tout de suite.

use serde::Deserialize;
use uuid::Uuid;
use zones::ConfigurationZones;

use crate::modele::ErreurDispatch;

/// Clés des paramètres — le seul endroit où ces chaînes sont écrites.
pub mod cles {
    /// Durée de vie d'une inscription au pool (secondes).
    pub const POOL_TTL_S: &str = "dispatch.pool_ttl_s";
    /// Compte à rebours d'une offre (secondes).
    pub const TIMER_OFFRE_S: &str = "dispatch.timer_offre_s";
    /// Durée de l'exclusivité — **doit** rester > [`TIMER_OFFRE_S`].
    pub const VERROU_OFFRE_S: &str = "dispatch.verrou_offre_s";
    /// Non-réponses franches par jour (ni pénalité, ni effet sur le taux).
    pub const TIMEOUTS_FRANCS_PAR_JOUR: &str = "dispatch.timeouts_francs_par_jour";
    /// Fenêtre de mesure du taux d'acceptation (jours).
    pub const ACCEPTATION_FENETRE_JOURS: &str = "dispatch.acceptation_fenetre_jours";
    /// Valeur neutre d'une composante en millièmes (donnée absente).
    pub const NOTE_COMPOSANTE_NEUTRE: &str = "dispatch.note_composante_neutre_millimes";
    /// Rapprochement minimal qui compte comme un mouvement (mètres).
    pub const REASSIGNATION_DEPLACEMENT_MIN_M: &str = "dispatch.reassignation_deplacement_min_m";
    /// Rayon d'éligibilité, mesuré en distance ROUTIÈRE (mètres).
    pub const RAYON_M: &str = "dispatch.rayon_m";
    /// Grille des plafonds d'avance par note (tableau JSON — un seul paramètre).
    pub const GRILLE_AVANCE_PAR_NOTE: &str = "dispatch.grille_avance_par_note";
    /// Poids de la proximité (centièmes).
    pub const POIDS_PROXIMITE: &str = "dispatch.poids_proximite";
    /// Poids de l'inactivité (centièmes).
    pub const POIDS_INACTIVITE: &str = "dispatch.poids_inactivite";
    /// Poids de la note (centièmes).
    pub const POIDS_NOTE: &str = "dispatch.poids_note";
    /// Poids du taux d'acceptation (centièmes).
    pub const POIDS_ACCEPTATION: &str = "dispatch.poids_acceptation";
    /// Inactivité au-delà de laquelle la composante est à son maximum.
    pub const INACTIVITE_PLAFOND_S: &str = "dispatch.inactivite_plafond_s";
    /// Nombre de candidats sollicités avant bascule en broadcast.
    pub const BROADCAST_APRES_CANDIDATS: &str = "dispatch.broadcast_apres_candidats";
    /// Délai depuis le début du pipeline avant bascule en broadcast (secondes).
    pub const BROADCAST_APRES_S: &str = "dispatch.broadcast_apres_s";
    /// Fenêtre sans rapprochement au-delà de laquelle la course est reprise.
    pub const REASSIGNATION_SANS_MOUVEMENT_S: &str = "dispatch.reassignation_sans_mouvement_s";
    /// Marge après la préparation annoncée avant reprise « sans scan ».
    pub const REASSIGNATION_SANS_SCAN_MARGE_S: &str = "dispatch.reassignation_sans_scan_marge_s";

    // ── RÉUTILISÉS — propriétaires : cycles 008 et 002 ────────────────────
    /// Période de publication de position (cycle 008) — `pool_ttl_s` en dérive.
    pub const POSITION_PERIODE_S: &str = "suivi.position_periode_s";
    /// Seuil d'escalade d'une commande non assignée (cycle 008, research R14).
    pub const ESCALADE_ATTENTE_S: &str = "commande.escalade_attente_coursier_s";

    /// Les 18 clés créées par ce cycle — l'inventaire de SC-008.
    pub const TOUTES: [&str; 18] = [
        POOL_TTL_S,
        TIMER_OFFRE_S,
        VERROU_OFFRE_S,
        TIMEOUTS_FRANCS_PAR_JOUR,
        ACCEPTATION_FENETRE_JOURS,
        NOTE_COMPOSANTE_NEUTRE,
        REASSIGNATION_DEPLACEMENT_MIN_M,
        RAYON_M,
        GRILLE_AVANCE_PAR_NOTE,
        POIDS_PROXIMITE,
        POIDS_INACTIVITE,
        POIDS_NOTE,
        POIDS_ACCEPTATION,
        INACTIVITE_PLAFOND_S,
        BROADCAST_APRES_CANDIDATS,
        BROADCAST_APRES_S,
        REASSIGNATION_SANS_MOUVEMENT_S,
        REASSIGNATION_SANS_SCAN_MARGE_S,
    ];
}

/// Un palier de la grille des plafonds d'avance (FR-023).
///
/// `note_max_centiemes = None` = palier haut (aucune borne supérieure).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Deserialize)]
pub struct PalierAvance {
    /// Borne supérieure de note (centièmes), incluse. `None` = palier haut.
    pub note_max_centiemes: Option<i32>,
    /// Plafond d'avance de ce palier (unités mineures).
    pub plafond_unites: i64,
}

/// Où se situe un palier dans la grille — ce que Yao voit sur K1.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum RangPalier {
    /// Premier palier — celui d'un coursier sans note (research R7).
    Entree,
    /// Palier ni premier ni dernier.
    Intermediaire,
    /// Dernier palier — plafond maximal de la zone.
    Haut,
}

impl RangPalier {
    /// Clé i18n du palier (contrat §1.1 : `palier_note_cle`).
    pub fn cle_i18n(self) -> &'static str {
        match self {
            RangPalier::Entree => "dispatch.palier.entree",
            RangPalier::Intermediaire => "dispatch.palier.intermediaire",
            RangPalier::Haut => "dispatch.palier.haut",
        }
    }
}

/// La grille des plafonds d'avance, résolue pour une zone.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct GrilleAvance {
    /// Paliers dans l'ordre de la configuration (note croissante).
    pub paliers: Vec<PalierAvance>,
}

impl GrilleAvance {
    /// Palier applicable à une note, et son rang dans la grille.
    ///
    /// Une note **absente** rend le palier d'ENTRÉE : c'est une exposition
    /// financière, et un inconnu commence bas (research R7, cadrage §7.5).
    pub fn palier(&self, note_centiemes: Option<i32>) -> (PalierAvance, RangPalier) {
        let dernier = self.paliers.len().saturating_sub(1);
        let index = match note_centiemes {
            None => 0,
            Some(note) => self
                .paliers
                .iter()
                .position(|p| p.note_max_centiemes.is_none_or(|max| note <= max))
                .unwrap_or(dernier),
        };
        let rang = if index == 0 {
            RangPalier::Entree
        } else if index == dernier {
            RangPalier::Haut
        } else {
            RangPalier::Intermediaire
        };
        (self.paliers[index], rang)
    }

    /// Plafond du palier le plus haut — l'exposition maximale de la zone.
    pub fn plafond_max(&self) -> i64 {
        self.paliers
            .iter()
            .map(|p| p.plafond_unites)
            .max()
            .unwrap_or(0)
    }
}

/// Les quatre poids du classement, en centièmes (FR-034).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Poids {
    /// Poids de la proximité.
    pub proximite: i32,
    /// Poids de l'inactivité.
    pub inactivite: i32,
    /// Poids de la note.
    pub note: i32,
    /// Poids du taux d'acceptation.
    pub acceptation: i32,
}

impl Poids {
    /// Somme des quatre poids — **doit** valoir 100.
    pub fn somme(self) -> i32 {
        self.proximite + self.inactivite + self.note + self.acceptation
    }
}

/// Toute la configuration de dispatch d'une zone, chargée en une fois.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ConfigDispatch {
    /// Zone résolue.
    pub zone: Uuid,
    /// Devise ISO 4217 de la zone (jamais écrite en dur).
    pub devise: String,
    /// Durée de vie d'une inscription au pool.
    pub pool_ttl_s: i64,
    /// Période de publication attendue de l'app (paramètre du cycle 008).
    pub position_periode_s: i64,
    /// Compte à rebours d'une offre.
    pub timer_offre_s: i64,
    /// Durée de l'exclusivité — toujours > `timer_offre_s`.
    pub verrou_offre_s: i64,
    /// Non-réponses franches par jour.
    pub timeouts_francs_par_jour: i64,
    /// Fenêtre de mesure du taux d'acceptation, en jours.
    pub acceptation_fenetre_jours: i64,
    /// Valeur neutre d'une composante, en millièmes.
    pub note_composante_neutre_millimes: i32,
    /// Rayon d'éligibilité, en mètres routiers.
    pub rayon_m: i64,
    /// Grille des plafonds d'avance par note.
    pub grille_avance: GrilleAvance,
    /// Les quatre poids du classement.
    pub poids: Poids,
    /// Inactivité au-delà de laquelle la composante est maximale.
    pub inactivite_plafond_s: i64,
    /// Candidats sollicités avant bascule en broadcast.
    pub broadcast_apres_candidats: i64,
    /// Délai avant bascule en broadcast.
    pub broadcast_apres_s: i64,
    /// Seuil d'escalade d'une commande non assignée (paramètre du cycle 008).
    pub escalade_attente_s: i64,
    /// Rapprochement minimal comptant comme un mouvement.
    pub reassignation_deplacement_min_m: i64,
    /// Fenêtre sans rapprochement avant reprise.
    pub reassignation_sans_mouvement_s: i64,
    /// Marge après préparation annoncée avant reprise « sans scan ».
    pub reassignation_sans_scan_marge_s: i64,
}

impl ConfigDispatch {
    /// Charge et **valide** la configuration d'une zone.
    ///
    /// Deux gardes, toutes deux à ce seul endroit :
    ///
    /// 1. `verrou_offre_s > timer_offre_s` (SC-005) — sinon l'exclusivité
    ///    expire pendant que le coursier décide encore, et un second coursier
    ///    peut recevoir la même course ;
    /// 2. somme des quatre poids = 100 — sinon le score n'est plus sur l'échelle
    ///    des composantes et le classement devient incomparable d'une zone à
    ///    l'autre.
    pub async fn charger(zones: &dyn ConfigurationZones, zone: Uuid) -> Result<Self, ErreurDispatch> {
        let devise = zones.devise(zone).await?;
        let grille_avance = charger_grille(zones, zone).await?;
        let poids = Poids {
            proximite: entier(zones, zone, cles::POIDS_PROXIMITE).await? as i32,
            inactivite: entier(zones, zone, cles::POIDS_INACTIVITE).await? as i32,
            note: entier(zones, zone, cles::POIDS_NOTE).await? as i32,
            acceptation: entier(zones, zone, cles::POIDS_ACCEPTATION).await? as i32,
        };
        let config = Self {
            zone,
            devise: devise.code,
            pool_ttl_s: entier(zones, zone, cles::POOL_TTL_S).await?,
            position_periode_s: entier(zones, zone, cles::POSITION_PERIODE_S).await?,
            timer_offre_s: entier(zones, zone, cles::TIMER_OFFRE_S).await?,
            verrou_offre_s: entier(zones, zone, cles::VERROU_OFFRE_S).await?,
            timeouts_francs_par_jour: entier(zones, zone, cles::TIMEOUTS_FRANCS_PAR_JOUR).await?,
            acceptation_fenetre_jours: entier(zones, zone, cles::ACCEPTATION_FENETRE_JOURS).await?,
            note_composante_neutre_millimes: entier(zones, zone, cles::NOTE_COMPOSANTE_NEUTRE)
                .await? as i32,
            rayon_m: entier(zones, zone, cles::RAYON_M).await?,
            grille_avance,
            poids,
            inactivite_plafond_s: entier(zones, zone, cles::INACTIVITE_PLAFOND_S).await?,
            broadcast_apres_candidats: entier(zones, zone, cles::BROADCAST_APRES_CANDIDATS).await?,
            broadcast_apres_s: entier(zones, zone, cles::BROADCAST_APRES_S).await?,
            escalade_attente_s: entier(zones, zone, cles::ESCALADE_ATTENTE_S).await?,
            reassignation_deplacement_min_m: entier(
                zones,
                zone,
                cles::REASSIGNATION_DEPLACEMENT_MIN_M,
            )
            .await?,
            reassignation_sans_mouvement_s: entier(zones, zone, cles::REASSIGNATION_SANS_MOUVEMENT_S)
                .await?,
            reassignation_sans_scan_marge_s: entier(
                zones,
                zone,
                cles::REASSIGNATION_SANS_SCAN_MARGE_S,
            )
            .await?,
        };
        config.valider()?;
        Ok(config)
    }

    /// Les deux gardes, isolées pour être testables sans base.
    pub fn valider(&self) -> Result<(), ErreurDispatch> {
        if self.verrou_offre_s <= self.timer_offre_s {
            return Err(ErreurDispatch::ConfigurationInvalide(format!(
                "{} ({} s) doit être strictement supérieur à {} ({} s) : \
                 sinon l'exclusivité expire pendant que le coursier décide encore",
                cles::VERROU_OFFRE_S,
                self.verrou_offre_s,
                cles::TIMER_OFFRE_S,
                self.timer_offre_s,
            )));
        }
        let somme = self.poids.somme();
        if somme != 100 {
            return Err(ErreurDispatch::ConfigurationInvalide(format!(
                "la somme des quatre poids de classement vaut {somme}, attendu 100 \
                 (proximité {} + inactivité {} + note {} + acceptation {})",
                self.poids.proximite,
                self.poids.inactivite,
                self.poids.note,
                self.poids.acceptation,
            )));
        }
        Ok(())
    }

    /// Durée de vie du pool, en [`std::time::Duration`].
    pub fn pool_ttl(&self) -> std::time::Duration {
        std::time::Duration::from_secs(self.pool_ttl_s.max(0) as u64)
    }

    /// Durée de l'exclusivité, en [`std::time::Duration`].
    pub fn verrou_ttl(&self) -> std::time::Duration {
        std::time::Duration::from_secs(self.verrou_offre_s.max(0) as u64)
    }
}

/// Paramètre de zone entier, résolu par héritage.
///
/// Une clé absente est une **erreur de configuration**, jamais un défaut : un
/// seuil qui vaudrait 0 par accident changerait tout le comportement en silence.
async fn entier(
    zones: &dyn ConfigurationZones,
    zone: Uuid,
    cle: &str,
) -> Result<i64, ErreurDispatch> {
    zones
        .parametre(zone, cle)
        .await?
        .and_then(|v| v.as_i64())
        .ok_or_else(|| ErreurDispatch::ParametreAbsent(cle.to_owned()))
}

/// Charge la grille des plafonds d'avance — **un seul** paramètre JSON, comme
/// `transport.actifs` (research R7) : un seul point d'édition pour ADM-04.
async fn charger_grille(
    zones: &dyn ConfigurationZones,
    zone: Uuid,
) -> Result<GrilleAvance, ErreurDispatch> {
    let brut = zones
        .parametre(zone, cles::GRILLE_AVANCE_PAR_NOTE)
        .await?
        .ok_or_else(|| ErreurDispatch::ParametreAbsent(cles::GRILLE_AVANCE_PAR_NOTE.to_owned()))?;
    let paliers: Vec<PalierAvance> = serde_json::from_value(brut).map_err(|e| {
        ErreurDispatch::ConfigurationInvalide(format!(
            "{} illisible : {e}",
            cles::GRILLE_AVANCE_PAR_NOTE
        ))
    })?;
    if paliers.is_empty() {
        return Err(ErreurDispatch::ConfigurationInvalide(format!(
            "{} est vide : aucun coursier ne pourrait rien avancer",
            cles::GRILLE_AVANCE_PAR_NOTE
        )));
    }
    Ok(GrilleAvance { paliers })
}

#[cfg(test)]
mod tests {
    use super::*;

    fn config_saine() -> ConfigDispatch {
        ConfigDispatch {
            zone: Uuid::now_v7(),
            devise: "XOF".to_owned(),
            pool_ttl_s: 90,
            position_periode_s: 30,
            timer_offre_s: 40,
            verrou_offre_s: 45,
            timeouts_francs_par_jour: 3,
            acceptation_fenetre_jours: 7,
            note_composante_neutre_millimes: 500,
            rayon_m: 4_000,
            grille_avance: grille(),
            poids: Poids {
                proximite: 40,
                inactivite: 30,
                note: 20,
                acceptation: 10,
            },
            inactivite_plafond_s: 1_800,
            broadcast_apres_candidats: 3,
            broadcast_apres_s: 120,
            escalade_attente_s: 300,
            reassignation_deplacement_min_m: 150,
            reassignation_sans_mouvement_s: 300,
            reassignation_sans_scan_marge_s: 600,
        }
    }

    fn grille() -> GrilleAvance {
        GrilleAvance {
            paliers: vec![
                PalierAvance {
                    note_max_centiemes: Some(400),
                    plafond_unites: 5_000,
                },
                PalierAvance {
                    note_max_centiemes: Some(450),
                    plafond_unites: 10_000,
                },
                PalierAvance {
                    note_max_centiemes: None,
                    plafond_unites: 15_000,
                },
            ],
        }
    }

    /// SC-005 — un verrou qui n'excède pas le compte à rebours est REFUSÉ au
    /// chargement. À la seconde 41, l'exclusivité serait tombée alors que le
    /// coursier a encore la main : un second coursier recevrait la même course.
    #[test]
    fn un_verrou_plus_court_que_le_timer_est_refuse() {
        let mut config = config_saine();
        config.verrou_offre_s = 30;
        let e = config.valider().unwrap_err();
        assert!(matches!(e, ErreurDispatch::ConfigurationInvalide(_)));
        assert!(e.to_string().contains("dispatch.verrou_offre_s"));

        // L'ÉGALITÉ est refusée aussi : à la seconde exacte, la course des deux
        // horloges n'est pas décidable.
        config.verrou_offre_s = 40;
        assert!(config.valider().is_err());

        config.verrou_offre_s = 41;
        assert!(config.valider().is_ok());
    }

    /// Une somme de poids ≠ 100 sort le score de l'échelle des composantes :
    /// les classements de deux zones ne seraient plus comparables.
    #[test]
    fn une_somme_de_poids_differente_de_cent_est_refusee() {
        let mut config = config_saine();
        config.poids.note = 25;
        let e = config.valider().unwrap_err();
        assert!(e.to_string().contains("105"), "{e}");

        config.poids.note = 20;
        assert!(config.valider().is_ok());
    }

    /// Research R7 — une note ABSENTE rend le palier d'entrée : un inconnu
    /// commence bas, parce que le plafond est une exposition financière.
    #[test]
    fn une_note_absente_rend_le_palier_d_entree() {
        let (palier, rang) = grille().palier(None);
        assert_eq!(palier.plafond_unites, 5_000);
        assert_eq!(rang, RangPalier::Entree);
        assert_eq!(rang.cle_i18n(), "dispatch.palier.entree");
    }

    /// Les bornes de la grille sont INCLUSES, et le dernier palier n'a pas de
    /// borne haute.
    #[test]
    fn les_paliers_se_lisent_bornes_incluses() {
        let g = grille();
        assert_eq!(g.palier(Some(400)).0.plafond_unites, 5_000);
        assert_eq!(g.palier(Some(401)).0.plafond_unites, 10_000);
        assert_eq!(g.palier(Some(450)).0.plafond_unites, 10_000);
        assert_eq!(g.palier(Some(451)), (g.paliers[2], RangPalier::Haut));
        assert_eq!(g.palier(Some(500)).0.plafond_unites, 15_000);
        assert_eq!(g.plafond_max(), 15_000);
        assert_eq!(g.palier(Some(420)).1, RangPalier::Intermediaire);
    }

    /// La grille est lue depuis la MÊME forme JSON que celle seedée : un
    /// changement de format se voit ici, pas en production.
    #[test]
    fn la_grille_se_lit_depuis_le_json_seede() {
        let brut = serde_json::json!([
            {"note_max_centiemes": 400, "plafond_unites": 5000},
            {"note_max_centiemes": 450, "plafond_unites": 10000},
            {"note_max_centiemes": null, "plafond_unites": 15000}
        ]);
        let paliers: Vec<PalierAvance> = serde_json::from_value(brut).unwrap();
        assert_eq!(GrilleAvance { paliers }, grille());
    }

    /// L'inventaire de SC-008 : 18 clés créées, sans doublon, toutes préfixées
    /// `dispatch.` — les trois clés réutilisées n'y sont pas, parce qu'elles
    /// appartiennent à d'autres cycles.
    #[test]
    fn l_inventaire_compte_dix_huit_cles_sans_doublon() {
        let uniques: std::collections::HashSet<_> = cles::TOUTES.iter().collect();
        assert_eq!(uniques.len(), 18);
        assert!(cles::TOUTES.iter().all(|c| c.starts_with("dispatch.")));
        assert!(!cles::TOUTES.contains(&cles::POSITION_PERIODE_S));
        assert!(!cles::TOUTES.contains(&cles::ESCALADE_ATTENTE_S));
    }
}
