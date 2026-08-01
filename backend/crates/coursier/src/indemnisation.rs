//! Indemnisations du coursier (FR-071, FR-072, FR-074).
//!
//! Le cycle 008 a livré l'arbre §7.5 : quand une issue d'échec décide qu'une
//! indemnisation est due, il émet `indemnisation.due` — un contrat **sans
//! consommateur**, écrit pour ce cycle. Le voici branché.
//!
//! **Deux temps, et c'est délibéré.** Une indemnisation naît `demandee` et ne
//! touche pas la caisse ; elle n'y entre qu'à la **validation** par
//! l'exploitation. Écrire l'argent dès la demande ferait apparaître dans la
//! poche de Yao une somme que personne n'a encore décidée — et une caisse qui
//! annonce de l'argent qu'on peut lui refuser est pire qu'une caisse muette.
//!
//! **Le refus exige un motif** (FR-072). Un refus sans raison est ce qui rend
//! une promesse d'indemnisation invérifiable : Yao doit pouvoir lire pourquoi.

use serde_json::json;
use socle::{EvenementPublie, NouvelEvenement};
use uuid::Uuid;

use crate::caisse::DemandeEcriture;
use crate::depot::PgCoursier;
use crate::modele::{
    ErreurCoursier, EtatIndemnisation, IndemnisationVue, TypeEcriture,
};

/// Ce qu'une décision d'exploitation produit.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct DecisionIndemnisation {
    /// Indemnisation décidée.
    pub id: Uuid,
    /// Nouvel état.
    pub etat: EtatIndemnisation,
    /// Écriture de caisse produite — seulement à la validation.
    pub ecriture_id: Option<Uuid>,
}

impl PgCoursier {
    /// `indemnisation.due` → une ligne à l'état `demandee` (contrat §1).
    ///
    /// Idempotent par `evenement_id` : le worker livre au moins une fois.
    pub(crate) async fn indemnisation_demandee(
        &self,
        e: &EvenementPublie,
    ) -> Result<(), ErreurCoursier> {
        let montant = e.payload["montant"].as_i64().unwrap_or(0);
        if montant <= 0 {
            return Ok(());
        }
        let (Some(commande), Some(coursier)) = (
            e.payload["commande"].as_str().and_then(|s| s.parse().ok()),
            e.payload["coursier"].as_str().and_then(|s| s.parse().ok()),
        ) else {
            tracing::warn!(evenement = %e.id, "indemnisation.due sans commande ni coursier");
            return Ok(());
        };
        let commande: Uuid = commande;
        let coursier: Uuid = coursier;
        let devise = e.payload["devise"].as_str().unwrap_or_default().to_owned();

        sqlx::query!(
            r#"INSERT INTO coursier.indemnisation
                   (id, coursier_id, commande_id, issue_echec_id, montant_unites,
                    devise, etat, motif_cle, evenement_id)
               VALUES ($1, $2, $3, $4, $5, $6, 'demandee', $7, $8)
               ON CONFLICT (evenement_id) DO NOTHING"#,
            Uuid::now_v7(),
            coursier,
            commande,
            // L'entité de `indemnisation.due` EST l'issue d'échec (taxonomie).
            e.entite_id,
            montant,
            devise,
            // Le motif vient de l'arbre §7.5 ; à défaut, une clé générique —
            // jamais du texte libre (constitution VII).
            e.payload["motif_cle"]
                .as_str()
                .unwrap_or("indemnisation.issue_echec"),
            e.id,
        )
        .execute(&self.pool)
        .await?;
        Ok(())
    }

    /// Valide une indemnisation : l'argent entre au livre (FR-072).
    ///
    /// L'écriture de caisse et l'événement sont dans la MÊME transaction que le
    /// changement d'état — une validation sans son écriture laisserait Yao avec
    /// une promesse et rien dans sa caisse.
    pub async fn valider_indemnisation(
        &self,
        indemnisation: Uuid,
        acteur: Uuid,
    ) -> Result<DecisionIndemnisation, ErreurCoursier> {
        let mut tx = self.pool.begin().await?;
        let ligne = sqlx::query!(
            r#"UPDATE coursier.indemnisation
                  SET etat = 'validee', decide_par = $2, decide_le = now()
                WHERE id = $1 AND etat = 'demandee'
            RETURNING coursier_id, commande_id, montant_unites, devise, litige_id"#,
            indemnisation,
            acteur,
        )
        .fetch_optional(&mut *tx)
        .await?;

        let Some(l) = ligne else {
            tx.rollback().await?;
            return Err(self.pourquoi_pas_decidable(indemnisation).await);
        };

        let ecriture_id = self
            .ecrire_caisse(
                &mut tx,
                l.coursier_id,
                DemandeEcriture {
                    type_ecriture: TypeEcriture::Indemnisation,
                    // SIGNE POSITIF : l'argent entre dans la poche de Yao.
                    montant_unites: l.montant_unites,
                    devise: l.devise.clone(),
                    commande_id: Some(l.commande_id),
                    livraison_id: None,
                    arret_id: None,
                    indemnisation_id: Some(indemnisation),
                    // Décision humaine : aucun événement d'outbox ne la porte,
                    // donc aucune clé d'idempotence. La garde `etat = 'demandee'`
                    // de l'UPDATE tient déjà l'unicité — une seconde validation
                    // ne trouve plus de ligne à mettre à jour.
                    evenement_id: None,
                    source: "admin",
                },
            )
            .await?;

        socle::ecrire_evenement(
            &mut tx,
            NouvelEvenement {
                type_evenement: "indemnisation.validee",
                entite_type: "indemnisation",
                entite_id: indemnisation,
                payload: json!({
                    "coursier": l.coursier_id,
                    "commande": l.commande_id,
                    "montant": l.montant_unites,
                    "devise": l.devise,
                    "litige": l.litige_id,
                    "acteur": acteur,
                }),
                survenu_le: self.maintenant(),
            },
        )
        .await?;
        tx.commit().await?;

        Ok(DecisionIndemnisation {
            id: indemnisation,
            etat: EtatIndemnisation::Validee,
            ecriture_id,
        })
    }

    /// Refuse une indemnisation — **motif obligatoire** (FR-072).
    ///
    /// Aucune écriture de caisse : rien n'entre, rien ne sort. Ce que Yao doit
    /// pouvoir lire, c'est la raison.
    pub async fn refuser_indemnisation(
        &self,
        indemnisation: Uuid,
        acteur: Uuid,
        motif_cle: &str,
    ) -> Result<DecisionIndemnisation, ErreurCoursier> {
        if motif_cle.trim().is_empty() {
            return Err(ErreurCoursier::MotifRequis);
        }
        let mut tx = self.pool.begin().await?;
        let ligne = sqlx::query!(
            r#"UPDATE coursier.indemnisation
                  SET etat = 'refusee', decide_par = $2, decide_le = now(),
                      decision_motif_cle = $3
                WHERE id = $1 AND etat = 'demandee'
            RETURNING coursier_id, commande_id, montant_unites, devise"#,
            indemnisation,
            acteur,
            motif_cle,
        )
        .fetch_optional(&mut *tx)
        .await?;

        let Some(l) = ligne else {
            tx.rollback().await?;
            return Err(self.pourquoi_pas_decidable(indemnisation).await);
        };

        socle::ecrire_evenement(
            &mut tx,
            NouvelEvenement {
                type_evenement: "indemnisation.refusee",
                entite_type: "indemnisation",
                entite_id: indemnisation,
                payload: json!({
                    "coursier": l.coursier_id,
                    "commande": l.commande_id,
                    "montant": l.montant_unites,
                    "devise": l.devise,
                    "motif_cle": motif_cle,
                    "acteur": acteur,
                }),
                survenu_le: self.maintenant(),
            },
        )
        .await?;
        tx.commit().await?;

        Ok(DecisionIndemnisation {
            id: indemnisation,
            etat: EtatIndemnisation::Refusee,
            ecriture_id: None,
        })
    }

    /// Distingue « inconnue » de « déjà décidée » — deux refus différents, deux
    /// conduites à tenir différentes pour l'exploitation.
    async fn pourquoi_pas_decidable(&self, indemnisation: Uuid) -> ErreurCoursier {
        match sqlx::query_scalar!(
            "SELECT etat::text FROM coursier.indemnisation WHERE id = $1",
            indemnisation,
        )
        .fetch_optional(&self.pool)
        .await
        {
            Ok(Some(_)) => ErreurCoursier::IndemnisationDejaDecidee,
            Ok(None) => ErreurCoursier::IndemnisationInconnue(indemnisation),
            Err(e) => ErreurCoursier::Sql(e),
        }
    }

    /// Indemnisations d'un coursier, la plus récente d'abord (K5-1a).
    pub(crate) async fn indemnisations_du_coursier(
        &self,
        coursier: Uuid,
    ) -> Result<Vec<IndemnisationVue>, ErreurCoursier> {
        self.lire_indemnisations(Some(coursier), None).await
    }

    /// File des indemnisations pour l'exploitation, filtrable par état (FR-071).
    pub async fn indemnisations(
        &self,
        etat: Option<EtatIndemnisation>,
    ) -> Result<Vec<IndemnisationVue>, ErreurCoursier> {
        self.lire_indemnisations(None, etat).await
    }

    async fn lire_indemnisations(
        &self,
        coursier: Option<Uuid>,
        etat: Option<EtatIndemnisation>,
    ) -> Result<Vec<IndemnisationVue>, ErreurCoursier> {
        let lignes = sqlx::query!(
            r#"SELECT i.id, i.commande_id,
                      i.montant_unites, i.devise, i.etat::text AS "etat!",
                      i.litige_id, i.motif_cle, i.decision_motif_cle,
                      i.decide_le, i.cree_le
                 FROM coursier.indemnisation i
                WHERE ($1::uuid IS NULL OR i.coursier_id = $1)
                  AND ($2::text IS NULL OR i.etat::text = $2)
                ORDER BY i.cree_le DESC"#,
            coursier,
            etat.map(|e| e.comme_str()),
        )
        .fetch_all(&self.pool)
        .await?;

        lignes
            .into_iter()
            .map(|l| {
                Ok(IndemnisationVue {
                    id: l.id,
                    commande_id: l.commande_id,
                    // Dérivée de l'identifiant (patron `exploitation`) :
                    // une colonne de plus serait une chaîne à resynchroniser.
                    commande_reference: commandes::reference_courte(l.commande_id),
                    montant_unites: l.montant_unites,
                    devise: l.devise,
                    etat: l.etat.parse()?,
                    litige_id: l.litige_id,
                    motif_cle: l.motif_cle,
                    decision_motif_cle: l.decision_motif_cle,
                    decide_le: l.decide_le,
                    cree_le: l.cree_le,
                })
            })
            .collect()
    }
}
