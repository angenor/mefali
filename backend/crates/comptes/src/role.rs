//! L'UNIQUE machine à états des attributions de rôle (CPT-03, research R9,
//! data-model §4).
//!
//! ## Pourquoi une seule machine
//!
//! Le « statut du dossier coursier » (FR-016) EST le statut de l'attribution
//! `coursier`. Deux statuts — un sur le rôle, un sur le dossier — divergeraient
//! fatalement : un dossier validé avec un rôle encore en attente, et la porte
//! de mise en ligne (SC-005) deviendrait une question d'interprétation.
//!
//! ## Ce que ce module garantit
//!
//! Chaque transition écrit son événement `role.*` dans LA transaction de
//! l'appelant (constitution VI), avec `decide_par` et `motif` : le journal
//! exigé par FR-014 n'est pas une table d'audit à part, c'est cette colonne et
//! cet événement. Toute transition non prévue par data-model §4 est refusée —
//! il n'y a pas de chemin « par défaut ».

use chrono::Utc;
use serde_json::json;
use socle::{ecrire_evenement, NouvelEvenement};
use uuid::Uuid;

use crate::depot::PgComptes;
use crate::modele::{AttributionRole, ErreurComptes, Role, StatutRole};

/// Décision d'un admin sur un rôle (contrat `/admin/comptes/{id}/roles/{role}`).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ActionRole {
    /// Vendeur (à l'agrément, §5.1) ou admin (FR-012) : ∅ → valide.
    Attribuer,
    /// Coursier : en_attente → valide.
    Valider,
    /// Coursier : en_attente → refuse (motif REQUIS).
    Refuser,
    /// Coursier/vendeur : valide → suspendu (motif REQUIS).
    Suspendre,
    /// Coursier/vendeur : suspendu → valide.
    Retablir,
}

impl ActionRole {
    /// Événement émis par cette action (taxonomie CPT).
    fn evenement(self) -> &'static str {
        match self {
            ActionRole::Attribuer => "role.attribue",
            ActionRole::Valider => "role.valide",
            ActionRole::Refuser => "role.refuse",
            ActionRole::Suspendre => "role.suspendu",
            ActionRole::Retablir => "role.retabli",
        }
    }

    /// Un refus et une suspension PRIVENT quelqu'un de son gagne-pain : la spec
    /// exige qu'ils soient motivés (FR-017). Valider ou rétablir, non.
    fn motif_requis(self) -> bool {
        matches!(self, ActionRole::Refuser | ActionRole::Suspendre)
    }
}

/// Transition attendue par data-model §4 : (rôle, statut avant) → statut après.
///
/// Table EXHAUSTIVE et volontairement verbeuse : c'est la spec, écrite une fois.
/// `None` en entrée = aucune attribution.
fn transition(role: Role, action: ActionRole, avant: Option<StatutRole>) -> Option<StatutRole> {
    use ActionRole as A;
    use Role as R;
    use StatutRole as S;

    match (role, action, avant) {
        // Le rôle client est posé à l'inscription et immuable ce cycle (R9) —
        // le CHECK du schéma le garantit de toute façon.
        (R::Client, _, _) => None,

        // Vendeur : l'agrément VAUT validation (§5.1) — aucune demande in-app.
        // Admin : attribué par un admin existant (FR-012).
        (R::Vendeur | R::Admin, A::Attribuer, None) => Some(S::Valide),
        // Coursier : jamais « attribué » — il se demande avec un dossier (CPT-04).
        (R::Coursier, A::Attribuer, _) => None,
        (R::Vendeur | R::Admin, A::Attribuer, Some(_)) => None,

        // Coursier : décision sur une demande en attente.
        (R::Coursier, A::Valider, Some(S::EnAttente)) => Some(S::Valide),
        (R::Coursier, A::Refuser, Some(S::EnAttente)) => Some(S::Refuse),

        // Suspendre / rétablir : coursier ET vendeur.
        (R::Coursier | R::Vendeur, A::Suspendre, Some(S::Valide)) => Some(S::Suspendu),
        (R::Coursier | R::Vendeur, A::Retablir, Some(S::Suspendu)) => Some(S::Valide),

        // Un admin ne se suspend pas : le retrait du rôle admin n'est pas au
        // périmètre de ce cycle (aucun scénario de la spec ne le demande).
        (R::Admin, _, _) => None,

        // Tout le reste : refusé. Valider un rôle déjà validé, rétablir un rôle
        // jamais suspendu, refuser un coursier suspendu…
        _ => None,
    }
}

impl PgComptes {
    /// Applique une décision admin sur un rôle et émet son événement.
    ///
    /// `decide_par` est l'admin décideur — le contrôle de SON rôle appartient à
    /// la couche `api` (`exiger_role(Admin)`), pas ici : le domaine ne connaît
    /// pas les requêtes HTTP.
    pub async fn decider_role(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        compte: Uuid,
        role: Role,
        action: ActionRole,
        decide_par: Uuid,
        motif: Option<&str>,
    ) -> Result<AttributionRole, ErreurComptes> {
        let motif = motif.map(str::trim).filter(|m| !m.is_empty());
        if action.motif_requis() && motif.is_none() {
            return Err(ErreurComptes::MotifRequis);
        }
        if !self.compte_existe(tx, compte).await? {
            return Err(ErreurComptes::CompteInconnu(compte));
        }

        let avant = statut_role(tx, compte, role).await?;
        let Some(apres) = transition(role, action, avant) else {
            return Err(ErreurComptes::TransitionInvalide {
                role,
                avant: avant.map_or_else(|| "aucun".to_owned(), |s| s.comme_str().to_owned()),
                apres: format!("{action:?}").to_lowercase(),
            });
        };

        let maintenant = Utc::now();
        // UPSERT : l'attribution naît (attribuer) ou change d'état (décisions).
        let ligne = sqlx::query!(
            r#"INSERT INTO comptes.attribution_role
                 (compte_id, role, statut, motif, decide_par, decide_le)
               VALUES ($1, $2::text::comptes.role, $3::text::comptes.statut_role, $4, $5, $6)
               ON CONFLICT (compte_id, role) DO UPDATE SET
                 statut = EXCLUDED.statut,
                 motif = EXCLUDED.motif,
                 decide_par = EXCLUDED.decide_par,
                 decide_le = EXCLUDED.decide_le
               RETURNING demande_le"#,
            compte,
            role.comme_str(),
            apres.comme_str(),
            motif,
            decide_par,
            maintenant,
        )
        .fetch_one(&mut **tx)
        .await?;

        self.emettre_role(
            tx,
            action.evenement(),
            compte,
            role,
            avant,
            apres,
            Some(decide_par),
            motif,
            maintenant,
        )
        .await?;

        Ok(AttributionRole {
            role,
            statut: apres,
            motif: motif.map(str::to_owned),
            decide_par: Some(decide_par),
            decide_le: Some(maintenant),
            demande_le: ligne.demande_le,
        })
    }

    /// ∅ | refuse → en_attente : la demande de rôle coursier, portée par la
    /// soumission du dossier (CPT-04). Émet `role.demande`.
    ///
    /// Pas une décision admin : `decide_par` reste NULL et le motif du refus
    /// précédent est effacé — il ne concernait plus le nouveau dossier.
    ///
    /// Reste `pub(crate)` À DESSEIN : la publier laisserait demander le rôle
    /// coursier SANS dossier, ce que FR-015 interdit. Son unique appelant hors
    /// tests est `dossier.rs` — c'est la visibilité du langage, et non une
    /// convention de revue, qui tient la règle.
    pub(crate) async fn demander_role_coursier(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        compte: Uuid,
    ) -> Result<StatutRole, ErreurComptes> {
        let avant = statut_role(tx, compte, Role::Coursier).await?;
        // Seuls ∅ et `refuse` ouvrent une (nouvelle) demande. `en_attente`,
        // `valide` et `suspendu` sont des 409 (R14 : le rejeu idempotent d'une
        // demande en attente est traité par l'appelant, pas ici).
        if !matches!(avant, None | Some(StatutRole::Refuse)) {
            return Err(ErreurComptes::TransitionInvalide {
                role: Role::Coursier,
                avant: avant.map_or_else(|| "aucun".to_owned(), |s| s.comme_str().to_owned()),
                apres: StatutRole::EnAttente.comme_str().to_owned(),
            });
        }

        let maintenant = Utc::now();
        sqlx::query!(
            r#"INSERT INTO comptes.attribution_role
                 (compte_id, role, statut, demande_le)
               VALUES ($1, 'coursier'::comptes.role, 'en_attente'::comptes.statut_role, $2)
               ON CONFLICT (compte_id, role) DO UPDATE SET
                 statut = 'en_attente'::comptes.statut_role,
                 motif = NULL,
                 decide_par = NULL,
                 decide_le = NULL,
                 demande_le = EXCLUDED.demande_le"#,
            compte,
            maintenant,
        )
        .execute(&mut **tx)
        .await?;

        self.emettre_role(
            tx,
            "role.demande",
            compte,
            Role::Coursier,
            avant,
            StatutRole::EnAttente,
            None,
            None,
            maintenant,
        )
        .await?;
        Ok(StatutRole::EnAttente)
    }

    /// Écrit un événement `role.*` — payload commun à toutes les transitions
    /// (taxonomie CPT, T004).
    #[allow(clippy::too_many_arguments)]
    async fn emettre_role(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        type_evenement: &str,
        compte: Uuid,
        role: Role,
        avant: Option<StatutRole>,
        apres: StatutRole,
        decide_par: Option<Uuid>,
        motif: Option<&str>,
        survenu_le: chrono::DateTime<Utc>,
    ) -> Result<(), ErreurComptes> {
        let zone = sqlx::query_scalar!("SELECT zone_id FROM comptes.compte WHERE id = $1", compte,)
            .fetch_one(&mut **tx)
            .await?;

        ecrire_evenement(
            tx,
            NouvelEvenement {
                type_evenement,
                // PK composite (compte_id, role) : aucun id de substitution —
                // entite_id = compte, le rôle vit dans le payload (T004).
                entite_type: "attribution_role",
                entite_id: compte,
                payload: json!({
                    "zone": zone,
                    "compte": compte,
                    "role": role.comme_str(),
                    "avant": avant.map(StatutRole::comme_str),
                    "apres": apres.comme_str(),
                    "decide_par": decide_par,
                    "motif": motif,
                }),
                survenu_le,
            },
        )
        .await?;
        Ok(())
    }

    /// Existence d'un compte, dans la transaction en cours.
    pub(crate) async fn compte_existe(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        compte: Uuid,
    ) -> Result<bool, ErreurComptes> {
        let existe = sqlx::query_scalar!(
            "SELECT EXISTS(SELECT 1 FROM comptes.compte WHERE id = $1)",
            compte,
        )
        .fetch_one(&mut **tx)
        .await?;
        Ok(existe.unwrap_or(false))
    }
}

/// Statut d'une attribution dans la transaction en cours (`None` = aucune).
pub(crate) async fn statut_role(
    tx: &mut sqlx::PgTransaction<'_>,
    compte: Uuid,
    role: Role,
) -> Result<Option<StatutRole>, ErreurComptes> {
    let ligne = sqlx::query_scalar!(
        r#"SELECT statut::text AS "statut!" FROM comptes.attribution_role
           WHERE compte_id = $1 AND role = $2::text::comptes.role"#,
        compte,
        role.comme_str(),
    )
    .fetch_optional(&mut **tx)
    .await?;

    ligne
        .map(|s| s.parse().map_err(ErreurComptes::Jeton))
        .transpose()
}

#[cfg(test)]
mod tests {
    use super::*;

    /// La table de transitions EST la spec (data-model §4) : on la relit ici
    /// sans base, transition par transition.
    #[test]
    fn table_de_transitions_conforme_a_data_model() {
        use ActionRole as A;
        use Role as R;
        use StatutRole as S;

        // Coursier — 4 décisions admin (la demande a son propre chemin).
        assert_eq!(
            transition(R::Coursier, A::Valider, Some(S::EnAttente)),
            Some(S::Valide)
        );
        assert_eq!(
            transition(R::Coursier, A::Refuser, Some(S::EnAttente)),
            Some(S::Refuse)
        );
        assert_eq!(
            transition(R::Coursier, A::Suspendre, Some(S::Valide)),
            Some(S::Suspendu)
        );
        assert_eq!(
            transition(R::Coursier, A::Retablir, Some(S::Suspendu)),
            Some(S::Valide)
        );

        // Vendeur — l'agrément vaut validation, puis suspension/rétablissement.
        assert_eq!(transition(R::Vendeur, A::Attribuer, None), Some(S::Valide));
        assert_eq!(
            transition(R::Vendeur, A::Suspendre, Some(S::Valide)),
            Some(S::Suspendu)
        );
        assert_eq!(
            transition(R::Vendeur, A::Retablir, Some(S::Suspendu)),
            Some(S::Valide)
        );

        // Admin — attribution seule (FR-012).
        assert_eq!(transition(R::Admin, A::Attribuer, None), Some(S::Valide));
    }

    #[test]
    fn transitions_hors_machine_refusees() {
        use ActionRole as A;
        use Role as R;
        use StatutRole as S;

        // Le client est immuable.
        for action in [
            A::Attribuer,
            A::Valider,
            A::Refuser,
            A::Suspendre,
            A::Retablir,
        ] {
            assert_eq!(transition(R::Client, action, Some(S::Valide)), None);
        }
        // Le coursier ne s'attribue pas — il se demande avec un dossier.
        assert_eq!(transition(R::Coursier, A::Attribuer, None), None);
        // On ne valide pas une demande inexistante, ni un rôle déjà validé.
        assert_eq!(transition(R::Coursier, A::Valider, None), None);
        assert_eq!(transition(R::Coursier, A::Valider, Some(S::Valide)), None);
        // On ne refuse pas un coursier déjà refusé ou suspendu.
        assert_eq!(transition(R::Coursier, A::Refuser, Some(S::Refuse)), None);
        assert_eq!(transition(R::Coursier, A::Refuser, Some(S::Suspendu)), None);
        // On ne suspend pas ce qui n'est pas validé, on ne rétablit pas ce qui
        // n'est pas suspendu.
        assert_eq!(
            transition(R::Coursier, A::Suspendre, Some(S::EnAttente)),
            None
        );
        assert_eq!(transition(R::Vendeur, A::Retablir, Some(S::Valide)), None);
        // Un vendeur déjà attribué ne se ré-attribue pas (rétablir existe).
        assert_eq!(
            transition(R::Vendeur, A::Attribuer, Some(S::Suspendu)),
            None
        );
        // Le rôle admin ne se suspend pas ce cycle.
        assert_eq!(transition(R::Admin, A::Suspendre, Some(S::Valide)), None);
    }

    #[test]
    fn motif_requis_seulement_pour_refuser_et_suspendre() {
        assert!(ActionRole::Refuser.motif_requis());
        assert!(ActionRole::Suspendre.motif_requis());
        assert!(!ActionRole::Valider.motif_requis());
        assert!(!ActionRole::Retablir.motif_requis());
        assert!(!ActionRole::Attribuer.motif_requis());
    }
}

#[cfg(test)]
mod tests_integration {
    use super::*;
    use std::sync::Arc;

    use crate::depot::Comptes;
    use crate::modele::Role;
    use crate::ports::{MemoireEphemere, MemoireObjets, SmsTraces};
    use serde_json::Value;
    use sqlx::PgPool;
    use zones::{PgZones, TypeZone};

    /// La machine est testée ICI et non dans `tests/` : `demander_role_coursier`
    /// est `pub(crate)` À DESSEIN — la publier laisserait demander le rôle
    /// coursier SANS dossier, ce que FR-015 interdit. Ses tests vivent donc avec
    /// elle.
    struct Bac {
        depot: PgComptes,
        pool: PgPool,
    }

    async fn bac(pool: PgPool) -> (Bac, Uuid, Uuid) {
        let z = PgZones::new(pool.clone());
        let mut tx = pool.begin().await.unwrap();
        let pays = z
            .creer_zone(&mut tx, None, TypeZone::Pays, "CI")
            .await
            .unwrap()
            .id;
        let ville = z
            .creer_zone(&mut tx, Some(pays), TypeZone::Ville, "Tiassalé")
            .await
            .unwrap()
            .id;
        tx.commit().await.unwrap();

        let depot = PgComptes::new(
            pool.clone(),
            Arc::new(MemoireEphemere::new()),
            Arc::new(SmsTraces::new()),
            Arc::new(MemoireObjets::new()),
            Arc::from(&b"secret-de-test-de-32-octets-mini"[..]),
        );
        let mut tx = pool.begin().await.unwrap();
        let yao = depot
            .creer_compte(&mut tx, "+2250701020304", ville, "2026-07")
            .await
            .unwrap()
            .id;
        let admin = depot
            .creer_compte(&mut tx, "+2250700000001", ville, "2026-07")
            .await
            .unwrap()
            .id;
        tx.commit().await.unwrap();
        (Bac { depot, pool }, yao, admin)
    }

    impl Bac {
        async fn decider(
            &self,
            compte: Uuid,
            role: Role,
            action: ActionRole,
            admin: Uuid,
            motif: Option<&str>,
        ) -> Result<AttributionRole, ErreurComptes> {
            let mut tx = self.pool.begin().await.unwrap();
            let r = self
                .depot
                .decider_role(&mut tx, compte, role, action, admin, motif)
                .await;
            if r.is_ok() {
                tx.commit().await.unwrap();
            }
            r
        }

        async fn demander_coursier(&self, compte: Uuid) -> Result<StatutRole, ErreurComptes> {
            let mut tx = self.pool.begin().await.unwrap();
            let r = self.depot.demander_role_coursier(&mut tx, compte).await;
            if r.is_ok() {
                tx.commit().await.unwrap();
            }
            r
        }

        async fn evenements(&self, type_evenement: &str) -> Vec<Value> {
            sqlx::query_scalar(
                "SELECT payload FROM outbox.evenement WHERE type_evenement = $1 ORDER BY id",
            )
            .bind(type_evenement)
            .fetch_all(&self.pool)
            .await
            .unwrap()
        }
    }

    /// data-model §4 — le cycle COMPLET du coursier, transition par transition,
    /// avec l'événement de chacune (constitution VI/VII).
    #[sqlx::test(migrations = "../../migrations")]
    async fn cycle_complet_du_coursier(pool: PgPool) {
        let (bac, yao, admin) = bac(pool).await;

        // ∅ → en_attente (demande, portée par le dossier en T017).
        assert_eq!(
            bac.demander_coursier(yao).await.unwrap(),
            StatutRole::EnAttente
        );
        assert!(!bac.depot.coursier_autorise_en_ligne(yao).await.unwrap());
        let demandes = bac.evenements("role.demande").await;
        assert_eq!(demandes.len(), 1);
        assert_eq!(demandes[0]["avant"], Value::Null);
        assert_eq!(demandes[0]["apres"], "en_attente");
        assert_eq!(
            demandes[0]["decide_par"],
            Value::Null,
            "personne n'a décidé"
        );

        // en_attente → refuse (motif requis).
        let refus = bac
            .decider(
                yao,
                Role::Coursier,
                ActionRole::Refuser,
                admin,
                Some("pièce illisible"),
            )
            .await
            .unwrap();
        assert_eq!(refus.statut, StatutRole::Refuse);
        assert_eq!(refus.motif.as_deref(), Some("pièce illisible"));
        assert!(!bac.depot.coursier_autorise_en_ligne(yao).await.unwrap());

        // refuse → en_attente (re-soumission) : le motif du refus est effacé, il
        // ne concernait plus ce dossier-ci.
        assert_eq!(
            bac.demander_coursier(yao).await.unwrap(),
            StatutRole::EnAttente
        );
        let attributions = bac.depot.attributions(yao).await.unwrap();
        let coursier = attributions
            .iter()
            .find(|a| a.role == Role::Coursier)
            .unwrap();
        assert!(
            coursier.motif.is_none(),
            "le motif du refus précédent est effacé"
        );
        assert!(coursier.decide_par.is_none());

        // en_attente → valide : LA porte s'ouvre (SC-005).
        let valide = bac
            .decider(yao, Role::Coursier, ActionRole::Valider, admin, None)
            .await
            .unwrap();
        assert_eq!(valide.statut, StatutRole::Valide);
        assert_eq!(valide.decide_par, Some(admin));
        assert!(valide.decide_le.is_some());
        assert!(bac.depot.coursier_autorise_en_ligne(yao).await.unwrap());

        // valide → suspendu : la porte se referme.
        bac.decider(
            yao,
            Role::Coursier,
            ActionRole::Suspendre,
            admin,
            Some("plaintes"),
        )
        .await
        .unwrap();
        assert!(!bac.depot.coursier_autorise_en_ligne(yao).await.unwrap());

        // suspendu → valide : elle se rouvre.
        bac.decider(yao, Role::Coursier, ActionRole::Retablir, admin, None)
            .await
            .unwrap();
        assert!(bac.depot.coursier_autorise_en_ligne(yao).await.unwrap());

        // SC-008 — chaque transition a laissé son événement journalisé.
        for (type_evenement, attendu) in [
            ("role.demande", 2),
            ("role.refuse", 1),
            ("role.valide", 1),
            ("role.suspendu", 1),
            ("role.retabli", 1),
        ] {
            assert_eq!(
                bac.evenements(type_evenement).await.len(),
                attendu,
                "événement {type_evenement}"
            );
        }
        let suspensions = bac.evenements("role.suspendu").await;
        assert_eq!(suspensions[0]["decide_par"], serde_json::json!(admin));
        assert_eq!(suspensions[0]["motif"], "plaintes");
        assert_eq!(suspensions[0]["avant"], "valide");
        assert_eq!(suspensions[0]["apres"], "suspendu");
    }

    /// §5.1 — le vendeur naît VALIDE à l'agrément : aucune demande in-app.
    #[sqlx::test(migrations = "../../migrations")]
    async fn cycle_du_vendeur_attribue_a_l_agrement(pool: PgPool) {
        let (bac, kofi, admin) = bac(pool).await;

        let attribue = bac
            .decider(kofi, Role::Vendeur, ActionRole::Attribuer, admin, None)
            .await
            .unwrap();
        assert_eq!(
            attribue.statut,
            StatutRole::Valide,
            "l'agrément VAUT validation"
        );
        assert!(bac
            .depot
            .roles_valides(kofi)
            .await
            .unwrap()
            .contains(&Role::Vendeur));

        bac.decider(
            kofi,
            Role::Vendeur,
            ActionRole::Suspendre,
            admin,
            Some("boutique fermée"),
        )
        .await
        .unwrap();
        assert!(!bac
            .depot
            .roles_valides(kofi)
            .await
            .unwrap()
            .contains(&Role::Vendeur));

        bac.decider(kofi, Role::Vendeur, ActionRole::Retablir, admin, None)
            .await
            .unwrap();
        assert!(bac
            .depot
            .roles_valides(kofi)
            .await
            .unwrap()
            .contains(&Role::Vendeur));

        assert_eq!(bac.evenements("role.attribue").await.len(), 1);
        assert_eq!(bac.evenements("role.suspendu").await.len(), 1);
        assert_eq!(bac.evenements("role.retabli").await.len(), 1);
    }

    /// FR-010 — les rôles se CUMULENT sur un même compte, un même numéro.
    #[sqlx::test(migrations = "../../migrations")]
    async fn roles_cumulables_sur_un_meme_compte(pool: PgPool) {
        let (bac, compte, admin) = bac(pool).await;

        bac.demander_coursier(compte).await.unwrap();
        bac.decider(compte, Role::Coursier, ActionRole::Valider, admin, None)
            .await
            .unwrap();
        bac.decider(compte, Role::Vendeur, ActionRole::Attribuer, admin, None)
            .await
            .unwrap();
        bac.decider(compte, Role::Admin, ActionRole::Attribuer, admin, None)
            .await
            .unwrap();

        // Ordre de l'énum (client, coursier, vendeur, admin) — pas alphabétique.
        assert_eq!(
            bac.depot.roles_valides(compte).await.unwrap(),
            vec![Role::Client, Role::Coursier, Role::Vendeur, Role::Admin]
        );
        let comptes: i64 = sqlx::query_scalar("SELECT count(*) FROM comptes.compte")
            .fetch_one(&bac.pool)
            .await
            .unwrap();
        assert_eq!(
            comptes, 2,
            "un seul compte par numéro, quels que soient les rôles"
        );
    }

    /// FR-017 — refuser ou suspendre SANS motif est refusé, et ne change rien.
    #[sqlx::test(migrations = "../../migrations")]
    async fn motif_requis_pour_refuser_et_suspendre(pool: PgPool) {
        let (bac, yao, admin) = bac(pool).await;
        bac.demander_coursier(yao).await.unwrap();

        for motif in [None, Some(""), Some("   ")] {
            assert!(
                matches!(
                    bac.decider(yao, Role::Coursier, ActionRole::Refuser, admin, motif)
                        .await,
                    Err(ErreurComptes::MotifRequis)
                ),
                "motif {motif:?} doit être refusé"
            );
        }
        assert_eq!(
            statut_role(&mut bac.pool.begin().await.unwrap(), yao, Role::Coursier)
                .await
                .unwrap(),
            Some(StatutRole::EnAttente),
            "l'état n'a pas bougé"
        );
        assert_eq!(bac.evenements("role.refuse").await.len(), 0);
    }

    /// R9 — une transition hors machine est refusée, sans effet ni événement.
    #[sqlx::test(migrations = "../../migrations")]
    async fn transitions_invalides_refusees_sans_effet(pool: PgPool) {
        let (bac, yao, admin) = bac(pool).await;

        // Valider un coursier qui n'a rien demandé.
        assert!(matches!(
            bac.decider(yao, Role::Coursier, ActionRole::Valider, admin, None)
                .await,
            Err(ErreurComptes::TransitionInvalide { .. })
        ));
        // Attribuer le rôle coursier (il se DEMANDE, avec un dossier).
        assert!(matches!(
            bac.decider(yao, Role::Coursier, ActionRole::Attribuer, admin, None)
                .await,
            Err(ErreurComptes::TransitionInvalide { .. })
        ));
        // Toucher au rôle client.
        assert!(matches!(
            bac.decider(yao, Role::Client, ActionRole::Suspendre, admin, Some("x"))
                .await,
            Err(ErreurComptes::TransitionInvalide { .. })
        ));
        // Rétablir un vendeur jamais suspendu.
        bac.decider(yao, Role::Vendeur, ActionRole::Attribuer, admin, None)
            .await
            .unwrap();
        assert!(matches!(
            bac.decider(yao, Role::Vendeur, ActionRole::Retablir, admin, None)
                .await,
            Err(ErreurComptes::TransitionInvalide { .. })
        ));
        // Ré-attribuer un vendeur déjà attribué.
        assert!(matches!(
            bac.decider(yao, Role::Vendeur, ActionRole::Attribuer, admin, None)
                .await,
            Err(ErreurComptes::TransitionInvalide { .. })
        ));

        // Le rôle client est intact, le vendeur reste valide, rien d'autre.
        assert_eq!(
            bac.depot.roles_valides(yao).await.unwrap(),
            vec![Role::Client, Role::Vendeur]
        );
    }

    /// Une demande sur un dossier DÉJÀ en attente est refusée (le rejeu
    /// idempotent est traité par l'appelant — R14, T018).
    #[sqlx::test(migrations = "../../migrations")]
    async fn demande_refusee_si_deja_en_attente_ou_valide(pool: PgPool) {
        let (bac, yao, admin) = bac(pool).await;
        bac.demander_coursier(yao).await.unwrap();

        assert!(matches!(
            bac.demander_coursier(yao).await,
            Err(ErreurComptes::TransitionInvalide { .. })
        ));
        bac.decider(yao, Role::Coursier, ActionRole::Valider, admin, None)
            .await
            .unwrap();
        assert!(matches!(
            bac.demander_coursier(yao).await,
            Err(ErreurComptes::TransitionInvalide { .. })
        ));
        assert_eq!(bac.evenements("role.demande").await.len(), 1);
    }

    /// Constitution VI — un rollback ne laisse NI transition NI événement.
    #[sqlx::test(migrations = "../../migrations")]
    async fn rollback_ne_laisse_ni_transition_ni_evenement(pool: PgPool) {
        let (bac, yao, admin) = bac(pool).await;

        let mut tx = bac.pool.begin().await.unwrap();
        bac.depot
            .decider_role(
                &mut tx,
                yao,
                Role::Vendeur,
                ActionRole::Attribuer,
                admin,
                None,
            )
            .await
            .unwrap();
        tx.rollback().await.unwrap();

        assert_eq!(
            bac.depot.roles_valides(yao).await.unwrap(),
            vec![Role::Client]
        );
        assert_eq!(bac.evenements("role.attribue").await.len(), 0);
    }

    /// Un compte inconnu n'a pas de rôle à décider.
    #[sqlx::test(migrations = "../../migrations")]
    async fn compte_inconnu_refuse(pool: PgPool) {
        let (bac, _, admin) = bac(pool).await;
        assert!(matches!(
            bac.decider(
                Uuid::now_v7(),
                Role::Vendeur,
                ActionRole::Attribuer,
                admin,
                None
            )
            .await,
            Err(ErreurComptes::CompteInconnu(_))
        ));
    }
}
