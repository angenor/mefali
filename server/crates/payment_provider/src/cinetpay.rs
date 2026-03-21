use std::time::Duration;

use async_trait::async_trait;
use serde::{Deserialize, Serialize};
use tracing::{error, info, warn};

use crate::provider::{
    PaymentError, PaymentProvider, PaymentRequest, PaymentResponse, PaymentStatus,
    WithdrawalRequest, WithdrawalResponse,
};

const CINETPAY_TIMEOUT: Duration = Duration::from_secs(10);

/// CinetPay payment adapter.
/// Implements the PaymentProvider trait for CinetPay integration.
pub struct CinetPayAdapter {
    api_key: String,
    site_id: String,
    base_url: String,
    notify_url: String,
    return_url: String,
    client: reqwest::Client,
}

impl CinetPayAdapter {
    pub fn new(
        api_key: String,
        site_id: String,
        base_url: String,
        notify_url: String,
        return_url: String,
    ) -> Self {
        let client = reqwest::Client::builder()
            .timeout(CINETPAY_TIMEOUT)
            .build()
            .expect("Failed to build HTTP client");

        Self {
            api_key,
            site_id,
            base_url,
            notify_url,
            return_url,
            client,
        }
    }
}

/// CinetPay initiation request body.
#[derive(Debug, Serialize)]
struct CinetPayInitRequest {
    apikey: String,
    site_id: String,
    transaction_id: String,
    amount: i64,
    currency: String,
    description: String,
    return_url: String,
    notify_url: String,
    customer_phone_number: String,
    channels: String,
}

/// CinetPay initiation response.
#[derive(Debug, Deserialize)]
struct CinetPayInitResponse {
    code: String,
    message: String,
    data: Option<CinetPayInitData>,
}

#[derive(Debug, Deserialize)]
struct CinetPayInitData {
    payment_url: Option<String>,
}

/// CinetPay verification request body.
#[derive(Debug, Serialize)]
struct CinetPayCheckRequest {
    apikey: String,
    site_id: String,
    transaction_id: String,
}

/// CinetPay verification response.
#[derive(Debug, Deserialize)]
struct CinetPayCheckResponse {
    #[allow(dead_code)]
    code: String,
    data: Option<CinetPayCheckData>,
}

#[derive(Debug, Deserialize)]
struct CinetPayCheckData {
    status: Option<String>,
}

#[async_trait]
impl PaymentProvider for CinetPayAdapter {
    async fn initiate_payment(
        &self,
        request: PaymentRequest,
    ) -> Result<PaymentResponse, PaymentError> {
        let transaction_id = request.order_id.to_string();

        let body = CinetPayInitRequest {
            apikey: self.api_key.clone(),
            site_id: self.site_id.clone(),
            transaction_id: transaction_id.clone(),
            amount: request.amount / 100, // centimes -> FCFA
            currency: request.currency,
            description: request.description,
            return_url: self.return_url.clone(),
            notify_url: self.notify_url.clone(),
            customer_phone_number: request.customer_phone,
            channels: "MOBILE_MONEY".into(),
        };

        let url = format!("{}/payment", self.base_url);

        let response = self
            .client
            .post(&url)
            .json(&body)
            .send()
            .await
            .map_err(|e| {
                if e.is_timeout() {
                    error!(error = %e, "CinetPay timeout during payment initiation");
                    PaymentError::NetworkError("CinetPay timeout (>10s)".into())
                } else {
                    error!(error = %e, "CinetPay network error during payment initiation");
                    PaymentError::NetworkError(format!("CinetPay unreachable: {e}"))
                }
            })?;

        let cinetpay_resp: CinetPayInitResponse = response.json().await.map_err(|e| {
            error!(error = %e, "Failed to parse CinetPay initiation response");
            PaymentError::InitiationFailed(format!("Invalid CinetPay response: {e}"))
        })?;

        if cinetpay_resp.code != "201" {
            error!(
                code = %cinetpay_resp.code,
                message = %cinetpay_resp.message,
                "CinetPay payment initiation failed"
            );
            return Err(PaymentError::InitiationFailed(format!(
                "CinetPay error {}: {}",
                cinetpay_resp.code, cinetpay_resp.message
            )));
        }

        let payment_url = cinetpay_resp.data.and_then(|d| d.payment_url);

        info!(
            transaction_id = %transaction_id,
            has_payment_url = payment_url.is_some(),
            "CinetPay payment initiated"
        );

        Ok(PaymentResponse {
            transaction_id,
            payment_url,
            status: PaymentStatus::Pending,
        })
    }

    async fn verify_payment(&self, transaction_id: &str) -> Result<PaymentStatus, PaymentError> {
        let body = CinetPayCheckRequest {
            apikey: self.api_key.clone(),
            site_id: self.site_id.clone(),
            transaction_id: transaction_id.to_string(),
        };

        let url = format!("{}/payment/check", self.base_url);

        let response = self
            .client
            .post(&url)
            .json(&body)
            .send()
            .await
            .map_err(|e| {
                if e.is_timeout() {
                    error!(error = %e, "CinetPay timeout during payment verification");
                    PaymentError::NetworkError("CinetPay timeout (>10s)".into())
                } else {
                    error!(error = %e, "CinetPay network error during verification");
                    PaymentError::NetworkError(format!("CinetPay unreachable: {e}"))
                }
            })?;

        let cinetpay_resp: CinetPayCheckResponse = response.json().await.map_err(|e| {
            error!(error = %e, "Failed to parse CinetPay check response");
            PaymentError::VerificationFailed(format!("Invalid CinetPay response: {e}"))
        })?;

        let status_str = cinetpay_resp
            .data
            .and_then(|d| d.status)
            .unwrap_or_default();

        let status = match status_str.as_str() {
            "ACCEPTED" => PaymentStatus::Completed,
            "REFUSED" | "ERROR" | "EXPIRED" => PaymentStatus::Failed,
            "CANCELLED" => PaymentStatus::Cancelled,
            "" => PaymentStatus::Pending,
            other => {
                warn!(
                    transaction_id = %transaction_id,
                    unknown_status = %other,
                    "Unknown CinetPay status — treating as Pending"
                );
                PaymentStatus::Pending
            }
        };

        info!(
            transaction_id = %transaction_id,
            cinetpay_status = %status_str,
            mapped_status = ?status,
            "CinetPay payment verified"
        );

        Ok(status)
    }

    async fn initiate_withdrawal(
        &self,
        request: WithdrawalRequest,
    ) -> Result<WithdrawalResponse, PaymentError> {
        let transaction_id = uuid::Uuid::new_v4().to_string();
        let amount_fcfa = request.amount / 100; // centimes -> FCFA

        let body = serde_json::json!({
            "apikey": self.api_key,
            "site_id": self.site_id,
            "transaction_id": transaction_id,
            "amount": amount_fcfa,
            "currency": request.currency,
            "receiver": request.destination_phone,
            "payment_method": "MOBILE_MONEY",
            "notify_url": self.notify_url,
        });

        let url = format!("{}/transfer", self.base_url);

        let response = self
            .client
            .post(&url)
            .json(&body)
            .send()
            .await
            .map_err(|e| {
                if e.is_timeout() {
                    error!(error = %e, "CinetPay timeout during withdrawal");
                    PaymentError::NetworkError("CinetPay timeout (>10s)".into())
                } else {
                    error!(error = %e, "CinetPay network error during withdrawal");
                    PaymentError::NetworkError(format!("CinetPay unreachable: {e}"))
                }
            })?;

        let status_code = response.status();
        let resp_text = response.text().await.unwrap_or_default();

        if !status_code.is_success() {
            error!(
                status = %status_code,
                body = %resp_text,
                "CinetPay withdrawal failed"
            );
            return Err(PaymentError::WithdrawalFailed(format!(
                "CinetPay transfer error {status_code}: {resp_text}"
            )));
        }

        info!(
            transaction_id = %transaction_id,
            amount_fcfa = amount_fcfa,
            destination = %request.destination_phone,
            "CinetPay withdrawal initiated"
        );

        Ok(WithdrawalResponse {
            transaction_id,
            status: PaymentStatus::Pending,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_cinetpay_adapter_creation() {
        let adapter = CinetPayAdapter::new(
            "test_key".into(),
            "test_site".into(),
            "https://api-checkout.cinetpay.com/v2".into(),
            "https://api.mefali.ci/api/v1/payments/webhook".into(),
            "https://api.mefali.ci/payment/return".into(),
        );
        assert_eq!(adapter.api_key, "test_key");
        assert_eq!(adapter.site_id, "test_site");
    }

    #[test]
    fn test_cinetpay_status_mapping() {
        assert_eq!(map_cinetpay_status("ACCEPTED"), PaymentStatus::Completed);
        assert_eq!(map_cinetpay_status("REFUSED"), PaymentStatus::Failed);
        assert_eq!(map_cinetpay_status("ERROR"), PaymentStatus::Failed);
        assert_eq!(map_cinetpay_status("EXPIRED"), PaymentStatus::Failed);
        assert_eq!(map_cinetpay_status("CANCELLED"), PaymentStatus::Cancelled);
        assert_eq!(map_cinetpay_status(""), PaymentStatus::Pending);
        assert_eq!(map_cinetpay_status("UNKNOWN"), PaymentStatus::Pending);
    }

    fn map_cinetpay_status(s: &str) -> PaymentStatus {
        match s {
            "ACCEPTED" => PaymentStatus::Completed,
            "REFUSED" | "ERROR" | "EXPIRED" => PaymentStatus::Failed,
            "CANCELLED" => PaymentStatus::Cancelled,
            _ => PaymentStatus::Pending,
        }
    }
}
