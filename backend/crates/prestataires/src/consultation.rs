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
    Commandabilite, EffectifBoutique, ErreurPrestataires, HorairesSemaine, StatutPrestataire,
};
use crate::site::{etat_effectif, Site};

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
