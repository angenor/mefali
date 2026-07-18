//! Dérivés de consultation : commandabilité (FR-028) et — livrée avec le
//! catalogue — la fiche publique (FR-027).
//!
//! Tout est DÉRIVÉ à la lecture : aucun de ces états n'est stocké, c'est ce
//! qui rend la suspension et les échéances effectives « dans la seconde »
//! (SC-002, SC-007).

use chrono::Utc;
use uuid::Uuid;

use crate::depot::PgPrestataires;
use crate::modele::{
    AffichageRupture, ArticlePublic, Commandabilite, EffectifBoutique, ErreurPrestataires,
    FichePublique, HorairesSemaine, StatutPrestataire,
};
use crate::site::{etat_effectif, Site};

/// TTL des URLs présignées de la consultation (photos — patron cycle 003).
const PRESIGNEE_TTL: std::time::Duration = std::time::Duration::from_secs(10 * 60);

impl PgPrestataires {
    /// FR-028 — la SEULE définition de « commandable » : agréé ∧ catégorie
    /// active dans sa ville ∧ boutique effectivement ouverte. Les modules
    /// ultérieurs (CMD) s'y réfèrent sans la redupliquer.
    pub async fn commandabilite(
        &self,
        prestataire: Uuid,
    ) -> Result<Commandabilite, ErreurPrestataires> {
        let mut tx = self.pool.begin().await?;
        let c = self.commandabilite_dans_tx(&mut tx, prestataire).await?;
        tx.commit().await?;
        Ok(c)
    }

    pub(crate) async fn commandabilite_dans_tx(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        prestataire: Uuid,
    ) -> Result<Commandabilite, ErreurPrestataires> {
        let p = self.prestataire_dans_tx(tx, prestataire).await?;
        let agree = p.statut == StatutPrestataire::Agree;
        let categorie_active = self
            .categorie_active_dans_tx(tx, p.ville_id, p.categorie_id)
            .await?;
        let boutique_ouverte = self
            .boutique_effective_dans_tx(tx, prestataire, agree, p.ville_id)
            .await?
            .map(|(_, _, effectif)| effectif.ouvert)
            .unwrap_or(false);
        Ok(Commandabilite {
            agree,
            categorie_active,
            boutique_ouverte,
        })
    }

    /// État EFFECTIF d'activation de la catégorie dans la ville (colonne
    /// générée `actif` — ZON-03) ; aucune ligne = jamais activée.
    pub(crate) async fn categorie_active_dans_tx(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        ville: Uuid,
        categorie: Uuid,
    ) -> Result<bool, ErreurPrestataires> {
        let actif = sqlx::query_scalar!(
            "SELECT actif FROM zones.activation_categorie
             WHERE zone_id = $1 AND categorie_id = $2",
            ville,
            categorie,
        )
        .fetch_optional(&mut **tx)
        .await?;
        Ok(actif.flatten().unwrap_or(false))
    }

    /// FR-027 — la fiche PUBLIQUE : le sous-ensemble destiné aux applications,
    /// sans contact, sans coordonnées de site, sans donnée d'exploitation
    /// (SC-013).
    ///
    /// `None` — la MÊME absence pour trois cas indistinguables (FR-017,
    /// research R9) : id inconnu, non agréé (prospect/suspendu), et catégorie
    /// INACTIVE dans la ville (edge case spec : la fiche n'est ni servie ni
    /// commandable tant que la catégorie n'est pas active). Boutique fermée ≠
    /// indisponible : la fiche est servie en lecture seule (FR-029).
    ///
    /// Articles : retirés ABSENTS (FR-055) ; en rupture, servis
    /// `disponible=false` si le mode de la catégorie est `grise`, ABSENTS si
    /// `masque` — le mode est appliqué ET servi (FR-042, FR-050, research R8).
    pub async fn fiche_publique_de(
        &self,
        prestataire: Uuid,
    ) -> Result<Option<FichePublique>, ErreurPrestataires> {
        let mut tx = self.pool.begin().await?;
        let p = match self.prestataire_dans_tx(&mut tx, prestataire).await {
            Ok(p) => p,
            Err(ErreurPrestataires::PrestataireInconnu(_)) => return Ok(None),
            Err(e) => return Err(e),
        };
        if p.statut != StatutPrestataire::Agree {
            return Ok(None);
        }
        if !self
            .categorie_active_dans_tx(&mut tx, p.ville_id, p.categorie_id)
            .await?
        {
            return Ok(None);
        }

        let Some((site, horaires, effectif)) = self
            .boutique_effective_dans_tx(&mut tx, prestataire, true, p.ville_id)
            .await?
        else {
            // Agréé sans site : impossible par l'agrément (FR-005) — neutre.
            return Ok(None);
        };

        let affichage_rupture = self.affichage_rupture_de(p.ville_id, &p.categorie_slug).await?;
        let lignes = sqlx::query!(
            r#"SELECT a.id, a.nom, a.prix_unites, a.devise, a.prix_barre_unites,
                      a.photo_cle, a.categorie_interne,
                      COALESCE(d.disponible, true) AS "disponible!"
               FROM prestataires.article a
               LEFT JOIN prestataires.disponibilite_article d
                 ON d.article_id = a.id AND d.site_id = $2
               WHERE a.vendeur_id = $1 AND a.retire_le IS NULL
               ORDER BY a.categorie_interne NULLS FIRST, a.nom"#,
            prestataire,
            site.id,
        )
        .fetch_all(&mut *tx)
        .await?;
        tx.commit().await?;

        let mut articles = Vec::with_capacity(lignes.len());
        for l in lignes {
            if !l.disponible && affichage_rupture == AffichageRupture::Masque {
                continue; // FR-042 : absent quand la catégorie masque
            }
            let photo_url = match &l.photo_cle {
                Some(cle) => Some(self.objets.presigner_get(cle, PRESIGNEE_TTL).await?.url),
                None => None,
            };
            articles.push(ArticlePublic {
                id: l.id,
                nom: l.nom,
                prix_unites: l.prix_unites,
                devise: l.devise,
                prix_barre_unites: l.prix_barre_unites,
                photo_url,
                categorie_interne: l.categorie_interne,
                disponible: l.disponible,
            });
        }

        let mut photos = Vec::new();
        for photo in self.photos(prestataire).await? {
            photos.push(
                self.objets
                    .presigner_get(&photo.cle_objet, PRESIGNEE_TTL)
                    .await?
                    .url,
            );
        }

        Ok(Some(FichePublique {
            id: p.id,
            nom: p.nom,
            categorie: p.categorie_slug,
            photos,
            delai_preparation_min: p.delai_preparation_min,
            commandable: effectif.ouvert, // agréé ∧ catégorie active déjà garantis ici
            boutique: effectif,
            horaires,
            affichage_rupture,
            articles,
        }))
    }

    /// Mode de rendu des ruptures pour la catégorie, résolu par héritage
    /// (`categorie.<slug>.affichage_rupture` — défaut `grise`, valeur seed).
    pub(crate) async fn affichage_rupture_de(
        &self,
        ville: Uuid,
        categorie_slug: &str,
    ) -> Result<AffichageRupture, ErreurPrestataires> {
        use zones::ConfigurationZones;
        let cle = format!("categorie.{categorie_slug}.affichage_rupture");
        let valeur = self.zones.parametre(ville, &cle).await?;
        Ok(valeur
            .as_ref()
            .and_then(|v| v.as_str())
            .and_then(|s| s.parse().ok())
            .unwrap_or(AffichageRupture::Grise))
    }

    /// Site + horaires + état effectif dérivé (lecture sur pool), ou `None`
    /// si aucun site n'est encore créé. Consommé par la couche `api`.
    pub async fn boutique(
        &self,
        prestataire: Uuid,
    ) -> Result<Option<(Site, HorairesSemaine, EffectifBoutique)>, ErreurPrestataires> {
        let mut tx = self.pool.begin().await?;
        let p = self.prestataire_dans_tx(&mut tx, prestataire).await?;
        let agree = p.statut == StatutPrestataire::Agree;
        let boutique = self
            .boutique_effective_dans_tx(&mut tx, prestataire, agree, p.ville_id)
            .await?;
        tx.commit().await?;
        Ok(boutique)
    }

    /// Site + horaires + état effectif dérivé, ou `None` si aucun site n'est
    /// encore créé (prospect en cours de constitution).
    pub(crate) async fn boutique_effective_dans_tx(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        prestataire: Uuid,
        agree: bool,
        ville: Uuid,
    ) -> Result<Option<(Site, HorairesSemaine, EffectifBoutique)>, ErreurPrestataires> {
        let Some(site) = self.site_optionnel_dans_tx(tx, prestataire).await? else {
            return Ok(None);
        };
        let horaires = self.horaires_dans_tx(tx, site.id).await?;
        let fuseau = self.fuseau_de(ville).await?;
        let effectif = etat_effectif(
            agree,
            site.statut_boutique,
            site.pause_fin,
            site.ferme_journee_le,
            &horaires,
            Utc::now().with_timezone(&fuseau),
        );
        Ok(Some((site, horaires, effectif)))
    }
}
