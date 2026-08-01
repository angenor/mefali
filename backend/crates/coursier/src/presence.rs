//! Présence mesurée sur le lieu de livraison — la deuxième des trois preuves
//! (FR-056, FR-061, FR-064, research R8).
//!
//! Trois règles portent tout ce module, et chacune existe parce que son absence
//! produirait une preuve **fausse** plutôt qu'une erreur :
//!
//! 1. **Une distance, jamais une coordonnée.** L'app calcule elle-même son
//!    éloignement du point de livraison et n'envoie que le nombre de mètres,
//!    arrondi — patron `distance_scan_m` du cycle 006 (ARTCI). Le serveur ne
//!    stocke aucune position, donc n'en fuite aucune.
//! 2. **La durée se somme par intervalles, jamais par étendue.** Deux relevés
//!    espacés de dix minutes ne valent pas dix minutes de présence : tout
//!    intervalle supérieur au « trou » de la zone est ignoré. Sans cette règle,
//!    un aller-retour vaudrait une attente (R8).
//! 3. **Le serveur recalcule.** L'app n'envoie jamais de durée — elle envoie des
//!    échantillons. C'est le serveur qui compte, et c'est ce que FR-060 exige
//!    d'une preuve qui fonde une indemnisation.
//!
//! ⚠ Ce que ce module ne peut pas faire : vérifier la distance déclarée. Sans
//! coordonnée persistée (R8), le serveur n'a rien à recouper. Le garde-fou qui
//! reste est temporel — un appareil dont l'horloge **avance** sur celle du
//! serveur voit ses échantillons futurs écartés du calcul, parce que fabriquer
//! de la présence demande d'étirer les intervalles, et qu'étirer les intervalles
//! au-delà de la réception se voit.

use chrono::{DateTime, Utc};
use uuid::Uuid;

use crate::config::ConfigCoursier;
use crate::depot::PgCoursier;
use crate::modele::{ErreurCoursier, PreuvePresence};

/// Relevés acceptés dans un seul lot.
///
/// La file hors-ligne peut en avoir accumulé des heures ; 500 échantillons
/// couvrent largement une journée d'attente à la période d'échantillonnage la
/// plus fine. Au-delà, la demande est refusée plutôt que tronquée : une
/// troncature silencieuse ferait disparaître de la preuve sans le dire.
pub const LOT_MAX: usize = 500;

/// Clés i18n des motifs de non-progression affichés sur K4-1e (FR-058).
pub mod motifs {
    /// Aucun échantillon reçu — GPS coupé, ou l'app vient d'arriver.
    pub const AUCUN_RELEVE: &str = "coursier.preuve.presence_aucun_releve";
    /// Des échantillons arrivent, la durée exigée n'est pas atteinte.
    pub const EN_COURS: &str = "coursier.preuve.presence_en_cours";
    /// Des échantillons arrivent, mais tous hors du rayon.
    pub const HORS_RAYON: &str = "coursier.preuve.presence_hors_rayon";
}

/// Un échantillon de présence tel que l'app le déclare.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ReleveDePresence {
    /// Clé d'idempotence du relevé (UUIDv7 client, constitution V).
    pub uuid_client: Uuid,
    /// Éloignement du point de livraison, en mètres **arrondis** (R8).
    pub distance_m: i64,
    /// Instant de l'échantillon sur l'appareil. C'est lui qui porte l'ordre
    /// vécu — le hors-ligne le rend indispensable — mais le serveur le confronte
    /// à sa propre horloge avant de le compter.
    pub releve_le_local: DateTime<Utc>,
}

/// Ce que le serveur rend après avoir enregistré un lot.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PresenceEnregistree {
    /// Relevés du lot **connus du serveur** après l'écriture.
    ///
    /// Volontairement « connus » et non « insérés » : un lot rejoué par la file
    /// rend le MÊME nombre, sinon l'app croirait avoir perdu ses échantillons au
    /// second passage (constitution V).
    pub retenus: i64,
    /// La preuve de présence, recalculée dans la foulée.
    pub presence: PreuvePresence,
}

/// Un échantillon tel que le **calcul** le voit : sa mesure, son heure vécue et
/// son heure de réception.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Echantillon {
    /// Éloignement déclaré (m).
    pub distance_m: i64,
    /// Horodatage de l'appareil.
    pub local: DateTime<Utc>,
    /// Horodatage **serveur** de réception — le seul que le serveur ait vu.
    pub serveur: DateTime<Utc>,
}

/// Durée de présence retenue, en secondes — **la** fonction de la preuve.
///
/// Sans I/O, pour être exerçable seule : c'est le genre de calcul où une
/// inégalité inversée ne se remarque qu'à la première contestation, des semaines
/// plus tard.
///
/// - un intervalle ne compte que si **ses deux extrémités** sont dans le rayon ;
///   sinon un aller-retour se compterait comme une attente ;
/// - un intervalle plus long que le trou de zone ne compte pas (R8) ;
/// - un échantillon dont l'heure locale **dépasse** sa réception serveur de plus
///   d'un trou est écarté : l'horloge de l'appareil avance, et une horloge qui
///   avance est exactement ce qui permettrait de fabriquer de la durée.
pub fn duree_presence(echantillons: &[Echantillon], config: &ConfigCoursier) -> i64 {
    let tolerance = chrono::Duration::seconds(config.preuve_presence_trou_max_s);
    let mut retenus: Vec<&Echantillon> = echantillons
        .iter()
        .filter(|e| e.local <= e.serveur + tolerance)
        .collect();
    retenus.sort_by_key(|e| e.local);

    retenus
        .windows(2)
        .filter(|paire| {
            paire[0].distance_m <= config.preuve_presence_rayon_m
                && paire[1].distance_m <= config.preuve_presence_rayon_m
        })
        .map(|paire| (paire[1].local - paire[0].local).num_seconds())
        .filter(|d| *d > 0 && *d <= config.preuve_presence_trou_max_s)
        .sum()
}

/// Compose la preuve à partir d'une durée mesurée et des échantillons vus.
///
/// Le motif est ce que K4-1e affiche à la place d'un compteur qui n'avance pas :
/// « en cours » n'a pas la même conduite à tenir que « trop loin » ou « pas de
/// position » (FR-058).
pub fn composer_preuve(
    secondes: i64,
    echantillons: &[Echantillon],
    config: &ConfigCoursier,
) -> PreuvePresence {
    let requis = config.preuve_presence_s;
    let ok = secondes >= requis;
    let motif_cle = if ok {
        None
    } else if echantillons.is_empty() {
        Some(motifs::AUCUN_RELEVE)
    } else if !echantillons
        .iter()
        .any(|e| e.distance_m <= config.preuve_presence_rayon_m)
    {
        Some(motifs::HORS_RAYON)
    } else {
        Some(motifs::EN_COURS)
    };
    PreuvePresence {
        secondes,
        requis,
        ok,
        motif_cle,
    }
}

impl PgCoursier {
    /// Enregistre un lot de relevés et rend la présence recalculée.
    ///
    /// Idempotent par `uuid_client` : la file peut rejouer le même lot autant de
    /// fois qu'elle veut, il ne crée qu'une ligne par échantillon.
    ///
    /// Aucun événement outbox : un échantillon n'est pas une transition d'état.
    /// C'est le **basculement** des trois preuves qui en émet un, et il est
    /// évalué par [`crate::preuves`].
    pub async fn enregistrer_presence(
        &self,
        coursier: Uuid,
        livraison: Uuid,
        lot: Vec<ReleveDePresence>,
    ) -> Result<PresenceEnregistree, ErreurCoursier> {
        self.exiger_proprietaire(livraison, coursier).await?;
        if lot.is_empty() {
            return Err(ErreurCoursier::DemandeInvalide("lot de relevés vide"));
        }
        if lot.len() > LOT_MAX {
            return Err(ErreurCoursier::DemandeInvalide(
                "lot de relevés trop grand — le tronquer ferait disparaître de la preuve",
            ));
        }
        if lot.iter().any(|r| r.distance_m < 0) {
            return Err(ErreurCoursier::DemandeInvalide("distance négative"));
        }
        // Une distance qui ne tient pas dans un `integer` n'est pas une mesure :
        // c'est un capteur en panne. La refuser ici évite une erreur SQL nue.
        if lot.iter().any(|r| r.distance_m > i64::from(i32::MAX)) {
            return Err(ErreurCoursier::DemandeInvalide("distance hors échelle"));
        }

        let ids: Vec<Uuid> = lot.iter().map(|_| Uuid::now_v7()).collect();
        let distances: Vec<i32> = lot.iter().map(|r| r.distance_m as i32).collect();
        let locaux: Vec<DateTime<Utc>> = lot.iter().map(|r| r.releve_le_local).collect();
        let uuids: Vec<Uuid> = lot.iter().map(|r| r.uuid_client).collect();

        sqlx::query!(
            r#"INSERT INTO coursier.releve_presence
                   (id, livraison_id, distance_m, releve_le_local, uuid_client)
               SELECT g.id, $2, g.distance_m, g.local, g.uuid_client
                 FROM UNNEST($1::uuid[], $3::int4[], $4::timestamptz[], $5::uuid[])
                      AS g(id, distance_m, local, uuid_client)
               ON CONFLICT (uuid_client) DO NOTHING"#,
            &ids,
            livraison,
            &distances,
            &locaux,
            &uuids,
        )
        .execute(&self.pool)
        .await?;

        // Compté APRÈS l'écriture, sur ce que la base détient vraiment : c'est
        // ce qui rend le rejeu identique au premier envoi.
        let retenus = sqlx::query_scalar!(
            r#"SELECT count(*) AS "n!" FROM coursier.releve_presence
               WHERE livraison_id = $1 AND uuid_client = ANY($2::uuid[])"#,
            livraison,
            &uuids,
        )
        .fetch_one(&self.pool)
        .await?;

        // Le lot vient peut-être de faire tomber la troisième preuve : c'est
        // l'évaluation qui émet `preuves_echec.reunies`, exactement une fois.
        let etat = self.evaluer_basculement(livraison).await?;
        Ok(PresenceEnregistree {
            retenus,
            presence: etat.presence,
        })
    }

    /// La preuve de présence d'une livraison, recalculée depuis les relevés.
    pub async fn presence_mesuree(
        &self,
        livraison: Uuid,
        config: &ConfigCoursier,
    ) -> Result<PreuvePresence, ErreurCoursier> {
        let echantillons = self.echantillons_de(livraison).await?;
        let secondes = duree_presence(&echantillons, config);
        Ok(composer_preuve(secondes, &echantillons, config))
    }

    /// Échantillons bruts d'une livraison, ordonnés par heure vécue.
    async fn echantillons_de(&self, livraison: Uuid) -> Result<Vec<Echantillon>, ErreurCoursier> {
        let lignes = sqlx::query!(
            r#"SELECT distance_m, releve_le_local, releve_le
                 FROM coursier.releve_presence
                WHERE livraison_id = $1
                ORDER BY releve_le_local"#,
            livraison,
        )
        .fetch_all(&self.pool)
        .await?;
        Ok(lignes
            .into_iter()
            .map(|l| Echantillon {
                distance_m: i64::from(l.distance_m),
                local: l.releve_le_local,
                serveur: l.releve_le,
            })
            .collect())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn config() -> ConfigCoursier {
        ConfigCoursier {
            zone: Uuid::now_v7(),
            devise: "XOF".to_owned(),
            preuve_appels_min: 2,
            preuve_appels_espacement_s: 180,
            preuve_presence_s: 600,
            preuve_presence_rayon_m: 100,
            preuve_presence_trou_max_s: 120,
            retention_photo_preuve_jours: 365,
            offre_interrogation_arriere_plan_s: 5,
            essais_code_livraison: 3,
        }
    }

    fn base() -> DateTime<Utc> {
        DateTime::parse_from_rfc3339("2026-07-28T15:00:00Z")
            .unwrap()
            .with_timezone(&Utc)
    }

    /// Échantillon reçu à l'heure — l'appareil et le serveur sont d'accord.
    fn e(secondes: i64, distance_m: i64) -> Echantillon {
        let t = base() + chrono::Duration::seconds(secondes);
        Echantillon {
            distance_m,
            local: t,
            serveur: t,
        }
    }

    /// Le cas nominal : un échantillon toutes les 30 s pendant 10 minutes.
    #[test]
    fn une_presence_continue_se_somme_intervalle_par_intervalle() {
        let echantillons: Vec<Echantillon> = (0..=20).map(|i| e(i * 30, 12)).collect();
        assert_eq!(duree_presence(&echantillons, &config()), 600);
        let preuve = composer_preuve(600, &echantillons, &config());
        assert!(preuve.ok);
        assert_eq!(preuve.motif_cle, None);
    }

    /// R8 — un aller-retour n'est pas une attente. Seuls les intervalles dont
    /// **les deux bouts** sont dans le rayon comptent : sans cette règle, Yao
    /// pourrait passer, s'éloigner dix minutes, revenir, et prouver une présence.
    #[test]
    fn un_aller_retour_ne_vaut_pas_une_presence() {
        let echantillons = vec![
            e(0, 10),   // sur place
            e(30, 10),  // + 30 s
            e(60, 800), // parti
            e(90, 900),
            e(120, 10), // revenu — l'intervalle 90→120 ne compte pas
            e(150, 10), // + 30 s
        ];
        assert_eq!(
            duree_presence(&echantillons, &config()),
            60,
            "seuls les deux segments réellement sur place comptent",
        );
    }

    /// R8 — deux relevés espacés de cinq minutes ne valent PAS cinq minutes de
    /// présence : c'est exactement ce que le trou de zone existe pour empêcher.
    #[test]
    fn un_trou_plus_long_que_le_seuil_ne_compte_pas() {
        let echantillons = vec![e(0, 10), e(300, 10)];
        assert_eq!(duree_presence(&echantillons, &config()), 0);

        // Le même écart, sous le seuil, compte intégralement.
        let serres = vec![e(0, 10), e(120, 10)];
        assert_eq!(duree_presence(&serres, &config()), 120);
    }

    /// GPS coupé : aucun échantillon. La preuve ne progresse pas, et l'écran
    /// doit pouvoir DIRE pourquoi plutôt que d'afficher un compteur figé.
    #[test]
    fn sans_position_la_preuve_dit_pourquoi() {
        let vide: Vec<Echantillon> = vec![];
        assert_eq!(duree_presence(&vide, &config()), 0);
        let preuve = composer_preuve(0, &vide, &config());
        assert!(!preuve.ok);
        assert_eq!(preuve.motif_cle, Some(motifs::AUCUN_RELEVE));

        // Un seul échantillon ne forme aucun intervalle — mais il y a bien une
        // position, et le motif change en conséquence.
        let un = vec![e(0, 10)];
        assert_eq!(duree_presence(&un, &config()), 0);
        assert_eq!(composer_preuve(0, &un, &config()).motif_cle, Some(motifs::EN_COURS));
    }

    /// Des échantillons qui arrivent tous hors du rayon : la preuve ne progresse
    /// pas, et le motif le dit — « rapproche-toi », pas « attends ».
    #[test]
    fn des_releves_tous_trop_loin_donnent_leur_propre_motif() {
        let loin = vec![e(0, 900), e(30, 850), e(60, 880)];
        assert_eq!(duree_presence(&loin, &config()), 0);
        assert_eq!(
            composer_preuve(0, &loin, &config()).motif_cle,
            Some(motifs::HORS_RAYON),
        );
    }

    /// Piège du cycle 005 — l'horloge de l'appareil ne fait pas foi. Un appareil
    /// qui AVANCE sur le serveur verrait ses échantillons futurs écartés : c'est
    /// la seule façon de fabriquer de la durée sans être sur place.
    #[test]
    fn une_horloge_en_avance_ne_fabrique_pas_de_presence() {
        let recu = base();
        // Six échantillons « vécus » sur 10 minutes, tous reçus en même temps
        // parce qu'ils ont été fabriqués d'un coup par une horloge en avance.
        let triches: Vec<Echantillon> = (0..=5)
            .map(|i| Echantillon {
                distance_m: 10,
                local: base() + chrono::Duration::seconds(i * 120),
                serveur: recu,
            })
            .collect();
        assert_eq!(
            duree_presence(&triches, &config()),
            120,
            "seul le premier intervalle tient dans la tolérance de dérive",
        );

        // Le MÊME vécu, envoyé au fil de l'eau, compte intégralement : le
        // hors-ligne n'est pas puni, seule l'avance d'horloge l'est.
        let honnetes: Vec<Echantillon> = (0..=5).map(|i| e(i * 120, 10)).collect();
        assert_eq!(duree_presence(&honnetes, &config()), 600);
    }

    /// Deux échantillons de même heure locale (doublon d'un lot mal découpé)
    /// n'ajoutent rien : un intervalle nul n'est pas une durée.
    #[test]
    fn deux_echantillons_simultanes_n_ajoutent_rien() {
        let echantillons = vec![e(0, 10), e(0, 10), e(30, 10)];
        assert_eq!(duree_presence(&echantillons, &config()), 30);
    }

    /// Les échantillons arrivent dans le désordre (deux lots rejoués à
    /// l'envers) : le calcul les remet dans l'ordre vécu avant de compter.
    #[test]
    fn un_lot_desordonne_est_remis_dans_l_ordre_vecu() {
        let desordre = vec![e(60, 10), e(0, 10), e(120, 10), e(30, 10), e(90, 10)];
        assert_eq!(duree_presence(&desordre, &config()), 120);
    }
}
