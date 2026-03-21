-- Reconciliation enums
CREATE TYPE reconciliation_status AS ENUM ('ok', 'warnings', 'critical');
CREATE TYPE discrepancy_type AS ENUM (
    'orphan_credit',
    'orphan_withdrawal',
    'amount_mismatch',
    'missing_external_txn_id',
    'unconfirmed_aggregator'
);

-- Daily reconciliation reports
CREATE TABLE reconciliation_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reconciliation_date DATE NOT NULL UNIQUE,
    total_credits_count INT NOT NULL DEFAULT 0,
    total_credits_amount BIGINT NOT NULL DEFAULT 0,
    total_withdrawals_count INT NOT NULL DEFAULT 0,
    total_withdrawals_amount BIGINT NOT NULL DEFAULT 0,
    matched_count INT NOT NULL DEFAULT 0,
    discrepancy_count INT NOT NULL DEFAULT 0,
    status reconciliation_status NOT NULL DEFAULT 'ok',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_reconciliation_reports_date ON reconciliation_reports(reconciliation_date DESC);

-- Individual discrepancies linked to a report
CREATE TABLE reconciliation_discrepancies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id UUID NOT NULL REFERENCES reconciliation_reports(id) ON DELETE CASCADE,
    discrepancy_type discrepancy_type NOT NULL,
    wallet_transaction_id UUID REFERENCES wallet_transactions(id),
    internal_amount BIGINT,
    external_amount BIGINT,
    reference VARCHAR(255),
    details TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_reconciliation_discrepancies_report ON reconciliation_discrepancies(report_id);
