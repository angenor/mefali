//! Les **trois preuves** d'un client absent, et rien d'autre (FR-056 → FR-064).
//!
//! Un échec de livraison coûte de l'argent à quelqu'un : au client qui ne reçoit
//! pas, au vendeur déjà payé, au coursier qui a avancé. C'est pourquoi il ne se
//! déclare pas sur parole. Trois preuves, toutes mesurées, toutes revérifiées
//! ici :
//!
//! | Preuve | Ce qu'elle mesure | Où elle vit |
//! |---|---|---|
//! | **Appels** | appels `client_absent` retenus, ESPACÉS | [`crate::appels`] |
//! | **Présence** | durée sur place, trous exclus | [`crate::presence`] |
//! | **Photo** | au moins une photo de la porte close | ce module |
//!
//! **Une seule fonction, deux appelants.** [`PgCoursier::etat_preuves`] sert à
//! la fois l'écran K4-1e et la garde de `POST /courses/{id}/echec` : l'écran et
//! le serveur ne peuvent donc pas diverger (FR-059, FR-060). Un bouton actif
//! dont la déclaration serait refusée serait pire qu'un bouton inactif — Yao
//! aurait fait le travail pour rien.
//!
//! **Ce que le basculement émet.** `preuves_echec.reunies` marque l'INSTANT où
//! l'échec devient déclarable, exactement une fois (table `preuves_reunies`,
//! migration 0019). Les critères, eux, restent recalculés à chaque lecture :
//! un seuil de zone resserré s'applique tout de suite, y compris à une livraison
//! déjà basculée.

use chrono::{DateTime, Utc};
use serde_json::json;
use socle::NouvelEvenement;
use uuid::Uuid;

use crate::config::{ConfigCoursier, PHOTOS_PREUVE_MIN};
use crate::depot::PgCoursier;
use crate::modele::{AppelJournalise, ErreurCoursier, EtatPreuves, PreuveAppels, PreuvePhotos};

/// Clés i18n des motifs de non-progression (FR-058).
pub mod motifs {
    /// Aucun appel `client_absent` passé via l'app.
    pub const APPELS_AUCUN: &str = "coursier.preuve.appels_aucun";
    /// Des appels existent, mais trop rapprochés pour compter.
    pub const APPELS_TROP_RAPPROCHES: &str = "coursier.preuve.appels_trop_rapproches";
    /// Le compte n'y est pas encore.
    pub const APPELS_MANQUANTS: &str = "coursier.preuve.appels_manquants";
}

/// Ce que le serveur rend après le dépôt d'une photo de preuve.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PhotoPreuveDeposee {
    /// Photo enregistrée.
    pub photo_id: Uuid,
    /// Photos de preuve de cette livraison, après dépôt.
    pub photos: i64,
    /// Vrai si la photo existait déjà (rejeu de la file) — rien n'a été redéposé.
    pub rejeu: bool,
}

/// Retient les appels `client_absent` **suffisamment espacés** (FR-056).
///
/// Sans I/O : c'est la règle qui décide si trois appels en quarante secondes
/// valent trois preuves ou une seule, et elle mérite d'être exerçable seule.
///
/// Le premier appel est toujours retenu ; chaque suivant ne l'est que s'il est
/// distant du **dernier retenu** d'au moins l'espacement de zone. Compter depuis
/// le dernier retenu, et non depuis le dernier appel, empêche une rafale de
/// grignoter l'espacement appel après appel.
pub fn appels_retenus(appels: &[AppelJournalise], espacement_s: i64) -> Vec<&AppelJournalise> {
    let mut retenus: Vec<&AppelJournalise> = Vec::new();
    for appel in appels.iter().filter(|a| a.motif.compte_pour_preuve()) {
        let assez_loin = retenus
            .last()
            .is_none_or(|d| (appel.passe_le - d.passe_le).num_seconds() >= espacement_s);
        if assez_loin {
            retenus.push(appel);
        }
    }
    retenus
}

/// Compose la preuve « appels » depuis le journal d'une livraison.
pub fn composer_preuve_appels(appels: &[AppelJournalise], config: &ConfigCoursier) -> PreuveAppels {
    let candidats = appels
        .iter()
        .filter(|a| a.motif.compte_pour_preuve())
        .count();
    let retenus = appels_retenus(appels, config.preuve_appels_espacement_s);
    let faits = retenus.len() as i64;
    let requis = config.preuve_appels_min;
    let ok = faits >= requis;
    // Faux dès qu'un appel a été ÉCARTÉ pour cause d'espacement : c'est ce que
    // K4-1e doit dire à Yao (« attends trois minutes »), pas « rappelle ».
    let espacement_ok = candidats == retenus.len();

    let motif_cle = if ok {
        None
    } else if candidats == 0 {
        Some(motifs::APPELS_AUCUN)
    } else if !espacement_ok {
        Some(motifs::APPELS_TROP_RAPPROCHES)
    } else {
        Some(motifs::APPELS_MANQUANTS)
    };

    PreuveAppels {
        faits,
        requis,
        espacement_ok,
        horodatages: retenus.iter().map(|a| a.passe_le).collect(),
        issues: retenus.iter().map(|a| a.issue).collect(),
        ok,
        motif_cle,
    }
}

impl PgCoursier {
    /// Dépose une photo de preuve d'échec (FR-056, FR-064).
    ///
    /// La photo voyage **avec** la demande, comme celle du dépôt (R18) : c'est
    /// ce qui la rend prenable hors ligne. Idempotent par `uuid_client` — un
    /// rejeu ne redépose rien et ne compte pas une seconde photo.
    pub async fn deposer_photo_preuve(
        &self,
        coursier: Uuid,
        livraison: Uuid,
        uuid_client: Uuid,
        octets: Vec<u8>,
        prise_le_local: Option<DateTime<Utc>>,
    ) -> Result<PhotoPreuveDeposee, ErreurCoursier> {
        self.exiger_proprietaire(livraison, coursier).await?;
        if octets.is_empty() {
            return Err(ErreurCoursier::DemandeInvalide("photo vide"));
        }

        // Rejeu : la ligne existe déjà, l'objet aussi. Redéposer écraserait des
        // octets identiques pour rien — et compterait une photo de plus si la
        // contrainte d'unicité n'était pas là (elle l'est, migration 0015).
        if let Some(photo_id) = self.photo_par_uuid(uuid_client).await? {
            return Ok(PhotoPreuveDeposee {
                photo_id,
                photos: self.photos_de(livraison).await?,
                rejeu: true,
            });
        }

        let photo_id = Uuid::now_v7();
        let cle = format!("coursier/preuves/{photo_id}.jpg");
        // Déposé AVANT l'écriture en base : une clé en base qui ne désigne rien
        // serait une preuve manquante au moment où l'exploitation la lit, alors
        // qu'un objet sans ligne n'est qu'un orphelin que la purge ramassera.
        self.objets.deposer(&cle, octets, "image/jpeg").await?;

        let insere = sqlx::query_scalar!(
            r#"INSERT INTO coursier.preuve_photo (id, livraison_id, cle_objet, prise_le, uuid_client)
               VALUES ($1, $2, $3, COALESCE($4, now()), $5)
               ON CONFLICT (uuid_client) DO NOTHING
               RETURNING id"#,
            photo_id,
            livraison,
            cle,
            prise_le_local,
            uuid_client,
        )
        .fetch_optional(&self.pool)
        .await?;

        // Course entre deux rejeux simultanés : la contrainte a tranché, on rend
        // la ligne gagnante plutôt qu'une erreur.
        let (photo_id, rejeu) = match insere {
            Some(id) => (id, false),
            None => (
                self.photo_par_uuid(uuid_client)
                    .await?
                    .ok_or(ErreurCoursier::DemandeInvalide("photo introuvable"))?,
                true,
            ),
        };

        let photos = self.photos_de(livraison).await?;
        self.evaluer_basculement(livraison).await?;
        Ok(PhotoPreuveDeposee {
            photo_id,
            photos,
            rejeu,
        })
    }

    /// L'état des trois preuves d'une livraison — **la** fonction du module.
    ///
    /// C'est elle que lit l'écran K4-1e, et c'est elle que consulte la garde de
    /// `POST /courses/{id}/echec` via le port `commandes::PreuvesEchec`.
    pub async fn etat_preuves(&self, livraison: Uuid) -> Result<EtatPreuves, ErreurCoursier> {
        let config = self.config_de_livraison(livraison).await?;
        self.etat_preuves_avec(livraison, &config).await
    }

    /// Variante qui réutilise une configuration déjà chargée.
    pub(crate) async fn etat_preuves_avec(
        &self,
        livraison: Uuid,
        config: &ConfigCoursier,
    ) -> Result<EtatPreuves, ErreurCoursier> {
        let appels = self.appels_de_livraison(livraison).await?;
        let preuve_appels = composer_preuve_appels(&appels, config);
        let presence = self.presence_mesuree(livraison, config).await?;
        let faites = self.photos_de(livraison).await?;
        let photos = PreuvePhotos {
            faites,
            requis: PHOTOS_PREUVE_MIN,
            ok: faites >= PHOTOS_PREUVE_MIN,
        };

        let reunies_sur = u8::from(preuve_appels.ok) + u8::from(presence.ok) + u8::from(photos.ok);
        Ok(EtatPreuves {
            reunies: reunies_sur == EtatPreuves::TOTAL,
            reunies_sur,
            appels: preuve_appels,
            presence,
            photos,
        })
    }

    /// Évalue les preuves et émet `preuves_echec.reunies` **au basculement**.
    ///
    /// Appelée après chaque écriture qui peut faire avancer une preuve (appel,
    /// lot de présence, photo). L'unicité de `preuves_reunies.livraison_id` fait
    /// l'exactement-une-fois : « 0 ligne insérée » veut dire « déjà émis ».
    pub(crate) async fn evaluer_basculement(
        &self,
        livraison: Uuid,
    ) -> Result<EtatPreuves, ErreurCoursier> {
        let config = self.config_de_livraison(livraison).await?;
        let etat = self.etat_preuves_avec(livraison, &config).await?;
        if !etat.reunies {
            return Ok(etat);
        }

        let mut tx = self.pool.begin().await?;
        let marque = sqlx::query_scalar!(
            r#"INSERT INTO coursier.preuves_reunies (livraison_id, reunies_le)
               VALUES ($1, $2)
               ON CONFLICT (livraison_id) DO NOTHING
               RETURNING reunies_le"#,
            livraison,
            self.maintenant(),
        )
        .fetch_optional(&mut *tx)
        .await?;
        let Some(reunies_le) = marque else {
            // Déjà basculée : aucun second événement. Un flux d'événements
            // identiques ne marquerait plus aucun instant.
            tx.rollback().await?;
            return Ok(etat);
        };

        let commande = self.commande_de_livraison(&mut tx, livraison).await?;
        let delai = self
            .delai_depuis_arrivee(livraison, reunies_le)
            .await?
            .map(serde_json::Value::from)
            .unwrap_or(serde_json::Value::Null);
        socle::ecrire_evenement(
            &mut tx,
            NouvelEvenement {
                type_evenement: "preuves_echec.reunies",
                entite_type: "livraison",
                entite_id: livraison,
                // ⚠ Aucun secret, aucun numéro, et aucune ISSUE d'appel : elle
                // est déclarative et n'est pas un critère (R19).
                payload: json!({
                    "commande": commande,
                    "appels_retenus": etat.appels.faits,
                    "presence_s": etat.presence.secondes,
                    "photos": etat.photos.faites,
                    "delai_depuis_arrivee_s": delai,
                }),
                survenu_le: reunies_le,
            },
        )
        .await?;
        tx.commit().await?;
        Ok(etat)
    }

    /// Secondes écoulées entre l'arrivée SERVEUR chez le client et le
    /// basculement. `None` si l'arrivée n'a jamais été déclarée.
    async fn delai_depuis_arrivee(
        &self,
        livraison: Uuid,
        jusqu_a: DateTime<Utc>,
    ) -> Result<Option<i64>, ErreurCoursier> {
        let arrivee: Option<DateTime<Utc>> = sqlx::query_scalar!(
            r#"SELECT a.arrive_le
                 FROM commandes.arret a
                 JOIN commandes.segment s ON s.id = a.segment_id
                WHERE s.livraison_id = $1 AND a.type_arret = 'remise'
                ORDER BY s.ordre DESC, a.ordre DESC
                LIMIT 1"#,
            livraison,
        )
        .fetch_optional(&self.pool)
        .await?
        .flatten();
        Ok(arrivee.map(|a| (jusqu_a - a).num_seconds().max(0)))
    }

    /// Photos de preuve d'une livraison.
    ///
    /// Les photos **purgées** comptent encore : la rétention efface des octets,
    /// pas le fait que la photo a été prise. Un échec déclaré il y a un an ne
    /// doit pas devenir non prouvé le jour de la purge.
    pub(crate) async fn photos_de(&self, livraison: Uuid) -> Result<i64, ErreurCoursier> {
        Ok(sqlx::query_scalar!(
            r#"SELECT count(*) AS "n!" FROM coursier.preuve_photo WHERE livraison_id = $1"#,
            livraison,
        )
        .fetch_one(&self.pool)
        .await?)
    }

    /// Photo déjà enregistrée pour ce `uuid_client` (rejeu de la file).
    async fn photo_par_uuid(&self, uuid_client: Uuid) -> Result<Option<Uuid>, ErreurCoursier> {
        Ok(sqlx::query_scalar!(
            "SELECT id FROM coursier.preuve_photo WHERE uuid_client = $1",
            uuid_client,
        )
        .fetch_optional(&self.pool)
        .await?)
    }

    /// Clés présignées des photos d'une livraison — lecture d'exploitation
    /// (FR-063). Une photo purgée n'a plus d'octets : elle sort sans URL.
    pub async fn photos_presignees(
        &self,
        livraison: Uuid,
        ttl: std::time::Duration,
    ) -> Result<Vec<PhotoPreuveVue>, ErreurCoursier> {
        let lignes = sqlx::query!(
            r#"SELECT id, cle_objet, prise_le, purgee_le
                 FROM coursier.preuve_photo
                WHERE livraison_id = $1
                ORDER BY prise_le"#,
            livraison,
        )
        .fetch_all(&self.pool)
        .await?;

        let mut vues = Vec::with_capacity(lignes.len());
        for l in lignes {
            // Une photo dont l'objet est parti reste une preuve DATÉE : la
            // masquer ferait disparaître le fait avec les octets.
            let url = match l.purgee_le {
                Some(_) => None,
                None => match self.objets.presigner_get(&l.cle_objet, ttl).await {
                    Ok(u) => Some(u.url),
                    Err(e) => {
                        tracing::warn!(
                            cle = %l.cle_objet, erreur = %e,
                            "photo de preuve non présignable — servie sans URL",
                        );
                        None
                    }
                },
            };
            vues.push(PhotoPreuveVue {
                id: l.id,
                prise_le: l.prise_le,
                purgee_le: l.purgee_le,
                url,
            });
        }
        Ok(vues)
    }

    /// Tout ce que l'exploitation doit voir d'un échec (FR-063).
    ///
    /// C'est ce qui rend les preuves **lisibles** : sans cette lecture, elles
    /// existeraient en base sans que personne ne puisse répondre à un client qui
    /// conteste — et une preuve que personne ne lit ne protège personne.
    ///
    /// Aucune garde de propriété ici : l'appelant est l'exploitation, pas le
    /// coursier. La garde de rôle est faite par la couche HTTP.
    pub async fn preuves_pour_exploitation(
        &self,
        livraison: Uuid,
        ttl_photos: std::time::Duration,
    ) -> Result<PreuvesExploitation, ErreurCoursier> {
        let config = self.config_de_livraison(livraison).await?;
        let etat = self.etat_preuves_avec(livraison, &config).await?;
        Ok(PreuvesExploitation {
            appels: self.appels_de_livraison(livraison).await?,
            photos: self.photos_presignees(livraison, ttl_photos).await?,
            reunies_le: self.reunies_le(livraison).await?,
            etat,
        })
    }

    /// Instant du basculement des trois preuves, s'il a eu lieu.
    async fn reunies_le(&self, livraison: Uuid) -> Result<Option<DateTime<Utc>>, ErreurCoursier> {
        Ok(sqlx::query_scalar!(
            "SELECT reunies_le FROM coursier.preuves_reunies WHERE livraison_id = $1",
            livraison,
        )
        .fetch_optional(&self.pool)
        .await?)
    }

    /// Purge les photos de preuve échues (rétention de zone, FR-064).
    ///
    /// Patron `job_purge_photos_collecte` du cycle 006 : best-effort, un échec
    /// sur un objet ne bloque pas les autres et sera retenté au passage suivant.
    /// La LIGNE est conservée et seulement marquée : l'échec reste prouvé, sa
    /// photo seule disparaît.
    pub async fn purger_photos_preuve(&self) -> Result<u64, ErreurCoursier> {
        let candidats = sqlx::query!(
            r#"SELECT p.id, p.cle_objet, p.prise_le, c.zone_id
                 FROM coursier.preuve_photo p
                 JOIN commandes.livraison l ON l.id = p.livraison_id
                 JOIN commandes.commande c  ON c.id = l.commande_id
                WHERE p.purgee_le IS NULL"#,
        )
        .fetch_all(&self.pool)
        .await?;

        let mut purgees = 0u64;
        for c in candidats {
            let config = ConfigCoursier::charger(&self.zones, c.zone_id).await?;
            let echeance = c.prise_le + chrono::Duration::days(config.retention_photo_preuve_jours);
            if self.maintenant() < echeance {
                continue;
            }
            match self.objets.supprimer(&c.cle_objet).await {
                Ok(()) => {
                    sqlx::query!(
                        "UPDATE coursier.preuve_photo SET purgee_le = now() WHERE id = $1",
                        c.id,
                    )
                    .execute(&self.pool)
                    .await?;
                    purgees += 1;
                }
                Err(e) => tracing::warn!(
                    cle = %c.cle_objet, erreur = %e,
                    "purge d'une photo de preuve échouée — retentée au prochain passage",
                ),
            }
        }
        Ok(purgees)
    }
}

/// **Le** branchement du cycle (contrat §1) : le port que le cycle 008 avait
/// laissé au double `PreuvesFixes` reçoit enfin son implémentation.
///
/// À partir de là, `POST /courses/{id}/echec` et l'écran K4-1e lisent la MÊME
/// fonction. Un échec ne se déclare plus jamais sans preuves — en test comme en
/// production (FR-059, FR-060).
#[async_trait::async_trait]
impl commandes::PreuvesEchec for PgCoursier {
    async fn preuves_reunies(&self, livraison: Uuid) -> Result<bool, commandes::ErreurCommandes> {
        Ok(self.etat_preuves(livraison).await?.reunies)
    }
}

/// Le dossier de preuves d'une livraison, tel que l'exploitation le lit
/// (FR-063).
///
/// ⚠ **Aucun numéro** : le serveur n'en a jamais vu passer. Les appels sont
/// journalisés par leur intention, leur motif et leur issue déclarée — jamais
/// par le numéro composé (R6).
#[derive(Debug, Clone, PartialEq)]
pub struct PreuvesExploitation {
    /// **Tous** les appels journalisés, motifs de suivi compris : l'exploitation
    /// a besoin de voir ce qui n'a pas compté autant que ce qui a compté.
    pub appels: Vec<AppelJournalise>,
    /// Photos de preuve, présignées quand leurs octets existent encore.
    pub photos: Vec<PhotoPreuveVue>,
    /// Instant du basculement — `None` si les trois preuves ne l'ont jamais été.
    pub reunies_le: Option<DateTime<Utc>>,
    /// L'état recalculé des trois preuves, avec ce qui manque.
    pub etat: EtatPreuves,
}

/// Une photo de preuve telle que l'exploitation la lit (FR-063).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PhotoPreuveVue {
    /// Photo.
    pub id: Uuid,
    /// Prise le (horodatage serveur, ou local si l'app l'a déclaré).
    pub prise_le: DateTime<Utc>,
    /// Purgée le — la preuve reste datée, ses octets sont partis.
    pub purgee_le: Option<DateTime<Utc>>,
    /// URL présignée de courte durée. Absente si purgée ou indisponible.
    pub url: Option<String>,
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::modele::{CibleAppel, IssueAppel, MotifAppel};

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

    fn appel(secondes: i64, motif: MotifAppel) -> AppelJournalise {
        AppelJournalise {
            id: Uuid::now_v7(),
            vers: CibleAppel::Client,
            prestataire_id: None,
            motif,
            issue: IssueAppel::SansReponse,
            passe_le: base() + chrono::Duration::seconds(secondes),
            passe_le_local: base() + chrono::Duration::seconds(secondes),
        }
    }

    /// FR-035 — un appel de suivi ne prouve pas une absence. Trois appels de
    /// courtoisie ne doivent pas ouvrir la déclaration d'échec.
    #[test]
    fn seuls_les_appels_client_absent_comptent() {
        let appels = vec![
            appel(0, MotifAppel::Suivi),
            appel(200, MotifAppel::Substitution),
            appel(400, MotifAppel::Suivi),
        ];
        let preuve = composer_preuve_appels(&appels, &config());
        assert_eq!(preuve.faits, 0);
        assert!(!preuve.ok);
        assert_eq!(preuve.motif_cle, Some(motifs::APPELS_AUCUN));
    }

    /// Le cas nominal : deux appels espacés de plus de trois minutes.
    #[test]
    fn deux_appels_bien_espaces_reunissent_la_preuve() {
        let appels = vec![
            appel(0, MotifAppel::ClientAbsent),
            appel(200, MotifAppel::ClientAbsent),
        ];
        let preuve = composer_preuve_appels(&appels, &config());
        assert_eq!(preuve.faits, 2);
        assert!(preuve.espacement_ok);
        assert!(preuve.ok);
        assert_eq!(preuve.horodatages.len(), 2);
        assert_eq!(preuve.issues.len(), 2);
    }

    /// SC-007 — deux appels à quarante secondes d'écart ne valent qu'un appel,
    /// et l'écran doit DIRE que c'est l'espacement qui manque, pas le nombre.
    #[test]
    fn des_appels_trop_rapproches_ne_comptent_que_pour_un() {
        let appels = vec![
            appel(0, MotifAppel::ClientAbsent),
            appel(40, MotifAppel::ClientAbsent),
        ];
        let preuve = composer_preuve_appels(&appels, &config());
        assert_eq!(preuve.faits, 1);
        assert!(!preuve.espacement_ok);
        assert!(!preuve.ok);
        assert_eq!(preuve.motif_cle, Some(motifs::APPELS_TROP_RAPPROCHES));
    }

    /// L'espacement se compte depuis le dernier appel RETENU. Sinon une rafale
    /// de dix appels espacés de deux minutes finirait par tous les valider,
    /// deux minutes à la fois.
    #[test]
    fn l_espacement_se_compte_depuis_le_dernier_retenu() {
        let appels = vec![
            appel(0, MotifAppel::ClientAbsent),   // retenu
            appel(120, MotifAppel::ClientAbsent), // écarté (120 < 180)
            appel(240, MotifAppel::ClientAbsent), // 240 − 0 = 240 ≥ 180 → retenu
            appel(300, MotifAppel::ClientAbsent), // écarté (300 − 240 = 60)
        ];
        let retenus = appels_retenus(&appels, 180);
        assert_eq!(retenus.len(), 2);
        assert_eq!(retenus[1].passe_le, base() + chrono::Duration::seconds(240));
    }

    /// Le compte n'y est pas, mais rien n'a été écarté : le motif doit orienter
    /// vers « rappelle », pas vers « attends ».
    #[test]
    fn un_seul_appel_bien_espace_dit_qu_il_en_manque() {
        let appels = vec![appel(0, MotifAppel::ClientAbsent)];
        let preuve = composer_preuve_appels(&appels, &config());
        assert_eq!(preuve.faits, 1);
        assert!(preuve.espacement_ok);
        assert_eq!(preuve.motif_cle, Some(motifs::APPELS_MANQUANTS));
    }

    /// L'issue déclarée n'entre JAMAIS dans le calcul (R19) : un coursier qui
    /// déclare « répondu » garde ses preuves, il informe seulement.
    #[test]
    fn l_issue_declaree_ne_change_aucun_critere() {
        let mut appels = vec![
            appel(0, MotifAppel::ClientAbsent),
            appel(200, MotifAppel::ClientAbsent),
        ];
        let avec_sans_reponse = composer_preuve_appels(&appels, &config());
        appels[0].issue = IssueAppel::Repondu;
        appels[1].issue = IssueAppel::Inconnue;
        let avec_repondu = composer_preuve_appels(&appels, &config());
        assert_eq!(avec_sans_reponse.faits, avec_repondu.faits);
        assert_eq!(avec_sans_reponse.ok, avec_repondu.ok);
    }
}
