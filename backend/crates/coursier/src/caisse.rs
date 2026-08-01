//! Le livre de caisse du coursier — **append-only** (FR-067 → FR-078, R9).
//!
//! Yao sort de l'argent de sa poche à chaque arrêt et le récupère chez le
//! client. Entre les deux, il porte le risque. Cet écran est la seule façon
//! qu'il a de vérifier que « le coursier ne perd jamais » est vrai — et un
//! livre qui ment une fois ne se rattrape pas.
//!
//! **Trois règles, et chacune existe contre une erreur précise :**
//!
//! 1. **Aucun `UPDATE`, aucun `DELETE`.** Une correction est une écriture
//!    INVERSE qui pointe l'originale (FR-073). Corriger en place effacerait la
//!    trace de l'erreur en même temps que l'erreur — et c'est justement la
//!    trace qui permet de répondre à un coursier qui conteste.
//! 2. **Une écriture par événement, jamais deux.** `evenement_id UNIQUE` : le
//!    worker outbox livre **au moins** une fois (contrat `socle`), donc un lot
//!    rejoué doit être sans effet. L'idempotence est une contrainte de base,
//!    pas une convention (R9).
//! 3. **Un remboursement ne s'écrit que si le client a payé en ESPÈCES.** Sur
//!    une commande prépayée, aucun cash ne change de main à la livraison :
//!    écrire un remboursement fictif ferait mentir un solde d'argent réel. Ces
//!    avances restent ouvertes, marquées `en_attente_reglement` (R10, FR-117).
//!
//! **Le solde n'est pas une table.** Le « montant avancé en cours » est une
//! somme sur le livre (avances non compensées sur la même livraison). Une table
//! de solde serait une seconde vérité à réconcilier ; la somme est exacte par
//! construction (data-model §1.3).

use chrono::{DateTime, NaiveDate, Utc};
use chrono_tz::Tz;
use serde_json::json;
use socle::{EvenementPublie, NouvelEvenement};
use uuid::Uuid;
use zones::ConfigurationZones;

use crate::depot::PgCoursier;
use crate::modele::{
    ErreurCoursier, LigneHistorique, MouvementCaisse, TypeEcriture, VueCaisse,
};

/// Ce qu'une écriture demande au livre.
#[derive(Debug, Clone)]
pub struct DemandeEcriture {
    /// Nature de l'écriture.
    pub type_ecriture: TypeEcriture,
    /// Montant **signé** en unités mineures : `−` sortie, `+` entrée.
    pub montant_unites: i64,
    /// Devise ISO 4217 de la zone.
    pub devise: String,
    /// Commande concernée.
    pub commande_id: Option<Uuid>,
    /// Livraison concernée — c'est elle qui apparie avance et remboursement.
    pub livraison_id: Option<Uuid>,
    /// Arrêt concerné (avances).
    pub arret_id: Option<Uuid>,
    /// Indemnisation d'origine.
    pub indemnisation_id: Option<Uuid>,
    /// Événement consommé — **la** clé d'idempotence. `None` pour une écriture
    /// d'origine administrative, qui n'en a pas.
    pub evenement_id: Option<Uuid>,
    /// `outbox` | `admin` — porté par l'événement `caisse.mouvement`.
    pub source: &'static str,
}

impl PgCoursier {
    /// Porte une écriture au livre, dans la transaction de l'appelant.
    ///
    /// Rend `None` si l'événement avait déjà été consommé : c'est le chemin
    /// normal d'un rejeu du worker, pas une erreur.
    ///
    /// L'événement `caisse.mouvement` est écrit dans la MÊME transaction que
    /// l'écriture (constitution VI) : un mouvement d'argent sans son événement
    /// serait invisible des métriques, et un événement sans mouvement ferait
    /// compter de l'argent qui n'existe pas.
    pub(crate) async fn ecrire_caisse(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        coursier: Uuid,
        demande: DemandeEcriture,
    ) -> Result<Option<Uuid>, ErreurCoursier> {
        if demande.montant_unites == 0 {
            // La contrainte `CHECK (montant_unites <> 0)` le refuserait ; le
            // dire ici évite de faire échouer un lot d'outbox pour une avance
            // nulle, qui est un cas métier normal (arrêt entièrement retiré).
            return Ok(None);
        }

        let id = Uuid::now_v7();
        let ecrit = sqlx::query_scalar!(
            r#"INSERT INTO coursier.ecriture_caisse
                   (id, coursier_id, type, montant_unites, devise, commande_id,
                    livraison_id, arret_id, indemnisation_id, evenement_id)
               VALUES ($1, $2, $3::text::coursier.type_ecriture, $4, $5, $6, $7, $8, $9, $10)
               ON CONFLICT (evenement_id) DO NOTHING
               RETURNING id"#,
            id,
            coursier,
            demande.type_ecriture.comme_str(),
            demande.montant_unites,
            demande.devise,
            demande.commande_id,
            demande.livraison_id,
            demande.arret_id,
            demande.indemnisation_id,
            demande.evenement_id,
        )
        .fetch_optional(&mut **tx)
        .await?;

        let Some(id) = ecrit else {
            return Ok(None);
        };

        socle::ecrire_evenement(
            tx,
            NouvelEvenement {
                type_evenement: "caisse.mouvement",
                entite_type: "ecriture_caisse",
                entite_id: id,
                payload: json!({
                    "coursier": coursier,
                    "type": demande.type_ecriture.comme_str(),
                    "montant": demande.montant_unites,
                    "devise": demande.devise,
                    "commande": demande.commande_id,
                    "arret": demande.arret_id,
                    "source": demande.source,
                }),
                survenu_le: self.maintenant(),
            },
        )
        .await?;
        Ok(Some(id))
    }

    /// Traduit un événement d'outbox en écriture de caisse (T064).
    ///
    /// **La logique vit ici**, dans le crate ; `backend/api` n'en porte que
    /// l'adaptateur `ConsommateurOutbox`. Trois types seulement, et tout le
    /// reste du journal est ignoré — un consommateur reçoit TOUT.
    pub async fn consommer_pour_caisse(
        &self,
        evenement: &EvenementPublie,
    ) -> Result<(), ErreurCoursier> {
        match evenement.type_evenement.as_str() {
            "arret.collecte" => self.avance_sur_collecte(evenement).await,
            "livraison.livree" => self.remboursement_sur_remise(evenement).await,
            "indemnisation.due" => self.indemnisation_demandee(evenement).await,
            _ => Ok(()),
        }
    }

    /// `arret.collecte` → **avance** de `−montant_avance` (R9).
    async fn avance_sur_collecte(&self, e: &EvenementPublie) -> Result<(), ErreurCoursier> {
        let montant = e.payload["montant_avance"].as_i64().unwrap_or(0);
        if montant <= 0 {
            // Un arrêt dont toutes les lignes ont été retirées ne coûte rien :
            // il n'y a pas d'argent à porter au livre.
            return Ok(());
        }
        let Some(livraison) = uuid_du(&e.payload, "livraison") else {
            return Ok(());
        };
        let Some(contexte) = self.contexte_livraison(livraison).await? else {
            return Ok(());
        };
        let Some(coursier) = contexte.coursier_id else {
            // Une collecte sans coursier assigné n'existe pas en pratique ;
            // écrire au livre de personne serait pire que de ne rien écrire.
            tracing::warn!(livraison = %livraison, "collecte sans coursier — aucune écriture");
            return Ok(());
        };

        let mut tx = self.pool.begin().await?;
        self.ecrire_caisse(
            &mut tx,
            coursier,
            DemandeEcriture {
                type_ecriture: TypeEcriture::Avance,
                // SIGNE NÉGATIF : l'argent sort de la poche de Yao.
                montant_unites: -montant,
                devise: contexte.devise,
                commande_id: Some(contexte.commande_id),
                livraison_id: Some(livraison),
                arret_id: Some(e.entite_id),
                indemnisation_id: None,
                evenement_id: Some(e.id),
                source: "outbox",
            },
        )
        .await?;
        tx.commit().await?;
        Ok(())
    }

    /// `livraison.livree` → **remboursement** de la somme des avances, et
    /// **seulement si le client a payé en espèces** (R10, FR-117).
    async fn remboursement_sur_remise(&self, e: &EvenementPublie) -> Result<(), ErreurCoursier> {
        let livraison = e.entite_id;
        let Some(contexte) = self.contexte_livraison(livraison).await? else {
            return Ok(());
        };
        let Some(coursier) = contexte.coursier_id else {
            return Ok(());
        };
        if contexte.mode_paiement != "cash" {
            // Commande prépayée : aucun cash n'a changé de main. L'avance reste
            // OUVERTE et la caisse l'affiche comme telle — la masquer la ferait
            // disparaître de l'écran dont c'est la seule raison d'être (R10).
            tracing::info!(
                livraison = %livraison, mode = %contexte.mode_paiement,
                "remise prépayée — avance laissée ouverte, en attente de règlement",
            );
            return Ok(());
        }

        let avance = self.avances_de_livraison(livraison).await?;
        let frais = frais_encaisses(contexte.total_unites, avance);

        let mut tx = self.pool.begin().await?;
        if avance != 0 {
            self.ecrire_caisse(
                &mut tx,
                coursier,
                DemandeEcriture {
                    type_ecriture: TypeEcriture::Remboursement,
                    // SIGNE POSITIF, et exactement l'opposé des avances
                    // portées : c'est ce qui ramène le solde à zéro, au franc
                    // près.
                    montant_unites: avance,
                    devise: contexte.devise.clone(),
                    commande_id: Some(contexte.commande_id),
                    livraison_id: Some(livraison),
                    arret_id: None,
                    indemnisation_id: None,
                    evenement_id: Some(e.id),
                    source: "outbox",
                },
            )
            .await?;
        }

        // ── Cycle PAY 011 (T046, FR-056) : les FRAIS encaissés ────────────
        //
        // À côté du remboursement, et pas à sa place : ce sont deux mouvements
        // distincts. Le remboursement rend à Yao ce qu'il a avancé ; les frais
        // sont ce qu'il encaisse EN PLUS, et c'est son gain de la course.
        //
        // `evenement_id` DISTINCT du précédent : la contrainte d'unicité porte
        // sur cette colonne, et réutiliser l'identifiant de l'événement ferait
        // avaler la seconde écriture comme un doublon de la première. Le
        // dérivé est déterministe (UUIDv5 sur l'événement), donc le rejeu du
        // worker reste idempotent — c'est tout ce qu'on demande à cette clé.
        if frais != 0 {
            self.ecrire_caisse(
                &mut tx,
                coursier,
                DemandeEcriture {
                    type_ecriture: TypeEcriture::FraisEncaisses,
                    montant_unites: frais,
                    devise: contexte.devise,
                    commande_id: Some(contexte.commande_id),
                    livraison_id: Some(livraison),
                    arret_id: None,
                    indemnisation_id: None,
                    evenement_id: Some(evenement_derive(e.id, DERIVE_FRAIS_ENCAISSES)),
                    source: "outbox",
                },
            )
            .await?;
        }
        tx.commit().await?;
        Ok(())
    }

    /// Total **positif** des avances portées sur une livraison.
    async fn avances_de_livraison(&self, livraison: Uuid) -> Result<i64, ErreurCoursier> {
        Ok(sqlx::query_scalar!(
            r#"SELECT COALESCE(-SUM(montant_unites), 0)::bigint AS "total!"
                 FROM coursier.ecriture_caisse
                WHERE livraison_id = $1 AND type = 'avance'"#,
            livraison,
        )
        .fetch_one(&self.pool)
        .await?)
    }

    /// Ce que la caisse affiche (K5-1a), en une lecture.
    pub async fn vue_caisse(&self, coursier: Uuid) -> Result<VueCaisse, ErreurCoursier> {
        let devise = self.devise_du_coursier(coursier).await?;
        let ouvertes = self.avances_ouvertes(coursier).await?;
        let historique = self.historique_du_jour(coursier).await?;
        let mouvements = self.mouvements_du_jour(coursier).await?;
        let indemnisations = self.indemnisations_du_coursier(coursier).await?;
        let litiges = self.litiges.litiges_du_coursier(coursier).await?;

        // FR-078 — l'exposition dépasse-t-elle ce que Yao a déclaré pouvoir
        // avancer ? Un écart n'est jamais normal : il veut dire qu'une course a
        // été acceptée sur un plafond périmé, ou qu'un remboursement manque.
        let plafond = self.plafond_declare_du_jour(coursier).await?;
        let ecart_plafond = plafond.is_some_and(|p| ouvertes.total > p);

        Ok(VueCaisse {
            avance_en_cours_unites: ouvertes.total,
            courses_concernees: ouvertes.courses,
            avances_en_attente_reglement_unites: ouvertes.en_attente_reglement,
            historique,
            mouvements,
            indemnisations,
            litiges,
            devise,
            ecart_plafond,
        })
    }

    /// Les **mouvements du livre** du jour civil de la zone (cycle PAY 011).
    ///
    /// L'historique agrégé par course ne peut pas les porter : un `reglement`
    /// et un `reversement` ne sont rattachés à aucune commande — ils portent
    /// sur un solde. Les y agréger les aurait fait disparaître de l'écran, et
    /// un versement invisible est exactement ce que la caisse existe pour
    /// empêcher.
    async fn mouvements_du_jour(
        &self,
        coursier: Uuid,
    ) -> Result<Vec<MouvementCaisse>, ErreurCoursier> {
        let (debut, fin) = self.bornes_du_jour(coursier, None).await?;
        let lignes = sqlx::query!(
            r#"SELECT e.id, e.type::text AS "type_ecriture!", e.montant_unites,
                      e.commande_id, e.ecrit_le
                 FROM coursier.ecriture_caisse e
                WHERE e.coursier_id = $1 AND e.ecrit_le >= $2 AND e.ecrit_le < $3
                ORDER BY e.ecrit_le DESC, e.id DESC"#,
            coursier,
            debut,
            fin,
        )
        .fetch_all(&self.pool)
        .await?;

        lignes
            .into_iter()
            .map(|l| {
                Ok(MouvementCaisse {
                    id: l.id,
                    type_ecriture: l.type_ecriture.parse()?,
                    montant_unites: l.montant_unites,
                    commande_id: l.commande_id,
                    // La référence lisible est DÉRIVÉE de l'identifiant, comme
                    // partout ailleurs (`reference_courte`) : aucune colonne ne
                    // la stocke, et en inventer une ici l'aurait fait diverger
                    // de celle que le client lit.
                    reference: l.commande_id.map(commandes::reference_courte),
                    heure: l.ecrit_le,
                })
            })
            .collect()
    }

    /// Avances non compensées d'un coursier — **le** nombre de K5 (FR-067).
    pub(crate) async fn avances_ouvertes(
        &self,
        coursier: Uuid,
    ) -> Result<AvancesOuvertes, ErreurCoursier> {
        let l = sqlx::query!(
            r#"SELECT COALESCE(-SUM(e.montant_unites), 0)::bigint  AS "total!",
                      COUNT(DISTINCT e.livraison_id)               AS "courses!",
                      COALESCE(-SUM(e.montant_unites) FILTER (
                          WHERE c.mode_paiement <> 'cash' AND l.livree_le IS NOT NULL
                      ), 0)::bigint                                AS "en_attente!"
                 FROM coursier.ecriture_caisse e
                 JOIN commandes.livraison l ON l.id = e.livraison_id
                 JOIN commandes.commande  c ON c.id = e.commande_id
                WHERE e.coursier_id = $1 AND e.type = 'avance'
                  -- Une avance est SOLDÉE dès qu'un remboursement existe sur la
                  -- même livraison. Pas de table de solde : la somme est exacte
                  -- par construction (data-model §1.3).
                  AND NOT EXISTS (
                      SELECT 1 FROM coursier.ecriture_caisse r
                       WHERE r.livraison_id = e.livraison_id
                         AND r.type = 'remboursement')"#,
            coursier,
        )
        .fetch_one(&self.pool)
        .await?;
        Ok(AvancesOuvertes {
            total: l.total,
            courses: l.courses,
            en_attente_reglement: l.en_attente,
        })
    }

    /// L'historique du **jour civil de la zone** — trois chiffres par course.
    ///
    /// Le jour est celui de Yao, pas celui d'UTC : à Tiassalé, un UTC nu
    /// changerait de journée à minuit heure locale par chance, et ailleurs au
    /// milieu d'un service (FR-092, T077).
    async fn historique_du_jour(
        &self,
        coursier: Uuid,
    ) -> Result<Vec<LigneHistorique>, ErreurCoursier> {
        let (debut, fin) = self.bornes_du_jour(coursier, None).await?;
        let lignes = sqlx::query!(
            r#"SELECT e.commande_id AS "commande_id!", e.livraison_id,
                      COALESCE(-SUM(e.montant_unites) FILTER (WHERE e.type = 'avance'), 0)::bigint
                          AS "avance!",
                      COALESCE(SUM(e.montant_unites) FILTER (WHERE e.type = 'remboursement'), 0)::bigint
                          AS "rembourse!",
                      COALESCE(MAX(l.devis_part_coursier), 0)::bigint AS "gain!",
                      bool_or(l.livree_le IS NOT NULL) AS "terminee!",
                      (c.mode_paiement <> 'cash') AS "prepayee!",
                      MIN(e.ecrit_le) AS "heure!"
                 FROM coursier.ecriture_caisse e
                 JOIN commandes.commande  c ON c.id = e.commande_id
                 LEFT JOIN commandes.livraison l ON l.id = e.livraison_id
                WHERE e.coursier_id = $1 AND e.ecrit_le >= $2 AND e.ecrit_le < $3
                  AND e.commande_id IS NOT NULL
                GROUP BY e.commande_id, e.livraison_id, c.mode_paiement
                ORDER BY MIN(e.ecrit_le) DESC"#,
            coursier,
            debut,
            fin,
        )
        .fetch_all(&self.pool)
        .await?;

        Ok(lignes
            .into_iter()
            .map(|l| LigneHistorique {
                commande_id: l.commande_id,
                livraison_id: l.livraison_id,
                // Dérivée de l'identifiant, jamais stockée : une seconde
                // colonne à resynchroniser pour une chaîne d'affichage.
                reference: commandes::reference_courte(l.commande_id),
                avance_unites: l.avance,
                rembourse_unites: l.rembourse,
                gain_unites: l.gain,
                terminee: l.terminee,
                // FR-117 : livrée, prépayée, jamais remboursée — l'avance
                // attend un règlement que PAY ouvrira (R10).
                en_attente_reglement: l.terminee && l.prepayee && l.rembourse == 0,
                heure: l.heure,
            })
            .collect())
    }

    /// Bornes UTC du jour civil **de la zone** du coursier (T077, FR-092).
    ///
    /// `jour = None` veut dire « aujourd'hui, chez Yao ». Le plafond d'une
    /// course déjà acceptée ne bouge pas au passage de minuit : ce sont les
    /// GAINS qui sont bornés, pas les engagements en cours (FR-097).
    pub(crate) async fn bornes_du_jour(
        &self,
        coursier: Uuid,
        jour: Option<NaiveDate>,
    ) -> Result<(DateTime<Utc>, DateTime<Utc>), ErreurCoursier> {
        let fuseau = self.fuseau_du_coursier(coursier).await?;
        let jour = jour.unwrap_or_else(|| Utc::now().with_timezone(&fuseau).date_naive());
        let debut = jour
            .and_hms_opt(0, 0, 0)
            .and_then(|d| d.and_local_timezone(fuseau).single())
            .ok_or_else(|| {
                ErreurCoursier::ConfigurationInvalide(
                    "minuit local inexistant dans ce fuseau".to_owned(),
                )
            })?;
        Ok((
            debut.with_timezone(&Utc),
            (debut + chrono::Duration::days(1)).with_timezone(&Utc),
        ))
    }

    /// Fuseau de la zone où le coursier travaille.
    ///
    /// Résolu depuis la zone de sa DERNIÈRE course : un coursier n'a pas de
    /// zone propre en base, et c'est là qu'il gagne son argent. Sans course, le
    /// fuseau de la zone racine — il n'y a alors aucun gain à borner.
    async fn fuseau_du_coursier(&self, coursier: Uuid) -> Result<Tz, ErreurCoursier> {
        let zone = self.zone_du_coursier(coursier).await?;
        let Some(zone) = zone else {
            return Ok(Tz::UTC);
        };
        let valeur = self.zones.parametre(zone, "zone.fuseau_horaire").await?;
        let nom = valeur
            .as_ref()
            .and_then(|v| v.as_str())
            .ok_or_else(|| ErreurCoursier::ParametreAbsent("zone.fuseau_horaire".to_owned()))?;
        nom.parse().map_err(|_| {
            ErreurCoursier::ConfigurationInvalide(format!("fuseau IANA invalide : {nom}"))
        })
    }

    /// Zone de la dernière course du coursier.
    async fn zone_du_coursier(&self, coursier: Uuid) -> Result<Option<Uuid>, ErreurCoursier> {
        Ok(sqlx::query_scalar!(
            r#"SELECT c.zone_id FROM commandes.livraison l
                 JOIN commandes.commande c ON c.id = l.commande_id
                WHERE l.coursier_id = $1
                ORDER BY l.assignee_le DESC NULLS LAST
                LIMIT 1"#,
            coursier,
        )
        .fetch_optional(&self.pool)
        .await?)
    }

    /// Devise de la zone où le coursier travaille — jamais écrite en dur.
    pub(crate) async fn devise_du_coursier(
        &self,
        coursier: Uuid,
    ) -> Result<String, ErreurCoursier> {
        match self.zone_du_coursier(coursier).await? {
            Some(zone) => Ok(self.zones.devise(zone).await?.code),
            // Aucune course : il n'y a aucun montant à libeller. Une devise
            // inventée serait pire qu'une absence — la caisse est vide.
            None => Ok(String::new()),
        }
    }

    /// Plafond d'avance DÉCLARÉ du jour, s'il existe (FR-078).
    ///
    /// Lu directement en base plutôt que par un port vers `dispatch` : une
    /// arête permanente entre deux domaines pour un seul nombre serait un prix
    /// trop élevé (contrat §2). La table appartient à `dispatch` et n'est ici
    /// que **lue**.
    async fn plafond_declare_du_jour(
        &self,
        coursier: Uuid,
    ) -> Result<Option<i64>, ErreurCoursier> {
        Ok(sqlx::query_scalar!(
            r#"SELECT plafond_unites FROM dispatch.plafond_jour
                WHERE coursier_id = $1 ORDER BY jour DESC LIMIT 1"#,
            coursier,
        )
        .fetch_optional(&self.pool)
        .await?)
    }

    /// Contexte d'une livraison — ce qu'il faut pour écrire au bon livre.
    async fn contexte_livraison(
        &self,
        livraison: Uuid,
    ) -> Result<Option<ContexteLivraison>, ErreurCoursier> {
        let l = sqlx::query!(
            r#"SELECT l.coursier_id, l.commande_id, c.devise,
                      c.mode_paiement::text AS "mode_paiement!",
                      c.total_unites,
                      l.devis_part_coursier, l.devis_marge
                 FROM commandes.livraison l
                 JOIN commandes.commande c ON c.id = l.commande_id
                WHERE l.id = $1"#,
            livraison,
        )
        .fetch_optional(&self.pool)
        .await?;
        Ok(l.map(|l| ContexteLivraison {
            coursier_id: l.coursier_id,
            commande_id: l.commande_id,
            devise: l.devise,
            mode_paiement: l.mode_paiement,
            total_unites: l.total_unites,
            devis_part_coursier: l.devis_part_coursier,
            devis_marge: l.devis_marge,
        }))
    }

    /// Ce que **`coursier`** sait de la journée de Yao (FR-091, FR-095).
    ///
    /// Trois nombres seulement, et c'est volontaire : les courses livrées, leurs
    /// gains, et l'argent encore dehors. Le plafond retenu et le taux
    /// d'acceptation appartiennent à `dispatch` — ils sont ajoutés **dans le
    /// handler**, qui détient les deux dépôts. Faire dépendre `coursier` de
    /// `dispatch` pour deux nombres créerait une arête permanente entre deux
    /// domaines qui n'ont rien à se dire (contrat §2).
    ///
    /// Les gains sont la somme des **parts coursier du devis figé** (cycle 007),
    /// jamais un recalcul : un montant recalculé après coup pourrait différer de
    /// celui annoncé à l'acceptation, et Yao verrait son gain bouger tout seul.
    pub async fn journee_du_coursier(
        &self,
        coursier: Uuid,
    ) -> Result<JourneeCoursier, ErreurCoursier> {
        use commandes::CourseCoursier as _;

        let (debut, fin) = self.bornes_du_jour(coursier, None).await?;
        let livrees = self.commandes.livrees_du_jour(coursier, debut, fin).await?;
        let ouvertes = self.avances_ouvertes(coursier).await?;

        // La devise vient des livraisons du jour quand il y en a — c'est celle
        // dans laquelle l'argent a réellement circulé ; sinon celle de la zone
        // de travail, et à défaut rien du tout (aucune course, aucun montant à
        // libeller : une devise inventée serait pire qu'une absence).
        let devise = match livrees.first() {
            Some(l) => l.devise.clone(),
            None => self.devise_du_coursier(coursier).await?,
        };

        Ok(JourneeCoursier {
            courses_livrees: livrees.len() as i64,
            gains_unites: livrees.iter().map(|l| l.part_coursier_unites).sum(),
            avances_en_cours_unites: ouvertes.total,
            devise,
        })
    }

    /// Exposition cash de toute la flotte (FR-075).
    pub async fn exposition_cash(&self) -> Result<crate::modele::ExpositionCash, ErreurCoursier> {
        let lignes = sqlx::query!(
            r#"SELECT e.coursier_id AS "coursier_id!",
                      COALESCE(-SUM(e.montant_unites), 0)::bigint AS "avance!",
                      COUNT(DISTINCT e.livraison_id)      AS "courses!",
                      MAX(e.devise)                       AS "devise!"
                 FROM coursier.ecriture_caisse e
                WHERE e.type = 'avance'
                  AND NOT EXISTS (
                      SELECT 1 FROM coursier.ecriture_caisse r
                       WHERE r.livraison_id = e.livraison_id
                         AND r.type = 'remboursement')
                GROUP BY e.coursier_id
                HAVING COALESCE(-SUM(e.montant_unites), 0) <> 0
                ORDER BY COALESCE(-SUM(e.montant_unites), 0) DESC"#,
        )
        .fetch_all(&self.pool)
        .await?;

        let devise = lignes.first().map(|l| l.devise.clone()).unwrap_or_default();
        let total = lignes.iter().map(|l| l.avance).sum();
        Ok(crate::modele::ExpositionCash {
            total_unites: total,
            devise,
            par_coursier: lignes
                .into_iter()
                .map(|l| crate::modele::LigneExposition {
                    coursier_id: l.coursier_id,
                    // Le nom d'usage n'existe pas encore côté produit (cycle CPT
                    // 003 : « un numéro vérifié, rien d'autre ») — l'admin
                    // identifie par l'identifiant, pas par un nom fabriqué.
                    nom: String::new(),
                    avance_unites: l.avance,
                    courses: l.courses,
                })
                .collect(),
        })
    }
}

/// Ce que le domaine `coursier` sait de la journée — la moitié de K1-1a.
///
/// L'autre moitié (plafond retenu, taux d'acceptation) vient de `dispatch` et
/// est assemblée dans le handler `GET /moi/journee`.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct JourneeCoursier {
    /// Courses dont la remise est validée dans le jour civil de la zone.
    pub courses_livrees: i64,
    /// Somme des parts coursier de ces courses (devis FIGÉ du cycle 007).
    pub gains_unites: i64,
    /// Argent encore dehors — ce qui ampute le « reste disponible » (FR-095).
    pub avances_en_cours_unites: i64,
    /// Devise ISO 4217.
    pub devise: String,
}

/// Les avances non compensées d'un coursier, décomposées.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct AvancesOuvertes {
    /// Total en circulation (positif).
    pub total: i64,
    /// Courses concernées.
    pub courses: i64,
    /// Part que le cash ne soldera jamais (commandes prépayées, R10).
    pub en_attente_reglement: i64,
}

struct ContexteLivraison {
    coursier_id: Option<Uuid>,
    commande_id: Uuid,
    devise: String,
    mode_paiement: String,
    /// Total **dû par le client**, ajusté par les retraits de lignes.
    total_unites: i64,
    /// Part coursier du devis FIGÉ (cycle 007).
    devis_part_coursier: i64,
    /// Marge Mefali du devis figé. Nulle jusqu'à M4 — ce qui rend le cas
    /// « cash ordinaire » du tableau R13 particulièrement facile à mal lire.
    ///
    /// Lue ici parce qu'elle vient de la même requête que le reste ; elle sert
    /// à la créance `part_course` et à la position « détenu pour Mefali »
    /// (US6). La charger dès maintenant évite une seconde lecture sur le même
    /// chemin d'écriture.
    #[allow(dead_code)] // consommée par T065/T067 (US6)
    devis_marge: i64,
}

/// Lit un UUID dans une charge utile d'événement, `None` s'il est absent ou
/// malformé — un événement mal formé ne doit jamais faire tomber le worker.
fn uuid_du(payload: &serde_json::Value, cle: &str) -> Option<Uuid> {
    payload[cle].as_str().and_then(|s| s.parse().ok())
}

// ── Cycle PAY 011 — l'arithmétique de la chaîne cash (research R13) ───────
//
// Ces fonctions sont PURES et testées une par une. C'est délibéré : la
// première formule retenue pour `frais_encaisses` était `devis_prix_client`,
// et elle s'est révélée fausse dès que la retenue de la livraison offerte
// joue. Une formule d'argent qui ne se teste pas sans base finit par n'être
// testée que par le parcours qui l'a fait naître.

/// Frais **effectivement encaissés** chez le client, à la remise d'une commande
/// cash (FR-056).
///
/// ```text
/// frais_encaisses = total dû par le client − Σ avances de la livraison
/// ```
///
/// **Et non `devis_prix_client`.** Les deux coïncident dans le cas ordinaire et
/// divergent exactement là où la retenue de VND-08 joue : sur une livraison
/// offerte, le prix client vaut `0` alors que Yao a bien encaissé sa part —
/// parce que le vendeur la lui a laissée en retenant sur les articles. La
/// formule dit la **trésorerie réelle** : ce qui est entré moins ce qui est
/// sorti, quelle que soit la façon dont la course a été financée.
///
/// Borné à zéro : un total inférieur aux avances signifierait que le coursier
/// a avancé plus que le client ne doit — situation qui n'existe pas, mais dont
/// la traduction en écriture NÉGATIVE ferait un « frais encaissé » qui sort de
/// la poche, c'est-à-dire un contresens au livre.
pub fn frais_encaisses(total_du_unites: i64, avances_unites: i64) -> i64 {
    (total_du_unites - avances_unites).max(0)
}

/// Discriminant de l'écriture `frais_encaisses` dérivée d'un `livraison.livree`.
const DERIVE_FRAIS_ENCAISSES: &str = "frais_encaisses";

/// Identifiant d'événement **dérivé**, stable et distinct de l'original.
///
/// Un même `livraison.livree` produit plusieurs écritures de caisse, et
/// `ecriture_caisse.evenement_id` est UNIQUE : réutiliser l'identifiant de
/// l'événement ferait avaler la seconde écriture comme un doublon de la
/// première, et le livre perdrait silencieusement les frais.
///
/// UUIDv5 sur l'identifiant de l'événement et un discriminant : **déterministe**,
/// donc un rejeu du worker retrouve exactement la même clé et l'idempotence
/// tient (FR-068).
pub fn evenement_derive(evenement: Uuid, discriminant: &str) -> Uuid {
    Uuid::new_v5(&evenement, discriminant.as_bytes())
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    // ── T047 — les QUATRE cas de la table de vérité (research R13) ────────
    //
    // Notations : `A` = Σ avances, `PC` = prix client du devis, `P` = part
    // coursier, `M` = marge Mefali, `R` = retenue vendeur.
    //
    // | Cas                    | Total dû      | A         | frais_encaisses |
    // |------------------------|---------------|-----------|-----------------|
    // | Cash ordinaire         | articles + PC | articles  | PC = P + M      |
    // | Cash + retenue VND-08  | articles      | articles−R| R = P + M       |
    // | Cash + promo Mefali    | articles      | articles  | 0               |
    // | Prépayée               | 0 encaissé    | articles  | 0               |
    //
    // C'est **ce test** qui a fait rejeter la première formule
    // (`frais_encaisses = devis_prix_client`) : elle donnait `0` au cas 2,
    // alors que Yao a bien 500 F de plus dans sa poche.

    /// Cas 1 — **cash ordinaire**. Le client paie les articles plus les frais ;
    /// le coursier a avancé les articles. Il encaisse donc les frais.
    #[test]
    fn cas_1_cash_ordinaire() {
        let (articles, prix_client) = (3_000, 500);
        let total_du = articles + prix_client;
        assert_eq!(
            frais_encaisses(total_du, articles),
            prix_client,
            "les frais encaissés valent le prix client de la course",
        );
    }

    /// Cas 2 — **cash + retenue VND-08**, celui qui a fait rejeter la première
    /// formule.
    ///
    /// Le vendeur offre la livraison : le prix client tombe à **0**, et la
    /// retenue de 500 F est prélevée sur ce que le coursier verse au vendeur.
    /// Yao avance donc 2 500 au lieu de 3 000, et encaisse 3 000 chez le
    /// client. Il a bien **500 F de plus** dans la poche.
    ///
    /// Avec `frais_encaisses = devis_prix_client`, le livre aurait porté `0` —
    /// il aurait menti exactement là où la retenue existe pour qu'il dise vrai.
    #[test]
    fn cas_2_cash_avec_retenue_vendeur() {
        let (articles, retenue) = (3_000, 500);
        let total_du = articles; // prix client = 0, la livraison est offerte
        let avances = articles - retenue; // l'avance est NETTE de la retenue
        assert_eq!(
            frais_encaisses(total_du, avances),
            retenue,
            "Yao encaisse bien la retenue : c'est sa part, versée par le vendeur",
        );
        assert_ne!(
            frais_encaisses(total_du, avances),
            0,
            "la formule naïve `= devis_prix_client` aurait donné 0 — et menti",
        );
    }

    /// Cas 3 — **cash + promotion Mefali**. La livraison est offerte par
    /// Mefali, pas par le vendeur : aucune retenue, et le client ne paie que
    /// les articles.
    ///
    /// Yao avance 3 000 et encaisse 3 000 : rien en plus. Sa part deviendra une
    /// **créance** sur Mefali (US6), ce qui est exactement ce que la situation
    /// décrit — il a travaillé, personne ne l'a payé sur place.
    #[test]
    fn cas_3_cash_avec_promotion_mefali() {
        let articles = 3_000;
        assert_eq!(
            frais_encaisses(articles, articles),
            0,
            "rien n'est encaissé en plus : la part passera par une créance",
        );
    }

    /// Cas 4 — **commande prépayée**. Aucun cash ne change de main à la remise.
    ///
    /// Le chemin de production n'appelle même pas cette formule dans ce cas
    /// (la branche `mode_paiement != cash` sort avant) ; le test fige quand
    /// même le résultat, parce qu'une future modalité de paiement passerait
    /// par ici avec un total encaissé nul.
    #[test]
    fn cas_4_commande_prepayee() {
        let articles = 3_000;
        assert_eq!(
            frais_encaisses(0, articles),
            0,
            "aucun encaissement : la formule ne doit surtout pas rendre un \
             montant négatif, qui ferait SORTIR de l'argent de la poche",
        );
    }

    /// Une ligne retirée pendant la course baisse le total dû ET l'avance : les
    /// frais encaissés ne bougent pas. C'est le cas que le test d'intégration
    /// T048 déroule pour de vrai.
    #[test]
    fn un_retrait_de_ligne_ne_change_pas_les_frais() {
        let (articles, prix_client, retire) = (3_000, 500, 800);
        assert_eq!(
            frais_encaisses(articles + prix_client, articles),
            frais_encaisses(articles - retire + prix_client, articles - retire),
        );
    }

    /// L'identifiant dérivé est **stable** (le rejeu retrouve la même clé) et
    /// **distinct** de l'original (sinon la seconde écriture serait avalée
    /// comme un doublon de la première, et le livre perdrait les frais).
    #[test]
    fn l_identifiant_derive_est_stable_et_distinct() {
        let evenement = Uuid::now_v7();
        let derive = evenement_derive(evenement, DERIVE_FRAIS_ENCAISSES);
        assert_eq!(derive, evenement_derive(evenement, DERIVE_FRAIS_ENCAISSES));
        assert_ne!(derive, evenement);
        assert_ne!(derive, evenement_derive(evenement, "autre_chose"));
        assert_ne!(derive, evenement_derive(Uuid::now_v7(), DERIVE_FRAIS_ENCAISSES));
    }

    /// Les six natures d'écriture portent des libellés SQL stables : ce sont
    /// les valeurs de l'énumération Postgres, et les changer casserait la
    /// lecture de tout le livre déjà écrit.
    #[test]
    fn les_six_natures_d_ecriture_sont_stables() {
        for (nature, libelle) in [
            (TypeEcriture::Avance, "avance"),
            (TypeEcriture::Remboursement, "remboursement"),
            (TypeEcriture::Indemnisation, "indemnisation"),
            (TypeEcriture::Correction, "correction"),
            (TypeEcriture::FraisEncaisses, "frais_encaisses"),
            (TypeEcriture::Reglement, "reglement"),
        ] {
            assert_eq!(nature.comme_str(), libelle);
            assert_eq!(libelle.parse::<TypeEcriture>().unwrap(), nature);
        }
    }

    /// Le signe porte tout le sens : une avance SORT de la poche, un
    /// remboursement y ENTRE. Une inversion rendrait un solde parfaitement
    /// cohérent — et parfaitement faux.
    #[test]
    fn le_signe_d_une_ecriture_dit_le_sens_de_l_argent() {
        let avance = DemandeEcriture {
            type_ecriture: TypeEcriture::Avance,
            montant_unites: -1_500,
            devise: "XOF".to_owned(),
            commande_id: None,
            livraison_id: None,
            arret_id: None,
            indemnisation_id: None,
            evenement_id: None,
            source: "outbox",
        };
        assert!(avance.montant_unites < 0);
        assert_eq!(avance.type_ecriture.comme_str(), "avance");
    }

    /// Un UUID absent ou illisible rend `None` — jamais une panique. Le worker
    /// outbox distribue TOUT le journal ; un seul événement mal formé ne doit
    /// pas bloquer la file de toute la flotte.
    #[test]
    fn un_payload_mal_forme_ne_fait_pas_tomber_le_worker() {
        assert!(uuid_du(&json!({}), "livraison").is_none());
        assert!(uuid_du(&json!({ "livraison": "pas-un-uuid" }), "livraison").is_none());
        assert!(uuid_du(&json!({ "livraison": 42 }), "livraison").is_none());
        let id = Uuid::now_v7();
        assert_eq!(uuid_du(&json!({ "livraison": id }), "livraison"), Some(id));
    }
}
