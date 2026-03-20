-- M3: Add external_transaction_id for CinetPay audit/reconciliation
ALTER TABLE orders ADD COLUMN external_transaction_id TEXT;
