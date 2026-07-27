//! Plafond d'avance du jour : ce que Yao déclare, et ce qui s'applique
//! réellement (DSP-01, FR-010, FR-011, FR-023).
//!
//! **Deux nombres, jamais un.** Le plafond DÉCLARÉ est ce que Yao a en poche ce
//! matin ; le plafond RETENU est `min(déclaré, palier de la grille par note)`.
//! L'écran K1 montre les deux et dit **lequel** s'applique — un coursier à qui
//! l'on refuse une course sans lui dire que son palier le limite ne peut rien y
//! faire, et croira à un bug.
//!
//! **Jamais de report tacite** (FR-011). La clé primaire de
//! `dispatch.plafond_jour` porte la DATE : au nouveau jour, la déclaration
//! d'hier n'existe plus et l'app la redemande. Reporter silencieusement le
//! plafond de la veille exposerait un coursier qui n'a plus l'argent.
//!
//! **Le plafond retenu n'est PAS stocké** : il se recalcule à chaque lecture,
//! parce que la note peut changer entre deux offres — et parce qu'une valeur
//! dérivée stockée est une seconde vérité à resynchroniser.

use chrono::{DateTime, NaiveDate, Utc};
use serde_json::json;
use socle::{ecrire_evenement, NouvelEvenement};
use uuid::Uuid;

use crate::config::ConfigDispatch;
use crate::depot::PgDispatch;
use crate::modele::ErreurDispatch;

/// D'où vient le plafond qui s'applique — ce que K1 affiche.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SourcePlafond {
    /// C'est le palier de la grille (par note) qui limite (FR-023).
    GrilleNote,
    /// C'est la déclaration de Yao qui s'applique — elle est plus basse.
    Declaration,
}

impl SourcePlafond {
    /// Représentation textuelle (contrat §1.1, payload d'événement).
    pub fn comme_str(self) -> &'static str {
        match self {
            SourcePlafond::GrilleNote => "grille_note",
            SourcePlafond::Declaration => "declaration",
        }
    }
}

/// Le plafond d'avance d'un coursier pour un jour donné, résolu.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PlafondDuJour {
    /// Jour civil concerné.
    pub jour: NaiveDate,
    /// Ce que Yao a déclaré, ou `None` s'il n'a rien déclaré aujourd'hui.
    pub declare_unites: Option<i64>,
    /// Ce qui s'applique : `min(déclaré, palier)`. Sans déclaration, c'est le
    /// palier — mais aucune offre ne part avant la mise en ligne, qui exige la
    /// déclaration.
    pub retenu_unites: i64,
    /// Lequel des deux s'applique.
    pub source: SourcePlafond,
    /// Palier de la grille appliqué, et sa clé i18n.
    pub palier_unites: i64,
    /// Clé i18n du palier (`dispatch.palier.entree`…).
    pub palier_cle: &'static str,
    /// Note utilisée, ou `None` tant qu'AVI n'existe pas (research R7).
    pub note_centiemes: Option<i32>,
    /// Devise ISO 4217 de la zone.
    pub devise: String,
}

impl PgDispatch {
    /// Déclare le plafond d'avance du jour et rend ce qui s'applique.
    ///
    /// Rejouable : re-déclarer le même jour écrase la valeur (un coursier peut
    /// corriger son montant tant qu'il n'est pas en ligne). L'événement
    /// `coursier.plafond_jour_declare` accompagne l'écriture dans la MÊME
    /// transaction (constitution VI).
    pub async fn declarer_plafond_jour(
        &self,
        coursier: Uuid,
        config: &ConfigDispatch,
        plafond_unites: i64,
        horodatage: DateTime<Utc>,
    ) -> Result<PlafondDuJour, ErreurDispatch> {
        let jour = horodatage.date_naive();
        let plafond_unites = plafond_unites.max(0);

        let mut tx = self.pool.begin().await?;
        sqlx::query!(
            "INSERT INTO dispatch.plafond_jour (coursier_id, jour, plafond_unites, devise)
             VALUES ($1, $2, $3, $4)
             ON CONFLICT (coursier_id, jour)
             DO UPDATE SET plafond_unites = EXCLUDED.plafond_unites,
                           devise = EXCLUDED.devise,
                           declare_le = now()",
            coursier,
            jour,
            plafond_unites,
            config.devise,
        )
        .execute(&mut *tx)
        .await?;
        // ⚠ La bascule en ligne n'est PAS écrite ici : déclarer ce qu'on peut
        // avancer et décider de travailler sont deux gestes, et K1 permet
        // d'ajuster le montant avant de basculer.

        let note = self.notes.note_centiemes(coursier).await?;
        let resolu = resoudre(config, jour, Some(plafond_unites), note);

        ecrire_evenement(
            &mut tx,
            NouvelEvenement {
                type_evenement: "coursier.plafond_jour_declare",
                entite_type: "coursier",
                entite_id: coursier,
                payload: json!({
                    "zone": config.zone,
                    "plafond_declare_unites": plafond_unites,
                    "plafond_retenu_unites": resolu.retenu_unites,
                    "devise": resolu.devise,
                    "palier_note": resolu.palier_cle,
                }),
                survenu_le: horodatage,
            },
        )
        .await?;
        tx.commit().await?;

        Ok(resolu)
    }

    /// Pose l'INTENTION d'être en ligne pour le jour civil courant.
    ///
    /// Persistée en Postgres et non en Redis : une intention perdue au vidage du
    /// cache ferait ignorer toutes les publications suivantes, et le pool ne se
    /// reconstituerait jamais (SC-004). Rend `true` si l'état a effectivement
    /// changé — ce qui évite d'émettre un événement au second tap.
    pub async fn declarer_en_ligne(
        &self,
        coursier: Uuid,
        config: &ConfigDispatch,
        en_ligne: bool,
        horodatage: DateTime<Utc>,
    ) -> Result<bool, ErreurDispatch> {
        let jour = horodatage.date_naive();
        let avant = self.est_en_ligne(coursier, horodatage).await?;
        sqlx::query!(
            "INSERT INTO dispatch.plafond_jour
                 (coursier_id, jour, plafond_unites, devise, en_ligne, bascule_le)
             VALUES ($1, $2, 0, $3, $4, $5)
             ON CONFLICT (coursier_id, jour)
             DO UPDATE SET en_ligne = EXCLUDED.en_ligne, bascule_le = EXCLUDED.bascule_le",
            coursier,
            jour,
            config.devise,
            en_ligne,
            horodatage,
        )
        .execute(&self.pool)
        .await?;
        Ok(avant != en_ligne)
    }

    /// Vrai si le coursier s'est déclaré en ligne **aujourd'hui**.
    ///
    /// Jamais reporté d'un jour sur l'autre (FR-011) : au nouveau jour, il n'y a
    /// pas de ligne, donc pas d'intention, et l'app redemande tout.
    pub async fn est_en_ligne(
        &self,
        coursier: Uuid,
        horodatage: DateTime<Utc>,
    ) -> Result<bool, ErreurDispatch> {
        Ok(sqlx::query_scalar!(
            "SELECT en_ligne FROM dispatch.plafond_jour
             WHERE coursier_id = $1 AND jour = $2",
            coursier,
            horodatage.date_naive(),
        )
        .fetch_optional(&self.pool)
        .await?
        .unwrap_or(false))
    }

    /// Plafond du jour tel qu'il s'applique **maintenant**.
    ///
    /// Un jour sans déclaration rend `declare_unites: None` : l'app le voit et
    /// redemande le montant (FR-011). C'est aussi ce que la mise en ligne
    /// vérifie — un plafond non déclaré n'est pas un plafond nul.
    pub async fn plafond_du_jour(
        &self,
        coursier: Uuid,
        config: &ConfigDispatch,
        horodatage: DateTime<Utc>,
    ) -> Result<PlafondDuJour, ErreurDispatch> {
        let jour = horodatage.date_naive();
        let declare = sqlx::query_scalar!(
            "SELECT plafond_unites FROM dispatch.plafond_jour
             WHERE coursier_id = $1 AND jour = $2",
            coursier,
            jour,
        )
        .fetch_optional(&self.pool)
        .await?;
        let note = self.notes.note_centiemes(coursier).await?;
        Ok(resoudre(config, jour, declare, note))
    }
}

/// Résolution PURE — testable sans base, et c'est là que vit la règle.
pub fn resoudre(
    config: &ConfigDispatch,
    jour: NaiveDate,
    declare_unites: Option<i64>,
    note_centiemes: Option<i32>,
) -> PlafondDuJour {
    let (palier, rang) = config.grille_avance.palier(note_centiemes);
    // Sans déclaration, le palier fait foi pour l'affichage — mais rien ne part
    // avant la mise en ligne, qui exige la déclaration.
    let (retenu, source) = match declare_unites {
        Some(declare) if declare < palier.plafond_unites => (declare, SourcePlafond::Declaration),
        _ => (palier.plafond_unites, SourcePlafond::GrilleNote),
    };
    PlafondDuJour {
        jour,
        declare_unites,
        retenu_unites: retenu,
        source,
        palier_unites: palier.plafond_unites,
        palier_cle: rang.cle_i18n(),
        note_centiemes,
        devise: config.devise.clone(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::config::{GrilleAvance, PalierAvance, Poids};

    fn config() -> ConfigDispatch {
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
            grille_avance: GrilleAvance {
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
            },
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

    fn jour() -> NaiveDate {
        NaiveDate::from_ymd_opt(2026, 7, 27).unwrap()
    }

    /// **Le cas qui compte** (FR-010) : Yao déclare 15 000, mais son palier
    /// plafonne à 10 000 — c'est 10 000 qui décide, et l'écran doit le dire.
    #[test]
    fn le_plus_bas_des_deux_decide_et_la_source_le_dit() {
        let config = config();
        let r = resoudre(&config, jour(), Some(15_000), Some(450));
        assert_eq!(r.retenu_unites, 10_000);
        assert_eq!(r.source, SourcePlafond::GrilleNote);
        assert_eq!(r.palier_unites, 10_000);
        assert_eq!(r.palier_cle, "dispatch.palier.intermediaire");

        // Et l'inverse : une déclaration prudente s'applique telle quelle.
        let r = resoudre(&config, jour(), Some(3_000), Some(450));
        assert_eq!(r.retenu_unites, 3_000);
        assert_eq!(r.source, SourcePlafond::Declaration);
        assert_eq!(
            r.palier_unites, 10_000,
            "le palier reste visible : Yao sait de combien il dispose s'il déclare plus",
        );
    }

    /// Research R7 — sans note (AVI non construit), c'est le palier d'ENTRÉE.
    /// Un inconnu commence bas : le plafond est une exposition financière.
    #[test]
    fn sans_note_le_palier_d_entree_s_applique() {
        let r = resoudre(&config(), jour(), Some(15_000), None);
        assert_eq!(r.retenu_unites, 5_000);
        assert_eq!(r.palier_cle, "dispatch.palier.entree");
        assert_eq!(r.note_centiemes, None);
    }

    /// FR-011 — aucun report tacite : un jour sans déclaration rend `None`, et
    /// l'app redemande. Zéro ne serait pas la même chose : « je n'ai rien
    /// déclaré » n'est pas « je ne peux rien avancer ».
    #[test]
    fn un_jour_sans_declaration_se_distingue_d_un_plafond_nul() {
        let sans = resoudre(&config(), jour(), None, Some(450));
        assert_eq!(sans.declare_unites, None);

        let nul = resoudre(&config(), jour(), Some(0), Some(450));
        assert_eq!(nul.declare_unites, Some(0));
        assert_eq!(nul.retenu_unites, 0);
        assert_eq!(
            nul.source,
            SourcePlafond::Declaration,
            "déclarer zéro est une décision : Yao ne veut rien avancer aujourd'hui",
        );
    }

    /// L'égalité déclaré == palier n'est pas ambiguë : la grille l'emporte, ce
    /// qui garde `source` stable quand Yao déclare exactement son palier.
    #[test]
    fn a_egalite_la_grille_l_emporte() {
        let r = resoudre(&config(), jour(), Some(10_000), Some(450));
        assert_eq!(r.retenu_unites, 10_000);
        assert_eq!(r.source, SourcePlafond::GrilleNote);
    }

    /// Le palier HAUT est celui d'une bonne note — et il est nommé comme tel.
    #[test]
    fn une_bonne_note_ouvre_le_palier_haut() {
        let r = resoudre(&config(), jour(), Some(20_000), Some(490));
        assert_eq!(r.retenu_unites, 15_000);
        assert_eq!(r.palier_cle, "dispatch.palier.haut");
        assert_eq!(r.devise, "XOF");
    }
}
