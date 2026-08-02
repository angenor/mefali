//! Une course, un seul preneur (DSP-04) — émission, contenu, conclusion.
//!
//! **Deux barrières, dont la seconde suffit seule** (research R4) :
//!
//! 1. le **double verrou** (commande *et* coursier) désigne un destinataire
//!    unique et empêche qu'un coursier voie deux écrans à la fois ;
//! 2. l'**affectation en Postgres** — `SELECT … FOR UPDATE` puis table de
//!    transitions fermée — rend deux affectations concurrentes impossibles
//!    **même si Redis a totalement disparu**. C'est ce qui rend SC-001
//!    démontrable sans louer la garantie à un service éphémère.
//!
//! **`DejaPrise` n'est pas un refus** (FR-049) : aucune pénalité, le coursier
//! reste dans le pool, et l'app l'affiche d'un ton neutre (K2-1b). Le distinguer
//! d'un refus n'est pas une nuance d'affichage : un « déjà prise » compté comme
//! refus ferait baisser un taux d'acceptation sur une décision que le coursier
//! n'a jamais prise.
//!
//! **L'échéance est PERSISTÉE** (research R1) : le compte à rebours survit à un
//! redémarrage, et toute lecture la respecte — une offre échue rend `204` même
//! si le tic n'est pas encore passé.

use chrono::{DateTime, Duration, Utc};
use serde_json::json;
use socle::{ecrire_evenement, NouvelEvenement};
use tarification::Point;
use uuid::Uuid;

use crate::config::ConfigDispatch;
use crate::depot::PgDispatch;
use crate::modele::{ErreurDispatch, IssueOffre, ModeOffre, Offre};
use crate::ports::{Annonce, Canal, PoseVerrou};

/// Ce que l'émission a décidé pour un candidat donné.
#[derive(Debug, Clone, PartialEq)]
pub enum IssueEmission {
    /// L'offre est partie.
    Emise(Box<Offre>),
    /// Le coursier porte déjà une offre : passer au candidat SUIVANT, sans
    /// attendre la conclusion de l'offre concurrente (FR-057).
    CoursierIndisponible,
    /// Une autre évaluation tient déjà cette commande : abandonner ce passage.
    CommandeDejaTenue,
}

impl PgDispatch {
    /// Émet une offre à un candidat, sous **double verrou**.
    ///
    /// Les trois issues de la pose sont traitées séparément parce qu'elles ne
    /// conduisent pas au même comportement — les confondre ferait soit sauter un
    /// candidat éligible, soit dupliquer une offre.
    #[allow(clippy::too_many_arguments)]
    pub async fn emettre_offre(
        &self,
        config: &ConfigDispatch,
        commande: Uuid,
        coursier: Uuid,
        mode: ModeOffre,
        rang: i16,
        score: i32,
        montant_a_avancer: i64,
        maintenant: DateTime<Utc>,
    ) -> Result<IssueEmission, ErreurDispatch> {
        // Le jeton du verrou EST l'identifiant de l'offre : une libération ne
        // peut donc pas viser une offre qu'on ne détient pas.
        let offre_id = Uuid::now_v7();
        match mode {
            // CASCADE — double verrou : un seul destinataire pour la commande,
            // et un seul écran pour le coursier.
            ModeOffre::Cascade => match self
                .verrous
                .poser(commande, coursier, offre_id, config.verrou_ttl())
                .await?
            {
                PoseVerrou::CoursierDejaPorteur => return Ok(IssueEmission::CoursierIndisponible),
                PoseVerrou::CommandeDejaOfferte => return Ok(IssueEmission::CommandeDejaTenue),
                PoseVerrou::Obtenu => {}
            },
            // BROADCAST — verrou de COURSIER seul (FR-062). Verrouiller la
            // commande à chaque destinataire empêcherait le second d'exister,
            // et « demander à tout le monde » n'aurait plus de sens.
            ModeOffre::Broadcast => {
                if !self
                    .verrous
                    .poser_coursier(coursier, offre_id, config.verrou_ttl())
                    .await?
                {
                    return Ok(IssueEmission::CoursierIndisponible);
                }
            }
        }

        let echeance = maintenant + Duration::seconds(config.timer_offre_s.max(1));
        let mut tx = self.pool.begin().await?;
        let insere = sqlx::query!(
            "INSERT INTO dispatch.offre
                 (id, commande_id, coursier_id, zone_id, mode, rang, score,
                  montant_a_avancer, devise, emise_le, echeance_le)
             VALUES ($1, $2, $3, $4, $5::text::dispatch.mode_offre, $6, $7, $8, $9, $10, $11)
             ON CONFLICT DO NOTHING
             RETURNING id",
            offre_id,
            commande,
            coursier,
            config.zone,
            mode.comme_str(),
            rang,
            score,
            montant_a_avancer,
            config.devise,
            maintenant,
            echeance,
        )
        .fetch_optional(&mut *tx)
        .await?;

        // Les index UNIQUE partiels sont le FILET Postgres du double verrou :
        // si l'insertion est refusée, c'est qu'une offre en vol existe déjà —
        // Redis avait tort (redémarrage, vidage), la base a raison.
        if insere.is_none() {
            tx.rollback().await?;
            self.verrous.liberer(commande, coursier, offre_id).await?;
            return Ok(IssueEmission::CoursierIndisponible);
        }
        // ⚠ Le filet Postgres qui vient de jouer n'est plus l'unicité par
        // commande en broadcast (migration 0014) : c'est celle par COURSIER.

        ecrire_evenement(
            &mut tx,
            NouvelEvenement {
                type_evenement: "dispatch.offre_emise",
                entite_type: "offre",
                entite_id: offre_id,
                payload: json!({
                    "commande": commande,
                    "coursier": coursier,
                    "mode": mode.comme_str(),
                    "rang": rang,
                    "score": score,
                    "montant_a_avancer": montant_a_avancer,
                    "devise": config.devise,
                    "timer_s": config.timer_offre_s,
                }),
                survenu_le: maintenant,
            },
        )
        .await?;
        tx.commit().await?;

        // Annonce au coursier — canal HAUTE PRIORITÉ (sonnerie prolongée quand
        // NTF-01 existera). Émise APRÈS le commit : une annonce perdue ne doit
        // pas annuler une offre écrite, et le port ne rend jamais d'erreur.
        self.notifications
            .annoncer(
                Annonce::nouvelle(
                    Canal::CoursierHautePriorite,
                    Some(coursier),
                    "dispatch.offre.nouvelle",
                )
                .pour_commande(commande)
                .pour_offre(offre_id)
                .avec_variables(json!({
                    "timer_s": config.timer_offre_s,
                    "montant_a_avancer": montant_a_avancer,
                    "devise": config.devise,
                })),
            )
            .await;

        Ok(IssueEmission::Emise(Box::new(Offre {
            id: offre_id,
            commande,
            coursier,
            zone: config.zone,
            mode,
            rang,
            score,
            montant_a_avancer,
            devise: config.devise.clone(),
            emise_le: maintenant,
            echeance_le: echeance,
            issue: IssueOffre::EnVol,
            repondue_le: None,
            franche: false,
        })))
    }

    /// Offre EN VOL et non échue d'un coursier — la garde de propriété est dans
    /// le `WHERE` : une offre qui n'est pas la sienne n'existe pas (`404`).
    pub async fn offre_courante(
        &self,
        coursier: Uuid,
        maintenant: DateTime<Utc>,
    ) -> Result<Option<Offre>, ErreurDispatch> {
        let ligne = sqlx::query_as!(
            LigneOffre,
            r#"SELECT id, commande_id, coursier_id, zone_id, mode::text AS "mode!",
                      rang, score, montant_a_avancer, devise, emise_le, echeance_le,
                      issue::text AS "issue!", repondue_le, franche
               FROM dispatch.offre
               WHERE coursier_id = $1 AND issue = 'en_vol' AND echeance_le > $2"#,
            coursier,
            maintenant,
        )
        .fetch_optional(&self.pool)
        .await?;
        ligne.map(LigneOffre::vers_offre).transpose()
    }

    /// Une offre par son identifiant, **si elle appartient à ce coursier**.
    pub async fn offre_de(&self, offre_id: Uuid, coursier: Uuid) -> Result<Offre, ErreurDispatch> {
        let ligne = sqlx::query_as!(
            LigneOffre,
            r#"SELECT id, commande_id, coursier_id, zone_id, mode::text AS "mode!",
                      rang, score, montant_a_avancer, devise, emise_le, echeance_le,
                      issue::text AS "issue!", repondue_le, franche
               FROM dispatch.offre
               WHERE id = $1 AND coursier_id = $2"#,
            offre_id,
            coursier,
        )
        .fetch_optional(&self.pool)
        .await?
        .ok_or(ErreurDispatch::OffreInconnue(offre_id))?;
        ligne.vers_offre()
    }

    /// Accepte une offre : affecte la course, ou dit pourquoi c'est impossible.
    ///
    /// **Idempotent** (FR-054) : un rejeu avec le même `uuid_client` rend la même
    /// affectation, sans seconde écriture ni second événement.
    ///
    /// L'affectation passe par `CommandesADispatcher::affecter` — **jamais** par
    /// une écriture directe : c'est cette méthode qui porte le `FOR UPDATE` et la
    /// table de transitions fermée, et donc la garantie anti-double-acceptation.
    pub async fn accepter_offre(
        &self,
        offre_id: Uuid,
        coursier: Uuid,
        uuid_client: Uuid,
        maintenant: DateTime<Utc>,
    ) -> Result<AcceptationFaite, ErreurDispatch> {
        let offre = self.offre_de(offre_id, coursier).await?;

        // Rejeu : la même offre, déjà acceptée par le même UUID client.
        if offre.issue == IssueOffre::Acceptee {
            let deja = sqlx::query_scalar!(
                "SELECT reponse_uuid_client FROM dispatch.offre WHERE id = $1",
                offre_id,
            )
            .fetch_one(&self.pool)
            .await?;
            if deja == Some(uuid_client) {
                let livraison = self
                    .livraison_de(offre.commande)
                    .await?
                    .ok_or(ErreurDispatch::OffreInconnue(offre_id))?;
                return Ok(AcceptationFaite {
                    commande: offre.commande,
                    livraison,
                    rejeu: true,
                });
            }
            return Err(ErreurDispatch::DejaPrise);
        }
        if offre.issue != IssueOffre::EnVol {
            return Err(ErreurDispatch::DejaPrise);
        }
        if offre.est_echue(maintenant) {
            return Err(ErreurDispatch::OffreEchue);
        }
        if self.commandes.course_active(coursier).await?.is_some() {
            return Err(ErreurDispatch::CourseActive);
        }

        // LA barrière : `affecter` sérialise sur la ligne de commande et refuse
        // la seconde transition. Une `TransitionRefusee` devient `DejaPrise`.
        let livraison = self.commandes.affecter(offre.commande, coursier).await?;

        let mut tx = self.pool.begin().await?;
        sqlx::query!(
            "UPDATE dispatch.offre
             SET issue = 'acceptee', repondue_le = $2, reponse_uuid_client = $3
             WHERE id = $1",
            offre_id,
            maintenant,
            uuid_client,
        )
        .execute(&mut *tx)
        .await?;
        ecrire_evenement(
            &mut tx,
            NouvelEvenement {
                type_evenement: "dispatch.offre_acceptee",
                entite_type: "offre",
                entite_id: offre_id,
                payload: json!({
                    "commande": offre.commande,
                    "coursier": coursier,
                    "livraison": livraison,
                    "delai_reponse_s": (maintenant - offre.emise_le).num_seconds().max(0),
                }),
                survenu_le: maintenant,
            },
        )
        .await?;
        tx.commit().await?;

        // Les deux verrous tombent : la commande est prise, le coursier est
        // occupé — la base le dit désormais mieux que Redis.
        self.verrous
            .liberer(offre.commande, coursier, offre_id)
            .await?;

        Ok(AcceptationFaite {
            commande: offre.commande,
            livraison,
            rejeu: false,
        })
    }

    /// Refus explicite : le candidat suivant est sollicité **immédiatement**,
    /// sans attendre la fin du compte à rebours (FR-050).
    ///
    /// Un refus compte dans le taux d'acceptation ; il n'entraîne **aucune**
    /// sanction (l'anti-abus DSP-08 est hors périmètre).
    pub async fn refuser_offre(
        &self,
        offre_id: Uuid,
        coursier: Uuid,
        uuid_client: Uuid,
        maintenant: DateTime<Utc>,
    ) -> Result<Offre, ErreurDispatch> {
        let offre = self.offre_de(offre_id, coursier).await?;
        if offre.issue == IssueOffre::Refusee {
            return Ok(offre); // rejeu : même corps, aucune écriture
        }
        if offre.issue != IssueOffre::EnVol {
            return Err(ErreurDispatch::DejaPrise);
        }

        let mut tx = self.pool.begin().await?;
        sqlx::query!(
            "UPDATE dispatch.offre
             SET issue = 'refusee', repondue_le = $2, reponse_uuid_client = $3
             WHERE id = $1 AND issue = 'en_vol'",
            offre_id,
            maintenant,
            uuid_client,
        )
        .execute(&mut *tx)
        .await?;
        ecrire_evenement(
            &mut tx,
            NouvelEvenement {
                type_evenement: "dispatch.offre_refusee",
                entite_type: "offre",
                entite_id: offre_id,
                payload: json!({
                    "commande": offre.commande,
                    "coursier": coursier,
                    "delai_reponse_s": (maintenant - offre.emise_le).num_seconds().max(0),
                }),
                survenu_le: maintenant,
            },
        )
        .await?;
        tx.commit().await?;
        self.verrous
            .liberer(offre.commande, coursier, offre_id)
            .await?;

        Ok(Offre {
            issue: IssueOffre::Refusee,
            repondue_le: Some(maintenant),
            ..offre
        })
    }

    /// Marque une offre « déjà prise » — **sans pénalité**, coursier maintenu
    /// dans le pool (FR-049).
    pub async fn marquer_deja_prise(
        &self,
        offre_id: Uuid,
        maintenant: DateTime<Utc>,
    ) -> Result<(), ErreurDispatch> {
        let mut tx = self.pool.begin().await?;
        let ligne = sqlx::query!(
            "UPDATE dispatch.offre
             SET issue = 'deja_prise', repondue_le = $2
             WHERE id = $1 AND issue = 'en_vol'
             RETURNING commande_id, coursier_id",
            offre_id,
            maintenant,
        )
        .fetch_optional(&mut *tx)
        .await?;
        let Some(ligne) = ligne else {
            tx.rollback().await?;
            return Ok(());
        };
        ecrire_evenement(
            &mut tx,
            NouvelEvenement {
                type_evenement: "dispatch.offre_deja_prise",
                entite_type: "offre",
                entite_id: offre_id,
                payload: json!({
                    "commande": ligne.commande_id,
                    "coursier": ligne.coursier_id,
                }),
                survenu_le: maintenant,
            },
        )
        .await?;
        tx.commit().await?;
        self.verrous
            .liberer(ligne.commande_id, ligne.coursier_id, offre_id)
            .await?;
        Ok(())
    }

    /// Conclut une offre ÉCHUE en non-réponse, franche ou non.
    ///
    /// Les `dispatch.timeouts_francs_par_jour` premières du **jour** sont
    /// FRANCHES : ni pénalité, ni effet sur le taux d'acceptation (FR-052). La
    /// franchise se compte sur les offres du jour, pas sur un compteur séparé —
    /// un compteur pourrait se désynchroniser de la table qui fait foi.
    pub async fn conclure_non_reponse(
        &self,
        offre: &Offre,
        config: &ConfigDispatch,
        maintenant: DateTime<Utc>,
    ) -> Result<bool, ErreurDispatch> {
        let debut_jour = maintenant
            .date_naive()
            .and_hms_opt(0, 0, 0)
            .map(|d| d.and_utc())
            .unwrap_or(maintenant);
        let deja_franches = sqlx::query_scalar!(
            r#"SELECT count(*) AS "n!" FROM dispatch.offre
               WHERE coursier_id = $1 AND issue = 'non_repondue'
                 AND franche AND emise_le >= $2"#,
            offre.coursier,
            debut_jour,
        )
        .fetch_one(&self.pool)
        .await?;
        let franche = deja_franches < config.timeouts_francs_par_jour;
        let rang_du_jour = deja_franches + 1;

        let mut tx = self.pool.begin().await?;
        let maj = sqlx::query!(
            "UPDATE dispatch.offre
             SET issue = 'non_repondue', repondue_le = $2, franche = $3
             WHERE id = $1 AND issue = 'en_vol'
             RETURNING id",
            offre.id,
            maintenant,
            franche,
        )
        .fetch_optional(&mut *tx)
        .await?;
        if maj.is_none() {
            // Conclue entre-temps (acceptée, refusée) : rien à faire.
            tx.rollback().await?;
            return Ok(false);
        }
        ecrire_evenement(
            &mut tx,
            NouvelEvenement {
                type_evenement: "dispatch.offre_non_repondue",
                entite_type: "offre",
                entite_id: offre.id,
                payload: json!({
                    "commande": offre.commande,
                    "coursier": offre.coursier,
                    "franche": franche,
                    "rang_du_jour": rang_du_jour,
                }),
                survenu_le: maintenant,
            },
        )
        .await?;
        tx.commit().await?;
        self.verrous
            .liberer(offre.commande, offre.coursier, offre.id)
            .await?;

        // Ton NEUTRE, sans blâme : « sans pénalité — n sur 3 aujourd'hui ».
        self.notifications
            .annoncer(
                Annonce::nouvelle(
                    Canal::CoursierHautePriorite,
                    Some(offre.coursier),
                    "dispatch.offre.non_repondue",
                )
                .pour_offre(offre.id)
                .avec_variables(json!({
                    "franche": franche,
                    "rang_du_jour": rang_du_jour,
                    "plafond_francs": config.timeouts_francs_par_jour,
                })),
            )
            .await;
        Ok(true)
    }

    /// Offres EN VOL dont l'échéance est passée, les plus urgentes d'abord.
    pub async fn offres_echues(
        &self,
        maintenant: DateTime<Utc>,
    ) -> Result<Vec<Offre>, ErreurDispatch> {
        let lignes = sqlx::query_as!(
            LigneOffre,
            r#"SELECT id, commande_id, coursier_id, zone_id, mode::text AS "mode!",
                      rang, score, montant_a_avancer, devise, emise_le, echeance_le,
                      issue::text AS "issue!", repondue_le, franche
               FROM dispatch.offre
               WHERE issue = 'en_vol' AND echeance_le <= $1
               ORDER BY echeance_le"#,
            maintenant,
        )
        .fetch_all(&self.pool)
        .await?;
        lignes.into_iter().map(LigneOffre::vers_offre).collect()
    }

    /// Coursiers déjà sollicités pour une commande — mémoire de la cascade.
    ///
    /// Aucune colonne dédiée : l'historique des offres EST la mémoire (FR-051,
    /// FR-074). Une colonne de plus pourrait se désynchroniser de lui.
    pub async fn deja_sollicites(&self, commande: Uuid) -> Result<Vec<Uuid>, ErreurDispatch> {
        Ok(sqlx::query_scalar!(
            "SELECT DISTINCT coursier_id FROM dispatch.offre WHERE commande_id = $1",
            commande,
        )
        .fetch_all(&self.pool)
        .await?)
    }

    /// Nombre d'offres déjà émises pour une commande — le compteur de cascade
    /// qui décide de la bascule en broadcast (FR-058).
    pub async fn nb_offres_emises(&self, commande: Uuid) -> Result<i64, ErreurDispatch> {
        Ok(sqlx::query_scalar!(
            r#"SELECT count(*) AS "n!" FROM dispatch.offre WHERE commande_id = $1"#,
            commande,
        )
        .fetch_one(&self.pool)
        .await?)
    }

    /// Livraison d'une commande, si elle en a une.
    pub(crate) async fn livraison_de(
        &self,
        commande: Uuid,
    ) -> Result<Option<Uuid>, ErreurDispatch> {
        Ok(sqlx::query_scalar!(
            "SELECT id FROM commandes.livraison WHERE commande_id = $1",
            commande,
        )
        .fetch_optional(&self.pool)
        .await?)
    }
}

/// Ce qu'une acceptation a produit.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct AcceptationFaite {
    /// Commande affectée.
    pub commande: Uuid,
    /// Livraison assignée.
    pub livraison: Uuid,
    /// Vrai si l'appel était un rejeu du même `uuid_client` — même corps, aucune
    /// seconde écriture (FR-054).
    pub rejeu: bool,
}

/// Ligne de lecture d'une offre — **une seule** forme pour les quatre requêtes
/// qui la lisent. Les énums Postgres sont castés en `text` (patron du cycle
/// 005 : jamais l'énum brut, qui lierait le type Rust au type SQL).
struct LigneOffre {
    id: Uuid,
    commande_id: Uuid,
    coursier_id: Uuid,
    zone_id: Uuid,
    mode: String,
    rang: i16,
    score: i32,
    montant_a_avancer: i64,
    devise: String,
    emise_le: DateTime<Utc>,
    echeance_le: DateTime<Utc>,
    issue: String,
    repondue_le: Option<DateTime<Utc>>,
    franche: bool,
}

impl LigneOffre {
    fn vers_offre(self) -> Result<Offre, ErreurDispatch> {
        Ok(Offre {
            id: self.id,
            commande: self.commande_id,
            coursier: self.coursier_id,
            zone: self.zone_id,
            mode: self.mode.parse()?,
            rang: self.rang,
            score: self.score,
            montant_a_avancer: self.montant_a_avancer,
            devise: self.devise,
            emise_le: self.emise_le,
            echeance_le: self.echeance_le,
            issue: self.issue.parse()?,
            repondue_le: self.repondue_le,
            franche: self.franche,
        })
    }
}

// ══════════════════════════════════════════════════════════════════════════
// Contenu de l'offre — ce que Yao voit avant de décider (K2)
// ══════════════════════════════════════════════════════════════════════════

/// Un arrêt tel que l'offre le présente.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ArretOffert {
    /// Rang d'affichage (1 = premier arrêt).
    pub ordre: i32,
    /// Prestataire visé (`None` pour la remise).
    pub prestataire_id: Option<Uuid>,
    /// Nom affiché.
    pub nom: String,
    /// Distance INTER-ARRÊTS en mètres — « + 40 m » de la maquette K2.
    pub distance_m: i64,
}

/// Tout ce que l'écran d'offre affiche.
///
/// **Aucune coordonnée du client** (ARTCI, contrat §1.3) : la destination n'est
/// décrite que par le nom de sa zone et une distance arrondie. L'adresse exacte
/// n'arrive qu'**après** acceptation, par le suivi de course du cycle 008.
///
/// ⚠ **Écart assumé avec la maquette K2**, à porter au produit : K2 affiche
/// « quartier Sokoura ». Aucun quartier n'existe en donnée — `TypeZone::Quartier`
/// est une PROVISION (« données seulement », constitution IX) et l'arbre seedé
/// s'arrête à la ville. Le contrat rend donc le nom de la VILLE. Construire un
/// libellé de quartier exigerait soit d'activer la provision, soit un service de
/// géocodage inverse : aucun des deux n'est au périmètre.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ContenuOffre {
    /// Arrêts dans l'ordre optimisé du devis FIGÉ (jamais recalculé).
    pub arrets: Vec<ArretOffert>,
    /// Nom de la zone de livraison (jamais une adresse).
    pub destination_zone_nom: String,
    /// Distance approximative jusqu'à la destination (mètres arrondis).
    pub destination_distance_m: i64,
    /// Gain total du coursier (unités mineures).
    pub gain_total_unites: i64,
    /// Part de déplacement.
    pub gain_deplacement_unites: i64,
    /// Part des arrêts supplémentaires.
    pub gain_arrets_unites: i64,
    /// Part d'effort.
    pub gain_effort_unites: i64,
    /// Plafond d'avance retenu du destinataire — pourquoi il peut la prendre.
    pub plafond_retenu_unites: i64,
    /// Vrai si les distances viennent du repli vol d'oiseau (constitution IV).
    pub degraded: bool,
}

impl PgDispatch {
    /// Compose le contenu d'une offre depuis le devis FIGÉ de la livraison.
    ///
    /// Rien n'est recalculé : le devis a été figé à la création (cycle 007), et
    /// le recalculer ici ferait varier le gain annoncé entre deux affichages du
    /// même écran.
    pub async fn contenu_offre(
        &self,
        offre: &Offre,
        maintenant: DateTime<Utc>,
    ) -> Result<ContenuOffre, ErreurDispatch> {
        let entete = sqlx::query!(
            r#"SELECT l.devis_part_coursier, l.devis_distance_m, l.devis_degraded,
                      l.devis_composantes,
                      z.nom AS "zone_nom!"
               FROM commandes.livraison l
               JOIN commandes.commande c ON c.id = l.commande_id
               JOIN zones.zone z ON z.id = c.zone_id
               WHERE l.commande_id = $1"#,
            offre.commande,
        )
        .fetch_optional(&self.pool)
        .await?
        .ok_or(ErreurDispatch::OffreInconnue(offre.id))?;

        let arrets = sqlx::query!(
            r#"SELECT a.ordre, a.prestataire_id, a.type_arret::text AS "type_arret!",
                      a.site_lat, a.site_lon,
                      COALESCE(p.nom, '') AS "nom!"
               FROM commandes.arret a
               JOIN commandes.segment s ON s.id = a.segment_id
               JOIN commandes.livraison l ON l.id = s.livraison_id
               LEFT JOIN prestataires.prestataire p ON p.id = a.prestataire_id
               WHERE l.commande_id = $1
               ORDER BY s.ordre, a.ordre"#,
            offre.commande,
        )
        .fetch_all(&self.pool)
        .await?;

        // Les distances INTER-ARRÊTS viennent d'UNE SEULE matrice routière
        // (FR-035, research R5) : le premier arrêt est mesuré depuis la position
        // du coursier, les suivants depuis leur prédécesseur (maquette :
        // « à 800 m », « + 40 m »). Mesurer tronçon par tronçon coûterait une
        // requête de routage par arrêt, et le cache par tronçon du cycle 007 ne
        // les absorberait pas : il ne réchauffe jamais coursier→vendeur, qui
        // part d'une position mobile.
        let origine = self
            .pool_coursiers
            .etat(offre.coursier)
            .await?
            .map(|i| Point {
                lat: i.lat,
                lon: i.lon,
            });
        let mut points: Vec<Point> = Vec::new();
        if let Some(o) = origine {
            points.push(o);
        }
        for a in &arrets {
            points.push(Point {
                lat: a.site_lat,
                lon: a.site_lon,
            });
        }

        let troncons = self
            .proximite
            .troncons_consecutifs(offre.zone, &points)
            .await;
        // Une position de coursier ABSENTE (sorti du pool entre l'émission et
        // l'affichage) rend le premier tronçon INCONNU — et un « à 0 m » sur un
        // vendeur à 3 km est un mensonge, pas une approximation. On le marque
        // avec le seul mécanisme que l'écran sait rendre : `degraded`, qui
        // affiche « Distances estimées » (constitution IV).
        let degraded = entete.devis_degraded || troncons.degraded || origine.is_none();
        let distances: Vec<i64> = troncons.trajets.iter().map(|t| t.distance_m).collect();

        let origine_connue = origine.is_some();
        let distance_vers = |arret: usize| distance_vers_arret(&distances, arret, origine_connue);

        let gain = decomposer_gain(entete.devis_part_coursier, &entete.devis_composantes);

        let collectes: Vec<_> = arrets
            .iter()
            .enumerate()
            .filter(|(_, a)| a.type_arret == "collecte")
            .collect();
        let destination_distance_m = distances.last().copied().unwrap_or(0);

        let plafond_retenu = self
            .plafond_du_jour(offre.coursier, &self.config(offre.zone).await?, maintenant)
            .await?
            .retenu_unites;

        Ok(ContenuOffre {
            arrets: collectes
                .iter()
                .enumerate()
                .map(|(rang, (index, a))| ArretOffert {
                    ordre: rang as i32 + 1,
                    prestataire_id: a.prestataire_id,
                    nom: a.nom.clone(),
                    distance_m: distance_vers(*index),
                })
                .collect(),
            destination_zone_nom: entete.zone_nom,
            destination_distance_m,
            gain_total_unites: entete.devis_part_coursier,
            gain_deplacement_unites: gain.deplacement,
            gain_arrets_unites: gain.arrets,
            gain_effort_unites: gain.effort,
            plafond_retenu_unites: plafond_retenu,
            degraded,
        })
    }
}

/// Distance à afficher pour l'arrêt de rang `arret` (0 = premier).
///
/// Les tronçons viennent d'une matrice construite sur `[position du coursier ?,
/// arrêt 0, arrêt 1, …]` : quand la position OUVRE l'itinéraire, le tronçon `k`
/// mène à l'arrêt `k`, sinon il mène à l'arrêt `k+1`.
///
/// **Sans ce décalage**, une position absente décalait toutes les distances
/// d'un arrêt — chaque arrêt affichait celle de son SUIVANT, et le dernier
/// affichait la remise au client. Le premier arrêt rend alors `0` : c'est une
/// distance INCONNUE, et l'appelant la marque `degraded` plutôt que de la faire
/// passer pour une mesure.
fn distance_vers_arret(distances: &[i64], arret: usize, origine_connue: bool) -> i64 {
    (arret + usize::from(origine_connue))
        .checked_sub(1)
        .and_then(|troncon| distances.get(troncon).copied())
        .unwrap_or(0)
}

/// Les trois parts du gain que K2 affiche sous son total.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct GainDetaille {
    /// Part de déplacement — le RÉSIDU, jamais une somme reconstituée.
    pub deplacement: i64,
    /// Part des arrêts supplémentaires.
    pub arrets: i64,
    /// Part d'effort (paliers d'articles + prime d'attente).
    pub effort: i64,
}

/// Décompose la part coursier en trois parts dont la somme fait **exactement**
/// le total.
///
/// Ce que cette fonction protège : un détail qui contredit le total fait douter
/// du total. La première rédaction lisait trois clés qui n'existaient pas
/// (`deplacement`, `arrets`, `effort`) et affichait « 0 + 0 + 0 » sous un gain
/// de 150 FCFA — trouvé sur émulateur (T071), invisible en test.
///
/// **Pourquoi les composantes d'effort se lisent à l'échelle du coursier** :
/// `tarification::Composantes` porte les composantes du prix CLIENT, mais les
/// trois composantes d'effort y sont **100 % coursier** (évaluation, étape 5 :
/// « elle abonde le prix client ET la part coursier ; la marge ne bouge pas
/// d'un franc »). Elles se reportent donc telles quelles, sans prorata. Un
/// commentaire antérieur affirmait l'inverse — il a fait croire, à juste titre,
/// que les parts affichées étaient surévaluées.
///
/// Le déplacement se prend par SOUSTRACTION, jamais en ré-additionnant
/// `base + km + suppléments − marge` : la marge n'est pas une composante
/// stockée, et la reconstituer ferait diverger la somme du total au premier
/// arrondi.
///
/// **Le bornage n'est pas décoratif** : `part_coursier ≥ effort_total` est vrai
/// de tout devis produit par TRF (le résidu vaut `part_coursier_base + km +
/// supplements + arrondi`, tous positifs), mais cette fonction lit une colonne
/// JSON figée que rien ne garantit cohérente. Un `.max(0)` sur le seul
/// déplacement laissait alors la somme des trois parts DÉPASSER le total, en
/// silence. Ici les parts sont bornées dans l'ordre, et le déplacement absorbe
/// ce qui reste : la somme fait le total quoi qu'on lise.
pub fn decomposer_gain(part_coursier: i64, composantes: &serde_json::Value) -> GainDetaille {
    let composante = |cle: &str| -> i64 {
        composantes
            .get(cle)
            .and_then(serde_json::Value::as_i64)
            .unwrap_or(0)
            .max(0)
    };

    let total = part_coursier.max(0);
    let arrets = composante("effort_arrets").min(total);
    let effort = (composante("effort_paliers") + composante("effort_attente")).min(total - arrets);
    GainDetaille {
        deplacement: total - arrets - effort,
        arrets,
        effort,
    }
}

#[cfg(test)]
mod tests_distances {
    use super::*;

    /// Position connue : `[coursier, A, B, C]` ⇒ tronçons
    /// `coursier→A`, `A→B`, `B→C`. Chaque arrêt lit SA distance d'approche.
    #[test]
    fn avec_la_position_du_coursier_chaque_arret_lit_son_approche() {
        let distances = [800, 40, 1_200];
        assert_eq!(distance_vers_arret(&distances, 0, true), 800);
        assert_eq!(distance_vers_arret(&distances, 1, true), 40);
        assert_eq!(distance_vers_arret(&distances, 2, true), 1_200);
    }

    /// Position INCONNUE : `[A, B, C]` ⇒ tronçons `A→B`, `B→C`. Sans décalage,
    /// l'arrêt 0 affichait `A→B` (40 m) — la distance de son SUIVANT — et le
    /// dernier affichait la remise au client.
    #[test]
    fn sans_position_les_distances_ne_glissent_pas_d_un_arret() {
        let distances = [40, 1_200];
        assert_eq!(
            distance_vers_arret(&distances, 0, false),
            0,
            "le premier tronçon est INCONNU, pas emprunté au suivant",
        );
        assert_eq!(distance_vers_arret(&distances, 1, false), 40);
        assert_eq!(distance_vers_arret(&distances, 2, false), 1_200);
    }

    /// Un tronçon manquant ne panique pas : l'offre s'affiche quand même.
    #[test]
    fn un_troncon_absent_rend_zero_sans_paniquer() {
        assert_eq!(distance_vers_arret(&[], 0, true), 0);
        assert_eq!(distance_vers_arret(&[800], 5, true), 0);
    }
}

#[cfg(test)]
mod tests_gain {
    use super::*;
    use serde_json::json;

    /// Le cas nominal : les composantes d'effort sont 100 % coursier, elles se
    /// reportent telles quelles, et le déplacement est le reste.
    #[test]
    fn les_trois_parts_font_le_total() {
        let gain = decomposer_gain(
            450,
            &json!({
                "base": 500, "km": 120, "supplements": 0, "arrondi": 30,
                "effort_paliers": 60, "effort_attente": 40, "effort_arrets": 50,
            }),
        );
        assert_eq!(gain.arrets, 50);
        assert_eq!(gain.effort, 100);
        assert_eq!(gain.deplacement, 300);
        assert_eq!(gain.deplacement + gain.arrets + gain.effort, 450);
    }

    /// Un devis figé dont l'effort DÉPASSE la part coursier — impossible via
    /// TRF, mais cette fonction lit une colonne JSON que rien ne contraint.
    /// L'ancienne rédaction rendait `arrets=50, effort=500, deplacement=0`,
    /// soit 550 affichés sous un total de 150 : Yao lisait un détail qui
    /// contredisait son gain, et doutait du gain.
    #[test]
    fn un_devis_incoherent_ne_fait_jamais_mentir_le_total() {
        let total = 150;
        let gain = decomposer_gain(
            total,
            &json!({
                "effort_paliers": 300, "effort_attente": 200, "effort_arrets": 50,
            }),
        );
        assert_eq!(
            gain.deplacement + gain.arrets + gain.effort,
            total,
            "la somme affichée doit faire le total, quelle que soit la donnée lue",
        );
        assert!(gain.deplacement >= 0 && gain.arrets >= 0 && gain.effort >= 0);
    }

    /// Des clés ABSENTES (la faute d'origine) ne mettent pas les trois parts à
    /// zéro : le déplacement absorbe tout, et le total reste vrai.
    #[test]
    fn des_composantes_absentes_laissent_le_total_intact() {
        let gain = decomposer_gain(450, &json!({}));
        assert_eq!(gain.deplacement, 450);
        assert_eq!(gain.arrets + gain.effort, 0);
    }
}
