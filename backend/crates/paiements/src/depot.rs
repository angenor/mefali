//! `PgPaiements` — racine de composition du domaine paiement.
//!
//! Conventions du dépôt, tenues sans exception :
//!
//! - **lectures sur pool**, **écritures sur `&mut PgTransaction`** — l'appelant
//!   compose sa transaction, et l'événement outbox y entre avec l'écriture
//!   (constitution VI) ;
//! - `maintenant()` vient de l'**horloge serveur**, jamais de celle de l'app.
//!   Le cycle 010 a payé cette leçon : une horloge d'appareil décalée avait
//!   fait basculer un état de boutique. Ici, elle déciderait si une session de
//!   paiement vit encore.
//!
//! Ce module ne contient **aucune règle métier** : il lit, il écrit, il traduit.
//! Les décisions vivent dans `session`, `webhook`, `expiration` et `dossier`.

use chrono::{DateTime, Utc};
use sqlx::PgPool;
use uuid::Uuid;
use zones::PgZones;

use crate::config::ConfigPaiements;
use crate::modele::{
    Dossier, ErreurPaiements, EtatDossier, EtatTransaction, LigneRegistre, MoyenPaiement,
    Transaction, TypeDossier,
};

/// Dépôt Postgres du domaine paiement.
#[derive(Clone)]
pub struct PgPaiements {
    pool: PgPool,
    zones: PgZones,
}

impl PgPaiements {
    pub fn new(pool: PgPool) -> Self {
        let zones = PgZones::new(pool.clone());
        Self { pool, zones }
    }

    /// Accès au pool pour les modules du crate qui composent leur transaction.
    pub fn pool(&self) -> &PgPool {
        &self.pool
    }

    /// Horloge **serveur**. Le seul point du crate où « maintenant » est défini.
    ///
    /// Passer par une méthode plutôt que d'appeler `Utc::now()` partout rend le
    /// point de décision unique et repérable : c'est lui qui dit si une session
    /// est échue, et une seconde source d'heure aurait tôt fait de diverger.
    pub fn maintenant(&self) -> DateTime<Utc> {
        Utc::now()
    }

    /// Les 4 paramètres du cycle pour une zone, hérités et **validés**.
    pub async fn config(&self, zone: Uuid) -> Result<ConfigPaiements, ErreurPaiements> {
        ConfigPaiements::charger(&self.zones, zone).await
    }

    // ── Transactions ──────────────────────────────────────────────────────

    /// Transaction **vivante** d'une commande, s'il y en a une.
    ///
    /// « Vivante » = `ouverte`. L'index partiel `transaction_vivante_unique`
    /// garantit qu'il n'y en a jamais deux, donc cette lecture ne peut pas
    /// devenir ambiguë (FR-015).
    pub async fn transaction_vivante(
        &self,
        commande: Uuid,
    ) -> Result<Option<Transaction>, ErreurPaiements> {
        let l = sqlx::query!(
            r#"SELECT id, commande_id, montant_unites, devise,
                      etat  AS "etat!: EtatTransaction",
                      moyen AS "moyen!: MoyenPaiement",
                      fournisseur, reference_fournisseur, acces_paiement,
                      ouverte_le, expire_le, issue_le
               FROM paiements.transaction
               WHERE commande_id = $1 AND etat = 'ouverte'"#,
            commande,
        )
        .fetch_optional(&self.pool)
        .await?;

        Ok(l.map(|l| Transaction {
            id: l.id,
            commande_id: l.commande_id,
            montant_unites: l.montant_unites,
            devise: l.devise,
            etat: l.etat,
            moyen: l.moyen,
            fournisseur: l.fournisseur,
            reference_fournisseur: l.reference_fournisseur,
            acces_paiement: l.acces_paiement,
            ouverte_le: l.ouverte_le,
            expire_le: l.expire_le,
            issue_le: l.issue_le,
        }))
    }

    /// **Dernière** transaction d'une commande, quel que soit son état.
    ///
    /// Sert `GET /commandes/{id}/paiement` : après une expiration, le client
    /// doit encore pouvoir lire « expirée » plutôt qu'un `404` qui lui ferait
    /// croire qu'il n'a jamais rien tenté.
    pub async fn derniere_transaction(
        &self,
        commande: Uuid,
    ) -> Result<Option<Transaction>, ErreurPaiements> {
        let l = sqlx::query!(
            r#"SELECT id, commande_id, montant_unites, devise,
                      etat  AS "etat!: EtatTransaction",
                      moyen AS "moyen!: MoyenPaiement",
                      fournisseur, reference_fournisseur, acces_paiement,
                      ouverte_le, expire_le, issue_le
               FROM paiements.transaction
               WHERE commande_id = $1
               ORDER BY ouverte_le DESC
               LIMIT 1"#,
            commande,
        )
        .fetch_optional(&self.pool)
        .await?;

        Ok(l.map(|l| Transaction {
            id: l.id,
            commande_id: l.commande_id,
            montant_unites: l.montant_unites,
            devise: l.devise,
            etat: l.etat,
            moyen: l.moyen,
            fournisseur: l.fournisseur,
            reference_fournisseur: l.reference_fournisseur,
            acces_paiement: l.acces_paiement,
            ouverte_le: l.ouverte_le,
            expire_le: l.expire_le,
            issue_le: l.issue_le,
        }))
    }

    /// Transaction par son identifiant, **verrouillée** pour écriture.
    ///
    /// `FOR UPDATE` et non une simple lecture : deux notifications concurrentes
    /// du même fournisseur doivent se sérialiser sur cette ligne, sans quoi
    /// elles passeraient toutes deux la garde d'état avant que l'une n'écrive
    /// (research R5).
    pub async fn transaction_verrouillee(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        transaction_id: Uuid,
    ) -> Result<Option<Transaction>, ErreurPaiements> {
        let l = sqlx::query!(
            r#"SELECT id, commande_id, montant_unites, devise,
                      etat  AS "etat!: EtatTransaction",
                      moyen AS "moyen!: MoyenPaiement",
                      fournisseur, reference_fournisseur, acces_paiement,
                      ouverte_le, expire_le, issue_le
               FROM paiements.transaction
               WHERE id = $1
               FOR UPDATE"#,
            transaction_id,
        )
        .fetch_optional(&mut **tx)
        .await?;

        Ok(l.map(|l| Transaction {
            id: l.id,
            commande_id: l.commande_id,
            montant_unites: l.montant_unites,
            devise: l.devise,
            etat: l.etat,
            moyen: l.moyen,
            fournisseur: l.fournisseur,
            reference_fournisseur: l.reference_fournisseur,
            acces_paiement: l.acces_paiement,
            ouverte_le: l.ouverte_le,
            expire_le: l.expire_le,
            issue_le: l.issue_le,
        }))
    }

    /// Insère une transaction `ouverte`.
    ///
    /// Peut échouer sur `transaction_vivante_unique` si une session vivante
    /// existe déjà — et c'est **voulu** : l'idempotence de l'ouverture est
    /// portée par la base, pas par un `if` qui perdrait la course entre deux
    /// requêtes concurrentes (FR-015).
    #[allow(clippy::too_many_arguments)]
    pub async fn inserer_transaction(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        id: Uuid,
        commande_id: Uuid,
        montant_unites: i64,
        devise: &str,
        fournisseur: &str,
        reference_fournisseur: Option<&str>,
        acces_paiement: Option<&str>,
        ouverte_le: DateTime<Utc>,
        expire_le: DateTime<Utc>,
    ) -> Result<(), ErreurPaiements> {
        sqlx::query!(
            "INSERT INTO paiements.transaction
                 (id, commande_id, montant_unites, devise, fournisseur,
                  reference_fournisseur, acces_paiement, ouverte_le, expire_le)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)",
            id,
            commande_id,
            montant_unites,
            devise,
            fournisseur,
            reference_fournisseur,
            acces_paiement,
            ouverte_le,
            expire_le,
        )
        .execute(&mut **tx)
        .await?;
        Ok(())
    }

    /// Fait passer une transaction dans un nouvel état, et **efface l'accès de
    /// paiement** dès que cet état n'accepte plus de paiement.
    ///
    /// L'effacement n'est pas un détail d'hygiène : une URL d'encaissement
    /// encore vivante dans une base est une surface d'attaque sans usage
    /// (data-model §6, FR-006).
    ///
    /// ⚠ **Mais il ne s'applique pas à `echouee`.** Un refus d'opérateur ne clôt
    /// pas la session : le client réessaie sur le **même** accès tant que
    /// l'échéance n'est pas franchie (FR-026). L'effacer aurait rendu la
    /// reprise impossible — un « Payer maintenant » qui n'ouvre plus rien.
    /// C'est [`EtatTransaction::accepte_paiement`] qui tranche, et non une liste
    /// d'états recopiée ici, pour que les deux ne puissent pas diverger.
    ///
    /// La **garde de transition** n'est pas ici mais chez l'appelant, qui a lu
    /// la ligne sous `FOR UPDATE` : ce module n'arbitre pas, il écrit.
    pub async fn changer_etat_transaction(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        transaction_id: Uuid,
        vers: EtatTransaction,
        moyen: Option<MoyenPaiement>,
        reference_fournisseur: Option<&str>,
        quand: DateTime<Utc>,
    ) -> Result<(), ErreurPaiements> {
        let garder_acces = vers.accepte_paiement();
        sqlx::query!(
            "UPDATE paiements.transaction
                SET etat = $2,
                    moyen = COALESCE($3, moyen),
                    reference_fournisseur = COALESCE($4, reference_fournisseur),
                    issue_le = $5,
                    acces_paiement = CASE WHEN $6 THEN acces_paiement ELSE NULL END
              WHERE id = $1",
            transaction_id,
            vers as EtatTransaction,
            moyen as Option<MoyenPaiement>,
            reference_fournisseur,
            quand,
            garder_acces,
        )
        .execute(&mut **tx)
        .await?;
        Ok(())
    }

    /// Enregistre la référence du fournisseur et l'accès, sur une transaction
    /// encore `ouverte`.
    ///
    /// Séparé de l'insertion parce que `create_checkout` est appelé **hors** de
    /// la transaction SQL (research R2) : un appel HTTP sortant à l'intérieur
    /// tiendrait un verrou pendant toute la latence d'un tiers.
    pub async fn poser_acces(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        transaction_id: Uuid,
        reference_fournisseur: &str,
        acces_paiement: &str,
    ) -> Result<(), ErreurPaiements> {
        sqlx::query!(
            "UPDATE paiements.transaction
                SET reference_fournisseur = $2, acces_paiement = $3
              WHERE id = $1 AND etat = 'ouverte'",
            transaction_id,
            reference_fournisseur,
            acces_paiement,
        )
        .execute(&mut **tx)
        .await?;
        Ok(())
    }

    /// Sessions **échues** encore `ouverte`, les plus vieilles d'abord.
    ///
    /// Servie par l'index partiel `transaction_a_expirer`. Le balayage
    /// *matérialise* ce que la lecture savait déjà : `expire_le` est persistée,
    /// et toute lecture la respecte sans attendre le job (R7).
    pub async fn sessions_echues(
        &self,
        maintenant: DateTime<Utc>,
        limite: i64,
    ) -> Result<Vec<Transaction>, ErreurPaiements> {
        let lignes = sqlx::query!(
            r#"SELECT id, commande_id, montant_unites, devise,
                      etat  AS "etat!: EtatTransaction",
                      moyen AS "moyen!: MoyenPaiement",
                      fournisseur, reference_fournisseur, acces_paiement,
                      ouverte_le, expire_le, issue_le
               FROM paiements.transaction
               WHERE etat = 'ouverte' AND expire_le <= $1
               ORDER BY expire_le
               LIMIT $2"#,
            maintenant,
            limite,
        )
        .fetch_all(&self.pool)
        .await?;

        Ok(lignes
            .into_iter()
            .map(|l| Transaction {
                id: l.id,
                commande_id: l.commande_id,
                montant_unites: l.montant_unites,
                devise: l.devise,
                etat: l.etat,
                moyen: l.moyen,
                fournisseur: l.fournisseur,
                reference_fournisseur: l.reference_fournisseur,
                acces_paiement: l.acces_paiement,
                ouverte_le: l.ouverte_le,
                expire_le: l.expire_le,
                issue_le: l.issue_le,
            })
            .collect())
    }

    // ── Notifications reçues ──────────────────────────────────────────────

    /// Enregistre une notification, ou **détecte un rejeu**.
    ///
    /// `ON CONFLICT DO NOTHING RETURNING id` : `None` = la triple clé
    /// `(fournisseur, référence, empreinte)` existe déjà, donc c'est un rejeu,
    /// donc **aucun effet** (FR-021, FR-022).
    ///
    /// C'est une **contrainte**, pas un `if` : deux notifications concurrentes
    /// passeraient toutes deux un test « est-ce déjà réglé ? » avant que l'une
    /// n'écrive. Elles ne passent pas toutes deux un `INSERT` sous unicité.
    #[allow(clippy::too_many_arguments)]
    pub async fn enregistrer_notification(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        fournisseur: &str,
        reference_fournisseur: &str,
        empreinte_charge: &str,
        transaction_id: Option<Uuid>,
        signature_valide: bool,
        issue: &str,
        montant_annonce: Option<i64>,
        devise_annoncee: Option<&str>,
        recue_le: DateTime<Utc>,
    ) -> Result<Option<Uuid>, ErreurPaiements> {
        Ok(sqlx::query_scalar!(
            "INSERT INTO paiements.notification_recue
                 (id, fournisseur, reference_fournisseur, empreinte_charge,
                  transaction_id, signature_valide, issue, montant_annonce,
                  devise_annoncee, recue_le)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
             ON CONFLICT (fournisseur, reference_fournisseur, empreinte_charge)
             DO NOTHING
             RETURNING id",
            Uuid::now_v7(),
            fournisseur,
            reference_fournisseur,
            empreinte_charge,
            transaction_id,
            signature_valide,
            issue,
            montant_annonce,
            devise_annoncee,
            recue_le,
        )
        .fetch_optional(&mut **tx)
        .await?)
    }

    // ── Dossiers d'anomalie ───────────────────────────────────────────────

    /// Ouvre un dossier d'anomalie.
    ///
    /// `evenement_id` porte l'idempotence du **consommateur outbox** : `NULL`
    /// pour un dossier né du webhook (qui ne consomme aucun événement), et NULL
    /// n'entre pas dans un `UNIQUE` — plusieurs dossiers de webhook coexistent
    /// donc sans se bloquer.
    #[allow(clippy::too_many_arguments)]
    pub async fn ouvrir_dossier(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        id: Uuid,
        type_dossier: TypeDossier,
        commande_id: Option<Uuid>,
        transaction_id: Option<Uuid>,
        arret_id: Option<Uuid>,
        montant_constate: Option<i64>,
        montant_attendu: Option<i64>,
        devise: Option<&str>,
        motif_cle: &str,
        evenement_id: Option<Uuid>,
        ouvert_le: DateTime<Utc>,
    ) -> Result<Option<Uuid>, ErreurPaiements> {
        Ok(sqlx::query_scalar!(
            "INSERT INTO paiements.dossier
                 (id, type_dossier, commande_id, transaction_id, arret_id,
                  montant_constate, montant_attendu, devise, motif_cle,
                  evenement_id, ouvert_le)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
             ON CONFLICT (evenement_id) DO NOTHING
             RETURNING id",
            id,
            type_dossier as TypeDossier,
            commande_id,
            transaction_id,
            arret_id,
            montant_constate,
            montant_attendu,
            devise,
            motif_cle,
            evenement_id,
            ouvert_le,
        )
        .fetch_optional(&mut **tx)
        .await?)
    }

    /// Un dossier par son identifiant.
    pub async fn dossier(&self, id: Uuid) -> Result<Option<Dossier>, ErreurPaiements> {
        let l = sqlx::query!(
            r#"SELECT id,
                      type_dossier AS "type_dossier!: TypeDossier",
                      etat         AS "etat!: EtatDossier",
                      commande_id, transaction_id, arret_id,
                      montant_constate, montant_attendu, devise, motif_cle,
                      ouvert_le, clos_par, clos_le, clos_motif_cle
               FROM paiements.dossier WHERE id = $1"#,
            id,
        )
        .fetch_optional(&self.pool)
        .await?;

        Ok(l.map(|l| Dossier {
            id: l.id,
            type_dossier: l.type_dossier,
            etat: l.etat,
            commande_id: l.commande_id,
            transaction_id: l.transaction_id,
            arret_id: l.arret_id,
            montant_constate: l.montant_constate,
            montant_attendu: l.montant_attendu,
            devise: l.devise,
            motif_cle: l.motif_cle,
            ouvert_le: l.ouvert_le,
            clos_par: l.clos_par,
            clos_le: l.clos_le,
            clos_motif_cle: l.clos_motif_cle,
        }))
    }

    /// Registre des transactions, filtrable (FR-080, FR-081).
    ///
    /// Chaque ligne porte `reference_fournisseur` ET `commande_id` : le
    /// rapprochement dans les deux sens se lit sans jointure manuelle. Une
    /// transaction est marquée **orpheline** quand elle a encaissé de l'argent
    /// que plus aucune commande vivante n'attend — c'est le cas exact du
    /// paiement hors délai (R8), et c'est ce que l'exploitation cherche.
    pub async fn registre_transactions(
        &self,
        etat: Option<&str>,
        moyen: Option<&str>,
        commande: Option<Uuid>,
        depuis: Option<DateTime<Utc>>,
        jusqu_a: Option<DateTime<Utc>>,
    ) -> Result<Vec<LigneRegistre>, ErreurPaiements> {
        let lignes = sqlx::query!(
            r#"SELECT t.id, t.commande_id, t.montant_unites, t.devise,
                      t.etat::text  AS "etat!",
                      t.moyen::text AS "moyen!",
                      t.fournisseur, t.reference_fournisseur,
                      t.ouverte_le, t.issue_le,
                      c.etat::text AS "etat_commande?"
                 FROM paiements.transaction t
                 LEFT JOIN commandes.commande c ON c.id = t.commande_id
                WHERE ($1::text IS NULL OR t.etat::text = $1)
                  AND ($2::text IS NULL OR t.moyen::text = $2)
                  AND ($3::uuid IS NULL OR t.commande_id = $3)
                  AND ($4::timestamptz IS NULL OR t.ouverte_le >= $4)
                  AND ($5::timestamptz IS NULL OR t.ouverte_le <= $5)
                ORDER BY t.ouverte_le DESC, t.id DESC"#,
            etat,
            moyen,
            commande,
            depuis,
            jusqu_a,
        )
        .fetch_all(&self.pool)
        .await?;

        Ok(lignes
            .into_iter()
            .map(|l| LigneRegistre {
                // De l'argent encaissé qu'aucune commande vivante n'attend.
                orpheline: l.etat == "payee_hors_delai"
                    || l.etat_commande.as_deref() == Some("annulee"),
                id: l.id,
                commande_id: l.commande_id,
                montant_unites: l.montant_unites,
                devise: l.devise,
                etat: l.etat,
                moyen: l.moyen,
                fournisseur: l.fournisseur,
                reference_fournisseur: l.reference_fournisseur,
                ouverte_le: l.ouverte_le,
                issue_le: l.issue_le,
            })
            .collect())
    }

    /// File des dossiers d'anomalie, filtrable (FR-082).
    pub async fn lister_dossiers(
        &self,
        etat: Option<&str>,
        type_dossier: Option<&str>,
    ) -> Result<Vec<Dossier>, ErreurPaiements> {
        let lignes = sqlx::query!(
            r#"SELECT id,
                      type_dossier AS "type_dossier!: TypeDossier",
                      etat AS "etat!: EtatDossier",
                      commande_id, transaction_id, arret_id,
                      montant_constate, montant_attendu, devise, motif_cle,
                      ouvert_le, clos_par, clos_le, clos_motif_cle
                 FROM paiements.dossier
                WHERE ($1::text IS NULL OR etat::text = $1)
                  AND ($2::text IS NULL OR type_dossier::text = $2)
                ORDER BY ouvert_le DESC, id DESC"#,
            etat,
            type_dossier,
        )
        .fetch_all(&self.pool)
        .await?;

        Ok(lignes
            .into_iter()
            .map(|l| Dossier {
                id: l.id,
                type_dossier: l.type_dossier,
                etat: l.etat,
                commande_id: l.commande_id,
                transaction_id: l.transaction_id,
                arret_id: l.arret_id,
                montant_constate: l.montant_constate,
                montant_attendu: l.montant_attendu,
                devise: l.devise,
                motif_cle: l.motif_cle,
                ouvert_le: l.ouvert_le,
                clos_par: l.clos_par,
                clos_le: l.clos_le,
                clos_motif_cle: l.clos_motif_cle,
            })
            .collect())
    }

    /// Clôt un dossier. **Refuse** un second appel : la clôture n'est pas une
    /// bascule, et le `WHERE etat = 'ouvert'` en fait une garantie de base
    /// plutôt qu'une vérification préalable qui perdrait la course.
    pub async fn clore_dossier(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        id: Uuid,
        clos_par: Uuid,
        motif_cle: &str,
        quand: DateTime<Utc>,
    ) -> Result<bool, ErreurPaiements> {
        let touchees = sqlx::query!(
            "UPDATE paiements.dossier
                SET etat = 'clos', clos_par = $2, clos_le = $3, clos_motif_cle = $4
              WHERE id = $1 AND etat = 'ouvert'",
            id,
            clos_par,
            quand,
            motif_cle,
        )
        .execute(&mut **tx)
        .await?
        .rows_affected();
        Ok(touchees == 1)
    }
}
