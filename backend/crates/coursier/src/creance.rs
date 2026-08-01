//! Créances de coursier — **ce que Mefali doit, sans mentir sur la poche**
//! (cycle PAY 011, research R12).
//!
//! # Pourquoi une table, et pas une écriture au livre
//!
//! Le livre de caisse suit la **trésorerie de poche** : ce que Yao a
//! physiquement sur lui. Sa documentation du cycle 010 est explicite — « écrire
//! un remboursement fictif ferait mentir un solde d'argent réel ». Une créance
//! n'est pas de l'argent en poche : c'est une promesse. L'inscrire au livre
//! casserait précisément l'invariant que le cycle 010 a défendu, et l'écran de
//! caisse — dont c'est la seule raison d'être — mentirait.
//!
//! Deux objets, deux sémantiques, une jointure. Le **règlement** d'une créance,
//! lui, écrit bien au livre : à ce moment-là, l'argent entre pour de vrai.
//!
//! # Elles naissent seules
//!
//! Clarification Q2, tranchée A : la créance naît **automatiquement** à la
//! livraison. Seul son règlement est un geste humain. Un produit qui demanderait
//! à un humain de créer la dette qu'il doit ensuite payer aurait exactement le
//! biais qu'on veut éviter.
//!
//! `evenement_id UNIQUE` porte l'idempotence : un rejeu du worker outbox, ou
//! une fin de course rejouée depuis la file hors-ligne, ne crée jamais de
//! doublon (FR-068, SC-008).

use chrono::{DateTime, Utc};
use serde_json::json;
use socle::NouvelEvenement;
use uuid::Uuid;

use crate::depot::PgCoursier;
use crate::modele::ErreurCoursier;

/// Nature d'une créance (enum `coursier.nature_creance`).
#[derive(Debug, Clone, Copy, PartialEq, Eq, sqlx::Type)]
#[sqlx(type_name = "nature_creance", rename_all = "snake_case")]
pub enum NatureCreance {
    /// Le client a prépayé : Mefali doit au coursier l'avance qu'il a engagée
    /// chez les vendeurs, et que le cash ne soldera jamais.
    AvancePrepayee,
    /// Le coursier n'a encaissé aucun frais — commande prépayée, ou livraison
    /// offerte par Mefali. Sa part de course reste due.
    PartCourse,
}

impl NatureCreance {
    /// Libellé SQL, aligné sur l'énumération.
    pub fn comme_str(&self) -> &'static str {
        match self {
            NatureCreance::AvancePrepayee => "avance_prepayee",
            NatureCreance::PartCourse => "part_course",
        }
    }
}

/// État d'une créance (enum `coursier.etat_creance`).
#[derive(Debug, Clone, Copy, PartialEq, Eq, sqlx::Type)]
#[sqlx(type_name = "etat_creance", rename_all = "snake_case")]
pub enum EtatCreance {
    /// Née, pas encore versée.
    Due,
    /// Versée, et son mouvement est au livre.
    Reglee,
}

impl EtatCreance {
    /// Libellé SQL.
    pub fn comme_str(&self) -> &'static str {
        match self {
            EtatCreance::Due => "due",
            EtatCreance::Reglee => "reglee",
        }
    }
}

/// Une créance, telle que la caisse et l'exploitation la lisent.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Creance {
    /// Identifiant.
    pub id: Uuid,
    /// Coursier à qui Mefali doit.
    pub coursier_id: Uuid,
    /// Commande d'origine.
    pub commande_id: Uuid,
    /// Livraison d'origine.
    pub livraison_id: Uuid,
    /// Pourquoi elle existe.
    pub nature: NatureCreance,
    /// Montant dû (unités mineures, toujours > 0).
    pub montant_unites: i64,
    /// Devise ISO 4217.
    pub devise: String,
    /// Due ou réglée.
    pub etat: EtatCreance,
    /// Écriture de caisse du règlement — `None` tant qu'elle est due.
    pub ecriture_id: Option<Uuid>,
    /// Instant du règlement.
    pub regle_le: Option<DateTime<Utc>>,
    /// Naissance.
    pub cree_le: DateTime<Utc>,
}

/// Ce qu'il faut pour ouvrir une créance.
#[derive(Debug, Clone)]
pub struct NouvelleCreance {
    /// Coursier créancier.
    pub coursier_id: Uuid,
    /// Commande d'origine.
    pub commande_id: Uuid,
    /// Livraison d'origine.
    pub livraison_id: Uuid,
    /// Nature.
    pub nature: NatureCreance,
    /// Montant (> 0 — un montant nul n'ouvre aucune créance).
    pub montant_unites: i64,
    /// Devise.
    pub devise: String,
    /// Événement qui l'a fait naître — porte l'idempotence.
    pub evenement_id: Uuid,
}

impl PgCoursier {
    /// Ouvre une créance dans la transaction de l'appelant, et émet
    /// `caisse.creance_ouverte`.
    ///
    /// Rend `None` quand rien n'a été créé — deux cas, tous deux normaux :
    /// un montant nul (il n'y a rien à devoir), ou un rejeu (`evenement_id` ou
    /// `(livraison, nature)` déjà pris). L'idempotence est portée par les DEUX
    /// contraintes d'unicité : l'événement pour le rejeu du worker, le couple
    /// livraison/nature pour la garantie structurelle que « soldé » ne se dit
    /// qu'une fois.
    pub(crate) async fn ouvrir_creance(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        nouvelle: NouvelleCreance,
    ) -> Result<Option<Uuid>, ErreurCoursier> {
        if nouvelle.montant_unites <= 0 {
            return Ok(None);
        }

        let id = Uuid::now_v7();
        let cree = sqlx::query_scalar!(
            r#"INSERT INTO coursier.creance
                   (id, coursier_id, commande_id, livraison_id, nature,
                    montant_unites, devise, evenement_id)
               VALUES ($1, $2, $3, $4, $5::text::coursier.nature_creance, $6, $7, $8)
               ON CONFLICT DO NOTHING
               RETURNING id"#,
            id,
            nouvelle.coursier_id,
            nouvelle.commande_id,
            nouvelle.livraison_id,
            nouvelle.nature.comme_str(),
            nouvelle.montant_unites,
            nouvelle.devise,
            nouvelle.evenement_id,
        )
        .fetch_optional(&mut **tx)
        .await?;

        let Some(id) = cree else {
            return Ok(None);
        };

        socle::ecrire_evenement(
            tx,
            NouvelEvenement {
                type_evenement: "caisse.creance_ouverte",
                entite_type: "creance",
                entite_id: id,
                payload: json!({
                    "coursier": nouvelle.coursier_id,
                    "commande": nouvelle.commande_id,
                    "nature": nouvelle.nature.comme_str(),
                    "montant": nouvelle.montant_unites,
                    "devise": nouvelle.devise,
                }),
                survenu_le: self.maintenant(),
            },
        )
        .await?;
        Ok(Some(id))
    }

    /// Marque une créance **réglée** et écrit son mouvement de caisse dans la
    /// **même transaction** (FR-064, FR-067, research R12).
    ///
    /// L'ordre importe : l'`UPDATE … WHERE etat = 'due'` sert de verrou
    /// d'unicité. Un second appel ne trouve plus de ligne à mettre à jour et
    /// rend `CreanceDejaReglee` — c'est la base qui tranche la concurrence,
    /// pas un `if` lu avant l'écriture.
    ///
    /// # Aucun retour en arrière
    ///
    /// Le marquage n'est pas une bascule : une créance réglée à tort se corrige
    /// par une écriture **inverse** au livre, jamais en repassant `reglee →
    /// due` (FR-064). Un livre qu'on peut rembobiner ne prouve plus rien.
    pub async fn regler_creance(
        &self,
        creance_id: Uuid,
        acteur: Uuid,
        motif_cle: &str,
    ) -> Result<Creance, ErreurCoursier> {
        if motif_cle.trim().is_empty() {
            return Err(ErreurCoursier::MotifRequis);
        }

        let mut tx = self.pool.begin().await?;

        // Verrou de ligne AVANT toute décision : deux règlements concurrents se
        // sérialisent ici, et le second verra `reglee`.
        let creance = sqlx::query!(
            r#"SELECT c.coursier_id, c.commande_id, c.livraison_id,
                      c.nature::text AS "nature!", c.montant_unites, c.devise,
                      c.etat::text AS "etat!"
                 FROM coursier.creance c
                WHERE c.id = $1
                FOR UPDATE"#,
            creance_id,
        )
        .fetch_optional(&mut *tx)
        .await?
        .ok_or(ErreurCoursier::CreanceInconnue(creance_id))?;

        if creance.etat != "due" {
            return Err(ErreurCoursier::CreanceDejaReglee);
        }

        // L'écriture de caisse D'ABORD : c'est elle qui matérialise l'argent, et
        // la créance porte sa référence. `evenement_id` est nul — ce mouvement
        // ne naît d'aucun événement d'outbox mais d'un geste d'exploitation,
        // et `NULL` n'entre pas dans une contrainte d'unicité.
        let ecriture = self
            .ecrire_caisse(
                &mut tx,
                creance.coursier_id,
                crate::caisse::DemandeEcriture {
                    type_ecriture: crate::modele::TypeEcriture::Reglement,
                    // SIGNE POSITIF : l'argent entre pour de vrai.
                    montant_unites: creance.montant_unites,
                    devise: creance.devise.clone(),
                    commande_id: Some(creance.commande_id),
                    livraison_id: Some(creance.livraison_id),
                    arret_id: None,
                    indemnisation_id: None,
                    evenement_id: None,
                    source: "admin",
                },
            )
            .await?
            .ok_or(ErreurCoursier::DemandeInvalide(
                "règlement sans écriture de caisse",
            ))?;

        let maintenant = self.maintenant();
        let mise_a_jour = sqlx::query!(
            "UPDATE coursier.creance
                SET etat = 'reglee', regle_par = $2, regle_le = $3,
                    ecriture_id = $4
              WHERE id = $1 AND etat = 'due'
              RETURNING cree_le",
            creance_id,
            acteur,
            maintenant,
            ecriture,
        )
        .fetch_optional(&mut *tx)
        .await?
        .ok_or(ErreurCoursier::CreanceDejaReglee)?;

        socle::ecrire_evenement(
            &mut tx,
            NouvelEvenement {
                type_evenement: "caisse.creance_reglee",
                entite_type: "creance",
                entite_id: creance_id,
                payload: json!({
                    "coursier": creance.coursier_id,
                    "montant": creance.montant_unites,
                    "devise": creance.devise,
                    "regle_par": acteur,
                    "motif_cle": motif_cle,
                }),
                survenu_le: maintenant,
            },
        )
        .await?;

        tx.commit().await?;

        Ok(Creance {
            id: creance_id,
            coursier_id: creance.coursier_id,
            commande_id: creance.commande_id,
            livraison_id: creance.livraison_id,
            nature: match creance.nature.as_str() {
                "avance_prepayee" => NatureCreance::AvancePrepayee,
                _ => NatureCreance::PartCourse,
            },
            montant_unites: creance.montant_unites,
            devise: creance.devise,
            etat: EtatCreance::Reglee,
            ecriture_id: Some(ecriture),
            regle_le: Some(maintenant),
            cree_le: mise_a_jour.cree_le,
        })
    }

    /// Créances d'un coursier, les plus récentes d'abord (écran de caisse).
    pub async fn creances_du_coursier(
        &self,
        coursier: Uuid,
    ) -> Result<Vec<Creance>, ErreurCoursier> {
        self.lister_creances(Some(coursier), None).await
    }

    /// Créances filtrables — sert la caisse du coursier et la file
    /// d'exploitation (FR-083).
    pub async fn lister_creances(
        &self,
        coursier: Option<Uuid>,
        etat: Option<EtatCreance>,
    ) -> Result<Vec<Creance>, ErreurCoursier> {
        let lignes = sqlx::query!(
            r#"SELECT id, coursier_id, commande_id, livraison_id,
                      nature::text AS "nature!", montant_unites, devise,
                      etat::text AS "etat!", ecriture_id, regle_le, cree_le
                 FROM coursier.creance
                WHERE ($1::uuid IS NULL OR coursier_id = $1)
                  AND ($2::text IS NULL OR etat::text = $2)
                ORDER BY cree_le DESC, id DESC"#,
            coursier,
            etat.map(|e| e.comme_str()),
        )
        .fetch_all(&self.pool)
        .await?;

        Ok(lignes
            .into_iter()
            .map(|l| Creance {
                id: l.id,
                coursier_id: l.coursier_id,
                commande_id: l.commande_id,
                livraison_id: l.livraison_id,
                nature: match l.nature.as_str() {
                    "avance_prepayee" => NatureCreance::AvancePrepayee,
                    _ => NatureCreance::PartCourse,
                },
                montant_unites: l.montant_unites,
                devise: l.devise,
                etat: if l.etat == "reglee" {
                    EtatCreance::Reglee
                } else {
                    EtatCreance::Due
                },
                ecriture_id: l.ecriture_id,
                regle_le: l.regle_le,
                cree_le: l.cree_le,
            })
            .collect())
    }

    /// Somme des créances **dues** d'un coursier — la position « dû par
    /// Mefali » (FR-060). Calculée, jamais stockée : une table de soldes
    /// serait une seconde vérité à réconcilier.
    pub(crate) async fn du_par_mefali(&self, coursier: Uuid) -> Result<i64, ErreurCoursier> {
        Ok(sqlx::query_scalar!(
            r#"SELECT COALESCE(SUM(montant_unites), 0)::bigint AS "total!"
                 FROM coursier.creance
                WHERE coursier_id = $1 AND etat = 'due'"#,
            coursier,
        )
        .fetch_one(&self.pool)
        .await?)
    }
}

/// Part de course encore due au coursier après ce qu'il a encaissé (research
/// R13, FR-060).
///
/// ```text
/// part_course = max(devis_part_coursier − max(frais_encaisses − devis_marge, 0), 0)
/// ```
///
/// La double borne n'est pas une précaution de style, chaque `max` répond à un
/// cas réel :
///
/// - `max(frais − marge, 0)` — sur une course où les frais encaissés sont
///   inférieurs à la marge, le coursier n'a rien couvert de sa part ; sans
///   cette borne, un « négatif » viendrait **augmenter** ce qu'on lui doit ;
/// - `max(…, 0)` — sur une course où il a encaissé plus que sa part, il ne
///   doit rien de plus, mais Mefali ne lui doit rien non plus. Le surplus est
///   la marge, traitée par la position « détenu pour Mefali ».
///
/// Les quatre cas de la table R13 la traversent : cash ordinaire → 0, cash avec
/// retenue → 0, promo Mefali → `P`, prépayée → `P`.
pub fn part_course(devis_part_coursier: i64, frais_encaisses: i64, devis_marge: i64) -> i64 {
    (devis_part_coursier - (frais_encaisses - devis_marge).max(0)).max(0)
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Les quatre cas de la table de vérité R13, sur la formule de la part.
    ///
    /// Ce test est le pendant de celui des frais encaissés : la première
    /// formule retenue pour les frais était fausse dès que la retenue jouait,
    /// et c'est un test comme celui-ci qui l'a fait rejeter.
    #[test]
    fn les_quatre_cas_de_la_table_r13() {
        // Notations : P = part coursier, M = marge, F = frais encaissés.
        // Cash ordinaire : F = P + M → part restante nulle.
        assert_eq!(part_course(2_500, 2_500, 0), 0, "cash ordinaire");
        // Cash + retenue VND-08 : F = R = P + M → idem, la retenue a payé.
        assert_eq!(part_course(2_500, 2_500, 0), 0, "cash + retenue");
        // Cash + promo Mefali : rien d'encaissé → toute la part est due.
        assert_eq!(part_course(2_500, 0, 0), 2_500, "promo Mefali");
        // Prépayée : rien d'encaissé non plus → toute la part est due.
        assert_eq!(part_course(2_500, 0, 0), 2_500, "prépayée");
    }

    /// Avec une marge non nulle (après M4), les frais couvrent la part
    /// SEULEMENT au-delà de la marge — la marge n'est pas au coursier.
    #[test]
    fn la_marge_ne_couvre_pas_la_part_du_coursier() {
        // P = 2 000, M = 500, frais encaissés = 2 500 (= P + M).
        // Le coursier a encaissé 2 500, dont 500 appartiennent à Mefali : sa
        // part est couverte pile, rien n'est dû.
        assert_eq!(part_course(2_000, 2_500, 500), 0);

        // Frais encaissés = 1 000, marge 500 : seuls 500 couvrent sa part.
        assert_eq!(part_course(2_000, 1_000, 500), 1_500);

        // Frais encaissés INFÉRIEURS à la marge : rien n'a couvert la part.
        // Sans le `max` intérieur, on obtiendrait 2 000 − (300 − 500) = 2 200,
        // c'est-à-dire PLUS que sa part — une créance née de nulle part.
        assert_eq!(part_course(2_000, 300, 500), 2_000);
    }

    /// Encaisser plus que sa part ne crée pas de dette négative.
    #[test]
    fn un_encaissement_superieur_ne_rend_jamais_de_negatif() {
        assert_eq!(part_course(1_000, 5_000, 0), 0);
    }

    /// Les libellés SQL et le domaine ne peuvent pas diverger sans que ce test
    /// le dise — une valeur d'enum mal orthographiée ferait échouer un INSERT
    /// en production, pas à la compilation.
    #[test]
    fn les_libelles_sql_sont_alignes() {
        assert_eq!(NatureCreance::AvancePrepayee.comme_str(), "avance_prepayee");
        assert_eq!(NatureCreance::PartCourse.comme_str(), "part_course");
        assert_eq!(EtatCreance::Due.comme_str(), "due");
        assert_eq!(EtatCreance::Reglee.comme_str(), "reglee");
    }
}
