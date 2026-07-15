//! Surface HTTP d'administration des rôles (CPT-03, `/admin/comptes/*`).
//!
//! Aucun écran n'est construit avant le cycle ADM (tranche T3) : ces actions
//! vivent en API, protégées par le rôle admin et journalisées (spec, §Surface
//! utilisateur). C'est le précédent posé au cycle 002 pour le forçage de zone.

use actix_web::{post, web, HttpResponse};
use serde::Deserialize;
use utoipa::ToSchema;
use uuid::Uuid;

use comptes::{ActionRole, PgComptes, Role};

use crate::auth_http::{Auth, ErreurApi, ErreurApiDto, EtatRoleDto};

/// Action d'administration sur un rôle (contrat).
#[derive(Debug, Clone, Copy, Deserialize, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum ActionRoleDto {
    /// Vendeur (à l'agrément, §5.1) ou admin (FR-012).
    Attribuer,
    /// Coursier : accepte la demande.
    Valider,
    /// Coursier : refuse la demande (motif requis).
    Refuser,
    /// Coursier/vendeur : suspend (motif requis).
    Suspendre,
    /// Coursier/vendeur : rétablit.
    Retablir,
}

impl From<ActionRoleDto> for ActionRole {
    fn from(a: ActionRoleDto) -> Self {
        match a {
            ActionRoleDto::Attribuer => ActionRole::Attribuer,
            ActionRoleDto::Valider => ActionRole::Valider,
            ActionRoleDto::Refuser => ActionRole::Refuser,
            ActionRoleDto::Suspendre => ActionRole::Suspendre,
            ActionRoleDto::Retablir => ActionRole::Retablir,
        }
    }
}

/// Rôle décidable par l'admin. `client` en est ABSENT : il n'est pas décidable
/// (posé à l'inscription, immuable — R9). L'exclure du type le rend
/// irreprésentable, plutôt que de le refuser à l'exécution.
#[derive(Debug, Clone, Copy, Deserialize, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum RoleDecidableDto {
    /// Coursier — demandé in-app avec dossier.
    Coursier,
    /// Vendeur — attribué à l'agrément.
    Vendeur,
    /// Admin — attribué par un admin existant.
    Admin,
}

impl From<RoleDecidableDto> for Role {
    fn from(r: RoleDecidableDto) -> Self {
        match r {
            RoleDecidableDto::Coursier => Role::Coursier,
            RoleDecidableDto::Vendeur => Role::Vendeur,
            RoleDecidableDto::Admin => Role::Admin,
        }
    }
}

/// Corps de la décision.
#[derive(Debug, Deserialize, ToSchema)]
pub struct DecisionRole {
    /// Action à appliquer.
    pub action: ActionRoleDto,
    /// Motif — REQUIS pour `refuser` et `suspendre` (FR-017).
    #[schema(max_length = 500)]
    pub motif: Option<String>,
}

/// Décision admin sur un rôle — machine à états de data-model §4, journalisée.
#[utoipa::path(
    post,
    path = "/admin/comptes/{compte_id}/roles/{role}",
    tag = "admin",
    params(
        ("compte_id" = Uuid, Path, description = "Compte concerné."),
        // `inline` et non un $ref : utoipa ne collecte les schémas que depuis les
        // corps et les réponses, jamais depuis les paramètres de chemin — le $ref
        // pendouillerait et le générateur de clients refuserait la spec. Le
        // contrat attend de toute façon une énumération EN LIGNE.
        ("role" = inline(RoleDecidableDto), Path, description = "Rôle décidé (client exclu : immuable)."),
    ),
    request_body = DecisionRole,
    responses(
        (status = 200, description = "Nouvel état du rôle. Prise d'effet IMMÉDIATE (contrôle par requête, R5).",
         body = EtatRoleDto),
        (status = 409, description = "Transition invalide pour l'état courant.", body = ErreurApiDto),
        (status = 404, description = "Compte inconnu.", body = ErreurApiDto),
        (status = 403, description = "Rôle admin requis — seul un admin existant décide (FR-012).",
         body = ErreurApiDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
        (status = 422, description = "Motif absent pour un refus ou une suspension.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[post("/admin/comptes/{compte_id}/roles/{role}")]
pub async fn decider_role(
    auth: Auth,
    chemin: web::Path<(Uuid, RoleDecidableDto)>,
    corps: web::Json<DecisionRole>,
    depot: web::Data<PgComptes>,
) -> Result<HttpResponse, ErreurApi> {
    // FR-012 : seul un admin EXISTANT attribue le rôle admin ou décide des
    // rôles professionnels. Le domaine ne connaît pas HTTP — la garde est ici.
    auth.exiger_role(Role::Admin)?;
    let (compte_id, role) = chemin.into_inner();

    let mut tx = depot
        .pool()
        .begin()
        .await
        .map_err(comptes::ErreurComptes::from)?;
    let attribution = depot
        .decider_role(
            &mut tx,
            compte_id,
            role.into(),
            corps.action.into(),
            auth.compte_id,
            corps.motif.as_deref(),
        )
        .await?;
    tx.commit().await.map_err(comptes::ErreurComptes::from)?;

    Ok(HttpResponse::Ok().json(EtatRoleDto::from(attribution)))
}

/// `PathConfig` du module : un rôle hors énumération → 404 plutôt que le 400
/// par défaut d'Actix — `/roles/client` désigne une ressource qui n'existe pas.
pub fn config_path() -> web::PathConfig {
    web::PathConfig::default().error_handler(|_err, _req| ErreurApi::Introuvable.into())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::sync::Arc;

    use actix_web::{http::StatusCode, test as atest, App};
    use comptes::{Appareil, Comptes, MemoireEphemere, MemoireObjets, Plateforme, SmsTraces};
    use serde_json::json;
    use sqlx::PgPool;

    const ADMIN: &str = "01900000-0000-7000-8000-000000000401";
    const TIASSALE: &str = "01900000-0000-7000-8000-000000000002";
    const SECRET: &[u8] = b"secret-de-test-de-32-octets-mini";

    async fn preparer(pool: &PgPool) -> PgComptes {
        crate::charger_seeds(pool).await.unwrap();
        PgComptes::new(
            pool.clone(),
            Arc::new(MemoireEphemere::new()),
            Arc::new(SmsTraces::new()),
            Arc::new(MemoireObjets::new()),
            Arc::from(SECRET),
        )
    }

    async fn jeton(depot: &PgComptes, compte: Uuid) -> String {
        let zone = depot.compte(compte).await.unwrap().zone_id;
        let mut tx = depot.pool().begin().await.unwrap();
        let (_, jetons) = depot
            .creer_session(
                &mut tx,
                compte,
                zone,
                &Appareil {
                    nom: "Console".to_owned(),
                    plateforme: Plateforme::Android,
                },
                comptes::OrigineSession::VerificationOtp,
            )
            .await
            .unwrap();
        tx.commit().await.unwrap();
        jetons.acces
    }

    async fn creer_compte(depot: &PgComptes, numero: &str) -> Uuid {
        let mut tx = depot.pool().begin().await.unwrap();
        let compte = depot
            .creer_compte(&mut tx, numero, TIASSALE.parse().unwrap(), "2026-07")
            .await
            .unwrap();
        tx.commit().await.unwrap();
        compte.id
    }

    macro_rules! app {
        ($depot:expr) => {
            atest::init_service(
                App::new()
                    .app_data(web::Data::new($depot.clone()))
                    .app_data(crate::auth_http::config_json())
                    .app_data(config_path())
                    .service(decider_role)
                    .service(crate::auth_http::moi),
            )
            .await
        };
    }

    macro_rules! decider {
        ($app:expr, $acces:expr, $compte:expr, $role:expr, $corps:expr) => {{
            let requete = atest::TestRequest::post()
                .uri(&format!("/admin/comptes/{}/roles/{}", $compte, $role))
                .insert_header(("authorization", format!("Bearer {}", $acces)))
                .set_json($corps)
                .to_request();
            atest::call_service(&$app, requete).await
        }};
    }

    /// §5.1 — l'admin attribue le rôle vendeur à l'agrément : il naît VALIDE.
    #[sqlx::test(migrations = "../migrations")]
    async fn attribuer_vendeur_200(pool: PgPool) {
        let depot = preparer(&pool).await;
        let app = app!(depot);
        let acces = jeton(&depot, ADMIN.parse().unwrap()).await;
        let kofi = creer_compte(&depot, "+2250709080706").await;

        let resp = decider!(
            app,
            acces,
            kofi,
            "vendeur",
            json!({ "action": "attribuer" })
        );
        assert_eq!(resp.status(), StatusCode::OK);
        let corps: serde_json::Value = atest::read_body_json(resp).await;
        assert_eq!(corps["role"], "vendeur");
        assert_eq!(corps["statut"], "valide");
        assert!(corps["decide_le"].is_string());
        assert!(depot
            .roles_valides(kofi)
            .await
            .unwrap()
            .contains(&Role::Vendeur));
    }

    /// FR-012 — un compte NON admin ne décide rien, même sur lui-même. Sans
    /// cette garde, n'importe qui s'auto-promeut admin.
    #[sqlx::test(migrations = "../migrations")]
    async fn decider_403_sans_role_admin(pool: PgPool) {
        let depot = preparer(&pool).await;
        let app = app!(depot);
        let yao = creer_compte(&depot, "+2250709080706").await;
        let acces = jeton(&depot, yao).await;

        let resp = decider!(app, acces, yao, "admin", json!({ "action": "attribuer" }));
        assert_eq!(resp.status(), StatusCode::FORBIDDEN);
        let corps: serde_json::Value = atest::read_body_json(resp).await;
        assert_eq!(corps["message_cle"], "comptes.erreur.role_requis");
        assert!(!depot
            .roles_valides(yao)
            .await
            .unwrap()
            .contains(&Role::Admin));
    }

    #[sqlx::test(migrations = "../migrations")]
    async fn decider_401_sans_session(pool: PgPool) {
        let depot = preparer(&pool).await;
        let app = app!(depot);
        let yao = creer_compte(&depot, "+2250709080706").await;

        let requete = atest::TestRequest::post()
            .uri(&format!("/admin/comptes/{yao}/roles/vendeur"))
            .set_json(json!({ "action": "attribuer" }))
            .to_request();
        let resp = atest::call_service(&app, requete).await;
        assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
    }

    /// R9 — une transition hors machine → 409, pas un 500.
    #[sqlx::test(migrations = "../migrations")]
    async fn transition_invalide_409(pool: PgPool) {
        let depot = preparer(&pool).await;
        let app = app!(depot);
        let acces = jeton(&depot, ADMIN.parse().unwrap()).await;
        let yao = creer_compte(&depot, "+2250709080706").await;

        // Valider un coursier qui n'a jamais rien demandé.
        let resp = decider!(app, acces, yao, "coursier", json!({ "action": "valider" }));
        assert_eq!(resp.status(), StatusCode::CONFLICT);
        let corps: serde_json::Value = atest::read_body_json(resp).await;
        assert_eq!(corps["message_cle"], "comptes.erreur.transition_invalide");
    }

    /// FR-017 — refuser/suspendre sans motif → 422.
    #[sqlx::test(migrations = "../migrations")]
    async fn suspendre_sans_motif_422(pool: PgPool) {
        let depot = preparer(&pool).await;
        let app = app!(depot);
        let acces = jeton(&depot, ADMIN.parse().unwrap()).await;
        let kofi = creer_compte(&depot, "+2250709080706").await;
        decider!(
            app,
            acces,
            kofi,
            "vendeur",
            json!({ "action": "attribuer" })
        );

        let resp = decider!(
            app,
            acces,
            kofi,
            "vendeur",
            json!({ "action": "suspendre" })
        );
        assert_eq!(resp.status(), StatusCode::UNPROCESSABLE_ENTITY);
        assert!(
            depot
                .roles_valides(kofi)
                .await
                .unwrap()
                .contains(&Role::Vendeur),
            "le rôle n'a pas bougé"
        );
    }

    /// Compte inconnu → 404.
    #[sqlx::test(migrations = "../migrations")]
    async fn compte_inconnu_404(pool: PgPool) {
        let depot = preparer(&pool).await;
        let app = app!(depot);
        let acces = jeton(&depot, ADMIN.parse().unwrap()).await;

        let resp = decider!(
            app,
            acces,
            Uuid::now_v7(),
            "vendeur",
            json!({ "action": "attribuer" })
        );
        assert_eq!(resp.status(), StatusCode::NOT_FOUND);
    }

    /// Le rôle `client` n'est pas décidable : il n'existe pas comme ressource.
    #[sqlx::test(migrations = "../migrations")]
    async fn role_client_non_decidable_404(pool: PgPool) {
        let depot = preparer(&pool).await;
        let app = app!(depot);
        let acces = jeton(&depot, ADMIN.parse().unwrap()).await;
        let yao = creer_compte(&depot, "+2250709080706").await;

        let resp = decider!(
            app,
            acces,
            yao,
            "client",
            json!({ "action": "suspendre", "motif": "x" })
        );
        assert_eq!(resp.status(), StatusCode::NOT_FOUND);
    }

    /// US3 scénario 6 / R5 — LE test du cycle : une suspension vaut dès la
    /// requête SUIVANTE, sans attendre l'expiration des 15 min du jeton.
    #[sqlx::test(migrations = "../migrations")]
    async fn suspension_prend_effet_a_la_requete_suivante(pool: PgPool) {
        let depot = preparer(&pool).await;
        let app = app!(depot);
        let admin: Uuid = ADMIN.parse().unwrap();
        let acces_admin = jeton(&depot, admin).await;

        // Un seul compte, admin ET vendeur : son jeton restera valide.
        let acces = jeton(&depot, admin).await;
        decider!(
            app,
            acces_admin,
            admin,
            "vendeur",
            json!({ "action": "attribuer" })
        );

        let moi = |acces: String| {
            atest::TestRequest::get()
                .uri("/moi")
                .insert_header(("authorization", format!("Bearer {acces}")))
                .to_request()
        };
        let resp = atest::call_service(&app, moi(acces.clone())).await;
        let corps: serde_json::Value = atest::read_body_json(resp).await;
        let vendeur = corps["roles"]
            .as_array()
            .unwrap()
            .iter()
            .find(|r| r["role"] == "vendeur")
            .unwrap();
        assert_eq!(vendeur["statut"], "valide");

        // Suspension — le jeton d'accès n'est ni renouvelé ni expiré.
        let resp = decider!(
            app,
            acces_admin,
            admin,
            "vendeur",
            json!({ "action": "suspendre", "motif": "contrôle" })
        );
        assert_eq!(resp.status(), StatusCode::OK);

        let resp = atest::call_service(&app, moi(acces)).await;
        let corps: serde_json::Value = atest::read_body_json(resp).await;
        let vendeur = corps["roles"]
            .as_array()
            .unwrap()
            .iter()
            .find(|r| r["role"] == "vendeur")
            .unwrap();
        assert_eq!(
            vendeur["statut"], "suspendu",
            "le MÊME jeton voit déjà la suspension — les rôles sont relus en base"
        );
        assert!(!depot
            .roles_valides(admin)
            .await
            .unwrap()
            .contains(&Role::Vendeur));
    }

    /// SC-008 — la décision est journalisée : qui, quand, pourquoi.
    #[sqlx::test(migrations = "../migrations")]
    async fn decision_journalisee(pool: PgPool) {
        let depot = preparer(&pool).await;
        let app = app!(depot);
        let admin: Uuid = ADMIN.parse().unwrap();
        let acces = jeton(&depot, admin).await;
        let kofi = creer_compte(&depot, "+2250709080706").await;

        decider!(
            app,
            acces,
            kofi,
            "vendeur",
            json!({ "action": "attribuer" })
        );
        decider!(
            app,
            acces,
            kofi,
            "vendeur",
            json!({ "action": "suspendre", "motif": "boutique fermée" })
        );

        // La table porte la dernière décision…
        let (motif, decide_par): (Option<String>, Option<Uuid>) = sqlx::query_as(
            "SELECT motif, decide_par FROM comptes.attribution_role
             WHERE compte_id = $1 AND role = 'vendeur'",
        )
        .bind(kofi)
        .fetch_one(&pool)
        .await
        .unwrap();
        assert_eq!(motif.as_deref(), Some("boutique fermée"));
        assert_eq!(decide_par, Some(admin));

        // …et l'outbox porte l'HISTORIQUE, dans la même transaction.
        let payload: serde_json::Value = sqlx::query_scalar(
            "SELECT payload FROM outbox.evenement WHERE type_evenement = 'role.suspendu'",
        )
        .fetch_one(&pool)
        .await
        .unwrap();
        assert_eq!(payload["decide_par"], json!(admin));
        assert_eq!(payload["motif"], "boutique fermée");
        assert_eq!(payload["avant"], "valide");
        assert_eq!(payload["apres"], "suspendu");
    }
}
