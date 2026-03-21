use actix_web::{web, HttpResponse};
use common::error::AppError;
use common::response::ApiResponse;
use domain::agents::service;
use domain::users::model::UserRole;
use sqlx::PgPool;

use crate::extractors::AuthenticatedUser;
use crate::middleware::require_role;

/// GET /api/v1/agents/me/stats
///
/// Agent gets their onboarding performance dashboard stats.
pub async fn get_my_stats(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Agent, UserRole::Admin])?;

    let stats = service::get_agent_performance_stats(&pool, auth.user_id).await?;

    let response = ApiResponse::new(serde_json::json!(stats));
    Ok(HttpResponse::Ok().json(response))
}

#[cfg(test)]
mod integration_tests {
    use actix_web::test;
    use domain::test_fixtures::*;
    use domain::users::model::UserRole;
    use sqlx::PgPool;

    /// Agent gets 200 with empty stats when no merchants onboarded.
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_agent_stats_200_empty(pool: PgPool) {
        let agent = create_test_user_with_role(&pool, UserRole::Agent)
            .await
            .unwrap();

        let token = crate::test_helpers::create_test_jwt(agent.id, "agent");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri("/api/v1/agents/me/stats")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 200);

        let body: serde_json::Value = test::read_body_json(resp).await;
        assert_eq!(body["data"]["merchants_onboarded"]["today"], 0);
        assert_eq!(body["data"]["merchants_onboarded"]["this_week"], 0);
        assert_eq!(body["data"]["merchants_onboarded"]["total"], 0);
        assert_eq!(body["data"]["kyc_validated"]["total"], 0);
        assert_eq!(body["data"]["merchants_with_first_order"]["total"], 0);
        assert!(body["data"]["recent_merchants"]
            .as_array()
            .unwrap()
            .is_empty());
    }

    /// Agent gets correct counts with onboarded merchants and KYC.
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_agent_stats_200_with_data(pool: PgPool) {
        let agent = create_test_user_with_role(&pool, UserRole::Agent)
            .await
            .unwrap();

        // Onboard 2 merchants via this agent
        let m1 = create_test_merchant_for_agent(&pool, agent.id)
            .await
            .unwrap();
        let _m2 = create_test_merchant_for_agent(&pool, agent.id)
            .await
            .unwrap();

        // Create a delivered order for merchant 1
        let customer = create_test_user(&pool).await.unwrap();
        let product = create_test_product(&pool, m1.id).await.unwrap();
        create_test_delivered_order(&pool, customer.id, m1.id, &[(product.id, 1, 100000)])
            .await
            .unwrap();

        // Create a verified KYC doc for a driver, verified by this agent
        let driver = create_test_user_with_role(&pool, UserRole::Driver)
            .await
            .unwrap();
        create_test_verified_kyc(&pool, driver.id, agent.id)
            .await
            .unwrap();

        let token = crate::test_helpers::create_test_jwt(agent.id, "agent");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri("/api/v1/agents/me/stats")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 200);

        let body: serde_json::Value = test::read_body_json(resp).await;
        // 2 merchants onboarded
        assert_eq!(body["data"]["merchants_onboarded"]["total"], 2);
        // 1 KYC validated
        assert_eq!(body["data"]["kyc_validated"]["total"], 1);
        // 1 merchant with first order
        assert_eq!(body["data"]["merchants_with_first_order"]["total"], 1);
        // Recent merchants list should have 2
        assert_eq!(
            body["data"]["recent_merchants"].as_array().unwrap().len(),
            2
        );
    }

    /// Non-agent role gets 403 Forbidden.
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_agent_stats_403_wrong_role(pool: PgPool) {
        let token = crate::test_helpers::create_test_jwt(uuid::Uuid::new_v4(), "client");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri("/api/v1/agents/me/stats")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 403);
    }

    /// No auth token returns 401.
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_agent_stats_401_no_token(pool: PgPool) {
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri("/api/v1/agents/me/stats")
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 401);
    }

    /// Admin role also has access to agent stats (AC5).
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_agent_stats_200_admin_role(pool: PgPool) {
        let admin = create_test_user_with_role(&pool, UserRole::Admin)
            .await
            .unwrap();

        let token = crate::test_helpers::create_test_jwt(admin.id, "admin");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri("/api/v1/agents/me/stats")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 200);
    }

    /// Agent only sees their own onboarded merchants (isolation).
    #[sqlx::test(migrations = "../../migrations")]
    async fn test_agent_stats_isolation(pool: PgPool) {
        let agent_a = create_test_user_with_role(&pool, UserRole::Agent)
            .await
            .unwrap();
        let agent_b = create_test_user_with_role(&pool, UserRole::Agent)
            .await
            .unwrap();

        // Agent A onboards 3 merchants
        create_test_merchant_for_agent(&pool, agent_a.id)
            .await
            .unwrap();
        create_test_merchant_for_agent(&pool, agent_a.id)
            .await
            .unwrap();
        create_test_merchant_for_agent(&pool, agent_a.id)
            .await
            .unwrap();

        // Agent B onboards 1 merchant
        create_test_merchant_for_agent(&pool, agent_b.id)
            .await
            .unwrap();

        // Agent B should see only 1
        let token_b = crate::test_helpers::create_test_jwt(agent_b.id, "agent");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri("/api/v1/agents/me/stats")
            .insert_header(("Authorization", format!("Bearer {}", token_b)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 200);

        let body: serde_json::Value = test::read_body_json(resp).await;
        assert_eq!(body["data"]["merchants_onboarded"]["total"], 1);
        assert_eq!(
            body["data"]["recent_merchants"].as_array().unwrap().len(),
            1
        );
    }
}
