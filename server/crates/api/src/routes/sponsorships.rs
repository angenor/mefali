use actix_web::{web, HttpResponse};
use common::error::AppError;
use common::response::ApiResponse;
use domain::sponsorships::service;
use domain::users::model::UserRole;
use sqlx::PgPool;

use crate::extractors::AuthenticatedUser;
use crate::middleware::require_role;

/// GET /api/v1/sponsorships/me
///
/// Returns the driver's sponsored drivers (filleuls) with count and remaining slots.
pub async fn get_my_sponsorships(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Driver])?;

    let response = service::get_my_sponsorships(&pool, auth.user_id).await?;
    Ok(HttpResponse::Ok().json(ApiResponse::new(response)))
}

/// GET /api/v1/sponsorships/me/sponsor
///
/// Returns the sponsor info for the authenticated driver.
pub async fn get_my_sponsor(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Driver])?;

    let sponsor = service::get_my_sponsor(&pool, auth.user_id).await?;
    Ok(HttpResponse::Ok().json(ApiResponse::new(sponsor)))
}

#[cfg(test)]
mod integration_tests {
    use actix_web::test;
    use domain::sponsorships::repository as sponsorship_repo;
    use domain::test_fixtures::*;
    use domain::users::model::UserRole;
    use sqlx::PgPool;

    /// Helper: create a driver and a sponsor with sponsorship link.
    async fn create_sponsor_and_driver(pool: &PgPool) -> (domain::users::model::User, domain::users::model::User) {
        let sponsor = create_test_user_with_role(pool, UserRole::Driver).await.unwrap();
        let driver = create_test_user_with_role(pool, UserRole::Driver).await.unwrap();
        sponsorship_repo::create(pool, sponsor.id, driver.id).await.unwrap();
        (sponsor, driver)
    }

    #[sqlx::test(migrations = "../../migrations")]
    async fn test_get_my_sponsorships_200_empty(pool: PgPool) {
        let driver = create_test_user_with_role(&pool, UserRole::Driver).await.unwrap();
        let token = crate::test_helpers::create_test_jwt(driver.id, "driver");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri("/api/v1/sponsorships/me")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 200);

        let body: serde_json::Value = test::read_body_json(resp).await;
        assert_eq!(body["data"]["max_sponsorships"], 3);
        assert_eq!(body["data"]["active_count"], 0);
        assert_eq!(body["data"]["remaining_slots"], 3);
        assert!(body["data"]["can_sponsor"].as_bool().unwrap());
        assert_eq!(body["data"]["sponsored_drivers"].as_array().unwrap().len(), 0);
    }

    #[sqlx::test(migrations = "../../migrations")]
    async fn test_get_my_sponsorships_200_with_data(pool: PgPool) {
        let (sponsor, _driver) = create_sponsor_and_driver(&pool).await;
        let token = crate::test_helpers::create_test_jwt(sponsor.id, "driver");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri("/api/v1/sponsorships/me")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 200);

        let body: serde_json::Value = test::read_body_json(resp).await;
        assert_eq!(body["data"]["active_count"], 1);
        assert_eq!(body["data"]["remaining_slots"], 2);
        assert!(body["data"]["can_sponsor"].as_bool().unwrap());
        assert_eq!(body["data"]["sponsored_drivers"].as_array().unwrap().len(), 1);
    }

    #[sqlx::test(migrations = "../../migrations")]
    async fn test_get_my_sponsorships_max_3_reached(pool: PgPool) {
        let sponsor = create_test_user_with_role(&pool, UserRole::Driver).await.unwrap();
        for _ in 0..3 {
            let driver = create_test_user_with_role(&pool, UserRole::Driver).await.unwrap();
            sponsorship_repo::create(&pool, sponsor.id, driver.id).await.unwrap();
        }

        let token = crate::test_helpers::create_test_jwt(sponsor.id, "driver");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri("/api/v1/sponsorships/me")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 200);

        let body: serde_json::Value = test::read_body_json(resp).await;
        assert_eq!(body["data"]["active_count"], 3);
        assert_eq!(body["data"]["remaining_slots"], 0);
        // can_sponsor reflects the user's rights flag (not revoked), remaining_slots=0 blocks new sponsorships
        assert!(body["data"]["can_sponsor"].as_bool().unwrap(), "can_sponsor should be true (rights intact, max reached is shown via remaining_slots=0)");
    }

    #[sqlx::test(migrations = "../../migrations")]
    async fn test_get_my_sponsor_200_with_sponsor(pool: PgPool) {
        let (sponsor, driver) = create_sponsor_and_driver(&pool).await;
        let token = crate::test_helpers::create_test_jwt(driver.id, "driver");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri("/api/v1/sponsorships/me/sponsor")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 200);

        let body: serde_json::Value = test::read_body_json(resp).await;
        assert_eq!(body["data"]["id"], sponsor.id.to_string());
        assert_eq!(body["data"]["sponsorship_status"], "active");
    }

    #[sqlx::test(migrations = "../../migrations")]
    async fn test_get_my_sponsor_200_no_sponsor(pool: PgPool) {
        let driver = create_test_user_with_role(&pool, UserRole::Driver).await.unwrap();
        let token = crate::test_helpers::create_test_jwt(driver.id, "driver");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri("/api/v1/sponsorships/me/sponsor")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 200);

        let body: serde_json::Value = test::read_body_json(resp).await;
        assert!(body["data"].is_null());
    }

    #[sqlx::test(migrations = "../../migrations")]
    async fn test_get_my_sponsorships_403_non_driver(pool: PgPool) {
        let client = create_test_user_with_role(&pool, UserRole::Client).await.unwrap();
        let token = crate::test_helpers::create_test_jwt(client.id, "client");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri("/api/v1/sponsorships/me")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 403);
    }

    #[sqlx::test(migrations = "../../migrations")]
    async fn test_get_my_sponsorships_401_no_token(pool: PgPool) {
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri("/api/v1/sponsorships/me")
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 401);
    }

    #[sqlx::test(migrations = "../../migrations")]
    async fn test_validate_can_sponsor_max_reached(pool: PgPool) {
        let sponsor = create_test_user_with_role(&pool, UserRole::Driver).await.unwrap();
        for _ in 0..3 {
            let driver = create_test_user_with_role(&pool, UserRole::Driver).await.unwrap();
            sponsorship_repo::create(&pool, sponsor.id, driver.id).await.unwrap();
        }

        let result = domain::sponsorships::service::validate_can_sponsor(&pool, &sponsor.phone).await;
        assert!(result.is_err());
        let err_msg = format!("{}", result.unwrap_err());
        assert!(err_msg.contains("maximum de 3 filleuls"));
    }

    #[sqlx::test(migrations = "../../migrations")]
    async fn test_validate_can_sponsor_not_driver(pool: PgPool) {
        let client = create_test_user_with_role(&pool, UserRole::Client).await.unwrap();

        let result = domain::sponsorships::service::validate_can_sponsor(&pool, &client.phone).await;
        assert!(result.is_err());
        let err_msg = format!("{}", result.unwrap_err());
        assert!(err_msg.contains("livreur actif"));
    }

    #[sqlx::test(migrations = "../../migrations")]
    async fn test_validate_can_sponsor_not_found(pool: PgPool) {
        let result = domain::sponsorships::service::validate_can_sponsor(&pool, "+2250700099999").await;
        assert!(result.is_err());
    }

    #[sqlx::test(migrations = "../../migrations")]
    async fn test_validate_can_sponsor_inactive(pool: PgPool) {
        let driver = create_test_user_with_role(&pool, UserRole::Driver).await.unwrap();
        // Suspend the driver
        domain::users::repository::update_status(&pool, driver.id, domain::users::model::UserStatus::Suspended).await.unwrap();

        let result = domain::sponsorships::service::validate_can_sponsor(&pool, &driver.phone).await;
        assert!(result.is_err());
        let err_msg = format!("{}", result.unwrap_err());
        assert!(err_msg.contains("livreur actif"));
    }

    // === Story 9.2: Sponsor-First Contact Tests ===

    #[sqlx::test(migrations = "../../migrations")]
    async fn test_find_active_sponsor_for_driver_returns_some(pool: PgPool) {
        let (sponsor, driver) = create_sponsor_and_driver(&pool).await;
        let result = domain::sponsorships::service::find_active_sponsor_for_driver(&pool, driver.id).await.unwrap();
        assert!(result.is_some());
        let contact = result.unwrap();
        assert_eq!(contact.id, sponsor.id);
        assert_eq!(contact.phone, sponsor.phone);
    }

    #[sqlx::test(migrations = "../../migrations")]
    async fn test_find_active_sponsor_for_driver_returns_none_no_sponsor(pool: PgPool) {
        let driver = create_test_user_with_role(&pool, UserRole::Driver).await.unwrap();
        let result = domain::sponsorships::service::find_active_sponsor_for_driver(&pool, driver.id).await.unwrap();
        assert!(result.is_none());
    }

    #[sqlx::test(migrations = "../../migrations")]
    async fn test_find_active_sponsor_for_driver_returns_none_terminated(pool: PgPool) {
        let sponsor = create_test_user_with_role(&pool, UserRole::Driver).await.unwrap();
        let driver = create_test_user_with_role(&pool, UserRole::Driver).await.unwrap();
        let s = sponsorship_repo::create(&pool, sponsor.id, driver.id).await.unwrap();
        sponsorship_repo::update_status(&pool, s.id, domain::sponsorships::model::SponsorshipStatus::Terminated).await.unwrap();

        let result = domain::sponsorships::service::find_active_sponsor_for_driver(&pool, driver.id).await.unwrap();
        assert!(result.is_none());
    }

    #[sqlx::test(migrations = "../../migrations")]
    async fn test_dispute_event_sponsor_contacted_in_timeline(pool: PgPool) {
        // Setup: create a delivered order with sponsored driver
        let customer = create_test_user_with_role(&pool, UserRole::Client).await.unwrap();
        let (sponsor, driver) = create_sponsor_and_driver(&pool).await;
        let merchant_user = create_test_user_with_role(&pool, UserRole::Merchant).await.unwrap();
        let merchant = create_test_merchant(&pool, merchant_user.id).await.unwrap();
        let product = create_test_product(&pool, merchant.id).await.unwrap();
        let order = create_test_delivered_order(&pool, customer.id, merchant.id, &[(product.id, 1, 1000)]).await.unwrap();
        // Assign driver to order
        domain::orders::repository::set_driver(&pool, order.id, driver.id).await.unwrap();

        // Create dispute
        let dispute = domain::disputes::repository::create_dispute(
            &pool,
            order.id,
            customer.id,
            &domain::disputes::model::DisputeType::Quality,
            Some("Mauvaise qualite"),
        ).await.unwrap();

        // Simulate what notify_sponsor_if_applicable does: insert sponsor_contacted event
        let label = format!("Parrain contacte : {} ({})", sponsor.name.as_deref().unwrap_or("Parrain"), sponsor.phone);
        domain::disputes::repository::insert_dispute_event(
            &pool,
            dispute.id,
            "sponsor_contacted",
            &label,
            Some(serde_json::json!({"sponsor_id": sponsor.id.to_string(), "notification_type": "push"})),
        ).await.unwrap();

        // Verify timeline includes the sponsor_contacted event
        let timeline = domain::disputes::repository::get_order_timeline(&pool, order.id).await.unwrap();
        let sponsor_event = timeline.iter().find(|e| e.label.contains("Parrain contacte"));
        assert!(sponsor_event.is_some(), "Timeline should contain 'Parrain contacte' event");
        assert!(sponsor_event.unwrap().label.contains(&sponsor.phone));
    }

    #[sqlx::test(migrations = "../../migrations")]
    async fn test_dispute_no_sponsor_event_when_no_sponsor(pool: PgPool) {
        // Setup: delivered order with unsponsored driver
        let customer = create_test_user_with_role(&pool, UserRole::Client).await.unwrap();
        let driver = create_test_user_with_role(&pool, UserRole::Driver).await.unwrap();
        let merchant_user = create_test_user_with_role(&pool, UserRole::Merchant).await.unwrap();
        let merchant = create_test_merchant(&pool, merchant_user.id).await.unwrap();
        let product = create_test_product(&pool, merchant.id).await.unwrap();
        let order = create_test_delivered_order(&pool, customer.id, merchant.id, &[(product.id, 1, 1000)]).await.unwrap();
        domain::orders::repository::set_driver(&pool, order.id, driver.id).await.unwrap();

        // Create dispute
        domain::disputes::repository::create_dispute(
            &pool, order.id, customer.id,
            &domain::disputes::model::DisputeType::Incomplete,
            None,
        ).await.unwrap();

        // No sponsor → no sponsor event should exist
        let result = domain::sponsorships::service::find_active_sponsor_for_driver(&pool, driver.id).await.unwrap();
        assert!(result.is_none());

        // Timeline should NOT contain sponsor event
        let timeline = domain::disputes::repository::get_order_timeline(&pool, order.id).await.unwrap();
        let sponsor_event = timeline.iter().find(|e| e.label.contains("Parrain contacte"));
        assert!(sponsor_event.is_none(), "Timeline should NOT contain sponsor event for unsponsored driver");
    }

    #[sqlx::test(migrations = "../../migrations")]
    async fn test_admin_dispute_detail_includes_sponsor_event(pool: PgPool) {
        // Setup: sponsored driver with dispute + sponsor_contacted event
        let admin = create_test_user_with_role(&pool, UserRole::Admin).await.unwrap();
        let customer = create_test_user_with_role(&pool, UserRole::Client).await.unwrap();
        let (sponsor, driver) = create_sponsor_and_driver(&pool).await;
        let merchant_user = create_test_user_with_role(&pool, UserRole::Merchant).await.unwrap();
        let merchant = create_test_merchant(&pool, merchant_user.id).await.unwrap();
        let product = create_test_product(&pool, merchant.id).await.unwrap();
        let order = create_test_delivered_order(&pool, customer.id, merchant.id, &[(product.id, 1, 2000)]).await.unwrap();
        domain::orders::repository::set_driver(&pool, order.id, driver.id).await.unwrap();

        let dispute = domain::disputes::repository::create_dispute(
            &pool, order.id, customer.id,
            &domain::disputes::model::DisputeType::WrongOrder,
            Some("Mauvais plat"),
        ).await.unwrap();

        // Insert sponsor_contacted event
        domain::disputes::repository::insert_dispute_event(
            &pool, dispute.id, "sponsor_contacted",
            &format!("Parrain contacte : {} ({})", sponsor.name.as_deref().unwrap_or("Parrain"), sponsor.phone),
            Some(serde_json::json!({"sponsor_id": sponsor.id.to_string()})),
        ).await.unwrap();

        // Admin GET dispute detail → timeline should include sponsor event
        let token = crate::test_helpers::create_test_jwt(admin.id, "admin");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;
        let req = test::TestRequest::get()
            .uri(&format!("/api/v1/admin/disputes/{}", dispute.id))
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();
        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 200);

        let body: serde_json::Value = test::read_body_json(resp).await;
        let timeline = body["data"]["timeline"].as_array().unwrap();
        let sponsor_event = timeline.iter().find(|e| {
            e["label"].as_str().map_or(false, |l| l.contains("Parrain contacte"))
        });
        assert!(sponsor_event.is_some(), "Admin dispute detail timeline should include sponsor_contacted event");
    }

    // === Story 9.3: Progressive Penalties Tests ===

    /// Helper: create a full dispute setup for a sponsored driver.
    /// Returns (sponsor, driver, dispute).
    async fn create_dispute_for_sponsored_driver(
        pool: &PgPool,
        sponsor_id: common::types::Id,
    ) -> (domain::users::model::User, domain::disputes::model::Dispute) {
        let driver = create_test_user_with_role(pool, UserRole::Driver).await.unwrap();
        sponsorship_repo::create(pool, sponsor_id, driver.id).await.unwrap();
        let customer = create_test_user_with_role(pool, UserRole::Client).await.unwrap();
        let merchant_user = create_test_user_with_role(pool, UserRole::Merchant).await.unwrap();
        let merchant = create_test_merchant(pool, merchant_user.id).await.unwrap();
        let product = create_test_product(pool, merchant.id).await.unwrap();
        let order = create_test_delivered_order(pool, customer.id, merchant.id, &[(product.id, 1, 1000)]).await.unwrap();
        domain::orders::repository::set_driver(pool, order.id, driver.id).await.unwrap();
        let dispute = domain::disputes::repository::create_dispute(
            pool, order.id, customer.id,
            &domain::disputes::model::DisputeType::Quality,
            Some("Test dispute"),
        ).await.unwrap();
        (driver, dispute)
    }

    #[sqlx::test(migrations = "../../migrations")]
    async fn test_sponsor_2_disputes_rights_maintained(pool: PgPool) {
        let sponsor = create_test_user_with_role(&pool, UserRole::Driver).await.unwrap();

        // Create 2 disputes for sponsored drivers
        create_dispute_for_sponsored_driver(&pool, sponsor.id).await;
        create_dispute_for_sponsored_driver(&pool, sponsor.id).await;

        // Check: threshold NOT reached, rights maintained
        let revoked = domain::sponsorships::service::check_and_revoke_sponsor_rights(&pool, sponsor.id).await.unwrap();
        assert!(!revoked, "Rights should NOT be revoked with only 2 disputes");

        // Verify can still sponsor
        let result = domain::sponsorships::service::validate_can_sponsor(&pool, &sponsor.phone).await;
        assert!(result.is_ok(), "Sponsor with 2 disputes should still be able to sponsor");
    }

    #[sqlx::test(migrations = "../../migrations")]
    async fn test_sponsor_3_disputes_rights_revoked(pool: PgPool) {
        let sponsor = create_test_user_with_role(&pool, UserRole::Driver).await.unwrap();

        // Create 3 disputes for sponsored drivers
        create_dispute_for_sponsored_driver(&pool, sponsor.id).await;
        create_dispute_for_sponsored_driver(&pool, sponsor.id).await;
        create_dispute_for_sponsored_driver(&pool, sponsor.id).await;

        // Check: threshold reached, rights revoked
        let revoked = domain::sponsorships::service::check_and_revoke_sponsor_rights(&pool, sponsor.id).await.unwrap();
        assert!(revoked, "Rights should be revoked with 3 disputes");

        // Verify sponsor user has can_sponsor = false
        let user = domain::users::repository::find_by_id(&pool, sponsor.id).await.unwrap().unwrap();
        assert!(!user.can_sponsor, "can_sponsor should be false after revocation");
    }

    #[sqlx::test(migrations = "../../migrations")]
    async fn test_revoked_sponsor_cannot_sponsor_new_driver(pool: PgPool) {
        let sponsor = create_test_user_with_role(&pool, UserRole::Driver).await.unwrap();

        // Revoke rights directly
        domain::users::repository::update_can_sponsor(&pool, sponsor.id, false).await.unwrap();

        // Try to sponsor — should fail with SPONSOR_RIGHTS_REVOKED
        let result = domain::sponsorships::service::validate_can_sponsor(&pool, &sponsor.phone).await;
        assert!(result.is_err());
        let err_msg = format!("{}", result.unwrap_err());
        assert!(err_msg.contains("plus le droit de parrainer"), "Error should mention revoked rights, got: {}", err_msg);
    }

    #[sqlx::test(migrations = "../../migrations")]
    async fn test_existing_sponsorships_stay_active_after_revocation(pool: PgPool) {
        let sponsor = create_test_user_with_role(&pool, UserRole::Driver).await.unwrap();

        // Create 3 sponsored drivers with disputes
        let (driver1, _) = create_dispute_for_sponsored_driver(&pool, sponsor.id).await;
        let (driver2, _) = create_dispute_for_sponsored_driver(&pool, sponsor.id).await;
        let (driver3, _) = create_dispute_for_sponsored_driver(&pool, sponsor.id).await;

        // Revoke rights
        let revoked = domain::sponsorships::service::check_and_revoke_sponsor_rights(&pool, sponsor.id).await.unwrap();
        assert!(revoked);

        // Verify existing sponsorships are still active
        let sponsored = sponsorship_repo::find_by_sponsor(&pool, sponsor.id).await.unwrap();
        assert_eq!(sponsored.len(), 3, "Should still have 3 sponsored drivers");
        for d in &sponsored {
            assert_eq!(d.status, domain::sponsorships::model::SponsorshipStatus::Active,
                "All existing sponsorships should remain active, but {} is {:?}", d.phone, d.status);
        }

        // Verify drivers are still linked to sponsor
        for driver_id in [driver1.id, driver2.id, driver3.id] {
            let sponsor_info = domain::sponsorships::service::find_active_sponsor_for_driver(&pool, driver_id).await.unwrap();
            assert!(sponsor_info.is_some(), "Driver should still have an active sponsor after revocation");
        }
    }

    #[sqlx::test(migrations = "../../migrations")]
    async fn test_dispute_event_sponsor_rights_revoked_in_timeline(pool: PgPool) {
        let sponsor = create_test_user_with_role(&pool, UserRole::Driver).await.unwrap();

        // Create 3 disputes
        create_dispute_for_sponsored_driver(&pool, sponsor.id).await;
        create_dispute_for_sponsored_driver(&pool, sponsor.id).await;
        let (_driver3, dispute3) = create_dispute_for_sponsored_driver(&pool, sponsor.id).await;

        // Revoke rights
        domain::sponsorships::service::check_and_revoke_sponsor_rights(&pool, sponsor.id).await.unwrap();

        // Insert the event manually (as check_sponsor_penalties would in the route)
        let label = format!("Droits de parrainage revoques pour {} ({})", sponsor.name.as_deref().unwrap_or("Parrain"), sponsor.phone);
        domain::disputes::repository::insert_dispute_event(
            &pool, dispute3.id, "sponsor_rights_revoked", &label,
            Some(serde_json::json!({"sponsor_id": sponsor.id.to_string(), "reason": "dispute_threshold_reached"})),
        ).await.unwrap();

        // Verify timeline includes the revocation event
        let order_id = dispute3.order_id;
        let timeline = domain::disputes::repository::get_order_timeline(&pool, order_id).await.unwrap();
        let revoked_event = timeline.iter().find(|e| e.label.contains("Droits de parrainage revoques"));
        assert!(revoked_event.is_some(), "Timeline should contain revocation event");
    }

    #[sqlx::test(migrations = "../../migrations")]
    async fn test_audit_log_created_for_revocation(pool: PgPool) {
        let sponsor = create_test_user_with_role(&pool, UserRole::Driver).await.unwrap();

        // Production uses sponsor_id as both admin_id and target_user_id
        // (system action — UUID nil violates FK, so sponsor acts as own actor)
        let log = domain::users::repository::insert_audit_log(
            &pool,
            sponsor.id,
            sponsor.id,
            "revoke_sponsorship_rights",
            None,
            None,
            Some("Seuil de litiges filleuls atteint (3+)"),
        ).await.unwrap();

        assert_eq!(log.admin_id, sponsor.id, "admin_id should be sponsor_id (system action)");
        assert_eq!(log.target_user_id, sponsor.id);
        assert_eq!(log.action, "revoke_sponsorship_rights");
        assert_eq!(log.reason.as_deref(), Some("Seuil de litiges filleuls atteint (3+)"));
    }

    #[sqlx::test(migrations = "../../migrations")]
    async fn test_get_my_sponsorships_shows_revoked_status(pool: PgPool) {
        let sponsor = create_test_user_with_role(&pool, UserRole::Driver).await.unwrap();
        let driver = create_test_user_with_role(&pool, UserRole::Driver).await.unwrap();
        sponsorship_repo::create(&pool, sponsor.id, driver.id).await.unwrap();

        // Revoke rights
        domain::users::repository::update_can_sponsor(&pool, sponsor.id, false).await.unwrap();

        // GET /sponsorships/me should show can_sponsor=false
        let token = crate::test_helpers::create_test_jwt(sponsor.id, "driver");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;
        let req = test::TestRequest::get()
            .uri("/api/v1/sponsorships/me")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();
        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 200);

        let body: serde_json::Value = test::read_body_json(resp).await;
        assert!(!body["data"]["can_sponsor"].as_bool().unwrap(), "can_sponsor should be false when rights revoked");
        assert_eq!(body["data"]["active_count"], 1, "Active sponsorship count should still be 1");
        assert_eq!(body["data"]["remaining_slots"], 2, "Remaining slots should still show 2 (existing sponsorships unaffected)");
    }

    #[sqlx::test(migrations = "../../migrations")]
    async fn test_decrement_on_terminated_sponsorship(pool: PgPool) {
        let sponsor = create_test_user_with_role(&pool, UserRole::Driver).await.unwrap();
        let driver1 = create_test_user_with_role(&pool, UserRole::Driver).await.unwrap();
        let driver2 = create_test_user_with_role(&pool, UserRole::Driver).await.unwrap();
        let driver3 = create_test_user_with_role(&pool, UserRole::Driver).await.unwrap();

        let s1 = sponsorship_repo::create(&pool, sponsor.id, driver1.id).await.unwrap();
        sponsorship_repo::create(&pool, sponsor.id, driver2.id).await.unwrap();
        sponsorship_repo::create(&pool, sponsor.id, driver3.id).await.unwrap();

        // Max 3 reached
        let count = sponsorship_repo::count_active_by_sponsor(&pool, sponsor.id).await.unwrap();
        assert_eq!(count, 3);

        // Terminate one sponsorship
        sponsorship_repo::update_status(&pool, s1.id, domain::sponsorships::model::SponsorshipStatus::Terminated).await.unwrap();

        // Now only 2 active
        let count = sponsorship_repo::count_active_by_sponsor(&pool, sponsor.id).await.unwrap();
        assert_eq!(count, 2);

        // Can sponsor again
        let result = domain::sponsorships::service::validate_can_sponsor(&pool, &sponsor.phone).await;
        assert!(result.is_ok());
    }
}
