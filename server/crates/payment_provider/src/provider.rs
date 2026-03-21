use async_trait::async_trait;
use common::types::Id;
use serde::{Deserialize, Serialize};
use thiserror::Error;

#[derive(Debug, Error)]
pub enum PaymentError {
    #[error("Payment initiation failed: {0}")]
    InitiationFailed(String),

    #[error("Payment verification failed: {0}")]
    VerificationFailed(String),

    #[error("Withdrawal failed: {0}")]
    WithdrawalFailed(String),

    #[error("Network error: {0}")]
    NetworkError(String),
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PaymentRequest {
    pub order_id: Id,
    pub amount: i64,
    pub currency: String,
    pub customer_phone: String,
    pub description: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PaymentResponse {
    pub transaction_id: String,
    pub payment_url: Option<String>,
    pub status: PaymentStatus,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum PaymentStatus {
    Pending,
    Completed,
    Failed,
    Cancelled,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WithdrawalRequest {
    pub user_id: Id,
    pub amount: i64,
    pub currency: String,
    pub destination_phone: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WithdrawalResponse {
    pub transaction_id: String,
    pub status: PaymentStatus,
}

/// Abstract payment provider trait.
/// CinetPay is behind this abstraction — easily swappable for another aggregator.
#[async_trait]
pub trait PaymentProvider: Send + Sync {
    async fn initiate_payment(
        &self,
        request: PaymentRequest,
    ) -> Result<PaymentResponse, PaymentError>;
    async fn verify_payment(&self, transaction_id: &str) -> Result<PaymentStatus, PaymentError>;
    async fn initiate_withdrawal(
        &self,
        request: WithdrawalRequest,
    ) -> Result<WithdrawalResponse, PaymentError>;

    /// Verify multiple payments in batch. Default implementation calls verify_payment sequentially.
    async fn verify_payment_batch(
        &self,
        transaction_ids: &[String],
    ) -> Result<Vec<(String, PaymentStatus)>, PaymentError> {
        let mut results = Vec::with_capacity(transaction_ids.len());
        for txn_id in transaction_ids {
            let status = self.verify_payment(txn_id).await?;
            results.push((txn_id.clone(), status));
        }
        Ok(results)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_payment_status_equality() {
        assert_eq!(PaymentStatus::Pending, PaymentStatus::Pending);
        assert_ne!(PaymentStatus::Pending, PaymentStatus::Completed);
    }

    #[test]
    fn test_payment_request_serialization() {
        let request = PaymentRequest {
            order_id: Id::new_v4(),
            amount: 5000,
            currency: "XOF".into(),
            customer_phone: "+2250700000000".into(),
            description: "Order payment".into(),
        };
        let json = serde_json::to_value(&request).unwrap();
        assert_eq!(json["amount"], 5000);
        assert_eq!(json["currency"], "XOF");
    }
}
