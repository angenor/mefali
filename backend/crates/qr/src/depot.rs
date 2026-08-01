//! Racine de composition du domaine QR (`PgQr`, data-model §4.2).
//!
//! Compose le pool + le socle logistique (`PgCommandes`) + le domaine
//! prestataires (`PgPrestataires`, résolution/identité de plaque) + la
//! configuration de zone (`PgZones`) + le port objets (`DepotObjets`, PDF +
//! photo) + le port compteur d'essais (`CompteurEssais`, Redis). Les impls
//! réelles sont câblées dans `api::run` (racine de composition applicative).

use std::sync::Arc;

use chrono::Utc;
use commandes::{ArretACollecter, EtatLivraison, ModeCollecte, PgCommandes, StatutArret};
use prestataires::PgPrestataires;
use serde_json::json;
use socle::{ecrire_evenement, DepotObjets, NouvelEvenement, UrlPresignee};
use sqlx::PgPool;
use uuid::Uuid;
use zones::{ConfigurationZones, PgZones};

use crate::modele::{
    ArretPreProvisionne, DemandeCollecte, ErreurQr, PlaqueResolue, ResultatCollecte,
};
use crate::ports::CompteurEssais;
use crate::{plaque, verification};

/// TTL des URL présignées de lecture (patron `prestataires::consultation`, R9).
pub(crate) const PRESIGNEE_TTL: std::time::Duration = std::time::Duration::from_secs(10 * 60);

/// Handle de dépôt du domaine QR. Clone bon marché (pool et ports partagés).
#[derive(Clone)]
pub struct PgQr {
    pub(crate) pool: PgPool,
    pub(crate) commandes: PgCommandes,
    pub(crate) prestataires: PgPrestataires,
    pub(crate) zones: PgZones,
    pub(crate) objets: Arc<dyn DepotObjets>,
    pub(crate) essais: Arc<dyn CompteurEssais>,
}

impl PgQr {
    /// Compose le dépôt QR. `PgZones` est dérivé du pool (même base) ;
    /// `PgCommandes`/`PgPrestataires` sont injectés déjà composés par la racine.
    pub fn new(
        pool: PgPool,
        commandes: PgCommandes,
        prestataires: PgPrestataires,
        objets: Arc<dyn DepotObjets>,
        essais: Arc<dyn CompteurEssais>,
    ) -> Self {
        Self {
            zones: PgZones::new(pool.clone()),
            pool,
            commandes,
            prestataires,
            objets,
            essais,
        }
    }

    /// Accès au pool applicatif.
    pub fn pool(&self) -> &PgPool {
        &self.pool
    }

    // ── QRC-01 : PDF de plaque ─────────────────────────────────────────────

    /// Compose le PDF de plaque, le dépose (Garage), émet `plaque.generee` et
    /// renvoie l'URL présignée. Refuse si le prestataire n'a pas d'identité de
    /// plaque (jamais agréé, FR-011 → `plaque_absente`).
    pub async fn plaque_pdf(
        &self,
        prestataire_id: Uuid,
        acteur: Uuid,
    ) -> Result<UrlPresignee, ErreurQr> {
        let ctx = self
            .prestataires
            .contexte_plaque(prestataire_id)
            .await?
            .ok_or(ErreurQr::PlaqueAbsente)?;
        let cle = format!("qr/plaques/{prestataire_id}.pdf");
        // Régénération : l'objet existait-il déjà ? `existe` (HEAD) est fiable en
        // prod S3, contrairement à `presigner_get` (calcul local, toujours OK).
        let regeneration = self.objets.existe(&cle).await?;
        let pdf = plaque::composer_plaque_pdf(
            prestataire_id,
            &ctx.nom,
            &ctx.jeton_plaque,
            &ctx.code_secours,
        );
        self.objets.deposer(&cle, pdf, "application/pdf").await?;
        let url = self.objets.presigner_get(&cle, PRESIGNEE_TTL).await?;

        // La génération est une transition tracée par l'événement (pas de table
        // de métadonnées, R9) : écrit dans sa propre transaction.
        let mut tx = self.pool.begin().await?;
        ecrire_evenement(
            &mut tx,
            NouvelEvenement {
                type_evenement: "plaque.generee",
                entite_type: "plaque",
                entite_id: prestataire_id,
                payload: json!({
                    "prestataire": prestataire_id,
                    "format": "pdf",
                    "regeneration": regeneration,
                    "acteur": acteur,
                }),
                survenu_le: Utc::now(),
            },
        )
        .await?;
        tx.commit().await?;
        Ok(url)
    }

    // ── QRC-02 : pré-provisionnement hors-ligne ────────────────────────────

    /// Empreintes + sites + montants + politique photo résolue de tous les
    /// arrêts de la course active du coursier (R6). Vide si aucune course
    /// assignée (exact en prod avant DSP).
    pub async fn pre_provisionnement(
        &self,
        coursier: Uuid,
    ) -> Result<Vec<ArretPreProvisionne>, ErreurQr> {
        let arrets = self.commandes.arrets_course_active(coursier).await?;
        let mut sortie = Vec::with_capacity(arrets.len());
        for a in arrets {
            let Some(ctx) = self.prestataires.contexte_plaque(a.prestataire_id).await? else {
                continue; // prestataire sans plaque (jamais agréé) — arrêt ignoré
            };
            let seuil = self
                .parametre_int(ctx.ville_id, "qr.photo_seuil_montant")
                .await?
                .unwrap_or(i64::MAX);
            let distance_max_m = self
                .parametre_int(ctx.ville_id, "qr.distance_scan_max_m")
                .await?
                .unwrap_or(100);
            let photo_exigee =
                verification::photo_exigee(&ctx.politique_photo_base, a.montant_avance, seuil);
            sortie.push(ArretPreProvisionne {
                arret_id: a.arret_id,
                prestataire_id: a.prestataire_id,
                nom: ctx.nom,
                empreinte_jeton: verification::empreinte_jeton(&ctx.jeton_plaque),
                empreinte_code: verification::empreinte_code(a.prestataire_id, &ctx.code_secours),
                site_lat: a.site_lat,
                site_lon: a.site_lon,
                montant_avance: a.montant_avance,
                devise: a.devise,
                photo_exigee,
                distance_max_m,
            });
        }
        Ok(sortie)
    }

    /// Plaque résolue d'un SEUL prestataire, pour un montant d'arrêt donné
    /// (cycle CRS 010).
    ///
    /// `pre_provisionnement` ne rend que les arrêts **restant à collecter**
    /// d'une livraison **`en_collecte`** : c'est exactement ce dont le cycle 006
    /// avait besoin, et exactement ce qui ne suffit plus. La course complète du
    /// cycle 010 porte aussi les arrêts DÉJÀ collectés (K3-1b les affiche
    /// repliés, avec leur heure) et démarre dès l'état `assignee`.
    ///
    /// Plutôt que d'élargir le filtre de `pre_provisionnement` — ce qui
    /// changerait le contrat d'un endpoint en service — la résolution unitaire
    /// est exposée telle quelle. La politique photo reste décidée **ici**,
    /// c'est-à-dire dans le domaine à qui elle appartient.
    ///
    /// `None` = prestataire jamais agréé (aucune identité de plaque).
    pub async fn plaque_resolue(
        &self,
        prestataire_id: Uuid,
        montant_avance: i64,
    ) -> Result<Option<PlaqueResolue>, ErreurQr> {
        let Some(ctx) = self.prestataires.contexte_plaque(prestataire_id).await? else {
            return Ok(None);
        };
        let seuil = self
            .parametre_int(ctx.ville_id, "qr.photo_seuil_montant")
            .await?
            .unwrap_or(i64::MAX);
        let distance_max_m = self
            .parametre_int(ctx.ville_id, "qr.distance_scan_max_m")
            .await?
            .unwrap_or(100);
        Ok(Some(PlaqueResolue {
            nom: ctx.nom,
            empreinte_jeton: verification::empreinte_jeton(&ctx.jeton_plaque),
            empreinte_code: verification::empreinte_code(prestataire_id, &ctx.code_secours),
            photo_exigee: verification::photo_exigee(
                &ctx.politique_photo_base,
                montant_avance,
                seuil,
            ),
            distance_max_m,
        }))
    }

    // ── QRC-02/03/04 : collecte d'un arrêt ─────────────────────────────────

    /// Vérifie (résolution du jeton | code dégradé, proximité, photo, 3 essais),
    /// puis bascule l'arrêt en COLLECTÉ via `commandes::marquer_arret_collecte`.
    /// Idempotent par `uuid_client` ; crée l'incident au 1er passage dégradé.
    pub async fn collecter(
        &self,
        coursier: Uuid,
        demande: DemandeCollecte,
    ) -> Result<ResultatCollecte, ErreurQr> {
        // 1. Idempotence : issue déjà enregistrée pour ce uuid_client ?
        if let Some(resultat) = self.issue_enregistree(demande.uuid_client).await? {
            return self.rejouer_issue(demande.arret_id, &resultat).await;
        }

        // 2. Précondition : arrêt de la course active du coursier (FR-012).
        let arret = self
            .commandes
            .arret_de_coursier(coursier, demande.arret_id)
            .await?
            .ok_or(ErreurQr::ArretHorsCourse)?;

        // 3. Contexte du prestataire (identité + politique photo).
        let ctx = self
            .prestataires
            .contexte_plaque(arret.prestataire_id)
            .await?
            .ok_or(ErreurQr::PlaqueInvalide)?;

        // 4. Proximité (porte de présence anti-fraude, R3) — VÉRIFIÉE AVANT la
        //    vérification de mode : un refus `hors_zone` ne doit ni consommer un
        //    essai de code dégradé ni résoudre le jeton (le coursier n'est pas
        //    sur place).
        let max_m = self
            .parametre_int(ctx.ville_id, "qr.distance_scan_max_m")
            .await?
            .unwrap_or(100);
        let distance = verification::distance_grand_cercle_m(
            demande.position_lat,
            demande.position_lon,
            arret.site_lat,
            arret.site_lon,
        );
        if distance > max_m as f64 {
            return self.rejeter_definitif(&arret, &demande, "hors_zone", coursier).await;
        }
        let distance_m = distance.round() as i32;

        // 5. Vérification selon le mode.
        match demande.mode {
            ModeCollecte::ScanQr => {
                let jeton = demande
                    .jeton
                    .as_deref()
                    .ok_or(ErreurQr::DemandeInvalide("jeton absent en mode scan"))?;
                match self.prestataires.resolution_plaque(jeton).await? {
                    None => return Err(ErreurQr::PlaqueInvalide),
                    // Jeton d'un AUTRE prestataire que celui de l'arrêt : refus.
                    Some(r) if r.prestataire_id != arret.prestataire_id => {
                        return Err(ErreurQr::PlaqueInvalide)
                    }
                    // Prestataire suspendu (révocation observée, QRC-03) : refus
                    // DÉFINITIF (réconciliation hors-ligne — arret.collecte_rejetee).
                    Some(r) if !r.valide => {
                        return self.rejeter_definitif(&arret, &demande, "jeton_revoque", coursier).await
                    }
                    Some(_) => {}
                }
            }
            ModeCollecte::CodeSecours => {
                // Incident « plaque à remplacer » dès le 1er passage dégradé
                // (Q2), UNE fois par arrêt.
                self.incident_si_absent(&arret, coursier).await?;
                let essais = self
                    .essais
                    .incrementer_essai(arret.arret_id)
                    .await
                    .map_err(|e| ErreurQr::Compteur(e.0))?;
                // 3 essais réels (FR-020, « 3 essais max ») : les tentatives 1,
                // 2 et 3 comparent le code ; au-DELÀ du 3ᵉ (backstop en ligne et
                // au rejeu), épuisé. L'app borne localement à 3 saisies
                // (`_maxEssais = 3`) — ce seuil doit rester aligné.
                if essais > 3 {
                    return self.rejeter_definitif(&arret, &demande, "code_epuise", coursier).await;
                }
                let code = demande
                    .code
                    .as_deref()
                    .ok_or(ErreurQr::DemandeInvalide("code absent en mode dégradé"))?;
                // Révocation observée aussi en dégradé (défensif).
                if matches!(
                    self.prestataires.resolution_plaque(&ctx.jeton_plaque).await?,
                    Some(r) if !r.valide
                ) {
                    return self.rejeter_definitif(&arret, &demande, "jeton_revoque", coursier).await;
                }
                // Comparaison au code du prestataire de l'arrêt (jamais globale).
                // Refus RETRYABLE : ni enregistrement, ni événement.
                if code != ctx.code_secours {
                    return Err(ErreurQr::CodeIncorrect);
                }
            }
        }

        // 6. Politique photo résolue (R4).
        let seuil = self
            .parametre_int(ctx.ville_id, "qr.photo_seuil_montant")
            .await?
            .unwrap_or(i64::MAX);
        let photo_exigee =
            verification::photo_exigee(&ctx.politique_photo_base, arret.montant_avance, seuil);
        let photo_cle = if photo_exigee {
            // Refus RETRYABLE (le coursier reprend une photo).
            let octets = demande.photo.clone().ok_or(ErreurQr::PhotoRequise)?;
            let cle = format!("qr/collectes/{}.jpg", arret.arret_id);
            self.objets.deposer(&cle, octets, "image/jpeg").await?;
            Some(cle)
        } else {
            None
        };

        // 7. Succès : bascule + événements + registre d'idempotence (même tx).
        let horodatage = Utc::now();
        let mut tx = self.pool.begin().await?;
        let progression = match self
            .commandes
            .marquer_arret_collecte(
                &mut tx,
                arret.arret_id,
                demande.uuid_client,
                demande.mode,
                photo_cle.as_deref(),
                distance_m,
                horodatage,
                coursier,
            )
            .await
        {
            Ok(p) => p,
            // Arrêt déjà collecté par un autre uuid (course concurrente) :
            // refus DÉFINITIF.
            Err(commandes::ErreurCommandes::EtatIncompatible { .. }) => {
                tx.rollback().await?;
                return self
                    .rejeter_definitif(&arret, &demande, "etat_incompatible", coursier)
                    .await;
            }
            Err(e) => {
                tx.rollback().await?;
                return Err(e.into());
            }
        };
        self.enregistrer_issue(&mut tx, demande.uuid_client, arret.arret_id, "collecte")
            .await?;
        tx.commit().await?;

        Ok(ResultatCollecte {
            arret_statut: StatutArret::Collecte,
            livraison_etat: if progression.en_livraison {
                EtatLivraison::EnLivraison
            } else {
                EtatLivraison::EnCollecte
            },
            nb_collectes: progression.nb_collectes,
            nb_arrets: progression.nb_arrets,
            en_livraison: progression.en_livraison,
        })
    }

    // ── Purge des photos de récupération (constitution VIII, T044) ─────────

    /// Supprime les photos de récupération dont la collecte dépasse la rétention
    /// de zone (`qr.retention_photo_collecte_jours`). Best-effort (patron du
    /// repère vocal R8) : un échec laisse un orphelin à rattraper, jamais une
    /// incohérence. Renvoie le nombre de photos purgées.
    pub async fn purger_photos_collecte(&self) -> Result<u64, ErreurQr> {
        let candidats = sqlx::query!(
            r#"SELECT a.id, a.photo_cle AS "photo_cle!", a.collecte_le AS "collecte_le!",
                      p.ville_id
               FROM commandes.arret a
               JOIN prestataires.prestataire p ON p.id = a.prestataire_id
               WHERE a.photo_cle IS NOT NULL AND a.collecte_le IS NOT NULL"#,
        )
        .fetch_all(&self.pool)
        .await?;

        let mut purgees = 0u64;
        for c in candidats {
            let jours = self
                .parametre_int(c.ville_id, "qr.retention_photo_collecte_jours")
                .await?
                .unwrap_or(365);
            let echeance = c.collecte_le + chrono::Duration::days(jours);
            if Utc::now() >= echeance {
                // Best-effort : un échec de suppression sur UN objet est
                // journalisé et n'interrompt PAS la purge des autres (la clé
                // reste, retentée au prochain passage). Ne déréférence en base
                // que si la suppression a réussi.
                match self.objets.supprimer(&c.photo_cle).await {
                    Ok(()) => {
                        sqlx::query!(
                            "UPDATE commandes.arret SET photo_cle = NULL WHERE id = $1",
                            c.id,
                        )
                        .execute(&self.pool)
                        .await?;
                        purgees += 1;
                    }
                    Err(e) => tracing::warn!(
                        cle = %c.photo_cle,
                        erreur = %e,
                        "purge d'une photo de récupération échouée — retentée au prochain passage",
                    ),
                }
            }
        }
        Ok(purgees)
    }

    // ── Helpers internes ───────────────────────────────────────────────────

    /// Lit un paramètre de zone hérité comme entier (`None` si absent/illisible).
    async fn parametre_int(&self, zone: Uuid, cle: &str) -> Result<Option<i64>, ErreurQr> {
        Ok(self.zones.parametre(zone, cle).await?.and_then(|v| v.as_i64()))
    }

    /// Issue enregistrée pour un `uuid_client` (`collecte` | `rejet:<motif>`).
    async fn issue_enregistree(&self, uuid_client: Uuid) -> Result<Option<String>, ErreurQr> {
        Ok(sqlx::query_scalar!(
            "SELECT resultat FROM qr.action_traitee WHERE uuid_client = $1",
            uuid_client,
        )
        .fetch_optional(&self.pool)
        .await?)
    }

    /// Rejeu idempotent : reconstruit l'issue enregistrée sans nouvelle écriture
    /// ni événement (V — le serveur fait foi une seule fois).
    async fn rejouer_issue(
        &self,
        arret_id: Uuid,
        resultat: &str,
    ) -> Result<ResultatCollecte, ErreurQr> {
        if resultat == "collecte" {
            return self.resultat_arret(arret_id).await;
        }
        // `rejet:<motif>` → même refus, aucun événement.
        let motif = resultat.strip_prefix("rejet:").unwrap_or(resultat);
        Err(Self::erreur_de_motif(motif))
    }

    /// Reconstruit `ResultatCollecte` depuis l'état courant de la livraison.
    ///
    /// ⚠ Ne compte que les arrêts de type `collecte` (cycle CMD 008, P1 /
    /// research R4) : la remise est un arrêt du segment, mais ce n'est pas une
    /// collecte. Sans ce filtre, l'écran coursier annoncerait « 2 sur 3 » pour
    /// une course de 2 collectes et ne verrait jamais sa progression complète.
    async fn resultat_arret(&self, arret_id: Uuid) -> Result<ResultatCollecte, ErreurQr> {
        let row = sqlx::query!(
            r#"SELECT l.etat::text AS "etat!",
                      (SELECT count(*) FROM commandes.arret a2
                         JOIN commandes.segment s2 ON s2.id = a2.segment_id
                         WHERE s2.livraison_id = l.id
                           AND a2.type_arret = 'collecte') AS "total!",
                      (SELECT count(*) FROM commandes.arret a2
                         JOIN commandes.segment s2 ON s2.id = a2.segment_id
                         WHERE s2.livraison_id = l.id AND a2.statut = 'collecte'
                           AND a2.type_arret = 'collecte') AS "collectes!"
               FROM commandes.arret a
               JOIN commandes.segment s ON s.id = a.segment_id
               JOIN commandes.livraison l ON l.id = s.livraison_id
               WHERE a.id = $1"#,
            arret_id,
        )
        .fetch_one(&self.pool)
        .await?;
        let en_livraison = row.etat == "en_livraison";
        Ok(ResultatCollecte {
            arret_statut: StatutArret::Collecte,
            livraison_etat: if en_livraison {
                EtatLivraison::EnLivraison
            } else {
                EtatLivraison::EnCollecte
            },
            nb_collectes: row.collectes as i16,
            nb_arrets: row.total as i16,
            en_livraison,
        })
    }

    /// Refus DÉFINITIF (réconciliation hors-ligne) : enregistre l'issue et émet
    /// `arret.collecte_rejetee` UNE fois (rejeu du même uuid → rien).
    async fn rejeter_definitif(
        &self,
        arret: &ArretACollecter,
        demande: &DemandeCollecte,
        motif: &str,
        acteur: Uuid,
    ) -> Result<ResultatCollecte, ErreurQr> {
        let mut tx = self.pool.begin().await?;
        let insere = sqlx::query!(
            "INSERT INTO qr.action_traitee (uuid_client, arret_id, resultat)
             VALUES ($1, $2, $3) ON CONFLICT (uuid_client) DO NOTHING",
            demande.uuid_client,
            arret.arret_id,
            format!("rejet:{motif}"),
        )
        .execute(&mut *tx)
        .await?
        .rows_affected();

        if insere == 1 {
            ecrire_evenement(
                &mut tx,
                NouvelEvenement {
                    type_evenement: "arret.collecte_rejetee",
                    entite_type: "arret",
                    entite_id: arret.arret_id,
                    payload: json!({
                        "commande": arret.commande_id,
                        "mode": demande.mode.comme_str(),
                        "motif": motif,
                        "horodatage_client": demande.horodatage_local,
                        "acteur": acteur,
                    }),
                    survenu_le: Utc::now(),
                },
            )
            .await?;
        }
        tx.commit().await?;
        Err(Self::erreur_de_motif(motif))
    }

    /// Crée l'incident « plaque à remplacer » s'il n'existe pas encore pour
    /// l'arrêt (UNIQUE arret) et émet `plaque.remplacement_requis` une fois (Q2).
    async fn incident_si_absent(
        &self,
        arret: &ArretACollecter,
        coursier: Uuid,
    ) -> Result<(), ErreurQr> {
        let mut tx = self.pool.begin().await?;
        let insere = sqlx::query!(
            "INSERT INTO qr.incident_plaque (id, prestataire_id, arret_id, coursier_id)
             VALUES ($1, $2, $3, $4) ON CONFLICT (arret_id) DO NOTHING",
            Uuid::now_v7(),
            arret.prestataire_id,
            arret.arret_id,
            coursier,
        )
        .execute(&mut *tx)
        .await?
        .rows_affected();

        if insere == 1 {
            ecrire_evenement(
                &mut tx,
                NouvelEvenement {
                    type_evenement: "plaque.remplacement_requis",
                    entite_type: "plaque",
                    entite_id: arret.prestataire_id,
                    payload: json!({
                        "prestataire": arret.prestataire_id,
                        "origine": "qr_illisible",
                        "commande": arret.commande_id,
                        "arret": arret.arret_id,
                        "automatique": true,
                        "acteur": coursier,
                    }),
                    survenu_le: Utc::now(),
                },
            )
            .await?;
        }
        tx.commit().await?;
        Ok(())
    }

    /// Enregistre l'issue d'un `uuid_client` dans la transaction courante.
    async fn enregistrer_issue(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        uuid_client: Uuid,
        arret_id: Uuid,
        resultat: &str,
    ) -> Result<(), ErreurQr> {
        // ON CONFLICT DO NOTHING : deux rejeux CONCURRENTS du même uuid_client
        // (l'un enregistrant l'issue avant que l'autre ne lise le registre) ne
        // doivent pas lever une violation de clé primaire (500) — l'idempotence
        // tient malgré la course (V).
        sqlx::query!(
            "INSERT INTO qr.action_traitee (uuid_client, arret_id, resultat)
             VALUES ($1, $2, $3) ON CONFLICT (uuid_client) DO NOTHING",
            uuid_client,
            arret_id,
            resultat,
        )
        .execute(&mut **tx)
        .await?;
        Ok(())
    }

    /// Mappe un motif enregistré vers l'erreur métier correspondante.
    fn erreur_de_motif(motif: &str) -> ErreurQr {
        match motif {
            "jeton_revoque" => ErreurQr::PrestataireIndisponible,
            "hors_zone" => ErreurQr::HorsZone,
            "etat_incompatible" => ErreurQr::EtatIncompatible,
            "code_epuise" => ErreurQr::CodeEpuise,
            _ => ErreurQr::EtatIncompatible,
        }
    }
}

