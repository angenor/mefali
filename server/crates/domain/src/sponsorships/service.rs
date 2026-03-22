use common::error::AppError;
use common::types::Id;
use sqlx::PgPool;
use tracing::info;

use super::model::{
    MySponsorshipsResponse, SponsorContactInfo, SponsorInfo, SponsorshipStatus,
    DISPUTE_THRESHOLD_FOR_REVOCATION, MAX_ACTIVE_SPONSORSHIPS,
};
use super::repository;
use crate::disputes;
use crate::users::model::{UserRole, UserStatus};
use crate::users::repository as user_repository;

/// Notification title sent to sponsor when sponsorship rights are revoked.
pub const SPONSOR_RIGHTS_REVOKED_TITLE: &str =
    "Vos droits de parrainage ont ete suspendus";
/// FCM body for sponsorship rights revocation.
pub const SPONSOR_RIGHTS_REVOKED_BODY: &str =
    "Vos droits de parrainage ont ete suspendus suite a des litiges repetes de vos filleuls.";
/// SMS message for sponsorship rights revocation.
pub const SPONSOR_RIGHTS_REVOKED_SMS: &str =
    "mefali: Vos droits de parrainage sont suspendus. Litiges repetes de vos filleuls. Contactez le support.";

/// Validate that a sponsor (by phone) can sponsor a new driver.
/// Returns the sponsor's user ID if valid.
pub async fn validate_can_sponsor(
    pool: &PgPool,
    sponsor_phone: &str,
) -> Result<Id, AppError> {
    let sponsor = user_repository::find_by_phone(pool, sponsor_phone)
        .await?
        .ok_or_else(|| {
            AppError::BadRequestWithCode(
                "SPONSOR_NOT_FOUND",
                "Ce numero de parrain est introuvable".into(),
            )
        })?;

    if sponsor.role != UserRole::Driver {
        return Err(AppError::BadRequestWithCode(
            "SPONSOR_NOT_ACTIVE",
            "Ce numero n'est pas un livreur actif".into(),
        ));
    }

    if sponsor.status != UserStatus::Active {
        return Err(AppError::BadRequestWithCode(
            "SPONSOR_NOT_ACTIVE",
            "Ce numero n'est pas un livreur actif".into(),
        ));
    }

    if !sponsor.can_sponsor {
        return Err(AppError::BadRequestWithCode(
            "SPONSOR_RIGHTS_REVOKED",
            "Ce livreur n'a plus le droit de parrainer de nouveaux livreurs".into(),
        ));
    }

    let active_count = repository::count_active_by_sponsor(pool, sponsor.id).await?;
    if active_count >= MAX_ACTIVE_SPONSORSHIPS {
        return Err(AppError::BadRequestWithCode(
            "SPONSOR_MAX_REACHED",
            "Votre parrain a atteint le maximum de 3 filleuls".into(),
        ));
    }

    Ok(sponsor.id)
}

/// Get sponsorship overview for a driver (their filleuls).
pub async fn get_my_sponsorships(
    pool: &PgPool,
    driver_id: Id,
) -> Result<MySponsorshipsResponse, AppError> {
    let driver = user_repository::find_by_id(pool, driver_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Driver not found".into()))?;

    let sponsored_drivers = repository::find_by_sponsor(pool, driver_id).await?;
    let active_count = sponsored_drivers
        .iter()
        .filter(|d| d.status == SponsorshipStatus::Active)
        .count() as i64;
    let remaining_slots = MAX_ACTIVE_SPONSORSHIPS - active_count;

    Ok(MySponsorshipsResponse {
        max_sponsorships: MAX_ACTIVE_SPONSORSHIPS,
        active_count,
        remaining_slots,
        can_sponsor: driver.can_sponsor,
        sponsored_drivers,
    })
}

/// Get sponsor info for a sponsored driver.
pub async fn get_my_sponsor(
    pool: &PgPool,
    driver_id: Id,
) -> Result<Option<SponsorInfo>, AppError> {
    repository::find_sponsor_info(pool, driver_id).await
}

/// Find the active sponsor for a driver (for notification purposes).
/// Returns None if the driver has no active sponsorship.
pub async fn find_active_sponsor_for_driver(
    pool: &PgPool,
    driver_id: Id,
) -> Result<Option<SponsorContactInfo>, AppError> {
    repository::find_active_sponsor_with_contact(pool, driver_id).await
}

/// Check if a sponsor's drivers have accumulated enough disputes to revoke sponsorship rights.
/// Returns true if rights were revoked (threshold reached), false otherwise.
pub async fn check_and_revoke_sponsor_rights(
    pool: &PgPool,
    sponsor_id: Id,
) -> Result<bool, AppError> {
    // Check if sponsor still has sponsorship rights
    let sponsor = user_repository::find_by_id(pool, sponsor_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Sponsor not found".into()))?;

    if !sponsor.can_sponsor {
        // Already revoked — nothing to do
        return Ok(false);
    }

    let dispute_count =
        disputes::repository::count_disputes_for_sponsored_drivers(pool, sponsor_id).await?;

    if dispute_count < DISPUTE_THRESHOLD_FOR_REVOCATION {
        return Ok(false);
    }

    // Threshold reached — revoke sponsorship rights
    user_repository::update_can_sponsor(pool, sponsor_id, false).await?;

    info!(
        sponsor_id = %sponsor_id,
        dispute_count = dispute_count,
        "Sponsorship rights revoked: threshold reached"
    );

    Ok(true)
}

/// Create a sponsorship after validating the max 3 constraint.
pub async fn create_sponsorship(
    pool: &PgPool,
    sponsor_id: Id,
    sponsored_id: Id,
) -> Result<(), AppError> {
    let active_count = repository::count_active_by_sponsor(pool, sponsor_id).await?;
    if active_count >= MAX_ACTIVE_SPONSORSHIPS {
        return Err(AppError::BadRequestWithCode(
            "SPONSOR_MAX_REACHED",
            "Votre parrain a atteint le maximum de 3 filleuls".into(),
        ));
    }

    repository::create(pool, sponsor_id, sponsored_id).await?;
    info!(sponsor_id = %sponsor_id, sponsored_id = %sponsored_id, "Sponsorship created");
    Ok(())
}
