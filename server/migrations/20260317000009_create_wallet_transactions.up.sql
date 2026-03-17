CREATE TABLE wallet_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    wallet_id UUID NOT NULL REFERENCES wallets(id),
    amount BIGINT NOT NULL,
    transaction_type wallet_transaction_type NOT NULL,
    reference VARCHAR(255),
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_wallet_transactions_wallet_id ON wallet_transactions(wallet_id);
CREATE INDEX idx_wallet_transactions_reference ON wallet_transactions(reference);
CREATE INDEX idx_wallet_transactions_created_at ON wallet_transactions(created_at);
