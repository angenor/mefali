//! Écriture d'un paramètre de zone (FR-005) : validation par namespace (registre
//! data-model §4) + événement outbox `zone.parametre_modifie` dans la MÊME
//! transaction (constitution VI).
//!
//! Les namespaces inconnus (`dispatch.*`, `tarification.*`…) sont acceptés tels
//! quels — de nouveaux paramètres s'ajoutent sans migration (FR-011). Seuls les
//! namespaces du registre sont validés à l'écriture.

use chrono::Utc;
use serde_json::{json, Value};
use uuid::Uuid;

use socle::{ecrire_evenement, NouvelEvenement};

use crate::modele::ErreurZones;
use crate::PgZones;

impl PgZones {
    /// Définit (crée ou remplace) un paramètre de zone. Valide la valeur selon le
    /// namespace de la clé, puis émet `zone.parametre_modifie` (avant/après/acteur)
    /// dans la transaction fournie.
    pub async fn definir_parametre(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        zone: Uuid,
        cle: &str,
        valeur: Value,
        acteur: &str,
    ) -> Result<(), ErreurZones> {
        if !self.zone_existe(tx, zone).await? {
            return Err(ErreurZones::ZoneInconnue(zone));
        }
        self.valider_parametre(tx, cle, &valeur).await?;

        // Valeur précédente (null si création) — pour le journal avant/après.
        let avant: Option<Value> = sqlx::query_scalar!(
            "SELECT valeur FROM zones.parametre_zone WHERE zone_id = $1 AND cle = $2",
            zone,
            cle,
        )
        .fetch_optional(&mut **tx)
        .await?;

        let payload = json!({
            "zone": zone,
            "cle": cle,
            "avant": avant,
            "apres": valeur,
            "acteur": acteur,
        });

        sqlx::query!(
            "INSERT INTO zones.parametre_zone (zone_id, cle, valeur)
             VALUES ($1, $2, $3)
             ON CONFLICT (zone_id, cle) DO UPDATE SET valeur = $3, modifie_le = now()",
            zone,
            cle,
            valeur,
        )
        .execute(&mut **tx)
        .await?;

        ecrire_evenement(
            tx,
            NouvelEvenement {
                type_evenement: "zone.parametre_modifie",
                entite_type: "zone",
                entite_id: zone,
                payload,
                survenu_le: Utc::now(),
            },
        )
        .await?;
        Ok(())
    }

    /// Valide une valeur selon le namespace de sa clé (registre data-model §4).
    async fn valider_parametre(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        cle: &str,
        valeur: &Value,
    ) -> Result<(), ErreurZones> {
        let invalide = |raison: &str| {
            Err(ErreurZones::ValeurInvalide {
                cle: cle.to_owned(),
                raison: raison.to_owned(),
            })
        };

        match cle {
            "devise.code" => {
                let ok = valeur
                    .as_str()
                    .is_some_and(|c| c.len() == 3 && c.chars().all(|ch| ch.is_ascii_uppercase()));
                if !ok {
                    return invalide("code ISO 4217 attendu (3 lettres majuscules)");
                }
            }
            "devise.decimales" => {
                if valeur.as_u64().filter(|&n| n <= 4).is_none() {
                    return invalide("entier 0..4 attendu");
                }
            }
            "transport.actifs" => {
                // Forme seulement ; l'existence des slugs est validée en T013.
                let ok = valeur
                    .as_array()
                    .is_some_and(|a| a.iter().all(Value::is_string));
                if !ok {
                    return invalide("tableau de slugs (chaînes) attendu");
                }
            }
            _ if cle.starts_with("drapeau.") => {
                if !valeur.is_boolean() {
                    return invalide("booléen attendu");
                }
            }
            _ if cle.starts_with("texte.") => {
                if !valeur.is_string() {
                    return invalide("chaîne attendue");
                }
            }
            _ if cle.starts_with("categorie.") => {
                self.valider_cle_categorie(tx, cle, valeur).await?;
            }
            // client.* (libre) et tout autre namespace (FR-011) : acceptés.
            _ => {}
        }
        Ok(())
    }

    /// Valide les clés `categorie.<slug>.seuil_activation` / `.mixable`
    /// (slug existant + type de la valeur). Toute autre clé `categorie.*` est
    /// acceptée telle quelle (FR-011).
    async fn valider_cle_categorie(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        cle: &str,
        valeur: &Value,
    ) -> Result<(), ErreurZones> {
        let reste = cle.strip_prefix("categorie.").unwrap_or_default();
        let (slug, attendu_entier) = if let Some(slug) = reste.strip_suffix(".seuil_activation") {
            (slug, true)
        } else if let Some(slug) = reste.strip_suffix(".mixable") {
            (slug, false)
        } else {
            return Ok(());
        };

        let existe =
            sqlx::query_scalar!("SELECT EXISTS(SELECT 1 FROM zones.categorie WHERE slug = $1)", slug)
                .fetch_one(&mut **tx)
                .await?;
        if existe != Some(true) {
            return Err(ErreurZones::CategorieInconnue(slug.to_owned()));
        }

        if attendu_entier {
            if valeur.as_i64().filter(|&n| n >= 1).is_none() {
                return Err(ErreurZones::ValeurInvalide {
                    cle: cle.to_owned(),
                    raison: "entier ≥ 1 attendu".to_owned(),
                });
            }
        } else if !valeur.is_boolean() {
            return Err(ErreurZones::ValeurInvalide {
                cle: cle.to_owned(),
                raison: "booléen attendu".to_owned(),
            });
        }
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use crate::modele::{ErreurZones, TypeZone};
    use crate::PgZones;
    use serde_json::{json, Value};
    use sqlx::PgPool;
    use uuid::Uuid;

    async fn zone_avec_categorie(z: &PgZones, tx: &mut sqlx::PgTransaction<'_>) -> Uuid {
        let zone = z
            .creer_zone(tx, None, TypeZone::Pays, "CI")
            .await
            .unwrap();
        sqlx::query(
            "INSERT INTO zones.categorie (id, slug, nom_cle, workflow_vendeur)
             VALUES ($1, 'restauration', 'categorie.restauration.nom', 'restauration')",
        )
        .bind(Uuid::now_v7())
        .execute(&mut **tx)
        .await
        .unwrap();
        zone.id
    }

    /// Validation par namespace : valeurs conformes acceptées, non conformes
    /// refusées ; namespace libre (FR-011) accepté.
    #[sqlx::test(migrations = "../../migrations")]
    async fn validation_par_cle(pool: PgPool) {
        let z = PgZones::new(pool.clone());
        let mut tx = pool.begin().await.unwrap();
        let zone = zone_avec_categorie(&z, &mut tx).await;

        // Valides.
        for (cle, val) in [
            ("devise.code", json!("XOF")),
            ("devise.decimales", json!(0)),
            ("drapeau.pluie", json!(false)),
            ("transport.actifs", json!(["a_pied", "moto"])),
            ("categorie.restauration.seuil_activation", json!(8)),
            ("categorie.restauration.mixable", json!(false)),
            ("texte.bandeau", json!("Bienvenue")),
            ("client.theme", json!({ "mode": "clair" })),
            ("dispatch.rayon_km", json!(3)), // namespace libre (FR-011)
        ] {
            z.definir_parametre(&mut tx, zone, cle, val, "test")
                .await
                .unwrap_or_else(|e| panic!("{cle} devrait être accepté : {e}"));
        }

        // Invalides (types).
        for (cle, val) in [
            ("devise.code", json!("us")),
            ("devise.decimales", json!(5)),
            ("drapeau.pluie", json!("oui")),
            ("transport.actifs", json!("moto")),
            ("categorie.restauration.seuil_activation", json!(0)),
            ("texte.bandeau", json!(42)),
        ] {
            let err = z
                .definir_parametre(&mut tx, zone, cle, val, "test")
                .await
                .unwrap_err();
            assert!(
                matches!(err, ErreurZones::ValeurInvalide { .. }),
                "{cle} devrait être refusé (ValeurInvalide), obtenu {err:?}"
            );
        }

        // Slug de catégorie inconnu.
        let err = z
            .definir_parametre(&mut tx, zone, "categorie.inconnue.mixable", json!(true), "test")
            .await
            .unwrap_err();
        assert!(matches!(err, ErreurZones::CategorieInconnue(_)));
    }

    /// Commit → événement `zone.parametre_modifie` présent ; avant/après corrects.
    #[sqlx::test(migrations = "../../migrations")]
    async fn commit_emet_evenement(pool: PgPool) {
        let z = PgZones::new(pool.clone());
        let mut tx = pool.begin().await.unwrap();
        let zone = z
            .creer_zone(&mut tx, None, TypeZone::Pays, "CI")
            .await
            .unwrap();
        z.definir_parametre(&mut tx, zone.id, "texte.bandeau", json!("A"), "admin")
            .await
            .unwrap();
        tx.commit().await.unwrap();

        let (type_ev, payload): (String, Value) = sqlx::query_as(
            "SELECT type_evenement, payload FROM outbox.evenement
             WHERE type_evenement = 'zone.parametre_modifie' ORDER BY cree_le DESC LIMIT 1",
        )
        .fetch_one(&pool)
        .await
        .unwrap();
        assert_eq!(type_ev, "zone.parametre_modifie");
        assert_eq!(payload["cle"], json!("texte.bandeau"));
        assert_eq!(payload["apres"], json!("A"));
        assert_eq!(payload["avant"], Value::Null, "création → avant null");
        assert_eq!(payload["acteur"], json!("admin"));

        // Redéfinir → avant = ancienne valeur.
        let mut tx = pool.begin().await.unwrap();
        z.definir_parametre(&mut tx, zone.id, "texte.bandeau", json!("B"), "admin")
            .await
            .unwrap();
        tx.commit().await.unwrap();
        let payload2: Value = sqlx::query_scalar(
            "SELECT payload FROM outbox.evenement
             WHERE type_evenement = 'zone.parametre_modifie' ORDER BY cree_le DESC LIMIT 1",
        )
        .fetch_one(&pool)
        .await
        .unwrap();
        assert_eq!(payload2["avant"], json!("A"));
        assert_eq!(payload2["apres"], json!("B"));
    }

    /// Rollback → ni paramètre ni événement (atomicité, constitution VI).
    #[sqlx::test(migrations = "../../migrations")]
    async fn rollback_aucun_evenement(pool: PgPool) {
        let z = PgZones::new(pool.clone());
        let mut tx = pool.begin().await.unwrap();
        let zone = z
            .creer_zone(&mut tx, None, TypeZone::Pays, "CI")
            .await
            .unwrap();
        z.definir_parametre(&mut tx, zone.id, "texte.bandeau", json!("A"), "admin")
            .await
            .unwrap();
        tx.rollback().await.unwrap();

        let evenements: i64 = sqlx::query_scalar(
            "SELECT count(*) FROM outbox.evenement WHERE type_evenement = 'zone.parametre_modifie'",
        )
        .fetch_one(&pool)
        .await
        .unwrap();
        assert_eq!(evenements, 0, "rollback → aucun événement");
        let parametres: i64 = sqlx::query_scalar("SELECT count(*) FROM zones.parametre_zone")
            .fetch_one(&pool)
            .await
            .unwrap();
        assert_eq!(parametres, 0, "rollback → aucun paramètre");
    }
}
