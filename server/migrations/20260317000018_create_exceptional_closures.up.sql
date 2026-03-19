-- Migration 018: Create exceptional_closures table
-- Story 3.8: Business Hours Management

CREATE TABLE exceptional_closures (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    merchant_id UUID NOT NULL REFERENCES merchants(id) ON DELETE CASCADE,
    closure_date DATE NOT NULL,
    reason VARCHAR(200),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (merchant_id, closure_date)
);

CREATE INDEX idx_exceptional_closures_merchant_date ON exceptional_closures(merchant_id, closure_date);

CREATE TRIGGER set_updated_at BEFORE UPDATE ON exceptional_closures
FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
