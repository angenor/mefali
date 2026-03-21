ALTER TABLE disputes DROP CONSTRAINT IF EXISTS disputes_order_id_unique;
ALTER TABLE disputes DROP COLUMN IF EXISTS description;
