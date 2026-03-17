DROP INDEX IF EXISTS idx_merchants_onboarding_step;
DROP INDEX IF EXISTS idx_merchants_created_by_agent_id;
ALTER TABLE merchants DROP COLUMN IF EXISTS created_by_agent_id;
ALTER TABLE merchants DROP COLUMN IF EXISTS onboarding_step;
ALTER TABLE merchants DROP COLUMN IF EXISTS category;
