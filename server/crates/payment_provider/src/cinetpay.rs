use async_trait::async_trait;

use crate::provider::{
    PaymentError, PaymentProvider, PaymentRequest, PaymentResponse, PaymentStatus,
    WithdrawalRequest, WithdrawalResponse,
};

/// CinetPay payment adapter — MVP implementation.
/// Implements the PaymentProvider trait for CinetPay integration.
pub struct CinetPayAdapter {
    _api_key: String,
    _site_id: String,
}

impl CinetPayAdapter {
    pub fn new(api_key: String, site_id: String) -> Self {
        Self {
            _api_key: api_key,
            _site_id: site_id,
        }
    }
}

#[async_trait]
impl PaymentProvider for CinetPayAdapter {
    async fn initiate_payment(
        &self,
        _request: PaymentRequest,
    ) -> Result<PaymentResponse, PaymentError> {
        // CinetPay API integration will be implemented in Epic 4
        Err(PaymentError::InitiationFailed(
            "CinetPay integration not yet implemented".into(),
        ))
    }

    async fn verify_payment(&self, _transaction_id: &str) -> Result<PaymentStatus, PaymentError> {
        // CinetPay verification will be implemented in Epic 4
        Err(PaymentError::VerificationFailed(
            "CinetPay integration not yet implemented".into(),
        ))
    }

    async fn initiate_withdrawal(
        &self,
        _request: WithdrawalRequest,
    ) -> Result<WithdrawalResponse, PaymentError> {
        // CinetPay withdrawal will be implemented in Epic 6
        Err(PaymentError::WithdrawalFailed(
            "CinetPay integration not yet implemented".into(),
        ))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_cinetpay_adapter_creation() {
        let adapter = CinetPayAdapter::new("test_key".into(), "test_site".into());
        // Adapter should be creatable without external dependencies
        assert!(std::mem::size_of_val(&adapter) > 0);
    }
}
