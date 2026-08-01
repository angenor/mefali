//! Substitutions : préférences, proposition, échéance persistée, expiration.
//!
//! Ce module porte aussi la **révision du montant** — la seule chose qui bouge
//! quand un article manque. Elle vit ici, et non chez chaque appelant, parce
//! que l'invariant qu'elle protège est global : `total = articles + devis
//! FIGÉ`. Un retrait, un remplacement ou un arrêt entièrement indisponible
//! recalculent tous le même montant par le même chemin ; les frais de
//! livraison, eux, ne sont JAMAIS recalculés (FR-050).
//!
//! Rempli par T047..T050 ; la révision de montant est posée dès T034, qui en a
//! besoin pour l'arrêt entièrement indisponible.

use chrono::{DateTime, Utc};
use serde_json::json;
use socle::{ecrire_evenement, NouvelEvenement};
use uuid::Uuid;

use crate::depot::PgCommandes;
use crate::modele::{
    ErreurCommandes, IssueSubstitution, PreferenceSubstitution, StatutLigne,
};

/// Montants d'une commande après révision.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct MontantsRevises {
    /// Somme des lignes encore vivantes (unités mineures).
    pub montant_articles_unites: i64,
    /// `montant_articles + devis_prix_client` — le devis n'entre dans le calcul
    /// que comme une constante lue.
    pub total_unites: i64,
    /// Prix client du devis FIGÉ, relu tel quel (base de l'assertion FR-050).
    pub devis_prix_client: i64,
}

impl PgCommandes {
    /// Recalcule les montants d'une commande à partir de ses lignes VIVANTES,
    /// et réécrit le tronc.
    ///
    /// ⚠ **Le devis de livraison n'est jamais recalculé** (FR-050) : il est lu
    /// depuis `livraison.devis_prix_client`, où la création l'a figé (R11).
    /// C'est structurel — aucun appel au moteur tarifaire n'existe sur ce
    /// chemin, donc aucun retrait ne peut faire varier les frais, même par
    /// accident. Un remplacement accepté compte au prix PROPOSÉ, un article
    /// retiré ne compte plus du tout.
    ///
    /// Aucun chemin de paiement partiel n'apparaît ici : le total révisé
    /// REMPLACE l'ancien, il ne le fractionne pas (constitution III).
    pub(crate) async fn reviser_montants(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        commande_id: Uuid,
    ) -> Result<MontantsRevises, ErreurCommandes> {
        let articles = sqlx::query_scalar!(
            r#"SELECT COALESCE(SUM(
                          lc.quantite * COALESCE(lc.remplace_prix_unites, pf.prix_unites)
                      ) FILTER (WHERE lc.statut <> 'retiree'), 0)::bigint AS "articles!"
               FROM commandes.ligne_commande lc
               JOIN prestataires.prix_fige pf ON pf.id = lc.prix_fige_id
               WHERE lc.commande_id = $1"#,
            commande_id,
        )
        .fetch_one(&mut **tx)
        .await?;

        // Une commande SANS livraison (vertical futur, constitution II) n'a
        // aucun frais : son total est celui de ses articles.
        let devis_prix_client = sqlx::query_scalar!(
            "SELECT devis_prix_client FROM commandes.livraison WHERE commande_id = $1",
            commande_id,
        )
        .fetch_optional(&mut **tx)
        .await?
        .unwrap_or(0);

        let total_unites = articles + devis_prix_client;

        sqlx::query!(
            "UPDATE commandes.commande
                SET montant_articles_unites = $2, total_unites = $3
              WHERE id = $1",
            commande_id,
            articles,
            total_unites,
        )
        .execute(&mut **tx)
        .await?;

        // Et les arrêts ENCORE À FAIRE suivent : `arret.montant_avance` est ce
        // que le coursier devra sortir de sa poche chez ce vendeur. Le laisser
        // à sa valeur de création en faisait un chiffre périmé dès le premier
        // retrait — la caisse portait alors 900 F que personne n'avait versés
        // (T087, rapport-ecarts §5.2).
        //
        // Les arrêts DÉJÀ collectés ne sont pas touchés : leur montant a fondé
        // une écriture de caisse, et réécrire l'histoire après coup ferait
        // diverger le livre de ce qui s'est réellement passé au comptoir.
        sqlx::query!(
            r#"UPDATE commandes.arret a
                  SET montant_avance = COALESCE((
                        SELECT SUM(lc.quantite
                                   * COALESCE(lc.remplace_prix_unites, pf.prix_unites))
                          FROM commandes.ligne_commande lc
                          JOIN prestataires.prix_fige pf ON pf.id = lc.prix_fige_id
                         WHERE lc.arret_id = a.id AND lc.statut <> 'retiree'), 0)
                 FROM commandes.segment s
                 JOIN commandes.livraison l ON l.id = s.livraison_id
                WHERE a.segment_id = s.id
                  AND l.commande_id = $1
                  AND a.type_arret = 'collecte'
                  AND a.statut IN ('a_collecter', 'en_route', 'arrive')"#,
            commande_id,
        )
        .execute(&mut **tx)
        .await?;

        Ok(MontantsRevises {
            montant_articles_unites: articles,
            total_unites,
            devis_prix_client,
        })
    }

    /// Retire toutes les lignes encore présentes d'un arrêt — un `ligne.retiree`
    /// par ligne — puis révise les montants.
    ///
    /// Sert l'arrêt entièrement indisponible (T034) et la résolution d'une
    /// rupture (T047). Renvoie `(nombre de lignes retirées, montant retiré)`.
    pub(crate) async fn retirer_lignes_de_l_arret(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        arret_id: Uuid,
        commande_id: Uuid,
        motif: &str,
        horodatage: DateTime<Utc>,
    ) -> Result<(i64, i64), ErreurCommandes> {
        let lignes = sqlx::query!(
            r#"SELECT lc.id,
                      lc.quantite * COALESCE(lc.remplace_prix_unites, pf.prix_unites)
                          AS "montant!",
                      pf.devise
               FROM commandes.ligne_commande lc
               JOIN prestataires.prix_fige pf ON pf.id = lc.prix_fige_id
               WHERE lc.arret_id = $1 AND lc.statut = 'presente'
               ORDER BY lc.cree_le"#,
            arret_id,
        )
        .fetch_all(&mut **tx)
        .await?;

        let mut montant_retire = 0_i64;
        for ligne in &lignes {
            sqlx::query!(
                "UPDATE commandes.ligne_commande SET statut = 'retiree' WHERE id = $1",
                ligne.id,
            )
            .execute(&mut **tx)
            .await?;

            ecrire_evenement(
                tx,
                NouvelEvenement {
                    type_evenement: "ligne.retiree",
                    entite_type: "ligne_commande",
                    entite_id: ligne.id,
                    payload: json!({
                        "commande": commande_id,
                        "motif": motif,
                        "montant_retire": ligne.montant,
                        "devise": ligne.devise,
                    }),
                    survenu_le: horodatage,
                },
            )
            .await?;
            montant_retire += ligne.montant;
        }

        if !lignes.is_empty() {
            self.reviser_montants(tx, commande_id).await?;
        }
        Ok((lignes.len() as i64, montant_retire))
    }
}

// ── T047..T050 : les trois préférences, la proposition, l'échéance ─────────

/// Clés de configuration de zone lues par les substitutions (constitution I).
mod cles {
    /// Fenêtre de décision du client, en secondes (défaut produit : 60).
    pub const DELAI_VALIDATION_S: &str = "substitution.delai_validation_s";
    /// Écart de prix maximal d'un remplacement, en pourcent (défaut : 20).
    pub const ECART_PRIX_MAX_POURCENT: &str = "substitution.ecart_prix_max_pourcent";
    /// Rétention des PHOTOS de remplacement, en jours (constitution VIII).
    pub const PHOTO_RETENTION_JOURS: &str = "substitution.photo_retention_jours";
}

/// Motifs de `ligne.retiree` — la taxonomie en ferme la liste.
mod motifs {
    /// Retrait décidé d'avance par la préférence du client.
    pub const PREFERENCE: &str = "preference";
    /// Retrait après expiration de la fenêtre et appel infructueux.
    pub const EXPIRATION: &str = "expiration";
    /// Retrait après refus explicite du remplacement proposé.
    pub const REFUS: &str = "refus";
}

/// Ce que le coursier fait d'un article manquant.
#[derive(Debug, Clone)]
pub enum ResolutionRupture {
    /// Retirer l'article — rien à payer pour lui.
    Retirer,
    /// Proposer un équivalent : photo et prix obligatoires (FR-045).
    Remplacer {
        /// Article proposé — **du même vendeur** (FR-048).
        article_propose_id: Uuid,
        /// Prix unitaire proposé (unités mineures).
        prix_propose_unites: i64,
        /// Photo du remplacement, déposée dans le stockage objet.
        photo: Vec<u8>,
        /// Type MIME de la photo.
        mime: String,
    },
}

/// Déclaration d'une rupture par le coursier.
#[derive(Debug, Clone)]
pub struct DemandeRupture {
    /// Ligne de commande concernée.
    pub ligne_id: Uuid,
    /// Clé d'idempotence de la file hors-ligne (constitution V).
    pub uuid_client: Uuid,
    /// Ce que le coursier fait. `None` = suivre la préférence du client.
    ///
    /// Renseigné pour la préférence « m'appeler » : c'est la **résolution
    /// saisie** après l'appel (FR-045). Renseigné aussi pour « remplacer »,
    /// où il porte l'article, le prix et la photo.
    pub resolution: Option<ResolutionRupture>,
}

/// Issue immédiate d'une rupture déclarée.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum IssueRupture {
    /// L'article est sorti de la commande ; le montant a été révisé.
    LigneRetiree {
        /// Ligne retirée.
        ligne_id: Uuid,
        /// Montant sorti du total (unités mineures).
        montant_retire: i64,
        /// Montants après révision.
        montants: MontantsRevises,
    },
    /// Une proposition est ouverte : le client a sa fenêtre pour décider.
    PropositionOuverte {
        /// Proposition créée.
        substitution_id: Uuid,
        /// Secondes dont dispose le client.
        reste_s: i64,
        /// Écart de prix en pourcent (signé).
        ecart_pourcent: i64,
    },
}

impl PgCommandes {
    /// Applique la préférence de substitution d'un article devenu indisponible
    /// (FR-044/045).
    ///
    /// Les trois chemins produisent des effets très différents, mais partagent
    /// deux invariants : le **devis de livraison ne bouge pas** (FR-050) et le
    /// total reste payé **en une fois** (FR-049).
    pub async fn declarer_rupture(
        &self,
        coursier: Uuid,
        demande: DemandeRupture,
        maintenant: DateTime<Utc>,
    ) -> Result<IssueRupture, ErreurCommandes> {
        let ligne = self.ligne_en_rupture(demande.ligne_id, coursier).await?;

        // Rejeu de la MÊME déclaration : la proposition déjà ouverte est rendue
        // telle quelle (constitution V).
        if let Some(deja) = self
            .proposition_par_uuid_client(demande.uuid_client, maintenant)
            .await?
        {
            return Ok(deja);
        }

        let mut tx = self.pool.begin().await?;

        // « M'appeler » : l'appel est passé depuis l'app et JOURNALISÉ, puis la
        // résolution saisie est appliquée. Le journal ne porte aucun numéro.
        if ligne.preference == PreferenceSubstitution::Appeler {
            ecrire_evenement(
                &mut tx,
                NouvelEvenement {
                    type_evenement: "appel.intention",
                    entite_type: "commande",
                    entite_id: ligne.commande_id,
                    payload: json!({
                        "de": "coursier",
                        "vers": "client",
                        "motif": "substitution",
                    }),
                    survenu_le: maintenant,
                },
            )
            .await?;
        }

        // Le chemin effectif : la résolution saisie prime sur la préférence —
        // c'est elle qui porte ce que le client a dit au téléphone. Sans
        // résolution, on retire : le défaut le plus sûr est celui qui ne fait
        // rien payer.
        let resolution = match (&demande.resolution, ligne.preference) {
            (Some(r), _) => r.clone(),
            (None, _) => ResolutionRupture::Retirer,
        };

        let issue = match resolution {
            ResolutionRupture::Retirer => {
                let montant = self
                    .retirer_ligne(
                        &mut tx,
                        &ligne,
                        if ligne.preference == PreferenceSubstitution::Retirer {
                            motifs::PREFERENCE
                        } else {
                            motifs::EXPIRATION
                        },
                        maintenant,
                    )
                    .await?;
                let montants = self.reviser_montants(&mut tx, ligne.commande_id).await?;
                IssueRupture::LigneRetiree {
                    ligne_id: ligne.ligne_id,
                    montant_retire: montant,
                    montants,
                }
            }
            ResolutionRupture::Remplacer {
                article_propose_id,
                prix_propose_unites,
                photo,
                mime,
            } => {
                self.ouvrir_proposition(
                    &mut tx,
                    &ligne,
                    article_propose_id,
                    prix_propose_unites,
                    photo,
                    &mime,
                    demande.uuid_client,
                    coursier,
                    maintenant,
                )
                .await?
            }
        };

        tx.commit().await?;
        Ok(issue)
    }

    /// Ouvre une proposition de remplacement (FR-045/047/048).
    ///
    /// Deux gardes, dans cet ordre — et l'ordre compte : refuser le mauvais
    /// vendeur AVANT de regarder le prix évite d'expliquer un écart sur un
    /// article qui n'aurait de toute façon pas pu être proposé.
    #[allow(clippy::too_many_arguments)]
    async fn ouvrir_proposition(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        ligne: &LigneEnRupture,
        article_propose_id: Uuid,
        prix_propose_unites: i64,
        photo: Vec<u8>,
        mime: &str,
        uuid_client: Uuid,
        coursier: Uuid,
        maintenant: DateTime<Utc>,
    ) -> Result<IssueRupture, ErreurCommandes> {
        // 1. MÊME VENDEUR (FR-048). La réaffectation vers un autre vendeur est
        //    la phase 2 : elle changerait la géométrie de la course, donc le
        //    devis — que ce cycle s'interdit de recalculer.
        // `vendeur_id` EST le `prestataire_id` : la table `vendeur` est la
        // spécialisation MVP du prestataire, et sa clé primaire est celle du
        // prestataire (constitution II).
        let vendeur_propose = sqlx::query_scalar!(
            "SELECT vendeur_id FROM prestataires.article WHERE id = $1",
            article_propose_id,
        )
        .fetch_optional(&mut **tx)
        .await?
        .ok_or(ErreurCommandes::ArticleIndisponible(article_propose_id))?;
        if vendeur_propose != ligne.prestataire_id {
            return Err(ErreurCommandes::SubstitutionAutreVendeur);
        }

        // 2. ÉCART DE PRIX borné par la zone (FR-047). L'écart se mesure sur le
        //    prix UNITAIRE : c'est ce que le client compare (« 600 au lieu de
        //    500 »), et c'est indépendant de la quantité.
        let max_pourcent = self
            .parametre_i64(ligne.zone_id, cles::ECART_PRIX_MAX_POURCENT)
            .await?;
        let ecart_pourcent = ecart_pourcent(ligne.prix_unitaire_unites, prix_propose_unites);
        if ecart_pourcent.abs() > max_pourcent {
            return Err(ErreurCommandes::SubstitutionEcartPrix);
        }

        // 3. Photo dans le stockage objet — rétention appliquée par le job de
        //    purge (T063), jamais par une durée en dur.
        let substitution_id = Uuid::now_v7();
        let photo_cle = format!("commandes/substitutions/{substitution_id}");
        self.objets
            .deposer(&photo_cle, photo, mime)
            .await
            .map_err(|e| ErreurCommandes::Dependance(e.to_string()))?;

        // 4. Échéance PERSISTÉE (research R10) : jamais un minuteur en mémoire.
        //    Une décision d'argent ne dépend pas de la vie d'un processus — un
        //    redémarrage ne doit pas rendre une proposition éternelle.
        let delai_s = self
            .parametre_i64(ligne.zone_id, cles::DELAI_VALIDATION_S)
            .await?;
        let echeance = maintenant + chrono::Duration::seconds(delai_s);

        sqlx::query!(
            "INSERT INTO commandes.substitution
                 (id, ligne_id, arret_id, article_propose_id, prix_propose_unites,
                  photo_cle, proposee_le, echeance, uuid_client)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)",
            substitution_id,
            ligne.ligne_id,
            ligne.arret_id,
            article_propose_id,
            prix_propose_unites,
            photo_cle,
            maintenant,
            echeance,
            uuid_client,
        )
        .execute(&mut **tx)
        .await?;

        ecrire_evenement(
            tx,
            NouvelEvenement {
                type_evenement: "substitution.proposee",
                entite_type: "substitution",
                entite_id: substitution_id,
                payload: json!({
                    "commande": ligne.commande_id,
                    "ligne": ligne.ligne_id,
                    "arret": ligne.arret_id,
                    "ecart_pourcent": ecart_pourcent,
                    "echeance_s": delai_s,
                    "acteur": coursier,
                }),
                survenu_le: maintenant,
            },
        )
        .await?;

        Ok(IssueRupture::PropositionOuverte {
            substitution_id,
            reste_s: delai_s,
            ecart_pourcent,
        })
    }

    /// Décision du client sur une proposition (FR-045).
    ///
    /// Acceptée → la ligne devient `remplacee` au prix PROPOSÉ ; refusée → la
    /// ligne est retirée, et rien n'est payé pour elle. Dans les deux cas, le
    /// devis de livraison ne bouge pas.
    ///
    /// Une décision arrivée APRÈS l'échéance est refusée : la fenêtre est une
    /// promesse faite au coursier autant qu'au client — passé le délai, il a
    /// déjà agi.
    pub async fn decider_substitution(
        &self,
        substitution_id: Uuid,
        client_id: Uuid,
        accepte: bool,
        maintenant: DateTime<Utc>,
    ) -> Result<(IssueSubstitution, MontantsRevises), ErreurCommandes> {
        let mut tx = self.pool.begin().await?;
        let sub = sqlx::query!(
            r#"SELECT sub.id, sub.ligne_id, sub.arret_id, sub.article_propose_id,
                      sub.prix_propose_unites, sub.echeance, sub.proposee_le,
                      sub.issue::text AS "issue!",
                      lc.commande_id, c.zone_id, c.client_id
               FROM commandes.substitution sub
               JOIN commandes.ligne_commande lc ON lc.id = sub.ligne_id
               JOIN commandes.commande c ON c.id = lc.commande_id
               WHERE sub.id = $1
               FOR UPDATE OF sub"#,
            substitution_id,
        )
        .fetch_optional(&mut *tx)
        .await?
        .ok_or(ErreurCommandes::SubstitutionInconnue(substitution_id))?;

        if sub.client_id != client_id {
            return Err(ErreurCommandes::NonProprietaire);
        }
        if sub.issue != IssueSubstitution::EnAttente.comme_str() {
            return Err(ErreurCommandes::SubstitutionExpiree);
        }
        if sub.echeance <= maintenant {
            return Err(ErreurCommandes::SubstitutionExpiree);
        }

        let issue = if accepte {
            IssueSubstitution::Acceptee
        } else {
            IssueSubstitution::Refusee
        };
        self.clore_substitution(
            &mut tx,
            substitution_id,
            sub.ligne_id,
            sub.commande_id,
            issue,
            sub.article_propose_id,
            sub.prix_propose_unites,
            (maintenant - sub.proposee_le).num_seconds().max(0),
            Some(client_id),
            maintenant,
        )
        .await?;

        let montants = self.reviser_montants(&mut tx, sub.commande_id).await?;
        tx.commit().await?;
        Ok((issue, montants))
    }

    /// Balaye les propositions ÉCHUES et les résout (research R10).
    ///
    /// Le chemin est celui de FR-046 : à l'expiration on **appelle**
    /// (`appel.intention`), et le client restant injoignable, l'article est
    /// **retiré et non facturé**. L'appel n'est pas une politesse : c'est ce
    /// qui distingue « on a essayé » de « on a décidé à votre place ».
    ///
    /// Idempotent : une proposition déjà close n'est plus candidate (l'index
    /// partiel `substitution_echeance` ne porte que `en_attente`).
    pub async fn expirer_substitutions_echues(
        &self,
        maintenant: DateTime<Utc>,
    ) -> Result<Vec<Uuid>, ErreurCommandes> {
        let echues = sqlx::query!(
            r#"SELECT sub.id, sub.ligne_id, sub.article_propose_id,
                      sub.prix_propose_unites, sub.proposee_le,
                      lc.commande_id
               FROM commandes.substitution sub
               JOIN commandes.ligne_commande lc ON lc.id = sub.ligne_id
               WHERE sub.issue = 'en_attente' AND sub.echeance <= $1
               ORDER BY sub.echeance"#,
            maintenant,
        )
        .fetch_all(&self.pool)
        .await?;

        let mut expirees = Vec::new();
        for sub in echues {
            let mut tx = self.pool.begin().await?;
            // 1. On APPELLE (FR-046).
            ecrire_evenement(
                &mut tx,
                NouvelEvenement {
                    type_evenement: "appel.intention",
                    entite_type: "commande",
                    entite_id: sub.commande_id,
                    payload: json!({
                        "de": "systeme",
                        "vers": "client",
                        "motif": "expiration",
                    }),
                    survenu_le: maintenant,
                },
            )
            .await?;
            // 2. Injoignable → l'article est retiré, et non facturé.
            self.clore_substitution(
                &mut tx,
                sub.id,
                sub.ligne_id,
                sub.commande_id,
                IssueSubstitution::ExpireeAppel,
                sub.article_propose_id,
                sub.prix_propose_unites,
                (maintenant - sub.proposee_le).num_seconds().max(0),
                None,
                maintenant,
            )
            .await?;
            self.reviser_montants(&mut tx, sub.commande_id).await?;
            tx.commit().await?;
            expirees.push(sub.id);
        }
        Ok(expirees)
    }

    /// Clôt une proposition et applique son effet sur la ligne.
    #[allow(clippy::too_many_arguments)]
    async fn clore_substitution(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        substitution_id: Uuid,
        ligne_id: Uuid,
        commande_id: Uuid,
        issue: IssueSubstitution,
        article_propose_id: Uuid,
        prix_propose_unites: i64,
        delai_reponse_s: i64,
        acteur: Option<Uuid>,
        maintenant: DateTime<Utc>,
    ) -> Result<(), ErreurCommandes> {
        sqlx::query!(
            "UPDATE commandes.substitution
                SET issue = $2::text::commandes.issue_substitution, decidee_le = $3
              WHERE id = $1",
            substitution_id,
            issue.comme_str(),
            maintenant,
        )
        .execute(&mut **tx)
        .await?;

        match issue {
            IssueSubstitution::Acceptee => {
                sqlx::query!(
                    "UPDATE commandes.ligne_commande
                        SET statut = 'remplacee',
                            remplace_par_article_id = $2,
                            remplace_prix_unites = $3
                      WHERE id = $1",
                    ligne_id,
                    article_propose_id,
                    prix_propose_unites,
                )
                .execute(&mut **tx)
                .await?;
            }
            // Refus ou expiration : l'article sort, et rien n'est payé pour lui.
            IssueSubstitution::Refusee | IssueSubstitution::ExpireeAppel => {
                let motif = if issue == IssueSubstitution::Refusee {
                    motifs::REFUS
                } else {
                    motifs::EXPIRATION
                };
                self.retirer_ligne_par_id(tx, ligne_id, commande_id, motif, maintenant)
                    .await?;
            }
            IssueSubstitution::EnAttente | IssueSubstitution::Retiree => {}
        }

        ecrire_evenement(
            tx,
            NouvelEvenement {
                type_evenement: "substitution.decidee",
                entite_type: "substitution",
                entite_id: substitution_id,
                payload: json!({
                    "commande": commande_id,
                    "issue": issue.comme_str(),
                    "delai_reponse_s": delai_reponse_s,
                    "acteur": acteur,
                }),
                survenu_le: maintenant,
            },
        )
        .await?;
        Ok(())
    }

    /// Contexte d'une ligne déclarée en rupture, avec la garde de PROPRIÉTÉ :
    /// la ligne doit appartenir à une course assignée à l'appelant.
    async fn ligne_en_rupture(
        &self,
        ligne_id: Uuid,
        coursier: Uuid,
    ) -> Result<LigneEnRupture, ErreurCommandes> {
        let ligne = sqlx::query!(
            // Le LEFT JOIN sur `livraison` empêche sqlx de prouver la
            // non-nullabilité des colonnes des tables jointes AVANT lui : elles
            // sont donc réaffirmées à la main. Seul `l.coursier_id`, qui vient
            // du côté FACULTATIF de la jointure, reste un `Option`.
            r#"SELECT lc.id AS "id!", lc.commande_id AS "commande_id!",
                      lc.prestataire_id AS "prestataire_id!",
                      lc.arret_id AS "arret_id?", lc.quantite AS "quantite!",
                      lc.statut::text AS "statut!",
                      lc.preference::text AS "preference!",
                      pf.prix_unites AS "prix_unites!", c.zone_id AS "zone_id!",
                      l.coursier_id
               FROM commandes.ligne_commande lc
               JOIN prestataires.prix_fige pf ON pf.id = lc.prix_fige_id
               JOIN commandes.commande c ON c.id = lc.commande_id
               LEFT JOIN commandes.livraison l ON l.commande_id = c.id
               WHERE lc.id = $1"#,
            ligne_id,
        )
        .fetch_optional(&self.pool)
        .await?
        .ok_or(ErreurCommandes::ArticleIndisponible(ligne_id))?;

        if ligne.coursier_id != Some(coursier) {
            return Err(ErreurCommandes::NonProprietaire);
        }
        // Une ligne déjà retirée ou remplacée n'est plus en rupture : rejouer
        // dessus doublerait le retrait du montant.
        if ligne.statut != StatutLigne::Presente.comme_str() {
            return Err(ErreurCommandes::EtatIncompatible {
                avant: ligne.statut.clone(),
                apres: "retiree".to_owned(),
            });
        }

        Ok(LigneEnRupture {
            ligne_id: ligne.id,
            commande_id: ligne.commande_id,
            zone_id: ligne.zone_id,
            prestataire_id: ligne.prestataire_id,
            arret_id: ligne.arret_id.ok_or(ErreurCommandes::ArretInconnu(ligne_id))?,
            quantite: ligne.quantite,
            prix_unitaire_unites: ligne.prix_unites,
            preference: ligne.preference.parse()?,
        })
    }

    /// Proposition déjà ouverte sous cet `uuid_client` (rejeu idempotent).
    async fn proposition_par_uuid_client(
        &self,
        uuid_client: Uuid,
        maintenant: DateTime<Utc>,
    ) -> Result<Option<IssueRupture>, ErreurCommandes> {
        let sub = sqlx::query!(
            "SELECT id, echeance FROM commandes.substitution WHERE uuid_client = $1",
            uuid_client,
        )
        .fetch_optional(&self.pool)
        .await?;
        Ok(sub.map(|s| IssueRupture::PropositionOuverte {
            substitution_id: s.id,
            reste_s: (s.echeance - maintenant).num_seconds().max(0),
            ecart_pourcent: 0,
        }))
    }

    /// Retire une ligne connue, avec son événement. Renvoie le montant sorti.
    async fn retirer_ligne(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        ligne: &LigneEnRupture,
        motif: &str,
        maintenant: DateTime<Utc>,
    ) -> Result<i64, ErreurCommandes> {
        self.retirer_ligne_par_id(tx, ligne.ligne_id, ligne.commande_id, motif, maintenant)
            .await
    }

    /// Retire une ligne par son identifiant, avec son `ligne.retiree`.
    async fn retirer_ligne_par_id(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        ligne_id: Uuid,
        commande_id: Uuid,
        motif: &str,
        maintenant: DateTime<Utc>,
    ) -> Result<i64, ErreurCommandes> {
        let ligne = sqlx::query!(
            r#"SELECT lc.quantite * COALESCE(lc.remplace_prix_unites, pf.prix_unites)
                          AS "montant!",
                      pf.devise
               FROM commandes.ligne_commande lc
               JOIN prestataires.prix_fige pf ON pf.id = lc.prix_fige_id
               WHERE lc.id = $1"#,
            ligne_id,
        )
        .fetch_one(&mut **tx)
        .await?;

        sqlx::query!(
            "UPDATE commandes.ligne_commande SET statut = 'retiree' WHERE id = $1",
            ligne_id,
        )
        .execute(&mut **tx)
        .await?;

        ecrire_evenement(
            tx,
            NouvelEvenement {
                type_evenement: "ligne.retiree",
                entite_type: "ligne_commande",
                entite_id: ligne_id,
                payload: json!({
                    "commande": commande_id,
                    "motif": motif,
                    "montant_retire": ligne.montant,
                    "devise": ligne.devise,
                }),
                survenu_le: maintenant,
            },
        )
        .await?;
        Ok(ligne.montant)
    }
}

/// Contexte d'une ligne en rupture.
struct LigneEnRupture {
    ligne_id: Uuid,
    commande_id: Uuid,
    zone_id: Uuid,
    prestataire_id: Uuid,
    arret_id: Uuid,
    #[allow(dead_code)]
    quantite: i16,
    prix_unitaire_unites: i64,
    preference: PreferenceSubstitution,
}

/// Écart de prix en pourcent, ARRONDI VERS ZÉRO (troncature).
///
/// Le sens de l'arrondi n'est pas neutre : arrondir au supérieur ferait
/// refuser un remplacement à exactement +20 % dès la moindre imprécision,
/// alors que le produit l'accepte (« +20 % accepté, +25 % refusé »). Un prix
/// d'origine nul rend 0 — aucun écart n'est mesurable sur rien.
fn ecart_pourcent(prix_origine: i64, prix_propose: i64) -> i64 {
    if prix_origine == 0 {
        return 0;
    }
    (prix_propose - prix_origine) * 100 / prix_origine
}

// ── T063 : purge des photos de substitution ───────────────────────────────

impl PgCommandes {
    /// Purge les photos de remplacement au-delà de la rétention de zone
    /// (`substitution.photo_retention_jours`).
    ///
    /// Même patron que les purges de repères vocaux (cycle 003) et de photos de
    /// collecte (cycle 006) : la rétention est un **paramètre de zone**, pas une
    /// durée en dur, et la purge est **best-effort** — un échec de suppression
    /// sur UN objet est journalisé et n'interrompt pas les autres. La clé reste
    /// alors en base et sera retentée au prochain passage : mieux vaut un
    /// orphelin rattrapable qu'une ligne qui pointe vers du vide.
    ///
    /// La ligne `substitution` SURVIT à sa photo : elle porte la trace d'une
    /// décision d'argent (qui a proposé quoi, à quel prix, accepté ou non) et
    /// n'est pas une donnée personnelle. Seule l'image, qui peut montrer un
    /// lieu ou une personne, est minimisée (constitution VIII).
    pub async fn purger_photos_substitution(&self) -> Result<u64, ErreurCommandes> {
        let candidates = sqlx::query!(
            r#"SELECT sub.id, sub.photo_cle, sub.proposee_le, c.zone_id
               FROM commandes.substitution sub
               JOIN commandes.ligne_commande lc ON lc.id = sub.ligne_id
               JOIN commandes.commande c ON c.id = lc.commande_id
               WHERE sub.photo_cle <> ''"#,
        )
        .fetch_all(&self.pool)
        .await?;

        let mut purgees = 0_u64;
        for candidate in candidates {
            let jours = self
                .parametre_i64(candidate.zone_id, cles::PHOTO_RETENTION_JOURS)
                .await?;
            if Utc::now() < candidate.proposee_le + chrono::Duration::days(jours) {
                continue;
            }
            match self.objets.supprimer(&candidate.photo_cle).await {
                Ok(()) => {
                    sqlx::query!(
                        "UPDATE commandes.substitution SET photo_cle = '' WHERE id = $1",
                        candidate.id,
                    )
                    .execute(&self.pool)
                    .await?;
                    purgees += 1;
                }
                Err(e) => tracing::warn!(
                    cle = %candidate.photo_cle,
                    erreur = %e,
                    "purge d'une photo de substitution échouée — retentée au prochain passage",
                ),
            }
        }
        Ok(purgees)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn l_ecart_de_prix_se_mesure_sur_le_prix_unitaire() {
        // Les deux bornes du produit : +20 % passe, +25 % non.
        assert_eq!(ecart_pourcent(500, 600), 20);
        assert_eq!(ecart_pourcent(500, 625), 25);
        // Un remplacement MOINS cher est un écart négatif — borné lui aussi.
        assert_eq!(ecart_pourcent(500, 400), -20);
        // Prix d'origine nul : rien à mesurer, jamais une division par zéro.
        assert_eq!(ecart_pourcent(0, 600), 0);
    }
}
