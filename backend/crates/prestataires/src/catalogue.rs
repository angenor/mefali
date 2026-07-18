//! Catalogue de l'extension VENDEUR : articles, prix, retrait réversible et
//! verrouillage de prix (FR-020..024, FR-055 — data-model §3.8, §3.11).
//!
//! Tout montant est un ENTIER en unités mineures ; la devise est POSÉE PAR LE
//! SERVEUR depuis la zone du prestataire, jamais fournie par le client
//! (constitution III, research R13). Le CHECK `prix_barre_strictement_superieur`
//! double la validation applicative au niveau du schéma (SC-006).

use chrono::{DateTime, Utc};
use serde_json::json;
use socle::{ecrire_evenement, NouvelEvenement};
use uuid::Uuid;

use crate::depot::PgPrestataires;
use crate::modele::{ErreurPrestataires, SourceBascule};
use crate::prestataire::{PHOTO_MIMES, PHOTO_TAILLE_MAX};

/// Article du catalogue, vue vendeur/admin (disponibilité du site unique
/// jointe — FR-018).
#[derive(Debug, Clone, PartialEq)]
pub struct Article {
    /// Identifiant.
    pub id: Uuid,
    /// Prestataire (extension vendeur) porteur.
    pub vendeur_id: Uuid,
    /// Nom (contenu vendeur).
    pub nom: String,
    /// Prix courant, entier en unités mineures.
    pub prix_unites: i64,
    /// Code ISO 4217 (posé par le serveur).
    pub devise: String,
    /// Prix barré — strictement supérieur, purement informatif (FR-023).
    pub prix_barre_unites: Option<i64>,
    /// Clé S3 de la photo.
    pub photo_cle: Option<String>,
    /// Étiquette libre de regroupement (FR-021).
    pub categorie_interne: Option<String>,
    /// Retrait RÉVERSIBLE : `Some` = hors catalogue, la ligne subsiste (FR-055).
    pub retire_le: Option<DateTime<Utc>>,
    /// Disponible sur le site (vrai par défaut).
    pub disponible: bool,
    /// Source de la DERNIÈRE bascule de disponibilité (FR-037).
    pub source_derniere_bascule: Option<SourceBascule>,
}

impl Article {
    /// Rupture posée par l'Admin : seule une bascule admin la lève (FR-041).
    pub fn rupture_admin(&self) -> bool {
        !self.disponible && self.source_derniere_bascule == Some(SourceBascule::Admin)
    }
}

/// Champs de création d'un article (disponible par défaut — FR-020).
#[derive(Debug, Clone)]
pub struct NouvelArticle {
    /// Nom.
    pub nom: String,
    /// Prix courant, entier en unités mineures.
    pub prix_unites: i64,
    /// Prix barré optionnel (strictement supérieur — FR-023).
    pub prix_barre_unites: Option<i64>,
    /// Étiquette libre.
    pub categorie_interne: Option<String>,
}

/// Modification partielle (`None` = inchangé ; `Some(None)` = effacer).
#[derive(Debug, Clone, Default)]
pub struct ModificationArticle {
    /// Nouveau nom.
    pub nom: Option<String>,
    /// Nouveau prix courant.
    pub prix_unites: Option<i64>,
    /// Nouveau prix barré — `Some(None)` retire la promotion EXPLICITEMENT.
    pub prix_barre_unites: Option<Option<i64>>,
    /// Nouvelle étiquette — `Some(None)` l'efface.
    pub categorie_interne: Option<Option<String>>,
}

/// Prix figé (FR-024) — un montant figé ne bouge JAMAIS (SC-005).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PrixFige {
    /// Identifiant du verrou.
    pub id: Uuid,
    /// Article verrouillé.
    pub article_id: Uuid,
    /// Montant figé, entier en unités mineures.
    pub prix_unites: i64,
    /// Devise du montant figé.
    pub devise: String,
    /// Prix barré au moment du verrou (informatif).
    pub prix_barre_unites: Option<i64>,
    /// Instant du verrou.
    pub fige_le: DateTime<Utc>,
}

impl PgPrestataires {
    // ── Création et modification (FR-020..023) ─────────────────────────────

    /// Crée un article — disponible par défaut sur chaque site du prestataire,
    /// devise lue de la zone (R13). Émet `article.cree`.
    pub async fn creer_article(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        prestataire: Uuid,
        nouveau: &NouvelArticle,
        source: SourceBascule,
        acteur: Uuid,
    ) -> Result<Article, ErreurPrestataires> {
        let p = self.prestataire_dans_tx(tx, prestataire).await?;
        valider_article(&nouveau.nom, nouveau.prix_unites, nouveau.prix_barre_unites)?;
        let devise = {
            use zones::ConfigurationZones;
            self.zones.devise(p.ville_id).await?.code
        };

        let id = Uuid::now_v7();
        sqlx::query!(
            "INSERT INTO prestataires.article
                 (id, vendeur_id, nom, prix_unites, devise, prix_barre_unites, categorie_interne)
             VALUES ($1, $2, $3, $4, $5, $6, $7)",
            id,
            prestataire,
            nouveau.nom.trim(),
            nouveau.prix_unites,
            devise,
            nouveau.prix_barre_unites,
            nouveau.categorie_interne.as_deref().map(str::trim),
        )
        .execute(&mut **tx)
        .await?;
        // Une ligne de disponibilité par site — vraie par défaut (FR-020) ;
        // MVP : le site unique, le modèle en accepte n (provision VND-06).
        sqlx::query!(
            "INSERT INTO prestataires.disponibilite_article (article_id, site_id)
             SELECT $1, id FROM prestataires.site WHERE prestataire_id = $2",
            id,
            prestataire,
        )
        .execute(&mut **tx)
        .await?;

        ecrire_evenement(
            tx,
            NouvelEvenement {
                type_evenement: "article.cree",
                entite_type: "article",
                entite_id: id,
                payload: json!({
                    "prestataire": prestataire,
                    "prix": nouveau.prix_unites,
                    "devise": devise,
                    "prix_barre": nouveau.prix_barre_unites,
                    "source": source.comme_str(),
                    "acteur": acteur,
                }),
                survenu_le: Utc::now(),
            },
        )
        .await?;
        self.article_dans_tx(tx, prestataire, id).await
    }

    /// Modifie un article NON retiré. Un prix barré qui deviendrait ≤ prix
    /// courant fait ÉCHOUER l'opération — la promotion n'est jamais retirée en
    /// silence (FR-023, edge case spec). Émet `article.modifie`.
    pub async fn modifier_article(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        prestataire: Uuid,
        article: Uuid,
        modification: &ModificationArticle,
        source: SourceBascule,
        acteur: Uuid,
    ) -> Result<Article, ErreurPrestataires> {
        let courant = self.article_dans_tx(tx, prestataire, article).await?;
        if courant.retire_le.is_some() {
            return Err(ErreurPrestataires::ArticleRetire(article));
        }

        let mut champs: Vec<&str> = Vec::new();
        let nom = match &modification.nom {
            Some(n) => {
                champs.push("nom");
                n.clone()
            }
            None => courant.nom.clone(),
        };
        let prix = match modification.prix_unites {
            Some(p) => {
                champs.push("prix");
                p
            }
            None => courant.prix_unites,
        };
        let prix_barre = match &modification.prix_barre_unites {
            Some(pb) => {
                champs.push("prix_barre");
                *pb
            }
            None => courant.prix_barre_unites,
        };
        let categorie_interne = match &modification.categorie_interne {
            Some(c) => {
                champs.push("categorie_interne");
                c.clone()
            }
            None => courant.categorie_interne.clone(),
        };
        if champs.is_empty() {
            return Ok(courant);
        }
        valider_article(&nom, prix, prix_barre)?;

        sqlx::query!(
            "UPDATE prestataires.article
             SET nom = $3, prix_unites = $4, prix_barre_unites = $5,
                 categorie_interne = $6, modifie_le = now()
             WHERE id = $2 AND vendeur_id = $1",
            prestataire,
            article,
            nom.trim(),
            prix,
            prix_barre,
            categorie_interne.as_deref().map(str::trim),
        )
        .execute(&mut **tx)
        .await?;

        let mut payload = json!({
            "prestataire": prestataire,
            "champs": champs,
            "source": source.comme_str(),
            "acteur": acteur,
        });
        if champs.contains(&"prix") {
            payload["prix"] = json!(prix);
        }
        if champs.contains(&"prix_barre") {
            payload["prix_barre"] = json!(prix_barre);
        }
        ecrire_evenement(
            tx,
            NouvelEvenement {
                type_evenement: "article.modifie",
                entite_type: "article",
                entite_id: article,
                payload,
                survenu_le: Utc::now(),
            },
        )
        .await?;
        self.article_dans_tx(tx, prestataire, article).await
    }

    /// Dépose/remplace la photo (clé NEUVE) — rend la clé remplacée, ORPHELINE
    /// à purger APRÈS commit. Émet `article.modifie` (`champs: ["photo"]`).
    pub async fn photo_article(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        prestataire: Uuid,
        article: Uuid,
        octets: Vec<u8>,
        mime: &str,
        source: SourceBascule,
        acteur: Uuid,
    ) -> Result<(Article, Option<String>), ErreurPrestataires> {
        let courant = self.article_dans_tx(tx, prestataire, article).await?;
        if courant.retire_le.is_some() {
            return Err(ErreurPrestataires::ArticleRetire(article));
        }
        crate::prestataire::valider_media(&octets, mime, PHOTO_MIMES, PHOTO_TAILLE_MAX)?;

        let cle = format!("prestataires/articles/{article}/{}", Uuid::now_v7());
        self.objets.deposer(&cle, octets, mime).await?;
        sqlx::query!(
            "UPDATE prestataires.article SET photo_cle = $3, modifie_le = now()
             WHERE id = $2 AND vendeur_id = $1",
            prestataire,
            article,
            cle,
        )
        .execute(&mut **tx)
        .await?;

        ecrire_evenement(
            tx,
            NouvelEvenement {
                type_evenement: "article.modifie",
                entite_type: "article",
                entite_id: article,
                payload: json!({
                    "prestataire": prestataire,
                    "champs": ["photo"],
                    "source": source.comme_str(),
                    "acteur": acteur,
                }),
                survenu_le: Utc::now(),
            },
        )
        .await?;
        let apres = self.article_dans_tx(tx, prestataire, article).await?;
        Ok((apres, courant.photo_cle))
    }

    // ── Retrait réversible (FR-055) ────────────────────────────────────────

    /// Retire l'article du catalogue : plus servi, plus commandable, plus
    /// signalable — la LIGNE subsiste (commandes passées, agrégats). Rejouer
    /// le retrait est sans effet (ni écriture ni événement).
    pub async fn retirer_article(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        prestataire: Uuid,
        article: Uuid,
        source: SourceBascule,
        acteur: Uuid,
    ) -> Result<Article, ErreurPrestataires> {
        let courant = self.article_dans_tx(tx, prestataire, article).await?;
        if courant.retire_le.is_some() {
            return Ok(courant);
        }
        sqlx::query!(
            "UPDATE prestataires.article SET retire_le = now(), modifie_le = now()
             WHERE id = $2 AND vendeur_id = $1",
            prestataire,
            article,
        )
        .execute(&mut **tx)
        .await?;
        ecrire_evenement(
            tx,
            NouvelEvenement {
                type_evenement: "article.retire_du_catalogue",
                entite_type: "article",
                entite_id: article,
                payload: json!({
                    "prestataire": prestataire,
                    "source": source.comme_str(),
                    "acteur": acteur,
                }),
                survenu_le: Utc::now(),
            },
        )
        .await?;
        self.article_dans_tx(tx, prestataire, article).await
    }

    /// Remet un article retiré au catalogue SANS ressaisie : il revient avec
    /// son historique et sa disponibilité telle qu'elle était (FR-055).
    pub async fn remettre_article(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        prestataire: Uuid,
        article: Uuid,
        source: SourceBascule,
        acteur: Uuid,
    ) -> Result<Article, ErreurPrestataires> {
        let courant = self.article_dans_tx(tx, prestataire, article).await?;
        if courant.retire_le.is_none() {
            return Ok(courant);
        }
        sqlx::query!(
            "UPDATE prestataires.article SET retire_le = NULL, modifie_le = now()
             WHERE id = $2 AND vendeur_id = $1",
            prestataire,
            article,
        )
        .execute(&mut **tx)
        .await?;
        ecrire_evenement(
            tx,
            NouvelEvenement {
                type_evenement: "article.remis_au_catalogue",
                entite_type: "article",
                entite_id: article,
                payload: json!({
                    "prestataire": prestataire,
                    "source": source.comme_str(),
                    "acteur": acteur,
                }),
                survenu_le: Utc::now(),
            },
        )
        .await?;
        self.article_dans_tx(tx, prestataire, article).await
    }

    // ── Verrouillage de prix (FR-024, CMD-03 à venir — research R6) ────────

    /// Fige le prix COURANT de l'article : la copie ne bougera JAMAIS, quelle
    /// que soit la suite des modifications (SC-005 — aucun UPDATE n'existe sur
    /// `prix_fige`). Appelé par le module commandes DANS sa transaction de
    /// création (déclencheur simulé par les tests d'ici là).
    pub async fn figer_prix(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        prestataire: Uuid,
        article: Uuid,
    ) -> Result<PrixFige, ErreurPrestataires> {
        let courant = self.article_dans_tx(tx, prestataire, article).await?;
        if courant.retire_le.is_some() {
            return Err(ErreurPrestataires::ArticleRetire(article));
        }
        let id = Uuid::now_v7();
        let ligne = sqlx::query!(
            "INSERT INTO prestataires.prix_fige
                 (id, article_id, prix_unites, devise, prix_barre_unites)
             VALUES ($1, $2, $3, $4, $5)
             RETURNING fige_le",
            id,
            article,
            courant.prix_unites,
            courant.devise,
            courant.prix_barre_unites,
        )
        .fetch_one(&mut **tx)
        .await?;
        Ok(PrixFige {
            id,
            article_id: article,
            prix_unites: courant.prix_unites,
            devise: courant.devise,
            prix_barre_unites: courant.prix_barre_unites,
            fige_le: ligne.fige_le,
        })
    }

    /// Un prix figé, relu (les tests prouvent son invariance — SC-005).
    pub async fn prix_fige(&self, id: Uuid) -> Result<PrixFige, ErreurPrestataires> {
        let l = sqlx::query!(
            "SELECT id, article_id, prix_unites, devise, prix_barre_unites, fige_le
             FROM prestataires.prix_fige WHERE id = $1",
            id,
        )
        .fetch_optional(&self.pool)
        .await?
        .ok_or(ErreurPrestataires::ArticleInconnu(id))?;
        Ok(PrixFige {
            id: l.id,
            article_id: l.article_id,
            prix_unites: l.prix_unites,
            devise: l.devise,
            prix_barre_unites: l.prix_barre_unites,
            fige_le: l.fige_le,
        })
    }

    // ── Lectures ───────────────────────────────────────────────────────────

    /// Catalogue complet du prestataire (vue vendeur V2 : ruptures, retirés et
    /// verrou admin visibles).
    pub async fn articles_du_vendeur(
        &self,
        prestataire: Uuid,
    ) -> Result<Vec<Article>, ErreurPrestataires> {
        let mut tx = self.pool.begin().await?;
        let lignes = sqlx::query!(
            r#"SELECT a.id, a.vendeur_id, a.nom, a.prix_unites, a.devise,
                      a.prix_barre_unites, a.photo_cle, a.categorie_interne, a.retire_le,
                      COALESCE(d.disponible, true) AS "disponible!",
                      d.source::text AS "source_bascule"
               FROM prestataires.article a
               LEFT JOIN prestataires.site s ON s.prestataire_id = a.vendeur_id
               LEFT JOIN prestataires.disponibilite_article d
                 ON d.article_id = a.id AND d.site_id = s.id
               WHERE a.vendeur_id = $1
               ORDER BY a.retire_le NULLS FIRST, a.categorie_interne NULLS FIRST, a.nom"#,
            prestataire,
        )
        .fetch_all(&mut *tx)
        .await?;
        tx.commit().await?;
        lignes
            .into_iter()
            .map(|l| {
                Ok(Article {
                    id: l.id,
                    vendeur_id: l.vendeur_id,
                    nom: l.nom,
                    prix_unites: l.prix_unites,
                    devise: l.devise,
                    prix_barre_unites: l.prix_barre_unites,
                    photo_cle: l.photo_cle,
                    categorie_interne: l.categorie_interne,
                    retire_le: l.retire_le,
                    disponible: l.disponible,
                    source_derniere_bascule: l
                        .source_bascule
                        .map(|s| s.parse())
                        .transpose()
                        .map_err(ErreurPrestataires::FicheInvalide)?,
                })
            })
            .collect()
    }

    /// Un article du vendeur, dans la transaction (appartenance vérifiée).
    pub(crate) async fn article_dans_tx(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        prestataire: Uuid,
        article: Uuid,
    ) -> Result<Article, ErreurPrestataires> {
        let l = sqlx::query!(
            r#"SELECT a.id, a.vendeur_id, a.nom, a.prix_unites, a.devise,
                      a.prix_barre_unites, a.photo_cle, a.categorie_interne, a.retire_le,
                      COALESCE(d.disponible, true) AS "disponible!",
                      d.source::text AS "source_bascule"
               FROM prestataires.article a
               LEFT JOIN prestataires.site s ON s.prestataire_id = a.vendeur_id
               LEFT JOIN prestataires.disponibilite_article d
                 ON d.article_id = a.id AND d.site_id = s.id
               WHERE a.vendeur_id = $1 AND a.id = $2"#,
            prestataire,
            article,
        )
        .fetch_optional(&mut **tx)
        .await?
        .ok_or(ErreurPrestataires::ArticleInconnu(article))?;
        Ok(Article {
            id: l.id,
            vendeur_id: l.vendeur_id,
            nom: l.nom,
            prix_unites: l.prix_unites,
            devise: l.devise,
            prix_barre_unites: l.prix_barre_unites,
            photo_cle: l.photo_cle,
            categorie_interne: l.categorie_interne,
            retire_le: l.retire_le,
            disponible: l.disponible,
            source_derniere_bascule: l
                .source_bascule
                .map(|s| s.parse())
                .transpose()
                .map_err(ErreurPrestataires::FicheInvalide)?,
        })
    }

    /// Articles COMMANDABLES du prestataire (trait `Vendeurs`, cycle CMD) :
    /// vide si le prestataire lui-même n'est pas commandable (SC-004).
    pub async fn articles_commandables_de(
        &self,
        prestataire: Uuid,
    ) -> Result<Vec<crate::modele::ArticleCommandable>, ErreurPrestataires> {
        if !self.commandabilite(prestataire).await?.commandable() {
            return Ok(Vec::new());
        }
        let articles = self.articles_du_vendeur(prestataire).await?;
        Ok(articles
            .into_iter()
            .filter(|a| a.retire_le.is_none() && a.disponible)
            .map(|a| crate::modele::ArticleCommandable {
                id: a.id,
                nom: a.nom,
                prix_unites: a.prix_unites,
                devise: a.devise,
            })
            .collect())
    }
}

/// Nom non vide, montants entiers positifs, prix barré STRICTEMENT supérieur.
fn valider_article(
    nom: &str,
    prix_unites: i64,
    prix_barre_unites: Option<i64>,
) -> Result<(), ErreurPrestataires> {
    if nom.trim().is_empty() {
        return Err(ErreurPrestataires::FicheInvalide("nom d'article vide".to_owned()));
    }
    if prix_unites < 0 {
        return Err(ErreurPrestataires::MontantInvalide(
            "prix négatif".to_owned(),
        ));
    }
    if let Some(barre) = prix_barre_unites {
        if barre <= prix_unites {
            return Err(ErreurPrestataires::PrixBarreInvalide);
        }
    }
    Ok(())
}
