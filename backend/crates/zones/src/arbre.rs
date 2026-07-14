//! Écritures sur l'arbre de zones (FR-001..004) : création, re-parentage,
//! suppression. Toutes prennent `&mut PgTransaction`.
//!
//! Anti-cycle en DOUBLE garde (data-model §2) : validation applicative ici
//! (erreur explicite [`ErreurZones::CycleDetecte`], AVANT toute écriture) +
//! trigger plpgsql `zone_sans_cycle` (défense en profondeur, écriture SQL
//! directe). La suppression est refusée par les FK `ON DELETE RESTRICT`.

use uuid::Uuid;

use crate::modele::{ErreurZones, TypeZone, Zone};
use crate::PgZones;

impl PgZones {
    /// Crée une zone (`parent` `None` = racine). Renvoie la zone créée (UUIDv7).
    ///
    /// Le `parent` fourni doit exister (erreur explicite, plutôt qu'une violation
    /// de clé étrangère opaque).
    pub async fn creer_zone(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        parent: Option<Uuid>,
        type_zone: TypeZone,
        nom: &str,
    ) -> Result<Zone, ErreurZones> {
        if let Some(p) = parent {
            if !self.zone_existe(tx, p).await? {
                return Err(ErreurZones::ZoneInconnue(p));
            }
        }
        let id = Uuid::now_v7();
        sqlx::query!(
            "INSERT INTO zones.zone (id, parent_id, type, nom)
             VALUES ($1, $2, $3::text::zones.type_zone, $4)",
            id,
            parent,
            type_zone.comme_str(),
            nom,
        )
        .execute(&mut **tx)
        .await?;
        Ok(Zone {
            id,
            parent_id: parent,
            type_zone,
            nom: nom.to_owned(),
        })
    }

    /// Re-parente une zone. Refuse tout cycle (FR-002) par validation applicative
    /// AVANT l'UPDATE : en remontant les ancêtres du nouveau parent, on ne doit
    /// jamais rencontrer la zone elle-même. Le re-parentage reste permis (edge
    /// case spec : la descendance se re-résout à la consultation suivante).
    pub async fn reparenter(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        zone: Uuid,
        nouveau_parent: Option<Uuid>,
    ) -> Result<(), ErreurZones> {
        if !self.zone_existe(tx, zone).await? {
            return Err(ErreurZones::ZoneInconnue(zone));
        }
        if let Some(parent) = nouveau_parent {
            if !self.zone_existe(tx, parent).await? {
                return Err(ErreurZones::ZoneInconnue(parent));
            }
            let mut courant = Some(parent);
            while let Some(c) = courant {
                if c == zone {
                    return Err(ErreurZones::CycleDetecte);
                }
                courant = sqlx::query_scalar!("SELECT parent_id FROM zones.zone WHERE id = $1", c)
                    .fetch_one(&mut **tx)
                    .await?;
            }
        }
        sqlx::query!(
            "UPDATE zones.zone SET parent_id = $2, modifie_le = now() WHERE id = $1",
            zone,
            nouveau_parent,
        )
        .execute(&mut **tx)
        .await?;
        Ok(())
    }

    /// Supprime une zone. La base la refuse (`ON DELETE RESTRICT`) si la zone a
    /// des enfants ou est référencée (paramètres, activations) → [`ErreurZones::Sql`].
    pub async fn supprimer_zone(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        zone: Uuid,
    ) -> Result<(), ErreurZones> {
        let resultat = sqlx::query!("DELETE FROM zones.zone WHERE id = $1", zone)
            .execute(&mut **tx)
            .await?;
        if resultat.rows_affected() == 0 {
            return Err(ErreurZones::ZoneInconnue(zone));
        }
        Ok(())
    }

    /// Existence d'une zone (helper interne).
    pub(crate) async fn zone_existe(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        zone: Uuid,
    ) -> Result<bool, ErreurZones> {
        let existe = sqlx::query_scalar!(
            "SELECT EXISTS(SELECT 1 FROM zones.zone WHERE id = $1)",
            zone
        )
        .fetch_one(&mut **tx)
        .await?;
        Ok(existe.unwrap_or(false))
    }
}

#[cfg(test)]
mod tests {
    use crate::modele::{ErreurZones, TypeZone};
    use crate::PgZones;
    use sqlx::PgPool;
    use uuid::Uuid;

    /// Création d'un arbre CI (pays) > Tiassalé (ville) ; parent inexistant refusé.
    #[sqlx::test(migrations = "../../migrations")]
    async fn creation_et_arbre(pool: PgPool) {
        let z = PgZones::new(pool.clone());
        let mut tx = pool.begin().await.unwrap();
        let ci = z
            .creer_zone(&mut tx, None, TypeZone::Pays, "Côte d'Ivoire")
            .await
            .unwrap();
        let tia = z
            .creer_zone(&mut tx, Some(ci.id), TypeZone::Ville, "Tiassalé")
            .await
            .unwrap();
        tx.commit().await.unwrap();

        assert_eq!(ci.parent_id, None);
        assert_eq!(tia.parent_id, Some(ci.id));
        let parent: Option<Uuid> =
            sqlx::query_scalar("SELECT parent_id FROM zones.zone WHERE id = $1")
                .bind(tia.id)
                .fetch_one(&pool)
                .await
                .unwrap();
        assert_eq!(parent, Some(ci.id), "parent persisté");

        let mut tx = pool.begin().await.unwrap();
        let err = z
            .creer_zone(&mut tx, Some(Uuid::now_v7()), TypeZone::Ville, "orpheline")
            .await
            .unwrap_err();
        assert!(matches!(err, ErreurZones::ZoneInconnue(_)));
    }

    /// Anti-cycle APPLICATIF : rattacher une zone sous elle-même ou sous une de
    /// ses descendantes → erreur explicite, avant toute écriture.
    #[sqlx::test(migrations = "../../migrations")]
    async fn cycle_refuse_par_application(pool: PgPool) {
        let z = PgZones::new(pool.clone());
        let mut tx = pool.begin().await.unwrap();
        let a = z
            .creer_zone(&mut tx, None, TypeZone::Pays, "A")
            .await
            .unwrap();
        let b = z
            .creer_zone(&mut tx, Some(a.id), TypeZone::Ville, "B")
            .await
            .unwrap();

        let err = z.reparenter(&mut tx, a.id, Some(b.id)).await.unwrap_err();
        assert!(
            matches!(err, ErreurZones::CycleDetecte),
            "A sous son enfant B"
        );
        let err2 = z.reparenter(&mut tx, a.id, Some(a.id)).await.unwrap_err();
        assert!(matches!(err2, ErreurZones::CycleDetecte), "A sous A");
    }

    /// Anti-cycle par TRIGGER : même en écriture SQL directe (validation
    /// applicative contournée), la base refuse le cycle (défense en profondeur).
    #[sqlx::test(migrations = "../../migrations")]
    async fn cycle_refuse_par_trigger(pool: PgPool) {
        let z = PgZones::new(pool.clone());
        let mut tx = pool.begin().await.unwrap();
        let a = z
            .creer_zone(&mut tx, None, TypeZone::Pays, "A")
            .await
            .unwrap();
        let b = z
            .creer_zone(&mut tx, Some(a.id), TypeZone::Ville, "B")
            .await
            .unwrap();
        tx.commit().await.unwrap();

        let res = sqlx::query("UPDATE zones.zone SET parent_id = $1 WHERE id = $2")
            .bind(b.id)
            .bind(a.id)
            .execute(&pool)
            .await;
        assert!(
            res.is_err(),
            "le trigger zone_sans_cycle doit refuser le cycle"
        );
    }

    /// Suppression refusée (RESTRICT) avec enfants ou références ; feuille libre OK.
    #[sqlx::test(migrations = "../../migrations")]
    async fn suppression_restrict(pool: PgPool) {
        let z = PgZones::new(pool.clone());
        let mut tx = pool.begin().await.unwrap();
        let a = z
            .creer_zone(&mut tx, None, TypeZone::Pays, "A")
            .await
            .unwrap();
        let b = z
            .creer_zone(&mut tx, Some(a.id), TypeZone::Ville, "B")
            .await
            .unwrap();
        tx.commit().await.unwrap();

        // A a un enfant → suppression refusée.
        let mut tx = pool.begin().await.unwrap();
        let err = z.supprimer_zone(&mut tx, a.id).await.unwrap_err();
        assert!(matches!(err, ErreurZones::Sql(_)), "RESTRICT (enfant)");
        tx.rollback().await.unwrap();

        // B est référencée par un paramètre → suppression refusée.
        sqlx::query("INSERT INTO zones.parametre_zone (zone_id, cle, valeur) VALUES ($1, 'texte.x', '\"v\"')")
            .bind(b.id)
            .execute(&pool)
            .await
            .unwrap();
        let mut tx = pool.begin().await.unwrap();
        let err = z.supprimer_zone(&mut tx, b.id).await.unwrap_err();
        assert!(matches!(err, ErreurZones::Sql(_)), "RESTRICT (référence)");
        tx.rollback().await.unwrap();

        // Feuille sans enfant ni référence → suppression permise.
        let mut tx = pool.begin().await.unwrap();
        let c = z
            .creer_zone(&mut tx, Some(a.id), TypeZone::Ville, "C")
            .await
            .unwrap();
        z.supprimer_zone(&mut tx, c.id).await.unwrap();
        tx.commit().await.unwrap();
    }
}
