use crate::merchants;
use crate::merchants::model::{CreateMerchantPayload, MerchantStatus};
use crate::orders;
use crate::orders::model::{OrderStatus, PaymentType};
use crate::products;
use crate::products::model::CreateProductPayload;
use crate::users;
use crate::users::model::{UserRole, UserStatus};
use common::error::AppError;
use common::types::Id;
use sqlx::PgPool;
use std::sync::atomic::{AtomicU64, Ordering};

static PHONE_COUNTER: AtomicU64 = AtomicU64::new(0);

/// Create a test user with role Client and unique phone.
pub async fn create_test_user(pool: &PgPool) -> Result<users::model::User, AppError> {
    create_test_user_with_role(pool, UserRole::Client).await
}

/// Create a test user with a specific role and unique phone.
/// Phone format: +22501000NNNNN (AtomicU64 counter avoids ON CONFLICT silent upsert).
pub async fn create_test_user_with_role(
    pool: &PgPool,
    role: UserRole,
) -> Result<users::model::User, AppError> {
    let n = PHONE_COUNTER.fetch_add(1, Ordering::Relaxed);
    let phone = format!("+22501000{:05}", n);
    let referral_code = crate::users::service::generate_referral_code();
    users::repository::create_user(pool, &phone, Some("Test User"), role, UserStatus::Active, &referral_code).await
}

/// Create a test merchant in Open status.
/// Internally creates an Agent user, then the merchant, then updates status from Closed to Open.
pub async fn create_test_merchant(
    pool: &PgPool,
    user_id: Id,
) -> Result<merchants::model::Merchant, AppError> {
    let agent = create_test_user_with_role(pool, UserRole::Agent).await?;
    let payload = CreateMerchantPayload {
        name: "Test Merchant".into(),
        address: Some("Bouaké centre".into()),
        category: Some("restaurant".into()),
        city_id: None,
    };
    let merchant =
        merchants::repository::create_merchant(pool, user_id, agent.id, &payload).await?;
    // Default DB status is Closed — must update to Open for order creation to succeed
    merchants::repository::update_status(pool, merchant.id, &MerchantStatus::Open).await
}

/// Create a test product with default values (price 100000 = 1000 FCFA, stock 50).
pub async fn create_test_product(
    pool: &PgPool,
    merchant_id: Id,
) -> Result<products::model::Product, AppError> {
    create_test_product_with_price(pool, merchant_id, "Test Product", 100000).await
}

/// Create a test product with custom name and price.
pub async fn create_test_product_with_price(
    pool: &PgPool,
    merchant_id: Id,
    name: &str,
    price: i64,
) -> Result<products::model::Product, AppError> {
    let payload = CreateProductPayload {
        name: name.into(),
        price,
        description: None,
        photo_url: None,
        stock: Some(50),
    };
    products::repository::create_product(pool, merchant_id, &payload).await
}

/// Create a test merchant linked to a specific agent with onboarding_step = 5 (finalized).
pub async fn create_test_merchant_for_agent(
    pool: &PgPool,
    agent_id: Id,
) -> Result<merchants::model::Merchant, AppError> {
    let user = create_test_user_with_role(pool, UserRole::Merchant).await?;
    let payload = CreateMerchantPayload {
        name: "Agent Test Merchant".into(),
        address: Some("Bouaké centre".into()),
        category: Some("restaurant".into()),
        city_id: None,
    };
    let merchant =
        merchants::repository::create_merchant(pool, user.id, agent_id, &payload).await?;
    // Finalize onboarding (step 5) and set status to Open
    merchants::repository::update_onboarding_step(pool, merchant.id, 5).await?;
    merchants::repository::update_status(pool, merchant.id, &MerchantStatus::Open).await
}

/// Create a verified KYC document for a user, verified by a specific agent.
pub async fn create_test_verified_kyc(
    pool: &PgPool,
    user_id: Id,
    agent_id: Id,
) -> Result<crate::kyc::model::KycDocument, AppError> {
    let doc = crate::kyc::repository::create_document(
        pool,
        user_id,
        crate::kyc::model::KycDocumentType::Cni,
        "/encrypted/test.bin",
    )
    .await?;

    // Verify the document
    crate::kyc::repository::verify_all_for_user(pool, user_id, agent_id).await?;

    // Re-fetch the updated document
    let docs = crate::kyc::repository::find_by_user(pool, user_id).await?;
    Ok(docs.into_iter().find(|d| d.id == doc.id).unwrap())
}

/// Create a test order with items and set status to Delivered.
/// `items` is a slice of (product_id, quantity, unit_price).
///
/// SHORTCUT: Jumps directly Pending → Delivered (skips Confirmed/Ready/Collected/InTransit).
/// Creates orders with driver_id=NULL. Acceptable for aggregate/stats tests only.
/// Non-transactional (each repository call is independent) — safe with #[sqlx::test] cleanup.
pub async fn create_test_delivered_order(
    pool: &PgPool,
    customer_id: Id,
    merchant_id: Id,
    items: &[(Id, i32, i64)],
) -> Result<orders::model::Order, AppError> {
    let subtotal: i64 = items
        .iter()
        .map(|(_, qty, price)| *qty as i64 * price)
        .sum();
    let delivery_fee = 0i64;
    let total = subtotal + delivery_fee;

    let order = orders::repository::create_order(
        pool,
        customer_id,
        merchant_id,
        &PaymentType::Cod,
        subtotal,
        delivery_fee,
        total,
        &None,
        None,
        None,
        None,
        &None,
    )
    .await?;

    for (product_id, quantity, unit_price) in items {
        orders::repository::create_order_item(pool, order.id, *product_id, *quantity, *unit_price)
            .await?;
    }

    orders::repository::update_status(pool, order.id, &OrderStatus::Delivered).await
}
