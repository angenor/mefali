-- Migration 015: Add onboarding fields to merchants table
-- Story 3.1: Agent Terrain Merchant Onboarding Flow

ALTER TABLE merchants ADD COLUMN category VARCHAR(100);
ALTER TABLE merchants ADD COLUMN onboarding_step INT NOT NULL DEFAULT 0;
ALTER TABLE merchants ADD COLUMN created_by_agent_id UUID REFERENCES users(id);

CREATE INDEX idx_merchants_created_by_agent_id ON merchants(created_by_agent_id);
CREATE INDEX idx_merchants_onboarding_step ON merchants(onboarding_step);
