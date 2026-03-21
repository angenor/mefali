use common::error::AppError;
use payment_provider::provider::{PaymentProvider, PaymentStatus};
use sqlx::PgPool;
use tracing::{error, info, warn};

use super::model::{DiscrepancyType, PendingDiscrepancy, ReconciliationReport};
use super::repository;
use crate::deliveries::model::DeliveryStatus;
use crate::orders::model::PaymentType;
use crate::wallets::model::WalletTransactionType;
use crate::wallets::service::DELIVERY_COMMISSION_PERCENT;

/// Run daily reconciliation for a given date.
/// Matches all wallet credits/withdrawals against orders, deliveries, and CinetPay.
/// If `force` is true, deletes any existing report for the date and re-runs.
pub async fn run_daily_reconciliation(
    pool: &PgPool,
    payment_provider: &dyn PaymentProvider,
    date: chrono::NaiveDate,
    force: bool,
) -> Result<ReconciliationReport, AppError> {
    // Idempotency: return existing report if already ran for this date (unless forced)
    if let Some(existing) = repository::find_report_by_date(pool, date).await? {
        if !force {
            info!(date = %date, "Reconciliation already exists for this date");
            return Ok(existing);
        }
        info!(date = %date, "Force mode: deleting existing reconciliation report");
        repository::delete_report_by_date(pool, date).await?;
    }

    let transactions = repository::get_transactions_for_date(pool, date).await?;

    let mut discrepancies: Vec<PendingDiscrepancy> = Vec::new();
    let mut total_credits_count: i32 = 0;
    let mut total_credits_amount: i64 = 0;
    let mut total_withdrawals_count: i32 = 0;
    let mut total_withdrawals_amount: i64 = 0;
    let mut matched_count: i32 = 0;

    // Collect external_transaction_ids for batch verification
    // (tx_index, ext_txn_id, amount_ok) — only count as matched if amount also checks out
    let mut mobile_money_txns: Vec<(usize, String, bool)> = Vec::new();

    // First pass: classify transactions and collect data
    for (idx, tx) in transactions.iter().enumerate() {
        match tx.transaction_type {
            WalletTransactionType::Credit => {
                total_credits_count += 1;
                total_credits_amount += tx.amount;

                let reference = match &tx.reference {
                    Some(r) => r.clone(),
                    None => {
                        discrepancies.push(PendingDiscrepancy {
                            discrepancy_type: DiscrepancyType::OrphanCredit,
                            wallet_transaction_id: Some(tx.id),
                            internal_amount: Some(tx.amount),
                            external_amount: None,
                            reference: None,
                            details: Some("Credit without reference".into()),
                        });
                        continue;
                    }
                };

                if let Some(order_id_str) = reference.strip_prefix("order:") {
                    // Merchant credit — verify against order
                    match uuid::Uuid::parse_str(order_id_str) {
                        Ok(order_id) => {
                            match crate::orders::repository::find_by_id(pool, order_id).await {
                                Ok(Some(order)) => {
                                    // Check amount matches order.subtotal
                                    let amount_ok = tx.amount == order.subtotal;
                                    if !amount_ok {
                                        discrepancies.push(PendingDiscrepancy {
                                            discrepancy_type: DiscrepancyType::AmountMismatch,
                                            wallet_transaction_id: Some(tx.id),
                                            internal_amount: Some(tx.amount),
                                            external_amount: Some(order.subtotal),
                                            reference: Some(reference.clone()),
                                            details: Some(format!(
                                                "Wallet credit {} != order subtotal {}",
                                                tx.amount, order.subtotal
                                            )),
                                        });
                                    }

                                    if order.payment_type == PaymentType::MobileMoney {
                                        // MobileMoney: verify external_transaction_id
                                        match &order.external_transaction_id {
                                            Some(ext_id) => {
                                                mobile_money_txns.push((
                                                    idx,
                                                    ext_id.clone(),
                                                    amount_ok,
                                                ));
                                            }
                                            None => {
                                                discrepancies.push(PendingDiscrepancy {
                                                    discrepancy_type: DiscrepancyType::MissingExternalTxnId,
                                                    wallet_transaction_id: Some(tx.id),
                                                    internal_amount: Some(tx.amount),
                                                    external_amount: None,
                                                    reference: Some(reference.clone()),
                                                    details: Some(format!(
                                                        "MobileMoney order {} has no external_transaction_id",
                                                        order_id
                                                    )),
                                                });
                                            }
                                        }
                                    } else {
                                        // COD: verify delivery is delivered
                                        match crate::deliveries::repository::find_by_order(
                                            pool, order_id,
                                        )
                                        .await
                                        {
                                            Ok(Some(delivery))
                                                if delivery.status == DeliveryStatus::Delivered =>
                                            {
                                                if amount_ok {
                                                    matched_count += 1;
                                                }
                                            }
                                            _ => {
                                                discrepancies.push(PendingDiscrepancy {
                                                    discrepancy_type: DiscrepancyType::OrphanCredit,
                                                    wallet_transaction_id: Some(tx.id),
                                                    internal_amount: Some(tx.amount),
                                                    external_amount: None,
                                                    reference: Some(reference.clone()),
                                                    details: Some(format!(
                                                        "COD order {} has no confirmed delivery",
                                                        order_id
                                                    )),
                                                });
                                            }
                                        }
                                    }
                                }
                                Ok(None) => {
                                    discrepancies.push(PendingDiscrepancy {
                                        discrepancy_type: DiscrepancyType::OrphanCredit,
                                        wallet_transaction_id: Some(tx.id),
                                        internal_amount: Some(tx.amount),
                                        external_amount: None,
                                        reference: Some(reference.clone()),
                                        details: Some(format!("Order {} not found", order_id)),
                                    });
                                }
                                Err(e) => {
                                    warn!(order_id = %order_id, error = %e, "Failed to load order for reconciliation");
                                    discrepancies.push(PendingDiscrepancy {
                                        discrepancy_type: DiscrepancyType::OrphanCredit,
                                        wallet_transaction_id: Some(tx.id),
                                        internal_amount: Some(tx.amount),
                                        external_amount: None,
                                        reference: Some(reference.clone()),
                                        details: Some(format!("DB error loading order: {e}")),
                                    });
                                }
                            }
                        }
                        Err(_) => {
                            discrepancies.push(PendingDiscrepancy {
                                discrepancy_type: DiscrepancyType::OrphanCredit,
                                wallet_transaction_id: Some(tx.id),
                                internal_amount: Some(tx.amount),
                                external_amount: None,
                                reference: Some(reference.clone()),
                                details: Some("Invalid UUID in order reference".into()),
                            });
                        }
                    }
                } else if let Some(delivery_id_str) = reference.strip_prefix("delivery:") {
                    // Driver credit — verify against delivery
                    match uuid::Uuid::parse_str(delivery_id_str) {
                        Ok(delivery_id) => {
                            match crate::deliveries::repository::find_by_id(pool, delivery_id).await
                            {
                                Ok(Some(delivery)) => {
                                    if delivery.status != DeliveryStatus::Delivered {
                                        discrepancies.push(PendingDiscrepancy {
                                            discrepancy_type: DiscrepancyType::OrphanCredit,
                                            wallet_transaction_id: Some(tx.id),
                                            internal_amount: Some(tx.amount),
                                            external_amount: None,
                                            reference: Some(reference.clone()),
                                            details: Some(format!(
                                                "Delivery {} status is {}, expected delivered",
                                                delivery_id, delivery.status
                                            )),
                                        });
                                        continue;
                                    }

                                    // Verify amount: expected = delivery_fee - commission
                                    match crate::orders::repository::find_by_id(
                                        pool,
                                        delivery.order_id,
                                    )
                                    .await
                                    {
                                        Ok(Some(order)) => {
                                            let expected = order.delivery_fee
                                                - (order.delivery_fee
                                                    * DELIVERY_COMMISSION_PERCENT
                                                    / 100);
                                            if tx.amount != expected {
                                                discrepancies.push(PendingDiscrepancy {
                                                    discrepancy_type: DiscrepancyType::AmountMismatch,
                                                    wallet_transaction_id: Some(tx.id),
                                                    internal_amount: Some(tx.amount),
                                                    external_amount: Some(expected),
                                                    reference: Some(reference.clone()),
                                                    details: Some(format!(
                                                        "Driver credit {} != expected {} (fee={}, commission={}%)",
                                                        tx.amount, expected, order.delivery_fee, DELIVERY_COMMISSION_PERCENT
                                                    )),
                                                });
                                            } else {
                                                matched_count += 1;
                                            }
                                        }
                                        _ => {
                                            discrepancies.push(PendingDiscrepancy {
                                                discrepancy_type: DiscrepancyType::OrphanCredit,
                                                wallet_transaction_id: Some(tx.id),
                                                internal_amount: Some(tx.amount),
                                                external_amount: None,
                                                reference: Some(reference.clone()),
                                                details: Some(format!(
                                                    "Order not found for delivery {}",
                                                    delivery_id
                                                )),
                                            });
                                        }
                                    }
                                }
                                Ok(None) => {
                                    discrepancies.push(PendingDiscrepancy {
                                        discrepancy_type: DiscrepancyType::OrphanCredit,
                                        wallet_transaction_id: Some(tx.id),
                                        internal_amount: Some(tx.amount),
                                        external_amount: None,
                                        reference: Some(reference.clone()),
                                        details: Some(format!(
                                            "Delivery {} not found",
                                            delivery_id
                                        )),
                                    });
                                }
                                Err(e) => {
                                    discrepancies.push(PendingDiscrepancy {
                                        discrepancy_type: DiscrepancyType::OrphanCredit,
                                        wallet_transaction_id: Some(tx.id),
                                        internal_amount: Some(tx.amount),
                                        external_amount: None,
                                        reference: Some(reference.clone()),
                                        details: Some(format!("DB error loading delivery: {e}")),
                                    });
                                }
                            }
                        }
                        Err(_) => {
                            discrepancies.push(PendingDiscrepancy {
                                discrepancy_type: DiscrepancyType::OrphanCredit,
                                wallet_transaction_id: Some(tx.id),
                                internal_amount: Some(tx.amount),
                                external_amount: None,
                                reference: Some(reference.clone()),
                                details: Some("Invalid UUID in delivery reference".into()),
                            });
                        }
                    }
                } else if reference.starts_with("withdrawal:") {
                    // Compensation re-credit from failed withdrawal — not an orphan
                    matched_count += 1;
                } else {
                    discrepancies.push(PendingDiscrepancy {
                        discrepancy_type: DiscrepancyType::OrphanCredit,
                        wallet_transaction_id: Some(tx.id),
                        internal_amount: Some(tx.amount),
                        external_amount: None,
                        reference: Some(reference),
                        details: Some("Unknown reference prefix".into()),
                    });
                }
            }
            WalletTransactionType::Withdrawal => {
                total_withdrawals_count += 1;
                total_withdrawals_amount += tx.amount;
                // Internal consistency: withdrawal transaction exists → matched
                // CinetPay withdrawal verification is Phase 2
                matched_count += 1;
            }
            WalletTransactionType::Debit | WalletTransactionType::Refund => {
                // Debit/Refund are internal adjustments, not reconciled against external systems
                info!(tx_id = %tx.id, tx_type = ?tx.transaction_type, "Skipping non-reconcilable transaction type");
            }
        }
    }

    // Second pass: batch verify MobileMoney transactions with CinetPay
    if !mobile_money_txns.is_empty() {
        let ext_ids: Vec<String> = mobile_money_txns
            .iter()
            .map(|(_, id, _)| id.clone())
            .collect();

        match payment_provider.verify_payment_batch(&ext_ids).await {
            Ok(results) => {
                let results_map: std::collections::HashMap<String, PaymentStatus> =
                    results.into_iter().collect();

                for (idx, ext_id, amount_ok) in &mobile_money_txns {
                    let tx = &transactions[*idx];
                    match results_map.get(ext_id) {
                        Some(PaymentStatus::Completed) => {
                            if *amount_ok {
                                matched_count += 1;
                            }
                        }
                        Some(status) => {
                            discrepancies.push(PendingDiscrepancy {
                                discrepancy_type: DiscrepancyType::UnconfirmedAggregator,
                                wallet_transaction_id: Some(tx.id),
                                internal_amount: Some(tx.amount),
                                external_amount: None,
                                reference: tx.reference.clone(),
                                details: Some(format!(
                                    "CinetPay status {:?} for txn {}",
                                    status, ext_id
                                )),
                            });
                        }
                        None => {
                            discrepancies.push(PendingDiscrepancy {
                                discrepancy_type: DiscrepancyType::UnconfirmedAggregator,
                                wallet_transaction_id: Some(tx.id),
                                internal_amount: Some(tx.amount),
                                external_amount: None,
                                reference: tx.reference.clone(),
                                details: Some(format!(
                                    "CinetPay returned no result for txn {}",
                                    ext_id
                                )),
                            });
                        }
                    }
                }
            }
            Err(e) => {
                error!(error = %e, "CinetPay batch verification failed — marking all as unconfirmed");
                for (idx, ext_id, _) in &mobile_money_txns {
                    let tx = &transactions[*idx];
                    discrepancies.push(PendingDiscrepancy {
                        discrepancy_type: DiscrepancyType::UnconfirmedAggregator,
                        wallet_transaction_id: Some(tx.id),
                        internal_amount: Some(tx.amount),
                        external_amount: None,
                        reference: tx.reference.clone(),
                        details: Some(format!("Aggregator unavailable: {} (txn {})", e, ext_id)),
                    });
                }
            }
        }
    }

    // Persist report
    let params = repository::CreateReportParams {
        date,
        total_credits_count,
        total_credits_amount,
        total_withdrawals_count,
        total_withdrawals_amount,
        matched_count,
    };
    let report = repository::create_report(pool, &params, &discrepancies).await?;

    match &report.status {
        super::model::ReconciliationStatus::Ok => {
            info!(date = %date, credits = total_credits_count, withdrawals = total_withdrawals_count, "Reconciliation OK");
        }
        super::model::ReconciliationStatus::Warnings => {
            warn!(date = %date, discrepancies = report.discrepancy_count, "Reconciliation completed with warnings");
        }
        super::model::ReconciliationStatus::Critical => {
            error!(date = %date, discrepancies = report.discrepancy_count, "Reconciliation CRITICAL — discrepancies found");
        }
    }

    Ok(report)
}
