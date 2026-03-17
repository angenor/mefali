-- Migration 016: Create business_hours table
-- Story 3.1: Agent Terrain Merchant Onboarding Flow

CREATE TABLE business_hours (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    merchant_id UUID NOT NULL REFERENCES merchants(id) ON DELETE CASCADE,
    day_of_week SMALLINT NOT NULL CHECK (day_of_week >= 0 AND day_of_week <= 6),
    open_time TIME NOT NULL,
    close_time TIME NOT NULL,
    is_closed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (merchant_id, day_of_week)
);

CREATE INDEX idx_business_hours_merchant_id ON business_hours(merchant_id);

CREATE TRIGGER set_updated_at BEFORE UPDATE ON business_hours
FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
